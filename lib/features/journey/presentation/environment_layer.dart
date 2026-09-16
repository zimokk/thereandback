import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../design/colors.dart';
import '../data/scene_art_catalog.dart';
import '../domain/scene_ground.dart';
import '../domain/scene_prop_anchor.dart';
import '../domain/segment_biomes.dart';
import 'journey_scene_controller.dart';
import 'terrain_layer.dart';

/// World-space x at which to place an object that should *appear* to move at
/// [velocityMultiplier] times the camera's own rate, given its fixed
/// reference position [objectMeters] and the current [panMeters]/
/// [pixelsPerMeter].
///
/// The camera already translates every `World` child by the full pan
/// (`JourneyScene.update`), which is exactly right for anything standing on
/// the route and exactly wrong for a layer meant to drift at its own speed.
/// Sliding the layer forward by the part of the pan it is *not* supposed to
/// feel — `panMeters * (1 - velocityMultiplier)` — leaves the camera to
/// cancel out the rest, so what lands on screen moves at
/// [velocityMultiplier]:
///
/// - `1.0` cancels nothing: the on-path rate every world-space entity
///   (terrain, traveler, friends) already moves at.
/// - Below `1.0` reads as further away, moving less (§6.1's "дальние холмы
///   медленно"); above `1.0` as closer, moving more ("передний план
///   быстро").
///
/// A pure function, not just [EnvironmentLayer]'s private math — it is what
/// `environment_layer_test.dart` asserts linearity against (CLAUDE.md §12:
/// "parallax offset is linear in scroll position") without needing a
/// running `FlameGame`.
///
/// This replaced an earlier screen-space version that these layers used
/// while being added to the `World` anyway — so the camera's translation
/// landed on top of the layer's own, every layer ended up moving at the
/// same rate no matter its multiplier, and the whole point of the parallax
/// was silently lost. The old function's own doc comment claimed these
/// layers were not `World` children; the code had them as children. Only
/// the pure function was under test, which is why nothing caught it.
double parallaxWorldX({
  required double objectMeters,
  required double panMeters,
  required double velocityMultiplier,
  required double pixelsPerMeter,
}) {
  return (objectMeters + panMeters * (1 - velocityMultiplier)) * pixelsPerMeter;
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
/// A `World` child, like every other part of the scene — its z-order has to
/// interleave with the traveler and the ground, which a direct game child
/// (drawn either wholly behind or wholly in front of the entire world)
/// cannot do. It therefore moves at the camera's own 1:1 rate by default and
/// buys its parallax back through [parallaxWorldX], the manual equivalent of
/// `ParallaxComponent`'s `velocityMultiplier`.
///
/// Hand-rolled rather than a real `ParallaxComponent` (§3 names one) because
/// the art changes per biome and has to cross-fade at every segment
/// boundary: `ParallaxComponent` takes a fixed set of layers for the life of
/// the component, so per-segment swapping would mean rebuilding it mid-scene
/// anyway. The contract this exposes (`velocityMultiplier`, `priority`) is
/// the same either way, so the choice stays reversible.
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
    required this.scenePropLayer,
    required this.artLayer,
    required int priority,
    required Color color,
    required this.baselineFraction,
    required this.bucketMeters,
    required this.seed,
  }) : _paint = Paint()..color = color,
       super(priority: priority);

  /// Behind the characters and behind the ground art (priority -20) —
  /// middle-distance, slow-moving silhouettes.
  factory EnvironmentLayer.behind(JourneySceneController controller) =>
      EnvironmentLayer._(
        velocityMultiplier: 0.5,
        controller: controller,
        scenePropLayer: ScenePropLayer.behind,
        artLayer: SceneArtLayer.mid,
        priority: -20,
        color: AppColors.journeySceneEnvironmentBehind,
        baselineFraction: 0.47,
        bucketMeters: 420,
        seed: 1,
      );

  /// In front of the characters (priority 30) — close, fast-moving
  /// decoration.
  factory EnvironmentLayer.front(JourneySceneController controller) =>
      EnvironmentLayer._(
        velocityMultiplier: 1.6,
        controller: controller,
        scenePropLayer: ScenePropLayer.front,
        artLayer: SceneArtLayer.front,
        priority: 30,
        color: AppColors.journeySceneEnvironmentFront,
        baselineFraction: 0.78,
        bucketMeters: 260,
        seed: 2,
      );

  /// The furthest silhouettes, behind everything (priority -30) — slowest,
  /// so distant hills barely move while the foreground rushes past (§6.1's
  /// "небо почти статично, дальние холмы медленно").
  ///
  /// Draws art only: it has no procedural placeholder and no anchored props
  /// of its own, because there was no third depth before the art existed —
  /// a quest whose biome ships no `far` tile simply has nothing back there,
  /// exactly as today.
  factory EnvironmentLayer.distant(JourneySceneController controller) =>
      EnvironmentLayer._(
        velocityMultiplier: 0.25,
        controller: controller,
        scenePropLayer: null,
        artLayer: SceneArtLayer.far,
        priority: -30,
        color: AppColors.journeySceneEnvironmentBehind,
        baselineFraction: 0.42,
        bucketMeters: 0,
        seed: 3,
      );

  final double velocityMultiplier;
  final JourneySceneController controller;

  /// Which of a biome's drawn layers this instance paints
  /// (`scene_art_catalog.dart`). When the current biome ships that file,
  /// it replaces this layer's procedural placeholder outright — the
  /// placeholder is not drawn underneath it.
  final SceneArtLayer artLayer;

  /// Which named/anchored props (`controller.sceneProps`) belong to this
  /// instance — matches [EnvironmentLayer.behind]/[EnvironmentLayer.front]
  /// 1:1, so a [ScenePropAnchor] renders on exactly the one instance whose
  /// depth its content author picked. `null` on
  /// [EnvironmentLayer.distant], which content cannot anchor to.
  final ScenePropLayer? scenePropLayer;

  /// Width, in this layer's own reference-meters axis, of one deterministic
  /// "bucket" — one decoration is generated per bucket.
  final double bucketMeters;

  /// Where this layer's silhouette ridge sits, as a fraction of scene
  /// height (`0` = top of the screen, `1` = bottom). The further-away
  /// layers ridge just above the horizon the ground draws around
  /// mid-screen; the front layer sits well below it, reading as close
  /// enough to pass in front of the traveler.
  final double baselineFraction;

  /// Seeds each bucket's `math.Random` differently between the two layer
  /// instances, so `behind` and `front` don't generate identical patterns.
  final int seed;

  final Paint _paint;

  /// Reused across frames and tiles — a `Paint` per drawn tile would be an
  /// allocation per frame per repetition, which is exactly what the scene's
  /// own perf rule rules out.
  ///
  /// `isAntiAlias: false` — each repetition of a tile is its own
  /// `drawImageRect` call, and consecutive tiles' rects meet at exactly the
  /// same world x (`parallaxWorldX`'s own math is already seamless). With
  /// the default `Paint().isAntiAlias == true`, Skia anti-aliases that
  /// shared edge on *each* rect independently against whatever is already
  /// painted, rather than against the neighbouring tile — so a boundary
  /// that lands off the physical pixel grid gets two partial-coverage
  /// blends instead of one full one, leaving a thin translucent seam where
  /// the backdrop shows through even though the tiles are positioned
  /// exactly edge-to-edge. Turning AA off makes each rect hard-edged, so
  /// the shared boundary is drawn once, not twice.
  final Paint _artPaint = Paint()..isAntiAlias = false;

  /// Cached result of the last [_decorationsFor] call, keyed by the exact
  /// bucket range it was built for — most frames pan by nothing at all (the
  /// camera only moves during an active drag/return-to-You animation), so
  /// this turns "no per-frame allocation" (the `flame-scene` skill's own
  /// rule) from an aspiration into what actually happens on a still frame:
  /// [render] reuses this list instead of rebuilding it every tick.
  List<_Decoration> _cachedDecorations = const [];
  int? _cachedFirstBucket;
  int? _cachedLastBucket;

  List<_Decoration> _decorationsFor(int firstBucket, int lastBucket) {
    if (_cachedFirstBucket == firstBucket && _cachedLastBucket == lastBucket) {
      return _cachedDecorations;
    }
    final decorations = <_Decoration>[];
    for (var bucket = firstBucket; bucket <= lastBucket; bucket++) {
      final random = math.Random(bucket * 1000003 + seed);
      final jitter = random.nextDouble() * bucketMeters;
      final radius = 6 + random.nextDouble() * 10;
      decorations.add(
        _Decoration(meters: bucket * bucketMeters + jitter, radius: radius),
      );
    }
    _cachedFirstBucket = firstBucket;
    _cachedLastBucket = lastBucket;
    _cachedDecorations = decorations;
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
    // World y, not screen y: the camera's viewfinder sits at world y 0, so
    // [baselineFraction] has to be measured from there. Deliberately still
    // `- 0.5`, not `- horizonScreenYFraction` (`terrain_layer.dart`) —
    // leaving this at the old dead-centre reference means this layer's
    // drawn position shifts down by exactly `horizonLoweringFraction` too,
    // same as the ground and every on-path figure, through the camera's own
    // transform, keeping hills and horizon moving as one composition rather
    // than only the ground shifting under a fixed backdrop.
    final baselineY = sceneHeight * (baselineFraction - 0.5);

    if (!_renderBiomeArt(canvas, panMeters, pixelsPerMeter, baselineY)) {
      _renderPlaceholderDecorations(
        canvas,
        centerX,
        panMeters,
        pixelsPerMeter,
        baselineY,
      );
    }

    _renderAnchoredProps(canvas, panMeters, pixelsPerMeter, baselineY);
  }

  /// Draws the biome tile(s) for this layer, cross-fading across a biome
  /// boundary. Returns whether anything was drawn — `false` means the
  /// current biome ships no art for this layer (or none has loaded yet), and
  /// the caller falls back to the procedural placeholder below.
  ///
  /// The tile repeats horizontally, like the ground's, so one drawing covers
  /// a biome of any length; unlike the ground it is not warped by anything,
  /// since nothing walks on it.
  bool _renderBiomeArt(
    Canvas canvas,
    double panMeters,
    double pixelsPerMeter,
    double baselineY,
  ) {
    final blend = biomeBlendAt(controller.biomes, panMeters.round());
    if (blend == null) return false;

    final current = controller.biomeArt[blend.current.biome]?.layers[artLayer];
    final next = blend.next == null
        ? null
        : controller.biomeArt[blend.next!.biome]?.layers[artLayer];
    if (current == null && next == null) return false;

    final eased = easeGroundBlend(blend.blend);
    if (current != null) {
      _drawLayerTile(
        canvas,
        current,
        panMeters,
        pixelsPerMeter,
        baselineY,
        next == null ? 1.0 : 1.0 - eased,
      );
    }
    if (next != null) {
      _drawLayerTile(canvas, next, panMeters, pixelsPerMeter, baselineY, eased);
    }
    return true;
  }

  /// Paints one biome tile across the visible width at [opacity].
  ///
  /// Tiles are placed by [parallaxScreenX] like everything else on this
  /// layer, so the art scrolls at exactly the [velocityMultiplier] the
  /// placeholder decorations used — swapping art in never changes how fast
  /// a layer moves, only what it shows.
  void _drawLayerTile(
    Canvas canvas,
    Image image,
    double panMeters,
    double pixelsPerMeter,
    double baselineY,
    double opacity,
  ) {
    if (opacity <= 0) return;

    final tileWidth = controller.artTileMeters * pixelsPerMeter;
    if (tileWidth <= 0) return;

    final drawnHeight = controller.sceneHeight * environmentLayerHeightFactor;
    // Hung by its middle, which is where the generator centres every
    // parallax silhouette — so [baselineFraction] means "where this layer's
    // ridge sits", and the fill below the ridge reaches down past the
    // horizon to be covered by the ground art.
    final top = baselineY - drawnHeight / 2;

    // The world x of the tile repetition covering the left edge of the
    // screen, then one per tile width until the right edge — bounded by
    // screen width, never by route length.
    final viewLeft =
        worldXFor(panMeters, pixelsPerMeter) - controller.sceneWidth / 2;
    final layerLeft =
        viewLeft -
        parallaxWorldX(
          objectMeters: 0,
          panMeters: panMeters,
          velocityMultiplier: velocityMultiplier,
          pixelsPerMeter: pixelsPerMeter,
        );
    final firstIndex = (layerLeft / tileWidth).floor();
    final lastIndex = ((layerLeft + controller.sceneWidth) / tileWidth).ceil();

    _artPaint
      ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity.clamp(0, 1))
      ..filterQuality = FilterQuality.low;

    for (var index = firstIndex; index <= lastIndex; index++) {
      final left = parallaxWorldX(
        objectMeters: index * controller.artTileMeters.toDouble(),
        panMeters: panMeters,
        velocityMultiplier: velocityMultiplier,
        pixelsPerMeter: pixelsPerMeter,
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(left, top, tileWidth, drawnHeight),
        _artPaint,
      );
    }
  }

  /// The pre-art placeholder: anonymous silhouette blobs scattered
  /// deterministically per visible window. Still the behaviour for any biome
  /// whose art has not landed (§9.1), which is what lets the generated
  /// tiles be replaced one file at a time.
  void _renderPlaceholderDecorations(
    Canvas canvas,
    double centerX,
    double panMeters,
    double pixelsPerMeter,
    double baselineY,
  ) {
    if (bucketMeters <= 0) return;

    final halfWidthMeters = centerX / pixelsPerMeter;
    final windowCenterMeters = panMeters * velocityMultiplier;
    final firstBucket = ((windowCenterMeters - halfWidthMeters) / bucketMeters)
        .floor();
    final lastBucket = ((windowCenterMeters + halfWidthMeters) / bucketMeters)
        .ceil();

    for (final decoration in _decorationsFor(firstBucket, lastBucket)) {
      final x = parallaxWorldX(
        objectMeters: decoration.meters,
        panMeters: panMeters,
        velocityMultiplier: velocityMultiplier,
        pixelsPerMeter: pixelsPerMeter,
      );
      canvas.drawCircle(Offset(x, baselineY), decoration.radius, _paint);
    }
  }

  /// Named, anchored props (§6.1 — e.g. a cyclops silhouette at its own
  /// landmark) — unlike the procedural decorations above, these are never
  /// bucketed or randomized: each sits at exactly its own route position, so
  /// it lines up with wherever the terrain shapes the ground for that same
  /// landmark without the two ever being tuned independently.
  ///
  /// Drawn as its own sprite once the quest ships one
  /// (`ScenePropAnchor.asset`), and as an oversized placeholder circle until
  /// then — larger than any procedural decoration so it reads as deliberate
  /// rather than scatter.
  void _renderAnchoredProps(
    Canvas canvas,
    double panMeters,
    double pixelsPerMeter,
    double baselineY,
  ) {
    for (final anchor in controller.sceneProps) {
      if (anchor.layer != scenePropLayer) continue;
      // An anchor names a position on the *route*, so it is placed at the
      // route's own rate — it has to stay over its landmark, not drift with
      // the layer it happens to be drawn on.
      final x = worldXFor(anchor.meters.toDouble(), pixelsPerMeter);

      final sprite = controller.propSprite?.call(anchor.asset);
      if (sprite == null) {
        // No art for this prop (or it is still loading) — the placeholder
        // shape, larger than any procedural decoration so it still reads as
        // a deliberate, named element.
        canvas.drawCircle(Offset(x, baselineY), _anchoredPropRadius, _paint);
        continue;
      }

      // Stood on the ground, not on this layer's baseline: a prop belongs to
      // its landmark, and the landmark's ground height is what
      // `terrainHeightAt` already decides for everything else on the route.
      // Its own drawing is what sets its size — the scene does not scale it.
      final feet = terrainHeightAt(x, controller);
      canvas.drawImage(
        sprite,
        Offset(x - sprite.width / 2, feet - sprite.height.toDouble()),
        _artPaint..color = const Color(0xFFFFFFFF),
      );
    }
  }
}

/// How tall a parallax layer's tile is drawn, as a multiple of the scene's
/// height. Taller than the screen so a layer whose baseline sits low still
/// covers everything above it, rather than leaving a band of bare sky under
/// its silhouette.
const double environmentLayerHeightFactor = 1.1;

/// Placeholder radius for an anchored [ScenePropAnchor] — larger than any
/// procedural `_Decoration` (`radius: 6 + random * 10`, so at most `16`) so
/// it reads as a deliberate, named element rather than random scatter, even
/// before real art (§9.1) replaces this shape.
const double _anchoredPropRadius = 20;
