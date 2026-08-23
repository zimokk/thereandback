import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_selection.freezed.dart';

/// The quest a user currently has active, plus the local bookkeeping needed
/// to sync it (CLAUDE.md §5.2).
///
/// This is in-memory application state today (see `journey_providers.dart`),
/// not a persisted entity — Phase 3 (drift) will back it with a real
/// repository sharing this same shape.
@freezed
abstract class SelectedQuest with _$SelectedQuest {
  const factory SelectedQuest({
    required String journeyId,

    /// When the user tapped "Start quest".
    required DateTime startedAt,

    /// Start of the sync window not yet applied to [progressMeters]. Seeded
    /// to the start of the local calendar day on quest start (§5.2), so
    /// steps already taken that day still count.
    required DateTime lastSyncedAt,

    /// Total meters credited to this quest so far. Monotonically
    /// non-decreasing — see `steps/domain/stride.dart`'s
    /// `clampNonDecreasing`.
    required int progressMeters,
  }) = _SelectedQuest;
}
