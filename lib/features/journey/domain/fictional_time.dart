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

/// [now]'s local time of day as a decimal hour (0..24) — e.g. 6:30am is
/// `6.5`. Shared by [skyPhaseFor] and `sky_gradient.dart`'s continuous
/// real-clock path, so both read the same clock the same way.
double hourOfDay(DateTime now) => now.hour + now.minute / 60;

/// Which [SkyPhase] [now]'s local time of day falls in — the real-clock
/// path, used whenever a journey has no fictional timeline of its own
/// (`sky_gradient.dart`'s `fictionalHour == null` fallback).
SkyPhase skyPhaseFor(DateTime now) => skyPhaseForHour(hourOfDay(now));

/// A point somewhere between two adjacent [SkyPhase]s — [from] fully
/// (`t == 0`) shading into [to] (`t == 1`) — used to cross-fade the sky
/// continuously instead of snapping at [skyPhaseForHour]'s band edges.
///
/// [from] and [to] are equal (with `t == 0`) inside the two flat bands
/// (night, day) where nothing is transitioning.
typedef SkyBlend = ({SkyPhase from, SkyPhase to, double t});

/// The continuous counterpart of [skyPhaseForHour]: where [hour] (0..24,
/// wrapped) sits between two [SkyPhase]s, instead of collapsing it into one.
///
/// Reuses [skyPhaseForHour]'s own band edges (5, 7, 18, 20) as the only
/// transition windows, but splits each short band (dawn, dusk) in half at
/// its midpoint (6, 19) rather than blending straight from night to day (or
/// day to night): this way the dedicated dawn/dusk hues
/// (`AppColors.skyDawnTop/Bottom`, `skyDuskTop/Bottom`) are still fully
/// visible for a moment at their center, instead of being skipped over by a
/// direct two-color lerp.
///
///  - `[20,5)` night — flat, `t == 0`
///  - `[5,6)` night → dawn
///  - `[6,7)` dawn → day
///  - `[7,18)` day — flat, `t == 0`
///  - `[18,19)` day → dusk
///  - `[19,20)` dusk → night
SkyBlend skyBlendForHour(double hour) {
  final h = hour % 24;
  if (h < 5) return (from: SkyPhase.night, to: SkyPhase.night, t: 0);
  if (h < 6) return (from: SkyPhase.night, to: SkyPhase.dawn, t: h - 5);
  if (h < 7) return (from: SkyPhase.dawn, to: SkyPhase.day, t: h - 6);
  if (h < 18) return (from: SkyPhase.day, to: SkyPhase.day, t: 0);
  if (h < 19) return (from: SkyPhase.day, to: SkyPhase.dusk, t: h - 18);
  if (h < 20) return (from: SkyPhase.dusk, to: SkyPhase.night, t: h - 19);
  return (from: SkyPhase.night, to: SkyPhase.night, t: 0);
}

/// The continuous counterpart of the star layer's visibility: how far
/// through the dawn/dusk fade [hour] (0..24, wrapped) sits, instead of the
/// binary on/off [skyPhaseForHour] would give. Reuses the same band edges
/// (5, 7, 18, 20) as [skyBlendForHour], fading linearly across the full
/// width of each band rather than splitting at its midpoint — there is no
/// "dawn/dusk" opacity to preserve mid-fade, unlike the named hues in
/// [skyBlendForHour].
double starOpacityForHour(double hour) {
  final h = hour % 24;
  if (h < 5 || h >= 20) return 1;
  if (h < 7) return 1 - (h - 5) / 2;
  if (h < 18) return 0;
  return (h - 18) / 2;
}

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
