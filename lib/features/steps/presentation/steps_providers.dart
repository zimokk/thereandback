import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/app_lifecycle.dart';
import '../../../app/auth_provider.dart';
import '../../../app/database_provider.dart';
import '../../../data/firestore/firestore_providers.dart';
import '../../achievements/presentation/achievements_providers.dart';
import '../../journey/presentation/journey_providers.dart';
import '../data/android_step_counting_service.dart';
import '../data/ios_step_counting_service.dart';
import '../data/step_counting_service.dart';
import '../data/step_sample_repository.dart';
import '../data/steps_sync_engine.dart';
import 'steps_sync_state.dart';

part 'steps_providers.g.dart';

/// Picks the platform's `StepCountingService` — the only
/// `Platform.isAndroid` check anywhere in this feature, since both concrete
/// classes are unconditional, single-platform code (see
/// `step_counting_service.dart`'s doc comment). Kept here, not in
/// `step_counting_service.dart`, so that file has no reason to import
/// either concrete implementation — only this composition-root-ish spot
/// needs to know both exist.
StepCountingService createStepCountingService() => Platform.isAndroid
    ? AndroidStepCountingService()
    : IosStepCountingService();

/// The step-counting service. Overridden with a fake in tests (`testing`
/// skill: never the real health plugin in a widget test).
@riverpod
StepCountingService stepCountingService(Ref ref) => createStepCountingService();

/// The drift-backed idempotency log for synced intervals (§5.2). Overridden
/// with an in-memory `AppDatabase` in tests via `appDatabaseProvider`
/// (`testing` skill).
@riverpod
StepSampleRepository stepSampleRepository(Ref ref) =>
    DriftStepSampleRepository(ref.watch(appDatabaseProvider));

/// Drives the foreground steps-sync flow: permission checks, the Health
/// Connect "not installed" case, and syncing a delta into
/// `selectedJourneyProvider` through the pure `stride.dart` math.
///
/// Foreground only — no background delivery/WorkManager here. §7 calls
/// background sync its own architectural decision that needs a separate
/// plan; this syncs when the Путь tab opens and on pull-to-refresh
/// (see `docs/screens/steps-sync.md`).
@riverpod
class StepsSync extends _$StepsSync {
  /// Guards `refreshStatus()` and `requestPermission()` against each other.
  /// Health Connect's permission screen is a separate activity: granting it
  /// resumes this app, which fires `refreshStatus()` from the lifecycle
  /// listener below, *while* the `await` in `requestPermission()` that
  /// launched that same screen is still pending. Both write
  /// `permissionStatus` when they resolve; without this guard, whichever
  /// finishes last wins even if its answer is the stale one — the explicit
  /// request's own result could be overwritten by a resume-triggered check
  /// that ran a moment earlier. Internal bookkeeping only, not part of
  /// [StepsSyncState] — nothing in the UI needs to observe it.
  bool _permissionOpInFlight = false;

  @override
  StepsSyncState build() {
    // Health Connect's permission screen is a separate activity, so the
    // grant usually lands while this app is backgrounded — without this the
    // gate keeps showing "denied" until the next cold start.
    ref.listen<AppLifecycleState>(appLifecycleProvider, (_, next) {
      if (next == AppLifecycleState.resumed) unawaited(refreshStatus());
    });

    // Kick off a status check as soon as this provider is first read; the
    // widget renders the `unknown` state for the one frame before this
    // resolves.
    Future.microtask(refreshStatus);
    return const StepsSyncState();
  }

  Future<void> refreshStatus() async {
    // An explicit requestPermission() is mid-flight (e.g. its Health Connect
    // screen just resumed this app and fired the lifecycle listener before
    // the awaited request itself resolved) — let that call's own result
    // stand rather than racing it with a status check that can read stale
    // platform state.
    if (_permissionOpInFlight) return;
    _permissionOpInFlight = true;
    try {
      final adapter = ref.read(stepCountingServiceProvider);
      await adapter.configure();

      if (Platform.isAndroid) {
        final availability = await adapter.healthConnectAvailability();
        if (availability == HealthConnectAvailability.notInstalled) {
          state = state.copyWith(
            permissionStatus: StepsPermissionStatus.healthConnectMissing,
          );
          return;
        }
      }

      final granted = await adapter.hasStepsPermission();
      state = state.copyWith(
        permissionStatus: granted == true
            ? StepsPermissionStatus.granted
            : StepsPermissionStatus.notRequested,
      );
      if (granted == true) {
        await sync();
      }
    } finally {
      _permissionOpInFlight = false;
    }
  }

