/// Steps → distance conversion (CLAUDE.md §5.1). This is the **only** place
/// in the app that turns raw step/health data into meters. Pure Dart, no
/// platform imports — the `health` package lives in `steps/data/`.
library;

/// Default stride length used for every user until they set one manually in
/// the profile (§6.5, §5.1). Onboarding never asks about height or sex —
/// this default applies with no questions.
const double defaultStrideMeters = 0.75;

/// Converts a step count to meters using a stride length.
///
/// [strideMeters] defaults to [defaultStrideMeters]; pass a manually set
/// stride from the user's profile when one exists — a manual value always
/// wins over the default (§5.1).
int stepsToMeters(int steps, {double strideMeters = defaultStrideMeters}) {
  assert(steps >= 0, 'a step count from the pedometer is never negative');
  assert(strideMeters > 0, 'stride length must be positive');
  return (steps * strideMeters).round();
}

/// Resolves the distance covered in an interval, preferring the platform's
/// own `DISTANCE_WALKING_RUNNING` reading over `steps × stride` whenever the
/// platform provides one — it is more accurate (§5.1).
///
/// [walkingDistanceMeters] is the platform-reported distance for the
/// interval, if any; [stepCount] is the step count for the same interval,
/// used only as a fallback.
int resolveDistanceMeters({
  required int stepCount,
  int? walkingDistanceMeters,
  double strideMeters = defaultStrideMeters,
}) {
  if (walkingDistanceMeters != null && walkingDistanceMeters >= 0) {
    return walkingDistanceMeters;
  }
  return stepsToMeters(stepCount, strideMeters: strideMeters);
}

/// Enforces the "progress never decreases" invariant (§5.1): if a source
/// hands back a delta that would move the traveler backwards, the traveler
/// simply does not move rather than rewinding.
int clampNonDecreasing(int previousMeters, int candidateMeters) {
  return candidateMeters > previousMeters ? candidateMeters : previousMeters;
}

/// A step/distance interval is realistic below ~250 steps/min sustained
/// (§5.2) — a runner sprinting a short interval can exceed it briefly, a
/// device or data glitch usually doesn't stay under it. This flags rather
/// than silently drops an implausible interval; the caller decides what a
/// flagged sample means for the sync (still counted, surfaced to the user,
/// excluded — that policy is not decided here).
const int maxRealisticStepsPerMinute = 250;

/// Whether an interval's average step rate exceeds [maxRealisticStepsPerMinute].
bool isImplausiblePace({required int steps, required Duration interval}) {
  if (interval <= Duration.zero) return steps > 0;
  final stepsPerMinute = steps / (interval.inSeconds / 60);
  return stepsPerMinute > maxRealisticStepsPerMinute;
}
