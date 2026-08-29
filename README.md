# There and Back

A walking-journey app. Real steps, read from the phone's sensors, are
converted into distance and move a traveler figure along a quest route from
point A to point B. It's not framed as fitness tracking — progress is always
shown in the language of travel ("Day 5, 5.23 kilometers, crossed a stream on
a narrow footbridge"), not as a step count.

Add friends to see where they are on the same route — on the map and in a
leaderboard.

## Stack

- **Flutter** (stable, ≥ 3.13 SDK) — iOS and Android from one codebase
- **Flame** for the animated main-screen parallax scene
- **Riverpod** for state, **freezed** for models, **go_router** for navigation
- **drift** (SQLite) as the offline-first local store
- **health** for step data (Health Connect on Android; a custom
  `MethodChannel` over Core Motion on iOS — see `CLAUDE.md` §3 for why)
- **Firebase** (Auth, Firestore, Cloud Functions, FCM) for friends, sync, and
  push notifications

See `CLAUDE.md` for the full architecture and product spec, and
`docs/implementation-plan.md` for the phased build-out.

## Screens (developer reference names)

The user-facing tab labels and their behavior are fixed in `CLAUDE.md` §6.
Two of the five tabs already carry an internal dev codename there (`Quest
Stats`, `Challengers`); the other three did not have one yet, so this table
fixes all five in one place for use in code comments, PRs, and discussion —
prefer these over ad-hoc names.

| # | Tab (UI label) | Feature dir | Dev codename | Why |
|---|---|---|---|---|
| 1 | Путь / Path | `features/journey/` | **Wayfarer's Chronicle** | the main Flame scene: distance in meters, a narrative/historical beat of text, the traveler figure, and the horizontal parallax route line the user scrolls |
| 2 | Карта / Map | `features/quest_map/` | **Quest Stats** | named in `CLAUDE.md` §6.2 |
| 3 | Трофеи / Achievements | `features/achievements/` | **Trophy Case** | grid of achievement badges, earned vs. silhouetted |
| 4 | Друзья / Friends | `features/friends/` | **Challengers** | named in `CLAUDE.md` §6.4 |
| 5 | Настройки / Settings | `features/profile/` | **Waystation** | the one screen where the player stops to adjust gear (profile, stride length, privacy, permissions, quest switch) rather than move along the route |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable
  channel), Dart ≥ 3.13
- Android Studio (Android SDK + an emulator or device) and/or Xcode (iOS
  Simulator or device) depending on which platform you're targeting
- A [Firebase project](https://firebase.google.com/) if you need backend
  features (friends, sync, push); the app also runs fully offline without one
- The [Firebase CLI](https://firebase.google.com/docs/cli) if you plan to run
  the Firestore/Functions emulators

Check `flutter doctor` reports everything set up before continuing.

## Setup

```bash
git clone https://github.com/zimokk/thereandback.git
cd thereandback

# Install Dart/Flutter dependencies
flutter pub get

# Generate code (freezed, riverpod, drift, json_serializable)
dart run build_runner build --delete-conflicting-outputs
```

### iOS extra step

Step counting on iOS uses Core Motion through a custom platform channel
(`ios/Runner/AppDelegate.swift`), which needs a `permission_handler` iOS
preprocessor flag. After the first `pod install` creates `ios/Podfile`, add
`PERMISSION_SENSORS=1` to `GCC_PREPROCESSOR_DEFINITIONS` in its
`post_install` block (see `permission_handler`'s README for the exact
snippet, and `docs/screens/steps-sync.md` for details). Without this,
`Permission.sensors` won't work on iOS.

## Running the app (demo)

List available devices/emulators/simulators:

```bash
flutter devices
```

Run on a connected device or emulator:

```bash
flutter run -d <device-id>
```

The app works fully offline out of the box — the main "Path" tab, the map,
and achievements all work without a Firebase project or network connection.
Health/step permissions are requested only when you start a quest, not on
launch (see `CLAUDE.md` §7).

To exercise the Firebase-backed parts (friends, sync), start the local
emulators alongside the app:

```bash
firebase emulators:start   # Firestore + Cloud Functions
```

## Development commands

```bash
flutter analyze                              # static analysis
dart format .                                 # format code
flutter test                                  # unit + widget tests
flutter test integration_test                 # integration tests
```

Before committing, all three of `dart format .`, `flutter analyze`, and
`flutter test` must be clean (see `CLAUDE.md` §10).

## Building

```bash
flutter build apk       # Android APK
flutter build appbundle # Android App Bundle
flutter build ios       # iOS (requires Xcode + a configured signing team)
```

## Project structure

Feature-first, with a strict layer split inside each feature
(`domain/` → `data/` → `presentation/`). See `CLAUDE.md` §4 for the full
layout and rules.

## License

See [`LICENSE`](LICENSE).
