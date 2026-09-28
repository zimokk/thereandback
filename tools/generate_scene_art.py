#!/usr/bin/env python3
"""Generate the "Путь" scene's per-biome parallax art (CLAUDE.md §6.1, §9.1).

Writes four seamless silhouette tiles per biome into a quest's own
``assets/journeys/{journeyId}/segments/`` folder:

    {biome}_far.webp     distant hills, slowest layer
    {biome}_mid.webp     middle distance
    {biome}_ground.webp  the ground itself — its top edge IS the route's
                         relief (`ground_heightmap_extractor.dart` reads it
                         back, column by column, and the traveler walks on it)
    {biome}_front.webp   close foreground, drawn over the traveler

Plus, for a quest listed in ``START_ART_GENERATORS``, one more file directly
under the quest's own folder (not ``segments/`` — it is one named place, never
tiled):

    start_art.webp       fills the space left of the route's own start (0 m)
                         — the Bellglass Tower (`start_art_layer.dart`)

These are placeholders, not final art: the art source is still open (§9.1).
They exist so the whole pipeline — extraction, tiling, cross-fading, the
traveler following the drawn hills — is real and testable now, and so a real
illustration can replace any single file later with no code change. The app
already treats a missing file as "fall back to the procedural placeholder",
so replacing them one at a time is the expected path, not a migration —
`odyssey-ithaca`'s own start_art.webp already made that swap (CLAUDE.md §14,
2026-09-15: a real illustration of Troy's gate, not this script's output),
which is why it no longer has an entry in ``START_ART_GENERATORS``.

## What a replacement file must satisfy

* **Seamless horizontally.** The tile repeats for the whole biome, so its
  right edge has to continue into its left. `--check` verifies it.
* **`SCREENS_PER_TILE` screen widths wide** (CLAUDE.md §14, 2026-09-16 —
  widened from 1 to 5 so a biome tile repeats far less often; a real
  illustration replacing a placeholder file should cover the same span, not
  one screen, or it will simply repeat 5x more often than its neighbours).
* **Transparent above the silhouette, opaque below it.** The ground layer's
  topmost opaque pixel per column is the relief; a soft or dithered edge
  reads as noise in the walking line.
* **Silhouettes in flat fill, no internal gradients** (§9). Layers differ by
  lightness, not by detail.
* **Ground: keep the silhouette's mean row in the upper half of the tile.**
  It is hung from that mean row, and everything below it has to still reach
  past the bottom of the screen when an authored climb lifts the line.
* **Ground: keep the drawn relief modest** — roughly a tenth of the tile's
  height. The tile is drawn 1.5 screens tall, so a tenth of it is already a
  substantial hill on screen.

Usage:

    python3 tools/generate_scene_art.py              # regenerate everything
    python3 tools/generate_scene_art.py --check      # verify what is there
    python3 tools/generate_scene_art.py --quest tower-of-lights
    python3 tools/generate_scene_art.py --quest odyssey-ithaca --biome ruined_city_coast
"""

from __future__ import annotations

import argparse
import json
import math
import random
import zlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO_ROOT = Path(__file__).resolve().parent.parent
JOURNEYS = REPO_ROOT / "assets" / "journeys"

# A repeated content tile (far/mid/ground/front) covers `SCREENS_PER_TILE`
# screen widths (`scene_art_catalog.dart`'s `sceneArtTileScreens` — the
# single Dart source of truth this has to match; the app itself reads
# width/height back off the decoded file, never a hardcoded pixel count, so
# this constant only has to agree with that one). `PIXELS_PER_SCREEN` is the
# resolution one screen's worth of tile is drawn at — also the relief's
# horizontal resolution, one sample per column. Widened from 1 screen
# (CLAUDE.md §14, 2026-09-16 — at 1 screen the repeat was frequent enough to
# read as a visible pattern even after the tile-seam anti-aliasing bug was
# fixed) to 5.
PIXELS_PER_SCREEN = 1024
SCREENS_PER_TILE = 5
TILE_WIDTH = PIXELS_PER_SCREEN * SCREENS_PER_TILE

# The ground tile is drawn 1.5 screens tall (`groundArtTileHeightFactor`);
# the parallax tiles 1.1 (`environmentLayerHeightFactor`).
GROUND_HEIGHT = 1536
LAYER_HEIGHT = 1024

# Where a parallax (non-ground) silhouette's mean row sits down its own
# tile. Exactly the middle, so the app hangs the tile by its centre and
# `baselineFraction` means "where this layer's ridge sits on screen".
PARALLAX_MEAN_ROW = 0.5

# Where the ground silhouette's mean row sits down its own tile. Above the
# middle, so the fill below it still covers the bottom of the screen when an
# authored climb lifts the line towards the top.
GROUND_MEAN_ROW = 0.40

# Peak-to-peak relief of the ground silhouette, as a fraction of the tile's
# height, for a biome of average roughness. Modest on purpose — see the
# module docstring. Each biome scales it by its own roughness, so open
# fields really are flatter underfoot than a mountain pass rather than
# differing only in the shape of an identically-sized wobble.
GROUND_RELIEF = 0.09

# How many columns wide the ground profile's circular smoothing pass is
# (see `_smooth_circular`, used only for the `ground` layer). Small next
# to `TILE_WIDTH` — it only needs to erase single-column noise spikes, not
# the broader hill shape.
GROUND_SMOOTHING_WINDOW = 9

# A scattered object's own bottom edge, wherever it re-samples `tops` at a
# different x than the single point `_scatter_on_ridge` already placed it
# at, is pushed this many pixels *past* the ridge instead of stopping
# exactly on it. Two different draw calls (the terrain's own `_silhouette`
# and the object's `polygon`/`ellipse`) can rasterize a mathematically
# identical boundary a pixel apart — found as a hairline gap under a
# wall's body and a beached hull's hull (CLAUDE.md §14, 2026-09-22 stage
# 2) even though both used the exact same `tops` values. The overlap is
# invisible (same fill colour as the terrain beneath) and small next to
# any object's own size.
TERRAIN_OVERLAP = 2.0

# §9's palette. Silhouettes are flat fills that differ in lightness, never in
# detail, so each biome is a family plus a lightness ramp rather than four
# separately-invented colour choices.
PALETTES = {
    # family: (far, mid, ground, front) as RGB
    "sea": ((0x2B, 0x33, 0x45), (0x22, 0x29, 0x38), (0x16, 0x1B, 0x26), (0x0C, 0x0E, 0x14)),
    "forest": ((0x2C, 0x34, 0x2E), (0x22, 0x2A, 0x24), (0x17, 0x1D, 0x19), (0x0C, 0x10, 0x0D)),
    "mountain": ((0x33, 0x33, 0x3D), (0x28, 0x28, 0x31), (0x1B, 0x1B, 0x22), (0x0E, 0x0E, 0x12)),
    "plain": ((0x38, 0x33, 0x2A), (0x2B, 0x27, 0x20), (0x1E, 0x1A, 0x15), (0x10, 0x0E, 0x0B)),
    "waste": ((0x3A, 0x30, 0x28), (0x2D, 0x25, 0x1E), (0x1F, 0x19, 0x14), (0x11, 0x0D, 0x0A)),
    "ruins": ((0x31, 0x2E, 0x33), (0x26, 0x24, 0x28), (0x1A, 0x18, 0x1C), (0x0E, 0x0D, 0x0F)),
    "ember": ((0x44, 0x2C, 0x24), (0x33, 0x21, 0x1B), (0x22, 0x16, 0x12), (0x12, 0x0B, 0x09)),
    "night": ((0x25, 0x28, 0x3A), (0x1D, 0x1F, 0x2E), (0x14, 0x15, 0x1F), (0x0A, 0x0B, 0x10)),
}

# Each biome's family and terrain character. `roughness` drives how jagged
# the silhouette is, `peaks` how many major rises fit in one tile.
BIOMES = {
    # The Odyssey: Troy to Ithaca
    "ruined_city_coast": ("ruins", 0.45, 3),
    "raider_coast": ("sea", 0.40, 3),
    "dreaming_dunes": ("waste", 0.20, 2),
    "storm_sea": ("sea", 0.70, 5),
    "giant_fjord": ("mountain", 0.85, 2),
    "floating_isle": ("sea", 0.35, 3),
    "underworld": ("ruins", 0.60, 4),
    "enchanted_forest": ("forest", 0.50, 4),
    "volcanic_crag": ("ember", 0.90, 2),
    "grotto_isle": ("sea", 0.45, 3),
    "sacred_pasture": ("plain", 0.18, 2),
    "moonlit_sea": ("night", 0.25, 4),
    "narrow_strait": ("mountain", 0.75, 2),
    "siren_reef": ("sea", 0.55, 4),
    "open_sea": ("sea", 0.30, 5),
    "garden_harbor": ("forest", 0.30, 3),
    "homeland_coast": ("plain", 0.35, 3),
    # The Road to the Skyfire
    "tower_cliffs": ("mountain", 0.80, 2),
    "pine_forest": ("forest", 0.55, 4),
    "river_valley": ("plain", 0.30, 2),
    "marsh_ruins": ("ruins", 0.35, 3),
    "mountain_pass": ("mountain", 0.95, 2),
    "rocky_coast": ("sea", 0.50, 3),
    "open_fields": ("plain", 0.15, 2),
    "night_meadow": ("night", 0.22, 3),
}

