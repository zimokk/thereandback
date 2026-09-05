import '../../../l10n/app_localizations.dart';
import '../domain/achievement.dart';

/// Resolves an [AchievementDef.titleKey] to its localized copy (§11 — no
/// hardcoded UI strings). Shared by the Трофеи grid (`achievements_tab.dart`)
/// and the Путь tab's marker-tap details (`journey_path_view.dart`), so the
/// two screens can never disagree on what a given achievement is called —
/// there is exactly one switch mapping key to string.
String achievementTitle(AppLocalizations l10n, AchievementDef def) {
  return switch (def.titleKey) {
    'achievementFirstStepsTitle' => l10n.achievementFirstStepsTitle,
    'achievementFirstLeagueTitle' => l10n.achievementFirstLeagueTitle,
    'achievementHalfDayMarchTitle' => l10n.achievementHalfDayMarchTitle,
    'achievementCenturyMarkTitle' => l10n.achievementCenturyMarkTitle,
    'achievementSeasonedWandererTitle' => l10n.achievementSeasonedWandererTitle,
    'achievementReachedCirceTitle' => l10n.achievementReachedCirceTitle,
    'achievementReachedLotusEatersTitle' =>
      l10n.achievementReachedLotusEatersTitle,
    'achievementHalfwayThereTitle' => l10n.achievementHalfwayThereTitle,
    'achievementReachedCalypsoTitle' => l10n.achievementReachedCalypsoTitle,
    'achievementLongHaulerTitle' => l10n.achievementLongHaulerTitle,
    'achievementPassedScyllaCharybdisTitle' =>
      l10n.achievementPassedScyllaCharybdisTitle,
    'achievementPassedSirensTitle' => l10n.achievementPassedSirensTitle,
    'achievementJourneysEndTitle' => l10n.achievementJourneysEndTitle,
    'achievementLeftTheTowerTitle' => l10n.achievementLeftTheTowerTitle,
    'achievementCrossedThePinesTitle' => l10n.achievementCrossedThePinesTitle,
    'achievementTowerHalfwayTitle' => l10n.achievementTowerHalfwayTitle,
    'achievementReachedMountainGateTitle' =>
      l10n.achievementReachedMountainGateTitle,
    'achievementReachedSeaHorizonTitle' =>
      l10n.achievementReachedSeaHorizonTitle,
    'achievementReachedLanternHillTitle' =>
      l10n.achievementReachedLanternHillTitle,
    'achievementUnderTheSkyfireTitle' => l10n.achievementUnderTheSkyfireTitle,
    'achievementDaily1kmTitle' => l10n.achievementDaily1kmTitle,
    'achievementDaily5kmTitle' => l10n.achievementDaily5kmTitle,
    'achievementDaily10kmTitle' => l10n.achievementDaily10kmTitle,
    'achievementDaily20kmTitle' => l10n.achievementDaily20kmTitle,
    'achievementDaily50kmTitle' => l10n.achievementDaily50kmTitle,
    _ => def.titleKey,
  };
}
