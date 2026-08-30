import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/app_scene_backdrop.dart';
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
/// line standing in for real terrain, panned by a horizontal drag. Dragging
/// left-to-right (positive `dx`) moves the visible line right — direct
/// manipulation, content follows the finger — and dragging right-to-left
/// reveals what's further down the route, toward B (see
/// [_onHorizontalDragUpdate]). The line's height at any given route meter
/// is fixed (see [_wavyPathY]'s doc comment) — panning changes which part
/// of that fixed profile is on screen, never the profile itself, which is
/// what sells "человек поднимается и спускается по линии": the traveler
/// visibly climbs and descends fixed hills the camera pans across, instead
/// of a pattern that warps as you drag.
///
/// Panning is a **rewind, not a peek**: it is clamped to `[0,
/// progressMeters]`, so it can rewind to any already-walked position but
/// never past the traveler's real, current one — there is nothing to look
/// at beyond it yet (revises the earlier "и заглянуть вперёд" allowance,
/// CLAUDE.md §6.1/§14). Two markers make what's being shown legible:
///
/// - The solid [_TravelerMarker] sits at the traveler's *real* position
///   ([progressMeters]) in the same world-space every achievement marker
///   uses — it does not follow the pan, so as the view rewinds away from
///   it, it visibly slides toward (and eventually off) the opposite edge
///   rather than the pan pulling it along ("на актуальном месте останется
///   сам человек", this task's requirement).
/// - The ghost [_TravelerMarker] is a dim, smaller echo of the same figure,
///   pinned to screen centre — wherever the view is currently centred is,
///   by definition, the position it stands for ("контур фигурки человека,
///   как будто тень, показывая где он был"). Hidden once it would coincide
///   with the solid marker (`_panMeters == progressMeters`, i.e. currently
///   looking at `You`) — one figure there, not two overlapping ones.
/// - A small [_ReturnToYouButton] appears in the corner whenever the ghost
///   is showing — the same rewound-away-from-You condition — and jumps
///   [_JourneyPathViewState._returnToYou] straight back, animated
///   ("прыжок анимированный, не мгновенный", same rule the eventual `You >`
///   anchor above follows).
///
/// Whenever the view is at `You` (`_panMeters == progressMeters`) when new
/// progress lands, the pan follows it forward automatically — "riding
/// along", per the `flame-scene` skill's contract — rather than being left
/// behind at a now-stale position; a deliberately rewound view is left
/// alone (never yanked forward) until the user returns to `You` themselves.
///
/// The line's *length* is not a placeholder, though: it always spans
/// exactly `[0, journey.totalMeters]` at this quest's fixed
/// [metersPerScreenWidthFor] scale (this task's requirement — "a line with
/// a start and an end, proportional to the route"). Achievement/landmark
/// markers (`achievementCatalog`) sit in their own layer pinned to the top
/// of the scene, at their real meter position along the x axis; ones not
/// reached yet render muted, the same way `achievements_tab.dart` mutes a
/// locked trophy — a marker just ahead of `You` can still be glimpsed
/// approaching from the edge without being reachable by rewinding to it.
///
/// Phase 5 (`flame-scene` skill) replaces this `CustomPaint` with a real
/// Flame `ParallaxComponent` scene — layered biome art, a sky gradient tied
/// to time of day, and the `< Start`/`You >` anchor buttons. None of that
/// exists yet: the wave shape here is purely decorative, and the
/// day/distance/narrative labels below always reflect real progress, never
/// the rewound position — those still only move with real progress, exactly
/// as before.
class JourneyPathView extends ConsumerStatefulWidget {
  const JourneyPathView({super.key});

  @override
  ConsumerState<JourneyPathView> createState() => _JourneyPathViewState();
}

