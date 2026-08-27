import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/quest_map_repository.dart';
import '../domain/route_mapping.dart';
import 'quest_map_providers.dart';

/// The drawn quest map of §6.2: the illustration, the route traced over it
/// from `map.json`, and the traveler's own position on that line.
///
/// The route is split at the walked distance — solid gold behind the
/// traveler, dashed ahead of them — so the position reads as a point on the
/// path, not a pin floating over the art. Pan and zoom come from
/// [InteractiveViewer]; nothing here touches the network, the map is a
/// bundled asset and the screen works fully offline (§6.2, §8).
class QuestMapView extends ConsumerWidget {
  const QuestMapView({super.key, required this.progressMeters});

  /// How far along the quest the traveler is, in meters.
  final int progressMeters;

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
          l10n: l10n,
        );
      },
    );
  }
}

/// Shape of the frame before the real map's own ratio is known.
const double _fallbackAspectRatio = 2 / 3;

class _LoadedMap extends StatelessWidget {
  const _LoadedMap({
    required this.assets,
    required this.progressMeters,
    required this.l10n,
  });

  final QuestMapAssets assets;
  final int progressMeters;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final map = assets.map;
    final upcoming = nextLandmark(map, progressMeters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MapFrame(
          aspectRatio: map.imageWidth / map.imageHeight,
          child: InteractiveViewer(
            maxScale: 5,
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (assets.hasIllustration)
                  // BoxFit.fill, not cover: the frame already carries the
                  // illustration's own aspect ratio, and filling it is what
                  // keeps every normalized (0..1) coordinate in `map.json`
                  // landing on the spot it was traced from.
                  Image.asset(map.imageAsset, fit: BoxFit.fill)
                else
                  const ColoredBox(color: AppColors.backgroundElevated),
                Semantics(
                  // A node of its own: the marker it describes is painted,
                  // so there is no child semantics for a label to annotate.
                  container: true,
                  label: l10n.questMapYouAreHere,
                  child: CustomPaint(
                    key: const Key('questMapRouteOverlay'),
                    painter: _RouteOverlayPainter(
                      polyline: map.polyline,
                      landmarks: map.landmarks,
                      progressMeters: progressMeters,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!assets.hasIllustration) ...[
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
                    formatDistance(upcoming.meters - progressMeters),
                  ),
                ),
          style: AppTypography.bodySecondary,
        ),
      ],
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

/// Dash and gap lengths of the not-yet-walked stretch, in logical pixels.
const double _dashLength = 6;
const double _dashGap = 5;

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

class _RouteOverlayPainter extends CustomPainter {
  const _RouteOverlayPainter({
    required this.polyline,
    required this.landmarks,
    required this.progressMeters,
  });

  final RoutePolyline polyline;
  final List<MapLandmark> landmarks;
  final int progressMeters;

  @override
  void paint(Canvas canvas, Size size) {
    Offset toOffset(MapPoint point) =>
        Offset(point.x * size.width, point.y * size.height);

    final split = splitRouteAt(polyline, progressMeters);
    final ahead = split.remaining.map(toOffset).toList(growable: false);
    final behind = split.walked.map(toOffset).toList(growable: false);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      _dashed(ahead),
      line
        ..color = AppColors.gold.withValues(alpha: 0.5)
        ..strokeWidth = AppStroke.path,
    );
    canvas.drawPath(
      _polylinePath(behind),
      line
        ..color = AppColors.gold
        ..strokeWidth = AppStroke.path + 1,
    );

    for (final landmark in landmarks) {
      _paintLandmark(
        canvas,
        toOffset(MapPoint(x: landmark.x, y: landmark.y)),
        landmark,
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

  Path _polylinePath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  /// The same polyline, cut into dashes — [Path] has no dash support, and a
  /// dashed stretch is what §6.2 asks for ahead of the traveler.
  Path _dashed(List<Offset> points) {
    final path = Path();
    var drawing = true;
    var remainingInDash = _dashLength;

    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final length = (end - start).distance;
      // Two vertices traced onto the same spot: nothing to dash.
      if (length == 0) continue;
      final direction = (end - start) / length;

      var walked = 0.0;
      while (walked < length) {
        final step = math.min(length - walked, remainingInDash);
        if (drawing) {
          final from = start + direction * walked;
          final to = start + direction * (walked + step);
          path
            ..moveTo(from.dx, from.dy)
            ..lineTo(to.dx, to.dy);
        }
        walked += step;
        remainingInDash -= step;
        if (remainingInDash <= 0) {
          drawing = !drawing;
          remainingInDash = drawing ? _dashLength : _dashGap;
        }
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _RouteOverlayPainter oldDelegate) =>
      oldDelegate.progressMeters != progressMeters ||
      oldDelegate.polyline != polyline ||
      // landmarks comes from the same immutable QuestMap.landmarks list for
      // the life of a loaded map — reference inequality is enough to catch
      // the one case that matters, a freshly (re)loaded map.
      !identical(oldDelegate.landmarks, landmarks);
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
