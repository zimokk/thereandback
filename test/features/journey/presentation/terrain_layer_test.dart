import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/ground_heightmap.dart';
import 'package:thereandback/features/journey/domain/segment_biomes.dart';
import 'package:thereandback/features/journey/domain/terrain_profile.dart'
    hide terrainHeightAt;
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';
import 'package:thereandback/features/journey/presentation/terrain_layer.dart';

/// A controller at a known scale. `pixelsPerMeter` is derived from
/// `sceneWidth` and the quest's own meters-per-screen, so the scene width is
/// what a test sets to fix it: 40 px/m here, as the old signature's explicit
/// parameter used to.
JourneySceneController _controller({
  TerrainProfile? profile,
  double pixelsPerMeter = 40,
  double sceneHeight = 800,
  List<BiomeSpan> biomes = const [],
  Map<String, GroundHeightmap> ground = const {},
}) {
  final controller = JourneySceneController()
    ..journeyId = 'test-quest'
    ..sceneWidth = pixelsPerMeter * 20000
    ..sceneHeight = sceneHeight
    ..terrainProfile = profile
    ..biomes = biomes;
  controller.biomeArt = {
    for (final entry in ground.entries)
      entry.key: (biome: entry.key, layers: const {}, ground: entry.value),
  };
  return controller;
}

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
        final a = terrainHeightAt(1234.5, _controller());
        final b = terrainHeightAt(1234.5, _controller());
        expect(a, b);
      },
    );

    test('oscillates around terrainMidY within terrainWaveAmplitude', () {
      for (var x = 0.0; x < terrainWaveWavelength * 3; x += 17) {
        final y = terrainHeightAt(x, _controller());
        expect(
          y,
          greaterThanOrEqualTo(terrainMidY - terrainWaveAmplitude - 1e-9),
        );
        expect(y, lessThanOrEqualTo(terrainMidY + terrainWaveAmplitude + 1e-9));
      }
    });

    test('one full wavelength returns to (approximately) the same height', () {
      final start = terrainHeightAt(500, _controller());
      final oneWavelengthLater = terrainHeightAt(
        500 + terrainWaveWavelength,
        _controller(),
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
        'by macroTerrainAmplitude — and upwards, since world y grows down', () {
      final worldX = worldXFor(100, pixelsPerMeter);
      expect(
        terrainHeightAt(worldX, _controller(profile: profile)),
        closeTo(terrainMidY - macroTerrainAmplitude * 0.9, 1e-9),
      );
    });

    test('at the route start, returns the profile\'s own start height', () {
      expect(terrainHeightAt(0, _controller(profile: profile)), terrainMidY);
    });

    test('never exceeds terrainMidY +/- macroTerrainAmplitude', () {
      for (var x = 0.0; x <= worldXFor(200, pixelsPerMeter); x += 50) {
        final y = terrainHeightAt(x, _controller(profile: profile));
        expect(
          y,
          inInclusiveRange(
            terrainMidY - macroTerrainAmplitude - 1e-9,
            terrainMidY + macroTerrainAmplitude + 1e-9,
          ),
        );
      }
    });
  });

  group('terrainHeightAt, loaded biome art (§6.1 — the traveler walks on '
      'the hills the art draws)', () {
    const pixelsPerMeter = 40.0;
    const sceneHeight = 800.0;
    const biomes = [
      BiomeSpan(segmentId: 'a', biome: 'hills', fromMeters: 0, toMeters: 20000),
    ];

    test('the art\'s relief moves the line, scaled by how tall the tile is '
        'drawn', () {
      // A tile whose ground is drawn at a constant +0.5 of its own height.
      const ground = {
        'hills': GroundHeightmap(samples: [0.5, 0.5], tileMeters: 1000),
      };
      final y = terrainHeightAt(
        0,
        _controller(
          pixelsPerMeter: pixelsPerMeter,
          sceneHeight: sceneHeight,
          biomes: biomes,
          ground: ground,
        ),
      );
      expect(
        y,
        closeTo(
          terrainMidY - sceneHeight * groundArtTileHeightFactor / 2 * 0.5,
          1e-9,
        ),
      );
    });

    test('art and an authored profile add up — the segment-long climb '
        'carries the drawn hills with it', () {
      const ground = {
        'hills': GroundHeightmap(samples: [0.5, 0.5], tileMeters: 1000),
      };
      final artOnly = terrainHeightAt(
        0,
        _controller(sceneHeight: sceneHeight, biomes: biomes, ground: ground),
      );
      final withClimb = terrainHeightAt(
        0,
        _controller(
          profile: const TerrainProfile(
            points: [
              TerrainPoint(meters: 0, height: 1.0),
              TerrainPoint(meters: 20000, height: 1.0),
            ],
          ),
          sceneHeight: sceneHeight,
          biomes: biomes,
          ground: ground,
        ),
      );
      expect(withClimb, closeTo(artOnly - macroTerrainAmplitude, 1e-9));
    });

    test('a biome whose art has not loaded falls back to the placeholder '
        'wave, so art can land one biome at a time', () {
      expect(
        terrainHeightAt(500, _controller(biomes: biomes)),
        terrainHeightAt(500, _controller()),
      );
    });
  });
}
