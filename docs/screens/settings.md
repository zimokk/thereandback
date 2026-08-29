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
`alreadyLinked` (`GoogleAccountAlreadyLinkedException` — this Google
identity already owns a different Firebase account, typically a reinstall)
shows that specific message rather than a raw exception.

## State — providers

| Provider | Shape | Notes |
|---|---|---|
| `appLocaleProvider` (`locale_provider.dart`) | `Locale` (Notifier) | Default `Locale('ru')` (§11 — Russian is this repo's primary language). **In-memory only** — resets to Russian on app restart, same placeholder-until-Phase-3 caveat as `journey_providers.dart`'s selected quest. |

## l10n keys

`settingsTitle`, `settingsAccountSectionTitle`, `settingsSignInButton`,
`settingsSignInSubtitle`, `settingsSignedInTitle`,
`settingsSignedInSubtitle`, `settingsSignInSuccessMessage`,
`settingsLanguageSectionTitle`, `settingsLanguageRussian`,
`settingsLanguageEnglish`. The `alreadyLinked` snackbar reuses
`friendsOutcomeUpgradeAlreadyLinked` — one message for one outcome,
regardless of which tab triggered the upgrade.

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
