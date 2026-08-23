---
name: new-screen
description: Add a new screen, tab, view, sheet, or dialog to There and Back. Use when the user asks to create a view/экран/страницу, add a route, build a widget for a feature, or wire UI to state. Covers feature-first placement, Riverpod wiring, go_router, l10n and the widget test that must ship with it.
---

# New screen / view

Every user-visible surface in this app is built the same way. Follow the order below — placement first, then state, then pixels.

## 0. Decide where it lives (§4)

```
lib/features/<feature>/
  domain/        # pure Dart entities + math, NO flutter/firebase/health imports
  data/          # repositories, mappers, DTOs
  presentation/  # widgets, Flame components, Riverpod providers
```

Features are fixed: `journey`, `steps`, `quest_map`, `achievements`, `friends`, `profile`. A new screen belongs to one of them — do not invent a top-level `screens/` or `pages/` folder. Shared, feature-agnostic widgets go in `lib/design/`; shared helpers in `lib/core/`.

The five bottom tabs (Путь · Карта · Трофеи · Друзья · Настройки) are **fixed** (§6). A new surface is a route *inside* a tab, a sheet, or a dialog — adding a sixth tab needs the user's explicit decision.

## 1. Route (`lib/app/router.dart`)

- `go_router` only. Named routes; nested under the owning tab's branch so the tab bar stays visible unless the design says full-screen (the quest-completion reward screen, §6.1, is full-screen and **closable** — it must not block navigation).
- Deep-linkable screens (friend invite, §6.4) get a stable path and are handled when the app is cold-started from a link.

## 2. State — Riverpod, never a direct repository call (§4)

```dart
@riverpod
Future<QuestStats> questStats(QuestStatsRef ref) =>
    ref.watch(questRepositoryProvider).loadStats();
```

- Widgets read providers; **providers** talk to repositories. A `build()` that constructs a repository or touches drift/Firestore directly is a bug.
- Generated providers (`riverpod_generator`) — after editing, run `dart run build_runner build --delete-conflicting-outputs` (see `codegen`).
- Handle all three states explicitly: data, loading, error. Never `.value!`.
- Offline-first (§8): the screen must render from local drift data with no network. No spinner that waits on Firestore.

## 3. UI

- Tokens only — colors, spacing and text styles from `lib/design/` (see the `styling` skill). No literal `Color(0x…)` or magic paddings in a feature widget.
- Dark theme is the only theme (§9).
- Numbers go through `core/formatters.dart` (§5.4) — never format meters inline. Units render as a separate small line under the number.
- Narrative lines render in serif italic (§9); distance in gold.
- Wrap raw metrics in journey language (§1): "День 5 · 5.23 kilometers · <region>", not "8412 шагов".

## 4. Strings — l10n from the first commit (§11)

No literal user-facing string in `build()`. Add the key to **both** `lib/l10n/app_en.arb` and `app_ru.arb` (see the `l10n` skill). Quest narrative is localizable content, not code.

## 5. Empty, error and permission states — required, not optional (§7)

Design them before you claim the screen is done:

- No steps data / permission denied → explanatory card + re-request button. **Never a dead end.**
- Health Connect missing on Android → explain + deep-link to Play Store.
- No friends yet, no achievements yet, quest finished (§6.1) → a real state, not a blank column.

## 6. Widget test — ships in the same commit (§12)

At minimum: the screen renders, and each non-trivial state (loading / error / empty / permission-denied) renders. Override providers with `ProviderScope(overrides: […])` and `mocktail` fakes — no real drift, health or Firestore in a widget test.

## 7. Verify

```bash
dart run build_runner build --delete-conflicting-outputs   # if providers/models changed
dart format . && flutter analyze && flutter test
```

Then check the screen against the relevant §6 subsection line by line and report anything from the spec you did not implement.
