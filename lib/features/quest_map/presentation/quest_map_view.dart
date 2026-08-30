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
import '../../journey/domain/quest_time_service.dart';
import '../data/quest_map_repository.dart';
import '../domain/route_mapping.dart';
import 'quest_map_providers.dart';

/// The drawn quest map of §6.2: the illustration and the traveler's own
/// position on the route traced in `map.json`.
///
/// The continuous route line itself is never drawn — the traveler moves
/// along it invisibly, so the only thing marking where they are is the
/// helmet itself, not a line leading up to it. Landmarks are marked the
/// same way. Trophies (§6.3's achievements, evaluated here against
/// [progressMeters]) are the one exception: each sits just above its own
/// route point, connected to it by a short, faint dotted guide — locked
/// ones muted and small, unlocked ones gold and visibly bigger
/// (`_RouteOverlayPainter._paintTrophy`) — but that guide only ever spans
/// the gap between one trophy and its own point, never the route between
/// two trophies or landmarks. Tapping the traveler or a landmark shows a
/// small tooltip with its stats (§6.2's "interactive hotspots"); tapping
/// empty space, or the same marker again, dismisses it — trophies are
/// display-only here, the Трофеи tab (§6.3) is where their own detail
/// lives. Pan and zoom come from [InteractiveViewer]; nothing here touches
/// the network, the map is a bundled asset and the screen works fully
/// offline (§6.2, §8).
class QuestMapView extends ConsumerWidget {
  const QuestMapView({
    super.key,
    required this.progressMeters,
    required this.startedAt,
  });

  /// How far along the quest the traveler is, in meters.
  final int progressMeters;

  /// When the quest started — needed for the traveler's tapped-open stat
  /// bubble, which shows the quest day alongside the distance.
  final DateTime startedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final assets = ref.watch(selectedQuestMapProvider);

    return assets.when(
      loading: () => const _MapFrame(
        aspectRatio: _fallbackAspectRatio,
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (_, _) => _MapNotice(text: l10n.questMapLoadFailed),
      data: (loaded) {
        if (loaded == null) return const SizedBox.shrink();
        return _LoadedMap(
          assets: loaded,
          progressMeters: progressMeters,
          startedAt: startedAt,
          l10n: l10n,
        );
      },
    );
  }
}

/// Shape of the frame before the real map's own ratio is known.
const double _fallbackAspectRatio = 2 / 3;

class _LoadedMap extends StatefulWidget {
  const _LoadedMap({
    required this.assets,
    required this.progressMeters,
    required this.startedAt,
    required this.l10n,
  });

  final QuestMapAssets assets;
  final int progressMeters;
  final DateTime startedAt;
  final AppLocalizations l10n;

  @override
  State<_LoadedMap> createState() => _LoadedMapState();
}

/// How close a tap has to land to a marker's center to select it, in
/// logical pixels — generous enough for a touch target well under the
/// marker's own visible halo.
const double _tapTargetRadius = 22;

class _LoadedMapState extends State<_LoadedMap> {
  /// Whether the traveler's own stat bubble is open. Mutually exclusive
  /// with [_selectedLandmark] — only one tooltip shows at a time.
  bool _travelerSelected = false;

  /// The landmark whose distance tooltip is open, or `null` if none is.
  MapLandmark? _selectedLandmark;

