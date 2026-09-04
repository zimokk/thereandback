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

  group('hourOfDay', () {
    test('extracts a decimal hour from a DateTime', () {
      expect(hourOfDay(DateTime(2026, 1, 1, 6, 30)), 6.5);
      expect(hourOfDay(DateTime(2026, 1, 1, 0, 0)), 0);
      expect(hourOfDay(DateTime(2026, 1, 1, 23, 45)), closeTo(23.75, 1e-9));
    });
  });

  group('skyBlendForHour (continuous counterpart of skyPhaseForHour, for '
      'smooth sky transitions)', () {
    test('flat inside night — from == to, t == 0', () {
      for (final hour in [0.0, 2.0, 4.99, 20.0, 23.0]) {
        final blend = skyBlendForHour(hour);
        expect(blend.from, SkyPhase.night);
        expect(blend.to, SkyPhase.night);
        expect(blend.t, 0);
      }
    });

    test('flat inside day — from == to, t == 0', () {
      for (final hour in [7.0, 12.0, 17.99]) {
        final blend = skyBlendForHour(hour);
        expect(blend.from, SkyPhase.day);
        expect(blend.to, SkyPhase.day);
        expect(blend.t, 0);
      }
    });

    test('night -> dawn across [5,6), dawn fully arrived at 6', () {
      expect(skyBlendForHour(5), (
        from: SkyPhase.night,
        to: SkyPhase.dawn,
        t: 0.0,
      ));
      expect(skyBlendForHour(5.5), (
        from: SkyPhase.night,
        to: SkyPhase.dawn,
        t: 0.5,
      ));
    });

    test('dawn -> day across [6,7), day fully arrived at 7', () {
      expect(skyBlendForHour(6), (
        from: SkyPhase.dawn,
        to: SkyPhase.day,
        t: 0.0,
      ));
      expect(skyBlendForHour(6.5), (
        from: SkyPhase.dawn,
        to: SkyPhase.day,
        t: 0.5,
      ));
    });

    test('day -> dusk across [18,19), dusk fully arrived at 19', () {
      expect(skyBlendForHour(18), (
        from: SkyPhase.day,
        to: SkyPhase.dusk,
        t: 0.0,
      ));
      expect(skyBlendForHour(18.5), (
        from: SkyPhase.day,
        to: SkyPhase.dusk,
        t: 0.5,
      ));
    });

    test('dusk -> night across [19,20), night fully arrived at 20', () {
      expect(skyBlendForHour(19), (
        from: SkyPhase.dusk,
        to: SkyPhase.night,
        t: 0.0,
      ));
      expect(skyBlendForHour(19.5), (
        from: SkyPhase.dusk,
        to: SkyPhase.night,
        t: 0.5,
      ));
    });

    test('seams are continuous where a transition ends: value just before '
        'the boundary has t close to 1, matching the flat/next phase that '
        'starts at the boundary', () {
      const epsilon = 1e-9;
      for (final boundary in [6.0, 7.0, 19.0, 20.0]) {
        final before = skyBlendForHour(boundary - epsilon);
        expect(before.t, closeTo(1, 1e-6));
      }
    });

    test('seams are continuous where a flat band ends: value just before '
        'the boundary is still flat (t == 0), matching the transition that '
        'starts at t == 0 right at the boundary', () {
      const epsilon = 1e-9;
      for (final boundary in [5.0, 18.0]) {
        final before = skyBlendForHour(boundary - epsilon);
        expect(before.t, 0);
      }
    });

    test('wraps past 24 the same as skyPhaseForHour', () {
      expect(skyBlendForHour(30), skyBlendForHour(6));
    });
  });

  group('starOpacityForHour (continuous counterpart of the binary night-only '
      'star opacity)', () {
    test('full opacity through the night band', () {
      expect(starOpacityForHour(0), 1);
      expect(starOpacityForHour(4.99), 1);
      expect(starOpacityForHour(20), 1);
      expect(starOpacityForHour(23), 1);
    });

    test('zero opacity through the day band', () {
      expect(starOpacityForHour(7), 0);
      expect(starOpacityForHour(12), 0);
      expect(starOpacityForHour(17.99), 0);
    });

    test('fades out linearly across dawn [5,7)', () {
      expect(starOpacityForHour(5), 1);
      expect(starOpacityForHour(6), 0.5);
      expect(starOpacityForHour(6.5), 0.25);
    });

    test('fades in linearly across dusk [18,20)', () {
      expect(starOpacityForHour(18), 0);
      expect(starOpacityForHour(19), 0.5);
      expect(starOpacityForHour(19.5), 0.75);
    });

    test('is monotonic across each transition band', () {
      const dawnHours = [5.0, 5.5, 6.0, 6.5, 6.99];
      final dawnSamples = dawnHours.map(starOpacityForHour).toList();
      for (var i = 1; i < dawnSamples.length; i++) {
        expect(dawnSamples[i], lessThan(dawnSamples[i - 1]));
      }

      const duskHours = [18.0, 18.5, 19.0, 19.5, 19.99];
      final duskSamples = duskHours.map(starOpacityForHour).toList();
      for (var i = 1; i < duskSamples.length; i++) {
        expect(duskSamples[i], greaterThan(duskSamples[i - 1]));
      }
    });

    test('wraps past 24 the same as within [0,24)', () {
      expect(starOpacityForHour(30), starOpacityForHour(6));
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

    test('at the exact boundary shared by two segments, belongs to the next '
        'one — not the previous segment rolled forward to the same meters', () {
      // meters 1000 is both segment a's toMeters and segment b's
      // fromMeters. Segment a rolled fully forward (24h added to its own
      // departureHour 6) would coincidentally also read 6 — a case that
      // could hide this off-by-one — so segment b's very different
      // departureHour (20) is the one that actually proves which segment
      // was picked.
      expect(fictionalHourFor(segments, 1000), 20);
    });

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
