import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'step_counting_service.dart';

/// The Android implementation of [StepCountingService]: Health Connect via
/// the `health` package, plus the `ACTIVITY_RECOGNITION` runtime permission
/// Health Connect requires as a prerequisite (see
/// [StepCountingService.hasActivityRecognitionPermission]).
///
/// Unconditional — no `Platform.isAndroid` checks anywhere in this class.
/// `createStepCountingService` (`steps/presentation/steps_providers.dart`)
/// only ever constructs this on Android; the Android `workmanager`
/// background task (`data/android_background_sync.dart`) constructs it
/// directly for the same reason (it *is* Android-only code, by
/// construction).
///
/// Health Connect has no account gate, unlike HealthKit — this app's
/// eventual iOS data source (see `ios_step_counting_service.dart`'s TODO;
/// iOS is temporarily on CMPedometer instead, §3/§14).
class AndroidStepCountingService
    with HealthPackagePedometer
    implements StepCountingService {
  AndroidStepCountingService([Health? health])
    : health = health ?? Health();

  @override
  final Health health;

  @override
  HealthDataType get walkingDistanceType => HealthDataType.DISTANCE_DELTA;

  @override
  Future<bool> hasActivityRecognitionPermission() async =>
      (await ph.Permission.activityRecognition.status).isGranted;

  @override
  Future<RuntimePermissionResult> requestActivityRecognitionPermission() async {
    final status = await ph.Permission.activityRecognition.request();
    if (status.isGranted) return RuntimePermissionResult.granted;
    if (status.isPermanentlyDenied) {
      return RuntimePermissionResult.permanentlyDenied;
    }
    return RuntimePermissionResult.denied;
  }

  @override
  Future<void> openAppSettings() => ph.openAppSettings();

  @override
  Future<HealthConnectAvailability> healthConnectAvailability() async {
    final available = await health.isHealthConnectAvailable();
    return available
        ? HealthConnectAvailability.available
        : HealthConnectAvailability.notInstalled;
  }

  @override
  Future<void> openHealthConnectInstall() => health.installHealthConnect();

  @override
  Future<bool> hasBackgroundHealthPermission() async {
    await _ensureHealthConnectReady();
    return health.isHealthDataInBackgroundAuthorized();
  }

  @override
  Future<bool> requestBackgroundHealthPermission() async {
    await _ensureHealthConnectReady();
    return health.requestHealthDataInBackgroundAuthorization();
  }

  /// Forces the `health` plugin's native side to (re-)check Health Connect
  /// availability before a background-permission call.
  ///
  /// The plugin only (re-)creates its Health-Connect-backed native helpers
  /// inside the handler for `getHealthConnectSdkStatus` — which
  /// `health.isHealthConnectAvailable()` calls. [hasStepsPermission] and
  /// [requestStepsPermission] (from [HealthPackagePedometer]) go through
  /// `health.hasPermissions()` / `requestAuthorization()`, which both call
  /// that same check as their own first step, so they self-heal.
  /// `isHealthDataInBackgroundAuthorized()` /
  /// `requestHealthDataInBackgroundAuthorization()` do not — they call
  /// straight into the native background-permission methods. If Health
  /// Connect wasn't installed yet when this app's process started, those
  /// native helpers stay uninitialized for the rest of that process's
  /// lifetime unless something else happens to trigger the check first —
  /// so even after the user installs Health Connect and grants the
  /// permission, this service kept reporting `false` until the app was
  /// killed and restarted. Calling this first closes that gap.
  Future<void> _ensureHealthConnectReady() => health.isHealthConnectAvailable();
}
