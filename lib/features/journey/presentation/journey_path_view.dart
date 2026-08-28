import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../achievements/data/achievement_catalog.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/presentation/achievement_titles.dart';
import '../domain/quest_time_service.dart';
import '../domain/route_scale.dart';
import 'journey_providers.dart';

/// The Путь tab's scene (§6.1) — today, a deliberate placeholder: a wavy
/// line standing in for real terrain, with the traveler icon pinned at the
/// screen's horizontal center and the line panned underneath it by a
/// horizontal drag — so moving the line makes the icon look like it rises
/// and falls with the terrain, without the icon itself ever leaving centre.
///
/// The line's *length* is not a placeholder, though: it always spans
/// exactly `[0, journey.totalMeters]` at this quest's fixed
/// [metersPerScreenWidthFor] scale (this task's requirement — "a line with
/// a start and an end, proportional to the route"), so panning is clamped
/// and cannot scroll past point A or point B. Achievement/landmark markers
/// (`achievementCatalog`) sit in their own layer pinned to the top of the
/// scene, at their real meter position along the x axis; ones not reached
/// yet render muted, the same way `achievements_tab.dart` mutes a locked
/// trophy — panning ahead previews them without unlocking them.
///
/// Phase 5 (`flame-scene` skill) replaces this `CustomPaint` with a real
/// Flame `ParallaxComponent` scene — layered biome art, a sky gradient tied
/// to time of day, and the `< Start`/`You >` anchors that tie the pan
/// position back to an actual point on the route. None of that exists yet:
/// the wave shape here is purely decorative, it does not change the
/// day/distance/narrative labels below or credit a different position on
/// the route — those still only move with real progress, exactly as
/// before.
class JourneyPathView extends ConsumerStatefulWidget {
  const JourneyPathView({super.key});

  @override
  ConsumerState<JourneyPathView> createState() => _JourneyPathViewState();
}

class _JourneyPathViewState extends ConsumerState<JourneyPathView> {
  /// The route position, in meters from point A, currently centered under
  /// the traveler icon — ephemeral view state, not progress: it resets on
  /// rebuild and is never persisted or read by any provider (see the class
  /// doc comment on scope). Always kept inside `[0, _totalMeters]` (set by
  /// [_onHorizontalDragUpdate]) so the line can never be panned past either
  /// end.
  double _panMeters = 0;

  /// The active journey's length, cached from the latest [build] so
  /// [_onHorizontalDragUpdate] (which fires outside the widget tree, from a
  /// raw gesture callback) knows where to clamp [_panMeters] without
  /// reaching back into Riverpod.
  int _totalMeters = 0;

  /// The active journey's id, cached the same way as [_totalMeters] — looks
  /// up this quest's own scale via [metersPerScreenWidthFor] rather than a
  /// single app-wide constant (§6.1 — the scale is per-quest config).
  String _journeyId = '';

