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
