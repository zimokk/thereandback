import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/painting.dart';

import '../../../design/colors.dart';
import 'journey_scene_controller.dart';
import 'terrain_layer.dart';

/// Size of a traveler/friend glyph, in logical pixels — same value the
/// CustomPaint placeholder used (`journey_path_view.dart`'s
/// `_travelerIconSize`).
const double travelerIconSize = 32;

/// Shared z-order for every on-path figure — the solid traveler
/// ([TravelerComponent] added in `journey_scene.dart`), each friend marker
/// (`friend_component.dart`), and the rewind ghost ([GhostTravelerComponent]
/// below) all render at this one `priority`, between
/// `EnvironmentLayer.behind` (10) and `EnvironmentLayer.front` (30) — the
/// front decoration layer is meant to visually pass in front of whichever
/// figures are currently behind it, not sit under them.
const int travelerPriority = 20;

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
/// offset math here. The rewind ghost ([GhostTravelerComponent] below) is a
/// separate class (it hides conditionally and draws a different glyph
/// scale/opacity) but shares this same `World` placement and
/// [travelerPriority].
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
    // `.setValues` on the existing `position` Vector2, not a fresh
    // `Vector2(...)` every tick — `flame-scene`'s own "no per-frame
    // allocation" rule.
    position.setValues(
      worldX,
      terrainHeightAt(
        worldX,
        controller.terrainProfile,
        controller.pixelsPerMeter,
      ),
    );
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
/// the traveler glyph, at the world position [JourneySceneController
/// .panMeters] — the route position the view is currently panned to,
/// standing on the horizon there. Hidden once that would coincide with the
/// real traveler (looking at `You`) — one figure there, not two overlapping
/// ones.
///
/// A `World` child, added at [travelerPriority] — same level as the solid
/// traveler and every friend marker — **not** a `camera.viewport` (HUD)
/// child: HUD content always paints after (on top of) the whole world,
/// which put the ghost above `EnvironmentLayer.front` regardless of
/// `priority`. As a world entity it needs no special-cased viewport-space
/// math either — [JourneyScene.update] already points the camera's
/// viewfinder at `worldXFor(panMeters, pixelsPerMeter)`, so a figure placed
/// at that exact world x lands at the viewport's centre on screen, exactly
/// like before, just by ordinary camera transform rather than manual HUD
/// positioning.
class GhostTravelerComponent extends PositionComponent {
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
    // `.setValues` on the existing `position` Vector2 — same
    // no-per-frame-allocation rule [TravelerComponent.update] follows.
    position.setValues(
      panWorldX,
      terrainHeightAt(panWorldX, controller.terrainProfile, pixelsPerMeter),
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
