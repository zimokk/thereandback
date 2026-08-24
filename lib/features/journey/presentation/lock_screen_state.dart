import 'package:freezed_annotation/freezed_annotation.dart';

part 'lock_screen_state.freezed.dart';

/// UI-facing permission state for the lock-screen/notification-shade
/// feature (§7). Two permissions are bundled behind one toggle —
/// `POST_NOTIFICATIONS` and Health Connect's background-read permission —
/// because neither alone is useful for this feature (see
/// `lock_screen_controller.dart`).
enum LockScreenPermissionStatus {
  /// Not checked/requested yet — the feature's toggle is off and untouched.
  unknown,
  notRequested,
  granted,
  denied,
}

@freezed
abstract class LockScreenState with _$LockScreenState {
  const factory LockScreenState({
    @Default(false) bool enabled,
    @Default(LockScreenPermissionStatus.unknown)
    LockScreenPermissionStatus permissionStatus,
    @Default(false) bool isBusy,

    /// The `journeyId` [LockScreenChannel.start] was last called for, or
    /// `null` if nothing is currently being shown. Lets the controller tell
    /// "first display for this quest" (→ `start`) apart from "same quest,
    /// new progress" (→ `update`) without asking the channel implementation
    /// to track that itself — a future iOS `Activity`-based implementation
    /// can rely on `start` never being called twice in a row for the same
    /// quest.
    String? activeJourneyId,
  }) = _LockScreenState;
}
