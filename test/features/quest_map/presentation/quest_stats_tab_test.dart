import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/quest_map/presentation/quest_stats_tab.dart';
import 'package:thereandback/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    // `testing` skill: never a real drift database in a test.
    overrides: [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows the empty state before any quest is selected', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const QuestStatsTab()));
    await tester.pump();

    expect(find.text('No quest yet'), findsOneWidget);
    expect(find.text('Go to Path'), findsOneWidget);
  });

  testWidgets('shows quest totals, start date and a dash ETA at zero pace', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const QuestStatsTab()));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(QuestStatsTab)),
    );
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    await tester.pump();

    expect(find.text('No quest yet'), findsNothing);
    expect(find.text('2850'), findsOneWidget); // total route length, km
    expect(find.text('To Ithaca'), findsOneWidget);
    expect(find.text('Quest Started'), findsOneWidget);
    expect(find.text('Estimated Arrival'), findsOneWidget);
    // Zero progress means zero pace, which renders a dash, never a date
    // (§5.3).
    expect(find.text('—'), findsOneWidget);

    // The drawn map section follows the stats — no heading above it
    // anymore (styling fix: "убери надпись route map"), just the map
    // itself. This one reads the real bundled
    // `assets/journeys/odyssey-ithaca/map.json` (no bundle override here on
    // purpose), so it also proves the asset is wired into pubspec.yaml —
    // QuestMapView's own test covers the rendering states.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('questMapRouteOverlay')), findsOneWidget);
    // The illustration itself is bundled too, so the overlay renders over
    // the drawing rather than over the no-art fallback.
    expect(find.byType(Image), findsOneWidget);
  });
}
