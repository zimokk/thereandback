import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/core/formatters.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/friendship_repository.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';
import 'package:thereandback/design/colors.dart';
import 'package:thereandback/design/components/distance_text.dart';
import 'package:thereandback/features/achievements/data/achievement_catalog.dart';
import 'package:thereandback/features/achievements/presentation/achievement_titles.dart';
import 'package:thereandback/features/friends/domain/friend_profile.dart';
import 'package:thereandback/features/friends/domain/friend_progress.dart';
import 'package:thereandback/features/friends/domain/friendship.dart';
import 'package:thereandback/features/friends/presentation/friend_pin_color.dart';
import 'package:thereandback/features/friends/presentation/friends_providers.dart';
import 'package:thereandback/features/journey/domain/route_scale.dart';
import 'package:thereandback/features/journey/presentation/journey_path_view.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// The scene's own rendering, isolated from `JourneyTab`'s catalog/gate
/// switching (`journey_tab_test.dart` covers that) — the wavy-line
/// placeholder, the solid traveler marker anchored to the real progress
/// position, and the rewind ghost that tracks a scrolled-back view (§6.1's
/// "перемотка, не подглядывание вперёд", 2026-08-30, in placeholder form
/// until Phase 5's real Flame scene).
Widget _app(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

final _travelerSolid = find.byKey(const Key('travelerSolid'));
final _travelerGhost = find.byKey(const Key('travelerGhost'));
final _returnToYouButton = find.byKey(const Key('returnToYouButton'));

class _MockFriendshipRepository extends Mock implements FriendshipRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockProgressSyncRepository extends Mock
    implements ProgressSyncRepository {}

/// Wires up one accepted friend ("friend-1", nickname "Circe") at
/// [friendProgressMeters] meters into `friendsViewProvider`'s real
/// dependency chain — same repositories-and-stubs shape
/// `friends_providers_test.dart` already proves works, copied here rather
/// than guessing at a shortcut override for the generated `Future`
/// provider itself.
List<Override> _friendOverrides({
  required _MockFriendshipRepository friendshipRepository,
  required _MockUserProfileRepository userProfileRepository,
  required _MockProgressSyncRepository progressSyncRepository,
  required int friendProgressMeters,
}) {
  final friendship = Friendship(
    pairId: pairIdFor('me', 'friend-1'),
    uids: ['me', 'friend-1']..sort(),
    status: FriendshipStatus.accepted,
    initiatorUid: 'me',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
  when(
    () => friendshipRepository.watchMyFriendships('me'),
  ).thenAnswer((_) => Stream.value([friendship]));
  when(() => userProfileRepository.watchProfile('me')).thenAnswer(
    (_) => Stream.value(
      const FriendProfile(uid: 'me', nickname: 'Odysseus', avatarPresetIndex: 0),
    ),
  );
  when(() => userProfileRepository.watchProfile('friend-1')).thenAnswer(
    (_) => Stream.value(
      const FriendProfile(uid: 'friend-1', nickname: 'Circe', avatarPresetIndex: 1),
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
  testWidgets(
    'a fresh quest (no progress yet) renders only the solid traveler, '
    'centred — nothing to rewind to yet, so no ghost',
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

      expect(_travelerSolid, findsOneWidget);
      expect(_travelerGhost, findsNothing);

      final screenWidth = tester.getSize(find.byType(JourneyPathView)).width;
      final iconCenter = tester.getCenter(_travelerSolid);
      expect(iconCenter.dx, moreOrLessEquals(screenWidth / 2, epsilon: 1));
    },
  );

  testWidgets(
    'rewinding the view (dragging right) leaves the solid traveler fixed at '
    'the real progress position and shows a ghost at the rewound position '
    'instead — "на актуальном месте останется сам человек"',
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
      final notifier = container.read(selectedJourneyProvider.notifier);
      notifier.start('odyssey-ithaca', now: DateTime.now());
      // Progress far enough along that a several-hundred-thousand-meter
      // rewind (the drag below) has room to move without hitting 0 m.
      notifier.applySyncedProgress(
        progressMeters: 500000,
        syncedAt: DateTime.now(),
      );
      await tester.pump();

      // At rest, freshly synced: the view is still following `You`
      // (follow-at-You, §6.1) — one figure, centred.
      expect(_travelerSolid, findsOneWidget);
      expect(_travelerGhost, findsNothing);
      final screenWidth = tester.getSize(find.byType(JourneyPathView)).width;
      final atYouCenter = tester.getCenter(_travelerSolid).dx;
      expect(atYouCenter, moreOrLessEquals(screenWidth / 2, epsilon: 1));

      // Dragging right (positive dx) rewinds — reveals earlier route
      // positions, per _onHorizontalDragUpdate's own convention.
      await tester.drag(
        find.byKey(const Key('journeyPathScene')),
        const Offset(200, 0),
      );
      await tester.pump();

      // The ghost is now the one centred — it stands for "what's currently
      // being looked at".
      expect(_travelerGhost, findsOneWidget);
      expect(
        tester.getCenter(_travelerGhost).dx,
        moreOrLessEquals(screenWidth / 2, epsilon: 1),
      );
      // The solid traveler hasn't moved off centre because it swayed —
      // it's genuinely still anchored to the real progress position, which
      // is no longer what's centred, so it has visibly shifted away.
      expect(
        tester.getCenter(_travelerSolid).dx,
        isNot(moreOrLessEquals(screenWidth / 2, epsilon: 1)),
      );
    },
  );

  testWidgets(
    'rewinding cannot go past the current progress — forward is capped at '
    'You, not at the route\'s full length (revises the earlier "peek '
    'ahead" allowance, §6.1/§14 2026-08-30)',
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
      final notifier = container.read(selectedJourneyProvider.notifier);
      notifier.start('odyssey-ithaca', now: DateTime.now());
      notifier.applySyncedProgress(
        progressMeters: 500000,
        syncedAt: DateTime.now(),
      );
      await tester.pump();

      // Rewind first, then try to drag forward (left) far past You —
      // dragging past totalMeters would have worked under the old "peek
      // ahead" behavior; now it must stop exactly at You.
      await tester.drag(
        find.byKey(const Key('journeyPathScene')),
        const Offset(200, 0),
      );
      await tester.pump();
      expect(_travelerGhost, findsOneWidget);

      await tester.drag(
        find.byKey(const Key('journeyPathScene')),
        const Offset(-1000000, 0),
      );
      await tester.pump();

      // Back at You: solid traveler centred, ghost gone — dragging forward
      // stopped exactly there rather than sailing past into unwalked
      // territory.
      expect(_travelerGhost, findsNothing);
      final screenWidth = tester.getSize(find.byType(JourneyPathView)).width;
      expect(
        tester.getCenter(_travelerSolid).dx,
        moreOrLessEquals(screenWidth / 2, epsilon: 1),
      );
    },
  );

  testWidgets('while the view is at You, new progress carries it forward '
      'automatically — it does not get left behind at a stale position', (
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
    final notifier = container.read(selectedJourneyProvider.notifier);
    notifier.start('odyssey-ithaca', now: DateTime.now());
    await tester.pump();

    // Still at You (0 m == 0 m progress) — new progress lands.
    notifier.applySyncedProgress(
      progressMeters: 5000,
      syncedAt: DateTime.now(),
    );
    await tester.pump();

    // No ghost appeared — the view rode along with the new progress
    // rather than being left behind at the old (now stale) position.
    expect(_travelerGhost, findsNothing);
    final screenWidth = tester.getSize(find.byType(JourneyPathView)).width;
    expect(
      tester.getCenter(_travelerSolid).dx,
      moreOrLessEquals(screenWidth / 2, epsilon: 1),
    );
  });

  testWidgets(
    'a deliberately rewound view is never yanked forward by new progress — '
    'only the user returns it to You',
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
      final notifier = container.read(selectedJourneyProvider.notifier);
      notifier.start('odyssey-ithaca', now: DateTime.now());
      notifier.applySyncedProgress(
        progressMeters: 500000,
        syncedAt: DateTime.now(),
      );
      await tester.pump();

      await tester.drag(
        find.byKey(const Key('journeyPathScene')),
        const Offset(200, 0),
      );
      await tester.pump();
      expect(_travelerGhost, findsOneWidget);
      final screenWidth = tester.getSize(find.byType(JourneyPathView)).width;
      final ghostXBefore = tester.getCenter(_travelerGhost).dx;

      // More progress lands while the view is still deliberately rewound.
      notifier.applySyncedProgress(
        progressMeters: 600000,
        syncedAt: DateTime.now(),
      );
      await tester.pump();

      // The ghost stayed put — the rewound view was not pulled forward.
      expect(_travelerGhost, findsOneWidget);
      expect(
        tester.getCenter(_travelerGhost).dx,
        moreOrLessEquals(ghostXBefore, epsilon: 0.5),
      );
      expect(
        tester.getCenter(_travelerGhost).dx,
        moreOrLessEquals(screenWidth / 2, epsilon: 1),
      );
    },
  );

  group('return-to-You button', () {
    testWidgets('hidden at You, appears once rewound', (tester) async {
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
      final notifier = container.read(selectedJourneyProvider.notifier);
      notifier.start('odyssey-ithaca', now: DateTime.now());
      notifier.applySyncedProgress(
        progressMeters: 500000,
        syncedAt: DateTime.now(),
      );
      await tester.pump();

      expect(_returnToYouButton, findsNothing);

      await tester.drag(
        find.byKey(const Key('journeyPathScene')),
        const Offset(200, 0),
      );
      await tester.pump();

      expect(_returnToYouButton, findsOneWidget);
    });

    testWidgets(
      'tapping it animates the view back to You — the ghost disappears '
      'and the solid traveler ends up centred again',
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
        final notifier = container.read(selectedJourneyProvider.notifier);
        notifier.start('odyssey-ithaca', now: DateTime.now());
        notifier.applySyncedProgress(
          progressMeters: 500000,
          syncedAt: DateTime.now(),
        );
        await tester.pump();

        await tester.drag(
          find.byKey(const Key('journeyPathScene')),
          const Offset(200, 0),
        );
        await tester.pump();
        expect(_travelerGhost, findsOneWidget);

        await tester.tap(_returnToYouButton);
        // The jump is animated (§6.1: "не мгновенно"), not instant — pump
        // through it rather than a single frame.
        await tester.pumpAndSettle();

        expect(_travelerGhost, findsNothing);
        expect(_returnToYouButton, findsNothing);
        final screenWidth = tester.getSize(find.byType(JourneyPathView)).width;
        expect(
          tester.getCenter(_travelerSolid).dx,
          moreOrLessEquals(screenWidth / 2, epsilon: 1),
        );
      },
    );

    testWidgets('starting a new drag mid-jump stops the animation instead of '
        'fighting it for control of the pan', (tester) async {
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
      final notifier = container.read(selectedJourneyProvider.notifier);
      notifier.start('odyssey-ithaca', now: DateTime.now());
      notifier.applySyncedProgress(
        progressMeters: 500000,
        syncedAt: DateTime.now(),
      );
      await tester.pump();

      await tester.drag(
        find.byKey(const Key('journeyPathScene')),
        const Offset(200, 0),
      );
      await tester.pump();

      await tester.tap(_returnToYouButton);
      // Only a few frames in — the animation is still mid-flight.
      await tester.pump(const Duration(milliseconds: 200));
      expect(_travelerGhost, findsOneWidget);
      // The ghost's x is always centerX by design (class doc comment — it
      // stands for "whatever's currently centred"); its y tracks _panMeters
      // via _wavyPathY, so that's what moving further actually changes.
      final midJumpY = tester.getCenter(_travelerGhost).dy;

      // A fresh drag interrupts the jump — it should not throw, and the
      // view should end up wherever the drag left it, not snap back to
      // wherever the jump was headed.
      await tester.drag(
        find.byKey(const Key('journeyPathScene')),
        const Offset(50, 0),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_travelerGhost, findsOneWidget);
      expect(
        tester.getCenter(_travelerGhost).dy,
        isNot(moreOrLessEquals(midJumpY, epsilon: 0.5)),
      );
    });
  });

  testWidgets("the line's height at a given route position doesn't change just "
      'because the view has been rewound further — fixed terrain the camera '
      'pans across, not a pattern that warps under the drag', (tester) async {
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
    final notifier = container.read(selectedJourneyProvider.notifier);
    notifier.start('odyssey-ithaca', now: DateTime.now());
    await tester.pump();

    // Measured from the scene's actual layout rather than assumed, so this
    // test doesn't depend on flutter_test's default surface size.
    final sceneWidth = tester
        .getSize(find.byKey(const Key('journeyPathScene')))
        .width;
    final pixelsPerMeter =
        sceneWidth / metersPerScreenWidthFor('odyssey-ithaca');

    // `_waveWavelength` (journey_path_view.dart, private — mirrored here)
    // is 260 "world" pixels at the quest's own pixels-per-meter scale:
    // panning by exactly 260 more world-pixels' worth of route meters
    // returns the fixed terrain to the same phase.
    const wavelengthWorldPixels = 260.0;
    const panMeters1 = 100000.0;
    final panMeters2 = panMeters1 + wavelengthWorldPixels / pixelsPerMeter;

    // Progress needs to reach at least panMeters2 for both rewind targets
    // below to be reachable at all under the new forward clamp.
    notifier.applySyncedProgress(
      progressMeters: panMeters2.ceil() + 1000,
      syncedAt: DateTime.now(),
    );
    await tester.pump();

    // Rewinds the same scene (dragging right decreases _panMeters, see
    // _onHorizontalDragUpdate) first to panMeters1, then further to
    // panMeters2 — the ghost tracks the rewound position, so its height is
    // what's compared here.
    await tester.drag(
      find.byKey(const Key('journeyPathScene')),
      Offset((panMeters2.ceil() + 1000 - panMeters1) * pixelsPerMeter, 0),
    );
    await tester.pump();
    final y1 = tester.getCenter(_travelerGhost).dy;

    await tester.drag(
      find.byKey(const Key('journeyPathScene')),
      Offset((panMeters1 - panMeters2) * pixelsPerMeter, 0),
    );
    await tester.pump();
    final y2 = tester.getCenter(_travelerGhost).dy;

    expect(y2, moreOrLessEquals(y1, epsilon: 0.5));
  });

  group('achievement markers (§6.1 — start/end line, markers ahead)', () {
    testWidgets('markers sit in one flat row pinned to the top of the scene, '
        'regardless of how far along the route they are', (tester) async {
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

      // 'first-steps' (1000 m) and 'journeys-end' (2 850 000 m — the
      // quest's full length) sit at very different points along the
      // route, so if their marker's top ever depended on the wavy
      // placeholder line's height at that x, these two would differ.
      final firstStepsTop = tester
          .getTopLeft(find.byKey(const Key('achievementMarker-first-steps')))
          .dy;
      final journeysEndTop = tester
          .getTopLeft(find.byKey(const Key('achievementMarker-journeys-end')))
          .dy;

      expect(journeysEndTop, moreOrLessEquals(firstStepsTop, epsilon: 0.5));
    });

    testWidgets(
      'a marker ahead of progress renders muted, then gold once progress '
      'reaches its threshold — previewing without unlocking',
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
        final notifier = container.read(selectedJourneyProvider.notifier);
        notifier.start('odyssey-ithaca', now: DateTime.now());
        await tester.pump();

        final markerFinder = find.byKey(
          const Key('achievementMarker-first-steps'),
        );
        Icon iconOf(Finder finder) => tester.widget<Icon>(
          find.descendant(of: finder, matching: find.byType(Icon)),
        );

        final beforeIcon = iconOf(markerFinder);
        expect(beforeIcon.icon, Icons.emoji_events_outlined);
        expect(beforeIcon.color, AppColors.textSecondary);

        notifier.applySyncedProgress(
          progressMeters: 1000,
          syncedAt: DateTime.now(),
        );
        await tester.pump();

        final afterIcon = iconOf(markerFinder);
        expect(afterIcon.icon, Icons.emoji_events);
        expect(afterIcon.color, AppColors.gold);
      },
    );

    testWidgets(
      'rewinding is clamped at point A — dragging further right past the '
      'start does nothing more once already there',
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

        final beforeY = tester.getCenter(_travelerSolid).dy;

        // Already sitting at point A (fresh quest, no progress, no pan
        // yet) — dragging further right tries to go *before* the start,
        // which the clamp in _onHorizontalDragUpdate refuses.
        await tester.drag(
          find.byKey(const Key('journeyPathScene')),
          const Offset(100000, 0),
        );
        await tester.pump();

        final afterY = tester.getCenter(_travelerSolid).dy;
        expect(afterY, moreOrLessEquals(beforeY, epsilon: 0.5));
        expect(_travelerGhost, findsNothing);
      },
    );

    testWidgets(
      'rewinding forward is clamped at the current progress, not at point '
      'B — dragging left twice, far past both, lands in the same place '
      'both times',
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
        final notifier = container.read(selectedJourneyProvider.notifier);
        notifier.start('odyssey-ithaca', now: DateTime.now());
        // Progress is a small fraction of odyssey-ithaca's ~2 850 000 m
        // length — under the old "peek ahead to point B" behavior a
        // million-pixel drag would have landed well past this, at the
        // route's own end; now it must stop exactly at progress.
        notifier.applySyncedProgress(
          progressMeters: 5000,
          syncedAt: DateTime.now(),
        );
        // Rewind first so there is somewhere for "drag left" to return
        // from — otherwise the view is already at You and this would
        // trivially never move.
        await tester.pump();
        await tester.drag(
          find.byKey(const Key('journeyPathScene')),
          const Offset(200, 0),
        );
        await tester.pump();
        expect(_travelerGhost, findsOneWidget);

        await tester.drag(
          find.byKey(const Key('journeyPathScene')),
          const Offset(-1000000, 0),
        );
        await tester.pump();
        expect(_travelerGhost, findsNothing);
        final afterFirstDrag = tester.getCenter(_travelerSolid).dy;

        await tester.drag(
          find.byKey(const Key('journeyPathScene')),
          const Offset(-1000000, 0),
        );
        await tester.pump();
        final afterSecondDrag = tester.getCenter(_travelerSolid).dy;

        expect(afterSecondDrag, moreOrLessEquals(afterFirstDrag, epsilon: 0.5));
      },
    );

    testWidgets(
      'a marker shows nothing until tapped, then opens a sheet with its '
      'name and status',
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

        final l10n = AppLocalizations.of(
          tester.element(find.byType(JourneyPathView)),
        )!;
        final def = achievementCatalog.firstWhere(
          (candidate) => candidate.id == 'first-steps',
        );
        final expectedTitle = achievementTitle(l10n, def);
        final expectedStatus = l10n.achievementRemainingLabel(
          localizedDistanceInline(l10n, formatDistance(def.thresholdMeters)),
        );

        // The name/status are nowhere on screen before the tap — a marker
        // is icon-only until interacted with.
        expect(find.text(expectedTitle), findsNothing);

        await tester.tap(
          find.byKey(const Key('achievementMarker-first-steps')),
        );
        await tester.pumpAndSettle();

        expect(find.text(expectedTitle), findsOneWidget);
        expect(find.text(expectedStatus), findsOneWidget);
      },
    );

    testWidgets(
      'a faint dotted guide line runs from each visible marker down to the '
      'wavy path — quest-map parity (§6.2), not just a floating icon',
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

        // The wavy path itself is drawn with `canvas.drawPath` (a single
        // continuous stroke); a marker's own guide is the only thing this
        // painter ever draws with `canvas.drawLine` — so any line() call at
        // all is evidence a guide was painted, without needing to pin down
        // every dash segment's exact endpoints.
        expect(find.byKey(const Key('journeyPathScene')), paints..line());
      },
    );
  });

  group('friend markers (§6.5, user request)', () {
    late _MockFriendshipRepository friendshipRepository;
    late _MockUserProfileRepository userProfileRepository;
    late _MockProgressSyncRepository progressSyncRepository;

    setUp(() {
      friendshipRepository = _MockFriendshipRepository();
      userProfileRepository = _MockUserProfileRepository();
      progressSyncRepository = _MockProgressSyncRepository();
    });

    testWidgets(
      'off by default — an accepted friend does not render even though '
      'friendsView has data, until the Настройки toggle is on',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
              ..._friendOverrides(
                friendshipRepository: friendshipRepository,
                userProfileRepository: userProfileRepository,
                progressSyncRepository: progressSyncRepository,
                friendProgressMeters: 300000,
              ),
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
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('friendMarker-friend-1')), findsNothing);
        expect(find.text('Circe'), findsNothing);
      },
    );

    testWidgets(
      'turning the toggle on renders the friend as a figure with their '
      'nickname above it, in their stable pin color',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
              ..._friendOverrides(
                friendshipRepository: friendshipRepository,
                userProfileRepository: userProfileRepository,
                progressSyncRepository: progressSyncRepository,
                friendProgressMeters: 300000,
              ),
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
        container.read(showFriendsOnMapProvider.notifier).setEnabled(true);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('friendMarker-friend-1')), findsOneWidget);
        expect(find.byKey(const Key('friendLabel-friend-1')), findsOneWidget);
        expect(find.text('Circe'), findsOneWidget);

        final icon = tester.widget<Icon>(
          find.descendant(
            of: find.byKey(const Key('friendMarker-friend-1')),
            matching: find.byType(Icon),
          ),
        );
        const friendRow = FriendProgressRow(
          uid: 'friend-1',
          nickname: 'Circe',
          progressMeters: 300000,
          isSelf: false,
        );
        expect(icon.color, friendMarkerColor(friendRow));
        // Distinct from the traveler's own gold — this task's requirement
        // ("человечками другого цвета").
        expect(icon.color, isNot(AppColors.gold));
      },
    );

    testWidgets(
      "the friend's own progress places them on the wavy path independently "
      "of the caller's `_panMeters` — a rewind moves where they land on "
      'screen, never their real position (same rule the solid traveler '
      'follows)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
              ..._friendOverrides(
                friendshipRepository: friendshipRepository,
                userProfileRepository: userProfileRepository,
                progressSyncRepository: progressSyncRepository,
                friendProgressMeters: 500000,
              ),
            ],
            child: _app(const JourneyPathView()),
          ),
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(JourneyPathView)),
        );
        final notifier = container.read(selectedJourneyProvider.notifier);
        notifier.start('odyssey-ithaca', now: DateTime.now());
        // Same progress as the friend — if both marker types read the same
        // route position math, the two land at the same screen x.
        notifier.applySyncedProgress(
          progressMeters: 500000,
          syncedAt: DateTime.now(),
        );
        container.read(showFriendsOnMapProvider.notifier).setEnabled(true);
        await tester.pumpAndSettle();

        final friendX = tester
            .getCenter(find.byKey(const Key('friendMarker-friend-1')))
            .dx;
        final travelerX = tester.getCenter(_travelerSolid).dx;
        expect(friendX, moreOrLessEquals(travelerX, epsilon: 1));
      },
    );
  });
}
