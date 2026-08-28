import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/achievements/presentation/achievements_tab.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
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
  testWidgets('with no quest selected, the whole catalog renders locked', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AchievementsTab()));
    await tester.pump();

    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('Unlocked'), findsNothing);

    // The catalog is longer than one screen now — scroll to the last tile
    // to confirm the grid actually renders the whole thing, not just what
    // fits without scrolling.
    await tester.dragUntilVisible(
      find.text("Journey's End"),
      find.byType(GridView),
      const Offset(0, -300),
    );
    expect(find.text("Journey's End"), findsOneWidget);
    expect(find.text('Unlocked'), findsNothing);
  });

  testWidgets('crossing a threshold unlocks that tile', (tester) async {
    await tester.pumpWidget(_wrap(const AchievementsTab()));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AchievementsTab)),
    );
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    container
        .read(selectedJourneyProvider.notifier)
        .applySyncedProgress(progressMeters: 1000, syncedAt: DateTime.now());
    await tester.pump();

    expect(find.text('Unlocked'), findsOneWidget); // First Steps only
  });
}
