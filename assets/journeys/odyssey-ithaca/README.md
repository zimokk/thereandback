# `odyssey-ithaca` — quest assets

| File | What it is | In the repo? |
|---|---|---|
| `locations.json` | Content draft: 120 landmarks, segments, narrative (§11) | yes |
| `map.json` | Route overlay for the drawn map: polyline + landmark hotspots (§6.2) | yes |
| `map.webp` | The drawn map illustration itself (§9.1) | yes — 1024 × 1536, ~330 KB |

## `map.webp` — what the file is

The ink illustration of the Odyssey: Troy on the right, Ithaka top left, the
dashed sea route between them past Aeaea, the Lotus-Eaters, Calypso, Scylla
and Charybdis and the Sirens. `map.json`'s polyline is traced onto **this**
drawing, so replacing it is not a drop-in swap:

- **Aspect ratio 2:3 portrait.** The trace was made against the 1024 × 1536
  source, and every coordinate in `map.json` is normalized (`0..1`) over the
  *whole* image. A larger export is welcome (~2730 × 4096 keeps the ratio and
  matches §6.2's "~4096 px on the long side"), but do **not** crop, pad or
  letterbox it: a different ratio silently moves the route off the drawing.
- **WebP**, dark ink style per §9.
- Named exactly `map.webp`, in this directory. `pubspec.yaml` bundles the
  whole directory, so a re-export needs no pubspec change.

If the file ever goes missing, the Карта tab still works: it draws the route
line and the traveler's position over a plain dark background and says the
illustration isn't in the build (`questMapIllustrationMissing`).

## Re-tracing the route

If the illustration is redrawn, `map.json` has to be re-traced against it.
Reading points off the art by eye is not tight enough — the drawn line has
to be *hugged*, not approximated — so the trace goes through three passes:

1. **Rough trace.** Read pixel coordinates of the drawn route off crops of
   the new art with a 50 px coordinate grid drawn over them (the quickest
   way to place points accurately by eye). A few dozen points is enough.
2. **Snap.** Densify that rough trace (a point every ~4 px), then at each
   point search perpendicular to the local direction for the brightest
   pixels — the drawn dashes — within about a 13 px radius, and move the
   point onto them. This is what actually pulls the trace onto the line;
   pass 1 only has to be close enough for the search radius to find it.
3. **Simplify.** Run Douglas–Peucker (tolerance ~0.8 px) on the snapped,
   smoothed trace to drop redundant points without losing the shape — the
   current `map.json` has 333 vertices from this pass, most of it doing real
   work following the drawing's own wobble, not noise.

Whatever the exact tooling, divide the final pixel coordinates by the
image's width/height, and keep `meters` non-decreasing from `0` at Troy to
`totalMeters` at Ithaca. Check the result by compositing the polyline over
the art at real size and at a few zoomed-in crops — the line should sit on
the drawn dashes the whole way, not just look right zoomed out.
`test/features/quest_map/data/quest_map_repository_test.dart` checks the
invariants and that the file still matches the catalog's route length, but
it cannot see a route traced loosely, or onto the wrong drawing.

## The traveler marker and landmark emoji

`QuestMapView` marks the traveler's position with a small vector Corinthian
helmet (painted, not an emoji — there is no helmet emoji, and a hand-drawn
silhouette fits §9's art direction) and each landmark with an emoji picked
for what it is, in `emojiForLandmarkId`
(`lib/features/quest_map/presentation/quest_map_view.dart`). Adding a
landmark to `map.json` — for the Odyssey or a future quest — that isn't in
that lookup is safe (it falls back to a plain pin, 📍) but loses the
per-landmark identity; add its id and an emoji to the lookup too.

## Known gap

`map.json`'s landmark order follows the **drawing** (Troy → Aeaea → the
Lotus-Eaters → Calypso → Scylla and Charybdis → the Sirens → Ithaca), which
is not the narrative order of `locations.json`'s segments, and the drawn
Cyclops and Underworld sit off the dashed line entirely. The distances in
`map.json` are distributed by drawn arc length, so the traveler moves at a
constant visual speed along the line. Reconciling the two — either redrawing
the route in narrative order or re-anchoring the segments — is content work
still open (CLAUDE.md §14).
