import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';

/// A trophy definition: data, not code (CLAUDE.md §6.3). Adding a new
/// achievement means adding an entry to the catalog config, never a new
/// `if` branch in a widget.
///
/// The only condition implemented today is a distance threshold on the
/// current quest. Richer conditions (streaks, landmarks reached, overtaking
/// a friend — §6.3) are represented by [AchievementKind] and can grow
/// without touching [evaluateAchievements]'s call sites, only its `switch`.
@freezed
abstract class AchievementDef with _$AchievementDef {
  const factory AchievementDef({
    required String id,

    /// L10n key for the title — achievement copy is UI text (§11), not
    /// narrative content, so it lives in the ARB files like any other label.
    required String titleKey,
    required AchievementKind kind,
    required int thresholdMeters,
  }) = _AchievementDef;
}

enum AchievementKind {
  /// Unlocked once total quest progress reaches [AchievementDef.thresholdMeters].
  distanceReached,
}

/// The evaluated state of one achievement for the current user.
@freezed
abstract class AchievementState with _$AchievementState {
  const factory AchievementState({
    required AchievementDef def,
    required bool unlocked,

    /// Meters still needed to unlock; `0` once [unlocked] is true.
    required int remainingMeters,
  }) = _AchievementState;
}

/// Evaluates every achievement in [catalog] against [progressMeters]. Pure
/// and total — one evaluator for the whole catalog, per §6.3.
List<AchievementState> evaluateAchievements({
  required int progressMeters,
  required List<AchievementDef> catalog,
}) {
  return catalog
      .map((def) {
        switch (def.kind) {
          case AchievementKind.distanceReached:
            final unlocked = progressMeters >= def.thresholdMeters;
            final remaining = unlocked
                ? 0
                : def.thresholdMeters - progressMeters;
            return AchievementState(
              def: def,
              unlocked: unlocked,
              remainingMeters: remaining,
            );
        }
      })
      .toList(growable: false);
}
