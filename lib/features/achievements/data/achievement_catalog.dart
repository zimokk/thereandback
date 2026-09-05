import '../domain/achievement.dart';

/// Sample achievement catalog (CLAUDE.md §6.3): editing this list is how a
/// new achievement gets added — no per-achievement branching in a widget.
/// Thresholds are picked against the Odyssey quest's 2 850 000 m length
/// (`journey_catalog.dart`); neutral, non-narrative titles for the
/// milestone entries, since real quest narrative is human-authored content
/// (Phase 11), not code. The `landmarkReached` entries are the one
/// exception, and deliberately so: their thresholds are the exact meters of
/// a landmark in `assets/journeys/odyssey-ithaca/map.json`, and their
/// titles name that landmark — that's not narrative prose, just the same
/// treatment the map screen already gives landmark names (§11, see
/// `quest_map_view.dart`'s "Ahead: {name}" caption). Kept in ascending
/// threshold order so the list itself reads as the route.
///
/// **Known gap since the second catalog quest ("The Road to the Skyfire",
/// 240 000 m, §14 2026-09-05):** this list is not scoped per quest —
/// `evaluateAchievements` compares whichever quest is active's raw meters
/// against these same absolute thresholds regardless of which journey they
/// were authored against. In practice that means every Odyssey-specific
/// entry above 240 000 m (most of this list, and every `landmarkReached`
/// entry) can simply never unlock while playing the shorter quest — not a
/// crash, just achievements that never fire for it. Not fixed here: giving
/// achievements a real per-quest scope is a larger design change (§13 wants
/// a plan first), tracked as an open item in CLAUDE.md §14.
const achievementCatalog = <AchievementDef>[
  AchievementDef(
    id: 'first-steps',
    titleKey: 'achievementFirstStepsTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 1000,
  ),
  AchievementDef(
    id: 'first-league',
    titleKey: 'achievementFirstLeagueTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 10000,
  ),
  AchievementDef(
    id: 'half-day-march',
    titleKey: 'achievementHalfDayMarchTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 50000,
  ),
  AchievementDef(
    id: 'century-mark',
    titleKey: 'achievementCenturyMarkTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 100000,
  ),
  AchievementDef(
    id: 'seasoned-wanderer',
    titleKey: 'achievementSeasonedWandererTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 500000,
  ),
  AchievementDef(
    id: 'reached-circe',
    titleKey: 'achievementReachedCirceTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 561921, // Aeaea (Circe) — map.json's "aeaea-circe".
  ),
  AchievementDef(
    id: 'reached-lotus-eaters',
    titleKey: 'achievementReachedLotusEatersTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 1215166, // map.json's "lotus-eaters".
  ),
  AchievementDef(
    id: 'halfway-there',
    titleKey: 'achievementHalfwayThereTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 1425000, // Exactly half of the quest's 2 850 000 m.
  ),
  AchievementDef(
    id: 'reached-calypso',
    titleKey: 'achievementReachedCalypsoTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 1804508, // map.json's "calypso".
  ),
  AchievementDef(
    id: 'long-hauler',
    titleKey: 'achievementLongHaulerTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 2000000,
  ),
  AchievementDef(
    id: 'passed-scylla-charybdis',
    titleKey: 'achievementPassedScyllaCharybdisTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 2011461, // map.json's "scylla-charybdis".
  ),
  AchievementDef(
    id: 'passed-sirens',
    titleKey: 'achievementPassedSirensTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 2465426, // map.json's "sirens".
  ),
  AchievementDef(
    id: 'journeys-end',
    titleKey: 'achievementJourneysEndTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 2850000,
  ),
];

/// Daily trophies (this task's requirement): a local calendar day's *total*
/// walked distance, across every quest — not part of any route's story
/// (§6.3 extended), evaluated by
/// `achievement_unlocks.dart`'s `computeDailyAchievementUnlockDates`, never
/// by `evaluateAchievements`. Shown in the Трофеи tab's own "Каждый день"
/// section, separate from [achievementCatalog]'s quest trophies.
const dailyAchievementCatalog = <AchievementDef>[
  AchievementDef(
    id: 'daily-1km',
    titleKey: 'achievementDaily1kmTitle',
    kind: AchievementKind.dailyDistance,
    thresholdMeters: 1000,
  ),
  AchievementDef(
    id: 'daily-5km',
    titleKey: 'achievementDaily5kmTitle',
    kind: AchievementKind.dailyDistance,
    thresholdMeters: 5000,
  ),
  AchievementDef(
    id: 'daily-10km',
    titleKey: 'achievementDaily10kmTitle',
    kind: AchievementKind.dailyDistance,
    thresholdMeters: 10000,
  ),
  AchievementDef(
    id: 'daily-20km',
    titleKey: 'achievementDaily20kmTitle',
    kind: AchievementKind.dailyDistance,
    thresholdMeters: 20000,
  ),
  AchievementDef(
    id: 'daily-50km',
    titleKey: 'achievementDaily50kmTitle',
    kind: AchievementKind.dailyDistance,
    thresholdMeters: 50000,
  ),
];
