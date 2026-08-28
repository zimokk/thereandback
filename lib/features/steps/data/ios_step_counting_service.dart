import 'package:cm_pedometer/cm_pedometer.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'step_counting_service.dart';

/// The iOS implementation of [StepCountingService] — **temporarily** backed
/// by Core Motion's `CMPedometer` (via the `cm_pedometer` package), not
/// HealthKit.
///
/// TODO(ios-healthkit-migration): migrate back to HealthKit once this app
/// has a paid Apple Developer Program membership (CLAUDE.md §3, §14) —
/// HealthKit is an Apple capability with no free/Personal-Team signing
/// path, unlike the plain runtime permission CMPedometer uses. A complete,
/// working HealthKit-based implementation of this exact class existed
/// before this file switched to CMPedometer — `git log -p -- lib/features/
/// steps/data/ios_step_counting_service.dart` finds it (the version using
/// the `HealthPackagePedometer` mixin, same shape as
/// `android_step_counting_service.dart` today). Restoring it is a revert,
/// not a rewrite: re-add `with HealthPackagePedometer`, restore its
/// `Health health` field and `walkingDistanceType` getter
/// (`HealthDataType.DISTANCE_WALKING_RUNNING`), and drop the CMPedometer
/// calls below. Also re-enable `com.apple.developer.healthkit` in
/// `Runner.entitlements` and restore `NSHealthShareUsageDescription` in
/// `Info.plist` (both currently commented out, not deleted) — and, once a
/// `Podfile` exists, remove the `PERMISSION_SENSORS` line documented in
/// `docs/screens/steps-sync.md`.
///
/// Trade-offs versus HealthKit, accepted deliberately for now (by explicit
/// request, not a default Claude would pick — §13):
/// - Sees only this iPhone's own steps — no aggregation with an Apple
///   Watch or a third-party health app, unlike HealthKit's cross-source
///   merge.
/// - `distance` is Core Motion's own on-device estimate, not HealthKit's
///   potentially more accurate `DISTANCE_WALKING_RUNNING` aggregate — still
///   preferred over steps×stride when present, same rule as everywhere
///   else (§5.1).
/// - Core Motion retains only a rolling window of on-device history
///   (about the last 7 days) — irrelevant to this app's own delta-sync
///   model, which only ever asks for "since the last successful sync",
///   never further back.
///
/// Unconditional — no `Platform.isAndroid` checks anywhere in this class.
class IosStepCountingService implements StepCountingService {
  /// `cm_pedometer` has no equivalent to `health`'s `configure()` — nothing
  /// to initialize before querying Core Motion.
  @override
  Future<void> configure() async {}

  /// Backed by `permission_handler`'s `Permission.sensors` — the one that
  /// maps to iOS's `NSMotionUsageDescription` (Core Motion). Not
  /// `Permission.activityRecognition`: that one has no iOS mapping at all
  /// (Android-only, see `AndroidStepCountingService`), despite some
  /// `cm_pedometer` examples using it — a real, if usually harmless,
  /// mismatch in those examples.
  @override
  Future<bool?> hasStepsPermission() async =>
      (await ph.Permission.sensors.status).isGranted;

  @override
  Future<bool> requestStepsPermission() async =>
      (await ph.Permission.sensors.request()).isGranted;

  /// No Android-style prerequisite permission for CMPedometer — `sensors`
  /// above is the only gate. Matches today's HealthKit-based no-op exactly.
  @override
  Future<bool> hasActivityRecognitionPermission() async => true;

  @override
  Future<RuntimePermissionResult> requestActivityRecognitionPermission() async {
    return RuntimePermissionResult.granted;
  }

  @override
  Future<void> openAppSettings() => ph.openAppSettings();

  /// No Health-Connect-style "is it installed" concept for CMPedometer —
  /// Core Motion is part of iOS itself. Matches today's HealthKit-based
  /// no-op exactly.
  @override
  Future<HealthConnectAvailability> healthConnectAvailability() async =>
      HealthConnectAvailability.available;

  @override
  Future<void> openHealthConnectInstall() async {}

  @override
  Future<StepsDelta> fetchDelta(DateTime from, DateTime to) async {
    final data = await CMPedometer.queryPedometerData(from: from, to: to);
    final steps = data.numberOfSteps;
    return StepsDelta(
      steps: steps < 0 ? 0 : steps,
      walkingDistanceMeters: data.distance?.round(),
    );
  }

  /// No iOS background-sync mechanism exists yet for either step source
  /// (§7 — a separate open item, tied to the same Live Activity iOS
  /// follow-up). Matches today's HealthKit-based no-op exactly.
  @override
  Future<bool> hasBackgroundHealthPermission() async => true;

  @override
  Future<bool> requestBackgroundHealthPermission() async => true;
}
