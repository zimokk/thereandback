import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:test/test.dart';
import 'package:thereandback/features/friends/domain/friend_progress.dart';
import 'package:thereandback/features/journey/presentation/friend_component.dart';
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';
import 'package:thereandback/features/journey/presentation/terrain_layer.dart';

void main() {
  group('FriendMarkerComponent (§6.5 — friends on the Путь tab)', () {
    late JourneySceneController controller;

    FlameGame createGame() {
      controller = JourneySceneController()
        ..journeyId = 'odyssey-ithaca'
        ..sceneWidth = 800
        ..sceneHeight = 400
        ..showFriends = true
        ..friendRows = const [
          FriendProgressRow(
            uid: 'friend-1',
            nickname: 'Circe',
            progressMeters: 12000,
            isSelf: false,
          ),
        ];
      return FlameGame();
    }

    testWithGame<FlameGame>(
      "positions its marker at the friend's own progressMeters",
      createGame,
      (game) async {
        final marker = FriendMarkerComponent(
          controller: controller,
          uid: 'friend-1',
        );
        await game.add(marker);
        await game.ready();
        game.update(0);

        final expectedX = worldXFor(12000, controller.pixelsPerMeter);
        expect(marker.markerPositionForTest.x, closeTo(expectedX, 1e-3));
      },
    );

    testWithGame<FlameGame>(
      'the nickname label shows the nickname and tracks above the marker',
      createGame,
      (game) async {
        final marker = FriendMarkerComponent(
          controller: controller,
          uid: 'friend-1',
        );
        await game.add(marker);
        await game.ready();
        game.update(0);

        expect(marker.labelTextForTest, 'Circe');
        expect(
          marker.labelPositionForTest.x,
          closeTo(marker.markerPositionForTest.x, 1e-3),
        );
        expect(
          marker.labelPositionForTest.y,
          lessThan(marker.markerPositionForTest.y),
        );
      },
    );

    testWithGame<FlameGame>(
      'a friend that disappears from friendRows falls back to meters 0',
      createGame,
      (game) async {
        final marker = FriendMarkerComponent(
          controller: controller,
          uid: 'someone-not-in-friendRows',
        );
        await game.add(marker);
        await game.ready();
        game.update(0);

        expect(marker.markerPositionForTest.x, closeTo(0, 1e-3));
        expect(marker.labelTextForTest, '');
      },
    );
  });
}
