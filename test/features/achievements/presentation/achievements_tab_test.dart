import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/core/local_owner.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/achievements/presentation/achievements_tab.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/l10n/app_localizations.dart';

Widget _wrap(Widget child, {AppDatabase? database}) {
  return ProviderScope(
    // `testing` skill: never a real drift database in a test.
    overrides: [
      appDatabaseProvider.overrideWithValue(
        database ?? AppDatabase.forTesting(),
      ),
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

/// Seeds a raw unlock row directly — the widget only ever reads this table
/// (`achievementUnlocksProvider`), so tests exercise its rendering without
/// going through a real step sync.
Future<void> _seedUnlock(
  AppDatabase db, {
  required String achievementId,
  required DateTime localDate,
}) {
  return db
      .into(db.achievementUnlockRows)
      .insert(
        AchievementUnlockRowsCompanion.insert(
          ownerId: localOwnerId,
          achievementId: achievementId,
          unlockedLocalDate: DateTime.utc(
            localDate.year,
            localDate.month,
            localDate.day,
          ),
        ),
      );
}

void main() {
  testWidgets('with no quest selected, the whole quest catalog renders '
      'locked', (tester) async {
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

  testWidgets('tapping an unlocked quest tile shows the day it was earned', (
    tester,
  ) async {
    final db = AppDatabase.forTesting();
    await _seedUnlock(
      db,
      achievementId: 'first-steps',
      localDate: DateTime(2026, 3, 10),
    );
    await tester.pumpWidget(_wrap(const AchievementsTab(), database: db));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AchievementsTab)),
    );
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    container
        .read(selectedJourneyProvider.notifier)
        .applySyncedProgress(progressMeters: 1000, syncedAt: DateTime.now());
    await tester.pumpAndSettle();

    await tester.tap(find.text('First Steps'));
    await tester.pumpAndSettle();

    expect(find.text('Dates reached'), findsOneWidget);
    expect(find.text('Mar 10, 2026'), findsOneWidget);
    await db.close();
  });

  testWidgets(
    'the Daily sub-tab lists its own catalog, separate from the quest one',
    (tester) async {
      await tester.pumpWidget(_wrap(const AchievementsTab()));
      await tester.pump();

      expect(find.text('Quest'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);

      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      expect(find.text('1 kilometer in a day'), findsOneWidget);
      expect(find.text('5 kilometers in a day'), findsOneWidget);
      expect(find.text('Not yet reached'), findsWidgets);
    },
  );

  testWidgets(
    'a daily trophy earned on more than one day badges the count and lists '
    'every day on tap',
    (tester) async {
      final db = AppDatabase.forTesting();
      await _seedUnlock(
        db,
        achievementId: 'daily-1km',
        localDate: DateTime(2026, 3, 10),
      );
      await _seedUnlock(
        db,
        achievementId: 'daily-1km',
        localDate: DateTime(2026, 3, 12),
      );
      await tester.pumpWidget(_wrap(const AchievementsTab(), database: db));
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      expect(find.text('×2'), findsOneWidget);

      await tester.tap(find.text('1 kilometer in a day'));
      await tester.pumpAndSettle();

      expect(find.text('Dates reached'), findsOneWidget);
      expect(find.text('Mar 10, 2026'), findsOneWidget);
      expect(find.text('Mar 12, 2026'), findsOneWidget);
      await db.close();
    },
  );

  testWidgets('a daily trophy earned exactly once shows no count badge', (
    tester,
  ) async {
    final db = AppDatabase.forTesting();
    await _seedUnlock(
      db,
      achievementId: 'daily-1km',
      localDate: DateTime(2026, 3, 10),
    );
    await tester.pumpWidget(_wrap(const AchievementsTab(), database: db));
    await tester.tap(find.text('Daily'));
    await tester.pumpAndSettle();

    expect(find.textContaining('×'), findsNothing);
    await db.close();
  });
}