class _JourneyPathViewState extends ConsumerState<JourneyPathView>
    with TickerProviderStateMixin {
  /// The route position, in meters from point A, currently centered under
  /// screen centre — ephemeral view state, not progress: it resets on
  /// rebuild and is never persisted or read by any provider (see the class
  /// doc comment on scope). Always kept inside `[0, _progressMeters]` (set
  /// by [_onHorizontalDragUpdate] and [build]'s own follow-at-You logic) —
  /// a rewind, never a peek past the traveler's real position (class doc
  /// comment).
  double _panMeters = 0;

  /// The active journey's length, cached from the latest [build] — used
  /// only for the line's own drawn extent ([_WavyPathPainter]) and for
  /// filtering which achievement markers exist on this route at all
  /// ([build]'s `state.def.thresholdMeters <= _totalMeters` check); no
  /// longer [_panMeters]'s own clamp bound (see [_progressMeters]).
  int _totalMeters = 0;

  /// The traveler's real, current position, cached from the latest [build]
  /// so [_onHorizontalDragUpdate] (which fires outside the widget tree,
  /// from a raw gesture callback) knows where to clamp [_panMeters]
  /// without reaching back into Riverpod. This is the forward bound a
  /// rewind can never cross — there is nothing to look at past it yet.
  int _progressMeters = 0;

  /// The active journey's id, cached the same way as [_totalMeters] — looks
  /// up this quest's own scale via [metersPerScreenWidthFor] rather than a
  /// single app-wide constant (§6.1 — the scale is per-quest config).
  String _journeyId = '';

  /// The scene's width in logical pixels, cached from the latest
  /// `LayoutBuilder` pass for the same reason as [_totalMeters] — converting
  /// a drag delta (pixels) to a meters delta needs the current
  /// pixels-per-meter ratio.
  double _sceneWidth = 0;

  /// Drives the small "return to You" button's animated jump (see
  /// [_returnToYou]) — `null` when no jump is in flight. Kept as a field
  /// (rather than fire-and-forget) so a drag that starts mid-jump can stop
  /// it (see [_onHorizontalDragUpdate]) instead of fighting it for control
  /// of [_panMeters].
  AnimationController? _returnController;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_sceneWidth <= 0) return; // not laid out yet — nothing to scroll.
    // A manual drag always wins over an in-flight animated jump.
    _returnController?.stop();
    final pixelsPerMeter = _sceneWidth / metersPerScreenWidthFor(_journeyId);
    setState(() {
      // Dragging left (negative dx) reveals what's further down the route
      // (toward B), matching the usual "swipe left to advance" convention —
      // so it increases _panMeters. Clamped at _progressMeters, not the
      // route's full length: this is a rewind of the ground already
      // covered, not a peek past it (class doc comment).
      _panMeters = (_panMeters - details.delta.dx / pixelsPerMeter).clamp(
        0.0,
        _progressMeters.toDouble(),
      );
    });
  }

  /// Jumps the view back to `You`, animated rather than an instant snap
  /// (§6.1's "`You >`" anchor: "прыжок анимированный, не мгновенный") — the
  /// small button that appears whenever the view is rewound away from the
  /// real position calls this (this task's requirement).
  void _returnToYou() {
    final start = _panMeters;
    final end = _progressMeters.toDouble();
    if (start == end) return; // already there — nothing to animate.

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

  @override
  void dispose() {
    _returnController?.dispose();
    super.dispose();
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

    // Was the view sitting exactly at `You` before this rebuild? Checked
    // against the *previous* _progressMeters, before it's overwritten below
    // — this is what tells "the user was following along" apart from "the
    // user deliberately rewound", the two cases the class doc comment's
    // follow-at-You paragraph distinguishes. A fresh quest starts with both
    // at 0, so this is also true (and a no-op) on the very first build.
    final wasAtYou = _panMeters >= _progressMeters;

    _totalMeters = journey.totalMeters;
    _journeyId = journey.id;
    _progressMeters = selected.progressMeters;
    _panMeters = wasAtYou
        ? _progressMeters.toDouble()
        // A deliberately rewound view stays put unless new progress has
        // shrunk *behind* it (never happens today — progress is monotonic,
        // §5.2 — but cheap to guard against a rewind stranded past the new
        // bound).
        : _panMeters.clamp(0.0, _progressMeters.toDouble());

    final day = questTimeService.questDay(
      startedAt: selected.startedAt,
      now: DateTime.now(),
    );
    final distance = formatDistance(selected.progressMeters);
    final achievementStates = evaluateAchievements(
      progressMeters: selected.progressMeters,
      catalog: achievementCatalog,
    );

    return Stack(
      children: [
        const Positioned.fill(child: AppSceneBackdrop()),
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
                    final midY = size.height / 2;
                    final pixelsPerMeter =
                        size.width / metersPerScreenWidthFor(_journeyId);

                    // The real traveler, in the same world-space every
                    // achievement marker uses (class doc comment) — it does
                    // not read _panMeters at all, so rewinding the view never
                    // moves it, only changes where on screen it lands.
                    final solidX =
                        centerX +
                        (_progressMeters - _panMeters) * pixelsPerMeter;
                    final solidY = _wavyPathY(
                      meters: _progressMeters.toDouble(),
                      pixelsPerMeter: pixelsPerMeter,
                      midY: midY,
                    );

                    // The rewind ghost — always screen-centred, since "what's
                    // currently centred" is exactly what it stands for.
                    final ghostY = _wavyPathY(
                      meters: _panMeters,
                      pixelsPerMeter: pixelsPerMeter,
                      midY: midY,
                    );
                    // Hidden once it would coincide with the solid marker
                    // (currently looking at `You`) — a pixel threshold, not
                    // a meters one, so it holds regardless of this quest's
                    // own meters-per-pixel scale.
                    final showGhost = (solidX - centerX).abs() > 1.0;

                    // Each visible marker's screen x, resolved once and shared
                    // by both the marker widget below and the painter's guide
                    // line (this task's requirement — a faint dotted line from
                    // each trophy down to the wavy path, quest-map parity,
                    // §6.2) — computing it twice would risk the two drifting
                    // apart on a future change to either loop.
                    final visibleAchievements = [
                      for (final state in achievementStates)
                        if (state.def.thresholdMeters <= _totalMeters)
                          (
                            state: state,
                            x:
                                centerX +
                                (state.def.thresholdMeters - _panMeters) *
                                    pixelsPerMeter,
                          ),
                    ];

                    return Stack(
                      children: [
                        CustomPaint(
                          key: const Key('journeyPathScene'),
                          size: size,
                          painter: _WavyPathPainter(
                            midY: midY,
                            totalMeters: _totalMeters,
                            panMeters: _panMeters,
                            pixelsPerMeter: pixelsPerMeter,
                            centerX: centerX,
                            markerGuides: [
                              for (final m in visibleAchievements)
                                (
                                  x: m.x,
                                  thresholdMeters: m.state.def.thresholdMeters,
                                ),
                            ],
                          ),
                        ),
                        for (final m in visibleAchievements)
                          _AchievementMarker(
                            key: Key('achievementMarker-${m.state.def.id}'),
                            state: m.state,
                            l10n: l10n,
                            x: m.x,
                          ),
                        if (showGhost)
                          _TravelerMarker(
                            key: const Key('travelerGhost'),
                            x: centerX,
                            y: ghostY,
                            solid: false,
                          ),
                        _TravelerMarker(
                          key: const Key('travelerSolid'),
                          x: solidX,
                          y: solidY,
                          solid: true,
                        ),
                        // Only while rewound away from You — once the ghost
                        // is gone there is nowhere left to jump back to
                        // (this task's requirement).
                        if (showGhost)
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
      ],
    );
  }
}

/// Size of the traveler icon, in logical pixels.
const double _travelerIconSize = 32;

/// How far the placeholder wave rises and falls from its vertical centre,
/// in pixels.
const double _waveAmplitude = 36;

/// Route distance, in pixels at the quest's own meters-per-pixel scale
/// (`meters * pixelsPerMeter` — see [_wavyPathY]), over which the
/// placeholder wave completes one full up-down cycle.
const double _waveWavelength = 260;

/// Height of the placeholder wavy path at route position [meters] (from
/// point A), given the quest's current pixels-per-meter scale
/// ([pixelsPerMeter]) and the scene's vertical centre ([midY]).
///
/// Deliberately a function of the *route position*, not of screen x or how
/// far the view has been panned: panning changes which meters are on
/// screen, never the elevation the terrain has at a given meter. That's
/// what makes the line read as fixed hills the camera pans across —
/// "человек поднимается и спускается по линии" — rather than a pattern
/// that slides and rescales as you drag (an earlier version keyed the
/// phase off `x - panOffset`, screen-space quantities that both shift with
/// `panMeters`, so the same route point rendered at a different height
/// after every pan — a bug this signature makes impossible to reintroduce).
///
/// Shared by the painter (draws the line) and both traveler markers (each
/// passes its own route meters directly — [_progressMeters] for the solid
/// one, [_panMeters] for the ghost — see [_JourneyPathViewState.build]) —
/// there is exactly one function that knows the shape of this curve, so
/// the three can never drift apart. Achievement markers deliberately do
/// *not* read this — they live in their own layer pinned to
/// [_markersLayerTop] instead (this task's requirement).
double _wavyPathY({
  required double meters,
  required double pixelsPerMeter,
  required double midY,
}) {
  final worldX = meters * pixelsPerMeter;
  final phase = worldX / _waveWavelength * 2 * math.pi;
  return midY + _waveAmplitude * math.sin(phase);
}

/// Size of the rewind ghost, relative to [_travelerIconSize] — smaller and
/// visibly behind the solid marker, not a same-size twin.
const double _travelerGhostScale = 0.85;

/// Opacity of the rewind ghost's outline — faint enough to read as "a
/// memory of a position", not a second real traveler.
const double _travelerGhostOpacity = 0.45;

/// One traveler figure on the scene — either the real, current position
/// ([solid] `true`, opaque gold, [_travelerIconSize]) or the rewind ghost
/// ([solid] `false`, a smaller, dim, hollow echo showing an earlier
/// position the view has rewound to; class doc comment on
/// [_JourneyPathViewState]). Both use the same glyph — it is the same
/// figure either way, just "real" versus "a shadow of where he was".
class _TravelerMarker extends StatelessWidget {
  const _TravelerMarker({
    super.key,
    required this.x,
    required this.y,
    required this.solid,
  });

  final double x;
  final double y;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final size = solid
        ? _travelerIconSize
        : _travelerIconSize * _travelerGhostScale;
    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: IgnorePointer(
        // Same glyph either way (class doc comment) — only color, opacity
        // and size tell the real traveler and the rewind ghost apart.
        child: Icon(
          Icons.directions_walk,
          color: solid
              ? AppColors.gold
              : AppColors.textSecondary.withValues(
                  alpha: _travelerGhostOpacity,
                ),
          size: size,
        ),
      ),
    );
  }
}

