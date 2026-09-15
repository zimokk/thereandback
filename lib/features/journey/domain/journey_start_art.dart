/// Per-quest "start art" (§6.1, §9.1) — a silhouette illustration anchored
/// at the route's own start (point A, 0 m) that fills the dead space
/// between the screen's left edge and the route start whenever the scene is
/// scrolled near the beginning.
///
/// That dead space exists by design elsewhere in this feature:
/// `terrain_layer.dart`'s ground/horizon layers stop exactly at 0 m
/// (`ground_art_layer_test.dart`'s own "the route's own start/end bounds
/// legitimately clip the window" case) — correct, since nothing has been
/// authored before point A, but it left nothing drawn there either. This is
/// the fill for that gap: one named place per quest (the city or tower the
/// traveler actually departs from), not a repeating biome texture.
///
/// A plain `Map`, not a field on `Journey` — the same shape
/// `journeyThemeTrackAssetPath` (`features/audio/domain/
/// journey_theme_track.dart`) already uses for "one more per-quest file, no
/// `build_runner` pass": a quest missing from this map (today: any future
/// quest without its own start art) simply draws nothing here, the same
/// "quest without one" fallback that map's own callers already rely on.
///
/// Paths point at a flat, per-quest file (`assets/journeys/{id}/
/// start_art.webp`), not under that quest's `segments/` folder
/// (`scene_art_catalog.dart`'s `sceneArtAssetPath`) — it is one specific,
/// named illustration, never tiled or repeated, so it does not belong next
/// to the biome layers that are.
const Map<String, String> journeyStartArtAssetPath = {
  // The Odyssey: Troy to Ithaca — the city walls the journey departs from.
  'odyssey-ithaca': 'assets/journeys/odyssey-ithaca/start_art.webp',
  // The Road to the Skyfire — the Bellglass Tower itself (point A).
  'tower-of-lights': 'assets/journeys/tower-of-lights/start_art.webp',
};

/// The start art asset path for [journeyId], or `null` for a quest that
/// ships none — `start_art_layer.dart`'s only caller.
String? startArtAssetPathFor(String journeyId) =>
    journeyStartArtAssetPath[journeyId];