LAYER_NAMES = ("far", "mid", "ground", "front")


def _peaks_per_tile(peaks_per_screen: float) -> int:
    """Scales a `BIOMES`-style peak count — tuned per *screen*, same as
    before `SCREENS_PER_TILE` existed — up to a count for the whole,
    now-wider tile.

    Without this, widening the tile alone would spread the same handful of
    hills over `SCREENS_PER_TILE` screens instead of one, reading as an
    unnaturally flat, empty stretch between them rather than the same
    density of terrain repeating less often.
    """
    return max(1, round(peaks_per_screen * SCREENS_PER_TILE))


def _seamless_profile(
    width: int,
    *,
    seed: int,
    peaks: int,
    roughness: float,
    octaves: int = 18,
) -> list[float]:
    """A closed (seamless) height profile in ``-1..1``.

    Built from `octaves` sine components at *random* integer frequencies —
    not a clean octave-doubling ladder (1x, 2x, 4x, 8x...) — each with its
    own random phase and a power-law amplitude falloff, plus a gentle
    domain warp that un-spaces where the resulting bumps land. A clean
    harmonic ladder is dominated by its low frequencies, so it reads as one
    wave shape repeated at a metronome-even spacing — reported directly
    (CLAUDE.md §14, 2026-09-22) as "the same hills over and over," the
    opposite of a photographed horizon, where no two bumps share a width,
    height or spacing. Random frequencies plus the warp break both kinds
    of evenness without giving up the seam guarantee every component still
    completes a whole number of cycles across the tile width, so the sum
    meets itself exactly at the seam by construction, same as before.
    """
    rng = random.Random(seed)
    # Rougher biomes keep relatively more high-frequency energy (a jagged
    # mountain pass), smoother ones fall off faster (open, gentle fields) —
    # the same job `roughness` already did for the old octave ladder.
    decay = 1.7 - roughness
    max_cycles = max(peaks * 5, 10)
    components = []
    for _ in range(octaves):
        cycles = rng.randint(1, max_cycles)
        amplitude = rng.uniform(0.6, 1.4) / (cycles**decay)
        components.append((cycles, amplitude, rng.uniform(0, 2 * math.pi)))

    # Warps *where along the tile* a given phase of the sum lands, so
    # peaks bunch together in one stretch and spread apart in another
    # instead of falling at even intervals — still exactly periodic since
    # `warp_cycles` is a whole number too.
    warp_cycles = max(1, round(peaks * 0.5))
    warp_phase = rng.uniform(0, 2 * math.pi)
    warp_amount = rng.uniform(0.05, 0.11)

    profile = []
    for x in range(width):
        t = x / width
        warped_t = t + warp_amount * math.sin(2 * math.pi * warp_cycles * t + warp_phase)
        value = sum(
            amplitude * math.sin(2 * math.pi * cycles * warped_t + phase)
            for cycles, amplitude, phase in components
        )
        profile.append(value)

    peak = max(abs(v) for v in profile) or 1.0
    return [v / peak for v in profile]


def _smooth_circular(values: list[float], *, window: int) -> list[float]:
    """A centered moving average over a *closed* sequence.

    Plain moving-average smoothing, but wrapping around both ends instead
    of clamping at them — the same "no edge gets different treatment than
    the interior" requirement `_blur_wrapped` already satisfies for a
    Gaussian blur, done here for a 1-D profile instead of a 2-D image.
    """
    n = len(values)
    half = window // 2
    return [
        sum(values[(i + k) % n] for k in range(-half, half + 1)) / (2 * half + 1)
        for i in range(n)
    ]


def _mid_smoothing_window(roughness: float, profile_peaks: float) -> int:
    """How wide a `_smooth_circular` window a `mid` profile needs to read
    as rolling hills instead of a picket fence of spikes.

    Not a hand-picked constant, and not roughness alone either — both
    tried first and both under-smoothed real biomes (CLAUDE.md §14,
    2026-09-22 stage 3, then 2026-09-23): a box filter of width `W` only
    meaningfully suppresses wavelengths shorter than roughly `W` itself,
    so the window has to be sized against the *actual* shortest
    wavelength `_seamless_profile` can produce for these parameters —
    `TILE_WIDTH / max_cycles`, mirroring that function's own formula —
    not guessed from `roughness` and `peaks` as independent knobs.
    `roughness` still matters, but as *how much of that wavelength* to
    smooth away: a rough biome (a volcanic crag) is supposed to keep more
    of its own jagged texture than a calm one (an open field), so a
    higher roughness keeps a *smaller* fraction of the shortest
    wavelength as its window, not a larger one.
    """
    max_cycles = max(round(profile_peaks * 5), 10)
    shortest_wavelength = TILE_WIDTH / max_cycles
    fraction = max(0.25, 0.75 - 0.5 * roughness)
    return max(15, round(shortest_wavelength * fraction))


def _profile_tops(
    profile: list[float], height: int, mean_row: float, relief: float
) -> list[float]:
    """Per-column top-of-silhouette y, before any pixel is drawn.

    Split out of `_silhouette` so scattered silhouette objects (a tree, a
    column) can look up "where does the hill's own surface sit at this x"
    and plant their own base exactly on it, instead of floating above or
    sinking into the ridge.
    """
    baseline = mean_row * height
    amplitude = relief * height / 2
    return [baseline - value * amplitude for value in profile]


def _silhouette(
    width: int,
    height: int,
    profile: list[float],
    color: tuple[int, int, int],
    *,
    mean_row: float,
    relief: float,
) -> Image.Image:
    """Fills every column from its profile height down to the tile's bottom."""
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for x, top in enumerate(_profile_tops(profile, height, mean_row, relief)):
        draw.line([(x, top), (x, height)], fill=(*color, 255))
    return image


def _scatter_on_ridge(
    image: Image.Image,
    tops: list[float],
    width: int,
    *,
    count: int,
    seed: int,
    draw_one,
    half_extent: float,
) -> None:
    """Plants `count` silhouette objects along a ridge, seamlessly.

    Each object gets its own seed (not a shared, mutating `Random`) so that
    when one near either edge of the tile is also drawn shifted by a full
    tile width — the same "duplicate near the seam" trick `_blur_wrapped`
    uses for a blur kernel, applied here to a discrete shape instead — both
    copies come out pixel-identical rather than two different random draws
    that would visibly disagree exactly at the seam.
    """
    draw = ImageDraw.Draw(image)
    picker = random.Random(seed)
    for _ in range(count):
        obj_seed = picker.randrange(2**31)
        x = picker.uniform(0, width)
        base_y = tops[int(x) % width]
        draw_one(draw, x, base_y, obj_seed)
        if x < half_extent:
            draw_one(draw, x + width, base_y, obj_seed)
        elif x > width - half_extent:
            draw_one(draw, x - width, base_y, obj_seed)


def _draw_cypress(
    draw: ImageDraw.ImageDraw, x: float, base_y: float, color, obj_seed: int, scale: float
) -> None:
    """A tall, narrow, flame-shaped silhouette — the Mediterranean cypress
    that lines the Troad's own coastal hills. Height, taper and lean are
    all randomized per instance (CLAUDE.md §14, 2026-09-22) so a handful of
    cypresses in the same tile read as a grove, not one shape stamped
    several times — a lean is a real cypress's own asymmetry, not noise."""
    r = random.Random(obj_seed)
    # Held well below `scale` and drawn noticeably wider than a first pass
    # tried — even after the first correction, a cluster of these still
    # towered over a smooth hill as bare needles (CLAUDE.md §14, 2026-09-22
    # bug-fix, second pass).
    height = scale * r.uniform(0.45, 0.65)
    width = height * r.uniform(0.26, 0.36)
    trunk_h = height * 0.08
    lean = r.uniform(-0.22, 0.22) * width
    tip_x = x + lean
    draw.rectangle(
        [x - width * 0.08, base_y - trunk_h, x + width * 0.08, base_y], fill=color
    )
    mid_y = base_y - height * r.uniform(0.45, 0.62)
    draw.polygon(
        [
            (x - width / 2, base_y - trunk_h),
            (x - width * 0.16 + lean * 0.4, mid_y),
            (tip_x, base_y - height),
            (x + width * 0.16 + lean * 0.4, mid_y),
            (x + width / 2, base_y - trunk_h),
        ],
        fill=color,
    )


