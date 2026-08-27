import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/app_lifecycle.dart';
import '../../../app/database_provider.dart';
import '../../../core/local_owner.dart';
import '../../steps/data/android_background_sync.dart';
import '../../steps/data/health_adapter.dart' show HealthConnectAvailability;
import '../../steps/presentation/steps_providers.dart';
import '../data/android_lock_screen_channel.dart';
import '../data/lock_screen_channel.dart';
import '../data/lock_screen_preference_repository.dart';
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

/// Durable store for [LockScreenState.enabled] — see
/// `LockScreenPreferenceRows` (`data/drift/database.dart`) for why the
/// in-memory flag alone isn't enough. Overridden with an in-memory
/// `AppDatabase` in tests via
/// `appDatabaseProvider` (`testing` skill), same as every other
/// drift-backed repository provider in this app.
@riverpod
LockScreenPreferenceRepository lockScreenPreferenceRepository(Ref ref) =>
    DriftLockScreenPreferenceRepository(ref.watch(appDatabaseProvider));

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
///
/// `keepAlive: true` (unlike `StepsSync`, which is autoDispose): this
/// controller must go on reconciling itself against the platform for the
/// whole app session, not just while the Настройки tab happens to be
/// mounted — see [build]'s restore step.
@Riverpod(keepAlive: true)
class LockScreenController extends _$LockScreenController {
  @override
  LockScreenState build() {
    ref.listen<SelectedQuest?>(selectedJourneyProvider, _onQuestChanged);

    // The permission screens this toggle sends the user to (Health Connect,
    // Android app settings) are separate activities, and access can also be
    // revoked there long after the fact — so re-read the OS on every return
    // to the app instead of trusting the last request's result forever.
    ref.listen<AppLifecycleState>(appLifecycleProvider, (_, next) {
      if (next == AppLifecycleState.resumed) unawaited(refreshStatus());
    });

    // Same shape as `StepsSync.build()`: the UI renders the `unknown` state
    // for the one frame before this resolves. Restoring the persisted
    // `enabled` flag first (not just calling `refreshStatus()` directly, the
    // way the resume listener above does) matters here: a fresh `build()`
    // otherwise starts from `enabled: false` no matter what a previous
    // session had, so `refreshStatus()`'s `if (state.enabled && !granted)
    // revoke()` check could never fire on a cold start — it wouldn't know
    // there was anything running to revoke. `app_shell.dart` reads this
    // provider unconditionally so this runs on every app start, not only
    // when the user happens to open Настройки.
    Future.microtask(_restoreThenRefresh);
    return const LockScreenState();
  }

  Future<void> _restoreThenRefresh() async {
    final persistedEnabled = await ref
        .read(lockScreenPreferenceRepositoryProvider)
        .loadEnabled(localOwnerId);
    await refreshStatus(restoredEnabled: persistedEnabled);
  }

