import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// One interval's worth of raw activity data, as reported by the platform.
/// Not a domain type — this is the shape the adapter hands to
/// `step_sync_repository.dart`, which runs it through `stride.dart` to get
/// meters (CLAUDE.md §5.1: the domain layer is the only place that does that
/// conversion).
class StepsDelta {
  const StepsDelta({required this.steps, this.walkingDistanceMeters});

  final int steps;

  /// Platform-reported `DISTANCE_WALKING_RUNNING`, in meters, if the
  /// platform provided one for this interval.
  final int? walkingDistanceMeters;
}

/// What the health-connect availability check on Android can report.
enum HealthConnectAvailability {
  /// Not applicable — iOS always reports available (§7).
  available,
  notInstalled,
}

/// Outcome of asking for a dangerous-protection-level OS runtime permission
/// (currently just `ACTIVITY_RECOGNITION`). Android auto-treats a second
/// denial of the same permission as "don't ask again" (`USER_FIXED`,
/// Android 11+): a third request shows no dialog at all and resolves
/// straight to [permanentlyDenied], so the only way forward is the app's
/// OS settings page ([HealthAdapter.openAppSettings]), never another
/// request. §7: denial is never a dead end, so the two outcomes need to
/// drive different UI, not both collapse into one "denied" bucket.
enum RuntimePermissionResult { granted, denied, permanentlyDenied }

/// Abstraction over the `health` package (HealthKit / Health Connect, §3),
/// so presentation and sync logic can be tested with a fake instead of the
/// real platform plugin (`testing` skill: never a real health plugin in a
/// widget test).
abstract class HealthAdapter {
  /// Must be called once before any other method.
  Future<void> configure();

  /// `null` on iOS means "undetermined" (HealthKit never discloses read
  /// grants, per the `health` package docs) — callers should treat `null`
  /// the same as "ask the user", not as granted.
  Future<bool?> hasStepsPermission();

  /// Shows the OS permission prompt. Returns whether the prompt was shown
  /// successfully — on iOS this is not the same as "granted" (§7 caveat
  /// carried over from `hasStepsPermission`).
  Future<bool> requestStepsPermission();

  /// Android's `ACTIVITY_RECOGNITION` runtime permission (shows as "Physical
  /// activity" in system settings) — a dangerous-protection-level OS
  /// permission, separate from and a prerequisite for Health Connect's own
  /// per-type consent screen ("Fitness and wellness"): Health Connect will
  /// not hand over the Steps/Distance read grant while this is missing, no
  /// matter how many times [requestStepsPermission] is called. Declaring it
  /// in the manifest is not enough on Android 10+ — it must be requested at
  /// runtime. Always `true` on iOS, which has no such permission.
  Future<bool> hasActivityRecognitionPermission();

  /// Shows the OS "Physical activity" runtime prompt. Must be called, and
  /// granted, before [requestStepsPermission] — see
  /// [hasActivityRecognitionPermission]. Always [RuntimePermissionResult.granted]
  /// on iOS. See [RuntimePermissionResult] for what
  /// [RuntimePermissionResult.permanentlyDenied] means and how a caller
  /// should react to it (never call this again — go to [openAppSettings]).
  Future<RuntimePermissionResult> requestActivityRecognitionPermission();

  /// Opens this app's page in the OS settings app — the only way left to
  /// grant a permission once [RuntimePermissionResult.permanentlyDenied]
  /// has been reached.
  Future<void> openAppSettings();

  /// Android-only meaningful check; always [HealthConnectAvailability.available]
  /// on iOS (§7: Health Connect can be missing on Android and must be
  /// handled explicitly, not assumed present).
  Future<HealthConnectAvailability> healthConnectAvailability();

  /// Deep-links to the Play Store listing for Health Connect.
  Future<void> openHealthConnectInstall();

  /// Steps and (if available) walking distance for `[from, to)`. Never
  /// negative — a platform quirk that reports a negative delta is the
  /// caller's problem to clamp (`stride.clampNonDecreasing`), not this
  /// adapter's.
  Future<StepsDelta> fetchDelta(DateTime from, DateTime to);

