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

/// The Путь tab's scene (§6.1) — today, a deliberate placeholder: a solid
/// background and a straight line the traveler marker sits on, per the
/// reference screenshot's intent without its art. Phase 5
/// (`flame-scene` skill) replaces this `CustomPaint` with a real Flame
/// `ParallaxComponent` scene; nothing else on this screen changes shape
/// when that happens (`docs/screens/journey.md`).
class JourneyPathView extends ConsumerWidget {
  const JourneyPathView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final progressFraction = journey.totalMeters == 0
        ? 0.0
        : (selected.progressMeters / journey.totalMeters).clamp(0.0, 1.0);

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _StraightPathPainter(progress: progressFraction),
              child: const SizedBox.expand(),
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

class _StraightPathPainter extends CustomPainter {
  const _StraightPathPainter({required this.progress});

  /// 0.0 (point A) .. 1.0 (point B).
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.backgroundElevated,
    );

    final lineY = size.height / 2;
    final linePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.45)
      ..strokeWidth = AppStroke.path;
    canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), linePaint);

    final travelerX = size.width * progress;
    canvas.drawCircle(
      Offset(travelerX, lineY),
      8,
      Paint()..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _StraightPathPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
