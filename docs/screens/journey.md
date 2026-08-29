# Screen: Путь (Journey)

Bottom tab 1 of 4 in this base (CLAUDE.md §6.1). Route: **`/journey`**
(initial route of the app). Entry widget: `JourneyTab`
(`lib/features/journey/presentation/journey_tab.dart`).

## What it shows

- **No quest selected** → `QuestPickerView`: the read-only quest catalog
  (one card today — Odyssey, §14). Tapping **Start quest** calls
  `selectedJourneyProvider.notifier.start(journeyId, now: DateTime.now())`.
- **Quest selected** → `StepsPermissionGate` (see
  [`steps-sync.md`](steps-sync.md)) on top, then `JourneyPathView`:
  - Day counter (`questDay`, §5.3)
  - Distance travelled so far (`formatDistance`, §5.4), gold hero number +
    unit line beneath it
  - `pointA → pointB`
  - A narrative placeholder line (see below)
  - A **`CustomPaint` scene**: solid background + a wavy line (background
    layer) + a traveler icon (`Icons.directions_walk`, foreground layer)
    resting on the line near the screen's horizontal centre — a
    `GestureDetector` pans the line horizontally under a finger drag.
    `_wavyPathY()` (`journey_path_view.dart`) is the one function both the
    painter and the icon's position read, so the two can never disagree
    about the curve's shape. The icon also **sways a small, bounded
    distance opposite the screen direction the line's pattern shifts in**
    (`_travelerOffsetX()`) — a parallax cue (§6.1: layers move at different
    speeds/directions) rather than the icon staying rigidly glued to
    centre; at rest (`_panMeters == 0`, a freshly started quest) it still
    sits exactly at centre.
  - The line has a **start and an end**: it spans exactly `[0 m,
    journey.totalMeters]`, drawn at a fixed **per-quest scale**
    (`metersPerScreenWidthFor`, `domain/route_scale.dart` — 20 000 m per
    screen width for `odyssey-ithaca`, configured per journey id, not one
    app-wide constant). Panning is clamped to that same range, so a drag
    can never scroll past point A or point B.
  - **Achievement markers** (`achievementCatalog`) sit in their own flat
    row pinned to the top of the scene, positioned along the x axis by
    their `thresholdMeters` at the same scale as the line. A marker not
    reached yet (`!AchievementState.unlocked`) renders muted
    (`AppColors.textSecondary`, outlined trophy icon); reached ones render
    gold (filled icon) — the same rule `achievements_tab.dart` uses.
    Scrolling ahead previews what's coming without unlocking it. The icon
    is all that shows on the line — **tapping it** opens a bottom sheet
    (`_showAchievementDetails`) with the achievement's name and status
    (unlocked / meters remaining); there is no always-on label and no
    hover/long-press reveal.

## Deliberate placeholder: no Flame yet

CLAUDE.md §3 fixes **Flame** (`ParallaxComponent`) as the tech for this
screen — that's still true. What's built here is the screen's *shape*
without its *art*: a wavy line stands in for the multi-layer parallax
route, because there is no quest art yet (§9.1 — art source unpicked) and
adding the `flame` dependency with nothing for it to render would be an
unjustified new dependency (§13). The pan here is purely a visual camera
move over that placeholder curve — it does not (yet) change the day/
distance/narrative labels below it or credit a different position on the
route; those still only move with real progress, same as before this
placeholder existed.

The line's *shape* (the sine wave) is the placeholder part. Its *length*
and the *scale* it's drawn at are not — both are real, meters-accurate and
per-quest (`domain/route_scale.dart`), which is also why panning is bounded
at point A/B instead of scrolling forever. Achievement markers are real
data too (`achievementCatalog`, evaluated against the actual
`selected.progressMeters`), just floating in their own top-pinned layer
rather than sitting on the (still placeholder) terrain.

**Phase 5** (`flame-scene` skill, `docs/implementation-plan.md`) replaces
`_WavyPathPainter` in `journey_path_view.dart` with a real
`ParallaxComponent` scene — free scroll tied to actual route position, the
`< Start`/`You >` anchors, time-of-day sky, animated traveler
interpolation, 60fps game loop that pauses off-screen. Nothing above the
painter (day counter, distance, catalog flow, providers) needs to change
shape when that happens.

## State — providers (`journey_providers.dart`)