/// Diameter of [_ReturnToYouButton], in logical pixels — small, per this
/// task's own request, not a full anchor bar (§6.1's eventual `< Start`/
/// `You >` pair is a separate, later addition).
const double _returnToYouButtonSize = 36;

/// Icon size inside [_ReturnToYouButton], in logical pixels.
const double _returnToYouIconSize = 18;

/// The small "jump back to You" button (this task's requirement) — shown
/// only while [_JourneyPathViewState] is rewound away from the real
/// position ([_JourneyPathViewState.build]'s `showGhost`). A round gold-
/// bordered button rather than a text pill, so it reads as a map/compass
/// "recenter" control instead of competing with the achievement markers'
/// own icon language.
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
            width: _returnToYouButtonSize,
            height: _returnToYouButtonSize,
            child: Icon(
              Icons.my_location,
              color: AppColors.gold,
              size: _returnToYouIconSize,
            ),
          ),
        ),
      ),
    );
  }
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

/// Where a trophy's guide line starts, in logical pixels from the top of
/// the scene — just under the marker icon itself
/// ([_markersLayerTop] + [_markerIconSize]), so the dotted line reads as
/// hanging from the icon rather than starting mid-air above or clipping
/// through it (`_WavyPathPainter._paintMarkerGuide`, this task's
/// requirement).
const double _markerGuideStartY = _markersLayerTop + _markerIconSize;

