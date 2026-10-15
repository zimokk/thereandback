import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../domain/scene_ground.dart';

/// Width, in world pixels, between two columns of a strip. Only the strip's
/// top edge and the fade mask vary between columns — the art's own detail is
/// in the texture at full resolution regardless — so a coarse step costs
/// nothing visible while keeping the vertex count bounded by screen width.
const double biomeStripStep = 16;

/// Paints one biome tile across world x `[left, right]` as a single
/// textured triangle strip — the one drawing primitive both the ground
/// (`GroundArtLayer`) and the parallax layers (`EnvironmentLayer`) share.
///
/// - The texture repeats horizontally through an [ImageShader] with
///   [TileMode.repeated], phased so tile repetition `n` starts at world x
///   `textureOriginX + n * tileWidth`. One draw per biome, not one
///   `drawImageRect` per repetition: there is no edge between repetitions
///   for anything to anti-alias, round or misplace, so a repeat can never
///   show as a seam or a one-pixel jump while panning.
/// - [topAt] places the strip's top edge per column, which is how the ground
///   is warped by the authored profile; a parallax layer passes a constant.
/// - [fadeIn], when set, ramps the strip from transparent at its `start` to
///   opaque at its `end` (world x), eased by [easeGroundBlend] — the same
///   curve the ground's relief blends on, so drawn hills and walked line
///   change together.
/// - [fadeOut], when set, is the mirror image: opaque at its `start`,
///   transparent at its `end`. A strip being crossed out of keeps going past
///   its boundary under the one crossed into, dissolving over this window,
///   rather than stopping dead at the boundary: the art crossed into is
///   only opaque where it draws something, so above its silhouette — the
///   sky of a lower ridge — a strip that simply ended would show its own
///   edge as a hard vertical cut.
///
/// Outside both windows the strip is fully opaque.
///
/// [paint] is the caller's long-lived [Paint], so a frame allocates no
/// paint of its own.
void drawBiomeStrip(
  Canvas canvas,
  Paint paint, {
  required Image image,
  required double left,
  required double right,
  required double tileWidth,
  required double textureOriginX,
  required double drawnHeight,
  required double Function(double worldX) topAt,
  ({double start, double end})? fadeIn,
  ({double start, double end})? fadeOut,
}) {
  if (tileWidth <= 0 || drawnHeight <= 0 || right <= left) return;

  final positions = <Offset>[];
  final texture = <Offset>[];
  final colors = fadeIn == null && fadeOut == null ? null : <Color>[];
  for (var x = left; ; x += biomeStripStep) {
    final columnX = math.min(x, right);
    final topY = topAt(columnX);

    positions
      ..add(Offset(columnX, topY))
      ..add(Offset(columnX, topY + drawnHeight));
    // Texture coordinates are in drawn pixels (the shader's matrix below
    // scales them into image pixels). Horizontally they run on past one
    // tile and `TileMode.repeated` wraps them; vertically each column maps
    // its own top vertex to the image's top row, so a column lifted by the
    // profile carries the drawing with it instead of sliding against it.
    final u = columnX - textureOriginX;
    texture
      ..add(Offset(u, 0))
      ..add(Offset(u, drawnHeight));

    if (colors != null) {
      final opacity =
          _ramp(fadeIn, columnX) * (1 - _ramp(fadeOut, columnX, empty: 0));
      // Only the alpha matters (`BlendMode.srcIn` below discards the vertex
      // RGB), so plain white doubles as the mask.
      final alpha = Color.fromARGB((opacity * 255).round(), 255, 255, 255);
      colors
        ..add(alpha)
        ..add(alpha);
    }

    if (columnX >= right) break;
  }
  if (positions.length < 4) return;

  paint
    ..color = const Color(0xFFFFFFFF)
    ..shader = ImageShader(
      image,
      TileMode.repeated,
      TileMode.clamp,
      // Column-major, written out rather than built through `Matrix4`, whose
      // Flame-exported flavour stores float32 while `ImageShader` wants
      // float64.
      Float64List.fromList([
        tileWidth / image.width, 0, 0, 0, //
        0, drawnHeight / image.height, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1, //
      ]),
      filterQuality: FilterQuality.low,
    );
  canvas.drawVertices(
    Vertices(
      VertexMode.triangleStrip,
      positions,
      colors: colors,
      textureCoordinates: texture,
    ),
    // With a fade mask, the shader-sampled art is the "source" and the
    // interpolated vertex colour the "destination": `srcIn` keeps the art's
    // colour and multiplies its alpha by the mask's (verified by rendering —
    // `dstIn` paints a plain white silhouette instead). Without one, plain
    // `srcOver`.
    colors == null ? BlendMode.srcOver : BlendMode.srcIn,
    paint,
  );
}

/// Eased progress through [window] at [x]: `0` before its start, `1` past
/// its end — or [empty] when there is no window at all.
double _ramp(
  ({double start, double end})? window,
  double x, {
  double empty = 1,
}) {
  if (window == null) return empty;
  final span = window.end - window.start;
  if (span <= 0) return x < window.start ? 0 : 1;
  return easeGroundBlend(((x - window.start) / span).clamp(0.0, 1.0));
}