def _draw_olive(
    draw: ImageDraw.ImageDraw, x: float, base_y: float, color, obj_seed: int, scale: float
) -> None:
    """A squat, gnarled trunk under an irregular bushy canopy — an olive
    tree, drawn as a randomized handful of overlapping blobs (3–7, size and
    position all rolled per instance) rather than a fixed five, and a
    trunk that can lean either way, so no two trees in the same tile share
    a silhouette."""
    r = random.Random(obj_seed)
    height = scale * r.uniform(0.55, 1.15)
    trunk_h = height * r.uniform(0.32, 0.48)
    trunk_w = max(2.0, height * 0.09)
    trunk_lean = r.uniform(-0.35, 0.35) * trunk_h
    canopy_x = x + trunk_lean
    draw.line(
        [(x, base_y), (canopy_x, base_y - trunk_h)], fill=color, width=int(trunk_w)
    )
    canopy_r = height * r.uniform(0.32, 0.5)
    canopy_y = base_y - trunk_h - canopy_r * 0.6
    for _ in range(r.randint(3, 7)):
        dx = r.uniform(-canopy_r * 0.6, canopy_r * 0.6)
        dy = r.uniform(-canopy_r * 0.35, canopy_r * 0.3)
        rr = canopy_r * r.uniform(0.5, 1.0)
        draw.ellipse(
            [canopy_x + dx - rr, canopy_y + dy - rr, canopy_x + dx + rr, canopy_y + dy + rr],
            fill=color,
        )


def _draw_broken_column(
    draw: ImageDraw.ImageDraw,
    x: float,
    base_y: float,
    color,
    obj_seed: int,
    scale: float,
    tops: list[float],
    tile_width: int,
) -> None:
    """Troy's own ruins, left on the ridge above the departing traveler —
    most often a column snapped off partway up, sometimes toppled and
    lying flat instead (CLAUDE.md §14, 2026-09-22 — a second silhouette
    shape, not just a rescaled copy of the standing one, so the ruins on a
    ridge don't all read as the same broken post)."""
    r = random.Random(obj_seed)
    if r.random() < 0.3:
        # Toppled: a tapered drum lying on its side, capital fallen beside
        # it. Anchored at *both* ends to the ridge's own local height, not
        # one flat base — a lying log is long enough to visibly float over
        # a dip otherwise (the same bug fixed in `_draw_wall_fragment`).
        length = scale * r.uniform(0.7, 1.2)
        girth = length * r.uniform(0.16, 0.24)
        direction = -1 if r.random() < 0.5 else 1
        near_x, far_x = x, x + direction * length
        near_base = tops[int(near_x) % tile_width]
        far_base = tops[int(far_x) % tile_width]
        draw.polygon(
            [
                (near_x, near_base - girth * 0.5),
                (far_x, far_base - girth * 0.5),
                (far_x, far_base + TERRAIN_OVERLAP),
                (near_x, near_base + TERRAIN_OVERLAP),
            ],
            fill=color,
        )
        # An ellipse's own bounding box only touches its bottom edge at one
        # point (dead center) — sat exactly on `far_base` like the log
        # above, its rounded sides curved away from the ridge with a
        # visible gap under them (CLAUDE.md §14, 2026-09-22 bug-fix,
        # third pass — the same "floats over the terrain" family as the
        # wall and the log, just for a round shape instead of a flat one).
        # Shifting the whole ellipse down so the ridge cuts through its
        # own vertical center buries the lower half in the hill's own
        # fill (identical color, so invisible) and leaves only a clean
        # dome poking up with no gap at any point along its width.
        cap_r = girth * 0.75
        draw.ellipse(
            [far_x - cap_r, far_base - cap_r, far_x + cap_r, far_base + cap_r + TERRAIN_OVERLAP],
            fill=color,
        )
        return

    # Capped well below the toppled variant's own scale and drawn
    # noticeably thicker than a first pass tried (CLAUDE.md §14,
    # 2026-09-22 bug-fix) — a tall, needle-thin column read as a spike or
    # an antenna jutting off the ridge, not ancient stonework.
    height = scale * r.uniform(0.35, 0.65)
    base_width = height * r.uniform(0.28, 0.4)
    taper = r.uniform(0.55, 0.85)  # real columns narrow slightly toward the top
    top_width = base_width * taper
    lean = r.uniform(-0.18, 0.18) * height
    jag = top_width * 0.4
    top = base_y - height
    top_x = x + lean
    draw.polygon(
        [
            (x - base_width / 2, base_y),
            (x - base_width / 2, top + r.uniform(0, jag)),
            (top_x - top_width / 6, top - r.uniform(0, jag)),
            (top_x + top_width / 6, top + r.uniform(0, jag)),
            (top_x + top_width / 2, top - r.uniform(0, jag)),
            (x + base_width / 2, base_y),
        ],
        fill=color,
    )


