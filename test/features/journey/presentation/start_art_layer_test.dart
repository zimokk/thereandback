import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/journey/presentation/journey_scene.dart';
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';
import 'package:thereandback/features/journey/presentation/start_art_layer.dart';

/// The size `testWithGame` gives the game — `JourneyScene.onGameResize`
/// writes it straight onto the controller, so it is the scene's real size
/// here regardless of what the fixture sets (`ground_art_layer_test.dart`'s
/// own doc comment).
const double _sceneWidth = 800;
const double _sceneHeight = 600;
const String _quest = 'odyssey-ithaca';

/// Strips the scene down to its start art layer, so a rendered pixel is
/// unambiguously this layer's own drawing and not the ground/parallax
/// layers it is meant to sit in front of.
void _isolateStartArt(JourneyScene game) {
  for (final child in game.world.children.toList()) {
    if (child is! StartArtLayer) child.removeFromParent();
  }
  game.update(0);
}

/// Renders the scene's world through its camera and returns whether each
/// screen column has *any* opaque pixel — same approach
/// `ground_art_layer_test.dart`'s own `_drawnGroundTop` uses, simplified to
/// a bool since this layer's own vertical extent is not under test here.
Future<List<bool>> _drawnColumns(JourneyScene game) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
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
          if (alpha >= 128) return true;
        }
        return false;
      }(),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image image;

  setUpAll(() async {
    image = await decodeImageFromList(
      File('assets/journeys/$_quest/start_art.webp').readAsBytesSync(),
    );
  });

  JourneyScene createGame({String journeyId = _quest, bool loaded = true}) {
    final controller = JourneySceneController()
      ..journeyId = journeyId
      ..totalMeters = 2850000
      ..propSprite = (asset) =>
          loaded && asset.endsWith('start_art.webp') ? image : null;
    return JourneyScene(controller: controller);
  }

  group('StartArtLayer (§6.1, §9.1 — Troy/the Bellglass Tower fills the '
      'space before the route start)', () {
    testWithGame<JourneyScene>(
      'at the widest possible gap (a fresh quest, panMeters clamped to 0) '
      'every column left of the route start is covered — no bare strip of '
      'backdrop showing through',
      createGame,
      (game) async {
        _isolateStartArt(game);
        game.controller.panMeters = 0;
        game.update(0);
        final drawn = await _drawnColumns(game);

        // Route start sits at screen centre when panMeters == 0 — every
        // column to its left (the gap this layer exists to fill) has to be
        // covered.
        for (var x = 0; x < (_sceneWidth / 2).floor(); x += 16) {
          expect(drawn[x], isTrue, reason: 'gap at x=$x');
        }
      },
    );

    testWithGame<JourneyScene>(
      'never draws past the route\'s own start — the traveler, always at '
      'meters >= 0, can never end up behind it',
      createGame,
      (game) async {
        _isolateStartArt(game);
        game.controller.panMeters = 0;
        game.update(0);
        final drawn = await _drawnColumns(game);

        for (var x = (_sceneWidth / 2).ceil(); x < _sceneWidth; x += 16) {
          expect(
            drawn[x],
            isFalse,
            reason: 'drew past the route start at x=$x',
          );
        }
      },
    );

    testWithGame<JourneyScene>(
      'draws nothing once scrolled deep enough that the route start is no '
      'longer in view',
      createGame,
      (game) async {
        _isolateStartArt(game);
        game.controller.panMeters = 100000;
        game.update(0);
        final drawn = await _drawnColumns(game);

        expect(drawn, everyElement(isFalse));
      },
    );

    testWithGame<JourneyScene>(
      'draws nothing while the image is still loading',
      () => createGame(loaded: false),
      (game) async {
        _isolateStartArt(game);
        game.controller.panMeters = 0;
        game.update(0);
        final drawn = await _drawnColumns(game);

        expect(drawn, everyElement(isFalse));
      },
    );

    testWithGame<JourneyScene>(
      'a quest with no start art mapped (`journey_start_art.dart`) draws '
      'nothing, rather than crashing on a missing asset path',
      () => createGame(journeyId: 'some-future-quest'),
      (game) async {
        _isolateStartArt(game);
        game.controller.panMeters = 0;
        game.update(0);
        final drawn = await _drawnColumns(game);

        expect(drawn, everyElement(isFalse));
      },
    );
  });
}
