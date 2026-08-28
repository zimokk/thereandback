import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/quest_time_service.dart';

void main() {
  const service = QuestTimeService();

  group('questDay (§5.3 — local calendar dates, never ms / 86400000)', () {
    test('same calendar day is Day 1', () {
      final startedAt = DateTime(2026, 3, 10, 23, 50);
      final now = DateTime(2026, 3, 10, 23, 55);
      expect(service.questDay(startedAt: startedAt, now: now), 1);
    });

    test('next calendar day is Day 2, even a minute later', () {
      final startedAt = DateTime(2026, 3, 10, 23, 59);
      final now = DateTime(2026, 3, 11, 0, 1);
      expect(service.questDay(startedAt: startedAt, now: now), 2);
    });

    test('a full week later is Day 8', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 17);
      expect(service.questDay(startedAt: startedAt, now: now), 8);
    });

    test('a DST transition still counts calendar days, not elapsed hours', () {
      // Europe/Berlin-style spring-forward: this calendar day is only 23
      // hours long in the real timezone, but questDay works on local
      // wall-clock dates handed to it, so it must not care.
      final startedAt = DateTime(2026, 3, 28, 12);
      final now = DateTime(2026, 3, 29, 12);
      expect(service.questDay(startedAt: startedAt, now: now), 2);
    });

    test('now before startedAt clamps to Day 1 instead of going negative', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 5);
      expect(service.questDay(startedAt: startedAt, now: now), 1);
    });
  });

  group('paceMetersPerDay (§5.3 — 7-day rolling mean, falling back under '
      '3 days of history)', () {
    test('zero progress is a real zero pace', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 12);
      expect(
        service.paceMetersPerDay(
          recentIntervals: const [],
          progressMeters: 0,
          startedAt: startedAt,
          now: now,
        ),
        0,
      );
    });

    test('under 3 elapsed days falls back to the whole-quest average, '
        'ignoring recentIntervals entirely', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 11); // Day 2
      expect(
        service.paceMetersPerDay(
          // Deliberately empty/inconsistent with progressMeters — the
          // fallback branch must not even look at this list.
          recentIntervals: const [],
          progressMeters: 2000,
          startedAt: startedAt,
          now: now,
        ),
        1000,
      );
    });

    test('at exactly 3 elapsed days the rolling window equals the whole-quest '
        'average — there is nothing older than the quest to exclude yet', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 12); // Day 3
      final recentIntervals = [
        MeteredInterval(end: DateTime(2026, 3, 10, 9), meters: 1000),
        MeteredInterval(end: DateTime(2026, 3, 11, 9), meters: 1000),
        MeteredInterval(end: DateTime(2026, 3, 12, 9), meters: 1000),
      ];
      expect(
        service.paceMetersPerDay(
          recentIntervals: recentIntervals,
          progressMeters: 3000,
          startedAt: startedAt,
          now: now,
        ),
        1000,
      );
    });

    test('past 7 elapsed days, only the last 7 calendar days count — older '
        'activity drops out of the window instead of dragging the average', () {
      final startedAt = DateTime(2026, 3, 1);
      final now = DateTime(2026, 3, 15); // Day 15
      final recentIntervals = [
        // A big push right after starting, now 14 days stale — outside
        // the 7-day window and must not inflate today's pace.
        MeteredInterval(end: DateTime(2026, 3, 2, 9), meters: 20000),
        // The last 7 calendar days (Mar 9 .. Mar 15): 500 m/day.
        for (var day = 9; day <= 15; day++)
          MeteredInterval(end: DateTime(2026, 3, day, 9), meters: 500),
      ];
      // Whole-quest average would be (20000 + 7*500) / 14 ≈ 1679 m/day —
      // the rolling window must report 500, not that.
      expect(
        service.paceMetersPerDay(
          recentIntervals: recentIntervals,
          progressMeters: 20000 + 7 * 500,
          startedAt: startedAt,
          now: now,
        ),
        500,
      );
    });

    test('a rest day with zero recorded meters counts as a real zero in '
        'the window, not as a gap that shrinks it', () {
      final startedAt = DateTime(2026, 3, 1);
      final now = DateTime(2026, 3, 15); // Day 15, 7-day window active
      final recentIntervals = [
        // Only 6 of the last 7 calendar days walked; Mar 12 is a rest day
        // with no interval at all.
        for (final day in [9, 10, 11, 13, 14, 15])
          MeteredInterval(end: DateTime(2026, 3, day, 9), meters: 700),
      ];
      // 6 * 700 = 4200 spread over all 7 window days, not divided by 6.
      expect(
        service.paceMetersPerDay(
          recentIntervals: recentIntervals,
          progressMeters: 4200,
          startedAt: startedAt,
          now: now,
        ),
        600,
      );
    });

    test('an interval from outside the window is ignored even if it is '
        'newer than the window end (e.g. clock skew in the fetched data)', () {
      final startedAt = DateTime(2026, 3, 1);
      final now = DateTime(2026, 3, 15);
      final recentIntervals = [
        MeteredInterval(end: DateTime(2026, 3, 16, 9), meters: 99999),
        for (var day = 9; day <= 15; day++)
          MeteredInterval(end: DateTime(2026, 3, day, 9), meters: 100),
      ];
      expect(
        service.paceMetersPerDay(
          recentIntervals: recentIntervals,
          progressMeters: 7 * 100,
          startedAt: startedAt,
          now: now,
        ),
        100,
      );
    });
  });

  group(
    'estimateArrival (§5.3 — zero pace renders a dash, never infinity)',
    () {
      test('zero pace returns null', () {
        final startedAt = DateTime(2026, 3, 10);
        final now = DateTime(2026, 3, 12);
        final eta = service.estimateArrival(
          recentIntervals: const [],
          progressMeters: 0,
          totalMeters: 10000,
          startedAt: startedAt,
          now: now,
        );
        expect(eta, isNull);
      });

      test('a real pace projects a future arrival date', () {
        final startedAt = DateTime(2026, 3, 10);
        final now = DateTime(2026, 3, 11); // Day 2 -> fallback pace 5000/2
        final eta = service.estimateArrival(
          recentIntervals: const [],
          progressMeters: 5000,
          totalMeters: 15000, // 10000 m remaining at 2500 m/day -> 4 days
          startedAt: startedAt,
          now: now,
        );
        expect(eta, DateTime(2026, 3, 15));
      });

      test('already past the total returns now, not a past date', () {
        final startedAt = DateTime(2026, 3, 10);
        final now = DateTime(2026, 3, 15); // Day 6 -> windowed branch
        final eta = service.estimateArrival(
          // A zero/negative pace returns null before `remaining` is even
          // checked (see estimateArrival), so this fixture must give a
          // real positive pace for the "remaining <= 0 -> now" branch
          // below to be reachable at all.
          recentIntervals: [
            MeteredInterval(end: DateTime(2026, 3, 10, 9), meters: 20000),
          ],
          progressMeters: 20000,
          totalMeters: 15000,
          startedAt: startedAt,
          now: now,
        );
        expect(eta, now);
      });

      test('the 7-day rolling window changes the projection past 7 days, '
          'not just the raw pace number', () {
        final startedAt = DateTime(2026, 3, 1);
        final now = DateTime(2026, 3, 15); // Day 15
        final recentIntervals = [
          for (var day = 9; day <= 15; day++)
            MeteredInterval(end: DateTime(2026, 3, day, 9), meters: 500),
        ];
        // Pace is 500 m/day (rolling), not ~1000 m/day (whole-quest with an
        // early burst) — remaining 5000 m takes 10 days at 500 m/day.
        final eta = service.estimateArrival(
          recentIntervals: recentIntervals,
          progressMeters: 10000 + 7 * 500,
          totalMeters: 10000 + 7 * 500 + 5000,
          startedAt: startedAt,
          now: now,
        );
        expect(eta, DateTime(2026, 3, 25));
      });
    },
  );
}
