import 'package:drift/drift.dart';

import '../../../data/drift/database.dart';

/// Records synced step intervals durably and enforces the CLAUDE.md §5.2
/// idempotency key `(ownerId, journeyId, intervalStart)` — this is what
/// makes "a repeated sync of the same interval never doubles progress" true
/// across app restarts, not just within one running session.
abstract class StepSampleRepository {
  /// Records one synced interval. Returns `true` if this interval was newly
  /// recorded — safe to credit its [resolvedMeters] to progress — or
  /// `false` if `(ownerId, journeyId, intervalStart)` was already recorded,
  /// in which case the caller must **not** credit progress again.
  Future<bool> recordInterval({
    required String ownerId,
    required String journeyId,
    required DateTime intervalStart,
    required DateTime intervalEnd,
    required int steps,
    int? walkingDistanceMeters,
    required int resolvedMeters,
    required bool flaggedPace,
    required DateTime syncedAt,
  });
}

class DriftStepSampleRepository implements StepSampleRepository {
  DriftStepSampleRepository(this._db);

  final AppDatabase _db;

  @override
  Future<bool> recordInterval({
    required String ownerId,
    required String journeyId,
    required DateTime intervalStart,
    required DateTime intervalEnd,
    required int steps,
    int? walkingDistanceMeters,
    required int resolvedMeters,
    required bool flaggedPace,
    required DateTime syncedAt,
  }) async {
    final inserted = await _db
        .into(_db.stepIntervalRecords)
        .insertReturningOrNull(
          StepIntervalRecordsCompanion.insert(
            ownerId: ownerId,
            journeyId: journeyId,
            intervalStart: intervalStart.toUtc(),
            intervalEnd: intervalEnd.toUtc(),
            steps: steps,
            walkingDistanceMeters: Value(walkingDistanceMeters),
            resolvedMeters: resolvedMeters,
            flaggedPace: Value(flaggedPace),
            syncedAt: syncedAt.toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return inserted != null;
  }
}
