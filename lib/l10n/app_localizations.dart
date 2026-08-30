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

  /// Bottom nav label for the friends/Challengers tab (§6.4)
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

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

  /// Small button shown on the Путь scene only while the view is rewound away from the traveler's real position — jumps back to it (§6.1's 'You >' anchor). Also its accessibility label.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get journeyReturnToYouButton;

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

  /// Heading over the drawn quest map on the stats tab (§6.2)
  ///
  /// In en, this message translates to:
  /// **'Route map'**
  String get questMapSectionTitle;

  /// Accessibility label of the route overlay drawn over the map — the marker itself is painted, not a widget with text
  ///
  /// In en, this message translates to:
  /// **'Your position on the route'**
  String get questMapYouAreHere;

  /// Shown under the map when map.json is bundled but its illustration (map.webp) isn't, so only the route line renders
  ///
  /// In en, this message translates to:
  /// **'The drawn map isn\'t in this build yet — below is the route itself, with your position on it.'**
  String get questMapIllustrationMissing;

  /// Caption under the map naming the next landmark on the route and how far it still is; the landmark name is quest data, not translated copy (§11). Reused verbatim as the tap-to-open tooltip for any landmark still ahead of the traveler, not just the next one.
  ///
  /// In en, this message translates to:
  /// **'Ahead: {name} — {distance} to go'**
  String questMapNextLandmark(String name, String distance);

  /// Tooltip shown when tapping a landmark the traveler has already passed; distance is how far past it they are. Mirrors questMapNextLandmark's "Ahead: {name} — {distance} to go" phrasing for the opposite direction.
  ///
  /// In en, this message translates to:
  /// **'Behind: {name} — {distance} ago'**
  String questMapLandmarkBehindCaption(String name, String distance);

  /// Caption under the map once the traveler has passed the last landmark
  ///
  /// In en, this message translates to:
  /// **'Every landmark on this route is behind you.'**
  String get questMapAllLandmarksReached;

  /// Shown in place of the map when the quest's map.json is missing or unusable
  ///
  /// In en, this message translates to:
  /// **'This quest\'s map couldn\'t be loaded.'**
  String get questMapLoadFailed;

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

  /// Achievement title: reach 10 km on the current quest
  ///
  /// In en, this message translates to:
  /// **'First League'**
  String get achievementFirstLeagueTitle;

  /// Achievement title: reach 50 km on the current quest
  ///
  /// In en, this message translates to:
  /// **'Half-Day March'**
  String get achievementHalfDayMarchTitle;

  /// Achievement title: reach 100 km on the current quest
  ///
  /// In en, this message translates to:
  /// **'Century Mark'**
  String get achievementCenturyMarkTitle;

  /// Achievement title: reach 500 km on the current quest
  ///
  /// In en, this message translates to:
  /// **'Seasoned Wanderer'**
  String get achievementSeasonedWandererTitle;

  /// Achievement title: reach the Aeaea (Circe) landmark on the Odyssey quest — map.json's "aeaea-circe"
  ///
  /// In en, this message translates to:
  /// **'Reached Aeaea'**
  String get achievementReachedCirceTitle;

  /// Achievement title: reach the Lotus-Eaters landmark on the Odyssey quest — map.json's "lotus-eaters"
  ///
  /// In en, this message translates to:
  /// **'Reached the Lotus-Eaters'**
  String get achievementReachedLotusEatersTitle;

  /// Achievement title: reach exactly half the current quest's total length
  ///
  /// In en, this message translates to:
  /// **'Halfway There'**
  String get achievementHalfwayThereTitle;

  /// Achievement title: reach the Calypso landmark on the Odyssey quest — map.json's "calypso"
  ///
  /// In en, this message translates to:
  /// **'Reached Calypso'**
  String get achievementReachedCalypsoTitle;

  /// Achievement title: reach 2000 km on the current quest
  ///
  /// In en, this message translates to:
  /// **'Long Hauler'**
  String get achievementLongHaulerTitle;

  /// Achievement title: reach the Scylla and Charybdis landmark on the Odyssey quest — map.json's "scylla-charybdis"
  ///
  /// In en, this message translates to:
  /// **'Passed Scylla and Charybdis'**
  String get achievementPassedScyllaCharybdisTitle;

  /// Achievement title: reach the Sirens landmark on the Odyssey quest — map.json's "sirens"
  ///
  /// In en, this message translates to:
  /// **'Passed the Sirens'**
  String get achievementPassedSirensTitle;

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

  /// Row title once the Google upgrade has linked the session
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get settingsSignedInTitle;

  /// Row subtitle once the Google upgrade has linked the session
  ///
  /// In en, this message translates to:
  /// **'Your Google account is linked — friends can find you by your nickname.'**
  String get settingsSignedInSubtitle;

  /// Snackbar shown after GoogleUpgradeOutcome.success from the settings row
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google.'**
  String get settingsSignInSuccessMessage;

  /// Snackbar shown after GoogleUpgradeOutcome.existingAccountRestored — the Google identity already owned a different account, so this session switched to it and reconciled progress/friends from it (repeat login on a new device or reinstall)
  ///
  /// In en, this message translates to:
  /// **'Signed in — synced with your existing account.'**
  String get settingsSignInRestoredMessage;

  /// Snackbar shown when upgradeWithGoogle() throws (e.g. no network, misconfigured Google sign-in) rather than returning a known GoogleUpgradeOutcome
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in — please try again.'**
  String get settingsSignInErrorMessage;

  /// Settings section heading for the nickname row
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get settingsNicknameSectionTitle;

  /// Placeholder shown in place of the nickname row before the profile has loaded
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get settingsNicknameLoading;

  /// Tooltip on the edit-nickname icon button
  ///
  /// In en, this message translates to:
  /// **'Change nickname'**
  String get settingsNicknameEditTooltip;

  /// Title of the change-nickname dialog
  ///
  /// In en, this message translates to:
  /// **'Change nickname'**
  String get settingsNicknameEditDialogTitle;

  /// Label of the text field in the change-nickname dialog
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get settingsNicknameFieldLabel;

  /// Save button in the change-nickname dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsNicknameSaveButton;

  /// Cancel button in the change-nickname dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsNicknameCancelButton;

  /// Snackbar shown after UpdateNicknameOutcome.success
  ///
  /// In en, this message translates to:
  /// **'Nickname updated.'**
  String get settingsNicknameUpdatedMessage;

  /// Snackbar shown after UpdateNicknameOutcome.nicknameTaken
  ///
  /// In en, this message translates to:
  /// **'That nickname is already taken — try another one.'**
  String get settingsNicknameTakenMessage;

  /// Snackbar shown when updateNickname() throws rather than returning a known UpdateNicknameOutcome, or for UpdateNicknameOutcome.notSignedIn (shouldn't be reachable from the UI, since the row needs a loaded profile to be tappable, but rendered explicitly rather than silently doing nothing)
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update nickname — please try again.'**
  String get settingsNicknameErrorMessage;

  /// Snackbar shown when the nickname row is tapped before the profile has loaded — retries the bootstrap write instead of leaving the tap a silent no-op
  ///
  /// In en, this message translates to:
  /// **'Still loading your profile — try again in a moment.'**
  String get settingsNicknameNotReadyMessage;

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
  /// **'Health Connect isn\'t installed. Install it to read your steps in the background and show progress on the lock screen.'**
  String get lockScreenHealthConnectMissingBody;

  /// Shown when ACTIVITY_RECOGNITION hit Android's two-denials-means-'don't ask again' rule — the toggle can no longer trigger the OS dialog, so this points at settings instead (§7: never a dead end)
  ///
  /// In en, this message translates to:
  /// **'Android won\'t ask again after a couple of tries — open this app\'s settings and allow Physical activity, then turn this back on.'**
  String get lockScreenPermissionPermanentlyDeniedBody;

  /// Button that opens this app's OS settings page when the permission dialog is no longer offered
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get lockScreenPermissionOpenSettings;

  /// Tappable hint shown once the toggle is on, opening the troubleshooting sheet below — some Android manufacturers gate lock-screen display behind their own separate OS settings this app has no API to request or detect
  ///
  /// In en, this message translates to:
  /// **'Not showing on the lock screen?'**
  String get lockScreenTroubleshootLink;

  /// Title of the troubleshooting sheet
  ///
  /// In en, this message translates to:
  /// **'Not showing on the lock screen?'**
  String get lockScreenTroubleshootTitle;

  /// Troubleshooting steps for OEM-specific (mainly MIUI) lock-screen notification restrictions this app cannot detect or fix in code
  ///
  /// In en, this message translates to:
  /// **'This app already asks Android to show it on the lock screen — some phone makers (Xiaomi/MIUI and others) add their own separate setting on top that can still block it, with no way for an app to check or request it directly. If it shows in the notification shade but not on the lock screen, check on your phone:\n\n1. A phone-wide \"Notifications on lock screen\" setting — usually under Settings → Lock screen or Settings → Notifications — set to show content, not hidden.\n2. This app\'s own lock-screen permission — under Settings → Apps → There and Back → Permissions.\n3. Autostart and battery saver for this app — set to unrestricted.\n4. After changing any of these, turn the toggle above off and back on, then restart the phone.\n5. Make sure Do Not Disturb is off.'**
  String get lockScreenTroubleshootBody;

  /// Button that dismisses the troubleshooting sheet
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get lockScreenTroubleshootClose;

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

  /// Друзья tab app bar title (§6.4)
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// Marker shown next to the signed-in user's own row in the Challengers table
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get friendsYouLabel;

  /// Button that opens the add-by-nickname dialog
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get friendsAddButton;

  /// Title of the add-friend dialog
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get friendsAddDialogTitle;

  /// Label of the nickname text field in the add-friend dialog
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get friendsAddNicknameLabel;

  /// Submit button in the add-friend dialog
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get friendsAddSubmit;

  /// Cancel button in the add-friend dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get friendsAddCancel;

  /// Label above the signed-in user's own nickname, so a friend can find them by it
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get friendsMyNicknameLabel;

  /// Tooltip on the icon button that copies the user's own nickname to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy nickname'**
  String get friendsMyNicknameCopyTooltip;

  /// Snackbar shown after the copy-nickname button is tapped
  ///
  /// In en, this message translates to:
  /// **'Nickname copied — share it with a friend.'**
  String get friendsMyNicknameCopied;

  /// Section heading for incoming friend requests awaiting the user's own accept/decline
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friendsPendingIncomingTitle;

  /// Section heading for the user's own outgoing, still-pending requests
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get friendsPendingOutgoingTitle;

  /// Row label for one incoming pending request
  ///
  /// In en, this message translates to:
  /// **'{name} wants to be your friend'**
  String friendsIncomingRequestLabel(String name);

  /// Row label for one of the user's own outgoing pending requests
  ///
  /// In en, this message translates to:
  /// **'Request sent to {name}'**
  String friendsOutgoingRequestLabel(String name);

  /// Accepts an incoming friend request
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAcceptButton;

  /// Declines an incoming friend request
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendsDeclineButton;

  /// Cancels the user's own outgoing friend request
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get friendsCancelRequestButton;

  /// Removes an existing (accepted) friend — reversible, §6.4
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get friendsRemoveButton;

  /// Title shown when the Challengers table has only the user's own row and no pending requests
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsEmptyTitle;

  /// Body text under friendsEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'Add a friend by their nickname to see how your quests compare.'**
  String get friendsEmptyBody;

  /// Confirmation after AddFriendOutcome.sent
  ///
  /// In en, this message translates to:
  /// **'Friend request sent.'**
  String get friendsOutcomeSent;

  /// Shown for AddFriendOutcome.nicknameNotFound
  ///
  /// In en, this message translates to:
  /// **'No one has that nickname.'**
  String get friendsOutcomeNicknameNotFound;

  /// Shown for AddFriendOutcome.cannotAddSelf
  ///
  /// In en, this message translates to:
  /// **'That\'s your own nickname.'**
  String get friendsOutcomeCannotAddSelf;

  /// Shown for AddFriendOutcome.alreadyExists (an existing pending or accepted friendship)
  ///
  /// In en, this message translates to:
  /// **'You\'re already connected with that person.'**
  String get friendsOutcomeAlreadyExists;

  /// Shown for AddFriendOutcome.notSignedIn — an unexpected, likely transient state
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign you in — try again in a moment.'**
  String get friendsOutcomeNotSignedIn;

  /// Shown for AddFriendOutcome.googleUpgradeCancelled — the user closed the Google account picker
  ///
  /// In en, this message translates to:
  /// **'Adding friends needs a Google account — sign-in was cancelled.'**
  String get friendsOutcomeUpgradeCancelled;
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
