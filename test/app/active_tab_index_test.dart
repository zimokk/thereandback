import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/active_tab_index.dart';
import 'package:thereandback/app/app_lifecycle.dart';

/// A controllable stand-in for the real lifecycle listener (which needs a
/// live `WidgetsBinding` to receive real transitions) — same
/// subclass-and-override-`build()` shape
/// `background_music_provider_test.dart`'s `_FakeAppLifecycle` already uses.
class _FakeAppLifecycle extends AppLifecycle {
  _FakeAppLifecycle(this._initial);

  final AppLifecycleState _initial;

  @override
  AppLifecycleState build() => _initial;

  void emit(AppLifecycleState next) => state = next;
}

void main() {
  group('ActiveTabIndex (§6.1/§12 — tab-visibility signal)', () {
    test('defaults to the Путь branch (index 0), matching the router\'s '
        'initialLocation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(activeTabIndexProvider), 0);
    });

    test('set() updates the state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(activeTabIndexProvider.notifier).set(3);
      expect(container.read(activeTabIndexProvider), 3);
    });

    test('set() with the already-current value is a no-op (cheap to call '
        'on every AppShell rebuild)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var notificationCount = 0;
      container.listen(activeTabIndexProvider, (_, _) => notificationCount++);

      container.read(activeTabIndexProvider.notifier).set(0); // already 0.
      expect(notificationCount, 0);

      container.read(activeTabIndexProvider.notifier).set(1);
      expect(notificationCount, 1);
      container.read(activeTabIndexProvider.notifier).set(1); // no change.
      expect(notificationCount, 1);
    });
  });

  group('journeySceneActiveProvider (§6.1/§12 — game loop pause signal)', () {
    late _FakeAppLifecycle lifecycle;
    late ProviderContainer container;

    setUp(() {
      lifecycle = _FakeAppLifecycle(AppLifecycleState.resumed);
      container = ProviderContainer(
        overrides: [appLifecycleProvider.overrideWith(() => lifecycle)],
      );
      addTearDown(container.dispose);
    });

    test('true only when on the Путь tab AND the app is foregrounded', () {
      // Fresh container: Путь tab (default) + resumed (default) → active.
      expect(container.read(journeySceneActiveProvider), isTrue);

      // Switch away from the Путь tab.
      container.read(activeTabIndexProvider.notifier).set(1);
      expect(container.read(journeySceneActiveProvider), isFalse);

      // Back on the Путь tab, but the app itself is backgrounded.
      container.read(activeTabIndexProvider.notifier).set(0);
      lifecycle.emit(AppLifecycleState.paused);
      expect(container.read(journeySceneActiveProvider), isFalse);

      // Foregrounded again.
      lifecycle.emit(AppLifecycleState.resumed);
      expect(container.read(journeySceneActiveProvider), isTrue);
    });
  });
}
