import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/traveler_interpolation.dart';

void main() {
  group('interpolatedTravelerMeters (§6.1 — smooth `You` interpolation)', () {
    test('elapsedMs == 0 returns the displayed value unchanged', () {
      expect(
        interpolatedTravelerMeters(
          displayedMeters: 100,
          targetMeters: 500,
          elapsedMs: 0,
          durationMs: 1000,
        ),
        100.0,
      );
    });

    test('elapsedMs >= durationMs reaches the target exactly', () {
      expect(
        interpolatedTravelerMeters(
          displayedMeters: 100,
          targetMeters: 500,
          elapsedMs: 1000,
          durationMs: 1000,
        ),
        500.0,
      );
      expect(
        interpolatedTravelerMeters(
          displayedMeters: 100,
          targetMeters: 500,
          elapsedMs: 5000, // well past the duration — still exactly the target.
          durationMs: 1000,
        ),
        500.0,
      );
    });

    test('midway is between displayed and target, never past it', () {
      final value = interpolatedTravelerMeters(
        displayedMeters: 0,
        targetMeters: 1000,
        elapsedMs: 500,
        durationMs: 1000,
      );
      expect(value, closeTo(500, 1e-9));
    });

    test('monotonically non-decreasing as elapsedMs grows', () {
      double previous = 0;
      for (var elapsed = 0.0; elapsed <= 1200; elapsed += 50) {
        final value = interpolatedTravelerMeters(
          displayedMeters: 0,
          targetMeters: 800,
          elapsedMs: elapsed,
          durationMs: 1000,
        );
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    test('never exceeds targetMeters at any elapsed time', () {
      for (var elapsed = 0.0; elapsed <= 2000; elapsed += 37) {
        final value = interpolatedTravelerMeters(
          displayedMeters: 10,
          targetMeters: 250,
          elapsedMs: elapsed,
          durationMs: 900,
        );
        expect(value, lessThanOrEqualTo(250));
      }
    });

    test('displayedMeters already at or past target snaps to target', () {
      expect(
        interpolatedTravelerMeters(
          displayedMeters: 900,
          targetMeters: 500,
          elapsedMs: 0,
          durationMs: 1000,
        ),
        500.0,
      );
      expect(
        interpolatedTravelerMeters(
          displayedMeters: 500,
          targetMeters: 500,
          elapsedMs: 0,
          durationMs: 1000,
        ),
        500.0,
      );
    });

    test('zero-distance interpolation (target == displayed) is a no-op', () {
      expect(
        interpolatedTravelerMeters(
          displayedMeters: 300,
          targetMeters: 300,
          elapsedMs: 200,
          durationMs: 1000,
        ),
        300.0,
      );
    });
  });
}
