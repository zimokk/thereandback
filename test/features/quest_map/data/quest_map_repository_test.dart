import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:thereandback/features/journey/data/journey_catalog.dart';
import 'package:thereandback/features/quest_map/data/quest_map_repository.dart';
import 'package:thereandback/features/quest_map/domain/route_mapping.dart';

String _json(Map<String, Object?> overrides) {
  return jsonEncode({
    'journeyId': 'test-quest',
    'totalMeters': 1000,
    'image': {
      'asset': 'assets/journeys/test-quest/map.webp',
      'width': 1024,
      'height': 1536,
    },
    'path': [
      {'x': 0.1, 'y': 0.2, 'meters': 0},
      {'x': 0.5, 'y': 0.6, 'meters': 400},
      {'x': 0.9, 'y': 0.8, 'meters': 1000},
    ],
    'landmarks': [
      {'id': 'b', 'name': 'B', 'x': 0.9, 'y': 0.8, 'meters': 1000},
      {'id': 'a', 'name': 'A', 'x': 0.1, 'y': 0.2, 'meters': 0},
    ],
    ...overrides,
  });
}

void main() {
  group('parseQuestMap', () {
    test('parses a well-formed map.json', () {
      final map = parseQuestMap(_json({}));

      expect(map.journeyId, 'test-quest');
      expect(map.imageAsset, 'assets/journeys/test-quest/map.webp');
      expect(map.imageWidth, 1024);
      expect(map.imageHeight, 1536);
      expect(map.totalMeters, 1000);
      expect(map.polyline.vertices, hasLength(3));
      expect(map.polyline.vertices.first.cumulativeMeters, 0);
      expect(map.polyline.vertices.last.cumulativeMeters, 1000);
    });

    test('sorts landmarks by distance along the route, whatever the file '
        'order', () {
      final map = parseQuestMap(_json({}));

      expect(map.landmarks.map((l) => l.id), ['a', 'b']);
    });

    test('rejects a path whose meters go backwards', () {
      expect(
        () => parseQuestMap(
          _json({
            'path': [
              {'x': 0.1, 'y': 0.2, 'meters': 0},
              {'x': 0.5, 'y': 0.6, 'meters': 500},
              {'x': 0.9, 'y': 0.8, 'meters': 400},
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects a path that does not start at 0 m', () {
      expect(
        () => parseQuestMap(
          _json({
            'path': [
              {'x': 0.1, 'y': 0.2, 'meters': 50},
              {'x': 0.9, 'y': 0.8, 'meters': 1000},
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects a path that does not end at totalMeters', () {
      expect(
        () => parseQuestMap(
          _json({
            'path': [
              {'x': 0.1, 'y': 0.2, 'meters': 0},
              {'x': 0.9, 'y': 0.8, 'meters': 900},
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects coordinates outside the normalized 0..1 space', () {
      expect(
        () => parseQuestMap(
          _json({
            'path': [
              {'x': 0.1, 'y': 0.2, 'meters': 0},
              {'x': 1.4, 'y': 0.8, 'meters': 1000},
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects a landmark placed off the route', () {
      expect(
        () => parseQuestMap(
          _json({
            'landmarks': [
              {'id': 'a', 'name': 'A', 'x': 0.1, 'y': 0.2, 'meters': 4000},
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects a path with fewer than two vertices', () {
      expect(
        () => parseQuestMap(
          _json({
            'path': [
              {'x': 0.1, 'y': 0.2, 'meters': 0},
            ],
          }),
        ),
        throwsFormatException,
      );
    });
  });

  group("the shipped Odyssey map.json", () {
    late QuestMap map;

    setUpAll(() {
      map = parseQuestMap(
        File(questMapAssetPath('odyssey-ithaca')).readAsStringSync(),
      );
    });

    test('describes the quest the catalog ships', () {
      final journey = findJourney('odyssey-ithaca')!;

      expect(map.journeyId, journey.id);
      // A map traced against a different route length would put the
      // traveler on the wrong part of the line — this is the check that
      // catches the catalog and the drawing drifting apart.
      expect(map.totalMeters, journey.totalMeters);
      expect(map.polyline.vertices.last.cumulativeMeters, journey.totalMeters);
    });

    test('runs from Troy to Ithaca, with both ends on the drawn line', () {
      expect(map.landmarks.first.id, 'troy');
      expect(map.landmarks.first.meters, 0);
      expect(map.landmarks.last.id, 'ithaca');
      expect(map.landmarks.last.meters, map.totalMeters);

      final start = metersToPoint(map.polyline, 0);
      final end = metersToPoint(map.polyline, map.totalMeters);
      expect(start.x, closeTo(map.landmarks.first.x, 0.06));
      expect(start.y, closeTo(map.landmarks.first.y, 0.06));
      expect(end.x, closeTo(map.landmarks.last.x, 0.06));
      expect(end.y, closeTo(map.landmarks.last.y, 0.06));
    });

    test('every landmark sits within a hair of the drawn line', () {
      for (final landmark in map.landmarks) {
        final onLine = metersToPoint(map.polyline, landmark.meters);
        // Landmarks are illustrated beside the path, not on it — the
        // Sirens' rock sits a good way above the line it belongs to — so
        // this is a sanity bound (10% of the image), not an exact match:
        // it catches a hotspot attached to the wrong stretch of the route.
        expect(
          (onLine.x - landmark.x).abs(),
          lessThan(0.1),
          reason: '${landmark.id} x',
        );
        expect(
          (onLine.y - landmark.y).abs(),
          lessThan(0.1),
          reason: '${landmark.id} y',
        );
      }
    });

    test('points at the illustration the coordinates were traced from', () {
      expect(map.imageAsset, 'assets/journeys/odyssey-ithaca/map.webp');
      expect(map.imageWidth / map.imageHeight, closeTo(2 / 3, 0.001));
    });
  });
}
