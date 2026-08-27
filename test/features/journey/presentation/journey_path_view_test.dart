import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/drift/database.dart';
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
}
