import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../domain/terrain_profile.dart' as domain;
import 'journey_scene.dart';
import 'journey_scene_controller.dart';

/// Converts a route position ([meters], point A = 0) to the world-space x
/// this scene renders in ("world" here means Flame's `World`/camera
/// coordinate system, which this scene keeps numerically identical to
/// logical screen pixels — see [JourneySceneController]'s own doc comment).
/// Shared by every entity that stands at a fixed route position — the
/// terrain, the solid traveler, friend markers — so a given route meter
/// always resolves to the same x regardless of which of them asks.
double worldXFor(double meters, double pixelsPerMeter) =>
    meters * pixelsPerMeter;

/// How far the placeholder terrain rises and falls from its vertical
/// centre, in pixels — same value the CustomPaint placeholder used
/// (`journey_path_view.dart`'s `_waveAmplitude`), kept for continuity while
/// there is still no real per-biome elevation art (§9.1).
const double terrainWaveAmplitude = 36;

/// World-space distance, in pixels, over which the placeholder terrain
/// completes one full up-down cycle.
const double terrainWaveWavelength = 260;

/// The world-space y the horizon line oscillates around — `0`, matching
/// [JourneyScene]'s camera, whose `viewfinder.position.y` never moves off
/// `0` (only `x` follows `panMeters`). Every entity that stands on the
/// horizon (the terrain itself, the traveler, friends) is positioned
/// relative to this constant rather than deriving it per-frame from the
/// camera's visible rect — there is exactly one place that says where the
/// scene's vertical centre is.
const double terrainMidY = 0;

/// Height of the horizon line at world position [worldX], for a quest whose
/// [profile] is `null` — the original placeholder sine wave (§9.1: no real
/// per-biome elevation art yet), kept exactly as it always rendered so a
/// quest with no authored terrain content is visually unaffected by
/// [terrainHeightAt] existing.
double _placeholderTerrainHeightAt(double worldX) {
  final phase = worldX / terrainWaveWavelength * 2 * math.pi;
  return terrainMidY + terrainWaveAmplitude * math.sin(phase);
}

/// Height of the horizon line at world position [worldX] (§6.1's "изменения
/// высоты, спуски и подъемы").
///
/// Deliberately a function of **world position** (and the fixed [profile]/
/// [pixelsPerMeter] for the current frame), never of the camera's current
/// pan — panning changes which part of this profile is visible, never the
/// profile itself (the same invariant the CustomPaint placeholder's
/// `_wavyPathY` doc comment protected, and the placeholder sine wave still
/// does below).
///
/// [profile] is `null` for a quest that authors no terrain content (today:
/// any quest other than `odyssey-ithaca`, and even that one until content
/// authors a `terrainHeight`) — falls back unchanged to
/// [_placeholderTerrainHeightAt]. Otherwise, [worldX] is converted back to a
/// route position in meters (the inverse of [worldXFor]) and looked up via
/// the domain's own `terrainHeightAt`, scaled from its unitless `-1..1`
/// range to pixels by [terrainWaveAmplitude] — the same scale the
/// placeholder wave already uses, so authored content and the placeholder
/// read at a consistent visual scale.
///
/// A top-level function, not a private method of [HorizonTerrainLayer]: it
/// is also the one place `achievement_overlay.dart` (the trophy guide-line),
/// `friend_component.dart` and `traveler_component.dart` ask "how tall is
/// the ground here" — there is exactly one function that knows the shape of
/// this curve.
double terrainHeightAt(
  double worldX,
  domain.TerrainProfile? profile,
  double pixelsPerMeter,
) {
  if (profile == null) return _placeholderTerrainHeightAt(worldX);

  final meters = pixelsPerMeter <= 0 ? 0 : (worldX / pixelsPerMeter).round();
  return terrainMidY +
      terrainWaveAmplitude * domain.terrainHeightAt(profile, meters);
}

/// A few pixels per sampled point reads as smooth without evaluating `sin()`
/// at every physical pixel — same step the CustomPaint placeholder used.
const double _terrainStep = 4.0;

/// The horizon line every on-path figure (traveler, friends) stands on —
/// this scene's "background, always on the horizon, height can vary" layer.
///
/// A `World` child, rendered under [JourneyScene]'s real `CameraComponent` —
/// unlike [EnvironmentLayer] (`environment_layer.dart`), this layer moves at
/// the camera's own 1:1 rate (`velocityMultiplier` conceptually `1.0`,
/// matching every on-path figure), so Flame's own camera transform is
/// exactly the "render in world space" this needs — no manual parallax
/// offset math here (contrast [EnvironmentLayer], which deliberately opts
/// out of the camera transform to move at a *different* rate).
///
/// Renders only the currently visible window
/// (`game.camera.visibleWorldRect`), not the whole route: a quest can span
/// on the order of a hundred screen-widths (§ "Рендер в окне" in the
/// implementation plan), so caching one `Path` for the entire route in
/// [onLoad] would mean either a path with an enormous coordinate range or,
/// worse, silently wrong geometry once the route is longer than whatever
/// arbitrary bound got baked in. Only the [Paint] is a long-lived field —
/// the per-frame `Path` itself is bounded by screen width, not route
/// length, so building a fresh one every [render] is the same bounded cost
/// the old `CustomPainter` already paid per frame, not a new allocation
/// concern.
class HorizonTerrainLayer extends PositionComponent
    with HasGameReference<JourneyScene> {
  HorizonTerrainLayer({required this.controller}) : super(priority: 0);

  final JourneySceneController controller;

  final Paint _linePaint = Paint()
    ..color = AppColors.gold.withValues(alpha: 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = AppStroke.path;

  @override
  void render(Canvas canvas) {
    final visible = game.camera.visibleWorldRect;
    // Clip to the route's own bounds — the line only exists between point A
    // (0 m) and point B (totalMeters), same as the CustomPaint placeholder.
    final routeRight = worldXFor(
      controller.totalMeters.toDouble(),
      controller.pixelsPerMeter,
    );
    final left = math.max(0.0, visible.left);
    final right = math.min(routeRight, visible.right);
    if (right <= left) return;

    final profile = controller.terrainProfile;
    final pixelsPerMeter = controller.pixelsPerMeter;
    final path = Path()
      ..moveTo(left, terrainHeightAt(left, profile, pixelsPerMeter));
    for (var x = left + _terrainStep; x <= right; x += _terrainStep) {
      path.lineTo(x, terrainHeightAt(x, profile, pixelsPerMeter));
    }
    path.lineTo(right, terrainHeightAt(right, profile, pixelsPerMeter));

    canvas.drawPath(path, _linePaint);
  }
}