/// Dash length of a trophy's guide line, in logical pixels — same value as
/// `quest_map_view.dart`'s `_trophyDashLength` (§6.2 visual parity).
const double _markerGuideDashLength = 3;

/// Gap length between dashes of a trophy's guide line, in logical pixels —
/// same value as `quest_map_view.dart`'s `_trophyDashGap`.
const double _markerGuideDashGap = 3;

/// Shows a marker's name and status (this task's requirement — "details on
/// tap only") in a bottom sheet, following the same shape every other sheet
/// in this app uses (see `settings_tab.dart`'s
/// `_showLockScreenTroubleshootSheet`): title,
/// then status line, dismissible by the sheet's own default swipe-down/
/// tap-outside gesture — no bespoke close button, since adding one needs a
/// new l10n key and this change didn't add one.
///
/// `useRootNavigator: true` (styling fix — regression): the Путь tab is one
/// `StatefulShellBranch` of `router.dart`'s `StatefulShellRoute.indexedStack`,
/// each with its own nested `Navigator`. The default `useRootNavigator:
/// false` attaches the sheet to *that* nested Navigator, whose branch stays
/// mounted (just not painted) when another tab is selected — so the sheet
/// never got told to close on a tab switch and stayed up over whatever tab
/// the user switched to. Pinning it to the single shared root Navigator
/// instead lets `AppShell`'s bottom-nav tap handler close it explicitly by
/// popping that same Navigator (`app_shell.dart`).
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

class _WavyPathPainter extends CustomPainter {
  const _WavyPathPainter({
    required this.midY,
    required this.totalMeters,
    required this.panMeters,
    required this.pixelsPerMeter,
    required this.centerX,
    required this.markerGuides,
  });

  final double midY;

  /// The route's full length in meters — the line is drawn only across
  /// `[0, totalMeters]`; it does not exist before point A or after point B
  /// (this task's requirement: "a line with a start and an end").
  final int totalMeters;

  /// The route position, in meters, currently centered at [centerX].
  final double panMeters;
  final double pixelsPerMeter;
  final double centerX;