def _draw_wall_fragment(
    draw: ImageDraw.ImageDraw,
    x: float,
    base_y: float,
    color,
    obj_seed: int,
    scale: float,
    tops: list[float],
    tile_width: int,
) -> None:
    """A low, broken stretch of the city wall — length, merlon count and
    which merlons survived are all randomized per instance (CLAUDE.md §14,
    2026-09-22), and a fragment occasionally carries a taller corner-tower
    stub, so the ruin line doesn't repeat the same battlement shape.

    The wall's own base is sampled along the ridge (`tops`) across its
    whole footprint rather than drawn as one flat rectangle at a single
    height — a wall wide enough is also wide enough to bridge a dip in the
    now-irregular terrain (CLAUDE.md §14, 2026-09-22 profile rewrite) and
    visibly float above it otherwise; reported directly as looking like
    floating scaffolding.
    """
    r = random.Random(obj_seed)
    width = scale * r.uniform(1.2, 2.8)
    height = scale * r.uniform(0.3, 0.6)
    body_h = height * 0.6
    left = x - width / 2

    samples = max(3, int(width // 6) + 1)
    xs = [left + width * i / (samples - 1) for i in range(samples)]
    bases = [tops[int(px) % tile_width] for px in xs]
    body = [(px, b - body_h) for px, b in zip(xs, bases)]
    body += [(px, b + TERRAIN_OVERLAP) for px, b in zip(reversed(xs), reversed(bases))]
    draw.polygon(body, fill=color)

    teeth = r.randint(4, 9)
    tooth_w = width / teeth
    for tooth in range(teeth):
        if r.random() < 0.4:
            continue  # a missing tooth reads as a broken stretch of wall
        tooth_x = left + tooth * tooth_w + tooth_w * 0.35
        local_top = tops[int(tooth_x) % tile_width] - body_h
        tooth_h = (height - body_h) * r.uniform(0.85, 1.15)
        draw.rectangle(
            [tooth_x, local_top - tooth_h, tooth_x + tooth_w * 0.7, local_top],
            fill=color,
        )
    if r.random() < 0.3:
        turret_x = left if r.random() < 0.5 else left + width
        turret_local = tops[int(turret_x) % tile_width] - body_h
        turret_w = width * 0.16
        # Capped well under the earlier 1.6-2.2x — that towered over its
        # own wall like a separate spike (CLAUDE.md §14, 2026-09-22
        # bug-fix, second pass) instead of reading as part of the same
        # ruin.
        turret_h = height * r.uniform(1.1, 1.4)
        draw.rectangle(
            [turret_x - turret_w / 2, turret_local - turret_h, turret_x + turret_w / 2, turret_local],
            fill=color,
        )


def _draw_palisade(
    draw: ImageDraw.ImageDraw,
    x: float,
    base_y: float,
    color,
    obj_seed: int,
    scale: float,
    tops: list[float],
    tile_width: int,
) -> None:
    """A stretch of the Cicones' wooden stockade — sharpened stakes, not
    Troy's dressed stone (`raider_coast` is a different place in a
    different episode, CLAUDE.md §14, 2026-09-22 stage 2). Each stake is
    anchored to its own point on the ridge (the same fix
    `_draw_wall_fragment` needed for stage 1) so a whole stretch of them
    doesn't float over a dip narrower than the stretch itself. Proportions
    are kept modest from the start — stage 1 needed two rounds of
    shrinking the standing column and the cypress after they towered as
    needles, so this one skips straight to their corrected range.
    """
    r = random.Random(obj_seed)
    stake_count = r.randint(5, 9)
    spacing = scale * r.uniform(0.16, 0.24)
    for i in range(stake_count):
        stake_x = x + (i - (stake_count - 1) / 2) * spacing
        stake_base = tops[int(stake_x) % tile_width]
        height = scale * r.uniform(0.35, 0.6)
        width = height * r.uniform(0.22, 0.32)
        lean = r.uniform(-0.15, 0.15) * height
        tip_x = stake_x + lean
        stake_base += TERRAIN_OVERLAP
        if r.random() < 0.35:
            # Snapped by the raid — a jagged stub, not a clean point.
            stub_h = height * r.uniform(0.35, 0.6)
            draw.polygon(
                [
                    (stake_x - width / 2, stake_base),
                    (stake_x - width / 2, stake_base - stub_h + width * 0.4),
                    (tip_x, stake_base - stub_h),
                    (stake_x + width / 2, stake_base - stub_h + width * 0.4),
                    (stake_x + width / 2, stake_base),
                ],
                fill=color,
            )
        else:
            draw.polygon(
                [
                    (stake_x - width / 2, stake_base),
                    (stake_x - width / 2, stake_base - height * 0.82),
                    (tip_x, stake_base - height),
                    (stake_x + width / 2, stake_base - height * 0.82),
                    (stake_x + width / 2, stake_base),
                ],
                fill=color,
            )


def _draw_shipwreck(
    draw: ImageDraw.ImageDraw,
    x: float,
    base_y: float,
    color,
    obj_seed: int,
    scale: float,
    tops: list[float],
    tile_width: int,
) -> None:
    """A beached hull left over from the raid, canted on its side.
    Anchored at both ends to the ridge (the same technique
    `_draw_broken_column`'s toppled variant already uses for stage 1's
    fallen column) — a hull this long would otherwise float over a dip
    exactly like that column did before its own fix.
    """
    r = random.Random(obj_seed)
    length = scale * r.uniform(0.9, 1.4)
    direction = -1 if r.random() < 0.5 else 1
    near_x, far_x = x, x + direction * length
    near_base = tops[int(near_x) % tile_width]
    far_base = tops[int(far_x) % tile_width]
    mid_x = (near_x + far_x) / 2
    mid_base = tops[int(mid_x) % tile_width]
    depth = length * r.uniform(0.16, 0.22)
    draw.polygon(
        [
            (near_x, near_base + TERRAIN_OVERLAP),
            (near_x, near_base - depth * 0.3),
            (mid_x, mid_base - depth),
            (far_x, far_base - depth * 0.3),
            (far_x, far_base + TERRAIN_OVERLAP),
        ],
        fill=color,
    )
    if r.random() < 0.5:
        mast_base = mid_base - depth * 0.7
        mast_h = scale * r.uniform(0.3, 0.5)
        mast_lean = r.uniform(-0.25, 0.25) * mast_h
        mast_w = max(2.0, scale * 0.025)
        draw.line(
            [(mid_x, mast_base), (mid_x + mast_lean, mast_base - mast_h)],
            fill=color,
            width=int(mast_w),
        )


def _draw_reeds(
    draw: ImageDraw.ImageDraw, x: float, base_y: float, color, obj_seed: int, scale: float
) -> None:
    """A clump of tall shore reeds — several thin blades per clump so it
    reads as a stand of vegetation, not one blade repeated (the same
    "several shapes, not one clone" rule stage 1's olive canopy already
    follows)."""
    r = random.Random(obj_seed)
    for _ in range(r.randint(4, 7)):
        blade_x = x + r.uniform(-scale * 0.22, scale * 0.22)
        height = scale * r.uniform(0.4, 0.75)
        lean = r.uniform(-0.3, 0.3) * height
        width = max(1.5, height * 0.035)
        draw.line(
            [(blade_x, base_y), (blade_x + lean, base_y - height)],
            fill=color,
            width=int(width),
        )


def _raider_coast_layer(layer: str, seed: int) -> Image.Image:
    """`raider_coast` — segment `cicones-ismarus`, the Thracian coast
    Odysseus's crew raid and sack right after leaving Troy (Odyssey, Book
    9) — composed the same way stage 1 (`ruined_city_coast`) was
    (CLAUDE.md §14, 2026-09-22), but with this episode's own elements: a
    wooden stockade and beached wrecks from the raid, not Troy's columns
    and dressed stone — the Cicones are a different place in a different
    part of the story, not Troy repeated.

    `ground` is deliberately excluded (`_tile` routes it to
    `_generic_tile` instead) for the same reason as stage 1: its top edge
    IS the walking line.
    """
    family, roughness, peaks = BIOMES["raider_coast"]
    color = PALETTES[family][LAYER_NAMES.index(layer)]

    if layer == "far":
        # A plain distant coastline — unlike Troy's Mount Ida, this
        # episode names no landmark mountain, so there is nothing to draw
        # a dominant peak for. Smoother and lower-relief than mid/front,
        # then blurred, same as stage 1's far layer.
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks * 0.6), roughness=roughness * 0.6
        )
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=0.16
        )
        return _blur_wrapped(image, 1.3)

    if layer == "mid":
        relief = 0.18
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks), roughness=roughness
        )
        # Never blurred, so smoothed the same way stage 1's mid layer is —
        # left at full frequency it reads as a picket fence of spikes
        # instead of coastal bluffs (CLAUDE.md §14, 2026-09-22).
        profile = _smooth_circular(profile, window=25)
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=relief
        )
        tops = _profile_tops(profile, LAYER_HEIGHT, PARALLAX_MEAN_ROW, relief)
        scale = LAYER_HEIGHT * 0.16
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            # A stretch of up to 9 stakes at up to 0.24x scale spacing —
            # half that full span, plus margin, so the wraparound
            # duplicate always triggers correctly near either tile edge.
            count=_peaks_per_tile(0.5), seed=seed + 2, half_extent=scale * 1.3,
            draw_one=lambda d, x, b, s: _draw_palisade(
                d, x, b, color, s, scale, tops, TILE_WIDTH
            ),
        )
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(0.4), seed=seed + 3, half_extent=scale * 1.4 * 1.5,
            draw_one=lambda d, x, b, s: _draw_shipwreck(
                d, x, b, color, s, scale, tops, TILE_WIDTH
            ),
        )
        return image

    if layer == "front":
        relief = 0.12
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks + 2),
            roughness=min(roughness * 1.1, 0.95),
        )
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=relief
        )
        tops = _profile_tops(profile, LAYER_HEIGHT, PARALLAX_MEAN_ROW, relief)
        scale = LAYER_HEIGHT * 0.30
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(2.2), seed=seed + 4, half_extent=scale * 0.3,
            draw_one=lambda d, x, b, s: _draw_reeds(d, x, b, color, s, scale),
        )
        return image

    raise AssertionError(f"unexpected layer {layer!r}")  # ground routes elsewhere


def _draw_storm_ship(
    draw: ImageDraw.ImageDraw, x: float, base_y: float, color, obj_seed: int, scale: float
) -> None:
    """A galley pitching on a storm wave — hull tilted hard to one side,
    mast bent or snapped. Kept short enough (well under stage 1/2's own
    wide objects) that anchoring to one point on the wave, the same way
    the standing column and cypress already do, stays safe — no need for
    the multi-point ridge-conforming `_draw_wall_fragment`/`_draw_palisade`
    use, which is only for objects wide enough to bridge a real dip.
    """
    r = random.Random(obj_seed)
    length = scale * r.uniform(0.55, 0.85)
    tilt = r.uniform(0.15, 0.4) * (1 if r.random() < 0.5 else -1)
    hull_h = length * r.uniform(0.16, 0.22)
    left_x, right_x = x - length / 2, x + length / 2
    left_y, right_y = base_y, base_y - tilt * length
    crest_y = min(left_y, right_y) - hull_h * 1.3
    draw.polygon(
        [
            (left_x, left_y + TERRAIN_OVERLAP),
            (left_x, left_y - hull_h),
            (x, crest_y),
            (right_x, right_y - hull_h),
            (right_x, right_y + TERRAIN_OVERLAP),
        ],
        fill=color,
    )
    mast_x = x + r.uniform(-length * 0.1, length * 0.1)
    mast_base_y = crest_y
    mast_h = scale * r.uniform(0.25, 0.45)
    bend = r.uniform(-0.5, 0.5) * mast_h
    mast_w = max(2.0, scale * 0.025)
    draw.line(
        [(mast_x, mast_base_y), (mast_x + bend, mast_base_y - mast_h)],
        fill=color,
        width=int(mast_w),
    )


