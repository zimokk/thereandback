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
2. The traveler's position, `metersToPoint(polyline, progressMeters)` — a
   small gold Corinthian-helmet silhouette (front view: the T-shaped
   eye/nose slit cut out of the dome, a low crest ridge on top), on a dark
   halo so it stays readable over the ink drawing. Vector, not an emoji —
   there is no helmet emoji, and a hand-drawn silhouette matches §9's
   "solid-fill silhouette, no gradients" art direction the way a borrowed
   glyph wouldn't.
3. Each landmark from `map.json`, marked with an emoji picked for what it
   is (`emojiForLandmarkId` — 🐖 for Circe, who turns Odysseus's crew into
   pigs; 🪷 for the Lotus-Eaters; and so on), on the same dark halo. An id
   the map doesn't have an emoji for falls back to a plain pin (📍) rather
   than crashing — future quests will hit that fallback until someone picks
   glyphs for their landmarks too.

**The route itself is never drawn.** `map.json`'s polyline still positions
both the traveler and the visual reasoning behind where each landmark's
hotspot sits (`route_mapping.dart` is unchanged), but nothing paints a line
along it — the traveler moves along the route invisibly, and only the
illustration's own hand-drawn dashes (baked into `map.webp`, not ours) hint
at the path. This is a deliberate product choice, not a fallback: earlier
revisions of this screen did draw a solid/dashed overlay line, and it was
removed on request.

Under the map: the next landmark still ahead and how far it is
(`nextLandmark` + `formatDistance`), or a line saying every landmark is
behind you.

### Tapping the traveler or a landmark

Tapping the helmet opens a small bubble above it with the quest day and
distance walked so far (`journeyDayCounter` + `formatDistance`, computed
against `QuestMapView.startedAt` — the one new required constructor
argument this feature added).

Tapping a landmark opens a bubble naming it and how far it is from the
traveler: `questMapNextLandmark`'s "Ahead: {name} — {distance} to go"
phrasing (reused verbatim — it already said exactly this) if the landmark
is still ahead, or the new `questMapLandmarkBehindCaption`'s
"Behind: {name} — {distance} ago" if the traveler has already passed it.
Any landmark is tappable this way, not just the next one shown in the
caption below the map.

Only one bubble shows at a time. Tapping the same marker again, or tapping
empty water, closes it; tapping a different marker switches directly to it
without needing a dismiss tap first. `_LoadedMapState` tracks the open
selection; hit-testing is a plain nearest-marker-within-`_tapTargetRadius`
scan in `_handleTap`, done in the same normalized-then-scaled coordinate
space `_RouteOverlayPainter` paints in, not a second source of truth for
where things are. The traveler and a landmark can coincide exactly (day 1,
before any steps, the traveler sits right on the quest's start landmark);
that tie deliberately favors the traveler, not the landmark, since it's
checked first and the landmark loop only overrides on a *strictly* closer
hit.

Tooltip positioning (`_MapTooltip`) reuses the same `(x, y)` → `Alignment`
mapping the painter's coordinates imply, so it pans and zooms with
`InteractiveViewer` exactly like the map and its markers do, rather than
tracking the marker separately.

### When the art isn't there

A quest can ship a `map.json` without its illustration. `loadQuestMap`
resolves that up front against the asset manifest, so the screen renders
the traveler and every landmark over a plain background and says so,
instead of failing an image load mid-build. A quest with no usable
`map.json` at all falls back to a one-line notice (`questMapLoadFailed`).
The Odyssey ships both (see `assets/journeys/odyssey-ithaca/README.md`).

## Deliberately not built here

Reached landmarks are not dimmed/highlighted differently from unreached
ones on the art (§6.2) — the illustration already draws every landmark the
same way, and that distinction would need its own art treatment, not just
code.

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
- `metersToPoint`, `nextLandmark` (`quest_map/domain/route_mapping.dart`,
  §6.2) — the map math actually in use, pure and unit-tested; the painter
  and the tap handler both just scale normalized points by the canvas size.
  `splitRouteAt` still exists and is still tested — it split the route into
  walked/remaining stretches for the overlay line this screen no longer
  draws — but nothing here calls it today.

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
(`{name}`, `{distance}` — also the tap-to-open tooltip for any landmark
still ahead, not just the next one), `questMapLandmarkBehindCaption`
(`{name}`, `{distance}` — the tooltip for a landmark already behind),
`questMapAllLandmarksReached`, `questMapLoadFailed`. Landmark names come
from `map.json` — quest data, not translated copy, same as point A/B (§11).

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
and the no-`map.json` notice — all against a fake bundle. Plus the tap
interactions: the traveler's stat bubble opens and shows the day + distance,
tapping it again closes it, a landmark ahead vs. behind shows the right
phrasing, tapping empty water dismisses, and switching between landmarks
works without an extra dismiss tap in between — including the exact-tie
case (day 1, traveler and the start landmark at the same point) that
regresses if the tie-break in `_handleTap` ever flips back to `<=`. These
tap tests grow the test surface first (`_growViewportForTapping`) since the
illustration's own aspect ratio makes the map taller than the default
800×600 test window, and `tester.tapAt` dispatches at a raw screen
coordinate that a point past the window's edge would silently miss. Plus
`emojiForLandmarkId` on its own: every shipped Odyssey id gets a distinct
emoji, and an unknown id falls back to a pin. (The helmet, the emoji
glyphs, and the tooltip bubbles' exact pixels are eyeballed against a real
render during development, the way the route trace itself was — nothing
here asserts on painted pixels, only on the widget tree taps produce.)

`test/features/quest_map/data/quest_map_repository_test.dart`: `map.json`
parsing and every invariant it rejects, plus checks on the shipped Odyssey
file itself (route length matches the catalog, ends at Troy and Ithaca,
landmarks sit near the drawn line).

`test/features/quest_map/domain/route_mapping_test.dart`: `metersToPoint`
edges, `splitRouteAt` (the two stretches meet, no duplicated vertex,
clamping), `nextLandmark`.
