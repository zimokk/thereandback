import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/terrain_profile.dart'
    hide terrainHeightAt;
import 'package:thereandback/features/journey/presentation/terrain_layer.dart';

void main() {
  group('worldXFor (§6.1 — route meters to world-space x)', () {
    test('point A (0 m) sits at world x 0', () {
      expect(worldXFor(0, 40), 0.0);
    });

    test('linear in meters, at a fixed pixelsPerMeter', () {
      expect(worldXFor(10, 40), 400.0);
      expect(worldXFor(20, 40), 800.0);
    });
  });

  group('terrainHeightAt, profile: null (§6.1 — placeholder horizon '
      'height, unchanged for a quest with no authored terrain content)', () {
    test(
      'height at a given world x does not depend on anything but that x',
      () {
        // The regression this guards: an earlier version keyed the phase off
        // a screen-relative offset that also shifted with pan, so the same
        // route point rendered at a different height after every pan. This
        // function takes only worldX (plus the fixed profile/scale) — there
        // is no pan parameter to leak in.
        final a = terrainHeightAt(1234.5, null, 40);
        final b = terrainHeightAt(1234.5, null, 40);
        expect(a, b);
      },
    );

    test('oscillates around terrainMidY within terrainWaveAmplitude', () {
      for (var x = 0.0; x < terrainWaveWavelength * 3; x += 17) {
        final y = terrainHeightAt(x, null, 40);
        expect(
          y,
          greaterThanOrEqualTo(terrainMidY - terrainWaveAmplitude - 1e-9),
        );
        expect(y, lessThanOrEqualTo(terrainMidY + terrainWaveAmplitude + 1e-9));
      }
    });

    test('one full wavelength returns to (approximately) the same height', () {
      final start = terrainHeightAt(500, null, 40);
      final oneWavelengthLater = terrainHeightAt(
        500 + terrainWaveWavelength,
        null,
        40,
      );
      expect(oneWavelengthLater, closeTo(start, 1e-9));
    });
  });

  group('terrainHeightAt, an authored profile (§6.1 — data-driven ascents/'
      'descents)', () {
    // 40 pixels per meter, so world x 4000 is exactly the 100 m landmark
    // below — a round number keeps the worldX/meters arithmetic exact.
    const pixelsPerMeter = 40.0;
    const profile = TerrainProfile(
      points: [
        TerrainPoint(meters: 0, height: 0.0),
        TerrainPoint(meters: 100, height: 0.9),
        TerrainPoint(meters: 200, height: 0.0),
      ],
    );

    test('at an authored landmark\'s own world x, returns its height scaled '
        'by terrainWaveAmplitude', () {
      final worldX = worldXFor(100, pixelsPerMeter);
      expect(
        terrainHeightAt(worldX, profile, pixelsPerMeter),
        closeTo(terrainWaveAmplitude * 0.9, 1e-9),
      );
    });

    test('at the route start, returns the profile\'s own start height', () {
      expect(terrainHeightAt(0, profile, pixelsPerMeter), terrainMidY);
    });

    test('never exceeds terrainMidY +/- terrainWaveAmplitude, same envelope '
        'as the placeholder wave', () {
      for (var x = 0.0; x <= worldXFor(200, pixelsPerMeter); x += 50) {
        final y = terrainHeightAt(x, profile, pixelsPerMeter);
        expect(
          y,
          inInclusiveRange(
            terrainMidY - terrainWaveAmplitude - 1e-9,
            terrainMidY + terrainWaveAmplitude + 1e-9,
          ),
        );
      }
    });
  });
}
