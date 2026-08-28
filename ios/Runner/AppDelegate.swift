import CoreMotion
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Backs the `com.zimokk.thereandback/pedometer` channel below — a
  // first-party MethodChannel, not a pub package. `cm_pedometer` (the one
  // package that wraps `CMPedometer.queryPedometerData` for Flutter) ships
  // an Android plugin registration (`androidPackage:
  // com.hieutv.cm_pedometer`) that doesn't match its own published file
  // layout, which breaks `flutter pub get`'s plugin resolution for *any*
  // app depending on it — iOS-only usage or not (CLAUDE.md §14). Core
  // Motion is a system framework, so this needs no CocoaPods entry either.
  private let pedometer = CMPedometer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let pedometerChannel = FlutterMethodChannel(
      name: "com.zimokk.thereandback/pedometer",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    pedometerChannel.setMethodCallHandler { [weak self] call, result in
      self?.handlePedometerCall(call, result: result)
    }
  }

  // Dart side: `lib/features/steps/data/ios_pedometer_channel.dart` — keep
  // both in sync when changing either. Permission is handled entirely on
  // the Dart side via `permission_handler`'s `Permission.sensors` before
  // this is ever called; this handler doesn't check authorization itself.
  private func handlePedometerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "queryPedometerData" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let fromMillis = args["fromMillis"] as? Int,
      let toMillis = args["toMillis"] as? Int
    else {
      result(
        FlutterError(
          code: "bad_args",
          message: "queryPedometerData needs fromMillis/toMillis",
          details: nil
        )
      )
      return
    }

    let from = Date(timeIntervalSince1970: Double(fromMillis) / 1000)
    let to = Date(timeIntervalSince1970: Double(toMillis) / 1000)
    pedometer.queryPedometerData(from: from, to: to) { data, error in
      if let error = error {
        result(
          FlutterError(
            code: "pedometer_error",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }
      let distanceValue: Any = data?.distance?.doubleValue ?? NSNull()
      result([
        "steps": data?.numberOfSteps ?? 0,
        "distanceMeters": distanceValue,
      ])
    }
  }
}
