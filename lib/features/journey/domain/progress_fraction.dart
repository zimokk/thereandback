/// Fraction of the route walked so far, in `[0.0, 1.0]` — the raw number
/// behind any "X%" label or progress bar. Formatting (e.g. turning `0.5`
/// into `"50%"`) stays in presentation (§5.4); this only produces the
/// clamped `0..1` value so it can't be computed slightly differently in two
/// places (see `journey_path_view.dart`, which used to do this inline).
///
/// Not time-related, unlike `quest_time_service.dart` — kept as its own
/// tiny pure function rather than folded into `QuestTimeService`.
///
/// `totalMeters <= 0` returns `0.0` rather than dividing by zero — a
/// degenerate quest length is not this function's problem to reject.
/// [progressMeters] past [totalMeters] (e.g. a sync credited after the
/// quest technically finished) clamps to `1.0`, never over.
double progressFraction({
  required int progressMeters,
  required int totalMeters,
}) {
  if (totalMeters <= 0) return 0.0;
  final fraction = progressMeters / totalMeters;
  if (fraction < 0) return 0.0;
  if (fraction > 1) return 1.0;
  return fraction;
}
