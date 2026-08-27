# `odyssey-ithaca` — quest assets

| File | What it is | In the repo? |
|---|---|---|
| `locations.json` | Content draft: 120 landmarks, segments, narrative (§11) | yes |
| `map.json` | Route overlay for the drawn map: polyline + landmark hotspots (§6.2) | yes |
| `map.webp` | The drawn map illustration itself (§9.1) | **no — drop it in** |

## `map.webp` — what the file has to be

`map.json` is traced against the supplied ink illustration of the Odyssey
(Troy on the right, Ithaka top left, the dashed sea route between them), so
the art that goes in has to be that same drawing:

- **Aspect ratio 2:3 portrait** — the trace was made against a 1024 × 1536
  source, and every coordinate in `map.json` is normalized (`0..1`) over the
  *whole* image. Ship it larger (~2730 × 4096 keeps the ratio and matches
  §6.2's "~4096 px on the long side"), but do **not** crop, pad or letterbox
  it: a different ratio silently moves the route off the drawing.
- **WebP**, dark ink style per §9.
- Named exactly `map.webp`, in this directory. `pubspec.yaml` bundles the
  whole directory, so no pubspec change is needed once the file is here.

Until the file exists the Карта tab still works: it draws the route line and
the traveler's position over a plain dark background and says the
illustration isn't in the build yet (`questMapIllustrationMissing`).

## Re-tracing the route

If the illustration is redrawn, `map.json` has to be re-traced against it:
read pixel coordinates of the dashed line off the new art, divide by the
image's width/height, and keep `meters` non-decreasing from `0` at Troy to
`totalMeters` at Ithaca. `test/features/quest_map/data/quest_map_repository_test.dart`
checks those invariants and that the file still matches the catalog's route
length.

## Known gap

`map.json`'s landmark order follows the **drawing** (Troy → Aeaea → the
Lotus-Eaters → Calypso → Scylla and Charybdis → the Sirens → Ithaca), which
is not the narrative order of `locations.json`'s segments, and the drawn
Cyclops and Underworld sit off the dashed line entirely. The distances in
`map.json` are distributed by drawn arc length, so the traveler moves at a
constant visual speed along the line. Reconciling the two — either redrawing
the route in narrative order or re-anchoring the segments — is content work
still open (CLAUDE.md §14).
