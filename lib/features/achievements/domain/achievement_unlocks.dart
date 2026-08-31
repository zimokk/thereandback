import '../../journey/domain/quest_time_service.dart'
    show MeteredInterval, calendarDate;
import 'achievement.dart';

/// Sums [intervals]' meters per local calendar day (§5.3's calendar-day
/// convention) — what [computeDailyAchievementUnlockDates] needs: "how much
/// was walked on this day", not a cumulative running total.
Map<DateTime, int> groupMetersByLocalDay(List<MeteredInterval> intervals) {
  final totals = <DateTime, int>{};
  for (final interval in intervals) {
    final day = calendarDate(interval.end);
    totals[day] = (totals[day] ?? 0) + interval.meters;
  }
  return totals;
}

/// For every def in [catalog] (a [AchievementDef.kind] of
/// [AchievementKind.distanceReached]/[AchievementKind.landmarkReached]),
/// finds the local calendar date the *cumulative* sum of
/// [orderedIntervals] first reached its threshold — the "which day was this
/// earned" this task's requirement needs, derived from the full interval
/// history rather than tracked as separate mutable state (§5.2's own
/// "derive, don't duplicate" rule, extended here to achievement dates).
///
/// [orderedIntervals] must be sorted ascending by [MeteredInterval.end] —
/// callers pass the *entire* history for one (owner, journey), not just a
/// recent window, since an old threshold's unlock day could be arbitrarily
/// far in the past. A def already present in the caller's persisted unlocks
/// still gets recomputed here (recomputing is cheap and always correct);
/// the repository's `insertOrIgnore` write is what makes re-deriving the
/// same answer twice harmless.
Map<String, DateTime> computeJourneyAchievementUnlockDates({
  required List<MeteredInterval> orderedIntervals,
  required List<AchievementDef> catalog,
}) {
  final unlocks = <String, DateTime>{};
  var cumulative = 0;
  for (final interval in orderedIntervals) {
    cumulative += interval.meters;
    if (unlocks.length == catalog.length) break; // everything found already.
    final day = calendarDate(interval.end);
    for (final def in catalog) {
      if (unlocks.containsKey(def.id)) continue;
      if (cumulative >= def.thresholdMeters) {
        unlocks[def.id] = day;
      }
    }
  }
  return unlocks;
}

/// For every def in [catalog] (a [AchievementKind.dailyDistance] catalog —
/// `achievement_catalog.dart`'s `dailyAchievementCatalog`), finds every day
/// in [dailyTotals] whose total met the threshold — a daily achievement can
/// be earned repeatedly, once per qualifying day (this task's requirement),
/// unlike [computeJourneyAchievementUnlockDates]'s single date.
Map<String, List<DateTime>> computeDailyAchievementUnlockDates({
  required Map<DateTime, int> dailyTotals,
  required List<AchievementDef> catalog,
}) {
  final unlocks = <String, List<DateTime>>{};
  for (final def in catalog) {
    final dates = [
      for (final entry in dailyTotals.entries)
        if (entry.value >= def.thresholdMeters) entry.key,
    ]..sort();
    if (dates.isNotEmpty) unlocks[def.id] = dates;
  }
  return unlocks;
}

/// Length of every run of consecutive calendar days in [unlockedDates] —
/// e.g. three unlock dates in a row, then a gap, then one more, is `[3, 1]`.
/// Shared by [currentStreak] (the last run) and [longestStreak] (the
/// longest run) so there is exactly one place deciding what "consecutive"
/// means (this task's requirement — "стрик"/"самый долгий стрик").
///
/// [unlockedDates] need not be sorted or pre-normalized — this is the one
/// place both happen, so [currentStreak]/[longestStreak] can hand it
/// whatever `DailyAchievementState.unlockedDates` already is.
List<int> _streakRuns(List<DateTime> unlockedDates) {
  if (unlockedDates.isEmpty) return const [];
  final sorted = [for (final date in unlockedDates) calendarDate(date)]..sort();

  final runs = <int>[1];
  for (var i = 1; i < sorted.length; i++) {
    final gap = sorted[i].difference(sorted[i - 1]).inDays;
    // A repeated date shouldn't happen (`computeDailyAchievementUnlockDates`
    // builds this list from a map's keys, which are already distinct days)
    // but is handled defensively as "still the same day", not a new one —
    // only a real gap (`gap > 1`) starts a new run.
    if (gap == 0) continue;
    if (gap == 1) {
      runs[runs.length - 1]++;
    } else {
      runs.add(1);
    }
  }
  return runs;
}

/// How many calendar days in a row [unlockedDates] were unlocked on, ending
/// at the most recent one (this task's requirement — "сколько дней подряд
/// достижение открыто"). `0` for a never-unlocked achievement, `1` for one
/// earned on a single day with no earlier day immediately before it.
///
/// Doesn't take "today" into account — an unlock three weeks ago that was
/// itself the tail of a 5-day run still reads as a streak of 5, not 0, the
/// same way the rest of this file derives everything from the persisted
/// unlock record rather than from the live clock (§5.2's "derive, don't
/// duplicate" rule).
int currentStreak(List<DateTime> unlockedDates) {
  final runs = _streakRuns(unlockedDates);
  return runs.isEmpty ? 0 : runs.last;
}

/// The longest run of consecutive calendar days anywhere in [unlockedDates]
/// — not just the most recent one (see [currentStreak] for that) — shown
/// in the achievement details sheet alongside the plain unlock-dates list
/// (this task's requirement — "показывать... самый долгий стрик").
int longestStreak(List<DateTime> unlockedDates) {
  final runs = _streakRuns(unlockedDates);
  return runs.isEmpty ? 0 : runs.reduce((a, b) => a > b ? a : b);
}
