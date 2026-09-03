import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/fictional_time.dart';

void main() {
  group('skyPhaseForHour / skyPhaseFor (§6.1 — sky by time of day)', () {
    test('deep night', () {
      expect(skyPhaseForHour(2), SkyPhase.night);
      expect(skyPhaseForHour(23), SkyPhase.night);
    });
    test('dawn', () {
      expect(skyPhaseForHour(6), SkyPhase.dawn);
    });
    test('day', () {
      expect(skyPhaseForHour(12), SkyPhase.day);
    });
    test('dusk', () {
      expect(skyPhaseForHour(19), SkyPhase.dusk);
    });
    test('boundaries are covered by exactly one phase each, no gaps', () {
      for (var hour = 0; hour < 24; hour++) {
        expect(SkyPhase.values, contains(skyPhaseForHour(hour.toDouble())));
      }
    });
    test('wraps hours past 24', () {
      expect(skyPhaseForHour(30), skyPhaseForHour(6)); // 30 % 24 == 6, dawn
    });

    test('skyPhaseFor derives the same bands from a real DateTime', () {
      expect(skyPhaseFor(DateTime(2026, 1, 1, 2, 0)), SkyPhase.night);
      expect(skyPhaseFor(DateTime(2026, 1, 1, 6, 0)), SkyPhase.dawn);
      expect(skyPhaseFor(DateTime(2026, 1, 1, 12, 0)), SkyPhase.day);
      expect(skyPhaseFor(DateTime(2026, 1, 1, 19, 0)), SkyPhase.dusk);
    });
  });

  group('fictionalHourFor (§6.1 — fictional sky time along the route)', () {
    final segments = [
      const JourneySegmentTiming(
        id: 'a',
        fromMeters: 0,
        toMeters: 1000,
        departureHour: 6,
        durationDays: 1,
      ),
      const JourneySegmentTiming(
        id: 'b',
        fromMeters: 1000,
        toMeters: 2000,
        departureHour: 20,
        durationDays: 3,
      ),
    ];

    test('at a segment start, returns exactly its departureHour', () {
      expect(fictionalHourFor(segments, 0), 6);
    });

    test(
      'at the exact boundary shared by two segments, belongs to the next '
      'one — not the previous segment rolled forward to the same meters',
      () {
        // meters 1000 is both segment a's toMeters and segment b's
        // fromMeters. Segment a rolled fully forward (24h added to its own
        // departureHour 6) would coincidentally also read 6 — a case that
        // could hide this off-by-one — so segment b's very different
        // departureHour (20) is the one that actually proves which segment
        // was picked.
        expect(fictionalHourFor(segments, 1000), 20);
      },
    );

    test('mid-segment position interpolates ("something in between")', () {
      // Segment a: 1 day (24h) over 1000 m — halfway is +12h from 6 -> 18.
      expect(fictionalHourFor(segments, 500), 18);
    });

    test('durationDays > 1 wraps through multiple day/night cycles', () {
      // Segment b: 3 days (72h) over 1000 m, starting at hour 20.
      // Halfway (500 m) = +36h = 20 + 36 = 56 -> 56 % 24 = 8.
      expect(fictionalHourFor(segments, 1500), 8);
    });

    test('clamps before the route to the first segment\'s departureHour', () {
      expect(fictionalHourFor(segments, -500), 6);
    });

    test('clamps after the route to the last segment\'s end hour', () {
      // Segment b ends at +72h from 20 -> 92 % 24 = 20.
      expect(fictionalHourFor(segments, 5000), 20);
    });

    test('a zero-length segment never divides by zero', () {
      final degenerate = [
        const JourneySegmentTiming(
          id: 'z',
          fromMeters: 0,
          toMeters: 0,
          departureHour: 9,
          durationDays: 0,
        ),
      ];
      expect(fictionalHourFor(degenerate, 0), 9);
    });
  });
}
