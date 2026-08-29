import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, SystemChannels;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/firebase/google_sign_in_service.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/friendship_repository.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';
import 'package:thereandback/features/friends/domain/friend_profile.dart';
import 'package:thereandback/features/friends/domain/friendship.dart';
import 'package:thereandback/features/friends/presentation/challengers_tab.dart';
import 'package:thereandback/features/journey/domain/quest_selection.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/l10n/app_localizations.dart';

class _MockFriendshipRepository extends Mock implements FriendshipRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockProgressSyncRepository extends Mock
    implements ProgressSyncRepository {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

class _FixedSelectedJourney extends SelectedJourney {
  _FixedSelectedJourney(this._state);
  final SelectedQuest? _state;
  @override
  SelectedQuest? build() => _state;
}

class _FixedAuthController extends AuthController {
  _FixedAuthController(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

Friendship _friendship({
  required String a,
  required String b,
  required FriendshipStatus status,
  required String initiatorUid,
}) {
  return Friendship(
    pairId: pairIdFor(a, b),
    uids: [a, b]..sort(),
    status: status,
    initiatorUid: initiatorUid,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

Widget _wrap({
  required _MockFriendshipRepository friendshipRepository,
  required _MockUserProfileRepository userProfileRepository,
  required _MockProgressSyncRepository progressSyncRepository,
  required _MockGoogleAuthService googleAuthService,
  AuthState authState = const AuthState(uid: 'me', isAnonymous: false),
}) {
  return ProviderScope(
    overrides: [
      currentUidProvider.overrideWithValue(authState.uid),
      authControllerProvider.overrideWith(
        () => _FixedAuthController(authState),
      ),
      googleAuthServiceProvider.overrideWithValue(googleAuthService),
      friendshipRepositoryProvider.overrideWithValue(friendshipRepository),
      userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
      progressSyncRepositoryProvider.overrideWithValue(progressSyncRepository),
      selectedJourneyProvider.overrideWith(
        () => _FixedSelectedJourney(
          SelectedQuest(
            journeyId: 'odyssey-ithaca',
            startedAt: DateTime.utc(2026, 1, 1),
            lastSyncedAt: DateTime.utc(2026, 1, 1),
            progressMeters: 5000,
          ),
        ),
      ),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const ChallengersTab(),
    ),
  );
}

void main() {
  late _MockFriendshipRepository friendshipRepository;
  late _MockUserProfileRepository userProfileRepository;
  late _MockProgressSyncRepository progressSyncRepository;
  late _MockGoogleAuthService googleAuthService;

  setUp(() {
    friendshipRepository = _MockFriendshipRepository();
    userProfileRepository = _MockUserProfileRepository();
    progressSyncRepository = _MockProgressSyncRepository();
    googleAuthService = _MockGoogleAuthService();

    when(
      () => userProfileRepository.createInitialProfileIfAbsent(
        any(),
        nickname: any(named: 'nickname'),
        avatarPresetIndex: any(named: 'avatarPresetIndex'),
      ),
    ).thenAnswer((_) async {});
    when(() => userProfileRepository.watchProfile('me')).thenAnswer(
      (_) => Stream.value(
        const FriendProfile(uid: 'me', nickname: 'Me', avatarPresetIndex: 0),
      ),
    );

    // Clipboard.setData has no plugin interface this app can inject a fake
    // behind (unlike GoogleAuthService/StepCountingService above) — it's a
    // raw Flutter SDK static call, so it's faked the standard Flutter way:
    // a mock handler on the platform channel. Without this, the real
    // channel has no engine on the other end and the awaited call never
    // completes, hanging the copy-nickname test rather than failing it.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          return null;
        });
  });

  testWidgets('empty state renders when there are no friends or requests', (
    tester,
  ) async {
    when(() => friendshipRepository.watchMyFriendships('me'))
        .thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(
      _wrap(
        friendshipRepository: friendshipRepository,
        userProfileRepository: userProfileRepository,
        progressSyncRepository: progressSyncRepository,
        googleAuthService: googleAuthService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No friends yet'), findsOneWidget);
  });

  testWidgets('a populated table shows the own row and an accepted friend', (
    tester,
  ) async {
    when(() => friendshipRepository.watchMyFriendships('me')).thenAnswer(
      (_) => Stream.value([
        _friendship(
          a: 'me',
          b: 'bob',
          status: FriendshipStatus.accepted,
          initiatorUid: 'me',
        ),
      ]),
    );
    when(() => userProfileRepository.watchProfile('bob')).thenAnswer(
      (_) => Stream.value(
        const FriendProfile(uid: 'bob', nickname: 'Bob', avatarPresetIndex: 1),
      ),
    );
    when(
      () => progressSyncRepository.watchFriendProgress('bob', 'odyssey-ithaca'),
    ).thenAnswer((_) => Stream.value(9000));

    await tester.pumpWidget(
      _wrap(
        friendshipRepository: friendshipRepository,
        userProfileRepository: userProfileRepository,
        progressSyncRepository: progressSyncRepository,
        googleAuthService: googleAuthService,
      ),
    );
    await tester.pumpAndSettle();

    // 'Me' now appears twice: once in the pinned "Your nickname" card
    // (§6.4 — findable so a friend can be given the nickname to add), once
    // in the own row further down ("Me (You)"). Same reason 'You' matches
    // twice — "Me (You)" and the card's own label "Your nickname" both
    // contain the substring.
    expect(find.textContaining('Me'), findsNWidgets(2));
    expect(find.text('Your nickname'), findsOneWidget);
    expect(find.textContaining('You'), findsNWidgets(2));
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('No friends yet'), findsNothing);
  });

  testWidgets('an incoming request shows accept/decline, and accept calls the '
      'repository', (tester) async {
    when(() => friendshipRepository.watchMyFriendships('me')).thenAnswer(
      (_) => Stream.value([
        _friendship(
          a: 'me',
          b: 'bob',
          status: FriendshipStatus.pending,
          initiatorUid: 'bob',
        ),
      ]),
    );
    when(() => userProfileRepository.watchProfile('bob')).thenAnswer(
      (_) => Stream.value(
        const FriendProfile(uid: 'bob', nickname: 'Bob', avatarPresetIndex: 1),
      ),
    );
    when(() => friendshipRepository.acceptRequest(pairIdFor('me', 'bob')))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrap(
        friendshipRepository: friendshipRepository,
        userProfileRepository: userProfileRepository,
        progressSyncRepository: progressSyncRepository,
        googleAuthService: googleAuthService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bob wants to be your friend'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    verify(() => friendshipRepository.acceptRequest(pairIdFor('me', 'bob')))
        .called(1);
  });

  testWidgets(
    'tapping the copy icon on the own-nickname card copies it and shows a '
    'confirmation',
    (tester) async {
      when(() => friendshipRepository.watchMyFriendships('me'))
          .thenAnswer((_) => Stream.value(const []));

      await tester.pumpWidget(
        _wrap(
          friendshipRepository: friendshipRepository,
          userProfileRepository: userProfileRepository,
          progressSyncRepository: progressSyncRepository,
          googleAuthService: googleAuthService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy));
      // A single pump, not pumpAndSettle: the SnackBar's own auto-dismiss
      // timer means settling would pump straight through its whole visible
      // duration and find it already gone by the time this returns.
      await tester.pump();

      expect(
        find.text('Nickname copied — share it with a friend.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'adding a friend while anonymous triggers the Google upgrade prompt, '
    'and a cancelled picker shows the cancelled message without resolving '
    'any nickname',
    (tester) async {
      when(() => friendshipRepository.watchMyFriendships('me'))
          .thenAnswer((_) => Stream.value(const []));
      when(() => googleAuthService.signIn()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        _wrap(
          friendshipRepository: friendshipRepository,
          userProfileRepository: userProfileRepository,
          progressSyncRepository: progressSyncRepository,
          googleAuthService: googleAuthService,
          authState: const AuthState(uid: 'me', isAnonymous: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add_alt_1));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      verify(() => googleAuthService.signIn()).called(1);
      verifyNever(() => userProfileRepository.resolveUidForNickname(any()));
      expect(
        find.text(
          'Adding friends needs a Google account — sign-in was cancelled.',
        ),
        findsOneWidget,
      );
    },
  );
}
