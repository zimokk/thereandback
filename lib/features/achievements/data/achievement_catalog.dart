import '../domain/achievement.dart';

/// Sample achievement catalog (CLAUDE.md §6.3): editing this list is how a
/// new achievement gets added — no per-achievement branching in a widget.
/// Thresholds are picked against the Odyssey quest's 2 850 000 m length
/// (`journey_catalog.dart`); neutral, non-narrative titles, since real quest
/// narrative is human-authored content (Phase 11), not code.
const achievementCatalog = <AchievementDef>[
  AchievementDef(
    id: 'first-steps',
    titleKey: 'achievementFirstStepsTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 1000,
  ),
  AchievementDef(
    id: 'half-day-march',
    titleKey: 'achievementHalfDayMarchTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 50000,
  ),
  AchievementDef(
    id: 'seasoned-wanderer',
    titleKey: 'achievementSeasonedWandererTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 500000,
  ),
  AchievementDef(
    id: 'journeys-end',
    titleKey: 'achievementJourneysEndTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 2850000,
  ),
];
