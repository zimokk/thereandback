import '../domain/route_scale.dart';

/// The four drawn layers one biome ships (CLAUDE.md §6.1's "набор
/// силуэтных слоёв по биомам", §9.1's asset requirements).
///
/// Ordered back to front, which is also the order they are drawn in — the
/// enum's own order is the z-order, so a new depth added here lands in the
/// right place everywhere without a second list to keep in sync.
enum SceneArtLayer {
  /// Distant hills, far behind the traveler — moves least.
  far,

  /// Middle distance, still behind the traveler.
  mid,

  /// The ground itself: the surface every figure stands on, and the layer
  /// whose drawn silhouette *is* the route's small-scale relief
  /// (`ground_heightmap_extractor.dart`).
  ground,

  /// Close foreground, drawn over the traveler — moves most.
  front,
}

/// Where a biome's layer art lives.
///
/// Under the quest's own `segments/` folder, which CLAUDE.md §4 already
/// reserves for exactly this ("слои пейзажа по сегментам") — not a shared
/// app-wide folder, because the two catalog quests have no biome in common
/// (Odyssey's 17 and Tower of Lights' 8 are disjoint sets), so "shared"
/// art would be a folder with nothing shared in it.
///
/// Flat file names rather than a folder per biome: Flutter's asset
/// declarations do not recurse into subdirectories, so a folder per biome
/// would mean one `pubspec.yaml` line per biome — 25 lines that a new quest
/// silently needs another of. One directory entry per quest covers every
/// biome it will ever have.
String sceneArtAssetPath(String journeyId, String biome, SceneArtLayer layer) =>
    'assets/journeys/$journeyId/segments/${biome}_${layer.name}.webp';

/// How much of the route one repetition of a biome's tile covers.
///
/// Exactly one screen width, whatever the quest's own scale
/// (`route_scale.dart`) — so a tile is always drawn at the same size it was
/// authored for, and the art has one fixed aspect ratio to be drawn against
/// (screen width by the layer's own band height) instead of one per quest.
/// The tile then repeats for as long as its biome lasts, which is how a
/// 150 km segment is drawn without a 150 km-wide illustration.
int sceneArtTileMeters(String journeyId) => metersPerScreenWidthFor(journeyId);
