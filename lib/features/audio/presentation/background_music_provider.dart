import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/app_lifecycle.dart';
import '../data/background_music_player.dart';

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

/// Whether the app's one background track (§6.5) is on. **Off by
/// default** — this task's own requirement — turning it on in Настройки
/// starts the track immediately (Настройки is only reachable while the app
/// is in the foreground, so there's no lifecycle gate to check first).
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
/// In-memory only, like `AppThemeOverride`/`AppLocale` (`theme_provider
/// .dart`, `locale_provider.dart`) — resets to off on the next cold start
/// rather than persisting. Matches every other Настройки toggle that isn't
/// already backed by drift; promoting it to a persisted preference (the
/// `LockScreenPreferenceRepository` shape) is a follow-up, not something
/// this task asked for.
@Riverpod(keepAlive: true)
class BackgroundMusicController extends _$BackgroundMusicController {
  @override
  bool build() {
    ref.listen<AppLifecycleState>(appLifecycleProvider, _onLifecycleChanged);
    ref.onDispose(() {
      unawaited(ref.read(backgroundMusicPlayerProvider).stop());
    });
    return false;
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
