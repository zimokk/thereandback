import 'ground_heightmap.dart';

/// The relief the biome art draws at [meters], blended across a biome
/// boundary — the "в зависимости от арта" half of the ground line (§6.1).
///
/// Unitless, like [GroundHeightmap.samples] themselves: how many pixels a
/// unit of relief is worth is presentation's decision (it follows from how
/// tall the tile is drawn — `terrain_layer.dart`'s
/// `groundArtTileHeightFactor`), not the domain's. The authored, route-scale
/// half of the line is `terrain_profile.dart`'s own `terrainHeightAt`,
/// applied separately and with its own amplitude, since it has no drawn tile
/// to stay aligned with.
///
/// [from] and [to] plus [blend] are the crossing of a biome boundary
/// (`segment_biomes.dart`'s `biomeBlendAt`): the two neighbouring tiles'
/// relief is interpolated over the transition window with the same eased
/// fraction the layer art cross-fades with. Without this the walking line
/// would step discontinuously at every segment boundary — the traveler
/// visibly jumping as one tile's relief was swapped for another's.
///
/// A `null` [from] is flat ground, not an error: a biome whose art has not
/// finished loading, or ships none, simply contributes no relief and leaves
/// the line to the authored profile.
double blendedGroundHeight({
  required int meters,
  GroundHeightmap? from,
  GroundHeightmap? to,
  double blend = 0,
}) {
  final fromHeight = from == null
      ? 0.0
      : groundHeightAt(from, meters.toDouble());
  if (to == null) return fromHeight;

  final toHeight = groundHeightAt(to, meters.toDouble());
  final clamped = blend < 0 ? 0.0 : (blend > 1 ? 1.0 : blend);
  return fromHeight + (toHeight - fromHeight) * easeGroundBlend(clamped);
}

/// Smoothstep (`3t² − 2t³`) over a biome transition's raw linear fraction.
///
/// Public and shared rather than duplicated per call site: the ground's
/// relief (here) and the layer art's opacity (`environment_layer.dart`)
/// must cross-fade on the *same* curve, or the drawn hills would lead or
/// trail the line the traveler walks on during a transition. Zero slope at
/// both ends also means the line's shape has no kink at the moment a
/// transition starts or ends.
double easeGroundBlend(double t) => t * t * (3 - 2 * t);
