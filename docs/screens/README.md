# Screens — base scaffold

This directory is the per-screen "contract" documentation requested
alongside the base app: what each screen shows, which providers/entities
back it, its l10n keys, and — critically — what's real today versus what's
a deliberate placeholder for a later phase. `CLAUDE.md` stays the source of
truth for product decisions; `docs/implementation-plan.md` sequences them
into phases; these files are the as-built record for this base.

| Screen | Route | Doc |
|---|---|---|
| Путь (journey home + placeholder scene) | `/journey` | [`journey.md`](journey.md) |
| Карта / Прогресс (quest stats) | `/quest-stats` | [`quest-stats.md`](quest-stats.md) |
| Трофеи (achievements) | `/achievements` | [`achievements.md`](achievements.md) |
| Друзья (Challengers) | `/friends` | [`friends.md`](friends.md) |
| Настройки (settings) | `/settings` | [`settings.md`](settings.md) |
| Steps sync (embedded in Путь, not its own tab) | — | [`steps-sync.md`](steps-sync.md) |

## Five tabs

CLAUDE.md §6 fixes five bottom tabs (Путь · Карта · Трофеи · Друзья ·
Настройки). All five are wired in `lib/app/router.dart` and
`lib/app/app_shell.dart` as of Phase 8 — Друзья was the last one added,
as its own `StatefulShellBranch` plus the `features/friends/` module
(`ChallengersTab`), not a restructuring of the four already here.

## What this base deliberately does not build

Each screen doc calls these out inline, gathered here for a single scan:

- **No Flame parallax scene** (Путь) — a `CustomPaint` straight line
  stands in; Phase 5 replaces it.
- **No drawn map** (Карта/Прогресс) — no `map.webp`/`map.json` exist yet
  (Phase 11 supplies them; Phase 6 renders them).
- **No Firebase Auth** (Настройки) — sign-in is a UI-only stub; Phase 8
  needs its own plan first (§13).
- **No drift persistence** (all of the above) — `selectedJourneyProvider`
  and `appLocaleProvider` are in-memory Riverpod state, reset on app
  restart. Phase 3 is the durable replacement, designed to slot in without
  changing the shapes these screens already depend on.
- **No background steps sync** — foreground-only; see
  [`steps-sync.md`](steps-sync.md).
- **No real quest narrative content** — a placeholder empty-state line
  stands in on the Путь tab; real `NarrativeBeat`s are human-authored
  content (Phase 11), never generated.

## Verifying this base

```bash
export PATH="/tmp/flutter_sdk/flutter/bin:$PATH"   # or wherever Flutter 3.47+ lives
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format .
flutter analyze
flutter test
```

All five commands are green as of this base's last commit. `flutter test
integration_test` is **not** part of that — there's no device/emulator to
run it against in the environment this was built in; see
[`steps-sync.md`](steps-sync.md)'s note on that gap.
