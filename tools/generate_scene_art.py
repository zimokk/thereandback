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
                         — Troy's walls, the Bellglass Tower
                         (`start_art_layer.dart`)

These are placeholders, not final art: the art source is still open (§9.1).
They exist so the whole pipeline — extraction, tiling, cross-fading, the
traveler following the drawn hills — is real and testable now, and so a real
illustration can replace any single file later with no code change. The app
already treats a missing file as "fall back to the procedural placeholder",
so replacing them one at a time is the expected path, not a migration.

## What a replacement file must satisfy

* **Seamless horizontally.** The tile repeats for the whole biome, so its
  right edge has to continue into its left. `--check` verifies it.
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
"""

from __future__ import annotations

import argparse
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO_ROOT = Path(__file__).resolve().parent.parent
JOURNEYS = REPO_ROOT / "assets" / "journeys"

# One tile covers exactly one screen width (`scene_art_catalog.dart`'s
# sceneArtTileMeters). Width is the resolution that relief is read back at —
# one sample per column — so it is also the relief's horizontal resolution.
TILE_WIDTH = 1024

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


def _seamless_profile(
    width: int,
    *,
    seed: int,
    peaks: int,
    roughness: float,
    octaves: int = 4,
) -> list[float]:
    """A closed (seamless) height profile in ``-1..1``.

    Built from whole-number sine harmonics with random phases: every
    component completes a whole number of cycles across the tile, so the
    profile meets itself exactly at the seam — by construction, not by
    blending the ends afterwards, which would flatten the shape there.
    """
    rng = random.Random(seed)
    harmonics = []
    for octave in range(octaves):
        cycles = peaks * (2**octave)
        amplitude = roughness**octave
        harmonics.append((cycles, amplitude, rng.uniform(0, 2 * math.pi)))

    profile = []
    for x in range(width):
        t = x / width
        value = sum(
            amplitude * math.sin(2 * math.pi * cycles * t + phase)
            for cycles, amplitude, phase in harmonics
        )
        profile.append(value)

    peak = max(abs(v) for v in profile) or 1.0
    return [v / peak for v in profile]


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
    baseline = mean_row * height
    amplitude = relief * height / 2

    for x, value in enumerate(profile):
        top = baseline - value * amplitude
        draw.line([(x, top), (x, height)], fill=(*color, 255))
    return image


def _tile(biome: str, layer: str) -> Image.Image:
    family, roughness, peaks = BIOMES[biome]
    color = PALETTES[family][LAYER_NAMES.index(layer)]
    # One seed per (biome, layer) so a biome's four layers are different
    # shapes rather than four tints of one, and so regenerating is stable.
    seed = abs(hash((biome, layer))) % (2**31)

    if layer == "ground":
        profile = _seamless_profile(
            TILE_WIDTH, seed=seed, peaks=peaks, roughness=roughness
        )
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
    layer_roughness, layer_peaks, relief = shape
    profile = _seamless_profile(
        TILE_WIDTH, seed=seed, peaks=layer_peaks, roughness=min(layer_roughness, 0.95)
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
# tiled. Sized the same 2:3 portrait as the ground tile (`GROUND_HEIGHT`/
# `TILE_WIDTH`) for the same reason: tall enough, once the app scales it by
# scene height, to reach comfortably past both edges of the screen.
START_ART_WIDTH = TILE_WIDTH
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


# Troy's own colour — by direct request, not `_start_art_color`'s usual
# "blend with the first segment's biome" pick: AppColors.gold (§9,
# 0xE0AE3F) scaled down to the same order of darkness the front-layer
# palette entries already sit at (PALETTES' front column tops out around
# 0x12), so it reads as "a dark, flat silhouette" alongside the mountains
# rather than a lit-up UI element, while still keeping gold's own hue —
# unlike every biome family above, which are all cool/neutral or ember-warm
# but never actually gold.
_TROY_WALL_COLOR = (0x19, 0x13, 0x07)


def _flatten_silhouette(image: Image.Image, color: tuple[int, int, int]) -> Image.Image:
    """Forces [image] to exactly two pixel states: fully transparent, or
    fully opaque in [color] — no in-between alpha, no blended edge colour.
    `ImageDraw`'s rectangle/polygon fills are already hard-edged (no
    anti-aliasing), so this is normally a no-op; it exists as an explicit,
    unconditional guarantee (direct request) rather than something left
    implicit in "how `ImageDraw` happens to behave", so it still holds if a
    future revision of this generator adds a drawing call that *can*
    anti-alias (an ellipse, a rotated shape, a resize).
    """
    alpha = image.split()[3].point(lambda a: 255 if a >= 128 else 0)
    solid = Image.new("RGBA", image.size, (*color, 255))
    flattened = Image.new("RGBA", image.size, (0, 0, 0, 0))
    flattened.paste(solid, mask=alpha)
    return flattened


def _troy_start_art(_color: tuple[int, int, int]) -> Image.Image:
    """Troy: a dense fortified skyline filling the full left and bottom of
    the tile — a crenellated curtain wall the width of the tile, a stepped
    acropolis/keep rising well above it at the left-centre, a pitched-roof
    building for skyline variety, and twin gate towers flanking a pointed
    archway right at the tile's own right edge — the route's own start
    (0 m) — so the walked line reads as beginning at the gate itself, never
    a stretch of plain wall before it. All flat fill, no internal gradient
    (§9) — same rule the biome tiles above follow — with the drawing itself
    hung from the same `wall_top` mean row (§0.62) `start_art_layer.dart`'s
    `startArtMeanRow` expects, so bigger/taller shapes than the previous
    version still map and clip correctly. Uses its own fixed dark-gold
    colour (`_TROY_WALL_COLOR`), not the [color] every other start-art
    generator blends with its quest's first biome — see that constant's own
    doc comment. Passed through `_flatten_silhouette` before returning, per
    direct request for a hard-thresholded, single-colour result.
    """
    width, height = START_ART_WIDTH, START_ART_HEIGHT
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    fill = (*_TROY_WALL_COLOR, 255)

    def h(fraction: float) -> int:
        return int(height * fraction)

    def w(fraction: float) -> int:
        return int(width * fraction)

    # The base curtain wall: crenellated, spans the full tile width, solid
    # from its own top down to the tile's bottom edge — this alone already
    # satisfies "opaque across the entire bottom" everywhere else on the
    # tile just builds further up from it.
    wall_top = h(0.62)
    merlon = width // 16
    x = 0
    raised = True
    while x < width:
        top = wall_top if raised else wall_top + merlon // 2
        draw.rectangle([x, top, x + merlon, height], fill=fill)
        x += merlon
        raised = not raised

    # Stepped acropolis/keep, left-of-centre — three receding terraces
    # topped by a pointed central tower, plus one smaller flanking tower,
    # so the left half of the tile reads as a dense hill city rather than
    # empty wall.
    draw.rectangle([w(0.12), h(0.58), w(0.42), height], fill=fill)
    draw.rectangle([w(0.17), h(0.50), w(0.37), height], fill=fill)
    keep_x0, keep_x1, keep_top = w(0.24), w(0.32), h(0.30)
    draw.rectangle([keep_x0, keep_top, keep_x1, height], fill=fill)
    draw.polygon(
        [(keep_x0, keep_top), ((keep_x0 + keep_x1) // 2, h(0.20)), (keep_x1, keep_top)],
        fill=fill,
    )
    flank_x0, flank_x1, flank_top = w(0.34), w(0.40), h(0.42)
    draw.rectangle([flank_x0, flank_top, flank_x1, height], fill=fill)
    draw.polygon(
        [(flank_x0, flank_top), ((flank_x0 + flank_x1) // 2, h(0.34)), (flank_x1, flank_top)],
        fill=fill,
    )

    # A pitched-roof building bridging the acropolis and the gate cluster —
    # breaks up the skyline so it does not read as two isolated clusters
    # with dead flat wall between them.
    roof_x0, roof_x1, roof_top = w(0.45), w(0.58), h(0.54)
    draw.rectangle([roof_x0, roof_top, roof_x1, height], fill=fill)
    draw.polygon(
        [(roof_x0, roof_top), ((roof_x0 + roof_x1) // 2, h(0.44)), (roof_x1, roof_top)],
        fill=fill,
    )

    # Twin gate towers flanking a pointed archway, the outer tower's right
    # edge landing exactly on the tile's own right edge (world x 0, the
    # route's start) — the last thing on screen before the golden route
    # line picks up is the gate itself.
    inner_x0, inner_x1, inner_top = w(0.66), w(0.775), h(0.22)
    arch_x0, arch_x1, arch_top = w(0.775), w(0.895), h(0.36)
    outer_x0, outer_x1, outer_top = w(0.895), width, h(0.17)

    draw.rectangle([inner_x0, inner_top, inner_x1, height], fill=fill)
    draw.polygon(
        [(inner_x0, inner_top), ((inner_x0 + inner_x1) // 2, h(0.09)), (inner_x1, inner_top)],
        fill=fill,
    )
    draw.rectangle([arch_x0, arch_top, arch_x1, height], fill=fill)
    draw.polygon(
        [(arch_x0, arch_top), ((arch_x0 + arch_x1) // 2, h(0.23)), (arch_x1, arch_top)],
        fill=fill,
    )
    draw.rectangle([outer_x0, outer_top, outer_x1, height], fill=fill)
    draw.polygon(
        [(outer_x0, outer_top), ((outer_x0 + outer_x1) // 2, h(0.05)), (outer_x1, outer_top)],
        fill=fill,
    )

    return _flatten_silhouette(image, _TROY_WALL_COLOR)


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


# One generator per quest that ships start art — a quest missing from here
# simply draws nothing (`start_art_layer.dart`'s own fallback), the same
# "not every quest has one" shape `journeyThemeTrackAssetPath` already uses.
START_ART_GENERATORS = {
    "odyssey-ithaca": _troy_start_art,
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


def generate(quests: list[str], *, check_only: bool) -> int:
    problems = 0
    for quest in quests:
        quest_dir = JOURNEYS / quest
        segments_dir = quest_dir / "segments"
        segments_dir.mkdir(exist_ok=True)

        for biome in _biomes_of(quest_dir):
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

        start_art_generator = START_ART_GENERATORS.get(quest)
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

        print(f"  {quest}: {len(_biomes_of(quest_dir)) * len(LAYER_NAMES)} tiles")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quest", action="append", help="only this quest id")
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the committed tiles instead of regenerating them",
    )
    args = parser.parse_args()

    quests = args.quest or sorted(
        p.name for p in JOURNEYS.iterdir() if (p / "locations.json").exists()
    )
    problems = generate(quests, check_only=args.check)
    if problems:
        print(f"{problems} problem(s)")
        return 1
    print("ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
