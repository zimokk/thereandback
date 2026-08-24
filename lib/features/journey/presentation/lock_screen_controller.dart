import 'dart:async';
import 'dart:io' show Platform;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../steps/data/android_background_sync.dart';
import '../../steps/presentation/steps_providers.dart';
import '../data/android_lock_screen_channel.dart';
import '../data/lock_screen_channel.dart';
import '../domain/lock_screen_snapshot.dart';
import '../domain/quest_selection.dart';
import 'journey_providers.dart';
import 'lock_screen_state.dart';

part 'lock_screen_controller.g.dart';

/// The single [AndroidLockScreenChannel] instance — kept alive so its
/// `flutter_local_notifications` plugin only initializes once per app run.
/// Exposed both under its concrete type (for
/// [AndroidLockScreenChannel.requestNotificationPermission], which isn't
/// part of the shared interface) and, via [lockScreenChannel] below, under
/// the platform-agnostic [LockScreenChannel] type everything else depends
/// on.
@Riverpod(keepAlive: true)
AndroidLockScreenChannel androidLockScreenChannel(Ref ref) =>
    AndroidLockScreenChannel();

/// The seam the rest of the app (this controller, the background sync
/// callback) depends on. Android-only today — this provider is the one
/// line an iOS follow-up changes (`Platform.isAndroid ? ... : ...`), not
/// any of its callers.
@riverpod
LockScreenChannel lockScreenChannel(Ref ref) =>
    ref.watch(androidLockScreenChannelProvider);

@Riverpod(keepAlive: true)
AndroidBackgroundSync androidBackgroundSync(Ref ref) => AndroidBackgroundSync();

/// Whether the lock-screen/notification-shade feature has an implementation
/// on this platform — Android only today (see the architecture plan: iOS
/// needs a native Live Activity Widget Extension, a separate follow-up).
/// `settings_tab.dart` reads this to decide whether to show the toggle at
/// all; a seam rather than a raw `Platform.isAndroid` check inline so a
/// widget test can override it.
@riverpod
bool lockScreenSupported(Ref ref) => Platform.isAndroid;

/// Drives the persistent lock-screen / notification-shade display (§7).
///
/// Off by default — turning it on requests two permissions
/// (`POST_NOTIFICATIONS` and Health Connect's background-read permission)
/// through [enable], mirroring the explanation-then-request shape
/// `steps/presentation/permission_gate.dart` already uses for the health
/// permission (§7: never request without explaining first).
///
/// While enabled, this listens to [selectedJourneyProvider] and keeps the
/// display in sync with it — on quest start/switch, on every progress
/// update (foreground sync drives this the same way it always has; the
/// `workmanager` background task drives it independently, straight through
/// [lockScreenChannelProvider], without going through this controller at
/// all), and on quest completion (§6.1: the scene goes static, so this
/// stops showing "in progress" too).
@riverpod
class LockScreenController extends _$LockScreenController {
  @override
  LockScreenState build() {
    ref.listen<SelectedQuest?>(selectedJourneyProvider, _onQuestChanged);
    return const LockScreenState();
  }

  /// Requests both permissions and, if both are granted, turns the feature
  /// on: registers the background sync task and shows the display
  /// immediately if a quest is already active.
  Future<void> enable() async {
    if (state.enabled || state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      final channel = ref.read(androidLockScreenChannelProvider);
      final healthAdapter = ref.read(healthAdapterProvider);

      final notificationsGranted = await channel
          .requestNotificationPermission();

      // Health Connect only grants READ_HEALTH_DATA_IN_BACKGROUND once the
      // app already holds the base read permissions (READ_STEPS/
      // READ_DISTANCE) — requesting it first fails even if the user taps
      // "Allow" on the system prompt. The Путь tab is the usual place those
      // get granted, but this toggle is reachable without ever opening it
      // (fresh install → straight to Настройки), so ensure the prerequisite
      // here too instead of assuming it's already in place.
      var stepsGranted = await healthAdapter.hasStepsPermission() ?? false;
      if (!stepsGranted) {
        stepsGranted = await healthAdapter.requestStepsPermission();
      }

      final backgroundHealthGranted = stepsGranted
          ? await healthAdapter.requestBackgroundHealthPermission()
          : false;
      final granted = notificationsGranted && backgroundHealthGranted;

      state = state.copyWith(
        enabled: granted,
        permissionStatus: granted
            ? LockScreenPermissionStatus.granted
            : LockScreenPermissionStatus.denied,
      );

      if (!granted) return;

      await ref.read(androidBackgroundSyncProvider).register();
      await _showCurrentQuestIfActive();
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  /// Turns the feature off: stops the background task and clears the
  /// display. Does not revoke the OS permissions themselves — same as every
  /// other permission in this app, the system owns that.
  Future<void> disable() async {
    if (!state.enabled || state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      await ref.read(androidBackgroundSyncProvider).cancel();
      await ref.read(lockScreenChannelProvider).end();
      state = state.copyWith(enabled: false, activeJourneyId: null);
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> _showCurrentQuestIfActive() async {
    final quest = ref.read(selectedJourneyProvider);
    if (quest == null) return;
    await _showQuest(quest);
  }

  Future<void> _onQuestChanged(
    SelectedQuest? previous,
    SelectedQuest? next,
  ) async {
    if (!state.enabled) return;

    if (next == null) {
      await _hide();
      return;
    }

    final journey = ref.read(selectedJourneyDetailsProvider);
    if (journey == null) return;

    if (next.progressMeters >= journey.totalMeters) {
      // §6.1: quest complete — the scene goes static, this stops showing
      // "in progress" the same way.
      await _hide();
      await ref.read(androidBackgroundSyncProvider).cancel();
      return;
    }

    await _showQuest(next);
  }

  Future<void> _showQuest(SelectedQuest quest) async {
    final journey = ref.read(selectedJourneyDetailsProvider);
    if (journey == null) return;

    final snapshot = buildLockScreenSnapshot(
      quest: quest,
      journey: journey,
      now: DateTime.now(),
    );
    final channel = ref.read(lockScreenChannelProvider);

    if (state.activeJourneyId == quest.journeyId) {
      await channel.update(snapshot);
    } else {
      await channel.start(snapshot);
      state = state.copyWith(activeJourneyId: quest.journeyId);
    }
  }

  Future<void> _hide() async {
    if (state.activeJourneyId == null) return;
    await ref.read(lockScreenChannelProvider).end();
    state = state.copyWith(activeJourneyId: null);
  }
}
