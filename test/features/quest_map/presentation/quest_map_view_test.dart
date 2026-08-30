import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/quest_map/presentation/quest_map_providers.dart';
import 'package:thereandback/features/quest_map/presentation/quest_map_view.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// A bundle holding nothing but the strings a test hands it — no real
/// assets, and no asset manifest, so the illustration always reads as
/// "not bundled" (`testing` skill).
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.contents);

  final Map<String, String> contents;

  @override
  Future<ByteData> load(String key) async {
    final value = contents[key];
    if (value == null) throw FlutterError('no asset bundled at $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

const _mapJson = '''
{
  "journeyId": "odyssey-ithaca",
  "totalMeters": 2850000,
  "image": {
    "asset": "assets/journeys/odyssey-ithaca/map.webp",
    "width": 1024,
    "height": 1536
  },
  "path": [
    {"x": 0.9, "y": 0.4, "meters": 0},
    {"x": 0.5, "y": 0.6, "meters": 1425000},
    {"x": 0.1, "y": 0.1, "meters": 2850000}
  ],
  "landmarks": [
    {"id": "troy", "name": "Troy", "x": 0.9, "y": 0.4, "meters": 0},
    {"id": "calypso", "name": "Calypso", "x": 0.5, "y": 0.6, "meters": 1425000},
    {"id": "ithaca", "name": "Ithaca", "x": 0.1, "y": 0.1, "meters": 2850000}
  ]
}
''';

Widget _wrap(Widget child, {required AssetBundle bundle}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      questMapBundleProvider.overrideWithValue(bundle),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // The tab hosts the map inside a ListView (the map is taller than a
      // phone screen); a test that puts it in a bare Scaffold would only be
      // testing an overflow.
      home: Scaffold(body: ListView(children: [child])),
    ),
  );
}

Future<void> _startQuest(WidgetTester tester) async {
  ProviderScope.containerOf(tester.element(find.byType(QuestMapView)))
      .read(selectedJourneyProvider.notifier)
      .start('odyssey-ithaca', now: DateTime.now());
  await tester.pumpAndSettle();
}

/// The screen point for a normalized `(nx, ny)` map coordinate, computed
/// from the route overlay's actual laid-out size rather than a hardcoded
/// pixel guess — the same mapping [QuestMapView] itself uses.
Offset _pointOn(WidgetTester tester, double nx, double ny) {
  final rect = tester.getRect(find.byKey(const Key('questMapRouteOverlay')));
  return rect.topLeft + Offset(rect.width * nx, rect.height * ny);
}

