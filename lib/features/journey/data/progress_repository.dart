import 'package:drift/drift.dart';

import '../../../data/drift/database.dart';
import '../domain/quest_selection.dart';
import '../domain/quest_time_service.dart';

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

  /// Synced intervals for [journeyId] ending at or after [since], reduced to
  /// what `QuestTimeService.paceMetersPerDay` needs (§5.3's 7-day rolling
  /// pace). Callers should pass a [since] a little wider than the 7
  /// calendar days they actually need — this method does no calendar-day
  /// math itself, it only filters by UTC instant; the exact local-day
  /// windowing happens in `domain/` (§13: layer purity — the query lives
  /// here, the math there).
  Future<List<MeteredInterval>> recentMeteredIntervals(
    String ownerId, {
    required String journeyId,
    required DateTime since,
  });

  /// Replaces [ownerId]'s local progress on [journeyId] with a cloud total
  /// (§8, §14 — "repeat login": `AuthController` calls this only when the
  /// account being switched to has *more* progress than this device's own
  /// local drift, never as a blind overwrite).
  ///
  /// Deletes this owner+journey's existing [StepIntervalRecords] first —
  /// otherwise their `resolvedMeters` would keep summing alongside the
  /// seeded total below and double-count. Then seeds a single interval
  /// (`[startedAt, asOf]` → [meters]) so `loadSelectedQuest`'s derived sum
  /// equals [meters] and `lastSyncedAt` becomes [asOf] — the next real sync
  /// continues forward from there without colliding with this seed row's
  /// idempotency key `(ownerId, journeyId, intervalStart)` (§5.2).
  ///
  /// Skips the seed row entirely when [meters] is `0`: seeding `[startedAt,
  /// asOf]` for a zero total would still set `lastSyncedAt = asOf`, and the
  /// very next real sync's interval always starts at `lastSyncedAt` — so a
  /// seeded [asOf] would collide with that first real interval's own
  /// `intervalStart` and get silently dropped by `insertOrIgnore`.
  /// `loadSelectedQuest`'s own fallback (`lastSyncedAt ?? startedAtLocal`)
  /// already handles "no interval yet" correctly with no seed at all.
  Future<void> restoreFromCloud(
    String ownerId, {
    required String journeyId,
    required DateTime startedAt,
    required int meters,
    required DateTime asOf,
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

    // No synced interval yet: seed to the exact moment the quest was
    // started (§5.2) — same as `start()` sets in-memory, kept in sync
    // deliberately rather than persisted twice.
    return SelectedQuest(
      journeyId: row.journeyId,
      startedAt: startedAtLocal,
      lastSyncedAt: latest?.intervalEnd.toLocal() ?? startedAtLocal,
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

  @override
  Future<List<MeteredInterval>> recentMeteredIntervals(
    String ownerId, {
    required String journeyId,
    required DateTime since,
  }) async {
    final intervals = _db.stepIntervalRecords;
    final rows =
        await (_db.select(intervals)..where(
              (t) =>
                  t.ownerId.equals(ownerId) &
                  t.journeyId.equals(journeyId) &
                  t.intervalEnd.isBiggerOrEqualValue(since.toUtc()),
            ))
            .get();

    return [
      for (final row in rows)
        MeteredInterval(
          end: row.intervalEnd.toLocal(),
          meters: row.resolvedMeters,
        ),
    ];
  }

  @override
  Future<void> restoreFromCloud(
    String ownerId, {
    required String journeyId,
    required DateTime startedAt,
    required int meters,
    required DateTime asOf,
  }) {
    final startedAtUtc = startedAt.toUtc();
    final asOfUtc = asOf.toUtc();

    return _db.transaction(() async {
      await (_db.delete(_db.stepIntervalRecords)..where(
            (t) => t.ownerId.equals(ownerId) & t.journeyId.equals(journeyId),
          ))
          .go();

      await _db
          .into(_db.selectedQuestRows)
          .insertOnConflictUpdate(
            SelectedQuestRowsCompanion.insert(
              ownerId: ownerId,
              journeyId: journeyId,
              startedAt: startedAtUtc,
            ),
          );

      if (meters > 0) {
        await _db
            .into(_db.stepIntervalRecords)
            .insert(
              StepIntervalRecordsCompanion.insert(
                ownerId: ownerId,
                journeyId: journeyId,
                intervalStart: startedAtUtc,
                intervalEnd: asOfUtc,
                steps: 0,
                resolvedMeters: meters,
                syncedAt: asOfUtc,
              ),
            );
      }
    });
  }
}
