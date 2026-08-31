import 'package:drift/drift.dart';

import '../../../data/drift/database.dart';
import '../../journey/domain/quest_time_service.dart'
    show MeteredInterval, calendarDate;
import '../domain/achievement_unlocks.dart';
import 'achievement_catalog.dart';

/// Durable storage for trophy unlock dates (§6.3, extended by the daily-
/// trophies task) — the drift-backed source `achievements_providers.dart`
/// reads instead of recomputing "when was this earned" live on every
/// Трофеи tab open.
abstract class AchievementRepository {
  /// Recomputes every quest and daily achievement unlock from the full
  /// interval history and durably records any newly-crossed ones.
  /// `insertOrIgnore` makes this idempotent (§5.2's own idempotency habit,
  /// extended to achievement dates) — safe to call after every sync,
  /// including a sync that crossed nothing new, and safe to call once after
  /// this feature ships to backfill every threshold already crossed before
  /// it existed, since it re-derives from the append-only
  /// `StepIntervalRecords` history rather than tracking a delta.
  Future<void> refreshUnlocks({
    required String ownerId,
    required String journeyId,
  });

  /// Every persisted unlock for [ownerId], grouped by achievement id — at
  /// most one date for a quest achievement, potentially several (sorted
  /// ascending) for a daily one. A missing key means never earned.
  Future<Map<String, List<DateTime>>> loadUnlocks(String ownerId);

  /// Total meters walked across every quest so far today (local calendar
  /// day, §5.3) — what a daily trophy's progress line needs (this task's
  /// requirement: "для ежедневных — прогресс за сегодняшний день"), unlike
  /// [loadUnlocks], which only knows about days that already crossed a
  /// threshold. Recomputed live from [StepIntervalRecords] rather than
  /// [AchievementUnlockRows] — today not yet reaching any threshold still
  /// has no persisted unlock row to read a partial number from.
  Future<int> todayTotalMeters(String ownerId);
}

class DriftAchievementRepository implements AchievementRepository {
  DriftAchievementRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> refreshUnlocks({
    required String ownerId,
    required String journeyId,
  }) async {
    final intervals = _db.stepIntervalRecords;

    // Quest achievements: this quest's own history only — its thresholds
    // (e.g. "journeys-end") are this specific route's own length.
    final journeyRows =
        await (_db.select(intervals)
              ..where(
                (t) =>
                    t.ownerId.equals(ownerId) & t.journeyId.equals(journeyId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.intervalEnd)]))
            .get();
    final journeyIntervals = [
      for (final row in journeyRows)
        MeteredInterval(
          end: row.intervalEnd.toLocal(),
          meters: row.resolvedMeters,
        ),
    ];
    final journeyUnlocks = computeJourneyAchievementUnlockDates(
      orderedIntervals: journeyIntervals,
      catalog: achievementCatalog,
    );

    // Daily achievements: every step this owner has ever recorded, across
    // every quest — a daily fitness milestone, not tied to one quest's
    // story (this task's requirement).
    final allRows = await (_db.select(
      intervals,
    )..where((t) => t.ownerId.equals(ownerId))).get();
    final allIntervals = [
      for (final row in allRows)
        MeteredInterval(
          end: row.intervalEnd.toLocal(),
          meters: row.resolvedMeters,
        ),
    ];
    final dailyUnlocks = computeDailyAchievementUnlockDates(
      dailyTotals: groupMetersByLocalDay(allIntervals),
      catalog: dailyAchievementCatalog,
    );

    if (journeyUnlocks.isEmpty && dailyUnlocks.isEmpty) return;

    await _db.batch((batch) {
      for (final entry in journeyUnlocks.entries) {
        batch.insert(
          _db.achievementUnlockRows,
          AchievementUnlockRowsCompanion.insert(
            ownerId: ownerId,
            achievementId: entry.key,
            unlockedLocalDate: _toStorable(entry.value),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final entry in dailyUnlocks.entries) {
        for (final date in entry.value) {
          batch.insert(
            _db.achievementUnlockRows,
            AchievementUnlockRowsCompanion.insert(
              ownerId: ownerId,
              achievementId: entry.key,
              unlockedLocalDate: _toStorable(date),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  @override
  Future<Map<String, List<DateTime>>> loadUnlocks(String ownerId) async {
    final rows =
        await (_db.select(_db.achievementUnlockRows)
              ..where((t) => t.ownerId.equals(ownerId))
              ..orderBy([(t) => OrderingTerm.asc(t.unlockedLocalDate)]))
            .get();

    final result = <String, List<DateTime>>{};
    for (final row in rows) {
      (result[row.achievementId] ??= []).add(
        _fromStorable(row.unlockedLocalDate),
      );
    }
    return result;
  }

  @override
  Future<int> todayTotalMeters(String ownerId) async {
    final intervals = _db.stepIntervalRecords;
    final today = calendarDate(DateTime.now());

    // A day of margin covers any timezone offset between UTC storage and
    // the user's local calendar day — the same wide-window-then-exact-
    // domain-math idiom `journey_providers.dart`'s `recentMeteredIntervals`
    // uses (§13: the query lives here in `data/`, the calendar math in
    // `domain/`'s `groupMetersByLocalDay`).
    final since = today.subtract(const Duration(days: 1)).toUtc();
    final rows =
        await (_db.select(intervals)..where(
              (t) =>
                  t.ownerId.equals(ownerId) &
                  t.intervalEnd.isBiggerOrEqualValue(since),
            ))
            .get();
    final todaysIntervals = [
      for (final row in rows)
        MeteredInterval(
          end: row.intervalEnd.toLocal(),
          meters: row.resolvedMeters,
        ),
    ];
    return groupMetersByLocalDay(todaysIntervals)[today] ?? 0;
  }

  /// Encodes a local calendar date ([AchievementUnlockRows.unlockedLocalDate]'s
  /// doc comment) as its own year/month/day at UTC midnight — never a real
  /// UTC instant conversion (`.toUtc()` would shift the date whenever the
  /// local offset isn't zero), so the exact calendar day survives storage
  /// unchanged.
  DateTime _toStorable(DateTime localCalendarDate) => DateTime.utc(
    localCalendarDate.year,
    localCalendarDate.month,
    localCalendarDate.day,
  );

  /// The inverse of [_toStorable] — reads the year/month/day back out as a
  /// local-flavored calendar date. Never `.toLocal()`, which would apply a
  /// UTC-offset shift this column was never storing an instant for.
  DateTime _fromStorable(DateTime stored) =>
      DateTime(stored.year, stored.month, stored.day);
}