def _draw_lightning(
    draw: ImageDraw.ImageDraw, x: float, image_height: int, color, obj_seed: int, scale: float
) -> None:
    """A jagged bolt in the storm sky — decorative only, hanging in the
    upper part of the tile rather than resting on the wave, so none of
    the terrain-conforming machinery the other objects need applies here:
    there is nothing on the ground for a bolt to float above.
    """
    r = random.Random(obj_seed)
    top_y = image_height * r.uniform(0.0, 0.12)
    bottom_y = image_height * r.uniform(0.4, 0.6)
    segments = r.randint(5, 8)
    # A pure random walk occasionally rolls a near-straight path by
    # chance — the first pass did exactly that, rendering as a fat
    # straight bar rather than a crack of lightning (CLAUDE.md §14,
    # 2026-09-22 bug-fix). Alternating the jitter's own sign forces a
    # real zigzag every time instead of leaving it to luck, and the bolt
    # is drawn far thinner than the first attempt's own width.
    half_width = scale * r.uniform(0.012, 0.02)
    step = (bottom_y - top_y) / segments
    zigzag = step * r.uniform(0.4, 0.8)
    cx = x
    direction = 1 if r.random() < 0.5 else -1
    left_points = []
    right_points = []
    for i in range(segments + 1):
        y = top_y + step * i
        left_points.append((cx - half_width, y))
        right_points.append((cx + half_width, y))
        cx += zigzag * direction
        direction *= -1
    draw.polygon(left_points + right_points[::-1], fill=color)


def _draw_flotsam(
    draw: ImageDraw.ImageDraw, x: float, base_y: float, color, obj_seed: int, scale: float
) -> None:
    """A broken oar or splintered plank washed up on a wave crest — a
    single tilted line, the cheapest possible shape, since the front
    layer already carries plenty of visual weight from the wave profile
    itself."""
    r = random.Random(obj_seed)
    length = scale * r.uniform(0.3, 0.55)
    tilt = r.uniform(-0.3, 0.3) * length
    width = max(2.0, length * 0.07)
    draw.line(
        [(x - length / 2, base_y), (x + length / 2, base_y - tilt)],
        fill=color,
        width=int(width),
    )


def _storm_sea_layer(layer: str, seed: int) -> Image.Image:
    """`storm_sea` — segment `storm-cape-malea`, the storm that drives
    Odysseus's fleet past Cape Malea (Odyssey, Book 9), right after the
    Cicones — composed the same way stages 1–2 were (CLAUDE.md §14,
    2026-09-22), with this episode's own elements: storm-tossed galleys
    and lightning over open water, not land ruins or a shore — there is
    no land here at all except the cape itself, glimpsed in the distance.

    `ground` stays on the generic path — its top edge is the walking
    line, same reason as stages 1–2.
    """
    family, roughness, peaks = BIOMES["storm_sea"]
    color = PALETTES[family][LAYER_NAMES.index(layer)]

    if layer == "far":
        # Cape Malea's own headland — the same "one dominant peak" trick
        # as Mount Ida (stage 1): the fleet is being driven past a named
        # point, not an anonymous stretch of coast.
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(1.2), roughness=0.4
        )
        peak_x = random.Random(seed + 1).uniform(0, TILE_WIDTH)
        sigma = TILE_WIDTH * 0.045
        boosted = []
        for x, value in enumerate(profile):
            distance = abs(x - peak_x)
            distance = min(distance, TILE_WIDTH - distance)
            boosted.append(value + 1.3 * math.exp(-(distance**2) / (2 * sigma**2)))
        peak = max(abs(v) for v in boosted) or 1.0
        profile = [v / peak for v in boosted]
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=0.22
        )
        return _blur_wrapped(image, 1.5)

    if layer == "mid":
        relief = 0.16
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks), roughness=roughness
        )
        # `storm_sea` has the highest `roughness` (0.70) of any biome in
        # `BIOMES` — a first pass smoothed it *less* than stages 1–2's
        # land ridges on the theory that a storm sea should stay choppier
        # (window 18 vs 25), which read as a picket fence of thin spikes
        # taller than the ships sailing between them, not water (CLAUDE.md
        # §14, 2026-09-22 bug-fix). The higher the underlying roughness,
        # the wider a smoothing window it takes to round it into swells —
        # widened well past stages 1–2's own window, and `relief` lowered
        # too, so the waves stay shorter than the ships riding them.
        profile = _smooth_circular(profile, window=45)
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=relief
        )
        tops = _profile_tops(profile, LAYER_HEIGHT, PARALLAX_MEAN_ROW, relief)
        scale = LAYER_HEIGHT * 0.16
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(0.35), seed=seed + 2, half_extent=scale * 0.6,
            draw_one=lambda d, x, b, s: _draw_storm_ship(d, x, b, color, s, scale),
        )
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(0.3), seed=seed + 3, half_extent=scale * 0.3,
            draw_one=lambda d, x, b, s: _draw_lightning(d, x, LAYER_HEIGHT, color, s, scale),
        )
        return image

    if layer == "front":
        relief = 0.16
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks + 2),
            roughness=min(roughness * 1.05, 0.95),
        )
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=relief
        )
        tops = _profile_tops(profile, LAYER_HEIGHT, PARALLAX_MEAN_ROW, relief)
        scale = LAYER_HEIGHT * 0.30
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(0.8), seed=seed + 4, half_extent=scale * 0.3,
            draw_one=lambda d, x, b, s: _draw_flotsam(d, x, b, color, s, scale),
        )
        return image

    raise AssertionError(f"unexpected layer {layer!r}")  # ground routes elsewhere


def _draw_boulder(
    draw: ImageDraw.ImageDraw, x: float, base_y: float, color, obj_seed: int, scale: float
) -> None:
    """A jagged standing rock — family-neutral on purpose, unlike the
    named props above: it stands in for "something rocky on the ridge"
    across every biome that needs one (a mountain crag, a reef, a
    volcanic spire), with colour alone doing the differentiating work —
    the same "family plus a lightness ramp" principle §9 already uses for
    colour, extended here to a shared shape (CLAUDE.md §14, 2026-09-23).
    Proportions start from stage 1's own corrected range (chunky, not
    needle-thin) instead of repeating that mistake."""
    r = random.Random(obj_seed)
    height = scale * r.uniform(0.35, 0.65)
    width = height * r.uniform(0.5, 0.75)
    peaks = r.randint(3, 5)
    top_points = []
    for i in range(peaks):
        t = i / (peaks - 1)
        px = x - width / 2 + width * t
        py = base_y - height * r.uniform(0.5, 1.0)
        top_points.append((px, py))
    polygon = (
        [(x - width / 2, base_y + TERRAIN_OVERLAP)]
        + top_points
        + [(x + width / 2, base_y + TERRAIN_OVERLAP)]
    )
    draw.polygon(polygon, fill=color)


def _draw_lotus(
    draw: ImageDraw.ImageDraw, x: float, base_y: float, color, obj_seed: int, scale: float
) -> None:
    """A lotus blossom on a low stem — the flower that gives the
    Lotus-Eaters' shore its own name (Odyssey, Book 9), low and wide
    rather than tall, so a field of them reads as ground cover, not a
    grove of trees."""
    r = random.Random(obj_seed)
    stem_h = scale * r.uniform(0.12, 0.22)
    draw.line(
        [(x, base_y + TERRAIN_OVERLAP), (x, base_y - stem_h)],
        fill=color,
        width=max(2, int(scale * 0.02)),
    )
    bloom_r = scale * r.uniform(0.1, 0.16)
    bloom_y = base_y - stem_h - bloom_r * 0.5
    petals = r.randint(4, 6)
    for i in range(petals):
        angle = (i / max(1, petals - 1)) * math.pi
        dx = math.cos(angle) * bloom_r * 0.8
        dy = -abs(math.sin(angle)) * bloom_r * 0.6
        draw.ellipse(
            [x + dx - bloom_r * 0.5, bloom_y + dy - bloom_r * 0.5,
             x + dx + bloom_r * 0.5, bloom_y + dy + bloom_r * 0.5],
            fill=color,
        )


# How far a prop's own footprint can reach from its scatter point, as a
# multiple of the `scale` value passed *to that prop function* — used to
# size `_scatter_on_ridge`'s `half_extent` (how close to a tile edge an
# instance has to be before it also gets drawn wrapped, so it doesn't miss
# its own seam duplicate). Copied from the exact multiples stages 1–3
# already validated at each call site above, not re-derived from scratch.
_PROP_HALF_EXTENT_MULT = {
    _draw_boulder: 0.35,
    _draw_lotus: 0.3,
    _draw_olive: 0.7,
    _draw_cypress: 0.9,
    _draw_reeds: 0.3,
    _draw_broken_column: 1.5,
    _draw_wall_fragment: 1.5,
    _draw_flotsam: 0.3,
}

