import 'dart:ui' show Color;

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:test/test.dart';
import 'package:thereandback/features/journey/presentation/journey_scene.dart';
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';
import 'package:thereandback/features/journey/presentation/terrain_layer.dart';
import 'package:thereandback/features/journey/presentation/traveler_component.dart';

void main() {
  group('TravelerComponent (world-space figure)', () {
    late JourneySceneController controller;

    FlameGame createGame() {
      controller = JourneySceneController()
        ..journeyId = 'odyssey-ithaca'
        ..progressMeters = 5000
        ..sceneWidth = 800
        ..sceneHeight = 400;
      return FlameGame();
    }

    testWithGame<FlameGame>(
      "always sits at worldXFor(the tracked meters) regardless of pan",
      createGame,
      (game) async {
        final traveler = TravelerComponent(
          controller: controller,
          metersProvider: () => controller.progressMeters.toDouble(),
          color: const Color(0xFFE0AE3F),
        );
        await game.add(traveler);
        await game.ready();

        final expectedX = worldXFor(5000, controller.pixelsPerMeter);
        traveler.update(0);
        // Flame's Vector2 is Float32-backed, so an exact `double` comparison
        // would be too strict — a small tolerance accounts for that, not
        // for anything about this component's own math.
        expect(traveler.position.x, closeTo(expectedX, 1e-3));
        expect(traveler.position.y, closeTo(terrainHeightAt(expectedX), 1e-3));

        controller.panMeters = 999999; // pan never affects this figure.
        traveler.update(0);
        expect(traveler.position.x, closeTo(expectedX, 1e-3));
      },
    );
  });

  group('GhostTravelerComponent (rewind ghost, world-space)', () {
    late JourneySceneController controller;

    JourneyScene createGame() {
      controller = JourneySceneController()
        ..journeyId = 'odyssey-ithaca'
        ..progressMeters = 5000
        // The ghost compares against the *displayed* position, not the raw
        // target (`traveler_component.dart`'s `GhostTravelerComponent`) —
        // no catch-up animation is in flight in this isolated test, so it
        // matches `progressMeters` exactly, same as a settled real view.
        ..displayedProgressMeters = 5000
        ..sceneWidth = 800
        ..sceneHeight = 400;
      return JourneyScene(controller: controller);
    }

    testWithGame<JourneyScene>(
      'hidden while panMeters == progressMeters (at You)',
      createGame,
      (game) async {
        controller.panMeters = 5000;
        game.update(0);

        final ghost = GhostTravelerComponent(controller: controller);
        await game.world.add(ghost);
        await game.ready();
        ghost.update(0);

        expect(ghost.isVisibleForTest, isFalse);
      },
    );

    testWithGame<JourneyScene>(
      'visible and sitting at worldXFor(panMeters) once rewound away from You',
      createGame,
      (game) async {
        controller.panMeters = 1000; // rewound well past the pixel threshold.
        game.update(0);

        final ghost = GhostTravelerComponent(controller: controller);
        await game.world.add(ghost);
        await game.ready();
        ghost.update(0);

        expect(ghost.isVisibleForTest, isTrue);
        // Same world x the camera itself points at (`JourneyScene.update`'s
        // `viewfinder.position`) — that's what puts the ghost at screen
        // centre, via the ordinary camera transform, not a HUD special case.
        final expectedX = worldXFor(1000, controller.pixelsPerMeter);
        expect(ghost.position.x, closeTo(expectedX, 1e-3));
        expect(ghost.position.y, closeTo(terrainHeightAt(expectedX), 1e-3));
      },
    );
  });
}
