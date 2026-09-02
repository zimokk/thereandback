import 'package:flame_test/flame_test.dart';
import 'package:test/test.dart';
import 'package:thereandback/features/journey/presentation/journey_scene.dart';
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';

void main() {
  group('JourneyScene (§12 — parallax offset linear in scroll position)', () {
    late JourneySceneController controller;

    JourneyScene createGame() {
      controller = JourneySceneController()
        ..journeyId = 'odyssey-ithaca'
        ..totalMeters = 2850000
        ..progressMeters = 100000
        ..sceneWidth = 800
        ..sceneHeight = 400;
      return JourneyScene(controller: controller);
    }

    testWithGame<JourneyScene>(
      "camera x tracks panMeters linearly, at this quest's own scale",
      createGame,
      (game) async {
        controller.panMeters = 1000;
        game.update(0);
        final x1 = game.camera.viewfinder.position.x;

        controller.panMeters = 2000;
        game.update(0);
        final x2 = game.camera.viewfinder.position.x;

        final expectedDelta = (2000 - 1000) * controller.pixelsPerMeter;
        expect(x2 - x1, closeTo(expectedDelta, 1e-9));
      },
    );

    testWithGame<JourneyScene>(
      'camera y never moves off the terrain mid-line',
      createGame,
      (game) async {
        controller.panMeters = 500;
        game.update(0);
        expect(game.camera.viewfinder.position.y, 0.0);

        controller.panMeters = 999999;
        game.update(0);
        expect(game.camera.viewfinder.position.y, 0.0);
      },
    );
  });
}
