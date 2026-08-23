import 'dart:io' show Platform;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../journey/presentation/journey_providers.dart';
import '../data/health_adapter.dart';
import '../domain/stride.dart';
import 'steps_sync_state.dart';

part 'steps_providers.g.dart';

/// The `health` package wrapper. Overridden with a fake in tests (`testing`
/// skill: never the real health plugin in a widget test).
@riverpod
HealthAdapter healthAdapter(Ref ref) => HealthPackageAdapter();

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
  /// `selectedJourneyProvider`. A no-op if no quest is selected or
  /// permission is not currently granted.
  ///
  /// Also runs the §5.2 realistic-pace check on the raw step count and
  /// records the result in [StepsSyncState.lastSyncFlagged] — flagged, not
  /// dropped, so the credited distance is unaffected either way.
  Future<void> sync() async {
    final selected = ref.read(selectedJourneyProvider);
    if (selected == null) return;
    if (state.permissionStatus != StepsPermissionStatus.granted) return;

    state = state.copyWith(isSyncing: true);
    try {
      final adapter = ref.read(healthAdapterProvider);
      final now = DateTime.now();
      final interval = now.difference(selected.lastSyncedAt);
      final delta = await adapter.fetchDelta(selected.lastSyncedAt, now);

      // §5.2: an interval above the realistic-pace threshold is flagged,
      // never silently dropped — the distance below is still credited.
      final flagged = isImplausiblePace(steps: delta.steps, interval: interval);

      final deltaMeters = resolveDistanceMeters(
        stepCount: delta.steps,
        walkingDistanceMeters: delta.walkingDistanceMeters,
      );
      final candidate = clampNonDecreasing(
        selected.progressMeters,
        selected.progressMeters + deltaMeters,
      );
      ref
          .read(selectedJourneyProvider.notifier)
          .applySyncedProgress(progressMeters: candidate, syncedAt: now);
      state = state.copyWith(lastSyncFlagged: flagged);
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }
}
