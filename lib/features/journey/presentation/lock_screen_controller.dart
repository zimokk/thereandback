import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/app_lifecycle.dart';
import '../../../app/database_provider.dart';
import '../../../core/local_owner.dart';
import '../../steps/data/android_background_sync.dart';
import '../../steps/data/step_counting_service.dart'
    show HealthConnectAvailability, RuntimePermissionResult;
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
  /// Completes when the currently-running [refreshStatus] finishes — `null`
  /// when none is in flight. [enable]/[disable] await this instead of
  /// bailing out the way the old shared `isBusy` guard used to: a
  /// resume-triggered background [refreshStatus] (see [build]'s lifecycle
  /// listener) could otherwise still be running at the exact instant the
  /// user taps the toggle, and silently eating that tap — no dialog, no
  /// state change, no error — was indistinguishable from the toggle being
  /// broken. Internal bookkeeping only, not part of [LockScreenState] —
  /// same shape as `StepsSync._permissionOpInFlight`.
  Completer<void>? _refreshCompleter;

  /// Set only while [enable]/[disable] are running, so a resume-triggered
  /// [refreshStatus] steps aside instead of racing an explicit user action
  /// and overwriting its result with stale platform state — the direction
  /// that guard actually matters for; see [_refreshCompleter]'s doc for the
  /// other direction.
  bool _userActionInFlight = false;

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
    // Gated on the just-loaded `persistedEnabled`, not the ambient
    // `state.enabled` — a concurrent explicit `enable()` call (e.g. a test,
    // or a very fast user tap) can itself flip `state.enabled` to `true`
    // while this method is still awaiting the line above; reading
    // `state.enabled` here would fire this cold-start catch-up for a
    // session this method never actually found persisted as on, double-
    // showing the quest alongside `enable()`'s own call. `persistedEnabled`
    // is a local value from *this* call's own read, immune to that race.
    // `refreshStatus`'s own permission check can still turn a persisted
    // `true` into a real `false` (revoked access) — `state.enabled` is
    // checked too, so a revoke isn't followed by a show.
    if (!ref.mounted || !persistedEnabled || !state.enabled) return;

    // Bug fix: a cold restart with the feature already on used to leave the
    // notification missing even though `state.enabled` came back `true` and
    // every permission still held. `refreshStatus()` only reconciles
    // permission/enabled state, it never (re)posts the notification —
    // that's `enable()`'s job, and `enable()` only ever runs from an
    // explicit user tap. The one other place that could show it,
    // `_onQuestChanged` (via the `ref.listen` in `build()`, firing once
    // `SelectedJourney`'s own independent restore resolves), guards on
    // `state.enabled` too — and that restore races this one: if
    // `SelectedJourney` finishes first, `_onQuestChanged` reads
    // `state.enabled` as still the pre-restore `false` and silently returns,
    // so neither path ever calls `_showQuest`. Explicitly showing here,
    // after both restores are known to have finished, closes that gap
    // regardless of which one actually won the race — `_showQuest`'s own
    // `activeJourneyId` check/write (kept synchronous, no `await` between
    // them) means it's harmless even if `_onQuestChanged` *also* fires for
    // the same quest around the same time.
    await ref.read(selectedJourneyProvider.notifier).ensureRestored();
    if (!ref.mounted) return;
    await _showCurrentQuestIfActive();
  }

  /// Re-reads both permissions from the platform and reconciles the toggle
  /// with them. Never turns the feature *on* by itself — holding the
  /// permissions is not the same as asking for a standing notification —
  /// but does turn it off if access was revoked while the app was away.
  ///
  /// [restoredEnabled], set only by [_restoreThenRefresh], applies the
  /// value just loaded from drift as part of *this* guarded run rather than
  /// as a separate unguarded write before it — `enable()`/`disable()` guard
  /// their own writes to `state.enabled` behind [_userActionInFlight], and a
  /// write to it from here needs the same guard: without it, a build()-time
  /// restore racing an in-flight `enable()`/`disable()` call could overwrite
  /// whichever of the two `state.enabled` values loses the race, not
  /// necessarily the correct one.
  ///
  /// Deliberately never touches [LockScreenState.isBusy] — that field is
  /// UI-facing (it disables the Настройки toggle) and this is a silent
  /// background reconciliation the user never asked for and shouldn't see
  /// the toggle react to; see [_refreshCompleter]'s doc for why.
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
    if (_userActionInFlight) return;
    final completer = Completer<void>();
    _refreshCompleter = completer;
    try {
      if (restoredEnabled != null) {
        state = state.copyWith(enabled: restoredEnabled);
      }

      // No implementation on iOS yet (`lockScreenSupported` returns
      // `false` there, so `settings_tab.dart` never shows the toggle and
      // `enable()` can never have run — `state.enabled` above is always
      // `false` on iOS). Bail out before touching anything below:
      // `androidLockScreenChannelProvider` is `AndroidLockScreenChannel`,
      // which crashes on iOS the moment
      // `FlutterLocalNotificationsPlugin.initialize` runs without iOS
      // settings — see `app_shell.dart`'s unconditional
      // `ref.watch(lockScreenControllerProvider)`, which is what drives
      // this method on every app start regardless of platform.
      //
      // Deliberately `Platform.isIOS`, not `!Platform.isAndroid` — the
      // widget-test host running this code is Linux, which is neither, and
      // `lock_screen_controller_test.dart` already exercises the
      // `AndroidLockScreenChannel` path unconditionally on it (its own doc
      // comment notes `Platform.isAndroid` reflects the actual host, not a
      // simulated target). `!Platform.isAndroid` would have silently
      // changed that suite's behavior on Linux too, not just fixed iOS.
      if (Platform.isIOS) return;

      final stepCountingService = ref.read(stepCountingServiceProvider);

      // Checked separately from the permission calls below, and before
      // them: unlike `hasStepsPermission()`/`requestStepsPermission()`,
      // `hasBackgroundHealthPermission()` doesn't itself distinguish "Health
      // Connect isn't installed" from "installed but not granted" — both
      // used to read as a flat `denied`, which sends the user back to a
      // permission screen Health Connect has nowhere to show yet.
      if (Platform.isAndroid) {
        final availability = await stepCountingService
            .healthConnectAvailability();
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
      final backgroundHealthGranted = await stepCountingService
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
      _refreshCompleter = null;
      completer.complete();
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
      // A background re-check can't re-derive this — only a fresh enable()
      // call learns whether ACTIVITY_RECOGNITION is still permanently
      // denied — so leave the "open settings" messaging in place rather
      // than downgrading it to a plain "denied" that implies retrying the
      // toggle would show a dialog again.
      LockScreenPermissionStatus.permanentlyDenied =>
        LockScreenPermissionStatus.permanentlyDenied,
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
    // A resume-triggered refreshStatus() (see build()'s lifecycle listener)
    // can still be running at this exact instant — Health Connect's and
    // Android settings' permission screens are separate activities, so
    // every trip through one of them resumes this app right before the
    // user's next tap. Wait for it instead of bailing out: dropping the
    // tap here used to be indistinguishable from the toggle being broken —
    // no dialog, no state change, no error, nothing in the logs.
    await _refreshCompleter?.future;
    if (state.enabled || state.isBusy) return;

    state = state.copyWith(isBusy: true);
    _userActionInFlight = true;
    try {
      final channel = ref.read(androidLockScreenChannelProvider);
      final stepCountingService = ref.read(stepCountingServiceProvider);

      // Same check as `refreshStatus()` — bail out before asking for
      // anything (including the notification prompt) rather than let the
      // user grant notifications only to land on a background-health
      // denial that Health Connect, not being installed, could never have
      // granted in the first place.
      if (Platform.isAndroid &&
          await stepCountingService.healthConnectAvailability() ==
              HealthConnectAvailability.notInstalled) {
        state = state.copyWith(
          permissionStatus: LockScreenPermissionStatus.healthConnectMissing,
        );
        return;
      }

      final notificationsGranted = await channel
          .requestNotificationPermission();

      // `ACTIVITY_RECOGNITION` ("Physical activity") is a prerequisite for
      // Health Connect's own Steps/Distance consent screen — Health Connect
      // won't grant that screen's request while this is missing, no matter
      // how many times requestStepsPermission() runs (see
      // StepCountingService.hasActivityRecognitionPermission). The Путь tab
      // requests this first (steps_providers.dart's requestPermission());
      // this toggle is reachable without ever opening it (fresh install →
      // straight to Настройки), so it needs the same first step, not just
      // the base read permission this used to jump straight to.
      final activityRecognitionResult = await stepCountingService
          .requestActivityRecognitionPermission();

      var backgroundHealthGranted = false;
      LockScreenPermissionStatus? blockedStatus;

      switch (activityRecognitionResult) {
        case RuntimePermissionResult.permanentlyDenied:
          // Android will not show the dialog again (`USER_FIXED`) —
          // retrying requestStepsPermission() from here on would silently
          // no-op every time the toggle is pressed. §7: never a dead end,
          // so route to the OS settings page instead of pretending another
          // in-app tap can still work.
          blockedStatus = LockScreenPermissionStatus.permanentlyDenied;
        case RuntimePermissionResult.denied:
          blockedStatus = LockScreenPermissionStatus.denied;
        case RuntimePermissionResult.granted:
          var stepsGranted =
              await stepCountingService.hasStepsPermission() ?? false;
          if (!stepsGranted) {
            stepsGranted = await stepCountingService.requestStepsPermission();
          }
          backgroundHealthGranted = stepsGranted
              ? await stepCountingService.requestBackgroundHealthPermission()
              : false;
      }

      final granted =
          blockedStatus == null &&
          notificationsGranted &&
          backgroundHealthGranted;

      state = state.copyWith(
        enabled: granted,
        notificationsGranted: notificationsGranted,
        backgroundHealthGranted: backgroundHealthGranted,
        permissionStatus: granted
            ? LockScreenPermissionStatus.granted
            : (blockedStatus ?? LockScreenPermissionStatus.denied),
      );
      await ref
          .read(lockScreenPreferenceRepositoryProvider)
          .saveEnabled(localOwnerId, granted);

      if (!granted) return;

      await ref.read(androidBackgroundSyncProvider).register();
      await _showCurrentQuestIfActive();
    } finally {
      _userActionInFlight = false;
      state = state.copyWith(isBusy: false);
    }
  }

  /// Deep-links to the Play Store listing for Health Connect — the action
  /// behind [LockScreenPermissionStatus.healthConnectMissing]'s card.
  /// Mirrors `StepsSync.openHealthConnectInstall()`.
  Future<void> openHealthConnectInstall() =>
      ref.read(stepCountingServiceProvider).openHealthConnectInstall();

  /// Turns the feature off: stops the background task and clears the
  /// display. Does not revoke the OS permissions themselves — same as every
  /// other permission in this app, the system owns that.
  Future<void> disable() async {
    if (!state.enabled || state.isBusy) return;
    // Same reasoning as enable() — see its comment above.
    await _refreshCompleter?.future;
    if (!state.enabled || state.isBusy) return;

    state = state.copyWith(isBusy: true);
    _userActionInFlight = true;
    try {
      await ref.read(androidBackgroundSyncProvider).cancel();
      await ref.read(lockScreenChannelProvider).end();
      state = state.copyWith(enabled: false, activeJourneyId: null);
      await ref
          .read(lockScreenPreferenceRepositoryProvider)
          .saveEnabled(localOwnerId, false);
    } finally {
      _userActionInFlight = false;
      state = state.copyWith(isBusy: false);
    }
  }

  /// Opens this app's OS settings page — the only way left to grant
  /// `ACTIVITY_RECOGNITION` once [LockScreenPermissionStatus.permanentlyDenied]
  /// has been reached (mirrors `StepsSync.openAppSettings()` for the Путь
  /// tab's own gate).
  Future<void> openAppSettings() =>
      ref.read(stepCountingServiceProvider).openAppSettings();

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

    // `_onQuestChanged` (the `selectedJourneyProvider` listener) and
    // `_restoreThenRefresh`'s own cold-start catch-up call can both end up
    // calling this for the same quest right after a restore — checking
    // `state.activeJourneyId` and writing it back are kept in the same
    // synchronous stretch (no `await` between them) so the second caller
    // always sees the first one's write and falls into `update()`, not a
    // second `start()`. Splitting the write to *after* `channel.start()`
    // used to leave a real gap there — an `await` on the plugin call — for
    // exactly that race to slip through.
    final isNewJourney = state.activeJourneyId != quest.journeyId;
    if (isNewJourney) state = state.copyWith(activeJourneyId: quest.journeyId);

    if (isNewJourney) {
      await channel.start(snapshot);
    } else {
      await channel.update(snapshot);
    }
  }

  Future<void> _hide() async {
    if (state.activeJourneyId == null) return;
    await ref.read(lockScreenChannelProvider).end();
    state = state.copyWith(activeJourneyId: null);
  }
}
