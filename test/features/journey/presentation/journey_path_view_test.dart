import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/core/formatters.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/design/colors.dart';
import 'package:thereandback/design/components/distance_text.dart';
import 'package:thereandback/features/achievements/data/achievement_catalog.dart';
import 'package:thereandback/features/achievements/presentation/achievement_titles.dart';
import 'package:thereandback/features/journey/presentation/journey_path_view.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// The scene's own rendering, isolated from `JourneyTab`'s catalog/gate
/// switching (`journey_tab_test.dart` covers that) — the wavy-line
/// placeholder and the traveler icon fixed at the horizontal centre
/// (§6.1's eventual "You" anchor, in placeholder form until Phase 5).
Widget _app(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders the traveler icon fixed at the horizontal centre', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
        ],
        child: _app(const JourneyPathView()),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(JourneyPathView)),
    );
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    await tester.pump();

    expect(find.byIcon(Icons.directions_walk), findsOneWidget);

    final screenWidth = tester.getSize(find.byType(JourneyPathView)).width;
    final iconCenter = tester.getCenter(find.byIcon(Icons.directions_walk));
    expect(iconCenter.dx, moreOrLessEquals(screenWidth / 2, epsilon: 1));
  });

  testWidgets(
    'dragging the scene horizontally moves the traveler icon vertically — '
    'the wavy line rising and falling under a horizontally-fixed icon '
    '(§6.1, placeholder ahead of the real Flame scene)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          ],
          child: _app(const JourneyPathView()),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(JourneyPathView)),
      );
      container
          .read(selectedJourneyProvider.notifier)
          .start('odyssey-ithaca', now: DateTime.now());
      await tester.pump();

      final beforeY = tester.getCenter(find.byIcon(Icons.directions_walk)).dy;
      final beforeX = tester.getCenter(find.byIcon(Icons.directions_walk)).dx;

      // Dragging on the painted scene area specifically (not anywhere in
      // `JourneyPathView`'s bounds, which also include the label text below
      // it) — half the placeholder wave's wavelength (see
      // journey_path_view.dart), a phase shift of exactly π, which flips
      // the sign of the wave's sin() term. The only way the traveler's
      // height could stay the same is landing exactly on sin() == 0, a
      // measure-zero coincidence for these constants and this test
      // surface's width.
      await tester.drag(
        find.byKey(const Key('journeyPathScene')),
        const Offset(-130, 0),
      );
      await tester.pump();

      final afterY = tester.getCenter(find.byIcon(Icons.directions_walk)).dy;
      final afterX = tester.getCenter(find.byIcon(Icons.directions_walk)).dx;

      expect(afterY, isNot(closeTo(beforeY, 0.5)));
      // The icon never leaves horizontal centre — only the line moves under
      // it, matching the request that drove this placeholder.
      expect(afterX, moreOrLessEquals(beforeX, epsilon: 0.5));
    },
  );

  group('achievement markers (§6.1 — start/end line, markers ahead)', () {
    testWidgets(
      'markers sit in one flat row pinned to the top of the scene, '
      'regardless of how far along the route they are',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyPathView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyPathView)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await tester.pump();

        // 'first-steps' (1000 m) and 'journeys-end' (2 850 000 m — the
        // quest's full length) sit at very different points along the
        // route, so if their marker's top ever depended on the wavy
        // placeholder line's height at that x, these two would differ.
        final firstStepsTop = tester
            .getTopLeft(find.byKey(const Key('achievementMarker-first-steps')))
            .dy;
        final journeysEndTop = tester
            .getTopLeft(
              find.byKey(const Key('achievementMarker-journeys-end')),
            )
            .dy;

        expect(journeysEndTop, moreOrLessEquals(firstStepsTop, epsilon: 0.5));
      },
    );

    testWidgets(
      'a marker ahead of progress renders muted, then gold once progress '
      'reaches its threshold — previewing without unlocking',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyPathView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyPathView)),
        );
        final notifier = container.read(selectedJourneyProvider.notifier);
        notifier.start('odyssey-ithaca', now: DateTime.now());
        await tester.pump();

        final markerFinder = find.byKey(
          const Key('achievementMarker-first-steps'),
        );
        Icon iconOf(Finder finder) => tester.widget<Icon>(
          find.descendant(of: finder, matching: find.byType(Icon)),
        );

        final beforeIcon = iconOf(markerFinder);
        expect(beforeIcon.icon, Icons.emoji_events_outlined);
        expect(beforeIcon.color, AppColors.textSecondary);

        notifier.applySyncedProgress(
          progressMeters: 1000,
          syncedAt: DateTime.now(),
        );
        await tester.pump();

        final afterIcon = iconOf(markerFinder);
        expect(afterIcon.icon, Icons.emoji_events);
        expect(afterIcon.color, AppColors.gold);
      },
    );

    testWidgets(
      'panning is clamped at point A — dragging further right past the '
      'start does nothing more once already there',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyPathView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyPathView)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await tester.pump();

        final beforeY = tester.getCenter(find.byIcon(Icons.directions_walk)).dy;

        // Already sitting at point A (fresh quest, no pan yet) — dragging
        // further right tries to go *before* the start, which the clamp in
        // _onHorizontalDragUpdate refuses.
        await tester.drag(
          find.byKey(const Key('journeyPathScene')),
          const Offset(100000, 0),
        );
        await tester.pump();

        final afterY = tester.getCenter(find.byIcon(Icons.directions_walk)).dy;
        expect(afterY, moreOrLessEquals(beforeY, epsilon: 0.5));
      },
    );

    testWidgets(
      'panning is clamped at point B — dragging past the end twice lands '
      'in the same place both times',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyPathView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyPathView)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await tester.pump();

        // Drag left by far more than the quest's own length in pixels —
        // this lands past point B, where the clamp should hold.
        await tester.drag(
          find.byKey(const Key('journeyPathScene')),
          const Offset(-1000000, 0),
        );
        await tester.pump();
        final afterFirstDrag = tester
            .getCenter(find.byIcon(Icons.directions_walk))
            .dy;

        await tester.drag(
          find.byKey(const Key('journeyPathScene')),
          const Offset(-1000000, 0),
        );
        await tester.pump();
        final afterSecondDrag = tester
            .getCenter(find.byIcon(Icons.directions_walk))
            .dy;

        expect(
          afterSecondDrag,
          moreOrLessEquals(afterFirstDrag, epsilon: 0.5),
        );
      },
    );

    testWidgets(
      'a marker shows nothing until tapped, then opens a sheet with its '
      'name and status',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            ],
            child: _app(const JourneyPathView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyPathView)),
        );
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());
        await tester.pump();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(JourneyPathView)),
        )!;
        final def = achievementCatalog.firstWhere(
          (candidate) => candidate.id == 'first-steps',
        );
        final expectedTitle = achievementTitle(l10n, def);
        final expectedStatus = l10n.achievementRemainingLabel(
          localizedDistanceInline(l10n, formatDistance(def.thresholdMeters)),
        );

        // The name/status are nowhere on screen before the tap — a marker
        // is icon-only until interacted with.
        expect(find.text(expectedTitle), findsNothing);

        await tester.tap(
          find.byKey(const Key('achievementMarker-first-steps')),
        );
        await tester.pumpAndSettle();

        expect(find.text(expectedTitle), findsOneWidget);
        expect(find.text(expectedStatus), findsOneWidget);
      },
    );
  });
}
