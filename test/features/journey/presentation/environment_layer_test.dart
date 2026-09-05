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

  group('anchored scene props (§6.1 — a ScenePropAnchor shares its meters '
      'with the terrain profile, not a pixel position)', () {
    // The formula `environment_layer.dart`'s render loop uses for a
    // ScenePropAnchor: objectMeters = anchor.meters * velocityMultiplier —
    // the one choice that makes the anchor sit at screen centre exactly
    // when panMeters == anchor.meters, for any depth.
    double anchorScreenX({
      required double anchorMeters,
      required double panMeters,
      required double velocityMultiplier,
    }) => parallaxScreenX(
      centerX: 400,
      objectMeters: anchorMeters * velocityMultiplier,
      panMeters: panMeters,
      velocityMultiplier: velocityMultiplier,
      pixelsPerMeter: 0.04,
    );

    test('sits at centerX exactly when panMeters == anchor.meters, on the '
        'behind layer (velocityMultiplier 0.5)', () {
      final x = anchorScreenX(
        anchorMeters: 391875,
        panMeters: 391875,
        velocityMultiplier: 0.5,
      );
      expect(x, closeTo(400, 1e-9));
    });

    test('sits at centerX exactly when panMeters == anchor.meters, on the '
        'front layer (velocityMultiplier 1.6) too', () {
      final x = anchorScreenX(
        anchorMeters: 391875,
        panMeters: 391875,
        velocityMultiplier: 1.6,
      );
      expect(x, closeTo(400, 1e-9));
    });

    test('screen position is linear in panMeters, same invariant every '
        'parallax layer already satisfies', () {
      double xAt(double pan) => anchorScreenX(
        anchorMeters: 391875,
        panMeters: pan,
        velocityMultiplier: 0.5,
      );
      final deltaA = xAt(392875) - xAt(391875);
      final deltaB = xAt(393875) - xAt(392875);
      expect(deltaA, closeTo(deltaB, 1e-9));
    });
  });
}
