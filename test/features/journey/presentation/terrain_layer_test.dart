import 'package:test/test.dart';
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

  group('terrainHeightAt (§6.1 — placeholder horizon height)', () {
    test(
      'height at a given world x does not depend on anything but that x',
      () {
        // The regression this guards: an earlier version keyed the phase off
        // a screen-relative offset that also shifted with pan, so the same
        // route point rendered at a different height after every pan. This
        // function takes only worldX — there is no pan parameter to leak in.
        final a = terrainHeightAt(1234.5);
        final b = terrainHeightAt(1234.5);
        expect(a, b);
      },
    );

    test('oscillates around terrainMidY within terrainWaveAmplitude', () {
      for (var x = 0.0; x < terrainWaveWavelength * 3; x += 17) {
        final y = terrainHeightAt(x);
        expect(
          y,
          greaterThanOrEqualTo(terrainMidY - terrainWaveAmplitude - 1e-9),
        );
        expect(y, lessThanOrEqualTo(terrainMidY + terrainWaveAmplitude + 1e-9));
      }
    });

    test('one full wavelength returns to (approximately) the same height', () {
      final start = terrainHeightAt(500);
      final oneWavelengthLater = terrainHeightAt(500 + terrainWaveWavelength);
      expect(oneWavelengthLater, closeTo(start, 1e-9));
    });
  });
}
