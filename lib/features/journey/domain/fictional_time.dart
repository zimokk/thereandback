import 'package:freezed_annotation/freezed_annotation.dart';

part 'fictional_time.freezed.dart';

/// Four broad slices of the day the sky's palette moves through (CLAUDE.md
/// §6.1: "процедурный градиент... ночь со звёздами, рассвет, день,
/// закат"). Boundaries are simple hour bands, not sunrise/sunset astronomy
/// — this is decorative atmosphere, not anything the rest of the domain
/// layer needs to reason about.
///
/// Lives in `domain/`, not `presentation/`, because it is now classified
/// from two different clocks — the real device clock
/// ([skyPhaseFor]/`DateTime.now()`, for any journey with no fictional
/// timeline) and the in-story clock ([skyPhaseForHour] fed by
/// [fictionalHourFor], for a journey like `odyssey-ithaca` that defines
/// one) — and both are meters/route math, not Flutter.
enum SkyPhase { night, dawn, day, dusk }

/// Which [SkyPhase] the given [hour] of the day (0..24, wrapped) falls in —
/// the shared band logic behind both [skyPhaseFor] (real clock) and the
/// fictional-time path ([fictionalHourFor] + this function, wired in
/// `journey_flame_scene_view.dart`).
SkyPhase skyPhaseForHour(double hour) {
  final h = hour % 24;
  if (h < 5 || h >= 20) return SkyPhase.night;
  if (h < 7) return SkyPhase.dawn;
  if (h < 18) return SkyPhase.day;
  return SkyPhase.dusk;
}

/// Which [SkyPhase] [now]'s local time of day falls in — the real-clock
/// path, used whenever a journey has no fictional timeline of its own
/// (`sky_gradient.dart`'s `fictionalHour == null` fallback).
SkyPhase skyPhaseFor(DateTime now) =>
    skyPhaseForHour(now.hour + now.minute / 60);

/// One journey segment's in-fiction time span (CLAUDE.md §6.1's fictional
/// sky for story-driven quests) — the same `fromMeters`/`toMeters` range
/// `assets/journeys/{id}/locations.json`'s `segments[]` already carries,
/// tagged with when (in the story) the traveler departs [fromMeters] and
/// how long (in story-days) reaching [toMeters] takes.
///
/// [durationDays] is capped, per segment, by the app's pace-safety rule
/// (`journey_timing_repository.dart`'s `parseJourneySegmentTimings`): no
/// more than 1 in-fiction day may elapse per 10 000 real meters of a
/// segment, so an ordinary walk can never flip through "several days" at
/// once — see that file's validation and the plan this shipped from.
@freezed
abstract class JourneySegmentTiming with _$JourneySegmentTiming {
  const factory JourneySegmentTiming({
    required String id,
    required int fromMeters,
    required int toMeters,
    required double departureHour,
    required double durationDays,
  }) = _JourneySegmentTiming;
}

/// The in-fiction hour of day (0..24) at [meters] along the route, given
/// the journey's ordered, contiguous [segments] (CLAUDE.md §6.1: "если
/// Одиссей вышел утром — в начале пути утро", "между — что-то среднее",
/// "несколько дней между пунктами — несколько смен суток").
///
/// [meters] outside the route clamps to the first/last segment rather than
/// extrapolating — same contract as `route_mapping.dart`'s
/// `metersToPoint`. [segments] must be non-empty, sorted, and contiguous
/// (`parseJourneySegmentTimings` enforces this on load) — not re-validated
/// here, since this runs on every scroll frame and content is assumed
/// already-checked by the time it reaches this function.
double fictionalHourFor(List<JourneySegmentTiming> segments, int meters) {
  assert(segments.isNotEmpty, 'a journey always has at least one segment');

  final clamped = meters.clamp(
    segments.first.fromMeters,
    segments.last.toMeters,
  );
  // Strictly less-than, not <=: at an exact boundary shared by two
  // segments (this segment's toMeters == the next one's fromMeters), the
  // position belongs to the *next* segment — e.g. `troy-departure`'s
  // toMeters is `cicones-ismarus`'s fromMeters, and that boundary must
  // read as the latter's `departureHour`, not the former's rolled-forward
  // end-of-segment hour. `orElse` only fires past the last segment's own
  // toMeters (nothing is strictly less than it there), which is exactly
  // when the route's own end state — the last segment fully elapsed — is
  // what's wanted.
  final segment = segments.firstWhere(
    (s) => clamped < s.toMeters,
    orElse: () => segments.last,
  );

  final span = segment.toMeters - segment.fromMeters;
  final fraction = span <= 0 ? 0.0 : (clamped - segment.fromMeters) / span;
  final elapsedHours = fraction * segment.durationDays * 24;
  return (segment.departureHour + elapsedHours) % 24;
}
