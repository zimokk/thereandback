import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/journey/data/ground_heightmap_extractor.dart';
import 'package:thereandback/features/journey/data/journey_terrain_repository.dart';
import 'package:thereandback/features/journey/data/journey_timing_repository.dart';
import 'package:thereandback/features/journey/data/scene_art_catalog.dart';
import 'package:thereandback/features/journey/domain/ground_heightmap.dart';
import 'package:thereandback/features/journey/presentation/terrain_layer.dart';

/// Every biome each catalog quest actually uses, read from its own content
/// file — so adding a segment with a new biome and forgetting to draw it
/// fails here rather than showing up as a bare stretch of route.
Map<String, List<String>> _biomesByQuest() {
  final result = <String, List<String>>{};
  for (final quest in const ['odyssey-ithaca', 'tower-of-lights']) {
    final content = parseJourneyTerrainContent(
      File(journeyTimingAssetPath(quest)).readAsStringSync(),
    );
    result[quest] = content.biomes
        .map((span) => span.biome)
        .toSet()
        .toList(growable: false);
  }
  return result;
}

Future<GroundHeightmap> _groundOf(String path) async {
  final image = await decodeImageFromList(File(path).readAsBytesSync());
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return extractGroundHeightmap(
    rgba: pixels!,
    width: image.width,
    height: image.height,
    tileMeters: 20000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final biomesByQuest = _biomesByQuest();

  group('the shipped biome art (§6.1, §9.1)', () {
    test('every biome both catalog quests use ships all four layers', () {
      for (final entry in biomesByQuest.entries) {
        for (final biome in entry.value) {
          for (final layer in SceneArtLayer.values) {
            final path = sceneArtAssetPath(entry.key, biome, layer);
            expect(
              File(path).existsSync(),
              isTrue,
              reason:
                  '$path is missing — regenerate with '
                  'tools/generate_scene_art.py',
            );
          }
        }
      }
    });

    test(
      'every ground tile hangs from a mean row in its upper half, so the '
      'fill below it still covers the screen when a climb lifts the line',
      () async {
        for (final entry in biomesByQuest.entries) {
          for (final biome in entry.value) {
            final ground = await _groundOf(
              sceneArtAssetPath(entry.key, biome, SceneArtLayer.ground),
            );
            expect(
              ground.centerFraction,
              lessThan(0.5),
              reason: '$biome draws its ground too low on its tile',
            );
          }
        }
      },
    );

    test('no ground tile draws relief steep enough to carry the traveler off '
        'the screen', () async {
      // Worst case: the drawn relief at full stretch plus the authored
      // profile at full stretch, against half a (short) screen.
      const shortestSceneHeight = 560.0;
      for (final entry in biomesByQuest.entries) {
        for (final biome in entry.value) {
          final ground = await _groundOf(
            sceneArtAssetPath(entry.key, biome, SceneArtLayer.ground),
          );
          final peak = ground.samples
              .map((sample) => sample.abs())
              .reduce((a, b) => a > b ? a : b);
          final pixels =
              peak * shortestSceneHeight * groundArtTileHeightFactor / 2 +
              macroTerrainAmplitude;
          expect(
            pixels,
            lessThan(shortestSceneHeight / 2),
            reason: '$biome would put the traveler off screen',
          );
        }
      }
    });

    test('ground tiles differ in how rough they are — the art, not a shared '
        'constant, is what decides the shape of the ground', () async {
      final flat = await _groundOf(
        sceneArtAssetPath(
          'tower-of-lights',
          'open_fields',
          SceneArtLayer.ground,
        ),
      );
      final rough = await _groundOf(
        sceneArtAssetPath(
          'tower-of-lights',
          'mountain_pass',
          SceneArtLayer.ground,
        ),
      );
      double peakOf(GroundHeightmap map) => map.samples
          .map((sample) => sample.abs())
          .reduce((a, b) => a > b ? a : b);
      expect(peakOf(flat), lessThan(peakOf(rough)));
    });

    test('ground tiles repeat without a visible seam — the joint is no '
        'sharper than the steepest slope already inside the tile', () async {
      for (final entry in biomesByQuest.entries) {
        for (final biome in entry.value) {
          final ground = await _groundOf(
            sceneArtAssetPath(entry.key, biome, SceneArtLayer.ground),
          );
          final samples = ground.samples;
          final seam = (samples.first - samples.last).abs();
          final interior = [
            for (var i = 1; i < samples.length; i++)
              (samples[i] - samples[i - 1]).abs(),
          ].reduce((a, b) => a > b ? a : b);
          expect(
            seam,
            lessThanOrEqualTo(interior + 1e-9),
            reason: '$biome steps at the seam where its tile repeats',
          );
        }
      }
    });
  });
}
