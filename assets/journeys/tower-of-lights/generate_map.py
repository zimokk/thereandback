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
   across the image — purely a visual composition (§9's palette/style,
   applied here as a dashed gold line over a flat dark background with
   faint bands hinting at the 8 biomes). The anchors' *index* order has
   nothing to do with route meters.
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
"""

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
LOCATIONS_PATH = HERE / "locations.json"
MAP_JSON_PATH = HERE / "map.json"
MAP_WEBP_PATH = HERE / "map.webp"

JOURNEY_ID = "tower-of-lights"
IMAGE_WIDTH, IMAGE_HEIGHT = 1024, 1536  # 2:3 portrait, matches §9.1/§6.2.

# Control anchors for the Catmull-Rom spline, in normalized (0..1) image
# space — a winding route from the Bellglass Tower (bottom) up to the
# Lantern Fields (top). Purely a visual composition (index-uniform
# parametrization): meters are assigned afterwards from real arc length,
# not from anchor index, so these don't need to line up with segment
# boundaries.
ANCHORS = [
    (0.52, 0.90),  # The Bellglass Tower / The Open Door
    (0.70, 0.80),
    (0.62, 0.68),
    (0.76, 0.60),
    (0.66, 0.50),  # The Golden Fields / River of Mills area
    (0.50, 0.44),
    (0.62, 0.34),  # The Blue Mountains zigzag
    (0.44, 0.26),  # The Salt Coast
    (0.30, 0.14),
    (0.20, 0.05),  # Under the Skyfire
]

SAMPLES_PER_SEGMENT = 500

BACKGROUND = (11, 10, 9)
GOLD = (224, 174, 63)
GOLD_DIM = (150, 116, 42)
# Faint region bands hinting at the 8 biomes, without gradients inside any
# one shape (§9 — flat fills only) — alternating very subtle tints, spanning
# the whole canvas rather than following the winding path itself.
BAND_COLORS = [
    (18, 16, 13),
    (14, 18, 15),
    (19, 18, 12),
    (13, 17, 19),
    (16, 14, 17),
    (12, 15, 19),
    (19, 16, 12),
    (13, 13, 20),
]


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


def _render_image(dense, map_landmarks, path):
    img = Image.new("RGB", (IMAGE_WIDTH, IMAGE_HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(img)

    band_count = len(BAND_COLORS)
    for i, color in enumerate(BAND_COLORS):
        y0 = int(IMAGE_HEIGHT * i / band_count)
        y1 = int(IMAGE_HEIGHT * (i + 1) / band_count)
        draw.rectangle([0, y0, IMAGE_WIDTH, y1], fill=color)

    # Dashed route line, drawn from the dense spline samples.
    px_dense = [(x * IMAGE_WIDTH, y * IMAGE_HEIGHT) for x, y in dense]
    dash_on, dash_off = 10, 7
    accumulated = 0.0
    drawing = True
    last = px_dense[0]
    for point in px_dense[1:]:
        seg_len = math.hypot(point[0] - last[0], point[1] - last[1])
        if drawing:
            draw.line([last, point], fill=GOLD, width=3)
        accumulated += seg_len
        limit = dash_on if drawing else dash_off
        if accumulated >= limit:
            accumulated = 0.0
            drawing = not drawing
        last = point

    for landmark in map_landmarks:
        x, y = landmark["x"] * IMAGE_WIDTH, landmark["y"] * IMAGE_HEIGHT
        r = 4
        draw.ellipse([x - r, y - r, x + r, y + r], fill=GOLD_DIM, outline=GOLD)

    # Endpoint markers: point A (square) and point B (ringed dot).
    ax, ay = path[0]["x"] * IMAGE_WIDTH, path[0]["y"] * IMAGE_HEIGHT
    bx, by = path[-1]["x"] * IMAGE_WIDTH, path[-1]["y"] * IMAGE_HEIGHT
    s = 9
    draw.rectangle([ax - s, ay - s, ax + s, ay + s], outline=GOLD, width=2)
    r = 12
    draw.ellipse([bx - r, by - r, bx + r, by + r], outline=GOLD, width=2)
    r2 = 5
    draw.ellipse([bx - r2, by - r2, bx + r2, by + r2], fill=GOLD)

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
    _render_image(dense, map_landmarks, path)

    print(f"wrote {MAP_JSON_PATH.name} ({len(path)} vertices) and {MAP_WEBP_PATH.name}")


if __name__ == "__main__":
    main()