  /// Shows the OS permission prompt (called from the explanation card).
  ///
  /// Android needs two prompts in sequence, not one: `ACTIVITY_RECOGNITION`
  /// ("Physical activity" in system settings) is a dangerous-protection-level
  /// OS permission that Health Connect requires as a prerequisite for its
  /// own Steps/Distance consent screen ("Fitness and wellness") — Health
  /// Connect will not grant that screen's request while it's missing, no
  /// matter how many times the request below runs. See
  /// `StepCountingService.hasActivityRecognitionPermission`. A no-op grant
  /// on iOS.
  ///
  /// A second `ACTIVITY_RECOGNITION` denial is Android's last one — the
  /// third call here shows no dialog at all
  /// ([RuntimePermissionResult.permanentlyDenied], see that enum) — so from
  /// then on this method routes to [StepsPermissionStatus.permanentlyDenied]
  /// instead of re-asking, and the gate offers [openAppSettings] instead of
  /// another "try again".
  Future<void> requestPermission() async {
    if (_permissionOpInFlight) return;
    _permissionOpInFlight = true;
    try {
      final adapter = ref.read(stepCountingServiceProvider);

      final activityRecognitionResult = await adapter
          .requestActivityRecognitionPermission();
      switch (activityRecognitionResult) {
        case RuntimePermissionResult.permanentlyDenied:
          state = state.copyWith(
            permissionStatus: StepsPermissionStatus.permanentlyDenied,
          );
          return;
        case RuntimePermissionResult.denied:
          state = state.copyWith(
            permissionStatus: StepsPermissionStatus.denied,
          );
          return;
        case RuntimePermissionResult.granted:
          break;
      }

      final granted = await adapter.requestStepsPermission();
      state = state.copyWith(
        permissionStatus: granted
            ? StepsPermissionStatus.granted
            : StepsPermissionStatus.denied,
      );
      if (granted) {
        await sync();
      }
    } finally {
      _permissionOpInFlight = false;
    }
  }

  /// Opens this app's OS settings page — the only way left to grant
  /// `ACTIVITY_RECOGNITION` once [StepsPermissionStatus.permanentlyDenied]
  /// has been reached (called from the gate's "Open settings" button).
  Future<void> openAppSettings() =>
      ref.read(stepCountingServiceProvider).openAppSettings();

  Future<void> openHealthConnectInstall() =>
      ref.read(stepCountingServiceProvider).openHealthConnectInstall();

  /// Fetches the delta since the selected quest's `lastSyncedAt`, resolves
  /// it to meters via `stride.dart`, and writes the new total back into
  /// `selectedJourneyProvider`. A no-op if no quest is selected, permission
  /// is not currently granted, or a sync is already in flight (the last one
  /// is itself the first line of defense against the §5.2 idempotency race
  /// a double-tap or overlapping background/foreground sync could cause).
  ///
  /// The actual fetch/resolve/record algorithm lives in
  /// `data/steps_sync_engine.dart`'s [StepsSyncEngine] — shared with the
  /// Android background sync task, so a background tick and a later
  /// foreground sync of the same interval go through the exact same
  /// idempotency key. This method's job is just the provider-facing part:
  /// building the engine, applying its result, and tracking
  /// [StepsSyncState.lastSyncFlagged]/`isSyncing`.
  Future<void> sync() async {
    final selected = ref.read(selectedJourneyProvider);
    if (selected == null) return;
    if (state.permissionStatus != StepsPermissionStatus.granted) return;
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true);
    try {
      final engine = StepsSyncEngine(
        stepCountingService: ref.read(stepCountingServiceProvider),
        stepSampleRepository: ref.read(stepSampleRepositoryProvider),
        achievementRepository: ref.read(achievementRepositoryProvider),
      );
      final result = await engine.sync(quest: selected, now: DateTime.now());

      ref
          .read(selectedJourneyProvider.notifier)
          .applySyncedProgress(
            progressMeters: result.progressMeters,
            syncedAt: result.syncedAt,
          );
      state = state.copyWith(lastSyncFlagged: result.flagged);
      // `achievementUnlocksProvider`/`todayAllQuestsMetersProvider` are both
      // `@riverpod` (autoDispose): they drop their cached read the moment
      // nothing watches them (leaving the Трофеи tab), so the next visit
      // already re-queries fresh — no manual invalidation needed here for
      // that case. This covers the one case that isn't: the tab open and
      // watching *right now*, mid-sync.
      ref.invalidate(achievementUnlocksProvider);
      ref.invalidate(todayAllQuestsMetersProvider);

      unawaited(
        _pushProgress(
          journeyId: selected.journeyId,
          startedAt: selected.startedAt,
          progressMeters: result.progressMeters,
        ),
      );
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Pushes the just-synced total to Firestore (§8, Phase 8) — foreground
  /// only, fire-and-forget with respect to this method's own caller: a
  /// Firestore failure (offline, permission not yet granted, no signed-in
  /// uid yet on a very fresh cold start) must never affect [sync]'s own
  /// result — the local drift write above already durably credited the
  /// distance regardless of whether this succeeds.
  Future<void> _pushProgress({
    required String journeyId,
    required DateTime startedAt,
    required int progressMeters,
  }) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    try {
      await ref
          .read(progressSyncRepositoryProvider)
          .pushProgress(
            uid: uid,
            journeyId: journeyId,
            meters: progressMeters,
            startedAt: startedAt,
            isCurrent: true,
          );
    } catch (_) {
      // See doc comment above — never let this surface to sync()'s caller.
    }
  }
}
