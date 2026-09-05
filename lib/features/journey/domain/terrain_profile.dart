import 'package:freezed_annotation/freezed_annotation.dart';

part 'terrain_profile.freezed.dart';

/// One authored control point of a quest's terrain profile (CLAUDE.md §6.1,
/// §9.1): a position along the route, in meters, and how high the ground
/// sits there.
///
/// [height] is unitless (roughly `-1..1`), not pixels — scaling to screen
/// space is presentation's job (`terrain_layer.dart`'s
/// `terrainWaveAmplitude`), the same "domain stays in raw units, formatting
/// happens later" split CLAUDE.md §5.4 already applies to distances.
@freezed
abstract class TerrainPoint with _$TerrainPoint {
  const factory TerrainPoint({required int meters, required double height}) =
      _TerrainPoint;
}

/// A quest's full-route terrain profile: an ordered list of [TerrainPoint]s,
/// sorted by [TerrainPoint.meters], that [terrainHeightAt] interpolates
/// between.
///
/// Assembled by `journey_terrain_repository.dart` from `locations.json`'s
/// per-landmark `terrainHeight` fields, plus synthetic endpoints at `0` and
/// the route's `totalMeters` — so a profile always spans the whole route
/// even when authored points only cover the middle of it.
@freezed
abstract class TerrainProfile with _$TerrainProfile {
  const factory TerrainProfile({required List<TerrainPoint> points}) =
      _TerrainProfile;
}

/// Height at [meters] along [profile] (§6.1's "изменения высоты, спуски и
/// подъемы"), smoothly interpolated between the two points bracketing it.
///
/// Uses smoothstep (`3t² − 2t³`) over the linear fraction, not a plain lerp:
/// it has zero slope at every control point, so consecutive segments meet
/// without a visible kink, and — unlike a Catmull-Rom spline — it never
/// overshoots past either bracketing point's own height. That matters here
/// because authored points can be sparse and far apart (one per notable
/// landmark, not one per meter): an overshooting spline could dip below or
/// rise above a real content value between two widely-spaced points.
///
/// [meters] is clamped to `[points.first.meters, points.last.meters]` —
/// negative or past-the-end input snaps to the nearest end — the same
/// invariant `route_mapping.dart`'s `metersToPoint` already applies to the
/// map polyline. A profile with fewer than 2 points is flat: empty returns
/// `0`, a single point returns that point's own height everywhere — this is
/// exactly the shape `journey_terrain_repository.dart` never actually
/// produces (it always adds two synthetic endpoints), but keeping the
/// function total avoids a caller needing to special-case it separately.
double terrainHeightAt(TerrainProfile profile, int meters) {
  final points = profile.points;
  if (points.isEmpty) return 0;
  if (points.length == 1) return points.single.height;

  final minMeters = points.first.meters;
  final maxMeters = points.last.meters;
  final target = meters < minMeters
      ? minMeters
      : (meters > maxMeters ? maxMeters : meters);

  for (var i = 0; i < points.length - 1; i++) {
    final from = points[i];
    final to = points[i + 1];
    if (target > to.meters) continue;

    final segmentMeters = to.meters - from.meters;
    final fraction = segmentMeters <= 0
        ? 0.0
        : (target - from.meters) / segmentMeters;
    final eased = fraction * fraction * (3 - 2 * fraction);

    return from.height + (to.height - from.height) * eased;
  }

  // Unreachable given the clamp above (the loop always finds a bracketing
  // segment before running out) — fails safe to the last point rather than
  // throwing if that invariant is ever wrong, same posture
  // `route_mapping.dart`'s `metersToPoint` takes at its own end.
  return points.last.height;
}
