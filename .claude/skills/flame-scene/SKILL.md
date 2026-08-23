---
name: flame-scene
description: Work on the "Путь" tab — the Flame parallax scene of There and Back. Use when the task touches journey_scene.dart, ParallaxComponent, the sky gradient, the traveler figure, scroll anchors, camera movement, scene performance, or quest completion. Covers CLAUDE.md §6.1 behavior plus the Flame lifecycle and perf rules.
---

# Flame scene — «Путь» tab

The central screen (§6.1). It is a **horizontal ribbon along the whole route**, not a fixed backdrop: scrolling changes layers, region, narrative line and distance to match the route position being viewed.

## Behavior contract (§6.1)

- **Free scroll** — the user can rewind to walked ground and peek ahead.
- Layers move at different speeds via `ParallaxComponent` `velocityMultiplier`: sky nearly static, far hills slow, foreground fast.
- Two anchors at the bottom: **`< Start`** (route beginning) and **`You >`** (current position). Both jump **animated**, never instantly.
- The **traveler figure exists only at `You`**. Scrolling elsewhere shows landscape with no figure — do not render a second traveler.
- New steps **interpolate** the `You` position (`Tween`/`lerp`, ~800–1200 ms). If the user is currently looking at `You`, the camera rides along; if they are looking elsewhere, do not yank the viewport.
- The labels under the scene update in step with the scroll: `День N`, distance, region name, narrative line in italics.

## Sky

Procedural gradient driven by the user's **real local time of day** — night with stars, dawn, day, dusk. Stars are a separate layer whose opacity is tied to the phase. Layer palettes shift with the same phase (§9).

## Landscape

Silhouette layers per biome (plain → forest → mountains → wasteland), composed by route position. Assets per §9.1: flat fills, no internal gradients, **seamless horizontal tiling** — a non-tiling layer shows a visible seam when one biome scrolls for a while.

## Performance and lifecycle (§6.1, §12)

- Target **60 fps on mid-range hardware**; no jank when an overlay appears.
- **Pause the game loop when the tab is not visible.** Wire it to the route/tab visibility, and assert it in a test.
- Preload and cache layer images; never decode during a scroll frame.
- Keep per-frame allocation out of `update()`/`render()` — no new `Paint`, `Vector2` or closures per tick.
- Flame `Game` instance is long-lived; do not rebuild it on every provider change. State flows in via Riverpod → a scene controller, not by recreating components.

## Tests (§12)

- Parallax offset is **linear in scroll position**.
- Game loop **stops** on an inactive tab.
- `You` interpolation reaches the new position and never moves backwards (§5.1).

## Quest completion (§6.1)

When `progress.meters >= journey.totalMeters`:

1. Full-screen **reward screen** — route walked, days on the road, total distance, unlocked trophies. It is **closable** and must not block navigation.
2. The tab enters a **"quest complete"** state: scene frozen on the final view of point B, progress replaced by a prompt to pick the next quest.
3. **No quest auto-starts.** The next one is chosen manually in Settings → "Смена квеста" (§6.5).
4. Steps accumulated after completion are **not lost** — they buffer unattached and credit to the new quest when it is selected, exactly like a normal delta.

## Boundaries

Scene code is `presentation/`. Any distance/position math belongs in `domain/` with tests (see the `domain-math` skill) — the scene converts meters to pixels, it does not decide how far the user walked.
