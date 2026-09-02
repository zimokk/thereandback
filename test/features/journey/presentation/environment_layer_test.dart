import 'package:test/test.dart';
import 'package:thereandback/features/journey/presentation/environment_layer.dart';

void main() {
  group(
    'parallaxScreenX (§12 — parallax offset linear in scroll position)',
    () {
      test('velocityMultiplier 1.0 matches the plain on-path formula', () {
        // centerX + (meters - pan) * pixelsPerMeter — the same formula every
        // world-space entity (terrain, traveler, friends) uses.
        final x = parallaxScreenX(
          centerX: 400,
          objectMeters: 5000,
          panMeters: 3000,
          velocityMultiplier: 1.0,
          pixelsPerMeter: 0.04,
        );
        expect(x, closeTo(400 + (5000 - 3000) * 0.04, 1e-9));
      });

      test('screen offset scales linearly with velocityMultiplier * Δpan', () {
        const centerX = 400.0;
        const objectMeters = 5000.0;
        const pixelsPerMeter = 0.04;
        const multiplier = 0.5;

        final atPan0 = parallaxScreenX(
          centerX: centerX,
          objectMeters: objectMeters,
          panMeters: 0,
          velocityMultiplier: multiplier,
          pixelsPerMeter: pixelsPerMeter,
        );
        final atPan1000 = parallaxScreenX(
          centerX: centerX,
          objectMeters: objectMeters,
          panMeters: 1000,
          velocityMultiplier: multiplier,
          pixelsPerMeter: pixelsPerMeter,
        );

        final actualDelta = atPan1000 - atPan0;
        final expectedDelta = -multiplier * 1000 * pixelsPerMeter;
        expect(actualDelta, closeTo(expectedDelta, 1e-9));
      });

      test('a slower layer (lower multiplier) moves less for the same pan', () {
        double offsetFor(double multiplier) =>
            parallaxScreenX(
              centerX: 0,
              objectMeters: 0,
              panMeters: 1000,
              velocityMultiplier: multiplier,
              pixelsPerMeter: 0.05,
            ) -
            parallaxScreenX(
              centerX: 0,
              objectMeters: 0,
              panMeters: 0,
              velocityMultiplier: multiplier,
              pixelsPerMeter: 0.05,
            );

        final slow = offsetFor(0.5).abs();
        final fast = offsetFor(1.6).abs();
        expect(slow, lessThan(fast));
      });
    },
  );
}
