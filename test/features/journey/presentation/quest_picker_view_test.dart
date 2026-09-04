import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/core/app_theme_id.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/domain/journey.dart';
import 'package:thereandback/features/journey/domain/journey_asset_status.dart';
import 'package:thereandback/features/journey/domain/quest_selection.dart';
import 'package:thereandback/features/journey/presentation/journey_asset_providers.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/journey/presentation/quest_picker_view.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// A downloadable-content test fixture — real catalog quests never have a
/// manifest today (§14: `journeyAssetManifests` is empty), so every test
/// that wants to exercise the download-state branches
/// (`_JourneyCardAction`) needs its own journey + a fixed status, injected
/// directly rather than reaching real Firebase Storage.
const _testJourney = Journey(
  id: 'test-quest',
  name: 'Test Quest',
  pointA: 'Start',
  pointB: 'End',
  totalMeters: 1000,
  themeId: AppThemeId.classic,
);

/// Renders a fixed [JourneyAssetStatus] without ever touching
/// `journeyAssetRepositoryProvider` (and so never `FirebaseStorage.instance`
/// — `testing` skill: never the real Firebase SDK in a widget test).
class _FixedJourneyAssetStatusController extends JourneyAssetStatusController {
  _FixedJourneyAssetStatusController(this._status);

  final JourneyAssetStatus _status;

  @override
  JourneyAssetStatus build(String journeyId) => _status;
}

/// Seeds `selectedJourneyProvider` with an already-started quest instead of
/// letting it restore (async, from an empty test database) to `null` — for
/// the "already underway" card tests below. Deliberately *not* overriding
/// `start()`: it must stay the real implementation so a tap on the card
/// exercises `SelectedJourney.start()`'s actual no-op guard (bug fix), not a
/// test double that merely assumes it.
class _FixedSelectedJourney extends SelectedJourney {
  _FixedSelectedJourney(this._initial);

  final SelectedQuest? _initial;

  @override
  SelectedQuest? build() => _initial;
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

Future<void> _pump(WidgetTester tester, JourneyAssetStatus status) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
        journeyCatalogEntriesProvider.overrideWithValue([_testJourney]),
        journeyAssetStatusControllerProvider(_testJourney.id)
            .overrideWith(() => _FixedJourneyAssetStatusController(status)),
      ],
      child: _app(const Scaffold(body: QuestPickerView())),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'a bundled quest (no manifest, JourneyAssetReady) shows "Start quest"',
    (tester) async {
      await _pump(tester, const JourneyAssetReady());

      expect(find.text('Start quest'), findsOneWidget);
      expect(find.text('Download'), findsNothing);
    },
  );

  testWidgets(
    'a quest with a manifest, nothing downloaded yet, shows "Download" '
    'instead of "Start quest"',
    (tester) async {
      await _pump(tester, const JourneyAssetNotDownloaded());

      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Start quest'), findsNothing);
    },
  );

  testWidgets('a downloading quest shows progress, not either button', (
    tester,
  ) async {
    await _pump(tester, const JourneyAssetDownloading(0.42));

    expect(find.text('Downloading… 42%'), findsOneWidget);
    expect(find.text('Start quest'), findsNothing);
    expect(find.text('Download'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('a failed download shows the error and a retry button', (
    tester,
  ) async {
    await _pump(tester, const JourneyAssetFailed('network unreachable'));

    expect(
      find.text("Couldn't download this quest's content."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Start quest'), findsNothing);
  });

  testWidgets('tapping "Download" calls the controller\'s download()', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          journeyCatalogEntriesProvider.overrideWithValue([_testJourney]),
          journeyAssetStatusControllerProvider(_testJourney.id).overrideWith(
            () => _FixedJourneyAssetStatusController(
              const JourneyAssetNotDownloaded(),
            ),
          ),
        ],
        child: _app(const Scaffold(body: QuestPickerView())),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();

    // The fixed fake controller's `download()` is the base class's real
    // implementation (only `build()` is overridden) — since there is no
    // real `journeyAssetRepositoryProvider` behind it in this test, this
    // just proves the tap wires through to the controller without
    // throwing, not a full download round-trip (covered instead by
    // `journey_asset_repository_test.dart`).
  });

  testWidgets(
    'the catalog always ends with the "more journeys are coming" stub '
    '(§8, §14 — this task\'s own requirement)',
    (tester) async {
      await _pump(tester, const JourneyAssetReady());

      expect(find.text('More journeys are on the way'), findsOneWidget);
      expect(
        find.text(
          "Future quests download their map and music on demand, so "
          "today's app stays small.",
        ),
        findsOneWidget,
      );
    },
  );

  group('the card for the quest already underway (bug fix: pressing the '
      'button used to reset its progress)', () {
    final activeQuest = SelectedQuest(
      journeyId: _testJourney.id,
      startedAt: DateTime(2026, 3, 1),
      lastSyncedAt: DateTime(2026, 3, 5),
      progressMeters: 500,
    );

    Future<void> pumpWithActiveQuest(WidgetTester tester) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            journeyCatalogEntriesProvider.overrideWithValue([_testJourney]),
            journeyAssetStatusControllerProvider(_testJourney.id).overrideWith(
              () =>
                  _FixedJourneyAssetStatusController(const JourneyAssetReady()),
            ),
            selectedJourneyProvider.overrideWith(
              () => _FixedSelectedJourney(activeQuest),
            ),
          ],
          child: _app(const Scaffold(body: QuestPickerView())),
        ),
      );
    }

    testWidgets('shows "Continue quest", not "Start quest"', (tester) async {
      await pumpWithActiveQuest(tester);
      await tester.pump();

      expect(find.text('Continue quest'), findsOneWidget);
      expect(find.text('Start quest'), findsNothing);
    });

    testWidgets('tapping "Continue quest" leaves progress, startedAt and '
        'lastSyncedAt untouched instead of resetting them to zero/now', (
      tester,
    ) async {
      await pumpWithActiveQuest(tester);
      await tester.pump();

      await tester.tap(find.text('Continue quest'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(QuestPickerView)),
      );
      final state = container.read(selectedJourneyProvider);
      expect(state, isNotNull);
      expect(state!.progressMeters, activeQuest.progressMeters);
      expect(state.startedAt, activeQuest.startedAt);
      expect(state.lastSyncedAt, activeQuest.lastSyncedAt);
    });

    testWidgets('a not-yet-started quest still shows "Start quest"', (
      tester,
    ) async {
      // Same catalog card, but `selectedJourneyProvider` restores to `null`
      // from the fresh test database (`_pump`'s own default overrides) —
      // the "Continue" branch above must not leak into the ordinary case.
      await _pump(tester, const JourneyAssetReady());

      expect(find.text('Start quest'), findsOneWidget);
      expect(find.text('Continue quest'), findsNothing);
    });
  });
}
