import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'journey_scene_controller.dart';

/// Screen-space x for an object that belongs to a parallax layer moving at
/// [velocityMultiplier] times the camera's own rate, given the object's own
/// fixed reference position [objectMeters] and the current [panMeters]/
/// [pixelsPerMeter].
///
/// A pure function, not just [EnvironmentLayer]'s private math — it is what
/// `environment_layer_test.dart` asserts linearity against
/// (CLAUDE.md §12: "parallax offset is linear in scroll position") without
/// needing a running `FlameGame`. `velocityMultiplier: 1.0` is exactly the
/// on-path formula every world-space entity (terrain, traveler, friends)
/// already uses; smaller values read as "further away, moves less" (§6.1's
/// "дальние холмы медленно"), larger as "closer, moves more" ("передний
/// план быстро").
double parallaxScreenX({
  required double centerX,
  required double objectMeters,
  required double panMeters,
  required double velocityMultiplier,
  required double pixelsPerMeter,
}) {
  return centerX +
      (objectMeters - panMeters * velocityMultiplier) * pixelsPerMeter;
}

/// One decorative object's placeholder shape and where it sits, in this
/// layer's own reference-meters axis (not the real route — see
/// [EnvironmentLayer]'s doc comment).
class _Decoration {
  const _Decoration({required this.meters, required this.radius});
  final double meters;
  final double radius;
}

/// A silhouette decoration layer — the "2 environment layers, one behind
/// the characters, one in front" from the request. Two instances exist
/// (`EnvironmentLayer.behind`/`EnvironmentLayer.front`), differing only in
/// [velocityMultiplier], `priority` (z-order relative to
/// [TravelerComponent]/[FriendMarkerComponent]) and a couple of purely
/// cosmetic knobs.
///
/// Deliberately **not** a `World` child: [World]'s children are transformed
/// by [JourneyScene]'s real `CameraComponent` at a uniform 1:1 rate, which
/// is exactly what the on-path entities (terrain, travelers) want but wrong
/// for a background/foreground layer that must move at its *own* rate. This
/// component is added directly to the game instead (screen space,
/// un-transformed) and reproduces the parallax effect itself via
/// [parallaxScreenX] — the manual equivalent of `ParallaxComponent`'s
/// `velocityMultiplier`, chosen over the real thing only because there is
/// no bitmap art yet to feed it (§9.1); swapping to a real `ParallaxComponent`
/// later is a self-contained change to this file, since every other
/// component's contract with this layer (`velocityMultiplier`, `priority`)
/// stays the same either way.
///
/// Decorations are generated **procedurally per visible window**, keyed by
/// a deterministic "bucket" of this layer's own reference-meters axis
/// (`math.Random(bucket)`), not stored as a fixed list spanning the whole
/// route — a quest can be on the order of a hundred screen-widths long, so
/// pre-generating (or even iterating) one shape per bucket across the
/// entire route would make a frame's cost grow with route length. Only the
/// currently visible bucket range is ever touched, so cost stays bounded
/// regardless of how long the quest is.
class EnvironmentLayer extends PositionComponent {
  EnvironmentLayer._({
    required this.velocityMultiplier,
    required this.controller,
    required int priority,
    required Color color,
    required this.baselineFraction,
    required this.bucketMeters,
    required this.seed,
  }) : _paint = Paint()..color = color,
       super(priority: priority);

  /// Behind the characters (priority 10, per the plan's z-order table) —
  /// distant, slow-moving decoration.
  factory EnvironmentLayer.behind(JourneySceneController controller) =>
      EnvironmentLayer._(
        velocityMultiplier: 0.5,
        controller: controller,
        priority: 10,
        color: const Color(0x8A7A6A4C), // muted gold-bronze, low alpha.
        baselineFraction: 0.35,
        bucketMeters: 420,
        seed: 1,
      );

  /// In front of the characters (priority 30) — close, fast-moving
  /// decoration.
  factory EnvironmentLayer.front(JourneySceneController controller) =>
      EnvironmentLayer._(
        velocityMultiplier: 1.6,
        controller: controller,
        priority: 30,
        color: const Color(0xCC1B1B1E), // near-silhouette, mostly opaque.
        baselineFraction: 0.85,
        bucketMeters: 260,
        seed: 2,
      );

  final double velocityMultiplier;
  final JourneySceneController controller;

  /// Width, in this layer's own reference-meters axis, of one deterministic
  /// "bucket" — one decoration is generated per bucket.
  final double bucketMeters;

  /// Vertical placement as a fraction of scene height (`0` = top, `1` =
  /// bottom) — the behind layer sits higher (reads as further away), the
  /// front layer lower (reads as closer to the viewer).
  final double baselineFraction;

  /// Seeds each bucket's `math.Random` differently between the two layer
  /// instances, so `behind` and `front` don't generate identical patterns.
  final int seed;

  final Paint _paint;

  List<_Decoration> _decorationsFor(int firstBucket, int lastBucket) {
    final decorations = <_Decoration>[];
    for (var bucket = firstBucket; bucket <= lastBucket; bucket++) {
      final random = math.Random(bucket * 1000003 + seed);
      final jitter = random.nextDouble() * bucketMeters;
      final radius = 6 + random.nextDouble() * 10;
      decorations.add(
        _Decoration(meters: bucket * bucketMeters + jitter, radius: radius),
      );
    }
    return decorations;
  }

  @override
  void render(Canvas canvas) {
    final pixelsPerMeter = controller.pixelsPerMeter;
    final sceneWidth = controller.sceneWidth;
    final sceneHeight = controller.sceneHeight;
    if (pixelsPerMeter <= 0 || sceneWidth <= 0 || sceneHeight <= 0) return;

    final centerX = sceneWidth / 2;
    final panMeters = controller.panMeters;
    final halfWidthMeters = centerX / pixelsPerMeter;
    final windowCenterMeters = panMeters * velocityMultiplier;
    final firstBucket = ((windowCenterMeters - halfWidthMeters) / bucketMeters)
        .floor();
    final lastBucket = ((windowCenterMeters + halfWidthMeters) / bucketMeters)
        .ceil();

    final baselineY = sceneHeight * baselineFraction;
    for (final decoration in _decorationsFor(firstBucket, lastBucket)) {
      final screenX = parallaxScreenX(
        centerX: centerX,
        objectMeters: decoration.meters,
        panMeters: panMeters,
        velocityMultiplier: velocityMultiplier,
        pixelsPerMeter: pixelsPerMeter,
      );
      canvas.drawCircle(Offset(screenX, baselineY), decoration.radius, _paint);
    }
  }
}
