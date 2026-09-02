import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/active_tab_index.dart';
import 'package:thereandback/app/app_lifecycle.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/presentation/journey_flame_scene_view.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/journey/presentation/journey_tab.dart';
import 'package:thereandback/features/journey/presentation/journey_scene.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// Same controllable stand-in `background_music_provider_test.dart`'s
/// `_FakeAppLifecycle` and `active_tab_index_test.dart` already use.
class _FakeAppLifecycle extends AppLifecycle {
  _FakeAppLifecycle(this._initial);
  final AppLifecycleState _initial;

  @override
  AppLifecycleState build() => _initial;

  void emit(AppLifecycleState next) => state = next;
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 3}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// The scene's own `FlameGame.paused` flag — read through the mounted
/// `GameWidget` rather than any private field, since `journey_flame_scene_
/// view.dart`'s `JourneyScene` is otherwise only reachable from inside its
/// own `State`.
bool _scenePaused(WidgetTester tester) => tester
    .widget<GameWidget<JourneyScene>>(find.byType(GameWidget<JourneyScene>))
    .game!
    .paused;

void main() {
  group('JourneyFlameSceneView game-loop pause (§6.1/§12)', () {
    late _FakeAppLifecycle lifecycle;
    late ProviderContainer container;

    setUp(() {
      lifecycle = _FakeAppLifecycle(AppLifecycleState.resumed);
    });

    testWidgets(
      'paused while another bottom-nav tab is selected, resumed back on '
      'the Путь tab',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
              appLifecycleProvider.overrideWith(() => lifecycle),
            ],
            child: _app(const JourneyFlameSceneView()),
          ),
        );
        container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyFlameSceneView)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await _pumpFrames(tester);

        expect(_scenePaused(tester), isFalse);

        // Simulate AppShell's own bottom-nav switch (`app_shell.dart`'s
        // post-frame push into `activeTabIndexProvider`) — this widget
        // itself is `JourneyTab`-branch content, so `AppShell` would stay
        // mounted with this branch merely unpainted; the pause has to come
        // from the provider, not from unmounting.
        container.read(activeTabIndexProvider.notifier).set(1);
        await _pumpFrames(tester);
        expect(_scenePaused(tester), isTrue);

        container.read(activeTabIndexProvider.notifier).set(0);
        await _pumpFrames(tester);
        expect(_scenePaused(tester), isFalse);
      },
    );

    testWidgets('paused while the app itself is backgrounded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            appLifecycleProvider.overrideWith(() => lifecycle),
          ],
          child: _app(const JourneyFlameSceneView()),
        ),
      );
      container = ProviderScope.containerOf(
        tester.element(find.byType(JourneyFlameSceneView)),
      );
      container
          .read(selectedJourneyProvider.notifier)
          .start('odyssey-ithaca', now: DateTime.now());
      await _pumpFrames(tester);
      expect(_scenePaused(tester), isFalse);

      lifecycle.emit(AppLifecycleState.paused);
      await _pumpFrames(tester);
      expect(_scenePaused(tester), isTrue);

      lifecycle.emit(AppLifecycleState.resumed);
      await _pumpFrames(tester);
      expect(_scenePaused(tester), isFalse);
    });
  });

  group('browsing-catalog round trip (§6.1 — back-to-catalog button)', () {
    testWidgets(
      'leaving for the catalog and returning remounts a single, fresh '
      'scene — never two at once',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyTab()),
          ),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyTab)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await _pumpFrames(tester);

        expect(find.byType(JourneyFlameSceneView), findsOneWidget);
        expect(find.byType(GameWidget<JourneyScene>), findsOneWidget);

        await tester.tap(find.byIcon(Icons.map_outlined));
        await _pumpFrames(tester);

        // Browsing the catalog swaps this branch's content entirely
        // (`journey_tab.dart`) — the scene is genuinely unmounted, not
        // merely hidden.
        expect(find.byType(JourneyFlameSceneView), findsNothing);
        expect(find.byType(GameWidget<JourneyScene>), findsNothing);

        container.read(browsingCatalogProvider.notifier).exit();
        await _pumpFrames(tester);

        // Back on the Путь tab — exactly one fresh scene, not a leftover
        // stacked on a new one.
        expect(find.byType(JourneyFlameSceneView), findsOneWidget);
        expect(find.byType(GameWidget<JourneyScene>), findsOneWidget);
        expect(_scenePaused(tester), isFalse);
      },
    );
  });
}
