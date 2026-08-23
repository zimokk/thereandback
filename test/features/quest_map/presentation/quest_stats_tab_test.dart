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
  });
}
