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

void main() {
  testWidgets('draws the route overlay over the quest map', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        const QuestMapView(progressMeters: 0),
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
        const QuestMapView(progressMeters: 425000),
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
        const QuestMapView(progressMeters: 2850000),
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

  testWidgets('still draws the route when the illustration is not bundled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const QuestMapView(progressMeters: 100000),
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
      _wrap(const QuestMapView(progressMeters: 0), bundle: _FakeBundle({})),
    );
    await _startQuest(tester);

    expect(find.byKey(const Key('questMapRouteOverlay')), findsNothing);
    expect(find.text("This quest's map couldn't be loaded."), findsOneWidget);
  });

  testWidgets('renders nothing before a quest is selected', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const QuestMapView(progressMeters: 0),
        bundle: _FakeBundle({
          'assets/journeys/odyssey-ithaca/map.json': _mapJson,
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('questMapRouteOverlay')), findsNothing);
  });
}
