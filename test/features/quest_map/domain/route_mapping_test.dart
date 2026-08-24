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
}
