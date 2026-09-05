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

    /// `null` — a generic milestone that applies to whichever quest is
    /// active (e.g. "First Steps"); a catalog id — this entry only makes
    /// sense for that one quest (its `landmarkReached` entries above all,
    /// since a threshold there is literally a specific quest's own
    /// landmark meters, but also a `distanceReached` one picked to land on
    /// a specific quest's own milestone, like "halfway through *this*
    /// route"). Added when the catalog grew a second quest (§14,
    /// 2026-09-05) — before that every entry's threshold happened to
    /// exceed any other quest's length, so the absence of scoping never
    /// showed. [achievementsForJourney] is the one place that reads this.
    String? journeyId,
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

/// Narrows [catalog] to what's meaningful for [journeyId] (§14, 2026-09-05 —
/// the catalog now spans more than one quest, and a landmark threshold from
/// one quest is nonsense progress to show against another).
///
/// [journeyId] `null` — no quest selected yet — returns the **whole**
/// [catalog] unchanged, generic and quest-specific entries alike: this is
/// the catalog-browsing preview shown before a quest is even picked
/// (`achievements_tab.dart`'s own "no quest selected" case), where showing
/// every trophy that exists is the point, not a specific one's relevance.
/// Once a quest **is** selected, only its own scoped entries
/// ([AchievementDef.journeyId] equal to it) plus every generic one
/// ([AchievementDef.journeyId] `null`) apply — a different quest's entries
/// are filtered out rather than shown forever-locked, since their thresholds
/// don't describe anything on this route at all.
List<AchievementDef> achievementsForJourney(
  List<AchievementDef> catalog,
  String? journeyId,
) {
  if (journeyId == null) return catalog;
  return catalog
      .where((def) => def.journeyId == null || def.journeyId == journeyId)
      .toList(growable: false);
}
