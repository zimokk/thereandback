import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'features/steps/data/android_background_sync.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
