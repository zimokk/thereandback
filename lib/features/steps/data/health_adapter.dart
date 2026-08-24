import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

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
  Future<bool?> hasStepsPermission() async {
    if (!await _hasActivityRecognitionPermission()) return false;
    return _health.hasPermissions(_types, permissions: _readPermissions);
  }

  @override
  Future<bool> requestStepsPermission() async {
    if (!await _requestActivityRecognitionPermission()) return false;
    return _health.requestAuthorization(_types, permissions: _readPermissions);
  }

  /// Android only: reading [HealthDataType.STEPS] through Health Connect
  /// additionally gates on the classic dangerous runtime permission
  /// `android.permission.ACTIVITY_RECOGNITION` ("Physical activity" in the
  /// system permissions UI). `_health.hasPermissions`/`requestAuthorization`
  /// never ask for it — it's a plain Android runtime permission, not part
  /// of Health Connect's own permission screen — so without this check the
  /// app would sit at "denied" forever without the user ever having seen a
  /// prompt for it. Always granted on iOS, which has no such permission.
  Future<bool> _hasActivityRecognitionPermission() async {
    if (!Platform.isAndroid) return true;
    return (await Permission.activityRecognition.status).isGranted;
  }

  /// Shows the OS prompt for [_hasActivityRecognitionPermission]'s
  /// permission, ahead of the Health Connect prompt `requestAuthorization`
  /// shows next — see that method's doc for why this is needed at all.
  Future<bool> _requestActivityRecognitionPermission() async {
    if (!Platform.isAndroid) return true;
    return (await Permission.activityRecognition.request()).isGranted;
  }

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
  Future<bool> hasBackgroundHealthPermission() =>
      _health.isHealthDataInBackgroundAuthorized();

  @override
  Future<bool> requestBackgroundHealthPermission() =>
      _health.requestHealthDataInBackgroundAuthorization();
}
