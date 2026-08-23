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
  - A **`CustomPaint` scene**: solid background + a straight horizontal
    line + a traveler dot positioned at `progressMeters / totalMeters`

## Deliberate placeholder: no Flame yet

CLAUDE.md §3 fixes **Flame** (`ParallaxComponent`) as the tech for this
screen — that's still true. What's built here is the screen's *shape*
without its *art*: one straight line stands in for the multi-layer parallax
route, because there is no quest art yet (§9.1 — art source unpicked) and
adding the `flame` dependency with nothing for it to render would be an
unjustified new dependency (§13).

**Phase 5** (`flame-scene` skill, `docs/implementation-plan.md`) replaces
`_StraightPathPainter` in `journey_path_view.dart` with a real
`ParallaxComponent` scene — free scroll, time-of-day sky, animated
traveler interpolation, 60fps game loop that pauses off-screen. Nothing
above the painter (day counter, distance, catalog flow, providers) needs to
change shape when that happens.

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
- `questDay` (`domain/quest_progress.dart`) — local-calendar-date day
  counter (§5.3).

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

`test/features/journey/domain/quest_progress_test.dart` covers `questDay`,
`paceMetersPerDay`, `estimateArrival` per the §12 mandatory list (local
calendar dates, DST-shaped date jump, zero-pace dash, clamped negative
day-diff).

`test/features/journey/presentation/journey_providers_test.dart` covers
`SelectedJourney.build()`'s restore-from-disk branch directly (see
[`steps-sync.md`](steps-sync.md#phase-3--durable-persistence-drift)) — a
database populated before the provider container exists comes back
correctly, and an empty one stays `null` rather than getting stuck.
