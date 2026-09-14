import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/segment_biomes.dart';

void main() {
  // Three contiguous segments, the last two sharing a biome — the shape
  // `locations.json` produces, including the case where two consecutive
  // segments draw the same art.
  const spans = [
    BiomeSpan(
      segmentId: 'a',
      biome: 'pine_forest',
      fromMeters: 0,
      toMeters: 20000,
    ),
    BiomeSpan(
      segmentId: 'b',
      biome: 'mountain_pass',
      fromMeters: 20000,
      toMeters: 40000,
    ),
    BiomeSpan(
      segmentId: 'c',
      biome: 'mountain_pass',
      fromMeters: 40000,
      toMeters: 60000,
    ),
  ];

  group('biomeAt', () {
    test('finds the span covering a position', () {
      expect(biomeAt(spans, 0)?.segmentId, 'a');
      expect(biomeAt(spans, 19999)?.segmentId, 'a');
      expect(biomeAt(spans, 20000)?.segmentId, 'b');
      expect(biomeAt(spans, 45000)?.segmentId, 'c');
    });

    test('clamps at both ends rather than returning null mid-route', () {
      expect(biomeAt(spans, -500)?.segmentId, 'a');
      expect(biomeAt(spans, 60000)?.segmentId, 'c');
      expect(biomeAt(spans, 999999)?.segmentId, 'c');
    });

    test('an empty list has no biome', () {
      expect(biomeAt(const [], 100), isNull);
    });
  });

  group('biomeBlendAt (§6.1 — one biome crossing into the next)', () {
    test('mid-segment there is nothing to cross into', () {
      final blend = biomeBlendAt(spans, 5000);
      expect(blend?.current.segmentId, 'a');
      expect(blend?.next, isNull);
      expect(blend?.blend, 0);
    });

    test('crosses into the next biome over the transition window', () {
      // Window is the full 2 000 m here: both spans are 20 km long.
      expect(biomeBlendAt(spans, 20000 - biomeTransitionMeters)?.next, isNull);
      final quarter = biomeBlendAt(spans, 20000 - biomeTransitionMeters + 500);
      expect(quarter?.next?.segmentId, 'b');
      expect(quarter?.blend, closeTo(0.25, 1e-12));
      final end = biomeBlendAt(spans, 19999);
      expect(end?.blend, closeTo(1.0, 1e-3));
    });

    test('two consecutive segments sharing a biome never cross-fade — they '
        'already draw the same art', () {
      final blend = biomeBlendAt(spans, 39999);
      expect(blend?.current.segmentId, 'b');
      expect(blend?.next, isNull);
    });

    test('the last segment has nothing to cross into', () {
      expect(biomeBlendAt(spans, 59999)?.next, isNull);
    });

    test('the window shrinks to half of the shorter neighbour, so a short '
        'segment is never fading in and out at once', () {
      const short = [
        BiomeSpan(
          segmentId: 'a',
          biome: 'marsh_ruins',
          fromMeters: 0,
          toMeters: 1000,
        ),
        BiomeSpan(
          segmentId: 'b',
          biome: 'rocky_coast',
          fromMeters: 1000,
          toMeters: 2000,
        ),
      ];
      // Half of 1 000 m is 500 m, well under the 2 000 m default.
      expect(biomeBlendAt(short, 500)?.next, isNull);
      expect(biomeBlendAt(short, 750)?.blend, closeTo(0.5, 1e-12));
    });

    test('an empty list has no blend', () {
      expect(biomeBlendAt(const [], 100), isNull);
    });
  });
}
