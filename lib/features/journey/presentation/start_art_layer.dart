import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../domain/journey_start_art.dart';
import 'environment_layer.dart';
import 'journey_scene_controller.dart';
import 'terrain_layer.dart';
import 'traveler_component.dart';

/// How tall [StartArtLayer] draws its tile, as a multiple of the scene's
/// height — taller than the screen (like [environmentLayerHeightFactor]'s
/// own comment explains) so it still covers everything above/below its
/// own hung baseline rather than leaving a band of bare sky or ground
/// showing past its edges. Originally `1.6`, tuned for the old procedural
/// Troy placeholder (any crop of a repeating silhouette still "worked");
/// brought down once a real illustration replaced it (CLAUDE.md §14,
/// 2026-09-15 — at `1.6` only a small, heavily zoomed-in corner of the art
/// was ever visible). Lower reads as more of the illustration at once;
/// too low re-opens a bare gap below the ground line (verified against
/// `start_art_layer_test.dart`'s own coverage assertion, not eyeballed).
const double startArtHeightFactor = 1.0;

/// Where the art's own silhouette sits down its source image, as a
/// fraction of the drawn tile's height (`0` = top, `1` = bottom) — mirrors
/// `groundArtTileHeightFactor`'s `GroundHeightmap.centerFraction`, except
/// fixed rather than measured: this art is never re-extracted for relief,
/// so there is nothing to read the value back from. Originally `0.62`,
/// matching `tools/generate_scene_art.py`'s old procedural Troy
/// placeholder's own `wall_top`; lowered to `0.46` alongside
/// [startArtHeightFactor] above once a real illustration replaced that
/// placeholder (CLAUDE.md §14, 2026-09-15) — `0.46` is close to where this
/// specific image's own clifftop path actually sits down its (cropped)
/// frame, so less of [startArtHeightFactor]'s scale is spent on the part
/// of the image above the ground line that this row doesn't need to cover.
/// `tower-of-lights`' own procedural placeholder still renders correctly
/// at this lower value too (its own drawn base sits even further down its
/// frame than this row, so it only gains extra safety margin below the
/// line, not a gap).
const double startArtMeanRow = 0.46;

/// Fills the space between the screen's left edge and the route's own
/// start (0 m, point A) with a per-quest illustration (§6.1, §9.1) — Troy's
/// walls for the Odyssey, the Bellglass Tower for The Road to the Skyfire
/// (`journey_start_art.dart`). Without this, that space showed nothing but
/// sky/backdrop: `GroundArtLayer`/`HorizonTerrainLayer` both stop exactly
/// at 0 m by design (nothing has been authored before point A), which is
/// correct for the route itself but left the space in front of it bare.
///
/// A `World` child at a fixed priority above every [EnvironmentLayer]
/// instance (`environment_layer.dart`) — those layers are deliberately
/// unclipped at the route's bounds (their own tiles/decorations continue
/// scrolling past 0 m, not just up to it), so without a higher priority
/// this art would be drawn *under* them and the generic parallax hills
/// would paint straight over Troy's own silhouette wherever the two
/// overlap. It never has to out-rank [TravelerComponent] the same way: its
/// own drawn rect never extends past world x `0`, and the traveler is
/// never drawn *before* 0 m (`JourneySceneController.displayedProgressMeters`
/// is never negative), so the two can never occupy the same pixel.
class StartArtLayer extends PositionComponent {
  StartArtLayer({required this.controller}) : super(priority: _priority);

  final JourneySceneController controller;

  /// Above [EnvironmentLayer.front]'s `30` — see this class's own doc
  /// comment for why that ordering has to hold.
  static const int _priority = 31;

  // `isAntiAlias: false` for the same reason `EnvironmentLayer._artPaint`
  // turns it off (`environment_layer.dart`) — this layer's own right edge
  // sits exactly at the route's start (world x `0`), directly abutting
  // whatever `EnvironmentLayer`/`GroundArtLayer` tile is drawn underneath at
  // that same x. Anti-aliasing that edge blends it against the backdrop
  // rather than the neighbouring art, which is the same translucent-seam
  // artifact, just at this layer's one fixed boundary instead of a
  // repeating tile's many.
  final Paint _paint = Paint()
    ..filterQuality = FilterQuality.low
    ..isAntiAlias = false;

  @override
  void render(Canvas canvas) {
    final pixelsPerMeter = controller.pixelsPerMeter;
    final sceneWidth = controller.sceneWidth;
    final sceneHeight = controller.sceneHeight;
    if (pixelsPerMeter <= 0 || sceneWidth <= 0 || sceneHeight <= 0) return;

    // The route's own start, in world x — this layer's right edge always
    // lands exactly here, never past it (see the `left`/`drawnWidth` below).
    final routeStartX = worldXFor(0, pixelsPerMeter);
    final viewLeft =
        worldXFor(controller.panMeters, pixelsPerMeter) - sceneWidth / 2;
    final gapWidth = routeStartX - viewLeft;
    if (gapWidth <= 0) return; // route start is not left of the visible view.

    final assetPath = startArtAssetPathFor(controller.journeyId);
    if (assetPath == null) return;
    final image = controller.propSprite?.call(assetPath);
    if (image == null) return; // still loading, or this quest ships none.

    final drawnHeight = sceneHeight * startArtHeightFactor;
    final naturalWidth = drawnHeight * image.width / image.height;
    // Wider than the widest possible gap on an ordinary phone already (see
    // the constants' own doc comments), but never narrower than the gap
    // actually on screen — a device wide enough to need it just stretches
    // the art's own left margin, which `generate_scene_art.py` draws as
    // plain flat fill for exactly this reason.
    final drawnWidth = math.max(naturalWidth, gapWidth);

    final baseline = terrainHeightAt(routeStartX, controller);
    final top = baseline - startArtMeanRow * drawnHeight;
    final left = routeStartX - drawnWidth;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(left, top, drawnWidth, drawnHeight),
      _paint,
    );
  }
}