  /// The scene's width in logical pixels, cached from the latest
  /// `LayoutBuilder` pass for the same reason as [_totalMeters] — converting
  /// a drag delta (pixels) to a meters delta needs the current
  /// pixels-per-meter ratio.
  double _sceneWidth = 0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_sceneWidth <= 0) return; // not laid out yet — nothing to scroll.
    final pixelsPerMeter = _sceneWidth / metersPerScreenWidthFor(_journeyId);
    setState(() {
      // Dragging left (negative dx) reveals what's further down the route
      // (toward B), matching the usual "swipe left to advance" convention —
      // so it increases _panMeters.
      _panMeters = (_panMeters - details.delta.dx / pixelsPerMeter).clamp(
        0.0,
        _totalMeters.toDouble(),
      );
    });
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

    _totalMeters = journey.totalMeters;
    _journeyId = journey.id;
    // A quest whose length shrank underneath an in-flight pan (never
    // happens today — the catalog is static — but cheap to guard) snaps the
    // view back inside bounds rather than leaving it stranded past B.
    _panMeters = _panMeters.clamp(0.0, _totalMeters.toDouble());

    final day = questTimeService.questDay(
      startedAt: selected.startedAt,
      now: DateTime.now(),
    );
    final distance = formatDistance(selected.progressMeters);
    final achievementStates = evaluateAchievements(
      progressMeters: selected.progressMeters,
      catalog: achievementCatalog,
    );

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
                  _sceneWidth = size.width;
                  final centerX = size.width / 2;
                  final midY = size.height / 2;
                  final pixelsPerMeter =
                      size.width / metersPerScreenWidthFor(_journeyId);
                  // Same panOffset feeds the painter and the traveler icon
                  // — one function decides the line's shape, so neither
                  // reader can drift apart from it (see the class doc
                  // comment). Achievement markers below use `pixelsPerMeter`
                  // directly instead, since their layer is pinned to the
                  // top and doesn't follow the line's height.
                  final panOffsetPixels = _panMeters * pixelsPerMeter;
                  final travelerY = _wavyPathY(
                    x: centerX,
                    panOffset: panOffsetPixels,
                    midY: midY,
                  );

                  return Stack(
                    children: [
                      CustomPaint(
                        key: const Key('journeyPathScene'),
                        size: size,
                        painter: _WavyPathPainter(
                          panOffset: panOffsetPixels,
                          midY: midY,
                          totalMeters: _totalMeters,
                          panMeters: _panMeters,
                          pixelsPerMeter: pixelsPerMeter,
                          centerX: centerX,
                        ),
                      ),
                      for (final state in achievementStates)
                        if (state.def.thresholdMeters <= _totalMeters)
                          _AchievementMarker(
                            key: Key('achievementMarker-${state.def.id}'),
                            state: state,
                            l10n: l10n,
                            x:
                                centerX +
                                (state.def.thresholdMeters - _panMeters) *
                                    pixelsPerMeter,
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
/// and the traveler icon (sits on it) — there is exactly one function that
/// knows the shape of this curve, so the two can never drift apart.
/// Achievement markers deliberately do *not* read this — they live in
/// their own layer pinned to [_markersLayerTop] instead (this task's
/// requirement).
double _wavyPathY({
  required double x,
  required double panOffset,
  required double midY,
}) {
  final phase = (x - panOffset) / _waveWavelength * 2 * math.pi;
  return midY + _waveAmplitude * math.sin(phase);
}

/// A single achievement/landmark marker, in its own layer pinned to the top
/// of the scene (this task's requirement) — every marker sits at the same
/// [_markersLayerTop], regardless of what the wavy placeholder line is
/// doing directly underneath it at that `x`. Only [x] (from the marker's
/// meters and the current pan) varies between markers; gold once
/// [AchievementState.unlocked] (the same rule `achievements_tab.dart`
/// uses), muted otherwise — so scrolling ahead of the current position
/// previews what's coming without pretending it has already been reached.
///
/// The icon itself is all that shows on the line — a tap is required to see
/// anything more (this task's requirement). No hover/long-press reveal, no
/// always-on label: [_showAchievementDetails] is the only way to read a
/// marker's name and status.
class _AchievementMarker extends StatelessWidget {
  const _AchievementMarker({
    super.key,
    required this.state,
    required this.x,
    required this.l10n,
  });

  final AchievementState state;
  final AppLocalizations l10n;

  /// Horizontal screen position, in pixels — already resolved by the
  /// caller from the marker's meters and the current pan (§ boundary: the
  /// scene converts meters to pixels, it does not decide the scale itself).
  final double x;

  @override
  Widget build(BuildContext context) {
    final color = state.unlocked ? AppColors.gold : AppColors.textSecondary;
    return Positioned(
      // The tappable area is padded out beyond the icon itself
      // (_markerTapPadding on every side) so a 20px icon still has a
      // comfortable touch target — the icon's own painted position doesn't
      // move, only the hit-testable region around it grows.
      left: x - _markerIconSize / 2 - _markerTapPadding,
      top: _markersLayerTop - _markerTapPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showAchievementDetails(context, l10n, state),
        child: Padding(
          padding: const EdgeInsets.all(_markerTapPadding),
          child: Icon(
            state.unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: color,
            size: _markerIconSize,
          ),
        ),
      ),
    );
  }
}

/// Size of an achievement marker icon, in logical pixels.
const double _markerIconSize = 20;

/// Fixed distance from the top of the scene to every marker's icon, in
/// logical pixels — "always at the very top" (this task's requirement), a
/// single flat row that never moves with the line's height at any given
/// `x`.
const double _markersLayerTop = AppSpacing.md;

/// Extra hit-testable margin around a marker icon, in logical pixels — the
/// icon itself is small (20px); this keeps the tap target from being
/// uncomfortably tight without changing how the icon looks or where it
/// visually sits.
const double _markerTapPadding = AppSpacing.sm;

/// Shows a marker's name and status (this task's requirement — "details on
/// tap only") in a bottom sheet, following the same shape every other sheet
/// in this app uses (see `settings_tab.dart`'s `_showSignInStub`): title,
/// then status line, dismissible by the sheet's own default swipe-down/
/// tap-outside gesture — no bespoke close button, since adding one needs a
/// new l10n key and this change didn't add one.
void _showAchievementDetails(
  BuildContext context,
  AppLocalizations l10n,
  AchievementState state,
) {
  showModalBottomSheet<void>(
    context: context,
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

class _WavyPathPainter extends CustomPainter {
  const _WavyPathPainter({
    required this.panOffset,
    required this.midY,
    required this.totalMeters,
    required this.panMeters,
    required this.pixelsPerMeter,
    required this.centerX,
  });

  final double panOffset;
  final double midY;

  /// The route's full length in meters — the line is drawn only across
  /// `[0, totalMeters]`; it does not exist before point A or after point B
  /// (this task's requirement: "a line with a start and an end").
  final int totalMeters;

  /// The route position, in meters, currently centered at [centerX].
  final double panMeters;
  final double pixelsPerMeter;
  final double centerX;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.backgroundElevated,
    );

    // The line only exists between point A (0 m) and point B (totalMeters);
    // convert those two route bounds to screen x once, then clip drawing to
    // whichever part of that span is actually on screen.
    final startX = centerX - panMeters * pixelsPerMeter;
    final endX = centerX + (totalMeters - panMeters) * pixelsPerMeter;
    final left = math.max(0.0, startX);
    final right = math.min(size.width, endX);
    if (right <= left) return; // point A and point B are both off-screen.

    final path = Path()
      ..moveTo(left, _wavyPathY(x: left, panOffset: panOffset, midY: midY));
    // A few pixels per segment reads as smooth without evaluating sin() at
    // every physical pixel.
    const step = 4.0;
    for (var x = left + step; x <= right; x += step) {
      path.lineTo(x, _wavyPathY(x: x, panOffset: panOffset, midY: midY));
    }
    path.lineTo(right, _wavyPathY(x: right, panOffset: panOffset, midY: midY));

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
      oldDelegate.panOffset != panOffset ||
      oldDelegate.midY != midY ||
      oldDelegate.totalMeters != totalMeters ||
      oldDelegate.panMeters != panMeters ||
      oldDelegate.pixelsPerMeter != pixelsPerMeter ||
      oldDelegate.centerX != centerX;
}