  void _handleTap(TapUpDetails details, QuestMap map, Size size) {
    Offset toOffset(MapPoint point) =>
        Offset(point.x * size.width, point.y * size.height);
    final tapped = details.localPosition;

    var closestDistance = _tapTargetRadius;
    var hitTraveler = false;
    MapLandmark? hitLandmark;

    final travelerAt = toOffset(
      metersToPoint(map.polyline, widget.progressMeters),
    );
    final travelerDistance = (tapped - travelerAt).distance;
    if (travelerDistance <= closestDistance) {
      closestDistance = travelerDistance;
      hitTraveler = true;
    }
    for (final landmark in map.landmarks) {
      final at = toOffset(MapPoint(x: landmark.x, y: landmark.y));
      final distance = (tapped - at).distance;
      // Strictly closer, not <=: early in the quest the traveler can sit
      // exactly on top of a landmark (progress 0 at Troy, the route's own
      // start), and a tie should stay with whichever was found first — the
      // traveler, checked above — not flip to the landmark checked last.
      if (distance < closestDistance) {
        closestDistance = distance;
        hitTraveler = false;
        hitLandmark = landmark;
      }
    }

    setState(() {
      if (hitTraveler) {
        final wasOpen = _travelerSelected;
        _selectedLandmark = null;
        _travelerSelected = !wasOpen;
      } else if (hitLandmark != null) {
        final wasOpen = _selectedLandmark == hitLandmark;
        _travelerSelected = false;
        _selectedLandmark = wasOpen ? null : hitLandmark;
      } else {
        _travelerSelected = false;
        _selectedLandmark = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.assets.map;
    final upcoming = nextLandmark(map, widget.progressMeters);
    final travelerPoint = metersToPoint(map.polyline, widget.progressMeters);
    final l10n = widget.l10n;
    // Every achievement is a distance along this same route (§6.3's
    // `AchievementKind` — both variants use `thresholdMeters` as a route
    // position), so each one has a real point on the drawn map via the
    // same `metersToPoint` the traveler and landmarks use — the guide-line
    // painter below relies on that. The `<= map.totalMeters` guard mirrors
    // `journey_path_view.dart`'s own filter: a future quest with a
    // shorter route should never render a trophy for a distance it
    // doesn't have.
    final trophyStates = evaluateAchievements(
      progressMeters: widget.progressMeters,
      catalog: achievementCatalog,
    ).where((state) => state.def.thresholdMeters <= map.totalMeters).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MapFrame(
          aspectRatio: map.imageWidth / map.imageHeight,
          child: InteractiveViewer(
            maxScale: 5,
            clipBehavior: Clip.hardEdge,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                return GestureDetector(
                  // Opaque so a tap on empty water (nothing painted there)
                  // still reaches this handler and dismisses an open
                  // tooltip, not just taps that land on a marker.
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTap(details, map, size),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.assets.hasIllustration)
                        // BoxFit.fill, not cover: the frame already carries
                        // the illustration's own aspect ratio, and filling
                        // it is what keeps every normalized (0..1)
                        // coordinate in `map.json` landing on the spot it
                        // was traced from.
                        Image.asset(map.imageAsset, fit: BoxFit.fill)
                      else
                        const ColoredBox(color: AppColors.backgroundElevated),
                      Semantics(
                        // A node of its own: the markers it describes are
                        // painted, so there is no child semantics for a
                        // label to annotate.
                        container: true,
                        label: l10n.questMapYouAreHere,
                        child: CustomPaint(
                          key: const Key('questMapRouteOverlay'),
                          painter: _RouteOverlayPainter(
                            polyline: map.polyline,
                            landmarks: map.landmarks,
                            trophyStates: trophyStates,
                            progressMeters: widget.progressMeters,
                          ),
                        ),
                      ),
                      if (_travelerSelected)
                        _MapTooltip(
                          key: const Key('questMapTravelerTooltip'),
                          x: travelerPoint.x,
                          y: travelerPoint.y,
                          child: _TravelerStats(
                            startedAt: widget.startedAt,
                            progressMeters: widget.progressMeters,
                            l10n: l10n,
                          ),
                        )
                      else if (_selectedLandmark case final landmark?)
                        _MapTooltip(
                          key: const Key('questMapLandmarkTooltip'),
                          x: landmark.x,
                          y: landmark.y,
                          child: _LandmarkDistance(
                            landmark: landmark,
                            progressMeters: widget.progressMeters,
                            l10n: l10n,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!widget.assets.hasIllustration) ...[
          Text(
            l10n.questMapIllustrationMissing,
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          upcoming == null
              ? l10n.questMapAllLandmarksReached
              : l10n.questMapNextLandmark(
                  // Landmark names are quest data, not UI copy — same
                  // treatment as point A/B (§11).
                  upcoming.name,
                  localizedDistanceInline(
                    l10n,
                    formatDistance(upcoming.meters - widget.progressMeters),
                  ),
                ),
          style: AppTypography.bodySecondary,
        ),
      ],
    );
  }
}

/// Floats [child] above the normalized `(x, y)` map point it's anchored to
/// — [Align] maps that same `0..1` space the painter uses to `-1..1`
/// alignment, and [FractionalTranslation] then lifts the tooltip up by its
/// own height (plus a little extra) so it sits above the marker rather than
/// centered on it, whatever size its content turns out to be.
class _MapTooltip extends StatelessWidget {
  const _MapTooltip({
    super.key,
    required this.x,
    required this.y,
    required this.child,
  });

  final double x;
  final double y;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment(x * 2 - 1, y * 2 - 1),
        child: FractionalTranslation(
          translation: const Offset(0, -1.15),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.gold, width: AppStroke.icon),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TravelerStats extends StatelessWidget {
  const _TravelerStats({
    required this.startedAt,
    required this.progressMeters,
    required this.l10n,
  });

  final DateTime startedAt;
  final int progressMeters;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final day = questTimeService.questDay(
      startedAt: startedAt,
      now: DateTime.now(),
    );
    final distance = formatDistance(progressMeters);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(l10n.journeyDayCounter(day), style: AppTypography.label),
        Text(
          localizedDistanceInline(l10n, distance),
          style: AppTypography.body,
        ),
      ],
    );
  }
}

class _LandmarkDistance extends StatelessWidget {
  const _LandmarkDistance({
    required this.landmark,
    required this.progressMeters,
    required this.l10n,
  });

  final MapLandmark landmark;
  final int progressMeters;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final diff = landmark.meters - progressMeters;
    final text = diff > 0
        ? l10n.questMapNextLandmark(
            landmark.name,
            localizedDistanceInline(l10n, formatDistance(diff)),
          )
        : l10n.questMapLandmarkBehindCaption(
            landmark.name,
            localizedDistanceInline(l10n, formatDistance(-diff)),
          );

    return Text(
      text,
      style: AppTypography.bodySecondary,
      textAlign: TextAlign.center,
    );
  }
}

class _MapFrame extends StatelessWidget {
  const _MapFrame({required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: ColoredBox(
        color: AppColors.backgroundElevated,
        child: AspectRatio(aspectRatio: aspectRatio, child: child),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(text, style: AppTypography.bodySecondary),
    );
  }
}

/// Emoji standing in for each landmark on the map, keyed by
/// [MapLandmark.id] — a small piece of presentation styling, not quest
/// content, so it lives here rather than in `map.json` (§11: the id itself
/// is the stable, content-authored key; what glyph represents it on this
/// screen is a display decision). An id this map doesn't know about (a
/// future quest's landmarks) falls back to [_defaultLandmarkEmoji] rather
/// than throwing — new quest content should never crash the map.
const Map<String, String> _landmarkEmoji = {
  'troy': '🏛️',
  'aeaea-circe': '🐖', // Circe turns Odysseus's crew into pigs.
  'lotus-eaters': '🪷',
  'calypso': '🏝️',
  'scylla-charybdis': '🌀',
  'sirens': '🧜‍♀️',
  'ithaca': '🏠',
};
const String _defaultLandmarkEmoji = '📍';

/// The emoji marker for one landmark id. Exposed at the top level (rather
/// than folded straight into the painter) so the mapping itself — every
/// shipped id resolves to something, the fallback pin catches the rest —
/// has a unit test that doesn't need a canvas.
@visibleForTesting
String emojiForLandmarkId(String landmarkId) =>
    _landmarkEmoji[landmarkId] ?? _defaultLandmarkEmoji;

/// Font size of a landmark's emoji marker, in logical pixels.
const double _landmarkEmojiSize = 16;

/// Radius of the dark halo painted behind a landmark emoji, so it stays
/// legible over both the pale ink lines and the black background.
const double _landmarkHaloRadius = 11;

/// On-screen height, in logical pixels, of the traveler's helmet marker
/// (crest included) — [_travelerHelmetBounds] gives its shape in local
/// units, this is what that gets scaled to.
const double _travelerIconHeight = 20;

/// Font size of a locked trophy's icon, in logical pixels.
const double _trophyLockedSize = 16;

/// Font size of an unlocked trophy's icon — visibly bigger than
/// [_trophyLockedSize], not only a different color (§6.3: "получен —
/// должен быть чуть крупнее").
const double _trophyUnlockedSize = 20;

/// Vertical distance from a trophy's icon down to its route point, in
/// logical pixels — how far "above the line" the trophy sits (§6.2).
const double _trophyLineHeight = 26;

/// Dash length of a trophy's guide line, in logical pixels.
const double _trophyDashLength = 3;

/// Gap length between dashes of a trophy's guide line, in logical pixels.
const double _trophyDashGap = 3;

/// Paints the traveler's position, every landmark, and every trophy's guide
/// line on the drawn map — **not** the route between them (§6.2: the path
/// is deliberately invisible; the traveler moves along it, nothing draws
/// it). Marker positions still come straight from the same route math
/// ([metersToPoint]) either way, so hiding the line changes nothing about
/// where the markers land.
class _RouteOverlayPainter extends CustomPainter {
  const _RouteOverlayPainter({
    required this.polyline,
    required this.landmarks,
    required this.trophyStates,
    required this.progressMeters,
  });

  final RoutePolyline polyline;
  final List<MapLandmark> landmarks;

  /// Every achievement whose route position fits this map, evaluated
  /// against [progressMeters] — `_LoadedMapState.build`'s own filter and
  /// evaluator (§6.3), not recomputed here.
  final List<AchievementState> trophyStates;
  final int progressMeters;

  @override
  void paint(Canvas canvas, Size size) {
    Offset toOffset(MapPoint point) =>
        Offset(point.x * size.width, point.y * size.height);

    for (final landmark in landmarks) {
      _paintLandmark(
        canvas,
        toOffset(MapPoint(x: landmark.x, y: landmark.y)),
        landmark,
      );
    }

    for (final state in trophyStates) {
      _paintTrophy(
        canvas,
        toOffset(metersToPoint(polyline, state.def.thresholdMeters)),
        state,
      );
    }

    final here = toOffset(metersToPoint(polyline, progressMeters));
    _paintTraveler(canvas, here);
  }

  void _paintLandmark(Canvas canvas, Offset at, MapLandmark landmark) {
    canvas.drawCircle(
      at,
      _landmarkHaloRadius,
      Paint()..color = AppColors.background.withValues(alpha: 0.55),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: emojiForLandmarkId(landmark.id),
        style: const TextStyle(fontSize: _landmarkEmojiSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  /// Paints one trophy above its route position, plus the faint dotted
  /// guide line down to the exact point on the route it belongs to (§6.2:
  /// "от каждого трофея сверху... вниз до самой линии") — [at] is that
  /// route point, already converted to screen space by [paint]; the
  /// trophy icon itself sits [_trophyLineHeight] px above it.
  ///
  /// Unlocked trophies (§6.3, same rule `achievements_tab.dart` and
  /// `journey_path_view.dart`'s markers use) render gold and
  /// [_trophyUnlockedSize] — visibly bigger than a locked one's muted,
  /// smaller [_trophyLockedSize] — rather than only a color swap.
  void _paintTrophy(Canvas canvas, Offset at, AchievementState state) {
    final above = at - const Offset(0, _trophyLineHeight);
    _paintDottedLine(canvas, above, at);

    final size = state.unlocked ? _trophyUnlockedSize : _trophyLockedSize;
    final color = state.unlocked ? AppColors.gold : AppColors.textSecondary;
    final icon = state.unlocked
        ? Icons.emoji_events
        : Icons.emoji_events_outlined;

    canvas.drawCircle(
      above,
      size / 2 + 3,
      Paint()..color = AppColors.background.withValues(alpha: 0.55),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      above - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// A faint, dim dotted stroke from [from] to [to] — deliberately unlike
  /// every other line this painter draws (all solid), so a trophy's guide
  /// reads as a pointer, not as part of the route itself (§6.2: the route
  /// line is still never drawn).
  void _paintDottedLine(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final total = (to - from).distance;
    if (total <= 0) return;
    final direction = (to - from) / total;

    var traveled = 0.0;
    while (traveled < total) {
      final segmentEnd = math.min(traveled + _trophyDashLength, total);
      canvas.drawLine(
        from + direction * traveled,
        from + direction * segmentEnd,
        paint,
      );
      traveled += _trophyDashLength + _trophyDashGap;
    }
  }

  /// Paints the traveler's position as a small gold Corinthian-helmet
  /// silhouette (front view: a domed shield with the T-shaped eye/nose
  /// slit and a low crest ridge) instead of a plain dot, on a dark halo so
  /// it stays readable over the ink drawing.
  void _paintTraveler(Canvas canvas, Offset at) {
    final bounds = _travelerHelmetBounds;
    final scale = _travelerIconHeight / bounds.height;
    final origin = at - Offset(bounds.center.dx, bounds.center.dy) * scale;

    canvas.drawCircle(
      at,
      bounds.longestSide * scale / 2 + 3,
      Paint()..color = AppColors.background.withValues(alpha: 0.7),
    );

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    final gold = Paint()..color = AppColors.gold;
    canvas.drawPath(_travelerHelmetCrest, gold);
    canvas.drawPath(_travelerHelmetDome, gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RouteOverlayPainter oldDelegate) =>
      oldDelegate.progressMeters != progressMeters ||
      oldDelegate.polyline != polyline ||
      // landmarks comes from the same immutable QuestMap.landmarks list for
      // the life of a loaded map — reference inequality is enough to catch
      // the one case that matters, a freshly (re)loaded map.
      !identical(oldDelegate.landmarks, landmarks) ||
      // trophyStates is recomputed by `_LoadedMapState.build` on every
      // build (it depends on progressMeters, already covered above, so
      // this only catches a rebuild where progress didn't change but the
      // list identity still did — cheap, and correct either way since
      // AchievementState is a value type).
      !identical(oldDelegate.trophyStates, trophyStates);
}

/// The helmet's dome + T-slit, in a local coordinate box (front view, eyes
/// and nose exposed through the slit). [PathFillType.evenOdd] cuts the two
/// slit rectangles out of the dome — one fill call paints gold everywhere
/// except the slit.
final Path _travelerHelmetDome = () {
  final path = Path()
    ..moveTo(14, 1)
    ..cubicTo(20, 1, 25, 4, 25, 10)
    ..lineTo(23, 20)
    ..cubicTo(23, 23.5, 20, 26, 16, 26)
    ..lineTo(12, 26)
    ..cubicTo(8, 26, 5, 23.5, 5, 20)
    ..lineTo(3, 10)
    ..cubicTo(3, 4, 8, 1, 14, 1)
    ..close();
  path.fillType = PathFillType.evenOdd;
  path.addRect(const Rect.fromLTRB(6.5, 10.5, 21.5, 13.5)); // eye bar
  path.addRect(const Rect.fromLTRB(12.5, 10.5, 15.5, 26)); // nose guard
  return path;
}();

/// The low crest ridge sitting on top of [_travelerHelmetDome], in the same
/// local coordinate box — the detail that reads as "Corinthian" rather than
/// a plain dome, even at marker size.
final Path _travelerHelmetCrest = () {
  return Path()
    ..moveTo(8, 1.5)
    ..quadraticBezierTo(14, -5, 20, 1.5)
    ..quadraticBezierTo(14, -1.5, 8, 1.5)
    ..close();
}();

/// Bounding box of the dome + crest together, in the same local units —
/// what [_paintTraveler] scales to [_travelerIconHeight] and centers on the
/// traveler's map point.
final Rect _travelerHelmetBounds = _travelerHelmetDome
    .getBounds()
    .expandToInclude(_travelerHelmetCrest.getBounds());
