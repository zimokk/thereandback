import 'package:freezed_annotation/freezed_annotation.dart';

part 'ground_heightmap.freezed.dart';

/// The relief of one biome's ground art, read straight off the drawing
/// (CLAUDE.md §6.1, §9.1): one height sample per pixel column of the
/// biome's `*_ground.webp` tile, taken from the topmost opaque pixel in
/// that column.
///
/// This is the "рельеф зависит от арта" half of the ground line — the art
/// *is* the source of truth for the small-scale shape, so the traveler
/// walks on exactly the hills that are drawn rather than on a curve tuned
/// separately from them and free to drift away. The slow, route-scale
/// half (a whole segment climbing towards a mountain) stays authored
/// content — `TerrainProfile`, from `locations.json` — and the two are
/// combined by `scene_ground.dart`'s [sceneGroundHeight].
///
/// [samples] are unitless, roughly `-1..1`, the same scale
/// [TerrainPoint.height] already uses — pixels are presentation's job
/// (`terrain_layer.dart`'s `terrainWaveAmplitude`), per CLAUDE.md §5.4's
/// "domain keeps raw units, formatting happens later".
///
/// [tileMeters] is how much of the route one repetition of the tile covers.
/// The tile repeats for as long as its biome lasts, so a biome spanning
/// 150 km does not need a 150 km-wide drawing — which is also why
/// [groundHeightAt] wraps around rather than clamping at the ends, and why
/// the extractor guarantees the first and last sample match (an audible
/// seam in the walking line would otherwise repeat every [tileMeters]).
/// [centerFraction] is where, down the tile's own height (`0` = its top
/// edge, `1` = its bottom), the row that [samples] are measured from sits —
/// the tile's mean ground level. Presentation needs it to place the drawn
/// tile: offsetting the image so that row lands on the line, rather than
/// its top edge, is what makes the drawn silhouette coincide with the line
/// the traveler walks on instead of sitting a constant distance above or
/// below it. It is also what lets two biomes whose ground is drawn at
/// different heights meet without a step.
@freezed
abstract class GroundHeightmap with _$GroundHeightmap {
  const factory GroundHeightmap({
    required List<double> samples,
    required int tileMeters,
    @Default(0.5) double centerFraction,
  }) = _GroundHeightmap;
}

/// Height of [map]'s relief at [meters] along the route, with the tile
/// repeating every [GroundHeightmap.tileMeters] and interpolating linearly
/// between the two samples bracketing the position.
///
/// Linear, not the smoothstep `terrainHeightAt` uses on [TerrainProfile]:
/// samples here are one pixel column apart, i.e. already far denser than
/// the screen's own resolution at this scale, so easing between two of them
/// would smooth nothing visible while costing every frame. Smoothstep earns
/// its keep on the authored profile precisely because those points are
/// kilometres apart.
///
/// The last sample interpolates back into the first, so the seam between
/// two repetitions is exactly as smooth as any other pair of columns.
/// Negative [meters] wraps the same way (the route never renders before
/// point A, but the function stays total rather than trusting that).
///
/// Degenerate maps are flat rather than an error: empty [samples] is `0`,
/// a single sample is that value everywhere, and a non-positive
/// [GroundHeightmap.tileMeters] — which the data layer rejects before
/// building one — means "no repetition scale known", so the first sample
/// stands in for the whole route.
double groundHeightAt(GroundHeightmap map, double meters) {
  final samples = map.samples;
  if (samples.isEmpty) return 0;
  if (samples.length == 1) return samples.single;
  if (map.tileMeters <= 0) return samples.first;

  final tiles = meters / map.tileMeters;
  final phase = tiles - tiles.floorToDouble(); // 0..1, negatives included.
  final position = phase * samples.length;
  final index = position.floor() % samples.length;
  final nextIndex = (index + 1) % samples.length;
  final fraction = position - position.floorToDouble();

  return samples[index] + (samples[nextIndex] - samples[index]) * fraction;
}
