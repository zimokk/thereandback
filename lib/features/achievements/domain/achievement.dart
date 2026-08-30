import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';

/// A trophy definition: data, not code (CLAUDE.md §6.3). Adding a new
/// achievement means adding an entry to the catalog config, never a new
/// `if` branch in a widget.
///
/// The only condition implemented today is a distance threshold on the
/// current quest. Richer conditions (streaks, landmarks reached, overtaking
/// a friend — §6.3) are represented by [AchievementKind] and can grow
/// without touching [evaluateAchievements]'s call sites, only its `switch`.
@freezed
abstract class AchievementDef with _$AchievementDef {
  const factory AchievementDef({
    required String id,

    /// L10n key for the title — achievement copy is UI text (§11), not
    /// narrative content, so it lives in the ARB files like any other label.
    required String titleKey,
    required AchievementKind kind,
    required int thresholdMeters,
  }) = _AchievementDef;
}

enum AchievementKind {
  /// Unlocked once total quest progress reaches [AchievementDef.thresholdMeters].
  distanceReached,

  /// Unlocked once total quest progress reaches [AchievementDef.thresholdMeters]
  /// — the same rule as [distanceReached], evaluated identically. Kept as
  /// its own variant because the *reason* the threshold unlocks is
  /// different: it names a specific landmark on the route (see the
  /// `-reached`/`passed-` entries in `achievement_catalog.dart`) rather
  /// than an arbitrary milestone, which is worth knowing at the catalog
  /// level even before anything downstream (an icon, a filter) reads it.
  landmarkReached,

  /// Unlocked on any local calendar day whose total walked distance (across
  /// every quest, not the current one — this task's requirement: a daily
  /// fitness milestone, not part of any route's story) reaches
  /// [AchievementDef.thresholdMeters]. Can unlock repeatedly, once per day
  /// it happens — [evaluateAchievements] never evaluates this kind (it only
  /// answers "unlocked against the current cumulative total", which doesn't
  /// apply here); `achievement_unlocks.dart`'s
  /// `computeDailyAchievementUnlockDates` does instead, and
  /// `daily_achievement.dart`'s [DailyAchievementState] carries the result.
  dailyDistance,
}

/// The evaluated state of one achievement for the current user.
@freezed
abstract class AchievementState with _$AchievementState {
  const factory AchievementState({
    required AchievementDef def,
    required bool unlocked,

    /// Meters still needed to unlock; `0` once [unlocked] is true.
    required int remainingMeters,
  }) = _AchievementState;
}

/// Evaluates every achievement in [catalog] against [progressMeters]. Pure
/// and total — one evaluator for the whole catalog, per §6.3.
///
/// Only meant for a catalog of [AchievementKind.distanceReached]/
/// [AchievementKind.landmarkReached] defs (i.e. `achievementCatalog`, never
/// `dailyAchievementCatalog`) — a single cumulative total can't answer
/// "unlocked" for [AchievementKind.dailyDistance], which needs per-day
/// totals instead (see `achievement_unlocks.dart`'s
/// `computeDailyAchievementUnlockDates`). Passing a daily def here is a
/// caller bug, not a case this function silently handles.
List<AchievementState> evaluateAchievements({
  required int progressMeters,
  required List<AchievementDef> catalog,
}) {
  return catalog
      .map((def) {
        switch (def.kind) {
          // Same rule, different reason to unlock — see the doc comment on
          // AchievementKind.landmarkReached.
          case AchievementKind.distanceReached:
          case AchievementKind.landmarkReached:
            final unlocked = progressMeters >= def.thresholdMeters;
            final remaining = unlocked
                ? 0
                : def.thresholdMeters - progressMeters;
            return AchievementState(
              def: def,
              unlocked: unlocked,
              remainingMeters: remaining,
            );
          case AchievementKind.dailyDistance:
            throw ArgumentError.value(
              def,
              'catalog',
              'evaluateAchievements cannot evaluate a dailyDistance def — '
                  'see this function\'s doc comment.',
            );
        }
      })
      .toList(growable: false);
}
