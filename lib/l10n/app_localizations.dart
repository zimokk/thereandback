import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Bottom nav label for the Путь (journey) tab
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get navJourney;

  /// Bottom nav label for the quest stats / progress tab
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navQuestStats;

  /// Bottom nav label for the achievements tab
  ///
  /// In en, this message translates to:
  /// **'Trophies'**
  String get navAchievements;

  /// Bottom nav label for the settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Unit label under a distance shown in meters (§5.4)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{meter} other{meters}}'**
  String unitMeters(int count);

  /// Unit label under a distance shown in kilometers (§5.4)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{kilometer} other{kilometers}}'**
  String unitKilometers(num count);

  /// Heading over the quest catalog when no quest is selected
  ///
  /// In en, this message translates to:
  /// **'Choose your quest'**
  String get journeyCatalogTitle;

  /// Button on a catalog card that starts that quest
  ///
  /// In en, this message translates to:
  /// **'Start quest'**
  String get journeyCatalogStartButton;

  /// Quest-day counter on the Путь tab; a label, not a count of days, so it never pluralizes (§5.3)
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String journeyDayCounter(int day);

  /// Empty-state line shown where a NarrativeBeat will render once quest content exists (Phase 11) — this is a UI empty state, not quest narrative itself (§11)
  ///
  /// In en, this message translates to:
  /// **'Narrative for this stretch of the road is still being written.'**
  String get journeyNarrativeComingSoon;

  /// Title of the card explaining why step access is requested, shown before the OS prompt (§7)
  ///
  /// In en, this message translates to:
  /// **'Let your steps move you'**
  String get stepsPermissionExplainTitle;

  /// Body of the pre-permission explanation card
  ///
  /// In en, this message translates to:
  /// **'There and Back reads your step and walking-distance data to move your traveler along the route. It never leaves this device except as your total quest progress.'**
  String get stepsPermissionExplainBody;

  /// Button that triggers the OS health-permission prompt
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get stepsPermissionAllow;

  /// Title shown after the user denies step access
  ///
  /// In en, this message translates to:
  /// **'No step data yet'**
  String get stepsPermissionDeniedTitle;

  /// Body shown after the user denies step access (§7: never a dead end)
  ///
  /// In en, this message translates to:
  /// **'Access was denied, so your traveler isn\'t moving yet. You can grant access again anytime.'**
  String get stepsPermissionDeniedBody;

  /// Button that re-requests step access after a denial
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get stepsPermissionRetry;

  /// Title shown after Android stops offering the permission dialog at all (two denials)
  ///
  /// In en, this message translates to:
  /// **'Permission needs a settings change'**
  String get stepsPermissionPermanentlyDeniedTitle;

  /// Body shown after Android stops offering the permission dialog at all (§7: never a dead end)
  ///
  /// In en, this message translates to:
  /// **'Android won\'t ask again after a couple of tries — open this app\'s settings and allow Physical activity to let your traveler move.'**
  String get stepsPermissionPermanentlyDeniedBody;

  /// Button that opens this app's OS settings page when the permission dialog is no longer offered
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get stepsPermissionOpenSettings;

  /// Title shown on Android when Health Connect isn't installed
  ///
  /// In en, this message translates to:
  /// **'Health Connect required'**
  String get stepsHealthConnectMissingTitle;

  /// Body shown on Android when Health Connect isn't installed
  ///
  /// In en, this message translates to:
  /// **'Install Health Connect to let your steps move your traveler.'**
  String get stepsHealthConnectMissingBody;

  /// Button that deep-links to the Health Connect Play Store listing
  ///
  /// In en, this message translates to:
  /// **'Install Health Connect'**
  String get stepsHealthConnectInstall;

  /// Shown after a sync whose step rate exceeded the realistic-pace threshold (§5.2); the distance is credited regardless, this is informational only
  ///
  /// In en, this message translates to:
  /// **'Your last sync included an unusually fast stretch — it\'s still counted, just flagged for review.'**
  String get stepsFlaggedPaceNotice;

  /// Subtitle under the total quest distance, naming the destination
  ///
  /// In en, this message translates to:
  /// **'To {pointB}'**
  String questStatsToLabel(String pointB);

  /// Label for the quest start date stat row
  ///
  /// In en, this message translates to:
  /// **'Quest Started'**
  String get questStatsStartedLabel;

  /// Label for the ETA stat row
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get questStatsEtaLabel;

  /// Title of the placeholder panel where the drawn map lands (Phase 11)
  ///
  /// In en, this message translates to:
  /// **'Route map'**
  String get questStatsMapComingSoonTitle;

  /// Body of the placeholder map panel
  ///
  /// In en, this message translates to:
  /// **'The illustrated map for this quest is on its way — check back in a future update.'**
  String get questStatsMapComingSoonBody;

  /// Title shown on the stats tab before any quest is selected
  ///
  /// In en, this message translates to:
  /// **'No quest yet'**
  String get questStatsEmptyTitle;

  /// Body shown on the stats tab before any quest is selected
  ///
  /// In en, this message translates to:
  /// **'Start a quest from the Path tab to see its stats here.'**
  String get questStatsEmptyBody;

  /// Button navigating from the empty stats tab to the Path tab
  ///
  /// In en, this message translates to:
  /// **'Go to Path'**
  String get questStatsEmptyCta;

  /// Achievement title: reach 1 km on the current quest
  ///
  /// In en, this message translates to:
  /// **'First Steps'**
  String get achievementFirstStepsTitle;

  /// Achievement title: reach 50 km on the current quest
  ///
  /// In en, this message translates to:
  /// **'Half-Day March'**
  String get achievementHalfDayMarchTitle;

  /// Achievement title: reach 500 km on the current quest
  ///
  /// In en, this message translates to:
  /// **'Seasoned Wanderer'**
  String get achievementSeasonedWandererTitle;

  /// Achievement title: reach the full quest length
  ///
  /// In en, this message translates to:
  /// **'Journey\'s End'**
  String get achievementJourneysEndTitle;

  /// Caption on an unlocked achievement tile
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievementUnlockedLabel;

  /// Caption on a locked achievement tile; word order is locale-specific (§11) — English puts the amount first
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String achievementRemainingLabel(String amount);

  /// Settings tab app bar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section heading for the sign-in row
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSectionTitle;

  /// Row label for the optional sign-in entry point (§8)
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get settingsSignInButton;

  /// Subtitle under the sign-in row explaining it's optional
  ///
  /// In en, this message translates to:
  /// **'Optional — your progress already works without an account.'**
  String get settingsSignInSubtitle;

  /// Title of the sheet shown when tapping sign-in today
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settingsSignInStubTitle;

  /// Body of the sign-in stub sheet
  ///
  /// In en, this message translates to:
  /// **'Account sign-in isn\'t wired up yet — your quest progress already works without it.'**
  String get settingsSignInStubBody;

  /// Button that dismisses the sign-in stub sheet
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsSignInStubClose;

  /// Settings section heading for the language switch
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSectionTitle;

  /// Language option label — kept in Russian in both locales, it names the language itself
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get settingsLanguageRussian;

  /// Language option label — kept in English in both locales, it names the language itself
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Settings section heading for the persistent lock-screen/notification-shade progress toggle (§7)
  ///
  /// In en, this message translates to:
  /// **'Lock screen'**
  String get settingsLockScreenSectionTitle;

  /// Label of the off-by-default toggle that turns on the ongoing notification
  ///
  /// In en, this message translates to:
  /// **'Show progress on the lock screen'**
  String get settingsLockScreenToggleTitle;

  /// Subtitle explaining what the toggle does, shown under it
  ///
  /// In en, this message translates to:
  /// **'A quiet, ongoing notification with your quest progress — visible in the notification shade and on the lock screen.'**
  String get settingsLockScreenToggleSubtitle;

  /// Title of the explanation shown before requesting the notification + background-sync permissions (§7)
  ///
  /// In en, this message translates to:
  /// **'Keep your progress visible'**
  String get lockScreenPermissionExplainTitle;

  /// Body of the pre-permission explanation, shown before the OS prompts
  ///
  /// In en, this message translates to:
  /// **'To show your progress on the lock screen, There and Back needs permission to post a notification and to read your steps in the background, roughly every 15 minutes. Only your quest progress is shown there — never raw health data.'**
  String get lockScreenPermissionExplainBody;

  /// Button that triggers the OS notification/background-health permission prompts
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get lockScreenPermissionAllow;

  /// Shown after the user denies the notification/background-health permissions (§7: never a dead end)
  ///
  /// In en, this message translates to:
  /// **'Permission wasn\'t granted, so the lock screen display is off. You can turn it on again anytime.'**
  String get lockScreenPermissionDeniedBody;

  /// Names POST_NOTIFICATIONS as the specific permission still missing, so the denial message doesn't read as 'nothing was granted'
  ///
  /// In en, this message translates to:
  /// **'Still missing: permission to post notifications.'**
  String get lockScreenPermissionMissingNotifications;

  /// Names Health Connect's READ_HEALTH_DATA_IN_BACKGROUND as the specific permission still missing
  ///
  /// In en, this message translates to:
  /// **'Still missing: permission to read your steps in the background. Health Connect grants it on its own permission screen.'**
  String get lockScreenPermissionMissingBackgroundHealth;

  /// Shown instead of the denied text when Health Connect itself isn't installed (Android), distinct from a plain permission denial
  ///
  /// In en, this message translates to:
  /// **'Health Connect isn't installed. Install it to read your steps in the background and show progress on the lock screen.'**
  String get lockScreenHealthConnectMissingBody;

  /// Android notification channel name for the ongoing lock-screen/shade notification (shown in system notification settings, not in-app)
  ///
  /// In en, this message translates to:
  /// **'Quest progress'**
  String get lockScreenChannelName;

  /// Android notification channel description (shown in system notification settings, not in-app)
  ///
  /// In en, this message translates to:
  /// **'Shows your current quest progress in the notification shade and on the lock screen.'**
  String get lockScreenChannelDescription;

  /// The ongoing notification's prominent line: the quest-day counter and formatted progress distance, already composed
  ///
  /// In en, this message translates to:
  /// **'{day} · {distance}'**
  String lockScreenBody(String day, String distance);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
