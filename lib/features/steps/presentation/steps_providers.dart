import 'dart:io' show Platform;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/database_provider.dart';
import '../../../core/local_owner.dart';
import '../../journey/presentation/journey_providers.dart';
import '../data/health_adapter.dart';
import '../data/step_sample_repository.dart';
import '../domain/stride.dart';
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
  @override
  StepsSyncState build() {
    // Kick off a status check as soon as this provider is first read; the
    // widget renders the `unknown` state for the one frame before this
    // resolves.
    Future.microtask(refreshStatus);
    return const StepsSyncState();
  }

  Future<void> refreshStatus() async {
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
  }

  /// Shows the OS permission prompt (called from the explanation card).
  Future<void> requestPermission() async {
    final adapter = ref.read(healthAdapterProvider);
    final granted = await adapter.requestStepsPermission();
    state = state.copyWith(
      permissionStatus: granted
          ? StepsPermissionStatus.granted
          : StepsPermissionStatus.denied,
    );
    if (granted) {
      await sync();
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
  /// Also runs the §5.2 realistic-pace check on the raw step count and
  /// records the result in [StepsSyncState.lastSyncFlagged] — flagged, not
  /// dropped, so the credited distance is unaffected either way.
  Future<void> sync() async {
    final selected = ref.read(selectedJourneyProvider);
    if (selected == null) return;
    if (state.permissionStatus != StepsPermissionStatus.granted) return;
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true);
    try {
      final adapter = ref.read(healthAdapterProvider);
      final intervalStart = selected.lastSyncedAt;
      final now = DateTime.now();
      final interval = now.difference(intervalStart);
      final delta = await adapter.fetchDelta(intervalStart, now);

      // §5.2: an interval above the realistic-pace threshold is flagged,
      // never silently dropped — the distance below is still credited.
      final flagged = isImplausiblePace(steps: delta.steps, interval: interval);

      final deltaMeters = resolveDistanceMeters(
        stepCount: delta.steps,
        walkingDistanceMeters: delta.walkingDistanceMeters,
      );

      // §5.2's real idempotency guarantee: durable, keyed on
      // (ownerId, journeyId, intervalStart), so a replay of this exact
      // interval — say, after an app restart lost `lastSyncedAt` — is
      // recognized and never credited twice.
      final isNewInterval = await ref
          .read(stepSampleRepositoryProvider)
          .recordInterval(
            ownerId: localOwnerId,
            journeyId: selected.journeyId,
            intervalStart: intervalStart,
            intervalEnd: now,
            steps: delta.steps,
            walkingDistanceMeters: delta.walkingDistanceMeters,
            resolvedMeters: deltaMeters,
            flaggedPace: flagged,
            syncedAt: now,
          );

      final candidateMeters = isNewInterval
          ? clampNonDecreasing(
              selected.progressMeters,
              selected.progressMeters + deltaMeters,
            )
          : selected.progressMeters; // already credited — advance the
      // sync window only, per the idempotency guard above.
      ref
          .read(selectedJourneyProvider.notifier)
          .applySyncedProgress(progressMeters: candidateMeters, syncedAt: now);
      state = state.copyWith(lastSyncFlagged: flagged);
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }
}
