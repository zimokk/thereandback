import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/terrain_profile.dart';

void main() {
  // A three-point profile: flat start -> a peak at 400 m -> flat end,
  // matching the "climb to a landmark, then descend" shape §6.1 asks for.
  const profile = TerrainProfile(
    points: [
      TerrainPoint(meters: 0, height: 0.0),
      TerrainPoint(meters: 400, height: 0.9),
      TerrainPoint(meters: 1000, height: 0.0),
    ],
  );

  group('terrainHeightAt (§6.1 — smooth ascents/descents)', () {
    test('exactly on a control point returns that point\'s own height', () {
      expect(terrainHeightAt(profile, 0), 0.0);
      expect(terrainHeightAt(profile, 400), closeTo(0.9, 1e-12));
      expect(terrainHeightAt(profile, 1000), 0.0);
    });

    test('midway through a segment lies strictly between the two heights '
        '(smoothstep at the midpoint is exactly halfway)', () {
      final height = terrainHeightAt(profile, 200);
      expect(height, closeTo(0.45, 1e-9));
    });

    test('never overshoots past either bracketing point\'s own height', () {
      for (var m = 0; m <= 1000; m += 10) {
        final height = terrainHeightAt(profile, m);
        expect(height, inInclusiveRange(0.0, 0.9));
      }
    });

    test('a negative input clamps to the first point, never extrapolates', () {
      expect(terrainHeightAt(profile, -500), 0.0);
    });

    test('an input past the last point clamps to it', () {
      expect(terrainHeightAt(profile, 5000), 0.0);
    });

    test('a single-point profile returns that height everywhere', () {
      const single = TerrainProfile(
        points: [TerrainPoint(meters: 250, height: 0.6)],
      );
      expect(terrainHeightAt(single, 0), 0.6);
      expect(terrainHeightAt(single, 250), 0.6);
      expect(terrainHeightAt(single, 9999), 0.6);
    });

    test('an empty profile is flat at 0 everywhere — the fallback shape '
        '`terrain_layer.dart` never actually produces, but the function '
        'stays total rather than throwing', () {
      const empty = TerrainProfile(points: []);
      expect(terrainHeightAt(empty, 0), 0.0);
      expect(terrainHeightAt(empty, 123), 0.0);
    });

    test('consecutive points at the same meters do not divide by zero', () {
      const degenerate = TerrainProfile(
        points: [
          TerrainPoint(meters: 100, height: 0.2),
          TerrainPoint(meters: 100, height: 0.8),
          TerrainPoint(meters: 200, height: 0.0),
        ],
      );
      // Both zero-width segments resolve without throwing; the exact value
      // picked between two coincident points isn't load-bearing.
      expect(() => terrainHeightAt(degenerate, 100), returnsNormally);
    });
  });
}
