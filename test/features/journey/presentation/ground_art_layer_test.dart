import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/journey/data/ground_heightmap_extractor.dart';
import 'package:thereandback/features/journey/data/scene_art_catalog.dart';
import 'package:thereandback/features/journey/data/scene_art_repository.dart';
import 'package:thereandback/features/journey/domain/segment_biomes.dart';
import 'package:thereandback/features/journey/domain/terrain_profile.dart'
    hide terrainHeightAt;
import 'package:thereandback/features/journey/presentation/journey_scene.dart';
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';
import 'package:thereandback/features/journey/presentation/terrain_layer.dart';

/// The size `testWithGame` gives the game — `JourneyScene.onGameResize`
/// writes it straight onto the controller, so it is the scene's real size
/// here regardless of what the fixture sets.
const double _sceneWidth = 800;
const double _sceneHeight = 600;
const String _quest = 'tower-of-lights';
const String _biome = 'mountain_pass';

const _biomes = [
  BiomeSpan(segmentId: 's1', biome: _biome, fromMeters: 0, toMeters: 60000),
];

Future<BiomeArt> _loadBiome() async {
  final layers = <SceneArtLayer, ui.Image>{};
  for (final layer in SceneArtLayer.values) {
    layers[layer] = await decodeImageFromList(
      File(sceneArtAssetPath(_quest, _biome, layer)).readAsBytesSync(),
    );
  }
  final groundImage = layers[SceneArtLayer.ground]!;
  final pixels = await groundImage.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  );
  return (
    biome: _biome,
    layers: layers,
    ground: extractGroundHeightmap(
      rgba: pixels!,
      width: groundImage.width,
      height: groundImage.height,
      tileMeters: 20000,
    ),
  );
}

/// Strips the scene down to its ground layer, so a rendered pixel is
/// unambiguously the drawn ground and not a distant hill ridging above it or
/// the traveler's own glyph.
void _isolateGround(JourneyScene game) {
  for (final child in game.world.children.toList()) {
    if (child is! GroundArtLayer) child.removeFromParent();
  }
  game.update(0);
}

