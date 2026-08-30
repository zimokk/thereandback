import 'package:freezed_annotation/freezed_annotation.dart';

import 'achievement.dart';

part 'daily_achievement.freezed.dart';

/// The evaluated state of one [AchievementKind.dailyDistance] achievement —
/// unlike [AchievementState], there is no single "unlocked" bool and
/// "remaining" number, because a daily achievement can be earned more than
/// once (once per calendar day its threshold is reached, §6.3 extended by
/// this task's "daily trophies" requirement).
@freezed
abstract class DailyAchievementState with _$DailyAchievementState {
  const DailyAchievementState._();

  const factory DailyAchievementState({
    required AchievementDef def,

    /// Every local calendar day this threshold was reached, ascending.
    /// Empty means never reached. Built directly from
    /// `AchievementRepository.loadUnlocks` (this task's requirement —
    /// trophies persisted in the DB) via [buildDailyAchievementStates],
    /// never recomputed live from raw step history in presentation code.
    required List<DateTime> unlockedDates,
  }) = _DailyAchievementState;

  bool get unlocked => unlockedDates.isNotEmpty;

  /// How many distinct days this was earned — the count the Трофеи tab
  /// badges when it's more than one (this task's requirement: "если
  /// получено больше 1 — показывать число полученных").
  int get unlockedCount => unlockedDates.length;
}

/// Builds a [DailyAchievementState] for every def in [catalog] from
/// [unlocks] (an achievement id → sorted unlock dates map, as
/// `AchievementRepository.loadUnlocks` returns it) — a catalog entry with no
/// matching key gets an empty [DailyAchievementState.unlockedDates], not an
/// absent entry, so the Трофеи grid always has one tile per catalog def
/// regardless of what's been earned yet.
List<DailyAchievementState> buildDailyAchievementStates({
  required List<AchievementDef> catalog,
  required Map<String, List<DateTime>> unlocks,
}) {
  return [
    for (final def in catalog)
      DailyAchievementState(
        def: def,
        unlockedDates: unlocks[def.id] ?? const [],
      ),
  ];
}
