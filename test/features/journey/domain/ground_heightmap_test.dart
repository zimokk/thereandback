import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/ground_heightmap.dart';

void main() {
  // Four columns of a 1 000 m-wide tile: flat, up, flat, down — so every
  // sample is 250 m apart and the tile's last sample interpolates back into
  // its first.
  const map = GroundHeightmap(samples: [0.0, 1.0, 0.0, -1.0], tileMeters: 1000);

  group('groundHeightAt (§6.1 — relief read off the biome art)', () {
    test('lands exactly on a sample at that sample\'s own position', () {
      expect(groundHeightAt(map, 0), 0.0);
      expect(groundHeightAt(map, 250), 1.0);
      expect(groundHeightAt(map, 500), 0.0);
      expect(groundHeightAt(map, 750), -1.0);
    });

    test('interpolates linearly between two samples', () {
      expect(groundHeightAt(map, 125), closeTo(0.5, 1e-12));
      expect(groundHeightAt(map, 625), closeTo(-0.5, 1e-12));
    });

    test('repeats every tileMeters — a biome longer than its tile keeps '
        'walking on the same drawn hills', () {
      expect(groundHeightAt(map, 1000), closeTo(groundHeightAt(map, 0), 1e-12));
      expect(
        groundHeightAt(map, 7 * 1000 + 250),
        closeTo(groundHeightAt(map, 250), 1e-12),
      );
    });

    test('the seam between two repetitions is as smooth as any other pair '
        'of samples — the last sample interpolates into the first', () {
      // 875 m is halfway between the last sample (-1.0 at 750 m) and the
      // first sample of the next repetition (0.0 at 1000 m).
      expect(groundHeightAt(map, 875), closeTo(-0.5, 1e-12));
      // Approaching the seam from either side converges on the same value.
      expect(
        groundHeightAt(map, 1000 - 0.001),
        closeTo(groundHeightAt(map, 0.001), 1e-4),
      );
    });

    test('negative meters wrap like any other position', () {
      expect(groundHeightAt(map, -1000), closeTo(0.0, 1e-12));
      expect(groundHeightAt(map, -750), closeTo(1.0, 1e-12));
    });

    test('degenerate maps are flat, not an error', () {
      expect(
        groundHeightAt(const GroundHeightmap(samples: [], tileMeters: 500), 42),
        0.0,
      );
      expect(
        groundHeightAt(
          const GroundHeightmap(samples: [0.3], tileMeters: 500),
          42,
        ),
        0.3,
      );
      expect(
        groundHeightAt(
          const GroundHeightmap(samples: [0.3, 0.9], tileMeters: 0),
          42,
        ),
        0.3,
      );
    });
  });
}
