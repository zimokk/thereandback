import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/core/local_owner.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/journey/presentation/journey_tab.dart';
import 'package:thereandback/features/steps/data/step_sample_repository.dart';
import 'package:thereandback/features/steps/presentation/steps_providers.dart';
import 'package:thereandback/features/steps/presentation/steps_sync_state.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// A [StepsSync] with a fixed state and no health-plugin side effects — the
/// real notifier kicks off a platform-channel call from `build()`, which
/// has nothing to talk to in a widget test (`testing` skill: never a real
/// health plugin here).
class _FixedStepsSync extends StepsSync {
  _FixedStepsSync(this._state);

  final StepsSyncState _state;

  @override
  StepsSyncState build() => _state;
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );
}

void main() {
  testWidgets('shows the quest catalog when no quest is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
        ],
        child: _app(const JourneyTab()),
      ),
    );
    await tester.pump();

    expect(find.text('Choose your quest'), findsOneWidget);
    expect(find.text('Start quest'), findsOneWidget);
  });

  testWidgets('shows the path scene once a quest is selected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          stepsSyncProvider.overrideWith(
            () => _FixedStepsSync(
              const StepsSyncState(
                permissionStatus: StepsPermissionStatus.granted,
              ),
            ),
          ),
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
    await tester.pump();

    expect(find.text('Choose your quest'), findsNothing);
    expect(find.text('Troy → Ithaca'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
  });

  testWidgets(
    "the quest catalog shows each route's own percent-complete badge (this "
    'task\'s requirement — "показывай процент пройденного пути для каждого '
    'маршрута"), derived from the steps database rather than the currently '
    'active quest',
    (tester) async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      // 10% of the Odyssey's 2 850 000 m route — recorded directly, with no
      // quest ever "selected" in this test, proving the badge doesn't rely
      // on `selectedJourneyProvider`.
      await DriftStepSampleRepository(db).recordInterval(
        ownerId: localOwnerId,
        journeyId: 'odyssey-ithaca',
        intervalStart: DateTime(2026, 1, 1),
        intervalEnd: DateTime(2026, 1, 2),
        steps: 1000,
        resolvedMeters: 285000,
        flaggedPace: false,
        syncedAt: DateTime(2026, 1, 2),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: _app(const JourneyTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10%'), findsOneWidget);
    },
  );

  testWidgets(
    'the top-left "choose a quest" button returns to the catalog without '
    'clearing the active quest, and starting a quest from there lands back '
    'on the path scene — this task\'s requirement: "кнопка возврата к '
    'выбору других маршрутов"',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            stepsSyncProvider.overrideWith(
              () => _FixedStepsSync(
                const StepsSyncState(
                  permissionStatus: StepsPermissionStatus.granted,
                ),
              ),
            ),
          ],
          child: _app(const JourneyTab()),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(JourneyTab)),
      );
      final startedAt = DateTime(2026, 3, 1);
      container
          .read(selectedJourneyProvider.notifier)
          .start('odyssey-ithaca', now: startedAt);
      container
          .read(selectedJourneyProvider.notifier)
          .applySyncedProgress(
            progressMeters: 5000,
            syncedAt: startedAt.add(const Duration(days: 2)),
          );
      await tester.pump();
      expect(find.text('Troy → Ithaca'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Choose a quest'));
      await tester.pump();

      // Back on the catalog — but the quest itself is still selected, not
      // cleared (browsing is separate from `selectedJourneyProvider`). Its
      // card shows "Continue quest", not "Start quest" (bug fix — see
      // `quest_picker_view_test.dart`/`journey_providers_test.dart` for the
      // dedicated coverage of that button label and its no-reset guard).
      expect(find.text('Choose your quest'), findsOneWidget);
      expect(find.text('Continue quest'), findsOneWidget);
      expect(find.text('Start quest'), findsNothing);
      expect(
        container.read(selectedJourneyProvider)?.journeyId,
        'odyssey-ithaca',
      );

      await tester.tap(find.text('Continue quest'));
      await tester.pump();

      // Picking (the same) quest again is the way back to the path scene —
      // without resetting the progress accumulated above.
      expect(find.text('Choose your quest'), findsNothing);
      expect(find.text('Troy → Ithaca'), findsOneWidget);
      final state = container.read(selectedJourneyProvider)!;
      expect(state.progressMeters, 5000);
      expect(state.startedAt, startedAt);
    },
  );

  testWidgets('falls back to the quest catalog, not a blank scene, when the '
      "persisted journeyId doesn't resolve in the current catalog — bug fix "
      '2026-09-03: a stale/orphaned local `selected` used to satisfy '
      '`selected != null` alone and commit to the (then-blank) path scene '
      'instead of recovering to the picker, unlike `quest_stats_tab.dart`\'s '
      'own `journey == null` guard.', (tester) async {
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
        .start('a-quest-no-longer-in-the-catalog', now: DateTime.now());
    await tester.pump();

    expect(find.text('Choose your quest'), findsOneWidget);
    expect(find.text('Start quest'), findsOneWidget);
  });

  testWidgets('permission-denied state renders the gate, not a blank screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          stepsSyncProvider.overrideWith(
            () => _FixedStepsSync(
              const StepsSyncState(
                permissionStatus: StepsPermissionStatus.denied,
              ),
            ),
          ),
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
    await tester.pump();

    expect(find.text('No step data yet'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
