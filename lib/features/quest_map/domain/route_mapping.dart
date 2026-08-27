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

/// A drawn landmark's hotspot on the map (§6.2): where its illustration
/// sits on `map.webp`, in the same normalized `(0..1, 0..1)` space as
/// [RouteVertex], and how far along the route the traveler has to walk to
/// reach it.
///
/// [name] is quest data, not UI copy — it comes from `map.json` alongside
/// the coordinates, the same way `Journey.pointA`/`pointB` do, so it is
/// not an l10n key (§11).
@freezed
abstract class MapLandmark with _$MapLandmark {
  const factory MapLandmark({
    required String id,
    required String name,
    required double x,
    required double y,
    required int meters,
  }) = _MapLandmark;
}

/// One quest's drawn map (§6.2): the illustration to show, the route
/// polyline traced over it, and the landmark hotspots along that route.
///
/// This is the parsed form of `assets/journeys/{journeyId}/map.json`.
/// [imageWidth] / [imageHeight] are the source illustration's pixel size —
/// only their ratio matters, since every coordinate here is normalized, but
/// keeping the numbers makes it obvious which art the trace was made
/// against.
@freezed
abstract class QuestMap with _$QuestMap {
  const factory QuestMap({
    required String journeyId,
    required String imageAsset,
    required int imageWidth,
    required int imageHeight,
    required int totalMeters,
    required RoutePolyline polyline,
    required List<MapLandmark> landmarks,
  }) = _QuestMap;
}

/// The route split at [meters] into the stretch already walked and the
/// stretch still ahead — what the map overlay strokes solid and dashed
/// (§6.2).
///
/// Both lists share the point at [meters] (the last walked point is the
/// first remaining point), so the two strokes meet with no visible gap.
/// [meters] is clamped exactly as [metersToPoint] clamps it.
typedef SplitRoute = ({List<MapPoint> walked, List<MapPoint> remaining});

/// Splits [polyline] at [meters] — see [SplitRoute].
SplitRoute splitRouteAt(RoutePolyline polyline, int meters) {
  final vertices = polyline.vertices;
  assert(
    vertices.isNotEmpty,
    'a route polyline always has at least one vertex',
  );

  final maxMeters = vertices.last.cumulativeMeters;
  final target = meters < 0 ? 0 : (meters > maxMeters ? maxMeters : meters);
  final here = metersToPoint(polyline, target);

  final walked = <MapPoint>[];
  final remaining = <MapPoint>[];
  for (final vertex in vertices) {
    final point = MapPoint(x: vertex.x, y: vertex.y);
    if (vertex.cumulativeMeters < target) {
      walked.add(point);
    } else if (vertex.cumulativeMeters > target) {
      remaining.add(point);
    } else {
      // A vertex exactly at the split is the shared point, added below —
      // never twice.
      continue;
    }
  }

  walked.add(here);
  remaining.insert(0, here);
  return (walked: walked, remaining: remaining);
}

/// The first landmark the traveler has not reached yet, or `null` once
/// every landmark is behind them (the quest's end included).
///
/// Landmarks are compared by their own [MapLandmark.meters]; the list is
/// scanned in `map.json` order, which is sorted by distance along the
/// route.
MapLandmark? nextLandmark(QuestMap map, int meters) {
  for (final landmark in map.landmarks) {
    if (landmark.meters > meters) return landmark;
  }
  return null;
}
