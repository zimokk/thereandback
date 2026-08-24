import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_mapping.freezed.dart';

/// One vertex of a route's polyline (§6.2): a point on the drawn map
/// (`assets/journeys/{id}/map.webp`), in normalized `(0..1, 0..1)`
/// coordinates over that image, tagged with how many meters of the route
/// have been walked by the time the traveler reaches it.
///
/// This is `map.json` content (Phase 6/11) — assembled from quest data, not
/// user input, so [metersToPoint] assumes vertices are ordered with
/// non-decreasing [cumulativeMeters] rather than re-validating that here.
@freezed
abstract class RouteVertex with _$RouteVertex {
  const factory RouteVertex({
    required double x,
    required double y,
    required int cumulativeMeters,
  }) = _RouteVertex;
}

/// A point on the drawn map, in the same normalized `(0..1, 0..1)`
/// coordinate space as [RouteVertex] — what [metersToPoint] returns. A
/// separate type from [RouteVertex] because a point on the map doesn't
/// carry a distance-along-the-route of its own.
@freezed
abstract class MapPoint with _$MapPoint {
  const factory MapPoint({required double x, required double y}) = _MapPoint;
}

/// A quest's route, as the ordered polyline `map.json` stores: first
/// [RouteVertex] at 0 m (point A), last at the quest's total length
/// (point B).
@freezed
abstract class RoutePolyline with _$RoutePolyline {
  const factory RoutePolyline({required List<RouteVertex> vertices}) =
      _RoutePolyline;
}

/// Maps a distance along the route to a point on the drawn map (§6.2),
/// linearly interpolating between the two vertices whose cumulative
/// distances bracket [meters].
///
/// Only this direction is implemented today — point → meters (for tapping
/// a spot on the map) is deferred until something on the map actually needs
/// tapping; adding it later doesn't change this function.
///
/// [meters] is clamped to `[0, polyline's own total length]`: a negative
/// input snaps to the first vertex, an input past the route's end snaps to
/// the last one — this never extrapolates off the drawn path.
MapPoint metersToPoint(RoutePolyline polyline, int meters) {
  final vertices = polyline.vertices;
  assert(
    vertices.isNotEmpty,
    'a route polyline always has at least one vertex',
  );

  if (vertices.length == 1) {
    final only = vertices.single;
    return MapPoint(x: only.x, y: only.y);
  }

  final maxMeters = vertices.last.cumulativeMeters;
  final target = meters < 0 ? 0 : (meters > maxMeters ? maxMeters : meters);

  for (var i = 0; i < vertices.length - 1; i++) {
    final from = vertices[i];
    final to = vertices[i + 1];
    if (target > to.cumulativeMeters) continue;

    final segmentMeters = to.cumulativeMeters - from.cumulativeMeters;
    final fraction = segmentMeters <= 0
        ? 0.0
        : (target - from.cumulativeMeters) / segmentMeters;

    return MapPoint(
      x: from.x + (to.x - from.x) * fraction,
      y: from.y + (to.y - from.y) * fraction,
    );
  }

  // Unreachable given the clamp above (the loop always finds a bracketing
  // segment before running out) — fails safe to the last vertex rather
  // than throwing if that invariant is ever wrong.
  final last = vertices.last;
  return MapPoint(x: last.x, y: last.y);
}
