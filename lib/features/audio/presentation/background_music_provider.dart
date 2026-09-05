import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/app_lifecycle.dart';
import '../../../app/user_preference_repository_provider.dart';
import '../../../core/local_owner.dart';
import '../../journey/presentation/journey_providers.dart';
import '../data/background_music_player.dart';
import '../domain/journey_theme_track.dart';

part 'background_music_provider.g.dart';

/// The single [BackgroundMusicPlayer] instance for the app session — kept
/// alive so the underlying `audioplayers` player (and, once loaded, the
/// track's decoded buffer) is created once, not on every toggle. Mirrors
/// `lock_screen_controller.dart`'s `androidLockScreenChannelProvider`.
@Riverpod(keepAlive: true)
BackgroundMusicPlayer backgroundMusicPlayer(Ref ref) {
  final player = BackgroundMusicPlayer();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
}

/// Whether background music (§6.5) is on. **Off by default** — this task's
/// own requirement — turning it on in Настройки starts the track
/// immediately (Настройки is only reachable while the app is in the
/// foreground, so there's no lifecycle gate to check first).
///
/// Which track plays isn't fixed — a quest with its own theme
/// (`journey_theme_track.dart`) overrides the app's shared default while
/// it's the selected quest (§14 "background music" — both catalog quests
/// have their own today), switching live if the toggle is already on when
/// the player switches quests, same as the shared default for every other
/// (future, track-less) quest.
///
/// While on, this also follows [appLifecycleProvider]: the track pauses the
/// instant the app leaves the foreground and resumes the instant it
/// returns — "играть будет... когда пользователь находится в приложении"
/// is a standing lifecycle rule, not just an on/off switch checked once at
/// toggle time. `keepAlive: true` so that rule keeps applying for the whole
/// app session, not only while the Настройки tab happens to be mounted —
/// see `app_shell.dart`'s eager `ref.watch`, same reasoning as
/// `LockScreenController`.
///
/// Durable since §14 ("сохраняй настройки пользователя..."): [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses — if the track
/// was on when the app was last closed, [_restore] resumes it through
/// [setEnabled] itself, so a restart gets the same guarantee a manual
/// toggle already has (state only reads "on" once playback actually
/// started).
@Riverpod(keepAlive: true)
class BackgroundMusicController extends _$BackgroundMusicController {
  @override
  bool build() {
    // Resolved once here, not inside the `onDispose` callback below —
    // riverpod asserts against calling `ref.read`/`ref.watch` from inside a
    // lifecycle callback (`Ref._throwIfInvalidUsage`), so the player has to
    // be captured in this synchronous scope and closed over instead.
    final player = ref.read(backgroundMusicPlayerProvider);
    ref.listen<AppLifecycleState>(appLifecycleProvider, _onLifecycleChanged);
    // The active quest's own track (`journey_theme_track.dart`) takes over
    // whenever the selected quest changes — including the very first read
    // below, so a quest already selected before this controller ever
    // builds (e.g. restart mid-quest) picks the right track from the
    // start, not just on the next switch.
    ref.listen(selectedJourneyDetailsProvider, (previous, next) {
      if (previous?.id == next?.id) return;
      unawaited(player.selectTrack(journeyThemeTrackAssetPath(next?.id)));
    });
    unawaited(
      player.selectTrack(
        journeyThemeTrackAssetPath(
          ref.read(selectedJourneyDetailsProvider)?.id,
        ),
      ),
    );
    ref.onDispose(() {
      unawaited(player.stop());
    });
    unawaited(_restore());
    return false;
  }

  Future<void> _restore() async {
    final enabled = await ref
        .read(userPreferenceRepositoryProvider)
        .loadBackgroundMusicEnabled(localOwnerId);
    if (!enabled) return;
    try {
      await setEnabled(true);
    } catch (error) {
      // A restart-time resume failing (e.g. the bundled asset went
      // missing) must not crash the app — a manual toggle tap would surface
      // this through the Настройки screen's own try/catch (§7), but there
      // is no user action here to attach that feedback to, so this just
      // leaves the toggle off (setEnabled never flipped [state] on a
      // failed start) and logs it.
      debugPrint('Failed to resume background music on restore: $error');
    }
  }

  /// Turns the track on or off. A failure starting playback (e.g. the
  /// bundled asset missing or unreadable) is left to propagate to the
  /// caller rather than swallowed here — the Настройки toggle catches it
  /// and shows a message (§7: never a silent dead end) — and [state] is
  /// only flipped to `true` once [BackgroundMusicPlayer.start] actually
  /// succeeds, so the switch never reads "on" while nothing is playing.
  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    final player = ref.read(backgroundMusicPlayerProvider);
    if (enabled) {
      await player.start();
    } else {
      await player.stop();
    }
    state = enabled;
    await ref
        .read(userPreferenceRepositoryProvider)
        .saveBackgroundMusicEnabled(localOwnerId, enabled);
  }

  void _onLifecycleChanged(
    AppLifecycleState? previous,
    AppLifecycleState next,
  ) {
    // Feature is off — nothing is playing, so there's nothing to pause or
    // resume; a stray lifecycle event here must not itself turn playback
    // on.
    if (!state) return;
    final player = ref.read(backgroundMusicPlayerProvider);
    unawaited(
      next == AppLifecycleState.resumed ? player.resume() : player.pause(),
    );
  }
}
