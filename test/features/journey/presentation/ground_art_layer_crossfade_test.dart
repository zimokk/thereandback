import 'dart:ui' as ui;

import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/journey/data/ground_heightmap_extractor.dart';
import 'package:thereandback/features/journey/data/scene_art_catalog.dart';
import 'package:thereandback/features/journey/data/scene_art_repository.dart';
import 'package:thereandback/features/journey/domain/segment_biomes.dart';
import 'package:thereandback/features/journey/presentation/journey_scene.dart';
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';
import 'package:thereandback/features/journey/presentation/terrain_layer.dart';

/// The size `testWithGame` gives the game — see `ground_art_layer_test.dart`'s
/// own doc comment on this same constant.
const double _sceneWidth = 800;
const double _sceneHeight = 600;
const String _quest = 'q';

const _biomeRed = 'red_biome';
const _biomeBlue = 'blue_biome';

/// Two adjacent spans sharing a boundary at 40 000 m, each long enough that
/// `_fadeInWindowFor`'s own half-span cap never shrinks the fade below the
/// full 2 000 m `biomeTransitionMeters` — otherwise this test would be
/// asserting against a narrower band than the one every real quest's
/// segments actually use.
const _biomes = [
  BiomeSpan(segmentId: 's1', biome: _biomeRed, fromMeters: 0, toMeters: 40000),
  BiomeSpan(
    segmentId: 's2',
    biome: _biomeBlue,
    fromMeters: 40000,
    toMeters: 100000,
  ),
];

/// A flat ground tile, fully opaque below its own midline, filled with one
/// solid [color] — a stand-in for a real biome's illustrated ground simple
/// enough that this test can assert on its exact drawn color rather than
/// guessing at what a real illustration's palette would blend to.
Future<BiomeArt> _solidGroundBiome(String biome, Color color) async {
  const width = 8.0;
  const height = 16.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, height / 2, width, height / 2),
    Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final layers = <SceneArtLayer, ui.Image>{SceneArtLayer.ground: image};
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final ground = extractGroundHeightmap(
    rgba: pixels!,
    width: width.toInt(),
    height: height.toInt(),
    tileMeters: 40000,
  );
  return (biome: biome, layers: layers, ground: ground);
}

/// Strips the scene down to its ground layer, same as
/// `ground_art_layer_test.dart`'s own helper.
void _isolateGround(JourneyScene game) {
  for (final child in game.world.children.toList()) {
    if (child is! GroundArtLayer) child.removeFromParent();
  }
  game.update(0);
}