# Which props scatter across which layer, for every biome *not* covered by
# a bespoke `_xxx_layer` function above. One entry: `(draw_fn, density,
# scale_mult)` — `density` is peaks-per-screen (same unit `_peaks_per_tile`
# already scales for every other count in this file), `scale_mult`
# multiplies the layer's own base scale before it reaches the prop.
# `_draw_broken_column`/`_draw_wall_fragment` reused here draw the exact
# same ruins as stage 1's Troy — apt for `underworld`/`marsh_ruins`'s own
# ruins and for `floating_isle`'s Aeolus's own wall, not a coincidence.
COMPOSED_BIOME_PROPS: dict[str, dict[str, list[tuple]]] = {
    # The Odyssey: Troy to Ithaca
    "dreaming_dunes": {  # the Lotus-Eaters' shore
        "mid": [(_draw_lotus, 1.0, 1.4)],
        "front": [(_draw_lotus, 2.2, 1.0)],
    },
    "volcanic_crag": {  # the island of the Cyclopes
        "mid": [(_draw_boulder, 1.1, 1.3)],
        "front": [(_draw_boulder, 0.7, 1.0)],
    },
    "floating_isle": {  # Aeolia — Aeolus's own wall
        "mid": [(_draw_wall_fragment, 0.4, 0.9)],
        "front": [(_draw_boulder, 0.4, 0.8)],
    },
    "giant_fjord": {  # the Laestrygonian fjord
        "mid": [(_draw_boulder, 0.9, 1.4)],
        "front": [(_draw_boulder, 0.5, 1.0)],
    },
    "enchanted_forest": {  # Aeaea, Circe's isle
        "mid": [(_draw_cypress, 0.7, 1.0), (_draw_olive, 0.6, 1.0)],
        "front": [(_draw_olive, 1.5, 1.0), (_draw_cypress, 0.6, 0.9)],
    },
    "underworld": {  # the shore of the dead
        "mid": [(_draw_wall_fragment, 0.4, 0.9), (_draw_broken_column, 0.7, 1.0)],
        "front": [(_draw_broken_column, 0.4, 1.0)],
    },
    "siren_reef": {  # the Sirens' rock
        "mid": [(_draw_boulder, 1.0, 1.1)],
        "front": [(_draw_boulder, 0.6, 0.9)],
    },
    "narrow_strait": {  # Scylla and Charybdis
        "mid": [(_draw_boulder, 1.0, 1.4)],
        "front": [(_draw_boulder, 0.5, 1.0)],
    },
    "sacred_pasture": {  # Thrinacia, pastures of the Sun
        "mid": [(_draw_reeds, 0.9, 1.0)],
        "front": [(_draw_reeds, 2.0, 1.0), (_draw_olive, 0.15, 0.8)],
    },
    "open_sea": {  # adrift alone
        "mid": [],
        "front": [(_draw_flotsam, 0.3, 0.8)],
    },
    "grotto_isle": {  # Ogygia, Calypso's isle
        "mid": [(_draw_boulder, 0.6, 1.0), (_draw_olive, 0.3, 0.9)],
        "front": [(_draw_olive, 0.6, 0.9), (_draw_boulder, 0.3, 0.8)],
    },
    "garden_harbor": {  # Scheria, land of the Phaeacians
        "mid": [(_draw_olive, 1.0, 1.0)],
        "front": [(_draw_olive, 1.8, 1.0)],
    },
    "moonlit_sea": {  # the night passage home
        "mid": [],
        "front": [(_draw_flotsam, 0.2, 0.7)],
    },
    "homeland_coast": {  # Ithaca, the homecoming
        "mid": [(_draw_olive, 0.5, 0.9), (_draw_reeds, 0.5, 0.9)],
        "front": [(_draw_reeds, 1.4, 1.0), (_draw_olive, 0.3, 0.9)],
    },
    # The Road to the Skyfire
    "tower_cliffs": {
        "mid": [(_draw_boulder, 0.8, 1.2)],
        "front": [(_draw_boulder, 0.5, 1.0)],
    },
    "pine_forest": {
        "mid": [(_draw_cypress, 1.1, 1.0)],
        "front": [(_draw_cypress, 1.8, 1.0)],
    },
    "river_valley": {
        "mid": [(_draw_reeds, 0.7, 1.0), (_draw_olive, 0.2, 0.9)],
        "front": [(_draw_reeds, 1.5, 1.0)],
    },
    "marsh_ruins": {
        "mid": [(_draw_wall_fragment, 0.4, 0.9), (_draw_broken_column, 0.4, 0.9)],
        "front": [(_draw_reeds, 1.1, 0.9)],
    },
    "mountain_pass": {
        "mid": [(_draw_boulder, 1.0, 1.3)],
        "front": [(_draw_boulder, 0.6, 1.0)],
    },
    "rocky_coast": {
        "mid": [(_draw_boulder, 0.7, 1.0)],
        "front": [(_draw_flotsam, 0.5, 0.9)],
    },
    "open_fields": {
        "mid": [(_draw_reeds, 0.5, 0.9)],
        "front": [(_draw_reeds, 1.2, 0.9)],
    },
    "night_meadow": {
        "mid": [(_draw_reeds, 0.6, 0.9)],
        "front": [(_draw_reeds, 1.3, 0.9)],
    },
}


def _place_prop(
    image: Image.Image,
    tops: list[float],
    draw_fn,
    *,
    biome_scale: float,
    scale_mult: float,
    density: float,
    seed: int,
    color,
) -> None:
    """Scatters one recipe entry from `COMPOSED_BIOME_PROPS` — the shared
    plumbing every prop already needs (`_scatter_on_ridge`'s wraparound
    duplication, the right `half_extent` for this specific shape, and the
    extra `tops`/`tile_width` args only the ridge-conforming wall/column
    need) factored out so `_composed_generic_layer` doesn't repeat it once
    per prop per biome.
    """
    prop_scale = biome_scale * scale_mult
    half_extent = prop_scale * _PROP_HALF_EXTENT_MULT[draw_fn]
    if draw_fn in (_draw_broken_column, _draw_wall_fragment):
        draw_one = lambda d, x, b, s: draw_fn(d, x, b, color, s, prop_scale, tops, TILE_WIDTH)
    else:
        draw_one = lambda d, x, b, s: draw_fn(d, x, b, color, s, prop_scale)
    _scatter_on_ridge(
        image, tops, TILE_WIDTH,
        count=_peaks_per_tile(density), seed=seed, half_extent=half_extent,
        draw_one=draw_one,
    )


def _composed_generic_layer(biome: str, layer: str, seed: int) -> Image.Image:
    """Every biome *not* covered by a bespoke `_xxx_layer` function above
    — 22 of them, too many for a hand-written narrative treatment each
    the way Troy/the Cicones/the storm got (CLAUDE.md §14, 2026-09-23,
    by direct request to extend the same treatment to every remaining
    biome). Composed the same way structurally — an organic
    `_seamless_profile`, `mid` smoothed, props scattered on top — but the
    *props themselves* come from the shared library above plus
    `COMPOSED_BIOME_PROPS`'s per-biome recipe, not bespoke ones: the same
    "family, not per-biome" principle §9's `PALETTES` already applies to
    colour.

    `ground` is excluded (`_tile` routes it to `_generic_tile` instead)
    for the same reason as stages 1–3: its top edge is the walking line.
    """
    family, roughness, peaks = BIOMES[biome]
    color = PALETTES[family][LAYER_NAMES.index(layer)]
    recipe = COMPOSED_BIOME_PROPS.get(biome, {})

    if layer == "far":
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(max(peaks * 0.6, 1)),
            roughness=roughness * 0.6,
        )
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=0.18
        )
        return _blur_wrapped(image, 1.3)

    if layer == "mid":
        # A biome with nothing in its own `mid` recipe (`moonlit_sea`,
        # `open_sea`) is deliberately bare — open water, nothing standing
        # on it — and that same signal doubles as "keep the water itself
        # calm": even a *wider* smoothing window (tried first) couldn't
        # tame `moonlit_sea`'s own `peaks=4` into anything but a jagged
        # mountain range, because the profile's underlying harmonic
        # content was never the problem post-smoothing so much as how
        # much of it there was to begin with (CLAUDE.md §14, 2026-09-23,
        # second pass — found by rendering the widened-window attempt and
        # still not liking it). Fewer harmonics and less relief up front
        # reads as calm water; biomes that DO carry rock props keep the
        # full profile — their jaggedness is the point.
        has_mid_props = bool(recipe.get("mid"))
        relief = 0.19 if has_mid_props else 0.09
        profile_peaks = peaks if has_mid_props else max(1, round(peaks * 0.4))
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(profile_peaks), roughness=roughness
        )
        window = _mid_smoothing_window(roughness, profile_peaks)
        profile = _smooth_circular(profile, window=window)
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=relief
        )
        tops = _profile_tops(profile, LAYER_HEIGHT, PARALLAX_MEAN_ROW, relief)
        scale = LAYER_HEIGHT * 0.16
        for i, (draw_fn, density, scale_mult) in enumerate(recipe.get("mid", [])):
            _place_prop(
                image, tops, draw_fn, biome_scale=scale, scale_mult=scale_mult,
                density=density, seed=seed + 10 + i, color=color,
            )
        return image

    if layer == "front":
        relief = 0.13
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks + 2),
            roughness=min(roughness * 1.1, 0.95),
        )
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=relief
        )
        tops = _profile_tops(profile, LAYER_HEIGHT, PARALLAX_MEAN_ROW, relief)
        scale = LAYER_HEIGHT * 0.30
        for i, (draw_fn, density, scale_mult) in enumerate(recipe.get("front", [])):
            _place_prop(
                image, tops, draw_fn, biome_scale=scale, scale_mult=scale_mult,
                density=density, seed=seed + 20 + i, color=color,
            )
        return image

    raise AssertionError(f"unexpected layer {layer!r}")  # ground routes elsewhere


