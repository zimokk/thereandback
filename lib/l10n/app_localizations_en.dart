// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navJourney => 'Path';

  @override
  String get navQuestStats => 'Map';

  @override
  String get navAchievements => 'Trophies';

  @override
  String get navSettings => 'Settings';

  @override
  String unitMeters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'meters',
      one: 'meter',
    );
    return '$_temp0';
  }

  @override
  String unitKilometers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kilometers',
      one: 'kilometer',
    );
    return '$_temp0';
  }

  @override
  String get journeyCatalogTitle => 'Choose your quest';

  @override
  String get journeyCatalogStartButton => 'Start quest';

  @override
  String journeyDayCounter(int day) {
    return 'Day $day';
  }

  @override
  String get journeyNarrativeComingSoon =>
      'Narrative for this stretch of the road is still being written.';

  @override
  String get stepsPermissionExplainTitle => 'Let your steps move you';

  @override
  String get stepsPermissionExplainBody =>
      'There and Back reads your step and walking-distance data to move your traveler along the route. It never leaves this device except as your total quest progress.';

  @override
  String get stepsPermissionAllow => 'Allow access';

  @override
  String get stepsPermissionDeniedTitle => 'No step data yet';

  @override
  String get stepsPermissionDeniedBody =>
      'Access was denied, so your traveler isn\'t moving yet. You can grant access again anytime.';

  @override
  String get stepsPermissionRetry => 'Try again';

  @override
  String get stepsHealthConnectMissingTitle => 'Health Connect required';

  @override
  String get stepsHealthConnectMissingBody =>
      'Install Health Connect to let your steps move your traveler.';

  @override
  String get stepsHealthConnectInstall => 'Install Health Connect';

  @override
  String questStatsToLabel(String pointB) {
    return 'To $pointB';
  }

  @override
  String get questStatsStartedLabel => 'Quest Started';

  @override
  String get questStatsEtaLabel => 'Estimated Arrival';

  @override
  String get questStatsMapComingSoonTitle => 'Route map';

  @override
  String get questStatsMapComingSoonBody =>
      'The illustrated map for this quest is on its way — check back in a future update.';

  @override
  String get questStatsEmptyTitle => 'No quest yet';

  @override
  String get questStatsEmptyBody =>
      'Start a quest from the Path tab to see its stats here.';

  @override
  String get questStatsEmptyCta => 'Go to Path';

  @override
  String get achievementFirstStepsTitle => 'First Steps';

  @override
  String get achievementHalfDayMarchTitle => 'Half-Day March';

  @override
  String get achievementSeasonedWandererTitle => 'Seasoned Wanderer';

  @override
  String get achievementJourneysEndTitle => 'Journey\'s End';

  @override
  String get achievementUnlockedLabel => 'Unlocked';

  @override
  String achievementRemainingLabel(String amount) {
    return '$amount left';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccountSectionTitle => 'Account';

  @override
  String get settingsSignInButton => 'Sign in';

  @override
  String get settingsSignInSubtitle =>
      'Optional — your progress already works without an account.';

  @override
  String get settingsSignInStubTitle => 'Coming soon';

  @override
  String get settingsSignInStubBody =>
      'Account sign-in isn\'t wired up yet — your quest progress already works without it.';

  @override
  String get settingsSignInStubClose => 'Close';

  @override
  String get settingsLanguageSectionTitle => 'Language';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsLanguageEnglish => 'English';
}
