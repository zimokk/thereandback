import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/ground_heightmap.dart';
import 'package:thereandback/features/journey/domain/scene_ground.dart';

void main() {
  // Two tile-scale reliefs, deliberately opposite, so a blend between them
  // is unmistakable in an assertion.
  const from = GroundHeightmap(samples: [1.0, 1.0], tileMeters: 500);
  const to = GroundHeightmap(samples: [-1.0, -1.0], tileMeters: 500);

  group('blendedGroundHeight (§6.1 — the art\'s own relief)', () {
    test('with no blend it is simply the current biome\'s relief', () {
      expect(blendedGroundHeight(meters: 0, from: from), 1.0);
      expect(blendedGroundHeight(meters: 250, from: to), -1.0);
    });

    test('flat where the biome has no art — a quest still gets its authored '
        'profile, applied separately', () {
      expect(blendedGroundHeight(meters: 1234), 0.0);
    });

    test('interpolates between two biomes across the transition', () {
      double at(double blend) =>
          blendedGroundHeight(meters: 0, from: from, to: to, blend: blend);

      expect(at(0), 1.0);
      expect(at(1), -1.0);
      expect(at(0.5), closeTo(0.0, 1e-12));
      // Monotonic across the window: the line never doubles back mid-fade.
      expect(at(0.25), greaterThan(at(0.75)));
    });

    test('blend outside 0..1 clamps instead of overshooting past either '
        'biome\'s real relief', () {
      expect(
        blendedGroundHeight(meters: 0, from: from, to: to, blend: -3),
        1.0,
      );
      expect(
        blendedGroundHeight(meters: 0, from: from, to: to, blend: 9),
        -1.0,
      );
    });

    test('a blend with no next biome stays on the current one', () {
      expect(blendedGroundHeight(meters: 0, from: from, blend: 1), 1.0);
    });

    test('fading into a biome whose art is missing fades towards flat, not '
        'to a jump', () {
      expect(
        blendedGroundHeight(meters: 0, from: from, to: null, blend: 0.5),
        1.0,
      );
    });
  });

  group('easeGroundBlend', () {
    test('is a smoothstep: pinned at both ends, halfway at the midpoint', () {
      expect(easeGroundBlend(0), 0.0);
      expect(easeGroundBlend(1), 1.0);
      expect(easeGroundBlend(0.5), closeTo(0.5, 1e-12));
    });

    test('has zero slope at both ends, so a transition starts and ends '
        'without a kink in the ground line', () {
      expect(easeGroundBlend(0.001), lessThan(0.001));
      expect(easeGroundBlend(0.999), greaterThan(0.999));
    });
  });
}
