import 'package:drift/drift.dart';

import '../../../data/drift/database.dart';
import '../domain/quest_selection.dart';

/// Durable storage for the single active [SelectedQuest] per local owner
/// (CLAUDE.md §5.2, §8) — the drift-backed replacement for the in-memory
/// -only state `journey_providers.dart` held before Phase 3 landed
/// (see `docs/screens/steps-sync.md`'s former "idempotency caveat").
///
/// `progressMeters` and `lastSyncedAt` are **derived** from
/// `StepIntervalRecords` (§5.2: "work with deltas, not an accumulated
/// total") rather than stored as their own mutable fields — see
/// `data/drift/database.dart`'s doc comment on `SelectedQuestRows` for why.
///
/// All timestamps cross this boundary as UTC on the way in and local time
/// on the way out — callers in `domain/`/`presentation/` never see UTC.
abstract class ProgressRepository {
  /// The persisted quest for [ownerId], or `null` if none was ever started.
  Future<SelectedQuest?> loadSelectedQuest(String ownerId);

  /// Persists a freshly started quest, replacing any previously active one
  /// for [ownerId] (§6.4: no concurrent multi-quest in MVP).
  Future<void> startQuest(
    String ownerId, {
    required String journeyId,
    required DateTime startedAt,
  });
}

class DriftProgressRepository implements ProgressRepository {
  DriftProgressRepository(this._db);

  final AppDatabase _db;

  @override
  Future<SelectedQuest?> loadSelectedQuest(String ownerId) async {
    final row = await (_db.select(
      _db.selectedQuestRows,
    )..where((t) => t.ownerId.equals(ownerId))).getSingleOrNull();
    if (row == null) return null;

    final startedAtLocal = row.startedAt.toLocal();
    final intervals = _db.stepIntervalRecords;
    final matchesQuest =
        intervals.ownerId.equals(ownerId) &
        intervals.journeyId.equals(row.journeyId);

    final sumQuery = _db.selectOnly(intervals)
      ..addColumns([intervals.resolvedMeters.sum()])
      ..where(matchesQuest);
    final progressMeters =
        (await sumQuery.getSingle()).read(intervals.resolvedMeters.sum()) ?? 0;

    // Deliberately *not* `intervals.intervalEnd.max()`: drift's DateTime
    // aggregate goes through a whole-second `unixepoch()` round trip and
    // would truncate this to second precision. Reading the actual latest
    // row instead keeps the full stored precision.
    final latest =
        await (_db.select(intervals)
              ..where((_) => matchesQuest)
              ..orderBy([(t) => OrderingTerm.desc(t.intervalEnd)])
              ..limit(1))
            .getSingleOrNull();

    // No synced interval yet: seed to the start of the local calendar day
    // the quest was started (§5.2) — same formula `start()` uses, kept in
    // sync deliberately rather than persisted twice.
    final seededLastSyncedAt = DateTime(
      startedAtLocal.year,
      startedAtLocal.month,
      startedAtLocal.day,
    );

    return SelectedQuest(
      journeyId: row.journeyId,
      startedAt: startedAtLocal,
      lastSyncedAt: latest?.intervalEnd.toLocal() ?? seededLastSyncedAt,
      progressMeters: progressMeters,
    );
  }

  @override
  Future<void> startQuest(
    String ownerId, {
    required String journeyId,
    required DateTime startedAt,
  }) {
    return _db
        .into(_db.selectedQuestRows)
        .insertOnConflictUpdate(
          SelectedQuestRowsCompanion.insert(
            ownerId: ownerId,
            journeyId: journeyId,
            startedAt: startedAt.toUtc(),
          ),
        );
  }
}
