/// Derived quest-progress values (CLAUDE.md §5.3). All pure functions — no
/// `DateTime.now()` inside; every caller passes the clock in so results stay
/// deterministic and testable (see the `domain-math` skill).
///
/// Both `startedAt` and `now` must be expressed in the **same** timezone —
/// the user's local time. Day boundaries are computed on local calendar
/// dates, never by dividing milliseconds by 86 400 000, so a DST shift
/// cannot skip or repeat a day.
library;

/// Truncates a [DateTime] down to its calendar date, discarding time of day.
DateTime _calendarDate(DateTime d) => DateTime(d.year, d.month, d.day);

/// The quest day counter shown as "Day N" (§5.3): the number of local
/// calendar days between [startedAt] and [now], inclusive of both ends.
///
/// Starting and checking on the same calendar date is Day 1. `now` before
/// `startedAt` (clock skew, or a quest that has not started yet) clamps to
/// Day 1 rather than going negative.
int questDay({required DateTime startedAt, required DateTime now}) {
  final days = _calendarDate(now).difference(_calendarDate(startedAt)).inDays;
  return (days < 0 ? 0 : days) + 1;
}

/// Average meters walked per calendar day since the quest started.
///
/// This app does not yet persist a per-day history of progress (that lands
/// with the drift-backed repository in Phase 3 / `docs/implementation-plan.md`),
/// so the §5.3 "7-day rolling mean, falling back to the whole-quest average
/// under 3 days of data" rule collapses to its fallback branch today: this
/// always returns the whole-quest average. The signature is written so that
/// swapping in a real rolling window later does not change any call site.
///
/// Returns `0` (not `null`) when no distance has been covered yet — that is
/// a meaningful, real pace, not a "no data" case.
double paceMetersPerDay({
  required int progressMeters,
  required DateTime startedAt,
  required DateTime now,
}) {
  final elapsedDays = questDay(startedAt: startedAt, now: now);
  if (elapsedDays <= 0) return 0;
  return progressMeters / elapsedDays;
}

/// Estimated arrival date (§5.3): `now + remainingMeters / pace` days.
///
/// Returns `null` when pace is zero — the caller renders that as a dash,
/// never as an infinite or NaN date.
DateTime? estimateArrival({
  required int progressMeters,
  required int totalMeters,
  required DateTime startedAt,
  required DateTime now,
}) {
  final pace = paceMetersPerDay(
    progressMeters: progressMeters,
    startedAt: startedAt,
    now: now,
  );
  if (pace <= 0) return null;

  final remaining = totalMeters - progressMeters;
  if (remaining <= 0) return now;

  final daysRemaining = (remaining / pace).ceil();
  return now.add(Duration(days: daysRemaining));
}

/// Fraction of the route walked so far, in `[0.0, 1.0]` — the raw number
/// behind any "X%" label or progress bar. Formatting (e.g. turning `0.5`
/// into `"50%"`) stays in presentation (§5.4); this only produces the
/// clamped `0..1` value so it can't be computed slightly differently in two
/// places (see `journey_path_view.dart`, which used to do this inline).
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
