import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/progress_fraction.dart';

void main() {
  group(
    'progressFraction (§5.4 — raw 0..1, formatting stays in presentation)',
    () {
      test('zero progress is 0.0', () {
        expect(progressFraction(progressMeters: 0, totalMeters: 10000), 0.0);
      });

      test('a normal in-between value divides cleanly', () {
        expect(
          progressFraction(progressMeters: 2500, totalMeters: 10000),
          0.25,
        );
      });

      test('exactly the full length is 1.0', () {
        expect(
          progressFraction(progressMeters: 10000, totalMeters: 10000),
          1.0,
        );
      });

      test('progress past totalMeters clamps to 1.0, never over', () {
        expect(
          progressFraction(progressMeters: 12000, totalMeters: 10000),
          1.0,
        );
      });

      test('zero-length quest returns 0.0 instead of dividing by zero', () {
        expect(progressFraction(progressMeters: 0, totalMeters: 0), 0.0);
      });
    },
  );
}
