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

  /// Android only: Health Connect itself isn't installed on the device.
  healthConnectMissing,
}

@freezed
abstract class StepsSyncState with _$StepsSyncState {
  const factory StepsSyncState({
    @Default(StepsPermissionStatus.unknown)
    StepsPermissionStatus permissionStatus,
    @Default(false) bool isSyncing,
  }) = _StepsSyncState;
}
