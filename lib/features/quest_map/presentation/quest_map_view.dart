import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../friends/domain/friend_progress.dart';
import '../../friends/presentation/friend_pin_color.dart';
import '../../friends/presentation/friends_providers.dart';
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
/// same way. Trophies (§6.3's achievements) are **not** shown here (styling
/// fix — this screen used to also paint each one above the route with a
/// dotted guide line down to it; that cluttered the drawn map without
/// adding anything the Трофеи tab's own grid, `achievements_tab.dart`,
/// doesn't already show better — that tab is the only place a trophy's own
/// detail lives now). Tapping the traveler or a landmark shows a small
/// tooltip with its stats (§6.2's "interactive hotspots"); tapping empty
/// space, or the same marker again, dismisses it. Pan and zoom come from
/// [InteractiveViewer]; nothing here touches the network, the map is a
/// bundled asset and the screen works fully offline (§6.2, §8).
///
/// Accepted friends (§6.5, off by default in Настройки) render as colored
/// helmets in their own stable pin color (`friendMarkerColor`) — always
/// visible once the Настройки toggle is on, same as the traveler's own gold
/// one. Landmark icons and every friend's nickname label are a separate,
/// map-local "legend" (`_LoadedMapState._legendVisible`), off by default so
/// the map reads as just the illustration and its helmets — the small
/// bottom-right button (`_LegendToggleButton`) reveals them.
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

    // §6.5 "friends on the map" preference — off by default. Resolved once
    // here rather than inside `_LoadedMap`/the painter, so neither of those
    // needs to know the toggle provider exists; they just render whatever
    // (possibly empty) list they're handed, the same way `progressMeters`
    // already flows in as a plain value.
    final showFriends = ref.watch(showFriendsOnMapProvider);
    final friends = showFriends
        ? (ref.watch(friendsViewProvider).value?.rows ??
                  const <FriendProgressRow>[])
              .where((row) => !row.isSelf)
              .toList()
        : const <FriendProgressRow>[];

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
          friends: friends,
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
    required this.friends,
    required this.l10n,
  });

  final QuestMapAssets assets;
  final int progressMeters;
  final DateTime startedAt;

  /// Accepted friends to draw as colored helmets — already filtered to
  /// exclude the caller's own row and already empty when the §6.5 toggle is
  /// off (`QuestMapView.build`'s own doc comment).
  final List<FriendProgressRow> friends;

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

  /// The map's own "legend" — landmark icons (visible and tappable) and
  /// friend nickname labels. **Off by default** (user request: "надписи и
  /// иконки должны быть невидимы, только шлемы") — the small toggle button
  /// below the map (`_LegendToggleButton`) turns it on, restoring the
  /// landmark icons this screen always showed before this preference
  /// existed. Purely a local view preference, same ephemeral-state shape
  /// `journey_path_view.dart`'s `_panMeters` is (never persisted, resets on
  /// rebuild) — nothing here is progress or a cross-screen setting.
  bool _legendVisible = false;

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
    // Landmarks are neither drawn nor tappable while the legend is hidden
    // (this task's requirement — invisible icons stay non-interactive
    // rather than tappable ghosts of themselves); the traveler's own tap
    // target above is unaffected either way, it isn't part of the legend.
    if (_legendVisible) {
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
                            progressMeters: widget.progressMeters,
                            friends: widget.friends,
                            legendVisible: _legendVisible,
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
        // Bottom-right, directly under the map (this task's requirement) —
        // the legend defaults hidden, so this is the only way back to the
        // landmark icons + friend nicknames it controls.
        Align(
          alignment: Alignment.centerRight,
          child: _LegendToggleButton(
            key: const Key('questMapLegendToggle'),
            visible: _legendVisible,
            label: _legendVisible
                ? l10n.questMapLegendHideLabel
                : l10n.questMapLegendShowLabel,
            onTap: () => setState(() => _legendVisible = !_legendVisible),
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

/// Diameter of [_LegendToggleButton], in logical pixels — same shape and
/// size as `journey_path_view.dart`'s round gold-bordered map controls
/// (`_BackToCatalogButton`, `_ReturnToYouButton`), so a "map control" reads
/// as one visual family across both screens.
const double _legendToggleButtonSize = 36;

/// Icon size inside [_LegendToggleButton], in logical pixels.
const double _legendToggleIconSize = 18;

/// The bottom-right toggle (this task's requirement) that shows/hides the
/// map's own legend — landmark icons and friend nickname labels, both
/// hidden by default so the map reads as just the drawn illustration plus
/// the helmets on it. [visible] only decides which icon/label this button
/// itself shows (an eye, crossed out once the legend is on — tapping it
/// will turn it off); [_LoadedMapState] owns the actual toggled state.
class _LegendToggleButton extends StatelessWidget {
  const _LegendToggleButton({
    super.key,
    required this.visible,
    required this.label,
    required this.onTap,
  });

  final bool visible;
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
          child: SizedBox(
            width: _legendToggleButtonSize,
            height: _legendToggleButtonSize,
            child: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.gold,
              size: _legendToggleIconSize,
            ),
          ),
        ),
      ),
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

/// Monochrome icon standing in for each landmark on the map, keyed by
/// [MapLandmark.id] — a small piece of presentation styling, not quest
/// content, so it lives here rather than in `map.json` (§11: the id itself
/// is the stable, content-authored key; what glyph represents it on this
/// screen is a display decision).
///
/// Plain Material icons, painted in a single [AppColors.mapLandmarkInk]
/// tone (styling fix) — colourful emoji (a mermaid, a pink pig) read as out
/// of place against the map's ink/parchment illustration style; a
/// consistent engraved-looking glyph set matches it instead. An id this map
/// doesn't know about (a future quest's landmarks) falls back to
/// [_defaultLandmarkIcon] rather than throwing — new quest content should
/// never crash the map.
const Map<String, IconData> _landmarkIcons = {
  'troy': Icons.account_balance, // temple/columns
  'aeaea-circe': Icons.change_circle_outlined, // Circe's transformation
  'lotus-eaters': Icons.spa, // the lotus flower
  'calypso': Icons.terrain, // the island
  'scylla-charybdis': Icons.cyclone, // the whirlpool
  'sirens': Icons.music_note, // the siren song
  'ithaca': Icons.home,
};
const IconData _defaultLandmarkIcon = Icons.location_on;

/// The icon marker for one landmark id. Exposed at the top level (rather
/// than folded straight into the painter) so the mapping itself — every
/// shipped id resolves to something, the fallback pin catches the rest —
/// has a unit test that doesn't need a canvas.
@visibleForTesting
IconData iconForLandmarkId(String landmarkId) =>
    _landmarkIcons[landmarkId] ?? _defaultLandmarkIcon;

/// Size of a landmark's icon marker, in logical pixels.
const double _landmarkIconSize = 16;

/// Radius of the dark halo painted behind a landmark emoji, so it stays
/// legible over both the pale ink lines and the black background.
const double _landmarkHaloRadius = 11;

/// On-screen height, in logical pixels, of the traveler's helmet marker
/// (crest included) — [_travelerHelmetBounds] gives its shape in local
/// units, this is what that gets scaled to.
const double _travelerIconHeight = 20;

/// Font size of a friend's nickname label, painted above their helmet only
/// while the map's legend is visible.
const double _friendNicknameFontSize = 10;

/// Vertical gap, in logical pixels, from a friend's helmet center to the
/// *bottom* of their nickname label — clears the helmet's own halo
/// (`_paintHelmet`'s `bounds.longestSide * scale / 2 + 3`) so the label
/// never overlaps the marker it names.
const double _friendNicknameOffsetY = _travelerIconHeight;

/// Padding, in logical pixels, between a friend's nickname text and the
/// dark pill painted behind it for legibility.
const double _friendNicknamePadding = 2;

/// Paints the traveler's position and every landmark on the drawn map —
/// **not** the route between them (§6.2: the path is deliberately
/// invisible; the traveler moves along it, nothing draws it). Marker
/// positions still come straight from the same route math ([metersToPoint])
/// either way, so hiding the line changes nothing about where the markers
/// land.
class _RouteOverlayPainter extends CustomPainter {
  const _RouteOverlayPainter({
    required this.polyline,
    required this.landmarks,
    required this.progressMeters,
    required this.friends,
    required this.legendVisible,
  });

  final RoutePolyline polyline;
  final List<MapLandmark> landmarks;
  final int progressMeters;

  /// Accepted friends to draw as colored helmets (§6.5, user request) —
  /// already filtered/emptied by `QuestMapView.build`. Always drawn
  /// (subject only to the Настройки toggle, not [legendVisible] — friends
  /// are the "only шлемы" this task keeps visible by default, same as the
  /// traveler's own helmet).
  final List<FriendProgressRow> friends;

  /// The map's own legend — landmark icons and friend nickname labels
  /// (this task's requirement: hidden by default, "надписи и иконки
  /// должны быть невидимы, только шлемы"). Every helmet (traveler's own,
  /// every friend's) paints regardless of this flag; only [_paintLandmark]
  /// and each friend's nickname label are gated on it.
  final bool legendVisible;

  @override
  void paint(Canvas canvas, Size size) {
    Offset toOffset(MapPoint point) =>
        Offset(point.x * size.width, point.y * size.height);

    if (legendVisible) {
      for (final landmark in landmarks) {
        _paintLandmark(
          canvas,
          toOffset(MapPoint(x: landmark.x, y: landmark.y)),
          landmark,
        );
      }
    }

    for (final friend in friends) {
      final at = toOffset(metersToPoint(polyline, friend.progressMeters));
      final color = friendMarkerColor(friend);
      _paintHelmet(canvas, at, color);
      if (legendVisible) _paintNickname(canvas, at, friend.nickname, color);
    }

    // Painted last so the caller's own helmet is never hidden under a
    // friend's, on the rare tie (e.g. both still at the route's own start).
    final here = toOffset(metersToPoint(polyline, progressMeters));
    _paintHelmet(canvas, here, AppColors.gold);
  }

  void _paintLandmark(Canvas canvas, Offset at, MapLandmark landmark) {
    canvas.drawCircle(
      at,
      _landmarkHaloRadius,
      Paint()..color = AppColors.background.withValues(alpha: 0.55),
    );
    final icon = iconForLandmarkId(landmark.id);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: _landmarkIconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: AppColors.mapLandmarkInk,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  /// Paints a Corinthian-helmet silhouette (front view: a domed shield with
  /// the T-shaped eye/nose slit and a low crest ridge) at [at] in [color] —
  /// gold for the traveler's own position, a friend's stable pin color
  /// (`friendMarkerColor`) for theirs — on a dark halo so it stays readable
  /// over the ink drawing either way. The shape itself doesn't change
  /// between the two; only the fill color and, implicitly, whose position
  /// [at] is does.
  void _paintHelmet(Canvas canvas, Offset at, Color color) {
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
    final paint = Paint()..color = color;
    canvas.drawPath(_travelerHelmetCrest, paint);
    canvas.drawPath(_travelerHelmetDome, paint);
    canvas.restore();
  }

  /// A friend's nickname, in their own helmet color, floating just above
  /// [at] — only ever called while [legendVisible] (the legend is what this
  /// label belongs to, per this task's own list: "ники над шлемами...").
  /// A dark pill behind the text keeps it legible over the ink drawing, the
  /// same halo idiom [_paintLandmark]/[_paintHelmet] already use.
  void _paintNickname(Canvas canvas, Offset at, String nickname, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: nickname,
        style: AppTypography.bodySecondary.copyWith(
          fontSize: _friendNicknameFontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Anchored by the label's *bottom*-center, not its top: [_paintHelmet]'s
    // halo radius depends on the helmet's own scaled bounds, not a fixed
    // constant, so pinning the text's top edge a flat distance above [at]
    // could still land inside a slightly larger halo. Bottom-anchoring at a
    // fixed clearance from [at] keeps the label above the halo regardless.
    final topLeft =
        at - Offset(painter.width / 2, _friendNicknameOffsetY + painter.height);
    final backgroundRect =
        (topLeft -
            const Offset(_friendNicknamePadding, _friendNicknamePadding)) &
        Size(
          painter.width + _friendNicknamePadding * 2,
          painter.height + _friendNicknamePadding * 2,
        );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(3)),
      Paint()..color = AppColors.background.withValues(alpha: 0.75),
    );
    painter.paint(canvas, topLeft);
  }

  @override
  bool shouldRepaint(covariant _RouteOverlayPainter oldDelegate) =>
      oldDelegate.progressMeters != progressMeters ||
      oldDelegate.polyline != polyline ||
      oldDelegate.legendVisible != legendVisible ||
      // landmarks comes from the same immutable QuestMap.landmarks list for
      // the life of a loaded map — reference inequality is enough to catch
      // the one case that matters, a freshly (re)loaded map.
      !identical(oldDelegate.landmarks, landmarks) ||
      // Unlike landmarks, `friends` is rebuilt fresh on every
      // `QuestMapView.build()` (`FriendProgressRow` isn't `==`-comparable),
      // so this repaints on every friends refresh even when the positions
      // didn't actually change — this screen isn't a 60fps scene, so the
      // occasional extra repaint costs nothing worth optimizing away.
      oldDelegate.friends != friends;
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
/// what `_RouteOverlayPainter._paintHelmet` scales to [_travelerIconHeight]
/// and centers on whichever position (traveler's or a friend's) it was
/// called for.
final Rect _travelerHelmetBounds = _travelerHelmetDome
    .getBounds()
    .expandToInclude(_travelerHelmetCrest.getBounds());
