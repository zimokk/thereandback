import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/quest_progress.dart';

void main() {
  group('questDay (§5.3 — local calendar dates, never ms / 86400000)', () {
    test('same calendar day is Day 1', () {
      final startedAt = DateTime(2026, 3, 10, 23, 50);
      final now = DateTime(2026, 3, 10, 23, 55);
      expect(questDay(startedAt: startedAt, now: now), 1);
    });

    test('next calendar day is Day 2, even a minute later', () {
      final startedAt = DateTime(2026, 3, 10, 23, 59);
      final now = DateTime(2026, 3, 11, 0, 1);
      expect(questDay(startedAt: startedAt, now: now), 2);
    });

    test('a full week later is Day 8', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 17);
      expect(questDay(startedAt: startedAt, now: now), 8);
    });

    test('a DST transition still counts calendar days, not elapsed hours', () {
      // Europe/Berlin-style spring-forward: this calendar day is only 23
      // hours long in the real timezone, but questDay works on local
      // wall-clock dates handed to it, so it must not care.
      final startedAt = DateTime(2026, 3, 28, 12);
      final now = DateTime(2026, 3, 29, 12);
      expect(questDay(startedAt: startedAt, now: now), 2);
    });

    test('now before startedAt clamps to Day 1 instead of going negative', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 5);
      expect(questDay(startedAt: startedAt, now: now), 1);
    });
  });

  group('paceMetersPerDay', () {
    test('zero progress is a real zero pace', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 12);
      expect(
        paceMetersPerDay(progressMeters: 0, startedAt: startedAt, now: now),
        0,
      );
    });

    test('averages total progress over elapsed quest days', () {
      final startedAt = DateTime(2026, 3, 10);
      final now = DateTime(2026, 3, 14); // Day 5
      expect(
        paceMetersPerDay(progressMeters: 5000, startedAt: startedAt, now: now),
        1000,
      );
    });
  });

  group(
    'estimateArrival (§5.3 — zero pace renders a dash, never infinity)',
    () {
      test('zero pace returns null', () {
        final startedAt = DateTime(2026, 3, 10);
        final now = DateTime(2026, 3, 12);
        final eta = estimateArrival(
          progressMeters: 0,
          totalMeters: 10000,
          startedAt: startedAt,
          now: now,
        );
        expect(eta, isNull);
      });

      test('a real pace projects a future arrival date', () {
        final startedAt = DateTime(2026, 3, 10);
        final now = DateTime(2026, 3, 14); // Day 5 -> pace 5000/5 = 1000 m/day
        final eta = estimateArrival(
          progressMeters: 5000,
          totalMeters: 15000, // 10000 m remaining -> 10 more days
          startedAt: startedAt,
          now: now,
        );
        expect(eta, DateTime(2026, 3, 24));
      });

      test('already past the total returns now, not a past date', () {
        final startedAt = DateTime(2026, 3, 10);
        final now = DateTime(2026, 3, 15);
        final eta = estimateArrival(
          progressMeters: 20000,
          totalMeters: 15000,
          startedAt: startedAt,
          now: now,
        );
        expect(eta, now);
      });
    },
  );
}
