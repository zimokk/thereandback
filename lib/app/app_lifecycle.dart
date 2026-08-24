import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lifecycle.g.dart';

/// The app's current [AppLifecycleState].
///
/// Lives in `app/` rather than in a feature because it is shared
/// infrastructure: OS permission state can change while the app is
/// backgrounded — Health Connect's permission screen and Android's app
/// settings are both separate activities — so more than one feature needs
/// to re-read the platform on resume.
///
/// Features `ref.listen` this instead of each installing its own
/// [WidgetsBindingObserver]: one observer for the whole app, no feature
/// importing another's presentation layer, and a test can override this
/// provider to drive a resume without touching the real binding.
@Riverpod(keepAlive: true)
class AppLifecycle extends _$AppLifecycle {
  @override
  AppLifecycleState build() {
    final listener = AppLifecycleListener(
      onStateChange: (next) => state = next,
    );
    ref.onDispose(listener.dispose);
    return WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }
}
