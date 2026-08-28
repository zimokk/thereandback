import 'package:health/health.dart';

/// One interval's worth of raw activity data, as reported by the platform.
/// Not a domain type — this is the shape the service hands to
/// `step_sync_repository.dart`, which runs it through `stride.dart` to get
/// meters (CLAUDE.md §5.1: the domain layer is the only place that does that
/// conversion).
class StepsDelta {
  const StepsDelta({required this.steps, this.walkingDistanceMeters});

  final int steps;

  /// Platform-reported `DISTANCE_WALKING_RUNNING`/`DISTANCE_DELTA`, in
  /// meters, if the platform provided one for this interval.
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
/// OS settings page ([StepCountingService.openAppSettings]), never another
/// request. §7: denial is never a dead end, so the two outcomes need to
/// drive different UI, not both collapse into one "denied" bucket.
enum RuntimePermissionResult { granted, denied, permanentlyDenied }

/// Abstraction over device step/distance counting — Health Connect on
/// Android, and, **temporarily**, Core Motion (`CMPedometer`) rather than
/// HealthKit on iOS (§3, §14: HealthKit needs a paid Apple Developer
/// Program membership CMPedometer doesn't) — so presentation and sync
/// logic can be tested with a fake instead of a real platform plugin
/// (`testing` skill: never a real health plugin in a widget test).
///
/// Exactly two concrete implementations exist, one per platform —
/// `AndroidStepCountingService` and `IosStepCountingService`
/// (`android_step_counting_service.dart`, `ios_step_counting_service.dart`)
/// — each unconditional, single-platform code with no `Platform.isAndroid`
/// branching inside it. `createStepCountingService`
/// (`steps/presentation/steps_providers.dart`) is the only place that
/// branches, so replacing either platform's implementation later (a
/// different data source, a different plugin) only ever touches that one
/// class.
abstract class StepCountingService {
  /// Must be called once before any other method.
  Future<void> configure();

  /// Nullable for HealthKit's sake, not Core Motion's: HealthKit never
  /// discloses read grants (`null` means "undetermined", per the `health`
  /// package docs) — callers should treat `null` the same as "ask the
  /// user", not as granted. `IosStepCountingService`'s current CMPedometer
  /// backing always returns a definite `bool`; a future HealthKit-based
  /// implementation is what this nullability exists for.
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
  /// service's.
  Future<StepsDelta> fetchDelta(DateTime from, DateTime to);

  /// Whether Health Connect's background-read permission is granted (§7's
  /// background-sync mechanism, Android only). Always `true` on iOS — there
  /// is no equivalent gate there; HealthKit's own background delivery has
  /// its own setup, out of scope for this service method.
  Future<bool> hasBackgroundHealthPermission();

  /// Shows the OS prompt for Health Connect's background-read permission.
  /// Always `true` on iOS, same reasoning as [hasBackgroundHealthPermission].
  Future<bool> requestBackgroundHealthPermission();
}

/// Shared `health`-package plumbing: `configure`, permission checks and
/// `fetchDelta` are identical apart from which `HealthDataType` carries
/// walking distance on each platform. An implementation-sharing detail, not
/// part of the public interface — mixing it into a class later (or
/// dropping it) is a one-line change that doesn't touch any other class.
///
/// Only `AndroidStepCountingService` uses this today —
/// `IosStepCountingService` is temporarily on CMPedometer instead of
/// HealthKit (§3, §14), so it has no `health`-package plumbing to share
/// right now. Kept general rather than folded into
/// `AndroidStepCountingService` directly so a future HealthKit-based iOS
/// implementation (see that class's TODO) can just mix this back in
/// instead of rewriting it.
mixin HealthPackagePedometer implements StepCountingService {
  /// The `Health` instance to call into — a getter, not a hardcoded
  /// `Health()`, so each concrete class can accept an injected fake in its
  /// own constructor. Neither concrete class's tests need this today, but
  /// it costs nothing to keep — the single pre-split implementation this
  /// mixin replaces had the same constructor-injection escape hatch.
  Health get health;

  /// The `HealthDataType` that carries walking distance on this platform —
  /// `DISTANCE_WALKING_RUNNING` (HealthKit) or `DISTANCE_DELTA` (Health
  /// Connect); both report meters, no unit conversion needed either way
  /// (the `health` package's own unit mapping).
  HealthDataType get walkingDistanceType;

  List<HealthDataType> get _types => [
    HealthDataType.STEPS,
    walkingDistanceType,
  ];
  static const _readPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  @override
  Future<void> configure() => health.configure();

  @override
  Future<bool?> hasStepsPermission() =>
      health.hasPermissions(_types, permissions: _readPermissions);

  @override
  Future<bool> requestStepsPermission() =>
      health.requestAuthorization(_types, permissions: _readPermissions);

  @override
  Future<StepsDelta> fetchDelta(DateTime from, DateTime to) async {
    final steps = await health.getTotalStepsInInterval(from, to) ?? 0;

    final distancePoints = await health.getHealthDataFromTypes(
      types: [walkingDistanceType],
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
      walkingDistanceMeters = total.round();
    }

    return StepsDelta(
      steps: steps < 0 ? 0 : steps,
      walkingDistanceMeters: walkingDistanceMeters,
    );
  }
}
