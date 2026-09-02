import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/painting.dart';

import '../../../design/colors.dart';
import 'journey_scene.dart' show JourneyScene;
import 'journey_scene_controller.dart';
import 'terrain_layer.dart';

/// Size of a traveler/friend glyph, in logical pixels — same value the
/// CustomPaint placeholder used (`journey_path_view.dart`'s
/// `_travelerIconSize`).
const double travelerIconSize = 32;

/// How far the rewind ghost's glyph shrinks relative to [travelerIconSize]
/// — smaller and visibly behind the solid marker, not a same-size twin.
const double travelerGhostScale = 0.85;

/// Opacity of the rewind ghost's glyph — faint enough to read as "a memory
/// of a position", not a second real traveler.
const double travelerGhostOpacity = 0.45;

/// Pixel threshold, in screen space, below which the ghost and the solid
/// traveler are considered "at the same spot" and the ghost hides — a
/// pixel, not a meters, threshold, so it holds regardless of a quest's own
/// meters-per-pixel scale (ported from the CustomPaint placeholder's
/// `showGhost` check).
const double ghostHideThresholdPx = 1.0;

/// Renders [Icons.directions_walk] onto a Flame canvas — the same glyph the
/// CustomPaint placeholder drew via a Flutter `Icon` widget, reused here so
/// the on-screen figure doesn't change shape mid-migration; §9.1's real art
/// replaces this glyph, not the positioning logic around it.
TextPainter _walkGlyphPainter({
  required double fontSize,
  required Color color,
}) {
  final icon = Icons.directions_walk;
  return TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: fontSize,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

/// One traveler-shaped figure standing at a fixed **world** position — the
/// player's own solid marker (always at [JourneySceneController
/// .progressMeters]) and every friend marker (`friend_component.dart`, each
/// at its own row's `progressMeters`) are both this same component, only
/// differing in which meters value they track and their color. A `World`
/// child, so Flame's own camera transform places it on screen — no manual
/// offset math here (contrast the rewind ghost, [GhostTravelerComponent]
/// below, which is deliberately *not* a `World` child).
class TravelerComponent extends PositionComponent {
  TravelerComponent({
    required this.controller,
    required this.metersProvider,
    required Color color,
    double iconSize = travelerIconSize,
  }) : super(size: Vector2.all(iconSize), anchor: Anchor.center) {
    _glyph = _walkGlyphPainter(fontSize: iconSize, color: color);
  }

  final JourneySceneController controller;

  /// Reads the meters this figure currently stands at — a closure rather
  /// than a fixed value so the player's own marker (which reads
  /// [JourneySceneController.progressMeters], not a value snapshotted once)
  /// and a friend's marker (which reads that friend's own, possibly
  /// changing, `progressMeters`) share one component class.
  final double Function() metersProvider;

  late final TextPainter _glyph;

  @override
  void update(double dt) {
    super.update(dt);
    final worldX = worldXFor(metersProvider(), controller.pixelsPerMeter);
    position = Vector2(worldX, terrainHeightAt(worldX));
  }

  @override
  void render(Canvas canvas) {
    _glyph.paint(
      canvas,
      Offset((size.x - _glyph.width) / 2, (size.y - _glyph.height) / 2),
    );
  }
}

/// The rewind ghost — "was here" (CLAUDE.md §6.1): a dim, smaller echo of
/// the traveler glyph, always centred on the *viewport* (screen-space, not
/// world-space) at the vertical height the horizon has at whatever route
/// position the view is currently panned to. Hidden once that would
/// coincide with the real traveler (looking at `You`) — one figure there,
/// not two overlapping ones.
///
/// A `camera.viewport` child, not a `World` child: "wherever the view is
/// currently centred" is by definition the viewport's own centre, which
/// only Flame's HUD-space (unaffected by the world/camera transform) can
/// express directly.
class GhostTravelerComponent extends PositionComponent
    with HasGameReference<JourneyScene> {
  GhostTravelerComponent({required this.controller})
    : super(
        size: Vector2.all(travelerIconSize * travelerGhostScale),
        anchor: Anchor.center,
      ) {
    _glyph = _walkGlyphPainter(
      fontSize: size.x,
      color: AppColors.textSecondary.withValues(alpha: travelerGhostOpacity),
    );
  }

  final JourneySceneController controller;

  late final TextPainter _glyph;

  bool _visible = false;

  /// Whether the ghost is currently showing — exposed only for
  /// `traveler_component_test.dart`; nothing in production code reads this
  /// (visibility is entirely a [render]-time concern).
  @visibleForTesting
  bool get isVisibleForTest => _visible;

  @override
  void update(double dt) {
    super.update(dt);
    final pixelsPerMeter = controller.pixelsPerMeter;
    // Compared against the *displayed* position, not the raw target — the
    // ghost should hide exactly when it visually lines up with wherever the
    // solid marker currently is drawn, including mid-catch-up (§6.1).
    final deltaMeters =
        controller.displayedProgressMeters - controller.panMeters;
    _visible = (deltaMeters * pixelsPerMeter).abs() > ghostHideThresholdPx;
    if (!_visible) return;

    final panWorldX = worldXFor(controller.panMeters, pixelsPerMeter);
    final viewportSize = game.camera.viewport.size;
    position = Vector2(
      viewportSize.x / 2,
      viewportSize.y / 2 + terrainHeightAt(panWorldX),
    );
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    _glyph.paint(
      canvas,
      Offset((size.x - _glyph.width) / 2, (size.y - _glyph.height) / 2),
    );
  }
}