def _ruined_city_coast_layer(layer: str, seed: int) -> Image.Image:
    """`ruined_city_coast` — segment `troy-departure`, the biome the
    traveler actually walks through right after stepping through the gate
    drawn in `start_art.webp` — composed from named silhouette elements
    instead of the one generic sine-wave hill every other biome still uses
    (`_generic_tile`), by direct request: a plain profile silhouette read
    as an anonymous repeating ridge, not a place a traveler had just left.
    Elements are drawn from the real Troad's own landscape and the
    Odyssey's own iconography — Mount Ida's distant range, the coastal
    hills' olive and cypress groves, and the ruined city's own broken walls
    and columns left on the ridge — not an invented fantasy skyline.

    `ground` is deliberately excluded (`_tile` routes it to
    `_generic_tile` instead): its exact top edge IS the walking line
    (module docstring), so a column or tree planted on it would make the
    traveler's own path spike at every object instead of rolling smoothly
    — the ground stays the plain profile every biome already uses.
    """
    family, roughness, peaks = BIOMES["ruined_city_coast"]
    color = PALETTES[family][LAYER_NAMES.index(layer)]

    if layer == "far":
        # Mount Ida's own range: the usual rolling profile plus one
        # dominant peak recurring once per tile (a circular Gaussian bump,
        # continuous across the seam by construction — no wraparound
        # duplication needed, unlike the discrete objects below), so the
        # horizon reads as a real named mountain rather than an anonymous
        # ridge of even hills.
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(1.4), roughness=0.35
        )
        peak_x = random.Random(seed + 1).uniform(0, TILE_WIDTH)
        sigma = TILE_WIDTH * 0.05
        boosted = []
        for x, value in enumerate(profile):
            distance = abs(x - peak_x)
            distance = min(distance, TILE_WIDTH - distance)
            boosted.append(value + 1.6 * math.exp(-(distance**2) / (2 * sigma**2)))
        peak = max(abs(v) for v in boosted) or 1.0
        profile = [v / peak for v in boosted]
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=0.30
        )
        return _blur_wrapped(image, 1.4)

    if layer == "mid":
        relief = 0.20
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks), roughness=roughness
        )
        # `far` gets the same random-frequency profile but reads as a
        # single smooth mountain because `_blur_wrapped` softens the whole
        # rendered image afterward; `mid` is never blurred (its silhouette
        # is meant to have real edges the ruins can sit on), so left at
        # full frequency it reads as a picket fence of thin spikes instead
        # of rolling hills (CLAUDE.md §14, 2026-09-22 bug-fix). A wider
        # circular smoothing pass than ground's own rounds those spikes
        # into hills while leaving the broader, still non-repeating shape
        # alone.
        profile = _smooth_circular(profile, window=25)
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=relief
        )
        tops = _profile_tops(profile, LAYER_HEIGHT, PARALLAX_MEAN_ROW, relief)
        scale = LAYER_HEIGHT * 0.16
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(0.6), seed=seed + 2, half_extent=scale * 1.5,
            draw_one=lambda d, x, b, s: _draw_wall_fragment(
                d, x, b, color, s, scale, tops, TILE_WIDTH
            ),
        )
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            # Wide enough to cover the toppled variant's one-sided reach
            # (up to ~1.2x its own scale), not just the standing column's
            # narrow footprint — otherwise a toppled instance near either
            # edge would miss its wraparound duplicate.
            count=_peaks_per_tile(1.0), seed=seed + 3, half_extent=scale * 1.1 * 1.5,
            draw_one=lambda d, x, b, s: _draw_broken_column(
                d, x, b, color, s, scale * 1.1, tops, TILE_WIDTH
            ),
        )
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(1.2), seed=seed + 4, half_extent=scale * 0.9,
            draw_one=lambda d, x, b, s: _draw_cypress(d, x, b, color, s, scale),
        )
        return image

    if layer == "front":
        relief = 0.13
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks + 2),
            roughness=min(roughness * 1.1, 0.95),
        )
        image = _silhouette(
            TILE_WIDTH, LAYER_HEIGHT, profile, color, mean_row=PARALLAX_MEAN_ROW, relief=relief
        )
        tops = _profile_tops(profile, LAYER_HEIGHT, PARALLAX_MEAN_ROW, relief)
        scale = LAYER_HEIGHT * 0.30
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(1.5), seed=seed + 5, half_extent=scale * 0.7,
            draw_one=lambda d, x, b, s: _draw_olive(d, x, b, color, s, scale),
        )
        _scatter_on_ridge(
            image, tops, TILE_WIDTH,
            count=_peaks_per_tile(0.4), seed=seed + 6, half_extent=scale * 1.2 * 1.5,
            draw_one=lambda d, x, b, s: _draw_broken_column(
                d, x, b, color, s, scale * 1.2, tops, TILE_WIDTH
            ),
        )
        return image

    raise AssertionError(f"unexpected layer {layer!r}")  # ground routes elsewhere


def _tile(biome: str, layer: str) -> Image.Image:
    # One seed per (biome, layer) so a biome's four layers are different
    # shapes rather than four tints of one, and so regenerating is stable.
    # `crc32` of a plain string, not `hash((biome, layer))` — Python
    # randomizes `str`/`tuple`-of-`str` hashing per *process*
    # (`PYTHONHASHSEED`) unless explicitly disabled, so the old code's own
    # "regenerating is stable" claim was false across separate runs of
    # this script even with no code change at all (CLAUDE.md §14,
    # 2026-09-22 bug-fix — found while trying to reproduce one specific
    # random instance to debug it, which `hash()` made impossible: the
    # same seed expression gave a different value on every invocation).
    # `crc32` is unaffected by that flag.
    seed = zlib.crc32(f"{biome}:{layer}".encode()) % (2**31)
    if biome == "ruined_city_coast" and layer != "ground":
        return _ruined_city_coast_layer(layer, seed)
    if biome == "raider_coast" and layer != "ground":
        return _raider_coast_layer(layer, seed)
    if biome == "storm_sea" and layer != "ground":
        return _storm_sea_layer(layer, seed)
    if biome in COMPOSED_BIOME_PROPS and layer != "ground":
        return _composed_generic_layer(biome, layer, seed)
    return _generic_tile(biome, layer, seed)


def _generic_tile(biome: str, layer: str, seed: int) -> Image.Image:
    family, roughness, peaks = BIOMES[biome]
    color = PALETTES[family][LAYER_NAMES.index(layer)]

    if layer == "ground":
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=_peaks_per_tile(peaks), roughness=roughness
        )
        # `_seamless_profile`'s random-frequency components (CLAUDE.md §14,
        # 2026-09-22) are wanted for the *look* of every layer, but ground's
        # own top edge is read back column-by-column as the walking line —
        # left at full frequency it reads as a rugged, characterful ridge
        # in far/mid/front, but as a jittery, vibrating floor underfoot.
        # A small circular smoothing pass (periodic — safe for a tile that
        # has to repeat) files down single- and few-pixel spikes while
        # leaving the broader, non-repeating shape alone.
        profile = _smooth_circular(profile, window=GROUND_SMOOTHING_WINDOW)
        return _silhouette(
            TILE_WIDTH,
            GROUND_HEIGHT,
            profile,
            color,
            mean_row=GROUND_MEAN_ROW,
            relief=GROUND_RELIEF * (0.45 + 0.75 * roughness),
        )

    # Distant layers read as further away by being smoother and taller in
    # relief, nearer ones as closer by being rougher — the "различаются
    # светлотой, а не деталями" rule keeps the *colour* ramp doing the
    # depth work, this only shapes the outline.
    # Every parallax tile centres its silhouette on its own middle row, so
    # the app can hang it by its centre without needing to know anything
    # about the drawing (`environmentLayerHeightFactor`). Only the ground
    # tile, whose exact top edge is read back as the route's relief, gets a
    # mean row of its own.
    shape = {
        "far": (roughness * 0.5, max(1, peaks - 1), 0.16),
        "mid": (roughness * 0.8, peaks, 0.20),
        "front": (roughness * 1.1, peaks + 2, 0.13),
    }[layer]
    layer_roughness, layer_peaks_per_screen, relief = shape
    profile = _seamless_profile(
        TILE_WIDTH,
        seed=seed,
        peaks=_peaks_per_tile(layer_peaks_per_screen),
        roughness=min(layer_roughness, 0.95),
    )
    image = _silhouette(
        TILE_WIDTH,
        LAYER_HEIGHT,
        profile,
        color,
        mean_row=PARALLAX_MEAN_ROW,
        relief=relief,
    )
    # A whisper of blur on the furthest layer only — atmosphere, not detail.
    if layer == "far":
        image = _blur_wrapped(image, 1.2)
    return image


