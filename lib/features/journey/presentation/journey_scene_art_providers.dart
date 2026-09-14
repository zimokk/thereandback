import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/scene_art_repository.dart';

part 'journey_scene_art_providers.g.dart';

/// The bundle biome art is read from. A provider of its own so a widget
/// test can hand the scene an empty bundle and get the placeholder path
/// deterministically — same pattern as `journey_terrain_providers.dart`'s
/// `journeyTerrainBundle`.
@riverpod
AssetBundle sceneArtBundle(Ref ref) => rootBundle;

/// The one [SceneArtRepository] the scene loads biome art through (§6.1,
/// §9.1).
///
/// `keepAlive` on purpose, unlike most providers here: it owns decoded
/// `ui.Image`s and a cache of which biomes are loaded. Letting it be
/// disposed and rebuilt on an unrelated rebuild would throw that away and
/// re-decode the art the scene is drawing right now.
@Riverpod(keepAlive: true)
SceneArtRepository sceneArtRepository(Ref ref) =>
    AssetSceneArtRepository(bundle: ref.watch(sceneArtBundleProvider));
