# `tower-of-lights` — quest assets

| File | What it is | In the repo? |
|---|---|---|
| `locations.json` | Content draft: 56 landmarks, segments, narrative (§11) | yes |
| `locations.ru.json` | Russian translation of `locations.json`'s names/narrative (§11) | yes |
| `map.json` | Route overlay for the drawn map: polyline + landmark hotspots (§6.2) | yes |
| `map.webp` | The map illustration — **placeholder, plain black**, see below (§9.1) | yes — 1024 × 1536, ~3 KB |
| `generate_map.py` | The script that generates `map.json` + `map.webp` (see below) | yes |
| `theme.mp3` | This quest's own background-music track (§6.5, §14 "background music") | yes — see below |

## `map.webp` — what the file actually is

Unlike `odyssey-ithaca/map.webp` (a real hand-drawn ink illustration this
quest's `map.json` was traced onto after the fact), this quest has no
commissioned art yet — the art source for the app as a whole is still an
open decision (CLAUDE.md §9.1). `map.webp` here is a **plain flat black
rectangle** (2026-09-05, by request) — no route line, bands, or landmark
dots drawn into the image at all. It exists only so the Карта tab has an
asset to load and the polyline invariants have a real file to check
against — the same "structure exists, source pending" treatment §9.1
already gives the art pipeline in general, and the same spirit as
`assets/media/README.md`'s procedurally generated placeholder track for the
app's background music. (An earlier version of this placeholder did draw a
dashed line, faint biome bands, and landmark dots into the image itself —
replaced by the plain rectangle above; the app's own runtime overlay, from
`map.json`, is what draws the route now, same as it will over real art.)

`map.json`'s route itself still comes from a Catmull-Rom spline through a
handful of control points in `generate_map.py` — redrawn 2026-09-05 from a
single direct diagonal sweep to a winding, multi-loop composition covering
the whole canvas (a generic switchback "adventure map" shape; no named
locations or characters from any existing IP, only the geometry). Because
there is no illustration to trace it onto, `map.json` is generated
**together with** that spline, not traced onto pre-existing art afterwards:
every landmark's `(x, y)` sits at the exact point along the spline that
corresponds to its `meters` value (arc-length parametrized, so the
traveler moves at constant visual speed along the line, matching
odyssey-ithaca's own polyline convention) — landmarks land essentially
exactly on the drawn line, not just near it.

**Rerunning it** (after editing the spline's control anchors, say, or once
Pillow's WebP encoder gets an update):

```bash
pip install pillow
cd assets/journeys/tower-of-lights
python3 generate_map.py
```

It reads only `locations.json` (already in this directory) and overwrites
`map.json`/`map.webp` in place — no other fixture file to keep in sync by
hand. Not part of `flutter test`/`flutter analyze`/the app build at all
(§9.1 — "не проектировать пайплайн генерации/приёмки арта в коде"); it's a
one-time content-authoring aid a person runs by hand, the same category as
odyssey-ithaca's own (unscripted) trace process.

**Replacing this with real art is a straight swap, not a re-trace**: once a
real illustration exists, retrace `map.json`'s polyline onto it following
`odyssey-ithaca/README.md`'s three-pass method (rough trace → snap → simplify)
and drop in the new `map.webp` — nothing else in this file changes, and
`generate_map.py` itself becomes dead weight to delete at that point, not
something to keep running. Aspect ratio 2:3 portrait is not load-bearing
here the way it is for the Odyssey illustration (there is no existing art
to stay letterboxed to) but is worth keeping for consistency with the rest
of the catalog and §9.1's "~4096 px on the long side" target for the
eventual real export.

If the file ever goes missing, the Карта tab still works — same fallback
as every quest (`questMapIllustrationMissing`): it draws the route line and
the traveler's position over a plain dark background.

## `locations.ru.json` — what the file is

A Russian translation overlay, not a full duplicate of `locations.json`:
just `segments[].name` and `landmarks[].name`/`narrative`, keyed by the
same `id`s, so nothing about the route itself (meters, `departureHour`,
`durationDays`, biome) is duplicated and able to drift out of sync with the
English original. `journey.name`/`pointA`/`pointB` are deliberately **not**
translated here — `quest_picker_view.dart`'s own comment already treats
catalog point-A/B names as data, not translatable UI copy, and that policy
doesn't change per locale. `timeNote` isn't translated either, same
treatment `historicalNote` gets on odyssey-ithaca: an author's aside, never
shown to the traveler as-is.

`journey_flame_scene_view.dart` reads this file's `narrative` overlay
(`journey_narrative_providers.dart`'s `selectedJourneyNarrativeBeatsProvider`)
whenever the app's language is `ru` — the Путь tab's narrative line shows
this file's translated text for a landmark once the traveler (or the
rewound scroll position) has reached it, falling back to the base
`locations.json` text for any `en` viewer. odyssey-ithaca's own "translate
the narrative to ru" item (CLAUDE.md §14) is unaffected by this — it just
has no such overlay file yet, so it always shows its base English text.

## `theme.mp3` — this quest's own track

Unlike `assets/media/journey_theme.wav` (the app's shared default —
§6.5, `assets/media/README.md`), this file only plays while
`tower-of-lights` is the selected quest — `journey_theme_track.dart`'s
`journeyThemeTrackAssetPath` maps this journey's id to it,
`BackgroundMusicPlayer.selectTrack` switches to it (live, if the toggle
is already on) the moment the quest becomes selected, and back to the
shared default the moment it stops being selected. Lives here rather
than in `assets/media/` for the same reason `map.webp`/`locations.json`
do: it's this quest's own content (§4), not an app-wide asset.

**Provenance:** supplied by the repository owner as their own original
studio recording, not commissioned or independently verified by this
tooling — the same posture `assets/media/README.md` already asks for
("check the track is actually cleared for use... before committing it")
applies here too; if that representation ever turns out to be wrong,
replacing this file is the same drop-in swap described for `map.webp`
above (keep the filename, or update the path in
`journey_theme_track.dart`).

It loops (`ReleaseMode.loop`, same as the shared default) — a source
that doesn't already start/end cleanly will click at the seam every
loop.

## Known gap

No `historicalNote` field anywhere in `locations.json` (contrast
odyssey-ithaca, where about half the landmarks carry one) — this is an
original setting with nothing real to anchor a note to, not an omission.
