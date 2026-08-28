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

  /// Android only: Health Connect itself isn't installed on the device —
  /// mirrors `StepsPermissionStatus.healthConnectMissing`. Distinct from
  /// [denied] so the card can offer "install Health Connect" instead of
  /// re-requesting a permission Health Connect has nowhere to grant yet.
  healthConnectMissing,

  /// Android only: `ACTIVITY_RECOGNITION` ("Physical activity") — a
  /// prerequisite for Health Connect's own Steps/Distance consent screen,
  /// see `StepCountingService.hasActivityRecognitionPermission` — hit
  /// Android's two-denials-means-"don't ask again" rule (`USER_FIXED`).
  /// Requesting it again shows no dialog at all, so the toggle must offer
  /// the OS settings page instead of another "try again" (§7).
  permanentlyDenied,
}

@freezed
abstract class LockScreenState with _$LockScreenState {
  const factory LockScreenState({
    @Default(false) bool enabled,
    @Default(LockScreenPermissionStatus.unknown)
    LockScreenPermissionStatus permissionStatus,
    @Default(false) bool isBusy,

    /// The two permissions behind [permissionStatus], kept separately so the
    /// UI can name the one that is actually missing instead of saying "no
    /// permission" when the other one was granted just fine — the exact
    /// confusion the combined status caused.
    @Default(false) bool notificationsGranted,
    @Default(false) bool backgroundHealthGranted,

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
