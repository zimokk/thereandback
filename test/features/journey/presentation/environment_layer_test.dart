import 'package:test/test.dart';
import 'package:thereandback/features/journey/presentation/environment_layer.dart';
import 'package:thereandback/features/journey/presentation/terrain_layer.dart';

/// Where a layer object actually lands on screen, given that the camera
/// translates every `World` child by the full pan
/// (`JourneyScene.update`) — world x, minus the camera, plus the viewport's
/// own centre. The parallax is only correct if it survives that, which is
/// exactly what an earlier screen-space version of [parallaxWorldX] did not:
/// the camera's translation landed on top of the layer's own and every layer
/// ended up moving at the same rate.
double _screenX({
  required double objectMeters,
  required double panMeters,
  required double velocityMultiplier,
  required double pixelsPerMeter,
  double centerX = 400,
}) {
  final worldX = parallaxWorldX(
    objectMeters: objectMeters,
    panMeters: panMeters,
    velocityMultiplier: velocityMultiplier,
    pixelsPerMeter: pixelsPerMeter,
  );
  return worldX - worldXFor(panMeters, pixelsPerMeter) + centerX;
}

void main() {
  group('parallaxWorldX (§12 — parallax offset linear in scroll position)', () {
    test('velocityMultiplier 1.0 is the plain on-path position — no drift '
        'of its own, the camera does all the moving', () {
      expect(
        parallaxWorldX(
          objectMeters: 5000,
          panMeters: 3000,
          velocityMultiplier: 1.0,
          pixelsPerMeter: 0.04,
        ),
        closeTo(worldXFor(5000, 0.04), 1e-9),
      );
      // ...and on screen, that is the same formula every world-space entity
      // (terrain, traveler, friends) ends up at.
      expect(
        _screenX(
          objectMeters: 5000,
          panMeters: 3000,
          velocityMultiplier: 1.0,
          pixelsPerMeter: 0.04,
        ),
        closeTo(400 + (5000 - 3000) * 0.04, 1e-9),
      );
    });

    test('on-screen offset scales linearly with velocityMultiplier * Δpan', () {
      const pixelsPerMeter = 0.04;
      const multiplier = 0.5;

      final atPan0 = _screenX(
        objectMeters: 5000,
        panMeters: 0,
        velocityMultiplier: multiplier,
        pixelsPerMeter: pixelsPerMeter,
      );
      final atPan1000 = _screenX(
        objectMeters: 5000,
        panMeters: 1000,
        velocityMultiplier: multiplier,
        pixelsPerMeter: pixelsPerMeter,
      );

      expect(
        atPan1000 - atPan0,
        closeTo(-multiplier * 1000 * pixelsPerMeter, 1e-9),
      );
    });

    test('a slower layer moves less on screen for the same pan — the whole '
        'point of the multiplier, and what the camera used to cancel out', () {
      double offsetFor(double multiplier) =>
          _screenX(
            objectMeters: 0,
            panMeters: 1000,
            velocityMultiplier: multiplier,
            pixelsPerMeter: 0.05,
          ) -
          _screenX(
            objectMeters: 0,
            panMeters: 0,
            velocityMultiplier: multiplier,
            pixelsPerMeter: 0.05,
          );

      expect(offsetFor(0.25).abs(), lessThan(offsetFor(0.5).abs()));
      expect(offsetFor(0.5).abs(), lessThan(offsetFor(1.0).abs()));
      expect(offsetFor(1.0).abs(), lessThan(offsetFor(1.6).abs()));
    });

    test('a layer at multiplier 0 never moves on screen at all', () {
      double screenAt(double pan) => _screenX(
        objectMeters: 0,
        panMeters: pan,
        velocityMultiplier: 0,
        pixelsPerMeter: 0.04,
      );
      expect(screenAt(50000), closeTo(screenAt(0), 1e-9));
    });
  });

  group('anchored scene props (§6.1 — a ScenePropAnchor shares its meters '
      'with the terrain profile, not a pixel position)', () {
    // A prop names a position on the *route*, so the render loop places it
    // at the route's own rate (`worldXFor`), whichever layer draws it — it
    // has to stay over its landmark rather than drift with its layer.
    double propScreenX({
      required double anchorMeters,
      required double panMeters,
      double pixelsPerMeter = 0.04,
    }) =>
        worldXFor(anchorMeters, pixelsPerMeter) -
        worldXFor(panMeters, pixelsPerMeter) +
        400;

    test('sits at centerX exactly when panMeters == anchor.meters, whichever '
        'layer draws it', () {
      expect(
        propScreenX(anchorMeters: 391875, panMeters: 391875),
        closeTo(400, 1e-9),
      );
    });

    test('screen position is linear in panMeters, same invariant every '
        'parallax layer satisfies', () {
      double xAt(double pan) =>
          propScreenX(anchorMeters: 391875, panMeters: pan);
      expect(
        xAt(392875) - xAt(391875),
        closeTo(xAt(393875) - xAt(392875), 1e-9),
      );
    });

    test('a prop stays over its landmark as the view pans past it', () {
      // Half a screen (10 000 m at the default scale) past the anchor puts
      // it half a screen left of centre — no layer-dependent drift.
      expect(
        propScreenX(anchorMeters: 100000, panMeters: 110000),
        closeTo(400 - 10000 * 0.04, 1e-9),
      );
    });
  });
}
