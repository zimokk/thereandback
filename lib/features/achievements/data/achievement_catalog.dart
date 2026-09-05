import '../domain/achievement.dart';

/// Sample achievement catalog (CLAUDE.md §6.3): editing this list is how a
/// new achievement gets added — no per-achievement branching in a widget.
/// Neutral, non-narrative titles for the milestone entries, since real
/// quest narrative is human-authored content (Phase 11), not code. The
/// `landmarkReached` entries are the one exception, and deliberately so:
/// their thresholds are the exact meters of a landmark in that quest's own
/// `map.json`, and their titles name that landmark — that's not narrative
/// prose, just the same treatment the map screen already gives landmark
/// names (§11, see `quest_map_view.dart`'s "Ahead: {name}" caption). Kept
/// in ascending threshold order so the list itself reads as the route.
///
/// **Scoped per quest since the catalog grew a second one** ("The Road to
/// the Skyfire", 240 000 m, §14 2026-09-05) — [AchievementDef.journeyId]
/// says which quest an entry belongs to, `null` for a generic milestone
/// that applies to any of them (`achievementsForJourney` is what reads
/// this). Before the second quest existed every threshold here happened to
/// exceed any other quest's length, so the absence of scoping never
/// showed; it would have started showing the moment a quest shorter than
/// "half of the Odyssey" existed, which this one is.
const achievementCatalog = <AchievementDef>[
  // Generic milestones — apply to whichever quest is active, reachable on
  // any quest at least this long.
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
    id: 'long-hauler',
    titleKey: 'achievementLongHaulerTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 2000000,
  ),

  // odyssey-ithaca — thresholds are this quest's own landmark meters or a
  // fraction of its 2 850 000 m length, meaningless against any other
  // quest's progress.
  AchievementDef(
    id: 'reached-circe',
    titleKey: 'achievementReachedCirceTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 561921, // Aeaea (Circe) — map.json's "aeaea-circe".
    journeyId: 'odyssey-ithaca',
  ),
  AchievementDef(
    id: 'reached-lotus-eaters',
    titleKey: 'achievementReachedLotusEatersTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 1215166, // map.json's "lotus-eaters".
    journeyId: 'odyssey-ithaca',
  ),
  AchievementDef(
    id: 'halfway-there',
    titleKey: 'achievementHalfwayThereTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 1425000, // Exactly half of the quest's 2 850 000 m.
    journeyId: 'odyssey-ithaca',
  ),
  AchievementDef(
    id: 'reached-calypso',
    titleKey: 'achievementReachedCalypsoTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 1804508, // map.json's "calypso".
    journeyId: 'odyssey-ithaca',
  ),
  AchievementDef(
    id: 'passed-scylla-charybdis',
    titleKey: 'achievementPassedScyllaCharybdisTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 2011461, // map.json's "scylla-charybdis".
    journeyId: 'odyssey-ithaca',
  ),
  AchievementDef(
    id: 'passed-sirens',
    titleKey: 'achievementPassedSirensTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 2465426, // map.json's "sirens".
    journeyId: 'odyssey-ithaca',
  ),
  AchievementDef(
    id: 'journeys-end',
    titleKey: 'achievementJourneysEndTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 2850000,
    journeyId: 'odyssey-ithaca',
  ),

  // tower-of-lights — thresholds are this quest's own landmark meters
  // (`assets/journeys/tower-of-lights/map.json`) or a fraction of its
  // 240 000 m length.
  AchievementDef(
    id: 'left-the-tower',
    titleKey: 'achievementLeftTheTowerTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 20000, // map.json's "005-stone-marker".
    journeyId: 'tower-of-lights',
  ),
  AchievementDef(
    id: 'crossed-the-pines',
    titleKey: 'achievementCrossedThePinesTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 50000, // map.json's "012-last-pine".
    journeyId: 'tower-of-lights',
  ),
  AchievementDef(
    id: 'tower-halfway',
    titleKey: 'achievementTowerHalfwayTitle',
    kind: AchievementKind.distanceReached,
    thresholdMeters: 120000, // Exactly half of the quest's 240 000 m.
    journeyId: 'tower-of-lights',
  ),
  AchievementDef(
    id: 'reached-mountain-gate',
    titleKey: 'achievementReachedMountainGateTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 145000, // map.json's "034-mountain-gate".
    journeyId: 'tower-of-lights',
  ),
  AchievementDef(
    id: 'reached-sea-horizon',
    titleKey: 'achievementReachedSeaHorizonTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 180000, // map.json's "042-sea-horizon".
    journeyId: 'tower-of-lights',
  ),
  AchievementDef(
    id: 'reached-lantern-hill',
    titleKey: 'achievementReachedLanternHillTitle',
    kind: AchievementKind.landmarkReached,
    thresholdMeters: 215000, // map.json's "049-lantern-hill".
    journeyId: 'tower-of-lights',
  ),
  AchievementDef(
    id: 'under-the-skyfire',
    titleKey: 'achievementUnderTheSkyfireTitle',
    kind: AchievementKind.landmarkReached,
    // map.json's "056-under-the-skyfire" — exactly the quest's 240 000 m
    // total, so this is also the completion trophy (contrast
    // odyssey-ithaca's neutrally-titled 'journeys-end': this one is a
    // landmarkReached entry named after the actual final landmark instead,
    // to avoid two different quests' completion trophies sharing the exact
    // same displayed title while the catalog-browsing "no quest selected"
    // preview shows every quest's entries at once).
    thresholdMeters: 240000,
    journeyId: 'tower-of-lights',
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
