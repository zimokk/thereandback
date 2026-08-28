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
    _ => def.titleKey,
  };
}
