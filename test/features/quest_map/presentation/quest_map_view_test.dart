import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/friendship_repository.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';
import 'package:thereandback/features/friends/domain/friend_profile.dart';
import 'package:thereandback/features/friends/domain/friendship.dart';
import 'package:thereandback/features/friends/presentation/friends_providers.dart';
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

Widget _wrap(
  Widget child, {
  required AssetBundle bundle,
  // No explicit `List<Override>` here — `Override` (riverpod's own type for
  // a `ProviderScope.overrides` entry) isn't actually exported by the
  // package under that name, only used structurally; every override list
  // in this repo is built as an inline list literal for the same reason
  // (see `_friendOverrides` below).
  extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      questMapBundleProvider.overrideWithValue(bundle),
      ...extraOverrides,
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

class _MockFriendshipRepository extends Mock implements FriendshipRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockProgressSyncRepository extends Mock
    implements ProgressSyncRepository {}

/// Wires up one accepted friend ("friend-1", nickname "Circe") into
/// `friendsViewProvider`'s real dependency chain — same shape
/// `journey_path_view_test.dart`'s own `_friendOverrides` helper uses,
/// duplicated here rather than shared since each test file's mocks are
/// already self-contained by this repo's own convention (e.g.
/// `settings_tab_test.dart`/`lock_screen_controller_test.dart` both define
/// their own `_MockChannel`).
///
/// No explicit return type — see `journey_path_view_test.dart`'s own
/// `_friendOverrides` doc comment for why (`Override` isn't a nameable
/// riverpod type).
// ignore: strict_top_level_inference
_friendOverrides({required int friendProgressMeters}) {
  final friendshipRepository = _MockFriendshipRepository();
  final userProfileRepository = _MockUserProfileRepository();
  final progressSyncRepository = _MockProgressSyncRepository();

  final friendship = Friendship(
    pairId: pairIdFor('me', 'friend-1'),
    uids: ['me', 'friend-1']..sort(),
    status: FriendshipStatus.accepted,
    initiatorUid: 'me',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
  when(() => friendshipRepository.watchMyFriendships('me'))
      .thenAnswer((_) => Stream.value([friendship]));
  when(() => userProfileRepository.watchProfile('me')).thenAnswer(
    (_) => Stream.value(
      const FriendProfile(
        uid: 'me',
        nickname: 'Odysseus',
        avatarPresetIndex: 0,
      ),
    ),
  );
  when(() => userProfileRepository.watchProfile('friend-1')).thenAnswer(
    (_) => Stream.value(
      const FriendProfile(
        uid: 'friend-1',
        nickname: 'Circe',
        avatarPresetIndex: 1,
      ),
    ),
  );
  when(
    () => progressSyncRepository.watchFriendProgress(
      'friend-1',
      'odyssey-ithaca',
    ),
  ).thenAnswer((_) => Stream.value(friendProgressMeters));

  return [
    currentUidProvider.overrideWithValue('me'),
    friendshipRepositoryProvider.overrideWithValue(friendshipRepository),
    userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
    progressSyncRepositoryProvider.overrideWithValue(progressSyncRepository),
  ];
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
    // Landmarks are only tappable while the map's legend is on (this task's
    // requirement — hidden, non-interactive icons by default); every test
    // in this group turns it on first, then exercises the tap behavior the
    // same way it always did.
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
      await tester.tap(find.byKey(const Key('questMapLegendToggle')));
      await tester.pump();

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
      await tester.tap(find.byKey(const Key('questMapLegendToggle')));
      await tester.pump();

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
      await tester.tap(find.byKey(const Key('questMapLegendToggle')));
      await tester.pump();

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
      await tester.tap(find.byKey(const Key('questMapLegendToggle')));
      await tester.pump();

      await tester.tapAt(_pointOn(tester, 0.9, 0.4)); // Troy.
      await tester.pump();
      expect(find.text('Behind: Troy — 425 kilometers ago'), findsOneWidget);

      await tester.tapAt(_pointOn(tester, 0.5, 0.6)); // Calypso.
      await tester.pump();
      expect(find.text('Behind: Troy — 425 kilometers ago'), findsNothing);
      expect(find.text('Ahead: Calypso — 1000 kilometers to go'), findsWidgets);
    });
  });

  group('iconForLandmarkId', () {
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

    test('gives every shipped landmark its own, distinct icon', () {
      final icons = shippedIds.map(iconForLandmarkId).toSet();
      expect(icons, hasLength(shippedIds.length));
    });

    test('falls back to a plain pin for an id it does not know', () {
      expect(
        iconForLandmarkId('some-future-quests-landmark'),
        Icons.location_on,
      );
    });
  });

  group('the map legend toggle (§6.5, user request)', () {
    testWidgets(
      'the legend is hidden by default — a tap where a landmark sits opens '
      'nothing',
      (tester) async {
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

        expect(find.byKey(const Key('questMapLegendToggle')), findsOneWidget);

        await tester.tapAt(_pointOn(tester, 0.5, 0.6)); // Calypso.
        await tester.pump();

        expect(find.byKey(const Key('questMapLandmarkTooltip')), findsNothing);
      },
    );

    testWidgets(
      'turning the legend on makes landmarks tappable again — restoring '
      "the behavior this screen always had before this preference existed",
      (tester) async {
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

        await tester.tap(find.byKey(const Key('questMapLegendToggle')));
        await tester.pump();

        await tester.tapAt(_pointOn(tester, 0.5, 0.6)); // Calypso.
        await tester.pump();

        expect(
          find.byKey(const Key('questMapLandmarkTooltip')),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping the toggle a second time hides the legend again — a '
        'landmark tap stops opening a tooltip', (tester) async {
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

      final toggle = find.byKey(const Key('questMapLegendToggle'));
      await tester.tap(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();

      await tester.tapAt(_pointOn(tester, 0.5, 0.6)); // Calypso.
      await tester.pump();

      expect(find.byKey(const Key('questMapLandmarkTooltip')), findsNothing);
    });

    testWidgets(
      "the toggle's own semantics label names the action a tap will take, "
      'swapping between the two states',
      (tester) async {
        _growViewportForTapping(tester);
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

        expect(find.bySemanticsLabel('Show map legend'), findsOneWidget);

        await tester.tap(find.byKey(const Key('questMapLegendToggle')));
        await tester.pump();

        expect(find.bySemanticsLabel('Hide map legend'), findsOneWidget);
        semantics.dispose();
      },
    );
  });

  group('friends on the map (§6.5, user request)', () {
    testWidgets(
      'off by default — the screen still renders normally even with an '
      'accepted friend in friendsView',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            QuestMapView(progressMeters: 0, startedAt: DateTime.now()),
            bundle: _FakeBundle({
              'assets/journeys/odyssey-ithaca/map.json': _mapJson,
            }),
            extraOverrides: _friendOverrides(friendProgressMeters: 300000),
          ),
        );
        await _startQuest(tester);

        expect(find.byKey(const Key('questMapRouteOverlay')), findsOneWidget);
      },
    );

    testWidgets(
      'turning the Настройки toggle on still renders the map with the '
      "friend's data resolved, without throwing",
      (tester) async {
        _growViewportForTapping(tester);
        await tester.pumpWidget(
          _wrap(
            QuestMapView(progressMeters: 0, startedAt: DateTime.now()),
            bundle: _FakeBundle({
              'assets/journeys/odyssey-ithaca/map.json': _mapJson,
            }),
            extraOverrides: _friendOverrides(friendProgressMeters: 300000),
          ),
        );
        await _startQuest(tester);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(QuestMapView)),
        );
        // `friends_providers_test.dart`'s own note, both halves: a
        // persistent listener so autoDispose can't tear either Stream
        // provider down mid-flight, plus awaiting each one's own `.future`
        // so `friendsView`'s synchronous `.value` read (still `null`/
        // loading at first subscription) sees real data by the time
        // `friendsViewProvider` is watched for the first time below (via
        // the toggle), instead of racing it.
        container.listen(friendshipsProvider, (_, _) {});
        container.listen(myProfileProvider, (_, _) {});
        await container.read(friendshipsProvider.future);
        await container.read(myProfileProvider.future);
        container.read(showFriendsOnMapProvider.notifier).setEnabled(true);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('questMapRouteOverlay')), findsOneWidget);
        // The traveler's own tap target still resolves correctly with
        // friends drawn alongside it — a regression here would mean a
        // friend's helmet is stealing the traveler's own hit-test area.
        await tester.tapAt(_pointOn(tester, 0.9, 0.4)); // Troy — 0 m.
        await tester.pump();
        expect(
          find.byKey(const Key('questMapTravelerTooltip')),
          findsOneWidget,
        );
      },
    );
  });
}
