import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../domain/ground_heightmap.dart';
import 'ground_heightmap_extractor.dart';
import 'scene_art_catalog.dart';

/// One biome's loaded art: the decoded image per layer that ships one, plus
/// the relief read off the ground layer (§6.1, §9.1).
///
/// [layers] is sparse on purpose — a biome part-way through being drawn can
/// ship, say, only its ground and far layers, and the scene simply draws
/// what exists and falls back to its procedural placeholder for the rest.
/// That is what makes "replace the generated placeholder art file by file"
/// (this task's own rollout) work without a code change per file.
typedef BiomeArt = ({
  String biome,
  Map<SceneArtLayer, ui.Image> layers,
  GroundHeightmap? ground,
});

/// Loads biome art on demand and keeps what the scene is currently drawing.
abstract class SceneArtRepository {
  /// The loaded art for one biome, or `null` when that biome ships no art
  /// at all — today, every biome, until the generated tiles land. Repeated
  /// calls for the same biome share one load rather than decoding twice.
  Future<BiomeArt?> loadBiome({
    required String journeyId,
    required String biome,
  });

  /// The sprite for one anchored scene prop (`ScenePropAnchor.asset` — e.g.
  /// a cyclops silhouette at its own landmark), or `null` while it is
  /// loading or if the quest names a file it does not ship.
  ///
  /// Synchronous and non-blocking on purpose: it is called from the render
  /// loop, which cannot await. The first call starts the load and returns
  /// `null` (the caller draws its placeholder); once the image arrives every
  /// later call returns it.
  ui.Image? propSprite(String asset);

  /// Drops (and disposes) every cached biome except [biomes].
  ///
  /// The caller is what knows which biomes are on screen or about to be —
  /// this class deliberately does not guess, because disposing a `ui.Image`
  /// the scene is still drawing would crash the frame rather than just look
  /// wrong.
  void retainOnly(Iterable<String> biomes);
}

/// Decodes encoded image bytes — injectable so a test can stand in for the
/// engine's own decoder.
typedef SceneImageDecoder = Future<ui.Image> Function(Uint8List bytes);

/// The real [SceneArtRepository]: reads from the asset bundle, decodes, and
/// extracts the ground layer's relief once per biome.
class AssetSceneArtRepository implements SceneArtRepository {
  AssetSceneArtRepository({
    required AssetBundle bundle,
    SceneImageDecoder decodeImage = decodeImageFromList,
  }) : _bundle = bundle, // ignore: prefer_initializing_formals
       _decodeImage = decodeImage; // ignore: prefer_initializing_formals

  final AssetBundle _bundle;
  final SceneImageDecoder _decodeImage;

  /// Keyed by biome, holding the in-flight or finished load. Futures, not
  /// results: the scene asks for the same biome on many consecutive frames
  /// while the first load is still running, and each of those must join the
  /// load already happening rather than start another decode of the same
  /// four files.
  final Map<String, Future<BiomeArt?>> _cache = {};

  /// Prop sprites, keyed by their own asset path. Separate from [_cache]
  /// and never evicted with it: a prop belongs to a landmark, not to the
  /// biome that happens to surround it, and there are only ever as many as
  /// the quest's content authors.
  final Map<String, ui.Image?> _props = {};

  @override
  Future<BiomeArt?> loadBiome({
    required String journeyId,
    required String biome,
  }) {
    return _cache.putIfAbsent(biome, () => _load(journeyId, biome));
  }

  Future<BiomeArt?> _load(String journeyId, String biome) async {
    final layers = <SceneArtLayer, ui.Image>{};
    for (final layer in SceneArtLayer.values) {
      final image = await _tryLoadImage(
        sceneArtAssetPath(journeyId, biome, layer),
      );
      if (image != null) layers[layer] = image;
    }
    if (layers.isEmpty) return null;

    final groundImage = layers[SceneArtLayer.ground];
    final ground = groundImage == null
        ? null
        : await _extractGround(groundImage, sceneArtTileMeters(journeyId));

    return (biome: biome, layers: layers, ground: ground);
  }

  Future<ui.Image?> _tryLoadImage(String path) async {
    final ByteData data;
    try {
      data = await _bundle.load(path);
    } catch (_) {
      // "This biome does not ship this layer" is the ordinary case while
      // art is still being filled in, not an error: the scene falls back to
      // its placeholder for that layer. A file that exists but cannot be
      // decoded still throws, below.
      return null;
    }
    return _decodeImage(data.buffer.asUint8List());
  }

  Future<GroundHeightmap?> _extractGround(
    ui.Image image,
    int tileMeters,
  ) async {
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (pixels == null) return null;
    return extractGroundHeightmap(
      rgba: pixels,
      width: image.width,
      height: image.height,
      tileMeters: tileMeters,
    );
  }

  @override
  ui.Image? propSprite(String asset) {
    if (_props.containsKey(asset)) return _props[asset];
    // Mark it in-flight immediately, so the next frame does not start the
    // same load again while this one is still running.
    _props[asset] = null;
    _tryLoadImage(asset).then((image) {
      if (image != null) _props[asset] = image;
    });
    return null;
  }

  @override
  void retainOnly(Iterable<String> biomes) {
    final keep = biomes.toSet();
    final stale = _cache.keys.where((key) => !keep.contains(key)).toList();
    for (final key in stale) {
      final pending = _cache.remove(key);
      // Dispose only once the load has actually finished — a biome scrolled
      // past before its images arrived would otherwise leak them.
      pending?.then((art) {
        for (final image in art?.layers.values ?? const <ui.Image>[]) {
          image.dispose();
        }
      });
    }
  }
}
