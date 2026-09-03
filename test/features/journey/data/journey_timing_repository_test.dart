import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:thereandback/features/journey/data/journey_timing_repository.dart';
import 'package:thereandback/features/journey/domain/fictional_time.dart';

String _json(List<Map<String, Object?>> segments) {
  return jsonEncode({'segments': segments});
}

Map<String, Object?> _segment({
  String id = 's',
  required int fromMeters,
  required int toMeters,
  double departureHour = 6,
  // Small enough to stay under the pace-safety cap for every fixture's
  // segment size below (as low as 900 m) without every test needing to
  // pick its own — tests that specifically exercise the cap override this.
  double durationDays = 0.05,
}) {
  return {
    'id': id,
    'fromMeters': fromMeters,
    'toMeters': toMeters,
    'departureHour': departureHour,
    'durationDays': durationDays,
  };
}

void main() {
  group('parseJourneySegmentTimings', () {
    test('parses a well-formed segment list', () {
      final segments = parseJourneySegmentTimings(
        _json([
          _segment(id: 'a', fromMeters: 0, toMeters: 1000),
          _segment(id: 'b', fromMeters: 1000, toMeters: 2000),
        ]),
      );

      expect(segments, hasLength(2));
      expect(segments.first.id, 'a');
      expect(segments.last.toMeters, 2000);
    });

    test('rejects an empty "segments" list', () {
      expect(
        () => parseJourneySegmentTimings(_json([])),
        throwsFormatException,
      );
    });

    test('rejects a first segment that does not start at 0 m', () {
      expect(
        () => parseJourneySegmentTimings(
          _json([_segment(fromMeters: 100, toMeters: 1000)]),
        ),
        throwsFormatException,
      );
    });

    test('rejects a gap between segments', () {
      expect(
        () => parseJourneySegmentTimings(
          _json([
            _segment(id: 'a', fromMeters: 0, toMeters: 1000),
            _segment(id: 'b', fromMeters: 1500, toMeters: 2000),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects an overlap between segments', () {
      expect(
        () => parseJourneySegmentTimings(
          _json([
            _segment(id: 'a', fromMeters: 0, toMeters: 1000),
            _segment(id: 'b', fromMeters: 500, toMeters: 2000),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects a departureHour outside [0, 24)', () {
      expect(
        () => parseJourneySegmentTimings(
          _json([_segment(fromMeters: 0, toMeters: 1000, departureHour: 24)]),
        ),
        throwsFormatException,
      );
      expect(
        () => parseJourneySegmentTimings(
          _json([_segment(fromMeters: 0, toMeters: 1000, departureHour: -1)]),
        ),
        throwsFormatException,
      );
    });

    test('rejects a negative durationDays', () {
      expect(
        () => parseJourneySegmentTimings(
          _json([_segment(fromMeters: 0, toMeters: 1000, durationDays: -0.1)]),
        ),
        throwsFormatException,
      );
    });

    test('rejects durationDays above the pace-safety cap '
        '(1 fictional day per ${minMetersPerFictionalDay ~/ 1000} km)', () {
      // 10 000 m segment -> cap is exactly 1 day; 1.01 exceeds it.
      expect(
        () => parseJourneySegmentTimings(
          _json([_segment(fromMeters: 0, toMeters: 10000, durationDays: 1.01)]),
        ),
        throwsFormatException,
      );
    });

    test('accepts durationDays exactly at the pace-safety cap', () {
      final segments = parseJourneySegmentTimings(
        _json([_segment(fromMeters: 0, toMeters: 10000, durationDays: 1)]),
      );
      expect(segments.single.durationDays, 1);
    });
  });

  group('the shipped Odyssey locations.json', () {
    late List<JourneySegmentTiming> segments;

    setUpAll(() {
      segments = parseJourneySegmentTimings(
        File(journeyTimingAssetPath('odyssey-ithaca')).readAsStringSync(),
      );
    });

    test('covers the whole route with 19 contiguous segments', () {
      expect(segments, hasLength(19));
      expect(segments.first.fromMeters, 0);
      expect(segments.last.toMeters, 2850000);
    });

    test('every segment respects the pace-safety cap', () {
      for (final segment in segments) {
        final cap =
            (segment.toMeters - segment.fromMeters) / minMetersPerFictionalDay;
        expect(
          segment.durationDays,
          lessThanOrEqualTo(cap),
          reason: segment.id,
        );
      }
    });

    test('Troy departs at dawn, per the request\'s own example', () {
      expect(segments.first.id, 'troy-departure');
      expect(segments.first.departureHour, 6);
    });
  });
}