  /// Whether Health Connect's background-read permission is granted (§7's
  /// background-sync mechanism, Android only). Always `true` on iOS — there
  /// is no equivalent gate there; HealthKit's own background delivery has
  /// its own setup, out of scope for this adapter method.
  Future<bool> hasBackgroundHealthPermission();

  /// Shows the OS prompt for Health Connect's background-read permission.
  /// Always `true` on iOS, same reasoning as [hasBackgroundHealthPermission].
  Future<bool> requestBackgroundHealthPermission();
}

/// Real implementation backed by the `health` package.
class HealthPackageAdapter implements HealthAdapter {
  HealthPackageAdapter([Health? health]) : _health = health ?? Health();

  final Health _health;

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
  ];
  static const _readPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  @override
  Future<void> configure() => _health.configure();

  @override
  Future<bool?> hasStepsPermission() =>
      _health.hasPermissions(_types, permissions: _readPermissions);

  @override
  Future<bool> requestStepsPermission() =>
      _health.requestAuthorization(_types, permissions: _readPermissions);

  @override
  Future<bool> hasActivityRecognitionPermission() async {
    if (!Platform.isAndroid) return true;
    return (await ph.Permission.activityRecognition.status).isGranted;
  }

  @override
  Future<RuntimePermissionResult> requestActivityRecognitionPermission() async {
    if (!Platform.isAndroid) return RuntimePermissionResult.granted;
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
    final available = await _health.isHealthConnectAvailable();
    return available
        ? HealthConnectAvailability.available
        : HealthConnectAvailability.notInstalled;
  }

  @override
  Future<void> openHealthConnectInstall() => _health.installHealthConnect();

  @override
  Future<StepsDelta> fetchDelta(DateTime from, DateTime to) async {
    final steps = await _health.getTotalStepsInInterval(from, to) ?? 0;

    final distancePoints = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.DISTANCE_WALKING_RUNNING],
      startTime: from,
      endTime: to,
    );

    int? walkingDistanceMeters;
    if (distancePoints.isNotEmpty) {
      var total = 0.0;
      for (final point in distancePoints) {
        final value = point.value;
        if (value is NumericHealthValue) {
          total += value.numericValue.toDouble();
        }
      }
      // HealthDataType.DISTANCE_WALKING_RUNNING is reported in meters
      // (health package's own unit mapping) — no conversion needed.
      walkingDistanceMeters = total.round();
    }

    return StepsDelta(
      steps: steps < 0 ? 0 : steps,
      walkingDistanceMeters: walkingDistanceMeters,
    );
  }

  @override
  Future<bool> hasBackgroundHealthPermission() async {
    await _ensureHealthConnectReady();
    return _health.isHealthDataInBackgroundAuthorized();
  }

  @override
  Future<bool> requestBackgroundHealthPermission() async {
    await _ensureHealthConnectReady();
    return _health.requestHealthDataInBackgroundAuthorization();
  }

  /// Forces the `health` plugin's native side to (re-)check Health Connect
  /// availability before a background-permission call.
  ///
  /// The plugin only (re-)creates its Health-Connect-backed native helpers
  /// inside the handler for `getHealthConnectSdkStatus` — which
  /// `_health.isHealthConnectAvailable()` calls. [hasStepsPermission] and
  /// [requestStepsPermission] go through `_health.hasPermissions()` /
  /// `requestAuthorization()`, which both call that same check as their own
  /// first step, so they self-heal. `isHealthDataInBackgroundAuthorized()` /
  /// `requestHealthDataInBackgroundAuthorization()` do not — they call
  /// straight into the native background-permission methods. If Health
  /// Connect wasn't installed yet when this app's process started, those
  /// native helpers stay uninitialized for the rest of that process's
  /// lifetime unless something else happens to trigger the check first —
  /// so even after the user installs Health Connect and grants the
  /// permission, this adapter kept reporting `false` until the app was
  /// killed and restarted. Calling this first closes that gap.
  Future<void> _ensureHealthConnectReady() async {
    if (!Platform.isAndroid) return;
    await _health.isHealthConnectAvailable();
  }
}
