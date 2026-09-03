import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../domain/fictional_time.dart';

/// Top-to-bottom gradient colors for [phase] — muted, low-saturation tones
/// that stay compatible with the scene's warm near-black backdrop
/// (`AppSceneBackdrop`'s `journeySceneBackground`) rather than a bright sky
/// blue that would clash with it.
List<Color> _gradientColorsFor(SkyPhase phase) {
  return switch (phase) {
    SkyPhase.night => const [AppColors.skyNightTop, AppColors.skyNightBottom],
    SkyPhase.dawn => const [AppColors.skyDawnTop, AppColors.skyDawnBottom],
    SkyPhase.day => const [AppColors.skyDayTop, AppColors.skyDayBottom],
    SkyPhase.dusk => const [AppColors.skyDuskTop, AppColors.skyDuskBottom],
  };
}

/// How visible the star layer is for [phase] — only night carries any
/// stars; dawn/dusk fade them out entirely rather than a partial value, to
/// keep the transition simple.
double _starOpacityFor(SkyPhase phase) => phase == SkyPhase.night ? 1.0 : 0.0;

/// How often [_SkyGradientState] re-checks the real clock (the
/// [SkyGradient.fictionalHour] == null fallback path) — the sky is "almost
/// static" (§6.1), so there is no reason to recompute this every Flame
/// frame; once a minute is coarse enough that a phase transition is never
/// visibly late by more than that.
const Duration _skyRecomputeInterval = Duration(minutes: 1);

/// The Путь tab's sky layer — a plain Flutter `CustomPaint`, not a Flame
/// component, since it is driven by wall-clock time or scroll position
/// rather than the Flame game loop, and has no per-frame reason to live
/// inside it (`journey_flame_scene_view.dart` positions it behind the
/// transparent `GameWidget`, in front of `AppSceneBackdrop`).
class SkyGradient extends StatefulWidget {
  const SkyGradient({super.key, this.fictionalHour});

  /// The in-fiction hour of day (0..24), e.g. from
  /// `fictionalHourFor(timings, panMeters)` — driven by where the "Путь"
  /// scene is scrolled to, for a journey whose content defines a
  /// fictional timeline (CLAUDE.md §6.1).
  ///
  /// `null` — the default, and every journey with no such content — falls
  /// back to today's behavior: the sky follows the device's real clock,
  /// polled once a minute.
  final double? fictionalHour;

  @override
  State<SkyGradient> createState() => _SkyGradientState();
}

class _SkyGradientState extends State<SkyGradient> {
  Timer? _timer;
  late SkyPhase _phase;

  @override
  void initState() {
    super.initState();
    _phase = widget.fictionalHour != null
        ? skyPhaseForHour(widget.fictionalHour!)
        : skyPhaseFor(DateTime.now());
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant SkyGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fictionalHour != oldWidget.fictionalHour) {
      // Recompute immediately on any mode change or new fictional hour —
      // driven by the parent's own rebuild cadence (every scroll/progress
      // change), not the once-a-minute real-clock timer. This also covers
      // flipping *back* to the real-clock fallback (e.g. leaving a
      // story-driven quest): `_phase` must not sit on a stale fictional
      // reading until the next timer tick.
      final next = widget.fictionalHour != null
          ? skyPhaseForHour(widget.fictionalHour!)
          : skyPhaseFor(DateTime.now());
      if (next != _phase) setState(() => _phase = next);
    }
    _syncTimer();
  }

  /// Starts the real-clock poll only while in the `fictionalHour == null`
  /// fallback path, and stops it otherwise — a fictional-hour-driven sky
  /// never needs to poll the device clock, and a widget that flips back to
  /// the fallback (e.g. leaving a story-driven quest) must pick the timer
  /// back up.
  void _syncTimer() {
    if (widget.fictionalHour == null) {
      _timer ??= Timer.periodic(_skyRecomputeInterval, (_) => _recompute());
    } else {
      _timer?.cancel();
      _timer = null;
    }
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
