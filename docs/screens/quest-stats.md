# Screen: Карта / Прогресс (Quest Stats)

Bottom tab 2 of 4 in this base — the "progress" screen the user asked for,
implementing the header of CLAUDE.md §6.2's Quest Stats tab. Route:
**`/quest-stats`**. Entry widget: `QuestStatsTab`
(`lib/features/quest_map/presentation/quest_stats_tab.dart`).

## What it shows

**No quest selected** → `_EmptyState`: explanation + a **Go to Path**
button (`context.go('/journey')`, via `go_router`).

**Quest selected** → `_StatsBody`:

- Total route length (gold hero number) + unit line + `To <pointB>`
- **Quest Started** — `selected.startedAt`, formatted with `formatDate`
  (locale date format, never hand-rolled `dd.MM.yyyy`, §11)
- **Estimated Arrival** — `estimateArrival` (§5.3); renders **`—`** when
  pace is zero, never an infinite/NaN date
- A placeholder panel where the drawn map (§6.2) will render once
  `map.webp`/`map.json` exist (Phase 11) — this base has neither

## Deliberately not built here

The **drawn map itself** (§6.2: ink-illustration route, polyline overlay,
landmark hotspots, friend pins, `InteractiveViewer` pan/zoom) needs
content that doesn't exist yet (§9.1 — art source unpicked; no
`journeys/odyssey-ithaca/map.webp` or `map.json`). Building the pan/zoom
scaffolding around nothing to show would be premature. Phase 11 supplies
the assets; Phase 6 (`docs/implementation-plan.md`) is the map-rendering
work itself.

No Friends tab yet in this base, so no friend-pin list under the stats
either (§6.2's "Challengers" button and friend delta rows are out of
scope here — see `docs/screens/README.md`).

## State — providers

Reads `selectedJourneyProvider` and `selectedJourneyDetailsProvider` from
`journey_providers.dart` (see [`journey.md`](journey.md)) — this screen
owns no provider of its own.

## Domain

- `estimateArrival`, and indirectly `paceMetersPerDay` (`domain/quest_progress.dart`, §5.3).
- `formatDistance`, `formatDate`, `formatEtaDate` (`core/formatters.dart`, §5.4).

## l10n keys

`questStatsToLabel` (`{pointB}`), `questStatsStartedLabel`,
`questStatsEtaLabel`, `questStatsMapComingSoonTitle`,
`questStatsMapComingSoonBody`, `questStatsEmptyTitle`,
`questStatsEmptyBody`, `questStatsEmptyCta`.

The `—` dash for a zero-pace ETA is a typographic glyph, not translated
text (same treatment as the `→` separator in `journey.md`).

## Tests

`test/features/quest_map/presentation/quest_stats_tab_test.dart`: empty
state renders with its CTA; populated state renders the total distance,
`To Ithaca`, both stat labels, and the dash ETA at zero progress.
