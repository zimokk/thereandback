# Screen: Настройки (Settings)

Bottom tab 4 of 4 in this base — a deliberately trimmed slice of CLAUDE.md
§6.5. Route: **`/settings`**. Entry widget: `SettingsTab`
(`lib/features/profile/presentation/settings_tab.dart`).

## What it shows

Two sections, exactly what was asked for — an optional sign-in entry
point and a working language switch. Everything else §6.5 lists (stride
override, privacy toggles, permission re-request, "Смена квеста") is a
later slice, not built here.

### Account

A row: **Sign in**, subtitle "Optional — your progress already works
without an account." Tapping it opens a bottom sheet ("Coming soon") —
see below.

### Language

`RadioGroup<Locale>` around two `RadioListTile`s — Русский / English.
Selecting one calls `appLocaleProvider.notifier.setLocale(locale)`, which
`app.dart`'s `MaterialApp.router` watches directly, so the whole app's
locale (including this screen's own labels) changes immediately, no
restart.

## Sign-in is a real UI stub, not a placeholder pretending to work

Tapping **Sign in** never calls Firebase — it shows a sheet
(`settingsSignInStubTitle`/`Body`/`Close`) saying account sign-in isn't
wired up yet. This matches CLAUDE.md §8's own MVP decision: anonymous
Firebase Auth by default, no login screen designed for MVP, but the
anonymous `uid` must not be blocked from a future `linkWithCredential`
upgrade. Building the real flow is **Phase 8** and needs its own
architecture plan first (§13 — Firestore/Auth work always does). This
base intentionally does not touch `firebase_core`/`firebase_auth` at all;
they are not dependencies of this project yet.

## State — providers

| Provider | Shape | Notes |
|---|---|---|
| `appLocaleProvider` (`locale_provider.dart`) | `Locale` (Notifier) | Default `Locale('ru')` (§11 — Russian is this repo's primary language). **In-memory only** — resets to Russian on app restart, same placeholder-until-Phase-3 caveat as `journey_providers.dart`'s selected quest. |

## l10n keys

`settingsTitle`, `settingsAccountSectionTitle`, `settingsSignInButton`,
`settingsSignInSubtitle`, `settingsSignInStubTitle`,
`settingsSignInStubBody`, `settingsSignInStubClose`,
`settingsLanguageSectionTitle`, `settingsLanguageRussian`,
`settingsLanguageEnglish`.

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
locale); tapping sign-in shows the stub sheet and not a real flow;
switching to English flips the visible copy immediately, English label
included.
