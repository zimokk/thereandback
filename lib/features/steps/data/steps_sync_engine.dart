import '../../../core/local_owner.dart';
import '../../achievements/data/achievement_repository.dart';
import '../../journey/domain/quest_selection.dart';
import '../domain/stride.dart';
import 'step_counting_service.dart';
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
/// No platform-channel or Riverpod dependency here — just the
/// step-counting service and the drift-backed idempotency log, both
/// already interface-typed for testing (`testing` skill).
class StepsSyncEngine {
  StepsSyncEngine({
    required this.stepCountingService,
    required this.stepSampleRepository,
    required this.achievementRepository,
  });

  final StepCountingService stepCountingService;
  final StepSampleRepository stepSampleRepository;

  /// Recomputes trophy unlock dates after a newly-credited interval (this
  /// task's requirement — trophies persisted in the DB). Injected the same
  /// way [stepSampleRepository] is, so both the foreground sync
  /// (`steps_providers.dart`) and the Android background task
  /// (`android_background_sync.dart`) go through the exact same code —
  /// consistent with the rest of this engine's "one path for both callers"
  /// design (see the class doc comment).
  final AchievementRepository achievementRepository;

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
    final delta = await stepCountingService.fetchDelta(intervalStart, now);

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

    // Only worth recomputing when the history this reads actually changed —
    // a replayed/duplicate interval (isNewInterval == false) leaves it
    // identical to the last run's answer.
    if (isNewInterval) {
      await achievementRepository.refreshUnlocks(
        ownerId: localOwnerId,
        journeyId: quest.journeyId,
      );
    }

    // Re-derived from the steps database itself, not computed as
    // `quest.progressMeters + deltaMeters` — `quest` is caller-supplied
    // (the foreground path passes whatever's currently in
    // `selectedJourneyProvider`'s in-memory state) and can be stale
    // relative to what's actually recorded, e.g. right after the Android
    // background-sync task (`android_background_sync.dart`) wrote new
    // intervals directly to the database while this app process wasn't
    // running to see them. `clampNonDecreasing` against the caller's own
    // `quest.progressMeters` is still the final word — never *less* than
    // what the caller already believed — but the database's fresh total
    // wins whenever it's the bigger of the two (this task's requirement:
    // "если в базе данных шагов больше — выбираем большее значение").
    final dbTotal = await stepSampleRepository.totalResolvedMeters(
      ownerId: localOwnerId,
      journeyId: quest.journeyId,
    );
    final progressMeters = clampNonDecreasing(quest.progressMeters, dbTotal);

    return StepsSyncResult(
      progressMeters: progressMeters,
      syncedAt: now,
      flagged: flagged,
    );
  }
}
