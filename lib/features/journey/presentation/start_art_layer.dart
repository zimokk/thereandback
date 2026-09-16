import 'dart:ui';

import 'package:flame/components.dart';

import '../../../design/colors.dart';
import '../domain/journey_start_art.dart';
import 'environment_layer.dart';
import 'journey_scene_controller.dart';
import 'terrain_layer.dart';
import 'traveler_component.dart';

/// Where the art's own silhouette sits down its source image, as a
/// fraction of the drawn tile's height (`0` = top, `1` = bottom) — mirrors
/// `groundArtTileHeightFactor`'s `GroundHeightmap.centerFraction`, except
/// fixed rather than measured: this art is never re-extracted for relief,
/// so there is nothing to read the value back from. Originally `0.62`,
/// matching `tools/generate_scene_art.py`'s old procedural Troy
/// placeholder's own `wall_top`; lowered to `0.46` once a real illustration
/// replaced that placeholder (CLAUDE.md §14, 2026-09-15) — `0.46` is close
/// to where this specific image's own clifftop path actually sits down its
/// (cropped) frame. `tower-of-lights`' own procedural placeholder still
/// renders correctly at this lower value too (its own drawn base sits even
/// further down its frame than this row, so it only gains extra safety
/// margin below the line, not a gap).
const double startArtMeanRow = 0.46;

/// Solid tone each quest's start art is extended with below its own drawn
/// bottom edge, so a screen taller (relative to [JourneySceneController.
/// sceneWidth]) than the illustration's own aspect ratio still never shows
/// a bare strip of backdrop under it (CLAUDE.md §14, 2026-09-16 — see
/// [_fillBelowIfNeeded]'s own doc comment for why an extension exists at
/// all). Sampled once from each file's own bottom-edge pixels (the tone the
/// illustration itself already fades/tapers into), not computed at
/// runtime — decoding pixels back out of a loaded `ui.Image` on every frame
/// would cost real time for a value that never changes for a given file. A
/// quest missing here (any future quest whose own art has not been sampled
/// yet) falls back to [AppColors.backgroundElevated] — dark enough to read
/// as "more shadow", not a jarring, oddly-colored patch.
const Map<String, Color> _startArtFillColor = {
  'odyssey-ithaca': Color(0xFF664E25),
  'tower-of-lights': Color(0xFF0E0E12),
};

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

  /// Painted with a fresh `..color` per frame ([_fillBelowIfNeeded]) rather
  /// than recreated — one long-lived [Paint], like [_paint].
  final Paint _fillPaint = Paint()..isAntiAlias = false;

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

    // Fits the *whole* illustration into the gap — no cropping — rather
    // than pinning height to the scene's own height and letting width fall
    // out of that (CLAUDE.md §14, 2026-09-16 bug-fix): the old formula's
    // width was tied to `sceneHeight`, never to [gapWidth], so on a screen
    // much taller than it is wide it always demanded a width far past the
    // gap, and only the illustration's own rightmost sliver — Troy's
    // tapering cliff edge, not its towers — ever ended up on screen. Fitting
    // by width instead means the castle itself is always what is visible,
    // scaled to whatever the gap actually is, on any device.
    final aspect = image.width / image.height;
    final drawnWidth = gapWidth;
    final drawnHeight = drawnWidth / aspect;

    final baseline = terrainHeightAt(routeStartX, controller);
    final top = baseline - startArtMeanRow * drawnHeight;
    final left = routeStartX - drawnWidth;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(left, top, drawnWidth, drawnHeight),
      _paint,
    );

    _fillBelowIfNeeded(
      canvas,
      journeyId: controller.journeyId,
      sceneHeight: sceneHeight,
      imageBottom: top + drawnHeight,
      left: left,
      right: routeStartX,
    );
  }

  /// Extends the illustration's own base tone down to the bottom of the
  /// screen whenever fitting it to the visible gap's width (`render`,
  /// above) leaves it short of that — unavoidable on a screen tall enough,
  /// relative to how narrow the gap currently is, that the illustration's
  /// own aspect ratio cannot reach both edges from a width-only fit.
  /// Filling with the art's own tone ([_startArtFillColor]) rather than
  /// leaving the real gap bare keeps the same "no bare strip under the
  /// illustration" guarantee a height-only fit gave for free, without
  /// reintroducing the crop that fit caused (this class's own doc comment
  /// above).
  void _fillBelowIfNeeded(
    Canvas canvas, {
    required String journeyId,
    required double sceneHeight,
    required double imageBottom,
    required double left,
    required double right,
  }) {
    // The one world y that lands on the screen's own bottom edge — fixed
    // regardless of [JourneySceneController.panMeters], since the camera's
    // vertical anchor never moves off world y `terrainMidY` (`0`,
    // `terrain_layer.dart`): world y `0` always renders at
    // `horizonScreenYFraction * sceneHeight`, so screen y `sceneHeight`
    // (the bottom edge) is always world y `sceneHeight * (1 -
    // horizonScreenYFraction)`.
    final screenBottomWorldY = sceneHeight * (1 - horizonScreenYFraction);
    if (imageBottom >= screenBottomWorldY) return;

    _fillPaint.color =
        _startArtFillColor[journeyId] ?? AppColors.backgroundElevated;
    canvas.drawRect(
      Rect.fromLTRB(left, imageBottom, right, screenBottomWorldY),
      _fillPaint,
    );
  }
}
