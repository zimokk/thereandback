import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/active_tab_index.dart';
import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/app_scene_backdrop.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../achievements/data/achievement_catalog.dart';
import '../../achievements/domain/achievement.dart';
import '../../friends/domain/friend_progress.dart';
import '../../friends/presentation/friends_providers.dart';
import '../domain/fictional_time.dart';
import '../domain/narrative_beat.dart';
import '../domain/quest_time_service.dart';
import '../domain/route_scale.dart';
import '../domain/traveler_interpolation.dart';
import 'achievement_overlay.dart';
import 'journey_narrative_providers.dart';
import 'journey_providers.dart';
import 'journey_scene.dart';
import 'journey_scene_controller.dart';
import 'journey_timing_providers.dart';
import 'sky_gradient.dart';

/// How long a new `progressMeters` takes to visually catch up to
/// (CLAUDE.md §6.1: "новые шаги плавно интерполируются... 800–1200 мс").
const Duration _travelerCatchUpDuration = Duration(milliseconds: 1000);

/// The Путь tab's real scene (§6.1) — Phase 5's Flame `FlameGame` +
/// `CameraComponent`, replacing the `journey_path_view.dart` `CustomPaint`
/// placeholder. Same behavior contract as that placeholder (rewind-only
/// pan, `You`/ghost figures, friends, achievement markers, the two round
/// anchor buttons, the day/distance/narrative block below the scene) — this
/// view only changes *how* the scene renders, plus one addition the
/// placeholder never had: the solid traveler's position now visibly
/// catches up over ~1 second on new progress, instead of snapping.
///
/// [JourneyScene]/[JourneySceneController] are created once in [initState]
/// and never rebuilt — every Riverpod change below only mutates the
/// controller's fields (§6.1/§12: "Flame `Game` instance is long-lived").
class JourneyFlameSceneView extends ConsumerStatefulWidget {
  const JourneyFlameSceneView({super.key});

  @override
  ConsumerState<JourneyFlameSceneView> createState() =>
      _JourneyFlameSceneViewState();
}

