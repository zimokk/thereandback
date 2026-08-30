import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/data/firebase/google_sign_in_service.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/friendship_repository.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';
import 'package:thereandback/features/friends/domain/friend_profile.dart';
import 'package:thereandback/features/friends/domain/friendship.dart';
import 'package:thereandback/features/friends/presentation/friends_providers.dart';
import 'package:thereandback/features/journey/domain/quest_selection.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';

class _MockFriendshipRepository extends Mock implements FriendshipRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockProgressSyncRepository extends Mock
    implements ProgressSyncRepository {}

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
  Map<String, bool> hiddenBy = const {},
}) {
  return Friendship(
    pairId: pairIdFor(a, b),
    uids: [a, b]..sort(),
    status: status,
    initiatorUid: initiatorUid,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    hiddenBy: hiddenBy,
  );
}

void main() {
  late _MockFriendshipRepository friendshipRepository;
  late _MockUserProfileRepository userProfileRepository;
  late _MockProgressSyncRepository progressSyncRepository;

  setUp(() {
    friendshipRepository = _MockFriendshipRepository();
    userProfileRepository = _MockUserProfileRepository();
    progressSyncRepository = _MockProgressSyncRepository();
  });

  ProviderContainer buildContainer({
    SelectedQuest? quest,
    AuthState authState = const AuthState(uid: 'me', isAnonymous: false),
  }) {
    final container = ProviderContainer(
      overrides: [
        currentUidProvider.overrideWithValue(authState.uid),
        authControllerProvider.overrideWith(
          () => _FixedAuthController(authState),
        ),
        friendshipRepositoryProvider.overrideWithValue(friendshipRepository),
        userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
        progressSyncRepositoryProvider.overrideWithValue(
          progressSyncRepository,
        ),
        selectedJourneyProvider.overrideWith(
          () => _FixedSelectedJourney(quest),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Keep the underlying stream providers alive for the container's whole
    // lifetime — without a persistent listener, Riverpod's autoDispose can
    // tear one down while `.future` is still awaiting its first event
    // (`Stream.value(...)` is single-subscription, not broadcast), racing
    // the very read below and throwing "disposed during loading state".
    container.listen(friendshipsProvider, (_, _) {});
    container.listen(myProfileProvider, (_, _) {});
    return container;
  }

  group('friendsView', () {
    test('own row + accepted friends, sorted, own row first', () async {
      when(() => friendshipRepository.watchMyFriendships('me')).thenAnswer(
        (_) => Stream.value([
          _friendship(
            a: 'me',
            b: 'bob',
            status: FriendshipStatus.accepted,
            initiatorUid: 'me',
          ),
          _friendship(
            a: 'me',
            b: 'carol',
            status: FriendshipStatus.accepted,
            initiatorUid: 'carol',
          ),
        ]),
      );
      when(() => userProfileRepository.watchProfile('me')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(uid: 'me', nickname: 'Me', avatarPresetIndex: 0),
        ),
      );
      when(() => userProfileRepository.watchProfile('bob')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'bob',
            nickname: 'Bob',
            avatarPresetIndex: 1,
          ),
        ),
      );
      when(() => userProfileRepository.watchProfile('carol')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'carol',
            nickname: 'Carol',
            avatarPresetIndex: 2,
          ),
        ),
      );
      when(
        () =>
            progressSyncRepository.watchFriendProgress('bob', 'odyssey-ithaca'),
      ).thenAnswer((_) => Stream.value(9000));
      when(
        () => progressSyncRepository.watchFriendProgress(
          'carol',
          'odyssey-ithaca',
        ),
      ).thenAnswer((_) => Stream.value(1000));

      final container = buildContainer(
        quest: SelectedQuest(
          journeyId: 'odyssey-ithaca',
          startedAt: DateTime.utc(2026, 1, 1),
          lastSyncedAt: DateTime.utc(2026, 1, 1),
          progressMeters: 5000,
        ),
      );

      // Let the underlying live streams settle before reading the composed
      // future, so `friendsView`'s build sees the real data, not the
      // loading-state default it started from.
      await container.read(friendshipsProvider.future);
      await container.read(myProfileProvider.future);

      final view = await container.read(friendsViewProvider.future);

      expect(view.rows.map((r) => r.uid), ['me', 'bob', 'carol']);
      expect(view.rows.first.progressMeters, 5000);
      expect(view.incoming, isEmpty);
      expect(view.outgoing, isEmpty);
    });

    test(
      'a friend who hid their progress from me is excluded from rows',
      () async {
        when(() => friendshipRepository.watchMyFriendships('me')).thenAnswer(
          (_) => Stream.value([
            _friendship(
              a: 'me',
              b: 'bob',
              status: FriendshipStatus.accepted,
              initiatorUid: 'me',
              hiddenBy: const {'bob': true},
            ),
          ]),
        );
        when(() => userProfileRepository.watchProfile('me')).thenAnswer(
          (_) => Stream.value(
            const FriendProfile(
              uid: 'me',
              nickname: 'Me',
              avatarPresetIndex: 0,
            ),
          ),
        );

        final container = buildContainer(quest: null);
        await container.read(friendshipsProvider.future);
        await container.read(myProfileProvider.future);

        final view = await container.read(friendsViewProvider.future);

        expect(view.rows.map((r) => r.uid), ['me']);
        verifyNever(() => userProfileRepository.watchProfile('bob'));
      },
    );

    test('pending requests are split into incoming and outgoing', () async {
      when(() => friendshipRepository.watchMyFriendships('me')).thenAnswer(
        (_) => Stream.value([
          _friendship(
            a: 'me',
            b: 'bob',
            status: FriendshipStatus.pending,
            initiatorUid: 'bob',
          ),
          _friendship(
            a: 'me',
            b: 'carol',
            status: FriendshipStatus.pending,
            initiatorUid: 'me',
          ),
        ]),
      );
      when(() => userProfileRepository.watchProfile('me')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(uid: 'me', nickname: 'Me', avatarPresetIndex: 0),
        ),
      );
      when(() => userProfileRepository.watchProfile('bob')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'bob',
            nickname: 'Bob',
            avatarPresetIndex: 1,
          ),
        ),
      );
      when(() => userProfileRepository.watchProfile('carol')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'carol',
            nickname: 'Carol',
            avatarPresetIndex: 2,
          ),
        ),
      );

      final container = buildContainer(quest: null);
      await container.read(friendshipsProvider.future);
      await container.read(myProfileProvider.future);

      final view = await container.read(friendsViewProvider.future);

      expect(view.rows.map((r) => r.uid), ['me']); // no accepted friends yet
      expect(view.incoming.single.otherNickname, 'Bob');
      expect(view.outgoing.single.otherNickname, 'Carol');
    });
  });

  group('FriendsController.addFriendByNickname', () {
    test('a signed-in, non-anonymous user sends a request', () async {
      when(() => userProfileRepository.resolveUidForNickname('bob'))
          .thenAnswer((_) async => 'bob-uid');
      when(() => friendshipRepository.watchMyFriendships('me'))
          .thenAnswer((_) => Stream.value(const []));
      when(
        () => friendshipRepository.sendRequest(fromUid: 'me', toUid: 'bob-uid'),
      ).thenAnswer((_) async {});

      final container = buildContainer(quest: null);
      await container.read(friendshipsProvider.future);

      final outcome = await container
          .read(friendsControllerProvider.notifier)
          .addFriendByNickname('bob');

      expect(outcome, AddFriendOutcome.sent);
      verify(
        () => friendshipRepository.sendRequest(fromUid: 'me', toUid: 'bob-uid'),
      ).called(1);
    });

    test('an unknown nickname returns nicknameNotFound', () async {
      when(() => userProfileRepository.resolveUidForNickname('nobody'))
          .thenAnswer((_) async => null);
      when(() => friendshipRepository.watchMyFriendships('me'))
          .thenAnswer((_) => Stream.value(const []));

      final container = buildContainer(quest: null);
      await container.read(friendshipsProvider.future);

      final outcome = await container
          .read(friendsControllerProvider.notifier)
          .addFriendByNickname('nobody');

      expect(outcome, AddFriendOutcome.nicknameNotFound);
    });

    test('resolving your own nickname returns cannotAddSelf', () async {
      when(() => userProfileRepository.resolveUidForNickname('me-nick'))
          .thenAnswer((_) async => 'me');
      when(() => friendshipRepository.watchMyFriendships('me'))
          .thenAnswer((_) => Stream.value(const []));

      final container = buildContainer(quest: null);
      await container.read(friendshipsProvider.future);

      final outcome = await container
          .read(friendsControllerProvider.notifier)
          .addFriendByNickname('me-nick');

      expect(outcome, AddFriendOutcome.cannotAddSelf);
    });

    test('an existing friendship (any status) returns alreadyExists', () async {
      when(() => userProfileRepository.resolveUidForNickname('bob'))
          .thenAnswer((_) async => 'bob-uid');
      when(() => friendshipRepository.watchMyFriendships('me')).thenAnswer(
        (_) => Stream.value([
          _friendship(
            a: 'me',
            b: 'bob-uid',
            status: FriendshipStatus.pending,
            initiatorUid: 'me',
          ),
        ]),
      );

      final container = buildContainer(quest: null);
      await container.read(friendshipsProvider.future);

      final outcome = await container
          .read(friendsControllerProvider.notifier)
          .addFriendByNickname('bob');

      expect(outcome, AddFriendOutcome.alreadyExists);
      verifyNever(
        () => friendshipRepository.sendRequest(
          fromUid: any(named: 'fromUid'),
          toUid: any(named: 'toUid'),
        ),
      );
    });

    test('an anonymous session triggers the Google upgrade first — a '
        'cancelled upgrade never reaches nickname resolution', () async {
      when(() => friendshipRepository.watchMyFriendships('me'))
          .thenAnswer((_) => Stream.value(const []));

      // The real AuthController.upgradeWithGoogle() would run here, but
      // GoogleAuthService isn't overridden by buildContainer — its real
      // signIn() prompts a native UI and would hang in a test. Overriding
      // googleAuthService to return null (a "cancelled" picker) keeps
      // this deterministic.
      final upgradeCancelling = ProviderContainer(
        overrides: [
          currentUidProvider.overrideWithValue('me'),
          authControllerProvider.overrideWith(
            () => _FixedAuthController(
              const AuthState(uid: 'me', isAnonymous: true),
            ),
          ),
          googleAuthServiceProvider.overrideWithValue(_CancellingGoogleAuth()),
          friendshipRepositoryProvider.overrideWithValue(friendshipRepository),
          userProfileRepositoryProvider.overrideWithValue(
            userProfileRepository,
          ),
          progressSyncRepositoryProvider.overrideWithValue(
            progressSyncRepository,
          ),
          selectedJourneyProvider.overrideWith(
            () => _FixedSelectedJourney(null),
          ),
        ],
      );
      addTearDown(upgradeCancelling.dispose);
      upgradeCancelling.listen(friendshipsProvider, (_, _) {});
      await upgradeCancelling.read(friendshipsProvider.future);

      final outcome = await upgradeCancelling
          .read(friendsControllerProvider.notifier)
          .addFriendByNickname('bob');

      expect(outcome, AddFriendOutcome.googleUpgradeCancelled);
      verifyNever(() => userProfileRepository.resolveUidForNickname(any()));
    });
  });

  group('FriendsController.updateNickname', () {
    test('a successful rename returns success', () async {
      when(() => userProfileRepository.updateNickname('me', 'NewNick'))
          .thenAnswer((_) async {});
      when(() => friendshipRepository.watchMyFriendships('me'))
          .thenAnswer((_) => Stream.value(const []));

      final container = buildContainer(quest: null);
      await container.read(friendshipsProvider.future);

      final outcome = await container
          .read(friendsControllerProvider.notifier)
          .updateNickname('NewNick');

      expect(outcome, UpdateNicknameOutcome.success);
      verify(() => userProfileRepository.updateNickname('me', 'NewNick'))
          .called(1);
    });

    test('a nickname already claimed by someone else returns nicknameTaken, '
        'not a thrown exception', () async {
      when(() => userProfileRepository.updateNickname('me', 'Taken'))
          .thenThrow(const NicknameTakenException('Taken'));
      when(() => friendshipRepository.watchMyFriendships('me'))
          .thenAnswer((_) => Stream.value(const []));

      final container = buildContainer(quest: null);
      await container.read(friendshipsProvider.future);

      final outcome = await container
          .read(friendsControllerProvider.notifier)
          .updateNickname('Taken');

      expect(outcome, UpdateNicknameOutcome.nicknameTaken);
    });

    test('no signed-in uid returns notSignedIn without touching the '
        'repository', () async {
      final container = buildContainer(
        quest: null,
        authState: const AuthState(),
      );

      final outcome = await container
          .read(friendsControllerProvider.notifier)
          .updateNickname('Anything');

      expect(outcome, UpdateNicknameOutcome.notSignedIn);
      verifyNever(() => userProfileRepository.updateNickname(any(), any()));
    });
  });

  group('friendsUnlocked (this task\'s requirement — the tab stays inactive '
      'until login + a nickname, §6.4/§6.5/§8)', () {
    test('locked while still anonymous, even with a resolved profile', () {
      when(() => userProfileRepository.watchProfile('me')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'me',
            nickname: 'Traveler-abc123',
            avatarPresetIndex: 0,
          ),
        ),
      );
      final container = buildContainer(
        authState: const AuthState(uid: 'me', isAnonymous: true),
      );

      expect(container.read(friendsUnlockedProvider), isFalse);
    });

    test('locked once logged in but the profile/nickname has not resolved '
        'yet', () {
      when(() => userProfileRepository.watchProfile('me'))
          .thenAnswer((_) => Stream.value(null));
      final container = buildContainer(
        authState: const AuthState(uid: 'me', isAnonymous: false),
      );

      expect(container.read(friendsUnlockedProvider), isFalse);
    });

    test('unlocked once logged in and the profile has a nickname', () async {
      when(() => userProfileRepository.watchProfile('me')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'me',
            nickname: 'pupa',
            avatarPresetIndex: 0,
          ),
        ),
      );
      final container = buildContainer(
        authState: const AuthState(uid: 'me', isAnonymous: false),
      );

      // myProfileProvider is a Stream-backed provider — its first real
      // value needs a beat to arrive, same as every other test in this
      // file that reads through it.
      await container.read(myProfileProvider.future);

      expect(container.read(friendsUnlockedProvider), isTrue);
    });
  });
}

class _CancellingGoogleAuth implements GoogleAuthService {
  @override
  Future<GoogleAuthTokens?> signIn() async => null;
}
