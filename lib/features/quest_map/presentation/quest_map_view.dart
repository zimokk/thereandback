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

/// Radius of the gold dot marking the traveler, in logical pixels.
const double _travelerDotRadius = 5.5;

/// Radius of the thin ring drawn around that dot.
const double _travelerRingRadius = 10;

/// Dash and gap lengths of the not-yet-walked stretch, in logical pixels.
const double _dashLength = 6;
const double _dashGap = 5;

class _RouteOverlayPainter extends CustomPainter {
  const _RouteOverlayPainter({
    required this.polyline,
    required this.progressMeters,
  });

  final RoutePolyline polyline;
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

    final here = toOffset(metersToPoint(polyline, progressMeters));
    // A dark disc under the marker so it stays readable wherever it lands
    // on the ink drawing.
    canvas.drawCircle(
      here,
      _travelerRingRadius - 1,
      Paint()..color = AppColors.background.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      here,
      _travelerDotRadius,
      Paint()..color = AppColors.gold,
    );
    canvas.drawCircle(
      here,
      _travelerRingRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.icon
        ..color = AppColors.gold.withValues(alpha: 0.7),
    );
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
      oldDelegate.polyline != polyline;
}
