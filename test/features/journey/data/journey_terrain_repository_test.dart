import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:thereandback/features/journey/data/journey_terrain_repository.dart';
import 'package:thereandback/features/journey/data/journey_timing_repository.dart';
import 'package:thereandback/features/journey/domain/scene_prop_anchor.dart';

String _json(List<Map<String, Object?>> landmarks, {int totalMeters = 1000}) {
  return jsonEncode({
    'journey': {'totalMeters': totalMeters},
    'landmarks': landmarks,
  });
}

Map<String, Object?> _landmark({
  String id = 'a',
  required int meters,
  double? terrainHeight,
  Map<String, Object?>? prop,
}) {
  return {
    'id': id,
    'meters': meters,
    'terrainHeight': ?terrainHeight,
    'prop': ?prop,
  };
}

void main() {
  group('parseJourneyTerrainContent', () {
    test('a landmark with neither field produces no terrain point and no '
        'prop, just the synthetic route endpoints', () {
      final content = parseJourneyTerrainContent(
        _json([_landmark(meters: 500)]),
      );
      expect(content.props, isEmpty);
      expect(content.profile.points.map((p) => p.meters), [0, 1000]);
      expect(content.profile.points.map((p) => p.height), [0.0, 0.0]);
    });

    test('an authored terrainHeight becomes a control point between the '
        'synthetic endpoints', () {
      final content = parseJourneyTerrainContent(
        _json([_landmark(meters: 400, terrainHeight: 0.9)]),
      );
      expect(content.profile.points.map((p) => p.meters), [0, 400, 1000]);
      expect(content.profile.points.map((p) => p.height), [0.0, 0.9, 0.0]);
    });

    test('an authored point exactly at 0 or totalMeters replaces the '
        'synthetic endpoint rather than duplicating it', () {
      final content = parseJourneyTerrainContent(
        _json([
          _landmark(id: 'start', meters: 0, terrainHeight: 0.2),
          _landmark(id: 'end', meters: 1000, terrainHeight: 0.4),
        ]),
      );
      expect(content.profile.points.map((p) => p.meters), [0, 1000]);
      expect(content.profile.points.map((p) => p.height), [0.2, 0.4]);
    });

    test('a landmark with a prop becomes a ScenePropAnchor sharing its own '
        'meters', () {
      final content = parseJourneyTerrainContent(
        _json([
          _landmark(
            id: 'cyclops-cave',
            meters: 391875,
            terrainHeight: 0.9,
            prop: {'asset': 'cyclops_silhouette', 'layer': 'behind'},
          ),
        ], totalMeters: 2850000),
      );
      expect(content.props, [
        const ScenePropAnchor(
          id: 'cyclops-cave',
          meters: 391875,
          asset: 'cyclops_silhouette',
          layer: ScenePropLayer.behind,
        ),
      ]);
      // The same meters drives the terrain control point too — one shared
      // number, not two independently authored ones.
      expect(content.profile.points.map((p) => p.meters), contains(391875));
    });

    test('rejects landmark meters outside [0, totalMeters]', () {
      expect(
        () => parseJourneyTerrainContent(_json([_landmark(meters: 1500)])),
        throwsFormatException,
      );
      expect(
        () => parseJourneyTerrainContent(_json([_landmark(meters: -1)])),
        throwsFormatException,
      );
    });

    test('rejects a non-numeric terrainHeight', () {
      final source = jsonEncode({
        'journey': {'totalMeters': 1000},
        'landmarks': [
          {'id': 'a', 'meters': 100, 'terrainHeight': 'high'},
        ],
      });
      expect(() => parseJourneyTerrainContent(source), throwsFormatException);
    });

    test('rejects decreasing meters among authored terrain points', () {
      expect(
        () => parseJourneyTerrainContent(
          _json([
            _landmark(id: 'a', meters: 500, terrainHeight: 0.5),
            _landmark(id: 'b', meters: 200, terrainHeight: 0.2),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects an empty prop asset', () {
      expect(
        () => parseJourneyTerrainContent(
          _json([
            _landmark(meters: 100, prop: {'asset': '', 'layer': 'front'}),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects an unknown prop layer', () {
      expect(
        () => parseJourneyTerrainContent(
          _json([
            _landmark(meters: 100, prop: {'asset': 'x', 'layer': 'middle'}),
          ]),
        ),
        throwsFormatException,
      );
    });
  });

  group('the shipped Odyssey locations.json', () {
    test('parses today without any authored terrain content — a flat, '
        'two-endpoint profile and no props, since none is authored yet', () {
      final content = parseJourneyTerrainContent(
        File(journeyTimingAssetPath('odyssey-ithaca')).readAsStringSync(),
      );
      expect(content.profile.points.map((p) => p.meters), [0, 2850000]);
      expect(content.profile.points.map((p) => p.height), [0.0, 0.0]);
      expect(content.props, isEmpty);
    });
  });
}
