import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/route_scale.dart';

void main() {
  group('metersPerScreenWidthFor (§6.1 — per-quest scale config)', () {
    test('a configured quest gets its own entry', () {
      expect(metersPerScreenWidthFor('odyssey-ithaca'), 20000);
    });

    test('an unconfigured quest falls back to the default scale', () {
      expect(
        metersPerScreenWidthFor('some-future-quest'),
        defaultMetersPerScreenWidth,
      );
    });
  });

  group(
    'metersToLineOffset (§6.1 — fixed meters-per-screen-width scale)',
    () {
      test('point A (0 m) sits at offset 0 regardless of screen width', () {
        expect(
          metersToLineOffset(
            journeyId: 'odyssey-ithaca',
            meters: 0,
            screenWidth: 800,
          ),
          0.0,
        );
      });

      test(
        'exactly one screen width of meters offsets by one screen width',
        () {
          expect(
            metersToLineOffset(
              journeyId: 'odyssey-ithaca',
              meters: metersPerScreenWidthFor('odyssey-ithaca'),
              screenWidth: 800,
            ),
            800.0,
          );
        },
      );

      test('offset is linear/proportional in meters', () {
        final scale = metersPerScreenWidthFor('odyssey-ithaca');
        final half = metersToLineOffset(
          journeyId: 'odyssey-ithaca',
          meters: scale ~/ 2,
          screenWidth: 800,
        );
        final full = metersToLineOffset(
          journeyId: 'odyssey-ithaca',
          meters: scale,
          screenWidth: 800,
        );
        expect(half, moreOrLessEquals(full / 2));
      });

      test('the scale itself does not depend on screen width', () {
        // Same distance, two device widths — the number of "screen widths"
        // it takes to cross it (offset / screenWidth) stays the same; only
        // the raw pixel offset scales with the device.
        final narrow = metersToLineOffset(
          journeyId: 'odyssey-ithaca',
          meters: 5000,
          screenWidth: 400,
        );
        final wide = metersToLineOffset(
          journeyId: 'odyssey-ithaca',
          meters: 5000,
          screenWidth: 800,
        );
        expect(wide, moreOrLessEquals(narrow * 2));
      });

      test('negative meters clamp to point A (offset 0), never negative', () {
        expect(
          metersToLineOffset(
            journeyId: 'odyssey-ithaca',
            meters: -1000,
            screenWidth: 800,
          ),
          0.0,
        );
      });

      test('an unconfigured quest uses the default scale', () {
        expect(
          metersToLineOffset(
            journeyId: 'some-future-quest',
            meters: defaultMetersPerScreenWidth,
            screenWidth: 800,
          ),
          800.0,
        );
      });
    },
  );
}
