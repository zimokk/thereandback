import 'dart:ui';

import 'package:flame/game.dart';

import 'environment_layer.dart';
import 'friend_component.dart';
import 'journey_scene_controller.dart';
import 'terrain_layer.dart';
import 'traveler_component.dart';

/// The Путь tab's Flame scene (CLAUDE.md §6.1) — a long-lived `FlameGame`
/// instance created once by `journey_flame_scene_view.dart` and never
/// rebuilt on a Riverpod change (§12: "Flame `Game` instance is long-lived").
/// Every frame's state comes from [controller], mutated by the hosting
/// widget — this class and its components never talk to Riverpod directly.
class JourneyScene extends FlameGame {
  JourneyScene({required this.controller});

  final JourneySceneController controller;

  late final HorizonTerrainLayer _terrain;
  late final GhostTravelerComponent _ghost;
  final Map<String, FriendMarkerComponent> _friendComponents = {};

  /// Transparent — the visible backdrop (`AppSceneBackdrop`, `SkyGradient`)
  /// lives in Flutter, behind the `GameWidget`; `FlameGame`'s own default
  /// background is opaque black and would otherwise paint over both.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _terrain = HorizonTerrainLayer(controller: controller);
    await world.add(_terrain);

    final solidTraveler = TravelerComponent(
      controller: controller,
      metersProvider: () => controller.displayedProgressMeters,
      color: const Color(0xFFE0AE3F), // AppColors.gold.
    )..priority = 20;
    await world.add(solidTraveler);

    await world.add(EnvironmentLayer.behind(controller));
    await world.add(EnvironmentLayer.front(controller));

    _ghost = GhostTravelerComponent(controller: controller);
    await camera.viewport.add(_ghost);
  }

  @override
  void update(double dt) {
    // The paused flag is mirrored from the controller on every Flutter
    // rebuild (`journey_flame_scene_view.dart`) rather than read here —
    // `update()` itself does not run at all once `paused` is true, so it
    // cannot un-pause itself from inside its own body.
    super.update(dt);

    camera.viewfinder.position = Vector2(
      worldXFor(controller.panMeters, controller.pixelsPerMeter),
      terrainMidY,
    );
    _syncFriends();
  }

  /// Adds/removes one [FriendMarkerComponent] per currently-visible friend
  /// row — driven by [JourneySceneController.friendRows]/`.showFriends`,
  /// which `journey_flame_scene_view.dart` keeps in sync with
  /// `friendsViewProvider`/`showFriendsOnMapProvider`. Existing components
  /// are left alone (not recreated) when their row simply changes progress
  /// — only membership changes (a friend appears/disappears from the
  /// filtered list) touches the component tree.
  void _syncFriends() {
    final visibleUids = controller.showFriends
        ? controller.friendRows.map((row) => row.uid).toSet()
        : const <String>{};

    final staleUids = _friendComponents.keys
        .where((uid) => !visibleUids.contains(uid))
        .toList(growable: false);
    for (final uid in staleUids) {
      _friendComponents.remove(uid)?.removeFromParent();
    }

    for (final uid in visibleUids) {
      if (_friendComponents.containsKey(uid)) continue;
      final component = FriendMarkerComponent(controller: controller, uid: uid)
        ..priority = 20;
      _friendComponents[uid] = component;
      world.add(component);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    controller.sceneWidth = size.x;
    controller.sceneHeight = size.y;
  }
}