class _JourneyFlameSceneViewState extends ConsumerState<JourneyFlameSceneView>
    with TickerProviderStateMixin {
  late final JourneySceneController _sceneController;
  late final JourneyScene _scene;

  /// The route position, in meters, currently centered on screen —
  /// ephemeral view state (see [JourneySceneController.panMeters]'s own
  /// doc comment; this field is the source of truth, pushed into the
  /// controller on every build).
  double _panMeters = 0;

  int _totalMeters = 0;
  int _progressMeters = 0;
  String _journeyId = '';
  double _sceneWidth = 0;

  AnimationController? _returnController;

  /// The traveler's *displayed* position — may still be catching up to
  /// [_progressMeters] via [_travelerCatchUpController]. Starts equal to
  /// the real progress on the very first build (nothing to catch up from
  /// on a cold start — see [_initializedDisplayedProgress]).
  double _displayedProgressMeters = 0;
  AnimationController? _travelerCatchUpController;
  bool _initializedDisplayedProgress = false;

  @override
  void initState() {
    super.initState();
    _sceneController = JourneySceneController();
    _scene = JourneyScene(controller: _sceneController);
  }

  @override
  void dispose() {
    _returnController?.dispose();
    _travelerCatchUpController?.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_sceneWidth <= 0) return; // not laid out yet — nothing to scroll.
    _returnController?.stop();
    final pixelsPerMeter = _sceneWidth / metersPerScreenWidthFor(_journeyId);
    setState(() {
      _panMeters = (_panMeters - details.delta.dx / pixelsPerMeter).clamp(
        0.0,
        _progressMeters.toDouble(),
      );
    });
  }

  /// Jumps the view back to `You`, animated (§6.1: "прыжок анимированный,
  /// не мгновенный") — ported unchanged from the CustomPaint placeholder.
  void _returnToYou() {
    final start = _panMeters;
    final end = _progressMeters.toDouble();
    if (start == end) return;

    _returnController?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final jump = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ).drive(Tween<double>(begin: start, end: end));
    jump.addListener(() => setState(() => _panMeters = jump.value));
    _returnController = controller;
    controller.forward();
  }

  /// Starts (or restarts) the traveler's catch-up animation toward
  /// [targetMeters] — restarting from whatever is *currently* displayed,
  /// not from the old target, so a second sync arriving mid-catch-up never
  /// causes a visible backward jump.
  void _startTravelerCatchUp(int targetMeters) {
    _travelerCatchUpController?.dispose();
    final startDisplayed = _displayedProgressMeters;
    final controller = AnimationController(
      vsync: this,
      duration: _travelerCatchUpDuration,
    );
    controller.addListener(() {
      final elapsedMs =
          controller.value * _travelerCatchUpDuration.inMilliseconds;
      setState(() {
        _displayedProgressMeters = interpolatedTravelerMeters(
          displayedMeters: startDisplayed,
          targetMeters: targetMeters,
          elapsedMs: elapsedMs,
          durationMs: _travelerCatchUpDuration.inMilliseconds.toDouble(),
        );
      });
    });
    _travelerCatchUpController = controller;
    controller.forward();
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

    // Same "was the view sitting at You before this rebuild" follow-along
    // check the CustomPaint placeholder used — see its own doc comment.
    final wasAtYou = _panMeters >= _progressMeters;
    final previousProgressMeters = _progressMeters;

    _totalMeters = journey.totalMeters;
    _journeyId = journey.id;
    _progressMeters = selected.progressMeters;
    _panMeters = wasAtYou
        ? _progressMeters.toDouble()
        : _panMeters.clamp(0.0, _progressMeters.toDouble());

    if (!_initializedDisplayedProgress) {
      // Cold start (or first build after a quest is selected) — nothing to
      // catch up from, show the real position immediately.
      _displayedProgressMeters = _progressMeters.toDouble();
      _initializedDisplayedProgress = true;
    } else if (_progressMeters != previousProgressMeters) {
      _startTravelerCatchUp(_progressMeters);
    }

    final day = questTimeService.questDay(
      startedAt: selected.startedAt,
      now: DateTime.now(),
    );
    final distance = formatDistance(selected.progressMeters);
    final achievementStates = evaluateAchievements(
      progressMeters: selected.progressMeters,
      catalog: achievementCatalog,
    );

    // Sky driven by the in-fiction timeline when the quest defines one
    // (§6.1) — `_panMeters` is the exact "route position currently centered
    // on screen" the scene already scrolls by, so rewinding re-derives the
    // sky the same way it re-derives the terrain/traveler position. `null`
    // (no timings loaded/shipped yet) falls back to `SkyGradient`'s own
    // real-clock behavior.
    final timings = ref.watch(selectedJourneySegmentTimingsProvider).value;
    final fictionalHour = (timings != null && timings.isNotEmpty)
        ? fictionalHourFor(timings, _panMeters.round())
        : null;

    // The narrative line under the scene follows the same scrolled-to
    // position the sky and terrain already do (§6.1) — falls back to the
    // "still being written" placeholder for a quest with no narrative
    // content at all, or before the traveler has reached the first beat.
    final narrativeBeats = ref
        .watch(selectedJourneyNarrativeBeatsProvider)
        .value;
    final narrativeText =
        (narrativeBeats == null
                ? null
                : narrativeBeatFor(narrativeBeats, _panMeters.round()))
            ?.text ??
        l10n.journeyNarrativeComingSoon;

    final showFriends = ref.watch(showFriendsOnMapProvider);
    final friendRows = showFriends
        ? (ref.watch(friendsViewProvider).value?.rows ??
                  const <FriendProgressRow>[])
              .where((row) => !row.isSelf)
              .toList()
        : const <FriendProgressRow>[];

    // Pushed into the long-lived controller every build — the Flame game
    // itself is never rebuilt (§6.1/§12).
    _sceneController
      ..journeyId = _journeyId
      ..totalMeters = _totalMeters
      ..progressMeters = _progressMeters
      ..displayedProgressMeters = _displayedProgressMeters
      ..panMeters = _panMeters
      ..showFriends = showFriends
      ..friendRows = friendRows;

    // §12: "game loop stops on inactive tab" — a plain field mutation on
    // the already-created game, safe to repeat on every build.
    _scene.paused = !ref.watch(journeySceneActiveProvider);

    return Stack(
      children: [
        const Positioned.fill(child: AppSceneBackdrop()),
        Positioned.fill(child: SkyGradient(fictionalHour: fictionalHour)),
        Column(
          children: [
            Expanded(
              child: GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    _sceneWidth = size.width;
                    final centerX = size.width / 2;
                    final pixelsPerMeter =
                        size.width / metersPerScreenWidthFor(_journeyId);

                    final visibleAchievements = [
                      for (final state in achievementStates)
                        if (state.def.thresholdMeters <= _totalMeters)
                          VisibleAchievement(
                            state: state,
                            x:
                                centerX +
                                (state.def.thresholdMeters - _panMeters) *
                                    pixelsPerMeter,
                          ),
                    ];

                    // Same pixel-threshold "not currently at You" check the
                    // rewind ghost itself uses (`GhostTravelerComponent`,
                    // compared against the *displayed*, possibly still
                    // catching-up position) — shown/hidden in lockstep with
                    // it.
                    final showReturnButton =
                        ((_displayedProgressMeters - _panMeters) *
                                pixelsPerMeter)
                            .abs() >
                        1.0;

                    return Stack(
                      key: const Key('journeyFlameScene'),
                      children: [
                        GameWidget(game: _scene),
                        AchievementMarkerOverlay(
                          achievements: visibleAchievements,
                          sceneHeight: size.height,
                          pixelsPerMeter: pixelsPerMeter,
                          l10n: l10n,
                        ),
                        if (showReturnButton)
                          Positioned(
                            right: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: _ReturnToYouButton(
                              key: const Key('returnToYouButton'),
                              label: l10n.journeyReturnToYouButton,
                              onTap: _returnToYou,
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
                  Text(
                    '${journey.pointA} → ${journey.pointB}',
                    style: AppTypography.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    narrativeText,
                    style: AppTypography.narrative,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          child: _BackToCatalogButton(
            label: l10n.journeyBackToCatalogButton,
            onTap: () => ref.read(browsingCatalogProvider.notifier).enter(),
          ),
        ),
      ],
    );
  }
}

const double _anchorButtonSize = 36;
const double _anchorIconSize = 18;

class _BackToCatalogButton extends StatelessWidget {
  const _BackToCatalogButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.gold, width: AppStroke.icon),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: _anchorButtonSize,
            height: _anchorButtonSize,
            child: Icon(
              Icons.map_outlined,
              color: AppColors.gold,
              size: _anchorIconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnToYouButton extends StatelessWidget {
  const _ReturnToYouButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.gold, width: AppStroke.icon),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: _anchorButtonSize,
            height: _anchorButtonSize,
            child: Icon(
              Icons.my_location,
              color: AppColors.gold,
              size: _anchorIconSize,
            ),
          ),
        ),
      ),
    );
  }
}
