import '../../../core/local_owner.dart';
import '../../journey/domain/quest_selection.dart';
import '../domain/stride.dart';
import 'health_adapter.dart';
import 'step_sample_repository.dart';

/// The outcome of one [StepsSyncEngine.sync] call: the new progress total to
/// credit, the sync window's new end, and whether §5.2's realistic-pace
/// check flagged this interval.
class StepsSyncResult {
  const StepsSyncResult({
    required this.progressMeters,
    required this.syncedAt,
    required this.flagged,
  });

  final int progressMeters;
  final DateTime syncedAt;
  final bool flagged;
}

/// The steps-sync algorithm (§5.1, §5.2), extracted from
/// `steps/presentation/steps_providers.dart`'s `StepsSync.sync()` so it can
/// run without a `Ref` — the foreground provider and the Android background
/// task (`android_background_sync.dart`) both call the exact same code,
/// through the exact same idempotency key, so a background tick and a later
/// foreground sync of the same interval can never double-credit distance.
///
/// No platform-channel or Riverpod dependency here — just the health
/// adapter and the drift-backed idempotency log, both already
/// interface-typed for testing (`testing` skill).
class StepsSyncEngine {
  StepsSyncEngine({
    required this.healthAdapter,
    required this.stepSampleRepository,
  });

  final HealthAdapter healthAdapter;
  final StepSampleRepository stepSampleRepository;

  /// Fetches the delta since [quest]'s `lastSyncedAt`, resolves it to meters
  /// via `stride.dart`, and records it idempotently. Does not touch any
  /// provider state — the caller decides what to do with the result (apply
  /// it to `selectedJourneyProvider` in the foreground case, or push it
  /// straight into the lock-screen channel in the background case).
  ///
  /// Also runs the §5.2 realistic-pace check on the raw step count —
  /// flagged, not dropped, so the credited distance is unaffected either
  /// way.
  Future<StepsSyncResult> sync({
    required SelectedQuest quest,
    required DateTime now,
  }) async {
    final intervalStart = quest.lastSyncedAt;
    final interval = now.difference(intervalStart);
    final delta = await healthAdapter.fetchDelta(intervalStart, now);

    final flagged = isImplausiblePace(steps: delta.steps, interval: interval);

    final deltaMeters = resolveDistanceMeters(
      stepCount: delta.steps,
      walkingDistanceMeters: delta.walkingDistanceMeters,
    );

    // §5.2's real idempotency guarantee: durable, keyed on
    // (ownerId, journeyId, intervalStart), so a replay of this exact
    // interval — from either sync path — is recognized and never credited
    // twice.
    final isNewInterval = await stepSampleRepository.recordInterval(
      ownerId: localOwnerId,
      journeyId: quest.journeyId,
      intervalStart: intervalStart,
      intervalEnd: now,
      steps: delta.steps,
      walkingDistanceMeters: delta.walkingDistanceMeters,
      resolvedMeters: deltaMeters,
      flaggedPace: flagged,
      syncedAt: now,
    );

    final progressMeters = isNewInterval
        ? clampNonDecreasing(
            quest.progressMeters,
            quest.progressMeters + deltaMeters,
          )
        : quest.progressMeters; // already credited — advance the sync
    // window only, per the idempotency guard above.

    return StepsSyncResult(
      progressMeters: progressMeters,
      syncedAt: now,
      flagged: flagged,
    );
  }
}
