import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'step_counting_service.dart';

/// The iOS implementation of [StepCountingService]: HealthKit via the
/// `health` package.
///
/// Unconditional — no `Platform.isAndroid` checks anywhere in this class.
/// Health Connect and `ACTIVITY_RECOGNITION` are Android-only concepts
/// (§7), so the methods for them here just return the constants that were
/// already correct for iOS: always granted/available, nothing to request.
///
/// **Ported now, not stubbed** — this logic already works via the `health`
/// package; what's actually deferred is *verifying it on a real device*:
/// HealthKit is an Apple capability gated behind a paid Apple Developer
/// Program membership (there is no free/Personal-Team path for it, unlike
/// Health Connect), so this class hasn't been exercised end-to-end yet.
/// Tracked as a status note in CLAUDE.md §14, not as missing code.
class IosStepCountingService
    with HealthPackagePedometer
    implements StepCountingService {
  IosStepCountingService([Health? health]) : health = health ?? Health();

  @override
  final Health health;

  @override
  HealthDataType get walkingDistanceType =>
      HealthDataType.DISTANCE_WALKING_RUNNING;

  @override
  Future<bool> hasActivityRecognitionPermission() async => true;

  @override
  Future<RuntimePermissionResult> requestActivityRecognitionPermission() async {
    return RuntimePermissionResult.granted;
  }

  @override
  Future<void> openAppSettings() => ph.openAppSettings();

  @override
  Future<HealthConnectAvailability> healthConnectAvailability() async =>
      HealthConnectAvailability.available;

  @override
  Future<void> openHealthConnectInstall() async {}

  @override
  Future<bool> hasBackgroundHealthPermission() async => true;

  @override
  Future<bool> requestBackgroundHealthPermission() async => true;
}
