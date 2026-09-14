import 'package:freezed_annotation/freezed_annotation.dart';

part 'segment_biomes.freezed.dart';

/// One segment's stretch of the route and the biome its art belongs to
/// (CLAUDE.md §6.1's "набор силуэтных слоёв по биомам... комбинируются по
/// позиции", §9.1).
///
/// Parsed from `locations.json`'s `segments[]`, which has carried a `biome`
/// on every segment of both catalog quests since they were written — this
/// is the first thing to actually read it.
///
/// [fromMeters] is inclusive, [toMeters] exclusive for lookup purposes,
/// except on the very last span, where the route's final meter still has to
/// resolve to a biome — [biomeAt] handles that end rather than the data
/// needing a special last entry.
@freezed
abstract class BiomeSpan with _$BiomeSpan {
  const factory BiomeSpan({
    required String segmentId,
    required String biome,
    required int fromMeters,
    required int toMeters,
  }) = _BiomeSpan;
}

/// Which biome is drawn at [meters], and how far into the cross-fade
/// towards the next one the scene is (`0` = fully [current], `1` = fully
/// [next]). [next] is `null` whenever nothing is being crossed into —
/// mid-segment, at the end of the route, or between two consecutive
/// segments that happen to share a biome and therefore share art.
///
/// A record, not a freezed class: it is a bundle of values that already
/// have types of their own, the same choice `journey_terrain_repository`'s
/// `JourneyTerrainContent` and `route_mapping.dart`'s `SplitRoute` make.
typedef BiomeBlend = ({BiomeSpan current, BiomeSpan? next, double blend});

/// How long, in route meters, one biome takes to cross-fade into the next.
///
/// 2 000 m is a tenth of a screen width at `route_scale.dart`'s 20 km per
/// screen — long enough that the swap reads as landscape changing rather
/// than art being replaced, short enough that a segment is overwhelmingly
/// its own biome. [biomeBlendAt] shortens it further where a segment is too
/// short to give it room, so it is a maximum rather than a promise.
const int biomeTransitionMeters = 2000;

/// The span covering [meters], or `null` if [spans] is empty.
///
/// Total by clamping, like every other route-position lookup in this layer
/// (`terrainHeightAt`, `metersToPoint`): a position before the first span
/// resolves to the first, past the last to the last, rather than throwing
/// on a rounding error at point A or B.
BiomeSpan? biomeAt(List<BiomeSpan> spans, int meters) {
  final index = _spanIndexAt(spans, meters);
  return index == null ? null : spans[index];
}

/// [biomeAt] plus the cross-fade towards the following biome (see
/// [BiomeBlend]), using at most [transitionMeters] of route.
///
/// The window is capped at half of either neighbouring span, so a short
/// segment can never be fading in at its start and out at its end at the
/// same time — which would leave a stretch of route where neither biome is
/// ever fully itself.
BiomeBlend? biomeBlendAt(
  List<BiomeSpan> spans,
  int meters, {
  int transitionMeters = biomeTransitionMeters,
}) {
  final index = _spanIndexAt(spans, meters);
  if (index == null) return null;

  final current = spans[index];
  final next = index + 1 < spans.length ? spans[index + 1] : null;
  if (next == null || next.biome == current.biome) {
    return (current: current, next: null, blend: 0);
  }

  final window = [
    transitionMeters,
    (current.toMeters - current.fromMeters) ~/ 2,
    (next.toMeters - next.fromMeters) ~/ 2,
  ].reduce((a, b) => a < b ? a : b);
  if (window <= 0) return (current: current, next: null, blend: 0);

  final start = current.toMeters - window;
  if (meters <= start) return (current: current, next: null, blend: 0);

  final blend = (meters - start) / window;
  return (current: current, next: next, blend: blend > 1 ? 1 : blend);
}

/// Index of the span covering [meters] — the one lookup both public
/// functions share, so "which biome is this" is answered in exactly one
/// place and [biomeBlendAt] gets the index it needs for the *next* span
/// without an `indexOf` scan of its own.
///
/// Relies on [spans] being contiguous and ordered, which
/// `journey_terrain_repository.dart` validates when parsing them: with no
/// gaps, the first span whose [BiomeSpan.toMeters] is past [meters] is the
/// one containing it.
int? _spanIndexAt(List<BiomeSpan> spans, int meters) {
  if (spans.isEmpty) return null;
  for (var i = 0; i < spans.length; i++) {
    if (meters < spans[i].toMeters) return i;
  }
  return spans.length - 1;
}
