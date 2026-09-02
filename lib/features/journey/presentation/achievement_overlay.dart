import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/presentation/achievement_titles.dart';
import 'terrain_layer.dart';

/// One achievement marker's already-resolved screen `x` (from its meters
/// and the current pan — §boundary: the scene converts meters to pixels,
/// it doesn't decide the scale itself) paired with its evaluated state.
/// Computed once by `journey_flame_scene_view.dart` and shared by both the
/// marker widget and its guide line, so the two positions can never drift
/// apart.
class VisibleAchievement {
  const VisibleAchievement({required this.state, required this.x});

  final AchievementState state;
  final double x;
}

/// Size of an achievement marker icon, in logical pixels.
const double markerIconSize = 20;

/// Fixed distance from the top of the scene to every marker's icon, in
/// logical pixels — always the top row, a single flat line that never
/// moves with the terrain's own height at any given `x` (ported unchanged
/// from the CustomPaint placeholder's `_markersLayerTop`).
const double markersLayerTop = AppSpacing.md;

/// Extra hit-testable margin around a marker icon, in logical pixels.
const double markerTapPadding = AppSpacing.sm;

/// Where a trophy's guide line starts, in logical pixels from the top of
/// the scene — just under the marker icon itself.
const double markerGuideStartY = markersLayerTop + markerIconSize;

/// Dash length of a trophy's guide line, in logical pixels — same value as
/// `quest_map_view.dart`'s `_trophyDashLength` (§6.2 visual parity).
const double markerGuideDashLength = 3;

/// Gap length between dashes of a trophy's guide line.
const double markerGuideDashGap = 3;

/// Every achievement/landmark marker (§6.2/§6.3), pinned to the top of the
/// scene, plus a faint dotted guide line down to the horizon line at each
/// marker's own route position — ported near-unchanged from the CustomPaint
/// placeholder (`journey_path_view.dart`'s `_AchievementMarker`/
/// `_WavyPathPainter._paintMarkerGuide`), since neither ever depended on
/// how the terrain itself was rendered, only on where it sits.
///
/// Deliberately Flutter widgets, not Flame components: they need a
/// tap-triggered `showModalBottomSheet(useRootNavigator: true)`
/// (`_showAchievementDetails`), which Flutter's own gesture/navigation
/// stack is the natural home for.
class AchievementMarkerOverlay extends StatelessWidget {
  const AchievementMarkerOverlay({
    super.key,
    required this.achievements,
    required this.sceneHeight,
    required this.pixelsPerMeter,
    required this.l10n,
  });

  final List<VisibleAchievement> achievements;
  final double sceneHeight;

  /// Same scale `journey_flame_scene_view.dart` already computes
  /// (`route_scale.dart`'s `metersPerScreenWidthFor`) — needed here to
  /// convert a marker's `thresholdMeters` to the same world-space x
  /// [terrainHeightAt] expects, so the guide line ends exactly on the
  /// horizon line instead of at an arbitrary height.
  final double pixelsPerMeter;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _AchievementGuidesPainter(
              achievements: achievements,
              sceneHeight: sceneHeight,
              pixelsPerMeter: pixelsPerMeter,
            ),
          ),
        ),
        for (final achievement in achievements)
          _AchievementMarker(
            key: Key('achievementMarker-${achievement.state.def.id}'),
            state: achievement.state,
            l10n: l10n,
            x: achievement.x,
          ),
      ],
    );
  }
}

class _AchievementMarker extends StatelessWidget {
  const _AchievementMarker({
    super.key,
    required this.state,
    required this.x,
    required this.l10n,
  });

  final AchievementState state;
  final AppLocalizations l10n;
  final double x;

  @override
  Widget build(BuildContext context) {
    final color = state.unlocked ? AppColors.gold : AppColors.textSecondary;
    return Positioned(
      left: x - markerIconSize / 2 - markerTapPadding,
      top: markersLayerTop - markerTapPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showAchievementDetails(context, l10n, state),
        child: Padding(
          padding: const EdgeInsets.all(markerTapPadding),
          child: Icon(
            state.unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: color,
            size: markerIconSize,
          ),
        ),
      ),
    );
  }
}

/// Shows a marker's name and status in a bottom sheet — same shape every
/// other sheet in this app uses. `useRootNavigator: true`: the Путь tab is
/// one `StatefulShellBranch` of `router.dart`, each with its own nested
/// `Navigator`; pinning to the shared root Navigator lets `AppShell`'s
/// bottom-nav tap handler close this sheet explicitly on a tab switch.
void _showAchievementDetails(
  BuildContext context,
  AppLocalizations l10n,
  AchievementState state,
) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(achievementTitle(l10n, state.def), style: AppTypography.heading),
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.unlocked
                ? l10n.achievementUnlockedLabel
                : l10n.achievementRemainingLabel(
                    localizedDistanceInline(
                      l10n,
                      formatDistance(state.remainingMeters),
                    ),
                  ),
            style: AppTypography.bodySecondary,
          ),
        ],
      ),
    ),
  );
}

class _AchievementGuidesPainter extends CustomPainter {
  const _AchievementGuidesPainter({
    required this.achievements,
    required this.sceneHeight,
    required this.pixelsPerMeter,
  });

  final List<VisibleAchievement> achievements;
  final double sceneHeight;
  final double pixelsPerMeter;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    for (final achievement in achievements) {
      if (achievement.x < 0 || achievement.x > size.width) continue;

      // The terrain sits at screen y = sceneHeight/2 + its world-space
      // height offset — the camera's own viewfinder never moves off world
      // y 0 (`JourneyScene`), so this is the same mapping the rewind ghost
      // uses to place itself relative to the viewport.
      final terrainWorldX = worldXFor(
        achievement.state.def.thresholdMeters.toDouble(),
        pixelsPerMeter,
      );
      final lineY = sceneHeight / 2 + terrainHeightAt(terrainWorldX);
      final from = Offset(achievement.x, markerGuideStartY);
      final to = Offset(achievement.x, lineY);
      _drawDashedLine(canvas, from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AchievementGuidesPainter oldDelegate) =>
      oldDelegate.sceneHeight != sceneHeight ||
      oldDelegate.pixelsPerMeter != pixelsPerMeter ||
      !identical(oldDelegate.achievements, achievements);
}

void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
  final total = (to - from).distance;
  if (total <= 0) return;
  final direction = (to - from) / total;

  var traveled = 0.0;
  while (traveled < total) {
    final segmentEnd = math.min(traveled + markerGuideDashLength, total);
    canvas.drawLine(
      from + direction * traveled,
      from + direction * segmentEnd,
      paint,
    );
    traveled += markerGuideDashLength + markerGuideDashGap;
  }
}