/// The drawn color at screen column [x], sampled well below the ground's
/// own top edge (never in the anti-aliased silhouette boundary row) so a
/// pixel is unambiguously the tile's own fill.
Future<Color> _colorAt(JourneyScene game, int x) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  game.render(canvas);
  final image = await recorder.endRecording().toImage(
    _sceneWidth.toInt(),
    _sceneHeight.toInt(),
  );
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final y = (_sceneHeight - 10).toInt();
  final offset = (y * _sceneWidth.toInt() + x) * 4;
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
      ..journeyId = _quest
      ..totalMeters = 100000
      ..biomes = _biomes;
    return JourneyScene(controller: controller);
  }

  group('GroundArtLayer biome crossfade (CLAUDE.md §14, 2026-09-16 bug-fix — '
      'a hard, unblended seam at every biome boundary)', () {
    testWithGame<JourneyScene>(
      'well before and well after the boundary, the ground is each '
      'biome\'s own solid color — the fade never leaks outside its window',
      createGame,
      (game) async {
        controller.biomeArt = {
          _biomeRed: await _solidGroundBiome(
            _biomeRed,
            const Color(0xFFFF0000),
          ),
          _biomeBlue: await _solidGroundBiome(
            _biomeBlue,
            const Color(0xFF0000FF),
          ),
        };
        _isolateGround(game);
        // Centers the view on the boundary itself (40 000 m) — the widest
        // possible look at both the fade window and the plain color either
        // side of it in one frame.
        controller.panMeters = 40000;
        game.update(0);

        expect(await _colorAt(game, 50), const Color(0xFFFF0000));
        expect(await _colorAt(game, 750), const Color(0xFF0000FF));
      },
    );

    testWithGame<JourneyScene>(
      'inside the transition window, the drawn color is a genuine blend of '
      'both biomes — not an unblended overwrite of one by the other. This '
      'is the seam itself: before this fix, `_paint` never carried an alpha '
      'at all, so whichever span was drawn later in `controller.biomes\' own '
      'order completely overwrote the other with a hard, pixel-sharp cut '
      'exactly at the boundary, regardless of how far into the fade a '
      'column actually was.',
      createGame,
      (game) async {
        controller.biomeArt = {
          _biomeRed: await _solidGroundBiome(
            _biomeRed,
            const Color(0xFFFF0000),
          ),
          _biomeBlue: await _solidGroundBiome(
            _biomeBlue,
            const Color(0xFF0000FF),
          ),
        };
        _isolateGround(game);
        controller.panMeters = 40000;
        game.update(0);

        // pixelsPerMeter at this scene width/quest scale (`route_scale.dart`'s
        // default 20 000 m per screen width) is 800/20000 = 0.04, so the
        // 2 000 m transition window is 80 screen px wide, landing at
        // screen x 400..480 — this samples its midpoint.
        final mid = await _colorAt(game, 440);
        expect(
          mid,
          isNot(anyOf(const Color(0xFFFF0000), const Color(0xFF0000FF))),
          reason: 'still a hard cut, not a blend, at the fade\'s own midpoint',
        );
        // A real blend of pure red and pure blue has no green at all, and
        // roughly equal red/blue once past `srcIn`'s own alpha compositing
        // over the (opaque) red tile drawn underneath.
        expect(mid.g, 0);
        expect(mid.r, greaterThan(0));
        expect(mid.b, greaterThan(0));
      },
    );

    testWithGame<JourneyScene>(
      'the fade is monotonic across the window — blue steadily replaces '
      'red left to right, never jumping straight from one to the other',
      createGame,
      (game) async {
        controller.biomeArt = {
          _biomeRed: await _solidGroundBiome(
            _biomeRed,
            const Color(0xFFFF0000),
          ),
          _biomeBlue: await _solidGroundBiome(
            _biomeBlue,
            const Color(0xFF0000FF),
          ),
        };
        _isolateGround(game);
        controller.panMeters = 40000;
        game.update(0);

        int? previousBlue;
        for (var x = 395; x <= 485; x += 15) {
          final color = await _colorAt(game, x);
          final blue = (color.b * 255).round();
          if (previousBlue != null) {
            expect(
              blue,
              greaterThanOrEqualTo(previousBlue),
              reason: 'blue channel decreased at x=$x — not a smooth ramp',
            );
          }
          previousBlue = blue;
        }
        // The window's own two ends really did move the channel, not just
        // stay flat throughout (which would also pass a monotonic check).
        expect(previousBlue, greaterThan(0));
      },
    );

    testWithGame<JourneyScene>(
      'two adjacent spans of the *same* biome never fade — nothing to '
      'blend between, so the seam this fix targets cannot apply',
      () {
        controller = JourneySceneController()
          ..journeyId = _quest
          ..totalMeters = 100000
          ..biomes = const [
            BiomeSpan(
              segmentId: 's1',
              biome: _biomeRed,
              fromMeters: 0,
              toMeters: 40000,
            ),
            BiomeSpan(
              segmentId: 's2',
              biome: _biomeRed,
              fromMeters: 40000,
              toMeters: 100000,
            ),
          ];
        return JourneyScene(controller: controller);
      },
      (game) async {
        controller.biomeArt = {
          _biomeRed: await _solidGroundBiome(
            _biomeRed,
            const Color(0xFFFF0000),
          ),
        };
        _isolateGround(game);
        controller.panMeters = 40000;
        game.update(0);

        expect(await _colorAt(game, 440), const Color(0xFFFF0000));
      },
    );
  });
}