def _blur_wrapped(image: Image.Image, radius: float) -> Image.Image:
    """Blurs horizontally-seamlessly.

    `GaussianBlur` clamps at the image's edges, so blurring a tile in place
    gives its first and last columns a treatment no interior column gets —
    a small but real step at the wrap, which `--check` catches. Blurring
    three copies side by side and keeping the middle one gives every column,
    the edges included, the same neighbourhood it will actually have once
    the tile repeats.
    """
    width, height = image.size
    wide = Image.new("RGBA", (width * 3, height), (0, 0, 0, 0))
    for index in range(3):
        wide.paste(image, (width * index, 0))
    wide = wide.filter(ImageFilter.GaussianBlur(radius))
    return wide.crop((width, 0, width * 2, height))


def _biomes_of(quest_dir: Path) -> list[str]:
    locations = json.loads((quest_dir / "locations.json").read_text())
    seen: list[str] = []
    for segment in locations["segments"]:
        if segment["biome"] not in seen:
            seen.append(segment["biome"])
    return seen


# The "start art" fills the space left of the route's own start (0 m) —
# `start_art_layer.dart` — with one named illustration per quest, never
# tiled, so it has no `SCREENS_PER_TILE` of its own to inherit. Sized the
# same 2:3 portrait as one screen of the ground tile (`GROUND_HEIGHT`/
# `PIXELS_PER_SCREEN`, deliberately *not* the now-wider `TILE_WIDTH`) for
# the same reason: tall enough, once the app scales it by scene height, to
# reach comfortably past both edges of the screen.
START_ART_WIDTH = PIXELS_PER_SCREEN
START_ART_HEIGHT = GROUND_HEIGHT


def _start_art_color(quest_dir: Path) -> tuple[int, int, int]:
    """The quest's own front-layer colour, at its first segment's biome.

    "The darkest, topmost layer" by direct request — `front` is both:
    `LAYER_NAMES`' own z-order puts it drawn last (topmost), and every
    family in `PALETTES` ramps darkest at that same index. Reading it from
    the quest's *first* segment, rather than picking one family by hand,
    keeps the start art in the same palette the traveler's first steps are
    actually drawn in.
    """
    locations = json.loads((quest_dir / "locations.json").read_text())
    first_biome = locations["segments"][0]["biome"]
    family, _roughness, _peaks = BIOMES[first_biome]
    return PALETTES[family][LAYER_NAMES.index("front")]


def _tower_start_art(color: tuple[int, int, int]) -> Image.Image:
    """The Bellglass Tower — "just a tower" by direct request: a single
    tall tower with a pointed roof over a low wall, simpler than Troy's
    full skyline above.
    """
    width, height = START_ART_WIDTH, START_ART_HEIGHT
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    fill = (*color, 255)

    base_top = int(height * 0.70)
    draw.rectangle([0, base_top, width, height], fill=fill)

    tower_w = int(width * 0.22)
    tower_x = int(width * 0.68)
    tower_top = int(height * 0.16)
    draw.rectangle([tower_x, tower_top, tower_x + tower_w, height], fill=fill)
    apex_y = tower_top - int(width * 0.10)
    draw.polygon(
        [
            (tower_x, tower_top),
            (tower_x + tower_w // 2, apex_y),
            (tower_x + tower_w, tower_top),
        ],
        fill=fill,
    )

    return image


# One generator per quest that ships *placeholder* start art — a quest
# missing from here simply draws nothing (`start_art_layer.dart`'s own
# fallback), the same "not every quest has one" shape
# `journeyThemeTrackAssetPath` already uses. `odyssey-ithaca` is
# deliberately absent (CLAUDE.md §14, 2026-09-15): its `start_art.webp` is
# now a real hand-drawn illustration, not this generator's output, so this
# script must never regenerate it — the same "becomes not needed" retirement
# `assets/journeys/tower-of-lights/README.md` already documents for
# `generate_map.py` once real art lands. Running this script un-checked
# for `odyssey-ithaca` still refreshes its biome tiles; `--check` simply has
# nothing left to verify for its start art.
START_ART_GENERATORS = {
    "tower-of-lights": _tower_start_art,
}


def _seam_error(image: Image.Image) -> tuple[int, int]:
    """How sharp the wrap-around joint is, against the tile's own roughness.

    Returns ``(seam step, largest interior step)`` in pixels of silhouette
    top. A tile repeats cleanly when the joint is no sharper than the
    steepest slope already inside it — *not* when the first and last columns
    are identical, which would instead mean the tile flattens out at its
    edges. The last column is one step before the wrap, so a step there is
    expected; only an outsized one is a visible seam.
    """
    pixels = image.load()
    width, height = image.size

    def top_of(x: int) -> int:
        for y in range(height):
            if pixels[x, y][3] >= 128:
                return y
        return height

    tops = [top_of(x) for x in range(width)]
    interior = max(
        abs(tops[x] - tops[x - 1]) for x in range(1, width)
    )
    return abs(tops[0] - tops[-1]), interior


def generate(
    quests: list[str], *, check_only: bool, biomes: list[str] | None = None
) -> int:
    problems = 0
    for quest in quests:
        quest_dir = JOURNEYS / quest
        segments_dir = quest_dir / "segments"
        segments_dir.mkdir(exist_ok=True)

        tile_count = 0
        for biome in _biomes_of(quest_dir):
            if biomes and biome not in biomes:
                continue
            tile_count += len(LAYER_NAMES)
            if biome not in BIOMES:
                print(f"  ! {quest}/{biome}: no entry in BIOMES")
                problems += 1
                continue
            for layer in LAYER_NAMES:
                path = segments_dir / f"{biome}_{layer}.webp"
                if check_only:
                    if not path.exists():
                        print(f"  ! missing {path.relative_to(REPO_ROOT)}")
                        problems += 1
                        continue
                    seam, interior = _seam_error(
                        Image.open(path).convert("RGBA")
                    )
                    if seam > max(interior, 2):
                        print(
                            f"  ! {path.relative_to(REPO_ROOT)}: seam step of "
                            f"{seam} px against an interior maximum of "
                            f"{interior} px — the tile does not repeat cleanly"
                        )
                        problems += 1
                else:
                    _tile(biome, layer).save(path, "WEBP", lossless=True, quality=90)

        # `--biome` scopes a run to specific biomes only — start art has no
        # biome of its own, so leave it untouched rather than regenerate it
        # as a side effect of a targeted biome run.
        start_art_generator = START_ART_GENERATORS.get(quest) if not biomes else None
        if start_art_generator is not None:
            path = quest_dir / "start_art.webp"
            if check_only:
                if not path.exists():
                    print(f"  ! missing {path.relative_to(REPO_ROOT)}")
                    problems += 1
            else:
                color = _start_art_color(quest_dir)
                start_art_generator(color).save(
                    path, "WEBP", lossless=True, quality=90
                )

        print(f"  {quest}: {tile_count} tiles")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quest", action="append", help="only this quest id")
    parser.add_argument(
        "--biome",
        action="append",
        help="only this biome (within the selected quests) — avoids "
        "touching unrelated already-committed tiles when regenerating "
        "just one",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the committed tiles instead of regenerating them",
    )
    args = parser.parse_args()

    quests = args.quest or sorted(
        p.name for p in JOURNEYS.iterdir() if (p / "locations.json").exists()
    )
    problems = generate(quests, check_only=args.check, biomes=args.biome)
    if problems:
        print(f"{problems} problem(s)")
        return 1
    print("ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
