#!/usr/bin/env python3
"""Generates this quest's placeholder map.json + map.webp (CLAUDE.md §9.1,
§6.2) from `locations.json`'s own landmark list — no separate fixture file
to keep in sync by hand.

This is a one-time content-authoring aid, not part of the Flutter build
(§9.1 — "не проектировать пайплайн генерации/приёмки арта в коде"): nothing
in `lib/` imports or runs this. Rerun it whenever the route composition
below changes, or as a starting point for a redraw once a real illustration
exists (see this directory's README.md for how a real illustration would
replace it instead).

Usage (from this directory):

    pip install pillow
    python3 generate_map.py

Requires only `locations.json` in the same directory; writes `map.json`
and `map.webp` next to it, overwriting both.

How it works
------------
1. A handful of hand-placed anchor points define a Catmull-Rom spline
   across the image — purely a visual composition, a winding multi-loop
   route covering the whole canvas (2026-09-05: redrawn from the earlier
   single diagonal sweep to a more meandering "adventure map" shape). The
   anchors' *index* order has nothing to do with route meters.
2. The spline is sampled densely and its real pixel arc length computed,
   giving an exact meters-to-point mapping (`point_at_meters`) — arc-length
   parametrized, so the traveler moves at constant visual speed along the
   line, the same invariant `odyssey-ithaca/map.json` keeps (there, kept by
   hand-tracing onto real art instead).
3. Every landmark in `locations.json` is placed via `point_at_meters` at
   its own `meters` value, so it lands exactly on the drawn line rather
   than merely near it (contrast a hand traced map, where a landmark is
   illustrated *beside* the path and only approximately matches it).
4. `map.json`'s `path` vertices are every landmark's meters, plus two
   evenly-spaced filler points between each consecutive pair for a
   smoother-looking line — not the full dense sample set, which would be
   thousands of vertices for no visible benefit.
5. `map.webp` itself is a plain flat black rectangle (2026-09-05, by
   request) — no drawn line, bands, or landmark dots baked into the image
   any more. The spline above still exists purely to place `map.json`'s
   polyline and landmark hotspots; the app's own `Карта` tab draws the
   route line and markers over this image at runtime from that data
   (CLAUDE.md §6.2), same as it would over a real illustration.
"""

import json
import math
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
LOCATIONS_PATH = HERE / "locations.json"
MAP_JSON_PATH = HERE / "map.json"
MAP_WEBP_PATH = HERE / "map.webp"

JOURNEY_ID = "tower-of-lights"
IMAGE_WIDTH, IMAGE_HEIGHT = 1024, 1536  # 2:3 portrait, matches §9.1/§6.2.

# Control anchors for the Catmull-Rom spline, in normalized (0..1) image
# space — a winding, multi-loop route from the Bellglass Tower (top-left)
# down to the Lantern Fields (bottom-right), covering the full canvas in a
# series of switchbacks rather than one direct diagonal sweep (2026-09-05
# redraw). Purely a visual composition (index-uniform parametrization):
# meters are assigned afterwards from real arc length, not from anchor
# index, so these don't need to line up with segment boundaries.
ANCHORS = [
    (0.15, 0.07),  # The Bellglass Tower / The Open Door
    (0.60, 0.12),
    (0.72, 0.28),
    (0.50, 0.38),  # The Singing Pines
    (0.20, 0.48),
    (0.48, 0.55),  # The Golden Fields / River of Mills area
    (0.72, 0.62),
    (0.55, 0.75),  # The Blue Mountains
    (0.18, 0.82),  # The Salt Coast
    (0.35, 0.92),
    (0.78, 0.95),  # Under the Skyfire
]

SAMPLES_PER_SEGMENT = 500

BLACK = (0, 0, 0)


def _catmull_rom(p0, p1, p2, p3, t):
    t2, t3 = t * t, t * t * t
    x = 0.5 * (
        (2 * p1[0])
        + (-p0[0] + p2[0]) * t
        + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2
        + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3
    )
    y = 0.5 * (
        (2 * p1[1])
        + (-p0[1] + p2[1]) * t
        + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2
        + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3
    )
    return x, y


def _sample_spline(anchors):
    """Densely samples a Catmull-Rom spline through `anchors`, clamping the
    tangent at both ends by repeating the first/last point."""
    padded = [anchors[0], *anchors, anchors[-1]]
    dense = []
    for seg in range(len(anchors) - 1):
        p0, p1, p2, p3 = padded[seg], padded[seg + 1], padded[seg + 2], padded[seg + 3]
        start = 0 if seg == 0 else 1
        for i in range(start, SAMPLES_PER_SEGMENT + 1):
            dense.append(_catmull_rom(p0, p1, p2, p3, i / SAMPLES_PER_SEGMENT))
    return dense


