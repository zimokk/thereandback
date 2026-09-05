import 'package:freezed_annotation/freezed_annotation.dart';

part 'scene_prop_anchor.freezed.dart';

/// Which of the two existing parallax layers
/// (`environment_layer.dart`'s `EnvironmentLayer.behind`/`.front`) a
/// [ScenePropAnchor] belongs to.
///
/// Named after the layer, not its `velocityMultiplier` — content authors a
/// depth by name, not a tuned physics constant, and a future third depth is
/// a one-line addition here rather than a renumbering of anything already
/// authored.
enum ScenePropLayer { behind, front }

/// A single named, non-procedural background element anchored to one exact
/// route position (§6.1 — e.g. a cyclops silhouette that must appear where
/// the terrain climbs the mountain at its landmark) — as opposed to
/// `EnvironmentLayer`'s existing `_Decoration`s, which are anonymous and
/// procedurally scattered.
///
/// [meters] is the *only* thing this shares with a terrain profile point at
/// the same landmark — each layer converts it through its own existing
/// formula ([ScenePropLayer] here uses `parallaxScreenX`, the terrain line
/// uses `terrainHeightAt`), so the two can never be edited into
/// disagreement: there is one number, not two independently-tuned ones.
@freezed
abstract class ScenePropAnchor with _$ScenePropAnchor {
  const factory ScenePropAnchor({
    required String id,
    required int meters,
    required String asset,
    required ScenePropLayer layer,
  }) = _ScenePropAnchor;
}
