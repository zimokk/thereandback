import 'package:test/test.dart';
import 'package:thereandback/features/quest_map/domain/route_mapping.dart';

void main() {
  // A simple three-vertex polyline: A (0 m) -> midpoint landmark (400 m) ->
  // B (1000 m), matching §6.2's normalized (0..1, 0..1) coordinate space.
  const polyline = RoutePolyline(
    vertices: [
      RouteVertex(x: 0.0, y: 0.5, cumulativeMeters: 0),
      RouteVertex(x: 0.4, y: 0.2, cumulativeMeters: 400),
      RouteVertex(x: 1.0, y: 0.5, cumulativeMeters: 1000),
    ],
  );

  group('metersToPoint (§6.2 — edges: 0 m and full length)', () {
    test('0 m returns the first vertex — point A', () {
      final point = metersToPoint(polyline, 0);
      expect(point.x, 0.0);
      expect(point.y, 0.5);
    });

    test('full length returns the last vertex — point B', () {
      final point = metersToPoint(polyline, 1000);
      expect(point.x, 1.0);
      expect(point.y, 0.5);
    });

    test('exactly on an interior vertex returns that vertex, not an '
        'interpolation', () {
      final point = metersToPoint(polyline, 400);
      expect(point.x, 0.4);
      expect(point.y, 0.2);
    });

    test('halfway through a segment linearly interpolates', () {
      // 200 m is halfway between the 0 m and 400 m vertices.
      final point = metersToPoint(polyline, 200);
      expect(point.x, closeTo(0.2, 1e-9));
      expect(point.y, closeTo(0.35, 1e-9));
    });

    test('a negative input clamps to point A, never extrapolates', () {
      final point = metersToPoint(polyline, -500);
      expect(point.x, 0.0);
      expect(point.y, 0.5);
    });

    test('an input past the route end clamps to point B', () {
      final point = metersToPoint(polyline, 5000);
      expect(point.x, 1.0);
      expect(point.y, 0.5);
    });

    test(
      'a single-vertex polyline returns that vertex regardless of input',
      () {
        const single = RoutePolyline(
          vertices: [RouteVertex(x: 0.3, y: 0.6, cumulativeMeters: 0)],
        );
        final point = metersToPoint(single, 999);
        expect(point.x, 0.3);
        expect(point.y, 0.6);
      },
    );

    test('a zero-length segment (two vertices at the same distance) does '
        'not divide by zero', () {
      const pause = RoutePolyline(
        vertices: [
          RouteVertex(x: 0.0, y: 0.0, cumulativeMeters: 0),
          RouteVertex(x: 0.5, y: 0.5, cumulativeMeters: 100),
          RouteVertex(x: 0.6, y: 0.5, cumulativeMeters: 100),
          RouteVertex(x: 1.0, y: 1.0, cumulativeMeters: 200),
        ],
      );
      final point = metersToPoint(pause, 100);
      // Both vertices at 100 m are valid answers for "exactly 100 m" — the
      // important thing is this returns a real point, not NaN/Infinity.
      expect(point.x.isFinite, isTrue);
      expect(point.y.isFinite, isTrue);
    });
  });

  group('splitRouteAt (§6.2 — walked stretch vs. the stretch ahead)', () {
    test('at 0 m nothing is walked and the whole route is still ahead', () {
      final split = splitRouteAt(polyline, 0);

      expect(split.walked, hasLength(1));
      expect(split.walked.single.x, 0.0);
      expect(split.remaining, hasLength(3));
      expect(split.remaining.first.x, 0.0);
      expect(split.remaining.last.x, 1.0);
    });

    test('at the full length the whole route is walked', () {
      final split = splitRouteAt(polyline, 1000);

      expect(split.walked, hasLength(3));
      expect(split.walked.last.x, 1.0);
      expect(split.remaining, hasLength(1));
      expect(split.remaining.single.x, 1.0);
    });

    test('the two stretches meet at the same point, so the strokes do not '
        'leave a gap', () {
      final split = splitRouteAt(polyline, 200);
      final here = metersToPoint(polyline, 200);

      expect(split.walked.last, here);
      expect(split.remaining.first, here);
    });

    test('a split exactly on a vertex does not duplicate that vertex', () {
      final split = splitRouteAt(polyline, 400);

      expect(split.walked, hasLength(2)); // 0 m vertex + the 400 m point
      expect(split.remaining, hasLength(2)); // the 400 m point + 1000 m vertex
      expect(split.walked.last.x, 0.4);
      expect(split.remaining.first.x, 0.4);
    });

    test('clamps like metersToPoint — past either end never extrapolates', () {
      expect(splitRouteAt(polyline, -100).walked.single.x, 0.0);
      expect(splitRouteAt(polyline, 9999).remaining.single.x, 1.0);
    });
  });

  group('nextLandmark', () {
    const map = QuestMap(
      journeyId: 'test-quest',
      imageAsset: 'assets/journeys/test-quest/map.webp',
      imageWidth: 1024,
      imageHeight: 1536,
      totalMeters: 1000,
      polyline: polyline,
      landmarks: [
        MapLandmark(id: 'a', name: 'A', x: 0.0, y: 0.5, meters: 0),
        MapLandmark(id: 'mid', name: 'Mid', x: 0.4, y: 0.2, meters: 400),
        MapLandmark(id: 'b', name: 'B', x: 1.0, y: 0.5, meters: 1000),
      ],
    );

    test('returns the first landmark still ahead', () {
      expect(nextLandmark(map, 0)!.id, 'mid');
      expect(nextLandmark(map, 399)!.id, 'mid');
    });

    test('a landmark exactly underfoot counts as reached', () {
      expect(nextLandmark(map, 400)!.id, 'b');
    });

    test('returns null once the last landmark is behind the traveler', () {
      expect(nextLandmark(map, 1000), isNull);
    });
  });
}