def _arc_length_table(dense, width, height):
    """Cumulative pixel arc length at each `dense` sample."""
    cumulative = [0.0]
    for i in range(1, len(dense)):
        dx = (dense[i][0] - dense[i - 1][0]) * width
        dy = (dense[i][1] - dense[i - 1][1]) * height
        cumulative.append(cumulative[-1] + math.hypot(dx, dy))
    return cumulative


def _point_at_meters(meters, *, total_meters, dense, cumulative):
    """The exact (x, y) on the spline at arc-length fraction
    `meters / total_meters`, linearly interpolated between the two nearest
    dense samples."""
    target = meters / total_meters * cumulative[-1]
    lo, hi = 0, len(cumulative) - 1
    while lo < hi:
        mid = (lo + hi) // 2
        if cumulative[mid] < target:
            lo = mid + 1
        else:
            hi = mid
    if lo == 0:
        return dense[0]
    span = cumulative[lo] - cumulative[lo - 1]
    frac = 0.0 if span == 0 else (target - cumulative[lo - 1]) / span
    x = dense[lo - 1][0] + (dense[lo][0] - dense[lo - 1][0]) * frac
    y = dense[lo - 1][1] + (dense[lo][1] - dense[lo - 1][1]) * frac
    return x, y


def _build_path_vertices(landmark_meters, total_meters, point_at):
    """Every landmark's meters, plus two evenly-spaced filler points between
    each consecutive pair, for a smoother-looking drawn line than the bare
    landmark spacing alone."""
    distinct = sorted(set(landmark_meters))
    vertex_meters = []
    for i, m in enumerate(distinct):
        vertex_meters.append(m)
        if i + 1 < len(distinct):
            nxt = distinct[i + 1]
            for k in (1, 2):
                vertex_meters.append(round(m + (nxt - m) * k / 3))
    vertex_meters = sorted(set(vertex_meters))
    if vertex_meters[0] != 0:
        vertex_meters.insert(0, 0)
    if vertex_meters[-1] != total_meters:
        vertex_meters.append(total_meters)

    path = []
    for m in vertex_meters:
        x, y = point_at(m)
        path.append({"x": round(x, 5), "y": round(y, 5), "meters": int(m)})
    return path


def _render_image():
    """Plain flat black rectangle (2026-09-05, by request) — no route line,
    bands, or landmark dots baked in. `map.json`'s polyline/landmarks (built
    from the same spline via `point_at_meters`) are what the app itself
    draws over this at runtime (CLAUDE.md §6.2), same as it would over a
    real illustration."""
    img = Image.new("RGB", (IMAGE_WIDTH, IMAGE_HEIGHT), BLACK)
    img.save(MAP_WEBP_PATH, "WEBP", quality=90)


def main():
    locations = json.loads(LOCATIONS_PATH.read_text())
    total_meters = locations["journey"]["totalMeters"]
    landmarks = locations["landmarks"]

    dense = _sample_spline(ANCHORS)
    cumulative = _arc_length_table(dense, IMAGE_WIDTH, IMAGE_HEIGHT)

    def point_at(meters):
        return _point_at_meters(
            meters,
            total_meters=total_meters,
            dense=dense,
            cumulative=cumulative,
        )

    map_landmarks = []
    for landmark in landmarks:
        x, y = point_at(landmark["meters"])
        map_landmarks.append(
            {
                "id": landmark["id"],
                "name": landmark["name"],
                "x": round(x, 5),
                "y": round(y, 5),
                "meters": landmark["meters"],
            }
        )

    path = _build_path_vertices(
        [l["meters"] for l in landmarks],
        total_meters,
        point_at,
    )

    map_json = {
        "$schemaNote": (
            "Route overlay for the drawn quest map (CLAUDE.md §6.2). This "
            "quest's map.webp is a procedurally generated placeholder "
            "(§9.1: art source not yet chosen) rather than a hand-traced "
            "ink illustration like odyssey-ithaca's — so, unlike that "
            "quest's own map.json, this polyline was generated together "
            "with the image from the same spline (generate_map.py, in "
            "this directory), not traced onto pre-existing art after the "
            "fact. Coordinates are normalized (0..1) over map.webp; "
            "meters along the path are distributed by the spline's own "
            "arc length, so the traveler moves at a constant visual speed "
            "along the line, same invariant as odyssey-ithaca's map.json."
        ),
        "journeyId": JOURNEY_ID,
        "totalMeters": total_meters,
        "image": {
            "asset": f"assets/journeys/{JOURNEY_ID}/map.webp",
            "width": IMAGE_WIDTH,
            "height": IMAGE_HEIGHT,
        },
        "path": path,
        "landmarks": map_landmarks,
    }

    MAP_JSON_PATH.write_text(json.dumps(map_json, indent=2) + "\n")
    _render_image()

    print(f"wrote {MAP_JSON_PATH.name} ({len(path)} vertices) and {MAP_WEBP_PATH.name}")


if __name__ == "__main__":
    main()
