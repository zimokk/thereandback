import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../data/scene_art_catalog.dart';
import '../domain/ground_heightmap.dart';
import '../domain/scene_ground.dart';
import '../domain/segment_biomes.dart';
import '../domain/terrain_profile.dart' as domain;
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

/// How much lower than dead centre the horizon renders, as a fraction of
/// [JourneySceneController.sceneHeight] — CLAUDE.md §6.1 (2026-09-15
/// request): at the previous `Anchor.center` default, the traveler and
/// ground sat at exactly 50% down the screen, reading as "visually very
/// high" and leaving too little sky above for the sky gradient/future
/// background art to show. [JourneyScene.onLoad] applies this to the
/// camera's own `viewfinder.anchor`, which shifts every `World` child
/// (ground, traveler, friends, environment layers, start art) down
/// together in one place, rather than each layer separately. Originally
/// `0.2`, brought back up to `0.13` the same day (CLAUDE.md §14 — "too
/// low now") once the full `0.2` lowering read as too much on a real
/// illustration.
const double horizonLoweringFraction = 0.13;

/// Fraction of the scene's height, from the top, at which the horizon
/// (world y [terrainMidY]) actually renders on screen once
/// [horizonLoweringFraction] is applied — `0.5` (dead centre) plus that
/// lowering. Every `World` child gets this for free through the camera's
/// own transform; `achievement_overlay.dart`'s guide-line painter is the
/// one screen-space calculation that sits *outside* that transform, so it
/// repeats this exact fraction to land on the same line the camera draws.
const double horizonScreenYFraction = 0.5 + horizonLoweringFraction;

/// Height of the horizon line at world position [worldX], for a quest whose
/// [profile] is `null` — the original placeholder sine wave (§9.1: no real
/// per-biome elevation art yet), kept exactly as it always rendered so a
/// quest with no authored terrain content is visually unaffected by
/// [terrainHeightAt] existing.
double _placeholderTerrainHeightAt(double worldX) {
  final phase = worldX / terrainWaveWavelength * 2 * math.pi;
  return terrainMidY + terrainWaveAmplitude * math.sin(phase);
}

/// How tall a biome's ground tile is drawn, as a multiple of the scene's
/// height.
///
/// Larger than the screen on purpose: the tile is positioned by its own
/// mean ground level ([GroundHeightmap.centerFraction]), which sits some way
/// down from its top edge, so the part below that line has to be long enough
/// to still reach past the bottom of the screen when the authored profile
/// lifts the line towards the top.
///
/// It is also, exactly, the scale of the drawn relief: a hill drawn one
/// tenth of the tile tall appears one tenth of this height tall on screen.
/// That is the whole contract with the art — what the illustration draws is
/// what the traveler walks over, with no separate amplitude to tune into
/// disagreement with it.
const double groundArtTileHeightFactor = 1.5;

/// Pixels of vertical travel the authored [domain.TerrainProfile] is worth
/// at its extremes (`height: ±1`) — the slow, route-scale half of the line
/// (a whole segment climbing towards a mountain).
///
/// Independent of the art's own amplitude above, because this half has no
/// drawn tile to stay aligned with: it moves the tile instead. Bounded
/// well inside half a screen so a climb can never carry the traveler off
/// the top or bottom of the view — the camera does not follow the ground
/// vertically (a deliberate choice: a fixed camera is what makes a climb
/// read as a climb rather than as the world tilting).
const double macroTerrainAmplitude = 90;