| Provider | Shape | Notes |
|---|---|---|
| `journeyCatalogEntriesProvider` | `List<Journey>` | Static list today (`journey_catalog.dart`); Phase 8 swaps in cached Firestore metadata, same shape. |
| `selectedJourneyProvider` | `SelectedQuest?` (Notifier) | **Durable since Phase 3.** `build()` restores whatever was persisted via `progressRepositoryProvider`; `start()` writes through it. See [`steps-sync.md`](steps-sync.md#phase-3--durable-persistence-drift) for how `progressMeters`/`lastSyncedAt` are derived from the drift-backed interval log rather than stored as their own mutable fields. |
| `progressRepositoryProvider` | `ProgressRepository` | Drift-backed. Overridden with an in-memory `AppDatabase` in tests (`testing` skill). |
| `selectedJourneyDetailsProvider` | `Journey?` | Catalog lookup for the currently selected quest. |

`SelectedQuest.progressMeters` is written by
[`steps-sync.md`](steps-sync.md)'s sync flow, not by this screen directly.

## Domain

- `Journey` (`domain/journey.dart`) — id, name, pointA, pointB, totalMeters.
- `SelectedQuest` (`domain/quest_selection.dart`) — see table above.
- `QuestTimeService.questDay` (`domain/quest_time_service.dart`) —
  local-calendar-date day counter (§5.3). The same service also carries
  `paceMetersPerDay`/`estimateArrival`, but this screen only ever needs
  the day counter — see [`quest-stats.md`](quest-stats.md) for the
  pace/ETA half.
- `metersPerScreenWidthFor`/`metersToLineOffset` (`domain/route_scale.dart`)
  — the per-quest meters-per-screen-width config and the pure meters→pixel
  conversion built on it. A plain `Map<String, int>` keyed by journey id,
  not a field on `Journey` — no `build_runner` pass needed to add a quest's
  scale.
- `evaluateAchievements` (`features/achievements/domain/achievement.dart`,
  `achievementCatalog` from `features/achievements/data/`) — reused as-is
  from the Трофеи tab (§6.3) to drive the marker row; this screen adds no
  achievement logic of its own.
- `achievementTitle` (`features/achievements/presentation/
  achievement_titles.dart`) — the `titleKey` → localized string switch,
  shared by `achievements_tab.dart`'s grid and this screen's marker-tap
  sheet so the two can't show a different name for the same achievement.

## l10n keys

`journeyCatalogTitle`, `journeyCatalogStartButton`, `journeyDayCounter`
(`{day}`, no plural — a label, not a count), `journeyNarrativeComingSoon`.

`pointA → pointB` and the distance number itself are **data, not copy** —
not routed through l10n (the arrow is a typographic separator, per the same
note in the source files).

## Narrative placeholder — not a shortcut around real content

`journeyNarrativeComingSoon` ("Narrative for this stretch of the road is
still being written.") is a UI **empty state**, distinct from real
`NarrativeBeat` content. CLAUDE.md §11 is explicit that quest narrative is
human-authored content that belongs with the journey (`journey-content`
skill), never generated — so this base does not fabricate Homer-flavored
copy. Phase 11 wires real narrative beats in; this line disappears once a
beat exists for the visible position.

## Empty / permission states

- No steps permission yet / denied / Health Connect missing → handled by
  `StepsPermissionGate`, see [`steps-sync.md`](steps-sync.md). The scene
  itself always renders underneath (starting at 0 m), so the tab is never a
  blank screen while permission is unresolved (§7).
- Quest completion (§6.1's reward screen, "Квест завершён" state) is **not
  implemented in this base** — `progressFraction` is clamped to `1.0` in
  the painter so an over-target total doesn't draw off the line, but there
  is no completion screen or catalog "completed" badge yet.

## Tests

`test/features/journey/presentation/journey_tab_test.dart`:
catalog renders with nothing selected; path view renders once a quest is
started; permission-denied state renders the gate instead of a blank
screen.

`test/features/journey/presentation/journey_path_view_test.dart` covers the
wavy-line placeholder scene directly: the traveler icon renders at the
screen's horizontal centre at rest (fresh quest, no pan yet), and dragging
the scene moves the icon both vertically and horizontally — swaying opposite
the screen direction the line's own pattern shifts in, the parallax cue
`_travelerOffsetX()` exists for. A second group covers the start/end line and markers:
every achievement marker sits at the same fixed top offset regardless of
its position along the route; a marker renders muted before its threshold
and gold right after `applySyncedProgress` crosses it; panning is clamped
at both point A and point B (dragging further past either end, twice,
lands in the same place both times); and a marker's name/status are
nowhere on screen until it's tapped, after which they appear in the
details sheet.

`test/features/journey/domain/route_scale_test.dart` covers
`metersPerScreenWidthFor`/`metersToLineOffset` directly: a configured
quest's own scale, the fallback for an unconfigured one, proportionality,
device-width independence of the scale itself, and the point-A clamp on
negative meters.

`test/features/journey/domain/quest_time_service_test.dart` covers
`questDay`, `paceMetersPerDay`, `estimateArrival` per the §12 mandatory
list (local calendar dates, DST-shaped date jump, zero-pace dash, clamped
negative day-diff, the 7-day rolling window and its under-3-days fallback).

`test/features/journey/presentation/journey_providers_test.dart` covers
`SelectedJourney.build()`'s restore-from-disk branch directly (see
[`steps-sync.md`](steps-sync.md#phase-3--durable-persistence-drift)) — a
database populated before the provider container exists comes back
correctly, and an empty one stays `null` rather than getting stuck.