  /// Every visible achievement marker's already-resolved screen `x`
  /// (`_JourneyPathViewState.build`'s `visibleAchievements`) paired with
  /// its own route position — lets [_paintMarkerGuide] find where the wavy
  /// line sits at that same route meter, independently of `x` (this task's
  /// requirement: "линия от кубка... до линии, по которой движется
  /// человек" — quest-map's own trophy guide, `quest_map_view.dart`'s
  /// `_RouteOverlayPainter._paintTrophy`, drawn here too).
  final List<({double x, int thresholdMeters})> markerGuides;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.backgroundElevated,
    );

    // Painted before the early-return below (unreachable in practice — see
    // that check's own math — but guides shouldn't depend on it holding):
    // a marker's guide is independent of whether the wavy path itself has
    // any on-screen extent this frame.
    for (final guide in markerGuides) {
      _paintMarkerGuide(canvas, size, guide);
    }

    // The line only exists between point A (0 m) and point B (totalMeters);
    // convert those two route bounds to screen x once, then clip drawing to
    // whichever part of that span is actually on screen.
    final startX = centerX - panMeters * pixelsPerMeter;
    final endX = centerX + (totalMeters - panMeters) * pixelsPerMeter;
    final left = math.max(0.0, startX);
    final right = math.min(size.width, endX);
    if (right <= left) return; // point A and point B are both off-screen.

    // Screen x -> route meters, the inverse of how the caller placed left/
    // right above — this is what lets [_wavyPathY] key its phase off the
    // route position instead of the screen position (see its doc comment).
    double metersAtX(double x) => panMeters + (x - centerX) / pixelsPerMeter;

    final path = Path()
      ..moveTo(
        left,
        _wavyPathY(
          meters: metersAtX(left),
          pixelsPerMeter: pixelsPerMeter,
          midY: midY,
        ),
      );
    // A few pixels per segment reads as smooth without evaluating sin() at
    // every physical pixel.
    const step = 4.0;
    for (var x = left + step; x <= right; x += step) {
      path.lineTo(
        x,
        _wavyPathY(
          meters: metersAtX(x),
          pixelsPerMeter: pixelsPerMeter,
          midY: midY,
        ),
      );
    }
    path.lineTo(
      right,
      _wavyPathY(
        meters: metersAtX(right),
        pixelsPerMeter: pixelsPerMeter,
        midY: midY,
      ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.path,
    );
  }

  /// A faint dotted line from just under a trophy's icon
  /// ([_markerGuideStartY]) down to the exact point on the wavy path
  /// belonging to [guide]'s own route meters — mirrors
  /// `quest_map_view.dart`'s `_RouteOverlayPainter._paintTrophy`/
  /// `_paintDottedLine` (§6.2's "неяркая приглушённая пунктирная
  /// линия-указатель"), applied here for the first time (this task's
  /// requirement). Skipped once [guide]'s `x` is off-screen — cheap to
  /// check, and avoids painting dashes nobody can see while a drag has
  /// carried a marker far past either edge.
  void _paintMarkerGuide(
    Canvas canvas,
    Size size,
    ({double x, int thresholdMeters}) guide,
  ) {
    if (guide.x < 0 || guide.x > size.width) return;

    final lineY = _wavyPathY(
      meters: guide.thresholdMeters.toDouble(),
      pixelsPerMeter: pixelsPerMeter,
      midY: midY,
    );
    final from = Offset(guide.x, _markerGuideStartY);
    final to = Offset(guide.x, lineY);

    final paint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final total = (to - from).distance;
    if (total <= 0) return;
    final direction = (to - from) / total;

    var traveled = 0.0;
    while (traveled < total) {
      final segmentEnd = math.min(traveled + _markerGuideDashLength, total);
      canvas.drawLine(
        from + direction * traveled,
        from + direction * segmentEnd,
        paint,
      );
      traveled += _markerGuideDashLength + _markerGuideDashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _WavyPathPainter oldDelegate) =>
      oldDelegate.midY != midY ||
      oldDelegate.totalMeters != totalMeters ||
      oldDelegate.panMeters != panMeters ||
      oldDelegate.pixelsPerMeter != pixelsPerMeter ||
      oldDelegate.centerX != centerX ||
      // markerGuides is rebuilt fresh every `build()` (same idiom
      // quest_map_view.dart's `trophyStates` check uses) — the values
      // above already cover every input it's derived from, this just
      // guards a future change that adds one that isn't.
      !identical(oldDelegate.markerGuides, markerGuides);
}
