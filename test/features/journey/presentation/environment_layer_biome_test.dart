import 'dart:ui' as ui;

import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/journey/data/scene_art_catalog.dart';
import 'package:thereandback/features/journey/data/scene_art_repository.dart';
import 'package:thereandback/features/journey/domain/segment_biomes.dart';
import 'package:thereandback/features/journey/presentation/environment_layer.dart';
import 'package:thereandback/features/journey/presentation/journey_scene.dart';
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';

/// The size `testWithGame` gives the game; at the default 20 000 m per
/// screen width that is 0.04 px per meter.
const double _sceneWidth = 800;
const double _sceneHeight = 600;

const _spans = [
  BiomeSpan(segmentId: 's1', biome: 'red', fromMeters: 0, toMeters: 40000),
  BiomeSpan(
    segmentId: 's2',
    biome: 'blue',
    fromMeters: 40000,
    toMeters: 100000,
  ),
];

/// A fully opaque, single-colour `far` tile, so a sampled pixel says
/// exactly which biome's art is drawn there.
Future<BiomeArt> _solidFarBiome(String biome, Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
      .drawRect(const Rect.fromLTWH(0, 0, 8, 16), Paint()..color = color);
  final image = await recorder.endRecording().toImage(8, 16);
  return (biome: biome, layers: {SceneArtLayer.far: image}, ground: null);
}

Future<Color> _colorAt(JourneyScene game, int x) async {
  final recorder = ui.PictureRecorder();
  game.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    _sceneWidth.toInt(),
    _sceneHeight.toInt(),
  );
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  // Mid-height: well inside the layer's drawn band.
  final offset = ((_sceneHeight ~/ 2) * _sceneWidth.toInt() + x) * 4;
  return Color.fromARGB(
    pixels!.getUint8(offset + 3),
    pixels.getUint8(offset),
    pixels.getUint8(offset + 1),
    pixels.getUint8(offset + 2),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JourneySceneController controller;

  JourneyScene createGame() {
    controller = JourneySceneController()
      ..journeyId = 'q'
      ..totalMeters = 100000
      ..biomes = _spans;
    return JourneyScene(controller: controller);
  }

  Future<void> prepare(JourneyScene game) async {
    controller.biomeArt = {
      'red': await _solidFarBiome('red', const Color(0xFFFF0000)),
      'blue': await _solidFarBiome('blue', const Color(0xFF0000FF)),
    };
    for (final child in game.world.children.toList()) {
      final keep =
          child is EnvironmentLayer && child.velocityMultiplier == 0.25;
      if (!keep) child.removeFromParent();
    }
    game.update(0);
  }

  group('EnvironmentLayer biome change (§6.1 — the landscape changes where '
      'the ground does, not all at once across the screen)', () {
    testWithGame<JourneyScene>(
      'each side of the boundary shows its own biome in the same frame — '
      'the old pan-driven cross-fade drew the whole layer as one biome',
      createGame,
      (game) async {
        await prepare(game);
        // The boundary (40 000 m) lands at screen x 400 + 5 000 * 0.04 = 600.
        controller.panMeters = 35000;
        game.update(0);

        expect(await _colorAt(game, 100), const Color(0xFFFF0000));
        expect(await _colorAt(game, 700), const Color(0xFF0000FF));
      },
    );

    testWithGame<JourneyScene>(
      'the boundary travels with the route as the view pans — no frame '
      'swaps the landscape anywhere else',
      createGame,
      (game) async {
        await prepare(game);
        controller.panMeters = 35000;
        game.update(0);
        // Inside the dissolve band (32 000..40 000 m → x 280..600).
        final before = await _colorAt(game, 500);
        expect(before.r, greaterThan(0));
        expect(before.b, greaterThan(0));

        // 2 000 m on, the same route position is 80 px further left and
        // drawn in exactly the same blend.
        controller.panMeters = 37000;
        game.update(0);
        expect(await _colorAt(game, 420), before);
      },
    );
  });
}
