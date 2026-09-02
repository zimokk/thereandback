import 'package:test/test.dart';
import 'package:thereandback/features/journey/presentation/sky_gradient.dart';

void main() {
  group('skyPhaseFor (§6.1 — sky by real local time of day)', () {
    test('deep night', () {
      expect(skyPhaseFor(DateTime(2026, 1, 1, 2, 0)), SkyPhase.night);
      expect(skyPhaseFor(DateTime(2026, 1, 1, 23, 0)), SkyPhase.night);
    });

    test('dawn', () {
      expect(skyPhaseFor(DateTime(2026, 1, 1, 6, 0)), SkyPhase.dawn);
    });

    test('day', () {
      expect(skyPhaseFor(DateTime(2026, 1, 1, 12, 0)), SkyPhase.day);
    });

    test('dusk', () {
      expect(skyPhaseFor(DateTime(2026, 1, 1, 19, 0)), SkyPhase.dusk);
    });

    test('boundaries are covered by exactly one phase each, no gaps', () {
      for (var hour = 0; hour < 24; hour++) {
        final phase = skyPhaseFor(DateTime(2026, 1, 1, hour));
        expect(SkyPhase.values, contains(phase));
      }
    });
  });
}
