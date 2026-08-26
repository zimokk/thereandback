import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps_sync_state.freezed.dart';

/// UI-facing permission state for the steps sync flow (§7). This is an
/// application/presentation concept — the platform-specific detail it wraps
/// (HealthKit's undetermined-`null`, Health Connect's install check) lives
/// behind `steps/data/health_adapter.dart`.
enum StepsPermissionStatus {
  /// Not checked yet.
  unknown,

  /// Checked; the user has not been asked (or, on iOS, HealthKit's grant is
  /// undetermined — treated the same as "ask").
  notRequested,
  granted,
  denied,

  /// Android only: `ACTIVITY_RECOGNITION` ("Physical activity") hit
  /// Android's two-denials-means-"don't ask again" rule (`USER_FIXED`) —
  /// requesting again shows no dialog at all, so the gate must offer the
  /// OS settings page instead of another "try again" (§7).
  permanentlyDenied,

  /// Android only: Health Connect itself isn't installed on the device.
  healthConnectMissing,
}

@freezed
abstract class StepsSyncState with _$StepsSyncState {
  const factory StepsSyncState({
    @Default(StepsPermissionStatus.unknown)
    StepsPermissionStatus permissionStatus,
    @Default(false) bool isSyncing,

    /// Whether the most recent sync's interval exceeded the §5.2 realistic
    /// pace threshold (`stride.isImplausiblePace`). The distance is still
    /// credited either way — §5.2 requires flagging, never silently
    /// dropping — this is only a signal for the UI to show a notice.
    @Default(false) bool lastSyncFlagged,
  }) = _StepsSyncState;
}
