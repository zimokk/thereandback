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
  String get navFriends => 'Friends';

  @override
  String get navFriendsLockedTooltip =>
      'Sign in and set a nickname in Settings first';

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
  String get journeyReturnToYouButton => 'You';

  @override
  String get journeyBackToCatalogButton => 'Choose a quest';

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
  String get stepsPermissionPermanentlyDeniedTitle =>
      'Permission needs a settings change';

  @override
  String get stepsPermissionPermanentlyDeniedBody =>
      'Android won\'t ask again after a couple of tries — open this app\'s settings and allow Physical activity to let your traveler move.';

  @override
  String get stepsPermissionOpenSettings => 'Open settings';

  @override
  String get stepsHealthConnectMissingTitle => 'Health Connect required';

  @override
  String get stepsHealthConnectMissingBody =>
      'Install Health Connect to let your steps move your traveler.';

  @override
  String get stepsHealthConnectInstall => 'Install Health Connect';

  @override
  String get stepsFlaggedPaceNotice =>
      'Your last sync included an unusually fast stretch — it\'s still counted, just flagged for review.';

  @override
  String questStatsToLabel(String pointB) {
    return 'To $pointB';
  }

  @override
  String get questStatsStartedLabel => 'Quest Started';

  @override
  String get questStatsEtaLabel => 'Estimated Arrival';

  @override
  String get questMapYouAreHere => 'Your position on the route';

  @override
  String get questMapIllustrationMissing =>
      'The drawn map isn\'t in this build yet — below is the route itself, with your position on it.';

  @override
  String questMapNextLandmark(String name, String distance) {
    return 'Ahead: $name — $distance to go';
  }

  @override
  String questMapLandmarkBehindCaption(String name, String distance) {
    return 'Behind: $name — $distance ago';
  }

  @override
  String get questMapAllLandmarksReached =>
      'Every landmark on this route is behind you.';

  @override
  String get questMapLoadFailed => 'This quest\'s map couldn\'t be loaded.';

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
  String get achievementFirstLeagueTitle => 'First League';

  @override
  String get achievementHalfDayMarchTitle => 'Half-Day March';

  @override
  String get achievementCenturyMarkTitle => 'Century Mark';

  @override
  String get achievementSeasonedWandererTitle => 'Seasoned Wanderer';

  @override
  String get achievementReachedCirceTitle => 'Reached Aeaea';

  @override
  String get achievementReachedLotusEatersTitle => 'Reached the Lotus-Eaters';

  @override
  String get achievementHalfwayThereTitle => 'Halfway There';

  @override
  String get achievementReachedCalypsoTitle => 'Reached Calypso';

  @override
  String get achievementLongHaulerTitle => 'Long Hauler';

  @override
  String get achievementPassedScyllaCharybdisTitle =>
      'Passed Scylla and Charybdis';

  @override
  String get achievementPassedSirensTitle => 'Passed the Sirens';

  @override
  String get achievementJourneysEndTitle => 'Journey\'s End';

  @override
  String get achievementUnlockedLabel => 'Unlocked';

  @override
  String achievementRemainingLabel(String amount) {
    return '$amount left';
  }

  @override
  String get achievementDaily1kmTitle => '1 kilometer in a day';

  @override
  String get achievementDaily5kmTitle => '5 kilometers in a day';

  @override
  String get achievementDaily10kmTitle => '10 kilometers in a day';

  @override
  String get achievementDaily20kmTitle => '20 kilometers in a day';

  @override
  String get achievementDaily50kmTitle => '50 kilometers in a day';

  @override
  String get achievementsJourneyTabLabel => 'Quest';

  @override
  String get achievementsDailyTabLabel => 'Daily';

  @override
  String get achievementNeverUnlockedLabel => 'Not yet reached';

  @override
  String achievementUnlockedCountLabel(int count) {
    return 'Reached: $count';
  }

  @override
  String get achievementUnlockDatesSheetTitle => 'Dates reached';

  @override
  String achievementLongestStreakLabel(int days) {
    return 'Longest streak: $days days';
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
  String get settingsSignedInTitle => 'Signed in';

  @override
  String get settingsSignedInSubtitle =>
      'Your Google account is linked — friends can find you by your nickname.';

  @override
  String get settingsSignInSuccessMessage => 'Signed in with Google.';

  @override
  String get settingsSignInRestoredMessage =>
      'Signed in — synced with your existing account.';

  @override
  String get settingsSignInErrorMessage =>
      'Couldn\'t sign in — please try again.';

  @override
  String get settingsNicknameSectionTitle => 'Nickname';

  @override
  String get settingsNicknameLoading => '—';

  @override
  String get settingsNicknameEditTooltip => 'Change nickname';

  @override
  String get settingsNicknameEditDialogTitle => 'Change nickname';

  @override
  String get settingsNicknameFieldLabel => 'Nickname';

  @override
  String get settingsNicknameSaveButton => 'Save';

  @override
  String get settingsNicknameCancelButton => 'Cancel';

  @override
  String get settingsNicknameUpdatedMessage => 'Nickname updated.';

  @override
  String get settingsNicknameTakenMessage =>
      'That nickname is already taken — try another one.';

  @override
  String get settingsNicknameErrorMessage =>
      'Couldn\'t update nickname — please try again.';

  @override
  String get settingsNicknameNotReadyMessage =>
      'Still loading your profile — try again in a moment.';

  @override
  String get settingsLanguageSectionTitle => 'Language';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsThemeSectionTitle => 'Theme';

  @override
  String get settingsThemeSectionSubtitle =>
      'Defaults to your current quest\'s own theme.';

  @override
  String get settingsThemeFollowQuest => 'Quest theme';

  @override
  String get settingsThemeClassic => 'Classic';

  @override
  String get settingsThemeOdyssey => 'Odyssey (active quest)';

  @override
  String get settingsLockScreenSectionTitle => 'Lock screen';

  @override
  String get settingsLockScreenToggleTitle =>
      'Show progress on the lock screen';

  @override
  String get settingsLockScreenToggleSubtitle =>
      'Show your quest progress in the notification shade and on the lock screen.';

  @override
  String get lockScreenPermissionExplainTitle => 'Keep your progress visible';

  @override
  String get lockScreenPermissionExplainBody =>
      'To show your progress on the lock screen, There and Back needs permission to post a notification and to read your steps in the background, roughly every 15 minutes. Only your quest progress is shown there — never raw health data.';

  @override
  String get lockScreenPermissionAllow => 'Allow';

  @override
  String get lockScreenPermissionDeniedBody =>
      'Permission wasn\'t granted, so the lock screen display is off. You can turn it on again anytime.';

  @override
  String get lockScreenPermissionMissingNotifications =>
      'Still missing: permission to post notifications.';

  @override
  String get lockScreenPermissionMissingBackgroundHealth =>
      'Still missing: permission to read your steps in the background. Health Connect grants it on its own permission screen.';

  @override
  String get lockScreenHealthConnectMissingBody =>
      'Health Connect isn\'t installed. Install it to read your steps in the background and show progress on the lock screen.';

  @override
  String get lockScreenPermissionPermanentlyDeniedBody =>
      'Android won\'t ask again after a couple of tries — open this app\'s settings and allow Physical activity, then turn this back on.';

  @override
  String get lockScreenPermissionOpenSettings => 'Open settings';

  @override
  String get lockScreenTroubleshootLink => 'Not showing on the lock screen?';

  @override
  String get lockScreenTroubleshootTitle => 'Not showing on the lock screen?';

  @override
  String get lockScreenTroubleshootBody =>
      'This app already asks Android to show it on the lock screen — some phone makers (Xiaomi/MIUI and others) add their own separate setting on top that can still block it, with no way for an app to check or request it directly. If it shows in the notification shade but not on the lock screen, check on your phone:\n\n1. A phone-wide \"Notifications on lock screen\" setting — usually under Settings → Lock screen or Settings → Notifications — set to show content, not hidden.\n2. This app\'s own lock-screen permission — under Settings → Apps → There and Back → Permissions.\n3. Autostart and battery saver for this app — set to unrestricted.\n4. After changing any of these, turn the toggle above off and back on, then restart the phone.\n5. Make sure Do Not Disturb is off.';

  @override
  String get lockScreenTroubleshootClose => 'Close';

  @override
  String get lockScreenChannelName => 'Quest progress';

  @override
  String get lockScreenChannelDescription =>
      'Shows your current quest progress in the notification shade and on the lock screen.';

  @override
  String lockScreenBody(String day, String distance) {
    return '$day · $distance';
  }

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsYouLabel => 'You';

  @override
  String get friendsAddButton => 'Add friend';

  @override
  String get friendsAddDialogTitle => 'Add a friend';

  @override
  String get friendsAddNicknameLabel => 'Nickname';

  @override
  String get friendsAddSubmit => 'Send request';

  @override
  String get friendsAddCancel => 'Cancel';

  @override
  String get friendsMyNicknameLabel => 'Your nickname';

  @override
  String get friendsMyNicknameCopyTooltip => 'Copy nickname';

  @override
  String get friendsMyNicknameCopied =>
      'Nickname copied — share it with a friend.';

  @override
  String get friendsPendingIncomingTitle => 'Requests';

  @override
  String get friendsPendingOutgoingTitle => 'Sent';

  @override
  String friendsIncomingRequestLabel(String name) {
    return '$name wants to be your friend';
  }

  @override
  String friendsOutgoingRequestLabel(String name) {
    return 'Request sent to $name';
  }

  @override
  String get friendsAcceptButton => 'Accept';

  @override
  String get friendsDeclineButton => 'Decline';

  @override
  String get friendsCancelRequestButton => 'Cancel';

  @override
  String get friendsRemoveButton => 'Remove';

  @override
  String get friendsEmptyTitle => 'No friends yet';

  @override
  String get friendsEmptyBody =>
      'Add a friend by their nickname to see how your quests compare.';

  @override
  String get friendsEmptyOdysseyTitle => 'The journey is better together';

  @override
  String get friendsEmptyOdysseyBody =>
      'Add friends by nickname and compare who has traveled further on their own Odyssey.';

  @override
  String get friendsLockedTitle => 'Friends isn\'t available yet';

  @override
  String get friendsLockedBody =>
      'Sign in and set a nickname in Settings to see and add friends.';

  @override
  String get friendsOutcomeSent => 'Friend request sent.';

  @override
  String get friendsOutcomeNicknameNotFound => 'No one has that nickname.';

  @override
  String get friendsOutcomeCannotAddSelf => 'That\'s your own nickname.';

  @override
  String get friendsOutcomeAlreadyExists =>
      'You\'re already connected with that person.';

  @override
  String get friendsOutcomeNotSignedIn =>
      'Couldn\'t sign you in — try again in a moment.';

  @override
  String get friendsOutcomeUpgradeCancelled =>
      'Adding friends needs a Google account — sign-in was cancelled.';

  @override
  String get friendsOutcomeError =>
      'Couldn\'t complete that — please try again.';
}