/// Height of the ground line at world position [worldX] (§6.1's "изменения
/// высоты, спуски и подъемы") — the single function every figure on the
/// path agrees on, so the drawn ground, the traveler's feet, friend markers
/// and the trophy guide-lines cannot end up on four subtly different curves.
///
/// Deliberately a function of **world position** (and the fixed content and
/// art in [controller] for the current frame), never of the camera's
/// current pan — panning changes which part of this curve is visible, never
/// the curve itself.
///
/// Combines the two halves described on [groundArtTileHeightFactor] and
/// [macroTerrainAmplitude]: the biome art's own drawn relief, blended
/// across a biome boundary, plus the quest's authored profile. Negative
/// because positive height means higher ground, and world y grows downward.
///
/// Falls back to [_placeholderTerrainHeightAt] only when *neither* half
/// exists — a quest with no authored terrain whose biome art has not loaded
/// (today: every quest). A quest with either one gets that one, so art can
/// land one biome at a time without the rest of the route changing shape.
double terrainHeightAt(double worldX, JourneySceneController controller) {
  final pixelsPerMeter = controller.pixelsPerMeter;
  final profile = controller.terrainProfile;
  final meters = pixelsPerMeter <= 0 ? 0 : (worldX / pixelsPerMeter).round();

  final blend = biomeBlendAt(controller.biomes, meters);
  final from = controller.groundFor(blend?.current.biome);
  final to = controller.groundFor(blend?.next?.biome);

  if (profile == null && from == null) {
    return _placeholderTerrainHeightAt(worldX);
  }

  final macro = profile == null ? 0.0 : domain.terrainHeightAt(profile, meters);
  final micro = blendedGroundHeight(
    meters: meters,
    from: from,
    to: to,
    blend: blend?.blend ?? 0,
  );

  return terrainMidY -
      macroTerrainAmplitude * macro -
      controller.sceneHeight * groundArtTileHeightFactor / 2 * micro;
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
/// Renders only the currently visible window, not the whole route: a quest
/// can span on the order of a hundred screen-widths (§ "Рендер в окне" in
/// the implementation plan), so caching one `Path` for the entire route in
/// [onLoad] would mean either a path with an enormous coordinate range or,
/// worse, silently wrong geometry once the route is longer than whatever
/// arbitrary bound got baked in. Only the [Paint] is a long-lived field —
/// the per-frame `Path` itself is bounded by screen width, not route
/// length, so building a fresh one every [render] is the same bounded cost
/// the old `CustomPainter` already paid per frame, not a new allocation
/// concern.
///
/// The visible window is computed straight from [controller] (pan, scene
/// size, scale) — the same inputs [EnvironmentLayer] already uses for its
/// own window — rather than `game.camera.visibleWorldRect`. That getter
/// only refreshes inside [JourneyScene.update], so a `render()` that runs
/// without a preceding `update()` (the game is paused — §6.1/§12 "паузим,
/// когда экран не виден" — while an unrelated Flutter rebuild still
/// repaints this layer) sees a stale window left over from whatever
/// `panMeters` was current at the *last* update, while every other figure
/// on the path (the traveler, friends, the achievement guide lines) reads
/// `controller.panMeters` directly and is never stale. When that stale
/// window happened to sit near route start, the `math.max(0.0, ...)` clamp
/// below (meant only for the route's own left edge) silently ate half of
/// it too — which is what actually produced the bug this doc comment
/// describes: a real device screenshot showing this layer half missing,
/// split exactly down the middle of the screen, background visible on one
/// side. Reproduced in a test by rendering with a changed `panMeters` and
/// no intervening `update()` call; computing the window from [controller]
/// removes the second, independently-stale source entirely.
class HorizonTerrainLayer extends PositionComponent {
  HorizonTerrainLayer({required this.controller}) : super(priority: 0);

  final JourneySceneController controller;

  final Paint _linePaint = Paint()
    ..color = AppColors.gold.withValues(alpha: 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = AppStroke.path;

  @override
  void render(Canvas canvas) {
    final pixelsPerMeter = controller.pixelsPerMeter;
    final sceneWidth = controller.sceneWidth;
    if (pixelsPerMeter <= 0 || sceneWidth <= 0) return;

    final viewLeft =
        worldXFor(controller.panMeters, pixelsPerMeter) - sceneWidth / 2;
    // Clip to the route's own bounds — the line only exists between point A
    // (0 m) and point B (totalMeters), same as the CustomPaint placeholder.
    final routeRight = worldXFor(
      controller.totalMeters.toDouble(),
      pixelsPerMeter,
    );
    final left = math.max(0.0, viewLeft);
    final right = math.min(routeRight, viewLeft + sceneWidth);
    if (right <= left) return;

    final path = Path()..moveTo(left, terrainHeightAt(left, controller));
    for (var x = left + _terrainStep; x <= right; x += _terrainStep) {
      path.lineTo(x, terrainHeightAt(x, controller));
    }
    path.lineTo(right, terrainHeightAt(right, controller));

    canvas.drawPath(path, _linePaint);
  }
}

/// Draws the biome's ground tile under the horizon line — the real art that
/// replaced the placeholder silhouettes (§6.1, §9.1).
///
/// A `World` child like [HorizonTerrainLayer] and every on-path figure: the
/// ground moves with the camera at 1:1, so Flame's own transform already is
/// the meters→screen conversion it needs.
///
/// One `drawVertices` call per visible biome, not one `drawImageRect` per
/// column band: the tile has to be *warped* by the authored profile (the
/// line it sits under rises and falls across the screen), and a textured
/// triangle strip does that in a single draw with the texture repeating
/// horizontally through an [ImageShader]. Per-band image draws would cost
/// one call per few pixels of screen width for the same result.
///
/// Nothing here re-derives the ground's shape: the strip's top edge is
/// placed from [terrainHeightAt] and the tile's own
/// [GroundHeightmap.centerFraction], which is why the drawn silhouette lands
/// on the line the traveler walks rather than near it.
///
/// The visible window is computed straight from [controller], not from
/// `game.camera.visibleWorldRect` — see [HorizonTerrainLayer]'s doc comment
/// for why that getter can go stale relative to `controller.panMeters` and
/// what that stale window did to this exact layer on a real device.
class GroundArtLayer extends PositionComponent {
  GroundArtLayer({required this.controller}) : super(priority: -10);

  final JourneySceneController controller;

  final Paint _paint = Paint();

  /// Width, in world pixels, between two columns of the triangle strip.
  /// Only the authored profile varies between them — the tile's own relief
  /// is in the texture, at full pixel resolution regardless of this step —
  /// so a coarse step costs nothing visible while keeping the vertex count
  /// bounded by screen width.
  static const double _stripStep = 16;

  @override
  void render(Canvas canvas) {
    final pixelsPerMeter = controller.pixelsPerMeter;
    final sceneWidth = controller.sceneWidth;
    final sceneHeight = controller.sceneHeight;
    if (pixelsPerMeter <= 0 || sceneWidth <= 0 || sceneHeight <= 0) return;
    if (controller.biomes.isEmpty) return;

    final viewLeft =
        worldXFor(controller.panMeters, pixelsPerMeter) - sceneWidth / 2;
    final routeRight = worldXFor(
      controller.totalMeters.toDouble(),
      pixelsPerMeter,
    );
    final left = math.max(0.0, viewLeft);
    final right = math.min(routeRight, viewLeft + sceneWidth);
    if (right <= left) return;

    // Each biome on screen is drawn over its own stretch of world x, with
    // the one being crossed into painted over the one being left at the
    // transition's own opacity — the same eased fraction the ground's relief
    // is already blending with (`scene_ground.dart`'s `easeGroundBlend`), so
    // the hills and the line they belong to never lead or trail each other.
    for (final span in controller.biomes) {
      final art = controller.biomeArt[span.biome];
      final image = art?.layers[SceneArtLayer.ground];
      final ground = art?.ground;
      if (image == null || ground == null) continue;

      final spanLeft = math.max(
        left,
        worldXFor(span.fromMeters.toDouble(), pixelsPerMeter),
      );
      // A span's art carries on under the next one for as long as the
      // cross-fade lasts, so the two overlap instead of meeting at a seam.
      final spanRight = math.min(
        right,
        worldXFor(span.toMeters.toDouble(), pixelsPerMeter) +
            biomeTransitionMeters * pixelsPerMeter,
      );
      if (spanRight <= spanLeft) continue;

      _drawTile(canvas, image, ground, spanLeft, spanRight, sceneHeight);
    }
  }

  void _drawTile(
    Canvas canvas,
    Image image,
    GroundHeightmap ground,
    double left,
    double right,
    double sceneHeight,
  ) {
    final pixelsPerMeter = controller.pixelsPerMeter;
    final tileWidth = ground.tileMeters * pixelsPerMeter;
    if (tileWidth <= 0) return;

    final drawnHeight = sceneHeight * groundArtTileHeightFactor;
    final scaleX = tileWidth / image.width;
    final scaleY = drawnHeight / image.height;

    final positions = <Offset>[];
    final texture = <Offset>[];
    for (var x = left; ; x += _stripStep) {
      final columnX = math.min(x, right);
      // The line at this column, minus the relief the texture itself draws
      // — what is left is where the tile's *mean* ground level belongs, and
      // the tile is hung from there by its own centerFraction.
      final lineY = terrainHeightAt(columnX, controller);
      final microY =
          drawnHeight / 2 * _microAt(ground, columnX, pixelsPerMeter);
      final topY = lineY + microY - ground.centerFraction * drawnHeight;

      positions.add(Offset(columnX, topY));
      positions.add(Offset(columnX, topY + drawnHeight));
      // Texture coordinates are in the *shader's* space, which the matrix
      // below scales down into image pixels — so they are given in the same
      // drawn pixels as the positions, not in image pixels. Horizontally
      // they run on past one tile's width and the shader's
      // `TileMode.repeated` wraps them, which is what covers a whole biome
      // from one drawing without a seam or a modulo jump mid-strip.
      // Vertically each column maps its own top vertex to the image's top
      // row, so a column lifted by the authored profile carries the drawing
      // with it instead of sliding it against the strip.
      texture.add(Offset(columnX, 0));
      texture.add(Offset(columnX, drawnHeight));

      if (columnX >= right) break;
    }
    if (positions.length < 4) return;

    _paint.shader = ImageShader(
      image,
      TileMode.repeated,
      TileMode.clamp,
      // The shader's own transform, column-major — written out rather than
      // built through `Matrix4`, whose Flame-exported flavour stores
      // float32 while `ImageShader` wants float64.
      Float64List.fromList([
        scaleX, 0, 0, 0, //
        0, scaleY, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1, //
      ]),
      filterQuality: FilterQuality.low,
    );
    canvas.drawVertices(
      Vertices(
        VertexMode.triangleStrip,
        positions,
        textureCoordinates: texture,
      ),
      BlendMode.srcOver,
      _paint,
    );
  }

  /// The relief this one tile contributes at [worldX], without any blend
  /// towards a neighbouring biome — the part of [terrainHeightAt]'s result
  /// that this tile's own pixels already draw.
  double _microAt(
    GroundHeightmap ground,
    double worldX,
    double pixelsPerMeter,
  ) {
    return groundHeightAt(ground, worldX / pixelsPerMeter);
  }
}
