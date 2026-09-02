import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Four broad slices of the day the sky's palette moves through (CLAUDE.md
/// §6.1: "процедурный градиент по реальному времени суток... ночь со
/// звёздами, рассвет, день, закат"). Boundaries are simple local-hour
/// bands, not sunrise/sunset astronomy — this is decorative atmosphere, not
/// anything the domain layer needs to reason about (§13's "sanitize
/// health data" concerns don't apply here; nothing about a device's clock
/// is sensitive).
enum SkyPhase { night, dawn, day, dusk }

/// Which [SkyPhase] [now]'s local time of day falls in. A pure function
/// (never reads the clock itself) so it can be unit-tested directly —
/// `SkyGradient` is the one caller that actually feeds it `DateTime.now()`.
SkyPhase skyPhaseFor(DateTime now) {
  final hour = now.hour + now.minute / 60;
  if (hour < 5 || hour >= 20) return SkyPhase.night;
  if (hour < 7) return SkyPhase.dawn;
  if (hour < 18) return SkyPhase.day;
  return SkyPhase.dusk;
}

/// Top-to-bottom gradient colors for [phase] — muted, low-saturation tones
/// that stay compatible with the scene's warm near-black backdrop
/// (`AppSceneBackdrop`'s `journeySceneBackground`) rather than a bright sky
/// blue that would clash with it.
List<Color> _gradientColorsFor(SkyPhase phase) {
  return switch (phase) {
    SkyPhase.night => const [Color(0xFF06060A), Color(0xFF15141C)],
    SkyPhase.dawn => const [Color(0xFF2B2436), Color(0xFF6E4A4A)],
    SkyPhase.day => const [Color(0xFF2E3446), Color(0xFF4C5568)],
    SkyPhase.dusk => const [Color(0xFF241A2E), Color(0xFF6B3B3F)],
  };
}

/// How visible the star layer is for [phase] — only night carries any
/// stars; dawn/dusk fade them out entirely rather than a partial value, to
/// keep the transition simple.
double _starOpacityFor(SkyPhase phase) => phase == SkyPhase.night ? 1.0 : 0.0;

/// How often [_SkyGradientState] re-checks the clock — the sky is "almost
/// static" (§6.1), so there is no reason to recompute this every Flame
/// frame; once a minute is coarse enough that a phase transition is never
/// visibly late by more than that.
const Duration _skyRecomputeInterval = Duration(minutes: 1);

/// The Путь tab's sky layer — a plain Flutter `CustomPaint`, not a Flame
/// component, since it is driven by wall-clock time rather than scroll
/// position and has no per-frame reason to live inside the game loop
/// (`journey_flame_scene_view.dart` positions it behind the transparent
/// `GameWidget`, in front of `AppSceneBackdrop`).
class SkyGradient extends StatefulWidget {
  const SkyGradient({super.key});

  @override
  State<SkyGradient> createState() => _SkyGradientState();
}

class _SkyGradientState extends State<SkyGradient> {
  Timer? _timer;
  late SkyPhase _phase;

  @override
  void initState() {
    super.initState();
    _phase = skyPhaseFor(DateTime.now());
    _timer = Timer.periodic(_skyRecomputeInterval, (_) => _recompute());
  }

  void _recompute() {
    final next = skyPhaseFor(DateTime.now());
    if (next != _phase && mounted) setState(() => _phase = next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _SkyPainter(phase: _phase)),
    );
  }
}

/// Number of stars painted at night — enough to read as a starfield without
/// per-pixel noise cost.
const int _starCount = 90;

/// Fixed seed for star positions — deterministic, so the field doesn't
/// visibly reshuffle every time the phase recomputes.
const int _starSeed = 11;

class _SkyPainter extends CustomPainter {
  const _SkyPainter({required this.phase});

  final SkyPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = _gradientColorsFor(phase);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    final starOpacity = _starOpacityFor(phase);
    if (starOpacity <= 0) return;

    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * starOpacity);
    final random = math.Random(_starSeed);
    for (var i = 0; i < _starCount; i++) {
      final dx = random.nextDouble() * size.width;
      // Stars only in the upper portion of the sky, not down at the
      // horizon where the terrain layer will sit on top anyway.
      final dy = random.nextDouble() * size.height * 0.6;
      canvas.drawCircle(Offset(dx, dy), 0.9, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
