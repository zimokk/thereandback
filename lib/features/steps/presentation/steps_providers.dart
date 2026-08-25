import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/app_lifecycle.dart';
import '../../../app/database_provider.dart';
import '../../journey/presentation/journey_providers.dart';
import '../data/health_adapter.dart';
import '../data/step_sample_repository.dart';
import '../data/steps_sync_engine.dart';
import 'steps_sync_state.dart';

part 'steps_providers.g.dart';

/// The `health` package wrapper. Overridden with a fake in tests (`testing`
/// skill: never the real health plugin in a widget test).
@riverpod
HealthAdapter healthAdapter(Ref ref) => HealthPackageAdapter();

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
      final adapter = ref.read(healthAdapterProvider);
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
  /// `HealthAdapter.hasActivityRecognitionPermission`. A no-op `true` on iOS.
  Future<void> requestPermission() async {
    if (_permissionOpInFlight) return;
    _permissionOpInFlight = true;
    try {
      final adapter = ref.read(healthAdapterProvider);

      final activityRecognitionGranted = await adapter
          .requestActivityRecognitionPermission();
      if (!activityRecognitionGranted) {
        state = state.copyWith(permissionStatus: StepsPermissionStatus.denied);
        return;
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

  Future<void> openHealthConnectInstall() =>
      ref.read(healthAdapterProvider).openHealthConnectInstall();

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
        healthAdapter: ref.read(healthAdapterProvider),
        stepSampleRepository: ref.read(stepSampleRepositoryProvider),
      );
      final result = await engine.sync(quest: selected, now: DateTime.now());

      ref
          .read(selectedJourneyProvider.notifier)
          .applySyncedProgress(
            progressMeters: result.progressMeters,
            syncedAt: result.syncedAt,
          );
      state = state.copyWith(lastSyncFlagged: result.flagged);
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }
}