  /// Re-reads both permissions from the platform and reconciles the toggle
  /// with them. Never turns the feature *on* by itself — holding the
  /// permissions is not the same as asking for a standing notification —
  /// but does turn it off if access was revoked while the app was away.
  ///
  /// [restoredEnabled], set only by [_restoreThenRefresh], applies the
  /// value just loaded from drift as part of *this* guarded run rather than
  /// as a separate unguarded write before it — `enable()`/`disable()` guard
  /// their own writes to `state.enabled` behind `isBusy`, and a write to it
  /// from here needs the same guard: without it, a build()-time restore
  /// racing an in-flight `enable()`/`disable()` call could overwrite
  /// whichever of the two `state.enabled` values loses the race, not
  /// necessarily the correct one.
  Future<void> refreshStatus({bool? restoredEnabled}) async {
    // Called from an unawaited `Future.microtask` in `build()` (via
    // `_restoreThenRefresh`) and from the app-lifecycle resume listener —
    // both fire-and-forget call sites that can still be pending after
    // whoever owns this controller has gone away (see the longer note
    // further down, at the `healthConnectAvailability()` await). Even the
    // very first `state` read below throws once that's happened, so this
    // has to be the first thing checked, not just something to guard after
    // an `await` inside the method.
    if (!ref.mounted) return;
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      if (restoredEnabled != null) {
        state = state.copyWith(enabled: restoredEnabled);
      }

      final healthAdapter = ref.read(healthAdapterProvider);

      // Checked separately from the permission calls below, and before
      // them: unlike `hasStepsPermission()`/`requestStepsPermission()`,
      // `hasBackgroundHealthPermission()` doesn't itself distinguish "Health
      // Connect isn't installed" from "installed but not granted" — both
      // used to read as a flat `denied`, which sends the user back to a
      // permission screen Health Connect has nowhere to show yet.
      if (Platform.isAndroid) {
        final availability = await healthAdapter.healthConnectAvailability();
        // `build()` kicks this method off from an unawaited
        // `Future.microtask` (see `_restoreThenRefresh`), so this call can
        // still be in flight after whoever owns this controller has gone
        // away — a torn-down widget tree in the app, or, in a test, a
        // `ProviderContainer` a `tearDown` already disposed. Riverpod
        // throws on any further `state` write once that happens
        // (`Ref.mounted`'s own doc comment recommends exactly this guard
        // after an `await`), so bail out instead of letting that throw
        // escape asynchronously into whatever happens to run next.
        if (!ref.mounted) return;
        if (availability == HealthConnectAvailability.notInstalled) {
          state = state.copyWith(
            permissionStatus: LockScreenPermissionStatus.healthConnectMissing,
          );
          if (state.enabled) await _revoke();
          return;
        }
      }

      final notificationsGranted = await ref
          .read(androidLockScreenChannelProvider)
          .hasNotificationPermission();
      if (!ref.mounted) return;
      final backgroundHealthGranted = await healthAdapter
          .hasBackgroundHealthPermission();
      if (!ref.mounted) return;
      final granted = notificationsGranted && backgroundHealthGranted;

      state = state.copyWith(
        notificationsGranted: notificationsGranted,
        backgroundHealthGranted: backgroundHealthGranted,
        permissionStatus: _statusFor(granted: granted),
      );

      if (state.enabled && !granted) await _revoke();
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Keeps [LockScreenPermissionStatus.notRequested] distinguishable from a
  /// real refusal: "not granted" only means "denied" once the user has
  /// actually been through [enable].
  LockScreenPermissionStatus _statusFor({required bool granted}) {
    if (granted) return LockScreenPermissionStatus.granted;
    return switch (state.permissionStatus) {
      LockScreenPermissionStatus.unknown ||
      LockScreenPermissionStatus.notRequested ||
      // Health Connect just became available again (e.g. the user installed
      // it) — the user hasn't been asked for anything yet on this round, so
      // this isn't a fresh refusal either.
      LockScreenPermissionStatus.healthConnectMissing =>
        LockScreenPermissionStatus.notRequested,
      LockScreenPermissionStatus.granted ||
      LockScreenPermissionStatus.denied => LockScreenPermissionStatus.denied,
    };
  }

  /// Access disappeared under a running feature: stop the background task
  /// and clear the display, but leave [LockScreenState.permissionStatus] to
  /// the caller — it already knows why this happened.
  Future<void> _revoke() async {
    await ref.read(androidBackgroundSyncProvider).cancel();
    await ref.read(lockScreenChannelProvider).end();
    state = state.copyWith(enabled: false, activeJourneyId: null);
    await ref
        .read(lockScreenPreferenceRepositoryProvider)
        .saveEnabled(localOwnerId, false);
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

      // Same check as `refreshStatus()` — bail out before asking for
      // anything (including the notification prompt) rather than let the
      // user grant notifications only to land on a background-health
      // denial that Health Connect, not being installed, could never have
      // granted in the first place.
      if (Platform.isAndroid &&
          await healthAdapter.healthConnectAvailability() ==
              HealthConnectAvailability.notInstalled) {
        state = state.copyWith(
          permissionStatus: LockScreenPermissionStatus.healthConnectMissing,
        );
        return;
      }

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
        notificationsGranted: notificationsGranted,
        backgroundHealthGranted: backgroundHealthGranted,
        permissionStatus: granted
            ? LockScreenPermissionStatus.granted
            : LockScreenPermissionStatus.denied,
      );
      await ref
          .read(lockScreenPreferenceRepositoryProvider)
          .saveEnabled(localOwnerId, granted);

      if (!granted) return;

      await ref.read(androidBackgroundSyncProvider).register();
      await _showCurrentQuestIfActive();
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  /// Deep-links to the Play Store listing for Health Connect — the action
  /// behind [LockScreenPermissionStatus.healthConnectMissing]'s card.
  /// Mirrors `StepsSync.openHealthConnectInstall()`.
  Future<void> openHealthConnectInstall() =>
      ref.read(healthAdapterProvider).openHealthConnectInstall();

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
      await ref
          .read(lockScreenPreferenceRepositoryProvider)
          .saveEnabled(localOwnerId, false);
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
