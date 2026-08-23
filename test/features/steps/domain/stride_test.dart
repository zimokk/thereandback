import 'package:test/test.dart';
import 'package:thereandback/features/steps/domain/stride.dart';

void main() {
  group('stepsToMeters (§5.1)', () {
    test('uses the 0.75 m default stride', () {
      expect(stepsToMeters(1000), 750);
    });

    test('a manually set stride overrides the default', () {
      expect(stepsToMeters(1000, strideMeters: 0.8), 800);
    });
  });

  group('resolveDistanceMeters — platform distance beats steps × stride', () {
    test('prefers platform DISTANCE_WALKING_RUNNING when present', () {
      final meters = resolveDistanceMeters(
        stepCount: 1000, // would be 750 m via stride
        walkingDistanceMeters: 820,
      );
      expect(meters, 820);
    });

    test('falls back to steps × stride when the platform gives none', () {
      final meters = resolveDistanceMeters(stepCount: 1000);
      expect(meters, 750);
    });

    test('a zero platform distance is still trusted over stride', () {
      final meters = resolveDistanceMeters(
        stepCount: 1000,
        walkingDistanceMeters: 0,
      );
      expect(meters, 0);
    });
  });

  group('clampNonDecreasing (§5.1 — progress never decreases)', () {
    test('a normal forward delta passes through', () {
      expect(clampNonDecreasing(1000, 1200), 1200);
    });

    test('a negative delta from the source clamps to the previous total', () {
      expect(clampNonDecreasing(1000, 800), 1000);
    });

    test('an equal reading is a no-op, not a decrease', () {
      expect(clampNonDecreasing(1000, 1000), 1000);
    });
  });

  group('isImplausiblePace (§5.2 — flag, never silently drop)', () {
    test('a realistic walking pace is not flagged', () {
      final flagged = isImplausiblePace(
        steps: 100,
        interval: const Duration(minutes: 1),
      );
      expect(flagged, isFalse);
    });

    test('over 250 steps/min is flagged', () {
      final flagged = isImplausiblePace(
        steps: 300,
        interval: const Duration(minutes: 1),
      );
      expect(flagged, isTrue);
    });

    test('exactly the threshold is not flagged', () {
      final flagged = isImplausiblePace(
        steps: 250,
        interval: const Duration(minutes: 1),
      );
      expect(flagged, isFalse);
    });

    test('a zero-length interval with any steps is flagged', () {
      final flagged = isImplausiblePace(steps: 1, interval: Duration.zero);
      expect(flagged, isTrue);
    });
  });
}
