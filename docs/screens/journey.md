# Screen: Путь (Journey)

Bottom tab 1 of 4 in this base (CLAUDE.md §6.1). Route: **`/journey`**
(initial route of the app). Entry widget: `JourneyTab`
(`lib/features/journey/presentation/journey_tab.dart`).

## What it shows

- **No quest selected** → `QuestPickerView`: the read-only quest catalog
  (one card today — Odyssey, §14). Tapping **Start quest** calls
  `selectedJourneyProvider.notifier.start(journeyId, now: DateTime.now())`.
- **Quest selected** → `StepsPermissionGate` (see
  [`steps-sync.md`](steps-sync.md)) on top, then `JourneyFlameSceneView`
  (Phase 5's real Flame scene — see below):
  - Day counter (`questDay`, §5.3)
  - Distance travelled so far (`formatDistance`, §5.4), gold hero number +
    unit line beneath it
  - `pointA → pointB`
  - A narrative placeholder line (see below)
  - A Flame `FlameGame` scene with camera-driven scroll, animated `You`
    catch-up, and the round `< catalog`/`You >` anchor buttons.

## Phase 5 — the Flame scene (`journey_scene.dart`, `journey_flame_scene_view.dart`)

`flame`/`flame_test` are real dependencies now (CLAUDE.md §3's long-standing
pin, finally pulled in) — the earlier "no art to render yet" deferral (§9.1)
was a deliberate, revisited decision: the scene renders on **procedural
placeholder graphics** instead of waiting for hand-drawn layers, the same
"cheap to swap later" philosophy `AppSceneBackdrop` already used for the
scene's backdrop. Swapping in real `.webp` art later is scoped to the
individual layer components below, not a rewrite of the scene's structure.

Architecture, `lib/features/journey/presentation/`:

- **`JourneyScene`** (`journey_scene.dart`) — the `FlameGame`. Long-lived:
  created once by `JourneyFlameSceneView`'s `initState`, never rebuilt on a
  Riverpod change (CLAUDE.md §6.1/§12). A `World` + `CameraComponent` whose
  `viewfinder.position.x` tracks `panMeters` every `update()` tick —
  Flame's own camera transform *is* the meters→screen conversion, replacing
  the manual `centerX + (meters - pan) * pixelsPerMeter` formula every
  marker used to compute by hand.
- **`JourneySceneController`** (`journey_scene_controller.dart`) — the
  Riverpod↔Flame seam. A plain Dart object (no Flutter/Riverpod import) with
  mutable fields (`journeyId`, `totalMeters`, `progressMeters`,
  `displayedProgressMeters`, `panMeters`, `sceneWidth`/`sceneHeight`,
  `friendRows`, `showFriends`) that every component reads from — the same
  seam shape `BackgroundMusicController` already uses between a Riverpod
  listener and a plain player object.
- **`terrain_layer.dart`** — `worldXFor`/`terrainHeightAt` (top-level, pure)
  and `HorizonTerrainLayer` (the `World` child that draws the horizon line
  every on-path figure stands on). Renders only the camera's currently
  visible window (`game.camera.visibleWorldRect`), never the whole route —
  a quest can span on the order of a hundred screen-widths, so a per-frame
  cost bounded by screen size, not route length, is load-bearing here.
- **`traveler_component.dart`** — `TravelerComponent` (world-space; reused
  for both the player's solid marker and every friend marker, parameterized
  by a `metersProvider` closure + color) and `GhostTravelerComponent` (the
  rewind ghost — a `camera.viewport` child, screen-centred, since "wherever
  the view is centred" is by definition the viewport's own centre).
- **`friend_component.dart`** — `FriendMarkerComponent`: a `TravelerComponent`
  + nickname `TextComponent`, one per row in `controller.friendRows`
  (§6.5's "Друзья на карте" toggle, off by default).
- **`environment_layer.dart`** — `EnvironmentLayer.behind`/`.front`: the "2
  environment layers, one behind the characters, one in front" — silhouette
  placeholder shapes moving at their own `velocityMultiplier`, deliberately
  **not** `World` children (the real camera transform is uniform 1:1; these
  reproduce `ParallaxComponent`'s effect by hand via `parallaxScreenX`,
  since there's no bitmap art yet to feed a real `ParallaxComponent`).
  Decorations are generated procedurally per visible window
  (`math.Random(bucket)`), never stored as a list spanning the whole route.
- **`sky_gradient.dart`** — `SkyGradient`, a plain Flutter `CustomPaint` (not
  a Flame component — it's driven by wall-clock time, not scroll, so it has
  no per-frame reason to live in the game loop). `skyPhaseFor(DateTime)` is
  a pure function picking one of night/dawn/day/dusk.
- **`achievement_overlay.dart`** — `AchievementMarkerOverlay`: markers +
  their dotted guide-lines down to the horizon, still plain Flutter widgets
  (they need `showModalBottomSheet`, which stays outside Flame).
- **`journey_flame_scene_view.dart`** — `JourneyFlameSceneView`, the
  `ConsumerStatefulWidget` that owns `JourneyScene`/`JourneySceneController`,
  hosts `GameWidget`, and pushes every Riverpod value into the controller.
  Also owns the drag-to-pan/return-to-You logic (ported near-unchanged from
  the old placeholder) and the traveler catch-up animation (see below).

New in Phase 5, not present in the earlier placeholder: the solid traveler's
**displayed** position now visibly catches up to a new `progressMeters` over
~1 second (`domain/traveler_interpolation.dart`'s pure
`interpolatedTravelerMeters`, driven by an `AnimationController` in
`journey_flame_scene_view.dart`) instead of snapping — CLAUDE.md §6.1 always
called for this; the CustomPaint placeholder never implemented it.

**Game-loop pause** (§6.1/§12 — "game loop stops on inactive tab"):
`lib/app/active_tab_index.dart`'s `journeySceneActiveProvider` combines
"is the Путь branch currently selected" (`ActiveTabIndex`, pushed by
`AppShell` on every bottom-nav switch — `StatefulShellRoute.indexedStack`
keeps other branches mounted, just unpainted, so this needs its own signal)
with `appLifecycleProvider` (already used by `BackgroundMusicController`).
`JourneyFlameSceneView.build()` mirrors the result onto `_scene.paused`
every rebuild. Leaving the Путь tab *entirely* for the quest catalog (the
`< catalog` button, `browsingCatalogProvider`) is a separate case: that
swaps this view out of `JourneyTab`'s own tree, so the scene is genuinely
unmounted and recreated fresh on return — no extra signal needed there, just
a clean `dispose()`.

Individual figures (the traveler, friends) are painted onto one Flame
canvas inside `GameWidget`, not separate `find.byKey`-able Flutter widgets
— their positioning is tested at the component level
(`traveler_component_test.dart`/`friend_component_test.dart`/
`journey_scene_test.dart`), not by inspecting rendered widget geometry.

## State — providers (`journey_providers.dart`)

| Provider | Shape | Notes |
|---|---|---|
| `journeyCatalogEntriesProvider` | `List<Journey>` | Static list today (`journey_catalog.dart`); Phase 8 swaps in cached Firestore metadata, same shape. |
| `selectedJourneyProvider` | `SelectedQuest?` (Notifier) | **Durable since Phase 3.** `build()` restores whatever was persisted via `progressRepositoryProvider`; `start()` writes through it. See [`steps-sync.md`](steps-sync.md#phase-3--durable-persistence-drift) for how `progressMeters`/`lastSyncedAt` are derived from the drift-backed interval log rather than stored as their own mutable fields. |
| `progressRepositoryProvider` | `ProgressRepository` | Drift-backed. Overridden with an in-memory `AppDatabase` in tests (`testing` skill). |
| `selectedJourneyDetailsProvider` | `Journey?` | Catalog lookup for the currently selected quest. |
| `browsingCatalogProvider` | `bool` (Notifier, autoDispose) | The `< catalog` button's "browsing" mode — swaps `JourneyFlameSceneView` for `QuestPickerView` without touching the active quest. |

`SelectedQuest.progressMeters` is written by
[`steps-sync.md`](steps-sync.md)'s sync flow, not by this screen directly.

## Domain

- `Journey` (`domain/journey.dart`) — id, name, pointA, pointB, totalMeters.
- `SelectedQuest` (`domain/quest_selection.dart`) — see table above.
- `QuestTimeService.questDay` (`domain/quest_time_service.dart`) —
  local-calendar-date day counter (§5.3). The same service also carries
  `paceMetersPerDay`/`estimateArrival`, but this screen only ever needs
  the day counter — see [`quest-stats.md`](quest-stats.md) for the
  pace/ETA half.
- `metersPerScreenWidthFor`/`metersToLineOffset` (`domain/route_scale.dart`)
  — the per-quest meters-per-screen-width config and the pure meters→pixel
  conversion built on it. A plain `Map<String, int>` keyed by journey id,
  not a field on `Journey` — no `build_runner` pass needed to add a quest's
  scale.
- `interpolatedTravelerMeters` (`domain/traveler_interpolation.dart`) — the
  pure catch-up math behind the solid traveler's smooth motion (see above).
- `evaluateAchievements` (`features/achievements/domain/achievement.dart`,
  `achievementCatalog` from `features/achievements/data/`) — reused as-is
  from the Трофеи tab (§6.3) to drive the marker row; this screen adds no
  achievement logic of its own.
- `achievementTitle` (`features/achievements/presentation/
  achievement_titles.dart`) — the `titleKey` → localized string switch,
  shared by `achievements_tab.dart`'s grid and this screen's marker-tap
  sheet so the two can't show a different name for the same achievement.

## l10n keys

`journeyCatalogTitle`, `journeyCatalogStartButton`, `journeyDayCounter`
(`{day}`, no plural — a label, not a count), `journeyNarrativeComingSoon`,
`journeyReturnToYouButton`, `journeyBackToCatalogButton`.

`pointA → pointB` and the distance number itself are **data, not copy** —
not routed through l10n (the arrow is a typographic separator, per the same
note in the source files).

## Narrative placeholder — not a shortcut around real content

`journeyNarrativeComingSoon` ("Narrative for this stretch of the road is
still being written.") is a UI **empty state**, distinct from real
`NarrativeBeat` content. CLAUDE.md §11 is explicit that quest narrative is
human-authored content that belongs with the journey (`journey-content`
skill), never generated — so this base does not fabricate Homer-flavored
copy. Phase 11 wires real narrative beats in; this line disappears once a
beat exists for the visible position.

## Empty / permission states

- No steps permission yet / denied / Health Connect missing → handled by
  `StepsPermissionGate`, see [`steps-sync.md`](steps-sync.md). The scene
  itself always renders underneath (starting at 0 m), so the tab is never a
  blank screen while permission is unresolved (§7).
- Quest completion (§6.1's reward screen, "Квест завершён" state) is **not
  implemented in this base** — still an open follow-up, tracked in
  `docs/implementation-plan.md`'s Phase 5 description.
- The **`< Start`** anchor (jump to point A, mirroring `You >`) is also
  **not implemented in this base** — only the return-to-`You` anchor exists
  today (ported unchanged from the earlier CustomPaint placeholder, which
  never had a `< Start` button either). Same follow-up as above.

## Tests

`test/features/journey/presentation/journey_tab_test.dart`: catalog renders
with nothing selected; the Flame scene renders once a quest is started;
permission-denied state renders the gate instead of a blank screen.

`test/features/journey/presentation/journey_flame_scene_view_test.dart`
covers what's still a real Flutter widget: the return-to-You/back-to-catalog
buttons, the achievement-tap sheet, and the day/distance/narrative block
staying tied to real progress rather than the rewound pan. Uses explicit
`pump()` calls rather than `pumpAndSettle()` throughout — the scene's game
loop ticks continuously, so `pumpAndSettle` never converges while it's
mounted.

`test/features/journey/presentation/journey_scene_test.dart`,
`terrain_layer_test.dart`, `environment_layer_test.dart`,
`traveler_component_test.dart`, `friend_component_test.dart` cover the
Flame-side math and components directly (`flame_test`'s `testWithGame` where
a running game is needed, plain `test` where the assertion is a pure
function): camera-position linearity in `panMeters`, the horizon height
function's world-position-only invariant, per-layer parallax linearity, the
solid/ghost traveler's positioning and visibility rules, and friend marker
placement/labeling.

`test/features/journey/presentation/journey_scene_lifecycle_test.dart`
covers the game-loop pause: paused on a bottom-nav tab switch and on app
backgrounding, resumed on return; and a clean unmount/remount round trip
through the quest catalog (never two scenes mounted at once).

`test/features/journey/presentation/achievement_overlay_test.dart` and
`sky_gradient_test.dart` cover those two extracted pieces in isolation.

`test/app/active_tab_index_test.dart` covers `ActiveTabIndex`/
`journeySceneActiveProvider` directly — the tab-visibility signal the pause
above depends on.

`test/features/journey/domain/route_scale_test.dart` covers
`metersPerScreenWidthFor`/`metersToLineOffset` directly: a configured
quest's own scale, the fallback for an unconfigured one, proportionality,
device-width independence of the scale itself, and the point-A clamp on
negative meters.

`test/features/journey/domain/traveler_interpolation_test.dart` covers the
catch-up math: monotonic, reaches the target exactly at the duration, never
overshoots, and is a no-op when already there.

`test/features/journey/domain/quest_time_service_test.dart` covers
`questDay`, `paceMetersPerDay`, `estimateArrival` per the §12 mandatory
list (local calendar dates, DST-shaped date jump, zero-pace dash, clamped
negative day-diff, the 7-day rolling window and its under-3-days fallback).

`test/features/journey/presentation/journey_providers_test.dart` covers
`SelectedJourney.build()`'s restore-from-disk branch directly (see
[`steps-sync.md`](steps-sync.md#phase-3--durable-persistence-drift)) — a
database populated before the provider container exists comes back
correctly, and an empty one stays `null` rather than getting stuck.