/// Renders the scene's world through its camera into an offscreen image and
/// returns the topmost opaque row per screen column — where the drawn ground
/// visibly starts, as a viewer sees it.
Future<List<int?>> _drawnGroundTop(JourneyScene game) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  game.render(canvas);
  final image = await recorder.endRecording().toImage(
    _sceneWidth.toInt(),
    _sceneHeight.toInt(),
  );
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  return [
    for (var x = 0; x < _sceneWidth; x++)
      () {
        for (var y = 0; y < _sceneHeight; y++) {
          final alpha = pixels!.getUint8((y * _sceneWidth.toInt() + x) * 4 + 3);
          if (alpha >= 128) return y;
        }
        return null;
      }(),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JourneySceneController controller;
  late BiomeArt art;

  setUpAll(() async {
    art = await _loadBiome();
  });

  JourneyScene createGame() {
    controller = JourneySceneController()
      ..journeyId = _quest
      ..totalMeters = 60000
      ..biomes = _biomes
      ..biomeArt = {_biome: art};
    return JourneyScene(controller: controller);
  }

  group('GroundArtLayer (§6.1 — the traveler walks on the drawn ground)', () {
    testWithGame<JourneyScene>(
      'the drawn ground\'s own top edge lands on the line terrainHeightAt '
      'returns — the invariant this whole feature rests on',
      createGame,
      (game) async {
        _isolateGround(game);
        controller.panMeters = 12000;
        game.update(0);
        final drawn = await _drawnGroundTop(game);

        var compared = 0;
        for (var x = 40; x < _sceneWidth - 40; x += 20) {
          final top = drawn[x];
          if (top == null) continue;
          final worldX =
              worldXFor(controller.panMeters, controller.pixelsPerMeter) +
              x -
              _sceneWidth / 2;
          final expected =
              terrainHeightAt(worldX, controller) +
              _sceneHeight * horizonScreenYFraction;
          // Within a few pixels: the strip is sampled every 16 px and the
          // tile is resampled to screen scale, so an exact match would be
          // asserting away antialiasing, not correctness.
          expect(
            top.toDouble(),
            closeTo(expected, 6),
            reason: 'drawn ground and the walking line disagree at x=$x',
          );
          compared++;
        }
        expect(compared, greaterThan(8), reason: 'nothing was actually drawn');
      },
    );

    testWithGame<JourneyScene>(
      'an authored climb carries the drawn ground with it, not just the line',
      createGame,
      (game) async {
        _isolateGround(game);
        controller
          ..panMeters = 30000
          ..terrainProfile = const TerrainProfile(
            points: [
              TerrainPoint(meters: 0, height: 0.0),
              TerrainPoint(meters: 30000, height: 1.0),
              TerrainPoint(meters: 60000, height: 0.0),
            ],
          );
        game.update(0);
        final climbed = await _drawnGroundTop(game);

        controller.terrainProfile = null;
        game.update(0);
        final flat = await _drawnGroundTop(game);

        final x = _sceneWidth ~/ 2;
        expect(climbed[x], isNotNull);
        expect(flat[x], isNotNull);
        // Higher ground is a smaller y, and by the authored amplitude.
        expect(
          (flat[x]! - climbed[x]!).toDouble(),
          closeTo(macroTerrainAmplitude, 8),
        );
      },
    );

    testWithGame<JourneyScene>(
      'a biome with no loaded art draws no ground at all, leaving the '
      'placeholder scene to show through',
      createGame,
      (game) async {
        _isolateGround(game);
        controller
          ..biomeArt = const {}
          ..panMeters = 12000;
        game.update(0);
        final drawn = await _drawnGroundTop(game);

        expect(drawn, everyElement(isNull));
      },
    );

    testWithGame<JourneyScene>(
      'covers the full screen width, with no gap at any (interior) pan '
      'position — guards the invariant behind a real device bug report: a '
      'screenshot showed the ground missing across exactly the left half '
      'of the screen, split at the pan position, background showing '
      'through. `render()` used to read `game.camera.visibleWorldRect` '
      'for this layer\'s draw window, a value that only refreshes inside '
      '`JourneyScene.update()` — unlike every other on-path figure '
      '(traveler, friends, `EnvironmentLayer`\'s own tiling, the '
      'achievement guide lines), which reads `controller.panMeters` '
      'directly and is never stale. Reproduced during investigation by '
      'rendering with a changed `panMeters` and no intervening `update()` '
      '(the scene is paused while off-screen, §6.1/§12, and an unrelated '
      'Flutter rebuild can still repaint a paused layer): the window '
      'stayed centred on the old pan, and its own route-start clamp '
      'silently ate whichever side of that stale window undershot 0 m. '
      'Not reproduced here as a literal "render with no update" case — '
      'that also desyncs Flame\'s own camera transform, an orthogonal '
      'concern this fix does not touch. Sourcing the window from '
      '`controller` instead, like every sibling layer already does, '
      'removes the second, independently-refreshing notion of "visible" '
      'that could go stale in the first place; this test locks in that '
      'the ordinary, correctly-updated case it protects stays covered '
      'edge to edge.',
      createGame,
      (game) async {
        _isolateGround(game);
        // Interior positions only — near either end of this fixture's short
        // 60 000 m route, the route's own start/end bounds legitimately clip
        // the window (nothing exists before point A or after point B), which
        // is correct behaviour, not this bug.
        for (final pan in [15000.0, 30000.0, 45000.0]) {
          controller.panMeters = pan;
          game.update(0);
          final drawn = await _drawnGroundTop(game);
          expect(
            drawn,
            everyElement(isNotNull),
            reason: 'gap in the ground at panMeters=$pan',
          );
        }
      },
    );
  });
}
