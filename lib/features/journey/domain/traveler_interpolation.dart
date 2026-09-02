/// The `You` marker's *displayed* position, smoothed between the last
/// displayed value and a new [targetMeters] (CLAUDE.md §6.1: "новые шаги
/// плавно интерполируются... 800–1200 мс, не прыгает рывком").
///
/// Pure and stateless — no `DateTime.now()` inside (see the `domain-math`
/// skill): the caller supplies its own clock via [elapsedMs], so a test
/// drives this exactly like every other pure function in `domain/`. The
/// presentation layer owns the actual ticking (an `AnimationController` or a
/// per-frame elapsed counter in `journey_flame_scene_view.dart`) and calls
/// this once per tick with a growing [elapsedMs].
///
/// Guarantees, all load-bearing for the `flame-scene` skill's own test list
/// ("`You` interpolation reaches the new position and never moves
/// backwards"):
/// - Monotonically non-decreasing as [elapsedMs] grows (progress never runs
///   backwards mid-interpolation, matching §5.1's "прогресс монотонно
///   неубывающий").
/// - Never exceeds [targetMeters].
/// - Exactly [targetMeters] once [elapsedMs] reaches [durationMs].
///
/// [displayedMeters] may be greater than [targetMeters] — e.g. a fresh
/// interpolation started while an older one was still short of a lower
/// intermediate target. That is clamped up to [targetMeters] immediately
/// (never actually reached in practice since progress itself never
/// decreases, but the clamp keeps the "never exceeds target" guarantee total
/// rather than assuming its caller already enforces it).
double interpolatedTravelerMeters({
  required double displayedMeters,
  required int targetMeters,
  required double elapsedMs,
  required double durationMs,
}) {
  if (displayedMeters >= targetMeters) return targetMeters.toDouble();
  if (elapsedMs <= 0) return displayedMeters;
  if (elapsedMs >= durationMs) return targetMeters.toDouble();

  final progress = elapsedMs / durationMs;
  final value = displayedMeters + (targetMeters - displayedMeters) * progress;
  // Guards against a caller-supplied `progress` at or past 1.0 slipping
  // through as a floating-point value fractionally above `targetMeters`.
  return value >= targetMeters ? targetMeters.toDouble() : value;
}
