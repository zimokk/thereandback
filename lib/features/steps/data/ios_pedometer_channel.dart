import 'package:flutter/services.dart';

import 'step_counting_service.dart';

/// Thin wrapper over a first-party `MethodChannel` into
/// `ios/Runner/AppDelegate.swift`'s `CMPedometer.queryPedometerData(from:to:)`
/// call.
///
/// Not a pub package: `cm_pedometer` — the one Flutter plugin that wraps
/// this exact Core Motion call — ships an Android plugin registration
/// (`androidPackage: com.hieutv.cm_pedometer`) that doesn't match its own
/// published file layout, which breaks `flutter pub get`'s plugin
/// resolution for *any* app depending on it, iOS-only usage or not (this
/// broke CI — see CLAUDE.md §14). Hand-rolling this one call as a plain
/// `MethodChannel` sidesteps needing that (or any other) plugin's Android
/// registration to be correct at all.
class IosPedometerChannel {
  const IosPedometerChannel();

  static const _channel = MethodChannel('com.zimokk.thereandback/pedometer');

  /// Steps and (if available) distance for `[from, to)`, via
  /// `CMPedometer.queryPedometerData(from:to:)`. Permission
  /// (`permission_handler`'s `Permission.sensors`) must already be granted
  /// — this makes no authorization check of its own, matching every other
  /// `fetchDelta` implementation in this app.
  Future<StepsDelta> queryPedometerData({
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'queryPedometerData',
      {
        'fromMillis': from.millisecondsSinceEpoch,
        'toMillis': to.millisecondsSinceEpoch,
      },
    );
    final steps = (result?['steps'] as int?) ?? 0;
    return StepsDelta(
      steps: steps < 0 ? 0 : steps,
      walkingDistanceMeters: (result?['distanceMeters'] as double?)?.round(),
    );
  }
}
