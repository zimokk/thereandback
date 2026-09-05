# `tower-of-lights` — quest assets

| File | What it is | In the repo? |
|---|---|---|
| `locations.json` | Content draft: 56 landmarks, segments, narrative (§11) | yes |
| `map.json` | Route overlay for the drawn map: polyline + landmark hotspots (§6.2) | yes |
| `map.webp` | The map illustration — **placeholder**, see below (§9.1) | yes — 1024 × 1536, ~17 KB |

## `map.webp` — what the file actually is

Unlike `odyssey-ithaca/map.webp` (a real hand-drawn ink illustration this
quest's `map.json` was traced onto after the fact), this quest has no
commissioned art yet — the art source for the app as a whole is still an
open decision (CLAUDE.md §9.1). `map.webp` here is a small script-generated
placeholder: a Catmull-Rom spline through a handful of control points,
rendered as a dashed gold line over a flat dark background with faint
horizontal bands hinting at the eight biomes, plus a dot per landmark. It
exists only so the Карта tab has something to show and the polyline
invariants have a real file to check against — the same "structure exists,
source pending" treatment §9.1 already gives the art pipeline in general,
and the same spirit as `assets/media/README.md`'s procedurally generated
placeholder track for the app's background music.

Because there is no pre-existing illustration to trace, `map.json` here was
generated **together with** the image from the same spline (script kept
outside the repo, not a build step — this is a one-time content-authoring
aid, same as odyssey-ithaca's own trace tooling isn't shipped either):
every landmark's `(x, y)` sits at the exact point along the spline that
corresponds to its `meters` value (arc-length parametrized, so the
traveler moves at constant visual speed along the line, matching
odyssey-ithaca's own polyline convention) — landmarks land essentially
exactly on the drawn line, not just near it.

**Replacing this with real art is a straight swap, not a re-trace**: once a
real illustration exists, retrace `map.json`'s polyline onto it following
`odyssey-ithaca/README.md`'s three-pass method (rough trace → snap → simplify)
and drop in the new `map.webp` — nothing else in this file changes. Aspect
ratio 2:3 portrait is not load-bearing here the way it is for the Odyssey
illustration (there is no existing art to stay letterboxed to) but is worth
keeping for consistency with the rest of the catalog and §9.1's "~4096 px
on the long side" target for the eventual real export.

If the file ever goes missing, the Карта tab still works — same fallback
as every quest (`questMapIllustrationMissing`): it draws the route line and
the traveler's position over a plain dark background.

## Known gap

No `historicalNote` field anywhere in `locations.json` (contrast
odyssey-ithaca, where about half the landmarks carry one) — this is an
original setting with nothing real to anchor a note to, not an omission.
