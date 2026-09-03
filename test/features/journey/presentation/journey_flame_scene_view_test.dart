import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/core/formatters.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/achievements/data/achievement_catalog.dart';
import 'package:thereandback/features/achievements/presentation/achievement_titles.dart';
import 'package:thereandback/features/journey/presentation/journey_flame_scene_view.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/journey/presentation/sky_gradient.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// The scene's own rendering, isolated from `JourneyTab`'s catalog/gate
/// switching (`journey_tab_test.dart` covers that). Unlike the old
/// `CustomPaint` placeholder, individual figures (the traveler, friends) are
/// painted onto one Flame canvas inside `GameWidget` rather than existing as
/// separate, `find.byKey`-able Flutter widgets — their positioning is
/// covered at the component level instead
/// (`traveler_component_test.dart`/`friend_component_test.dart`/
/// `journey_scene_test.dart`). This file only exercises what remains real
/// Flutter widgets: the two round anchor buttons, the achievement overlay,
/// and the day/distance/narrative text block.
///
/// `GameWidget`'s own game loop ticks continuously, so `pumpAndSettle()`
/// never converges here — every test below uses explicit `pump()` calls
/// instead (the same reason `flame-scene`'s own perf notes call for a
/// long-lived, always-ticking `Game`).
Widget _app(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

final _returnToYouButton = find.byKey(const Key('returnToYouButton'));
final _scene = find.byKey(const Key('journeyFlameScene'));

Future<void> _pumpFrames(WidgetTester tester, {int count = 3}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  group('JourneyFlameSceneView (§6.1 — Phase 5 Flame scene)', () {
    testWidgets('a fresh quest renders the scene with no return-to-You '
        'button — nothing to rewind to yet', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          ],
          child: _app(const JourneyFlameSceneView()),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(JourneyFlameSceneView)),
      );
      container
          .read(selectedJourneyProvider.notifier)
          .start('odyssey-ithaca', now: DateTime.now());
      await _pumpFrames(tester);

      expect(_scene, findsOneWidget);
      expect(_returnToYouButton, findsNothing);
    });

    testWidgets(
      'dragging rewound from progress shows the return-to-You button, '
      'and tapping it eventually hides it again',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyFlameSceneView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyFlameSceneView)),
        );
        final notifier = container.read(selectedJourneyProvider.notifier);
        notifier.start('odyssey-ithaca', now: DateTime.now());
        notifier.applySyncedProgress(
          progressMeters: 5000,
          syncedAt: DateTime.now(),
        );
        await _pumpFrames(tester);
        expect(_returnToYouButton, findsNothing); // still at You by default.

        await tester.drag(_scene, const Offset(200, 0));
        await _pumpFrames(tester);
        expect(_returnToYouButton, findsOneWidget);

        await tester.tap(_returnToYouButton);
        // The jump animates over 900ms (§6.1) — pump well past that.
        await _pumpFrames(tester, count: 80);
        expect(_returnToYouButton, findsNothing);
      },
    );

    testWidgets(
      'rewinding is clamped at point A — dragging further right past the '
      'start never reveals the return button',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyFlameSceneView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyFlameSceneView)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await _pumpFrames(tester);

        // Already at point A/You (fresh quest) — dragging right tries to
        // go before the start, which the clamp refuses.
        await tester.drag(_scene, const Offset(100000, 0));
        await _pumpFrames(tester);

        expect(_returnToYouButton, findsNothing);
      },
    );

    testWidgets(
      'the back-to-catalog button enters browsing mode without touching '
      'the active quest',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyFlameSceneView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyFlameSceneView)),
        );
        // `browsingCatalogProvider` is autoDispose (unlike, say,
        // `showFriendsOnMapProvider`) — in the real app `JourneyTab` keeps
        // it alive by watching it continuously; a bare `container.read`
        // here would see it reset to its default between reads, since
        // nothing else is watching it in this isolated test.
        container.listen(browsingCatalogProvider, (_, _) {});
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await _pumpFrames(tester);

        expect(container.read(browsingCatalogProvider), isFalse);

        await tester.tap(find.byIcon(Icons.map_outlined));
        await _pumpFrames(tester);

        expect(container.read(browsingCatalogProvider), isTrue);
        // The active quest is untouched — still the same journey.
        expect(
          container.read(selectedJourneyProvider)?.journeyId,
          'odyssey-ithaca',
        );
      },
    );

    testWidgets(
      'the day/distance/A→B/narrative block reflects real progress, not '
      'the rewound pan position',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyFlameSceneView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyFlameSceneView)),
        );
        final notifier = container.read(selectedJourneyProvider.notifier);
        notifier.start('odyssey-ithaca', now: DateTime.now());
        notifier.applySyncedProgress(
          progressMeters: 5230,
          syncedAt: DateTime.now(),
        );
        await _pumpFrames(tester);

        final distance = formatDistance(5230);
        expect(find.text(distance.value), findsOneWidget);

        // Rewind the view — the distance text must stay exactly the same.
        await tester.drag(_scene, const Offset(200, 0));
        await _pumpFrames(tester);
        expect(find.text(distance.value), findsOneWidget);
      },
    );

    testWidgets(
      'an achievement marker shows nothing until tapped, then opens a '
      'sheet with its name and status',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyFlameSceneView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyFlameSceneView)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await _pumpFrames(tester);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(JourneyFlameSceneView)),
        )!;
        final def = achievementCatalog.firstWhere(
          (candidate) => candidate.id == 'first-steps',
        );
        final expectedTitle = achievementTitle(l10n, def);

        expect(find.text(expectedTitle), findsNothing);

        await tester.tap(find.byKey(Key('achievementMarker-${def.id}')));
        // A modal bottom sheet's default entrance animation — settle it
        // with explicit frames rather than pumpAndSettle (the scene's game
        // loop never lets that converge).
        await _pumpFrames(tester, count: 40);

        expect(find.text(expectedTitle), findsOneWidget);
      },
    );

    testWidgets(
      'a fresh Odyssey quest feeds SkyGradient the fictional dawn hour '
      'Troy departs at (§6.1 — fictional sky, not the real device clock)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyFlameSceneView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyFlameSceneView)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        // The segment timings load asynchronously from the real
        // `locations.json` asset — pump generously past that, the same
        // margin the achievement-sheet test above gives its own async
        // settle.
        await _pumpFrames(tester, count: 40);

        final sky = tester.widget<SkyGradient>(find.byType(SkyGradient));
        // Fresh quest -> panMeters == progressMeters == 0 -> exactly
        // `troy-departure`'s departureHour from locations.json (§14
        // "Решено 2026-09-03": Troy departs at dawn).
        expect(sky.fictionalHour, 6);
      },
    );
  });
}
