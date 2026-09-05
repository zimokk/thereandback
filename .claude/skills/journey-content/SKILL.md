---
name: journey-content
description: Add or edit quest content for There and Back — a new journey, its locations, segments, narrative beats, landmarks, map.json polyline or assets under assets/journeys/. Use when the user asks to add a quest/маршрут/квест, write narrative, or wire a drawn map.
---

# Quest content

A quest is editorial content, not code (§8). Files live under:

```
assets/journeys/{journeyId}/
  map.webp        # one drawn map per quest, ink-illustration style
  map.json        # route polyline, landmarks, distance anchors
  segments/       # parallax layers per segment
  locations.json  # working draft of locations + narrative
```

The first catalog quest is **«The Odyssey: Troy to Ithaca»** (`assets/journeys/odyssey-ithaca/`). Other catalog quests use the project's own fantasy world — whose name and regions are **still undecided** (§14); use placeholders and flag them rather than inventing a final setting.

## Segments and narrative (§5, §11)

- `Segment` — a route stretch `[fromMeters, toMeters]` with region, biome and its layer set.
- `NarrativeBeat` — one narrative line anchored to a position in **meters**.
- Narrative is **written by a human, never generated** (§11), and it is **localizable content** (`ru`, `en`) — not string literals in code.
- Tone (§1): progress on a journey, not fitness. "День 5, 5.23 километра, перешёл ручей по узкому мостику" — never "8412 шагов".
- Beat density per quest is an **open question** (§14) — keep spacing consistent within a quest and note the choice.

## map.json

- Route polyline in **normalized `(0..1, 0..1)`** coordinates over `map.webp`, with **cumulative meters at each vertex** — that is what makes meters ↔ map point reversible (§6.2).
- Landmarks are **drawn into the image**; `map.json` holds only their interactive hotspots. Hotspot coordinates are taken **after** the art exists (§9.1).
- Landmarks not yet reached render muted; walked path styled, unwalked dashed.
- Validate: monotonically increasing distances, first vertex 0, last vertex == `journey.totalMeters`, every coordinate within `0..1`.

## Art (§9.1)

The art source is **not decided** (§14) — do not build a generation/acceptance pipeline in code. Regardless of source, layers need: flat silhouette fills, no internal gradients, one file per layer (sky / far / mid / foreground), a shared palette within a biome, and **seamless horizontal tiling**. The map is a single ~4096 px WebP with mip levels; SVG only if the art is natively vector. Palette and stroke weights come from §9, per project — not per illustrator's taste, or quests drift apart visually.

## Domain and catalog wiring

- `Journey`: id, title, total length in **integer meters**, segments, map assets (§5).
- Catalog metadata goes to Firestore `journeys/{journeyId}` (read-only for clients, §8); heavy assets to Storage, cached on device.
- Adding a quest must not require code changes beyond registering content.

## Verify

- The polyline test at both edges — 0 m and full length (§12).
- `flutter test` green; assets declared in `pubspec.yaml`; the app still opens the quest fully offline.
