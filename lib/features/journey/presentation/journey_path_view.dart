import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/quest_progress.dart';
import 'journey_providers.dart';

/// The Путь tab's scene (§6.1) — today, a deliberate placeholder: a wavy
/// line standing in for real terrain, with the traveler icon pinned at the
/// screen's horizontal center and the line panned underneath it by a
/// horizontal drag — so moving the line makes the icon look like it rises
/// and falls with the terrain, without the icon itself ever leaving centre.
///
/// Phase 5 (`flame-scene` skill) replaces this `CustomPaint` with a real
/// Flame `ParallaxComponent` scene — layered biome art, a sky gradient tied
/// to time of day, and the `< Start`/`You >` anchors that tie the pan
/// position back to an actual point on the route. None of that exists yet:
/// the drag here is purely visual camera movement over a placeholder curve,
/// it does not change the day/distance/narrative labels below or credit a
/// different position on the route — those still only move with real
/// progress, exactly as before.
class JourneyPathView extends ConsumerStatefulWidget {
  const JourneyPathView({super.key});

  @override
  ConsumerState<JourneyPathView> createState() => _JourneyPathViewState();
}

class _JourneyPathViewState extends ConsumerState<JourneyPathView> {
  /// How far the wavy line has been panned, in pixels — ephemeral view
  /// state, not progress: it resets on rebuild and is never persisted or
  /// read by any provider (see the class doc comment on scope).
  double _panOffset = 0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _panOffset += details.delta.dx);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedJourneyProvider);
    final journey = ref.watch(selectedJourneyDetailsProvider);
    final l10n = AppLocalizations.of(context)!;

    if (selected == null || journey == null) {
      // Guarded by JourneyTab (only built once a quest is selected); kept
      // as a safe fallback rather than an assertion so a race can't crash
      // the screen.
      return const SizedBox.shrink();
    }

    final day = questDay(startedAt: selected.startedAt, now: DateTime.now());
    final distance = formatDistance(selected.progressMeters);

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  final centerX = size.width / 2;
                  final midY = size.height / 2;
                  final travelerY = _wavyPathY(
                    x: centerX,
                    panOffset: _panOffset,
                    midY: midY,
                  );

                  return Stack(
                    children: [
                      CustomPaint(
                        key: const Key('journeyPathScene'),
                        size: size,
                        painter: _WavyPathPainter(
                          panOffset: _panOffset,
                          midY: midY,
                        ),
                      ),
                      Positioned(
                        left: centerX - _travelerIconSize / 2,
                        top: travelerY - _travelerIconSize / 2,
                        child: const IgnorePointer(
                          child: Icon(
                            Icons.directions_walk,
                            color: AppColors.gold,
                            size: _travelerIconSize,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              children: [
                Text(l10n.journeyDayCounter(day), style: AppTypography.label),
                const SizedBox(height: AppSpacing.md),
                Text(distance.value, style: AppTypography.distanceHero),
                Text(
                  localizedUnitLabel(l10n, distance),
                  style: AppTypography.distanceUnit,
                ),
                const SizedBox(height: AppSpacing.md),
                // Point A/B are journey data, not translatable copy — see
                // the same note in quest_picker_view.dart (§11).
                Text(
                  '${journey.pointA} → ${journey.pointB}',
                  style: AppTypography.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.journeyNarrativeComingSoon,
                  style: AppTypography.narrative,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Size of the traveler icon, in logical pixels.
const double _travelerIconSize = 32;

/// How far the placeholder wave rises and falls from its vertical centre,
/// in pixels.
const double _waveAmplitude = 36;

/// Horizontal distance, in pixels, over which the placeholder wave
/// completes one full up-down cycle.
const double _waveWavelength = 260;

/// Height of the placeholder wavy path at horizontal screen position [x],
/// given how far the line has been panned ([panOffset], pixels) and the
/// scene's vertical centre ([midY]). Shared by the painter (draws the line)
/// and the traveler icon (sits on it) so the two can never drift apart —
/// there is exactly one function that knows the shape of this curve.
double _wavyPathY({
  required double x,
  required double panOffset,
  required double midY,
}) {
  final phase = (x - panOffset) / _waveWavelength * 2 * math.pi;
  return midY + _waveAmplitude * math.sin(phase);
}

class _WavyPathPainter extends CustomPainter {
  const _WavyPathPainter({required this.panOffset, required this.midY});

  final double panOffset;
  final double midY;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.backgroundElevated,
    );

    final path = Path()
      ..moveTo(0, _wavyPathY(x: 0, panOffset: panOffset, midY: midY));
    // A few pixels per segment reads as smooth without evaluating sin() at
    // every physical pixel.
    const step = 4.0;
    for (var x = step; x <= size.width; x += step) {
      path.lineTo(x, _wavyPathY(x: x, panOffset: panOffset, midY: midY));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.path,
    );
  }

  @override
  bool shouldRepaint(covariant _WavyPathPainter oldDelegate) =>
      oldDelegate.panOffset != panOffset || oldDelegate.midY != midY;
}
