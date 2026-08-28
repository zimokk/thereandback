/// Per-quest fixed scale for the "Путь" tab's route line (§6.1): how many
/// meters of the route fit into one screen width. A config, not a single
/// app-wide constant — different quests can pick a different scale — but
/// whichever value a quest gets is fixed for that quest's whole route and
/// never changes while scrolling: 20 km reads as one screen width at the
/// route's start exactly as it does near the end, so the line's total
/// pixel length is simply proportional to the route's length in meters
/// (this task's requirement), and a marker's screen position never drifts
/// relative to its neighbours as progress advances.
///
/// Plain `Map`/`int`, not a field on the `Journey` freezed entity
/// (`journey.dart`) — adding a field there needs a `build_runner` pass to
/// regenerate `journey.freezed.dart`, which this change has no need to
/// force; a journey's line scale is presentation-facing config, not part
/// of its core identity the way `totalMeters` is.
///
/// The *scale* (route-meters per screen width) is what stays constant for
/// a given quest — not raw pixels-per-meter, which still depends on the
/// device's actual screen width (see [metersToLineOffset]). That is
/// deliberate: the same route then takes the same number of swipes to
/// cross on any device.
const Map<String, int> _metersPerScreenWidthByJourney = {
  'odyssey-ithaca': 20000, // §6.1: "1 screen width = 20 km".
};

/// Scale used for a quest with no entry in
/// [_metersPerScreenWidthByJourney] — keeps [metersPerScreenWidthFor] total
/// instead of throwing if the catalog ever grows a quest before its scale
/// is picked.
const int defaultMetersPerScreenWidth = 20000;

/// The fixed meters-per-screen-width scale for [journeyId] (§6.1). Falls
/// back to [defaultMetersPerScreenWidth] for a quest without its own entry
/// — see the doc comment on [_metersPerScreenWidthByJourney].
int metersPerScreenWidthFor(String journeyId) =>
    _metersPerScreenWidthByJourney[journeyId] ?? defaultMetersPerScreenWidth;

/// Converts a distance along the route ([meters], point A = 0) to a
/// horizontal pixel offset from point A, at [journeyId]'s fixed
/// [metersPerScreenWidthFor] scale, scaled to [screenWidth] (the device's
/// actual screen width in logical pixels, supplied by the caller — this
/// function does no layout of its own).
///
/// [meters] is clamped to `>= 0`: this never returns an offset before point
/// A. There is no upper clamp here — a caller that wants to stop drawing at
/// point B clamps [meters] to the route's `totalMeters` itself, the same
/// way `metersToPoint` (quest_map/domain/route_mapping.dart) clamps its
/// input rather than this shared conversion doing it implicitly.
double metersToLineOffset({
  required String journeyId,
  required int meters,
  required double screenWidth,
}) {
  final scale = metersPerScreenWidthFor(journeyId);
  final clamped = meters < 0 ? 0 : meters;
  return clamped / scale * screenWidth;
}
