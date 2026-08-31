import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'features/steps/data/android_background_sync.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide the Android navigation bar app-wide: `immersiveSticky` keeps it
  // hidden and brings it back — semi-transparent, over the content — on a
  // swipe from the bottom edge, then hides it again on its own. Applied
  // once here rather than per-screen: Android has no clean way to toggle
  // this per-route without a visible flash of the bars on every navigation,
  // and the "Путь" scene (§6.1) is full-screen enough that the rest of the
  // app staying immersive too is more consistent than bars reappearing
  // between tabs. `SystemUiMode.immersiveSticky` has no effect on iOS (no
  // equivalent chrome to hide there), so this is gated to Android like the
  // other Android-only setup below.
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // Without this, every Firebase call in the app (silent anonymous
  // sign-in on launch, the Google upgrade, Firestore) fails with
  // "[core/no-app] No Firebase App '[DEFAULT]' has been created" — the
  // FlutterFire CLI generates `firebase_options.dart` (§3, §8) but does not
  // wire this call into `main()` itself. `AuthController._bootstrap()`
  // (`app/auth_provider.dart`) swallows that failure silently by design
  // (no network on first launch is a real, expected case there too), which
  // is why a missing call here previously had no visible symptom until the
  // Google upgrade flow surfaced it.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registers the callback dispatcher `workmanager` invokes from its own
  // background isolate — cheap and idempotent, safe to call every launch
  // even before the lock-screen feature (`lock_screen_controller.dart`) is
  // ever turned on; `AndroidBackgroundSync.register()` is what actually
  // schedules work. Android-only: that's the only platform this feature
  // has an implementation for today (see `lockScreenSupportedProvider`).
  if (Platform.isAndroid) {
    Workmanager().initialize(androidBackgroundSyncCallbackDispatcher);
  }

  runApp(const ProviderScope(child: ThereAndBackApp()));
}
