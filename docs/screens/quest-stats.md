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
- **Route map** — the drawn map (§6.2) with the traveler's own position on
  its line: `QuestMapView`
  (`lib/features/quest_map/presentation/quest_map_view.dart`)

## The route map

`QuestMapView` renders, inside an `InteractiveViewer` (pan + zoom, no
network, fully offline):

1. The quest's illustration, `assets/journeys/{journeyId}/map.webp`, in a
   frame carrying the drawing's own aspect ratio and filled edge to edge —
   that is what makes `map.json`'s normalized `(0..1, 0..1)` coordinates
   land where they were traced.
2. The route polyline on top: **solid gold behind** the traveler, **dashed
   ahead** of them (§6.2), split by `splitRouteAt`. Traced tight against the
   illustration's own dashed line (see
   `assets/journeys/odyssey-ithaca/README.md`'s re-trace procedure), so the
   solid/dashed switch reads as a point *on* the drawn route, not near it.
3. The traveler's position, `metersToPoint(polyline, progressMeters)` — a
   small gold Corinthian-helmet silhouette (front view: the T-shaped
   eye/nose slit cut out of the dome, a low crest ridge on top), on a dark
   halo so it stays readable over the ink drawing. Vector, not an emoji —
   there is no helmet emoji, and a hand-drawn silhouette matches §9's
   "solid-fill silhouette, no gradients" art direction the way a borrowed
   glyph wouldn't.
4. Each landmark from `map.json`, marked with an emoji picked for what it
   is (`emojiForLandmarkId` — 🐖 for Circe, who turns Odysseus's crew into
   pigs; 🪷 for the Lotus-Eaters; and so on), on the same dark halo. An id
   the map doesn't have an emoji for falls back to a plain pin (📍) rather
   than crashing — future quests will hit that fallback until someone picks
   glyphs for their landmarks too.

Under the map: the next landmark still ahead and how far it is
(`nextLandmark` + `formatDistance`), or a line saying every landmark is
behind you.

### When the art isn't there

A quest can ship a `map.json` without its illustration. `loadQuestMap`
resolves that up front against the asset manifest, so the screen renders the
route line and the position over a plain background and says so, instead of
failing an image load mid-build. A quest with no usable `map.json` at all
falls back to a one-line notice (`questMapLoadFailed`). The Odyssey ships
both (see `assets/journeys/odyssey-ithaca/README.md`).

## Deliberately not built here

**Landmark hotspots** are parsed from `map.json` and used for the "next
landmark" caption, but nothing on the map is tappable yet, and reached
landmarks are not dimmed/highlighted on the art (§6.2) — the illustration
already draws them, and hit-testing them under a zoomed
`InteractiveViewer` is its own piece of work.

No Friends tab yet in this base, so no friend pins on the map and no
friend-pin list under the stats (§6.2's "Challengers" button and friend
delta rows are out of scope here — see `docs/screens/README.md`).

## State — providers

Reads `selectedJourneyProvider` and `selectedJourneyDetailsProvider` from
`journey_providers.dart` (see [`journey.md`](journey.md)).

The map adds two of its own, in
`lib/features/quest_map/presentation/quest_map_providers.dart`:

- `questMapBundleProvider` — the `AssetBundle` maps are read from
  (`rootBundle`), overridden in widget tests.
- `selectedQuestMapProvider` — the parsed `map.json` of the selected quest
  plus whether its illustration is bundled (`QuestMapAssets`).

## Domain

- `estimateArrival`, and indirectly `paceMetersPerDay` (`domain/quest_progress.dart`, §5.3).
- `formatDistance`, `formatDate`, `formatEtaDate` (`core/formatters.dart`, §5.4).
- `metersToPoint`, `splitRouteAt`, `nextLandmark`
  (`quest_map/domain/route_mapping.dart`, §6.2) — all the map math, pure and
  unit-tested; the painter only scales normalized points by the canvas size.

### Known simplification: pace is a whole-quest average, not a 7-day window

§5.3 specifies pace as a rolling mean over the last 7 calendar days,
falling back to the whole-quest average under 3 days of data.
`paceMetersPerDay` always computes the whole-quest average — the
7-day-window branch needs a persisted per-day history that doesn't exist
yet (Phase 3). The **Estimated Arrival** date on this screen inherits that
simplification: it reacts slower to a recent pace change than §5.3
describes, until Phase 3 lands. This is disclosed in the function's own
doc comment in `quest_progress.dart`; noted here too since this screen is
where the difference is actually visible to a user.

## l10n keys

`questStatsToLabel` (`{pointB}`), `questStatsStartedLabel`,
`questStatsEtaLabel`, `questStatsEmptyTitle`, `questStatsEmptyBody`,
`questStatsEmptyCta`.

Map: `questMapSectionTitle`, `questMapYouAreHere` (the painted marker's
accessibility label), `questMapIllustrationMissing`, `questMapNextLandmark`
(`{name}`, `{distance}`), `questMapAllLandmarksReached`,
`questMapLoadFailed`. Landmark names come from `map.json` — quest data, not
translated copy, same as point A/B (§11).

The `—` dash for a zero-pace ETA is a typographic glyph, not translated
text (same treatment as the `→` separator in `journey.md`).

## Tests

`test/features/quest_map/presentation/quest_stats_tab_test.dart`: empty
state renders with its CTA; populated state renders the total distance,
`To Ithaca`, both stat labels, the dash ETA at zero progress, and the map
section — that one reads the real bundled `map.json`, so it also covers the
`pubspec.yaml` asset wiring.

`test/features/quest_map/presentation/quest_map_view_test.dart`: overlay and
`InteractiveViewer` render, the marker's semantics label is there, the next
landmark caption and its end-of-route variant, the no-illustration fallback,
and the no-`map.json` notice — all against a fake bundle. Plus
`emojiForLandmarkId` on its own: every shipped Odyssey id gets a distinct
emoji, and an unknown id falls back to a pin. (The helmet and the emoji
glyphs themselves are painted on canvas, not widgets — nothing here asserts
on their pixels; that was eyeballed against a real render during
development, the way the route trace itself was.)

`test/features/quest_map/data/quest_map_repository_test.dart`: `map.json`
parsing and every invariant it rejects, plus checks on the shipped Odyssey
file itself (route length matches the catalog, ends at Troy and Ithaca,
landmarks sit near the drawn line).

`test/features/quest_map/domain/route_mapping_test.dart`: `metersToPoint`
edges, `splitRouteAt` (the two stretches meet, no duplicated vertex,
clamping), `nextLandmark`.