/// Grows the test surface enough that the whole map (taller than it is
/// wide — the illustration's own 2:3 ratio) lays out without the `ListView`
/// scrolling any of it off-screen. `tester.tapAt` dispatches at a raw
/// screen coordinate — a point past the default 800×600 surface's edge
/// silently hits nothing, which only the tap-driven tests below need to
/// worry about (`find.text` walks the element tree regardless of what's
/// actually painted, so every other test here is unaffected either way).
void _growViewportForTapping(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 1900);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders the overlay and illustration, with no route line '
      'drawn — the traveler moves along it invisibly', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        QuestMapView(progressMeters: 0, startedAt: DateTime.now()),
        bundle: _FakeBundle({
          'assets/journeys/odyssey-ithaca/map.json': _mapJson,
        }),
      ),
    );
    await _startQuest(tester);

    expect(find.byKey(const Key('questMapRouteOverlay')), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    // The traveler's marker is painted, not a widget — the overlay carries
    // its accessibility label instead.
    expect(find.bySemanticsLabel('Your position on the route'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('names the next landmark and how far it still is', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        // A quarter of the way to Calypso, the first landmark ahead.
        QuestMapView(progressMeters: 425000, startedAt: DateTime.now()),
        bundle: _FakeBundle({
          'assets/journeys/odyssey-ithaca/map.json': _mapJson,
        }),
      ),
    );
    await _startQuest(tester);

    expect(find.text('Ahead: Calypso — 1000 kilometers to go'), findsOneWidget);
  });

  testWidgets('says every landmark is behind you at the end of the route', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        QuestMapView(progressMeters: 2850000, startedAt: DateTime.now()),
        bundle: _FakeBundle({
          'assets/journeys/odyssey-ithaca/map.json': _mapJson,
        }),
      ),
    );
    await _startQuest(tester);

    expect(
      find.text('Every landmark on this route is behind you.'),
      findsOneWidget,
    );
  });

  testWidgets('still draws the overlay when the illustration is not bundled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        QuestMapView(progressMeters: 100000, startedAt: DateTime.now()),
        bundle: _FakeBundle({
          'assets/journeys/odyssey-ithaca/map.json': _mapJson,
        }),
      ),
    );
    await _startQuest(tester);

    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const Key('questMapRouteOverlay')), findsOneWidget);
    expect(
      find.textContaining("The drawn map isn't in this build yet"),
      findsOneWidget,
    );
  });

  testWidgets('falls back to a notice when the quest ships no map.json', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        QuestMapView(progressMeters: 0, startedAt: DateTime.now()),
        bundle: _FakeBundle({}),
      ),
    );
    await _startQuest(tester);

    expect(find.byKey(const Key('questMapRouteOverlay')), findsNothing);
    expect(find.text("This quest's map couldn't be loaded."), findsOneWidget);
  });

  testWidgets('renders nothing before a quest is selected', (tester) async {
    await tester.pumpWidget(
      _wrap(
        QuestMapView(progressMeters: 0, startedAt: DateTime.now()),
        bundle: _FakeBundle({
          'assets/journeys/odyssey-ithaca/map.json': _mapJson,
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('questMapRouteOverlay')), findsNothing);
  });

  group('tapping the traveler marker', () {
    testWidgets('opens a stat bubble with the day and distance walked', (
      tester,
    ) async {
      _growViewportForTapping(tester);
      await tester.pumpWidget(
        _wrap(
          // Started right now, so this is unambiguously Day 1 regardless
          // of what the calendar date happens to be at test time.
          QuestMapView(progressMeters: 500000, startedAt: DateTime.now()),
          bundle: _FakeBundle({
            'assets/journeys/odyssey-ithaca/map.json': _mapJson,
          }),
        ),
      );
      await _startQuest(tester);
      expect(find.byKey(const Key('questMapTravelerTooltip')), findsNothing);

      // 500 000 m is 500 000 / 1 425 000 of the way from Troy (0.9, 0.4) to
      // Calypso (0.5, 0.6), the path's first vertex pair.
      await tester.tapAt(_pointOn(tester, 0.75965, 0.47018));
      await tester.pump();

      expect(find.byKey(const Key('questMapTravelerTooltip')), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('500 kilometers'), findsOneWidget);
    });

    testWidgets('tapping the traveler again closes the bubble', (tester) async {
      _growViewportForTapping(tester);
      await tester.pumpWidget(
        _wrap(
          QuestMapView(progressMeters: 0, startedAt: DateTime.now()),
          bundle: _FakeBundle({
            'assets/journeys/odyssey-ithaca/map.json': _mapJson,
          }),
        ),
      );
      await _startQuest(tester);

      final travelerPoint = _pointOn(tester, 0.9, 0.4); // Troy — 0 m.
      await tester.tapAt(travelerPoint);
      await tester.pump();
      expect(find.byKey(const Key('questMapTravelerTooltip')), findsOneWidget);

      await tester.tapAt(travelerPoint);
      await tester.pump();
      expect(find.byKey(const Key('questMapTravelerTooltip')), findsNothing);
    });
  });

  group('tapping a landmark', () {
    testWidgets('ahead of the traveler shows how far it still is', (
      tester,
    ) async {
      _growViewportForTapping(tester);
      await tester.pumpWidget(
        _wrap(
          QuestMapView(progressMeters: 425000, startedAt: DateTime.now()),
          bundle: _FakeBundle({
            'assets/journeys/odyssey-ithaca/map.json': _mapJson,
          }),
        ),
      );
      await _startQuest(tester);

      await tester.tapAt(_pointOn(tester, 0.5, 0.6)); // Calypso — 1 425 000 m.
      await tester.pump();

      expect(find.byKey(const Key('questMapLandmarkTooltip')), findsOneWidget);
      expect(find.text('Ahead: Calypso — 1000 kilometers to go'), findsWidgets);
    });

    testWidgets('already behind the traveler shows how far past it they '
        'are', (tester) async {
      _growViewportForTapping(tester);
      await tester.pumpWidget(
        _wrap(
          QuestMapView(progressMeters: 425000, startedAt: DateTime.now()),
          bundle: _FakeBundle({
            'assets/journeys/odyssey-ithaca/map.json': _mapJson,
          }),
        ),
      );
      await _startQuest(tester);

      await tester.tapAt(_pointOn(tester, 0.9, 0.4)); // Troy — 0 m.
      await tester.pump();

      expect(find.byKey(const Key('questMapLandmarkTooltip')), findsOneWidget);
      expect(find.text('Behind: Troy — 425 kilometers ago'), findsOneWidget);
    });

    testWidgets('tapping empty water dismisses an open tooltip', (
      tester,
    ) async {
      _growViewportForTapping(tester);
      await tester.pumpWidget(
        _wrap(
          QuestMapView(progressMeters: 425000, startedAt: DateTime.now()),
          bundle: _FakeBundle({
            'assets/journeys/odyssey-ithaca/map.json': _mapJson,
          }),
        ),
      );
      await _startQuest(tester);

      await tester.tapAt(_pointOn(tester, 0.9, 0.4)); // Troy.
      await tester.pump();
      expect(find.byKey(const Key('questMapLandmarkTooltip')), findsOneWidget);

      await tester.tapAt(_pointOn(tester, 0.05, 0.9)); // Empty corner.
      await tester.pump();
      expect(find.byKey(const Key('questMapLandmarkTooltip')), findsNothing);
    });

    testWidgets('selecting a different landmark switches the tooltip '
        'directly, without needing a dismiss tap first', (tester) async {
      _growViewportForTapping(tester);
      await tester.pumpWidget(
        _wrap(
          QuestMapView(progressMeters: 425000, startedAt: DateTime.now()),
          bundle: _FakeBundle({
            'assets/journeys/odyssey-ithaca/map.json': _mapJson,
          }),
        ),
      );
      await _startQuest(tester);

      await tester.tapAt(_pointOn(tester, 0.9, 0.4)); // Troy.
      await tester.pump();
      expect(find.text('Behind: Troy — 425 kilometers ago'), findsOneWidget);

      await tester.tapAt(_pointOn(tester, 0.5, 0.6)); // Calypso.
      await tester.pump();
      expect(find.text('Behind: Troy — 425 kilometers ago'), findsNothing);
      expect(find.text('Ahead: Calypso — 1000 kilometers to go'), findsWidgets);
    });
  });

  group('emojiForLandmarkId', () {
    // Every id the shipped Odyssey map.json actually uses — see
    // assets/journeys/odyssey-ithaca/map.json.
    const shippedIds = [
      'troy',
      'aeaea-circe',
      'lotus-eaters',
      'calypso',
      'scylla-charybdis',
      'sirens',
      'ithaca',
    ];

    test('gives every shipped landmark its own, distinct emoji', () {
      final emoji = shippedIds.map(emojiForLandmarkId).toSet();
      expect(emoji, hasLength(shippedIds.length));
    });

    test('falls back to a plain pin for an id it does not know', () {
      expect(emojiForLandmarkId('some-future-quests-landmark'), '📍');
    });
  });
}
