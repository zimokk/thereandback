import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../colors.dart';

/// Warm, textured backdrop for the Путь tab's scene (§6.1, §9 styling fix —
/// a flat `#000000` "killed the atmosphere"). Paints [AppColors
/// .journeySceneBackground] (a near-black bronze/brown, not the app's
/// neutral [AppColors.background]) with a soft vignette and a faint static
/// grain on top.
///
/// Procedural rather than an image asset — §9.1's art source (illustrated
/// textures for the parallax layers) is still an open decision; this is
/// cheap to swap for a real papyrus-grain texture once one exists, without
/// touching whatever's painted on top of it.
class AppSceneBackdrop extends StatelessWidget {
  const AppSceneBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.journeySceneBackground),
      child: SizedBox.expand(
        child: CustomPaint(painter: _SceneVignettePainter()),
      ),
    );
  }
}

/// Number of grain specks painted across the backdrop — enough to read as
/// texture without the paint cost of a real per-pixel noise pass.
const int _grainSpeckCount = 260;

/// Fixed seed for the grain's pseudo-random positions — deterministic so
/// the texture doesn't visibly swim between rebuilds (a resize still
/// reseeds identically, since [paint] re-runs the same sequence).
const int _grainSeed = 7;

class _SceneVignettePainter extends CustomPainter {
  const _SceneVignettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 0.9,
        colors: [
          Colors.transparent,
          AppColors.background.withValues(alpha: 0.6),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    // A faint, static sprinkle of specks standing in for papyrus grain —
    // low-opacity enough that it reads as texture, not visible dirt.
    final grain = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.035);
    final random = math.Random(_grainSeed);
    for (var i = 0; i < _grainSpeckCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.6, grain);
    }
  }

  @override
  bool shouldRepaint(covariant _SceneVignettePainter oldDelegate) => false;
}
