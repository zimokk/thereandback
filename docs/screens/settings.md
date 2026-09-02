# Screen: Настройки (Settings)

Bottom tab 4 of 4 in this base — a deliberately trimmed slice of CLAUDE.md
§6.5. Route: **`/settings`**. Entry widget: `SettingsTab`
(`lib/features/profile/presentation/settings_tab.dart`).

## What it shows

Two sections, exactly what was asked for — a Google sign-in entry point
and a working language switch. Everything else §6.5 lists (stride
override, privacy toggles, permission re-request, "Смена квеста") is a
later slice, not built here.

### Account

Anonymous: a row — **Sign in**, subtitle "Optional — your progress
already works without an account." Tapping it runs the real §8 upgrade
(see below), not a stub.

Once linked: the row swaps to **Signed in** with a gold check icon and
becomes non-interactive — there's nothing left to tap once the upgrade
has already happened.

### Language

`RadioGroup<Locale>` around two `RadioListTile`s — Русский / English.
Selecting one calls `appLocaleProvider.notifier.setLocale(locale)`, which
`app.dart`'s `MaterialApp.router` watches directly, so the whole app's
locale (including this screen's own labels) changes immediately, no
restart.

## Sign-in is the real §8 Google upgrade, not a stub

Tapping **Sign in** calls `AuthController.upgradeWithGoogle()`
(`app/auth_provider.dart`) — the exact same call the friends feature makes
from "Add friend" when the session is still anonymous
(`friends_providers.dart`'s `addFriendByNickname`). Settings is just a
second, equally real entry point to that one upgrade path, not a separate
flow: an interactive Google account picker
(`data/firebase/google_sign_in_service.dart`), then
`AuthRepository.linkWithGoogleCredential` (`data/firebase/
auth_repository.dart`) linking the credential onto the existing anonymous
Firebase user via `linkWithCredential` — so the same `uid`, friendships and
progress carry over, nothing is re-created under a new identity.

The three `GoogleUpgradeOutcome` cases are rendered explicitly, same as on
the friends tab: `success` shows a confirmation snackbar and flips the row
to **Signed in**; `cancelled` (the user closed the picker) shows nothing;
`existingAccountRestored` (`GoogleAccountAlreadyLinkedException` — this
Google identity already owns a different, existing Firebase account, a
"repeat login" on a reinstall or a second device) no longer fails: the
session switches to that existing account instead
(`AuthRepository.signInWithGoogleCredential`), progress is reconciled by
keeping whichever total is larger — this device's local one or the
account's cloud one (`AuthController._reconcileProgressWithCloud`) — and a
distinct snackbar confirms the switch rather than reporting an error.

## iOS native config for Google Sign-In (fixed 2026-09-02)

`GoogleAuthService.signIn()` (`data/firebase/google_sign_in_service.dart`)
was failing on iOS with `PlatformException(google_sign_in, No active
configuration. Make sure GIDClientID is set in Info.plist., ...)` —
Android already had `android/app/google-services.json`, but the iOS side
of the same Firebase app (`firebase_options.dart`'s `ios` entry,
`1:443590986164:ios:8d61d9d67922181ea68ae1`) never had its counterpart
committed. Fixed by adding three files, all iOS-only, no Dart changes:

- `ios/Runner/GoogleService-Info.plist` — downloaded from Firebase Console
  for this exact app id; `PluginGoogleAuthService()` is still constructed
  with no explicit `clientId` (`app/auth_provider.dart`) — Google's iOS SDK
  reads `CLIENT_ID` from this file automatically once it's bundled, same
  as the comment in `google_sign_in_service.dart` already assumed.
- `ios/Runner/Info.plist` — a `CFBundleURLTypes` entry with the file's
  `REVERSED_CLIENT_ID` as the URL scheme, required separately for the
  OAuth redirect back into the app (GIDSignIn reading `CLIENT_ID` from the
  plist and the redirect URL scheme are two independent requirements, both
  needed).
- `ios/Runner.xcodeproj/project.pbxproj` — registered the new plist as a
  `PBXFileReference`/`PBXBuildFile` in the `Runner` target's Resources
  build phase, by hand, following the existing entries for
  `AppFrameworkInfo.plist`/`Assets.xcassets` as a template (plain ASCII,
  no Xcode needed to edit it). **Not verified against a real Xcode build
  in this sandbox** (no Xcode here, same limitation as the `Podfile`
  step in `steps-sync.md`) — worth opening the project once in Xcode
  before the next iOS build to confirm it parses and the file shows up
  under Target Membership → Runner.

## State — providers

| Provider | Shape | Notes |
|---|---|---|
| `appLocaleProvider` (`locale_provider.dart`) | `Locale` (Notifier) | Default `Locale('ru')` (§11 — Russian is this repo's primary language). **Durable since §14** — persisted through `UserPreferenceRepository` (`data/drift/user_preference_repository.dart`) the same way `journey_providers.dart`'s selected quest already was; a restart restores whatever was last chosen instead of resetting to Russian. |

## l10n keys

`settingsTitle`, `settingsAccountSectionTitle`, `settingsSignInButton`,
`settingsSignInSubtitle`, `settingsSignedInTitle`,
`settingsSignedInSubtitle`, `settingsSignInSuccessMessage`,
`settingsSignInRestoredMessage`, `settingsLanguageSectionTitle`,
`settingsLanguageRussian`, `settingsLanguageEnglish`. Unlike `success`,
the `existingAccountRestored` snackbar (`settingsSignInRestoredMessage`)
is Settings' own key, not shared with the friends tab's outcome
messages — the friends tab never surfaces this case as a distinct
snackbar of its own (`addFriendByNickname` just treats it as "proceed",
same as `success`).

`settingsLanguageRussian`/`settingsLanguageEnglish` are deliberately the
**same string in both ARB files** — a language names itself, it doesn't
get translated relative to the currently displayed locale.

## A layout note worth keeping

`_SectionCard` wraps its content in a `Material` widget, not a bare
`Container`/`DecoratedBox`. `ListTile`/`RadioListTile` paint their
background and ink splashes on the nearest `Material` ancestor — without
one, Flutter throws ("ListTile background color or ink splashes may be
invisible") the first time the row is tapped or rebuilt. Any future
section added here that contains a `ListTile`-family widget needs the same
`Material` wrapper, not a plain `Container`.

## Tests

`test/features/profile/presentation/settings_tab_test.dart`: both sections
render (Russian sign-in label by default, since `ru` is the default
locale); tapping sign-in while anonymous runs the real upgrade (mocked
`GoogleAuthService`/`AuthRepository`, same `_FixedAuthController` pattern
as `auth_provider_test.dart`) and shows the success snackbar; an
already-linked identity shows that specific message instead of crashing;
once signed in the row renders the signed-in state instead of the prompt;
switching to English flips the visible copy immediately, English label
included.
