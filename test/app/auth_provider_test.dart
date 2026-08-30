import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/data/firebase/auth_repository.dart';
import 'package:thereandback/data/firebase/google_sign_in_service.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';
import 'package:thereandback/features/friends/domain/friend_profile.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

/// An [AuthController] that starts from a fixed state and skips the real
/// `build()`'s `ensureSignedIn()`/`uidChanges()` bootstrap — same
/// "subclass the notifier to fix its starting state" trick as
/// `steps_providers_test.dart`'s `_GrantedStepsSync`. Used by every group
/// except the one that specifically exercises the real bootstrap.
class _FixedAuthController extends AuthController {
  _FixedAuthController(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

void main() {
  group('upgradeWithGoogle', () {
    late _MockAuthRepository authRepository;
    late _MockGoogleAuthService googleAuthService;
    late ProviderContainer container;

    setUp(() {
      authRepository = _MockAuthRepository();
      googleAuthService = _MockGoogleAuthService();
      // Stubbed by default for every test in this group: upgradeWithGoogle()
      // calls this itself now (guarding the race where build()'s own
      // unawaited _bootstrap() hasn't finished yet), regardless of what it
      // does with the Google picker result.
      when(() => authRepository.ensureSignedIn())
          .thenAnswer((_) async => 'anon-1');
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          googleAuthServiceProvider.overrideWithValue(googleAuthService),
          authControllerProvider.overrideWith(
            () => _FixedAuthController(
              const AuthState(uid: 'anon-1', isAnonymous: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('a cancelled picker returns cancelled without calling the '
        'repository', () async {
      when(() => googleAuthService.signIn()).thenAnswer((_) async => null);

      final outcome = await container
          .read(authControllerProvider.notifier)
          .upgradeWithGoogle();

      expect(outcome, GoogleUpgradeOutcome.cancelled);
      verifyNever(
        () => authRepository.linkWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      );
    });

    test('a successful link returns success and flips isAnonymous', () async {
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
      when(
        () => authRepository.linkWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => null);

      final outcome = await container
          .read(authControllerProvider.notifier)
          .upgradeWithGoogle();

      expect(outcome, GoogleUpgradeOutcome.success);
      expect(container.read(authControllerProvider).isAnonymous, isFalse);
    });

    test('ensures a signed-in session before linking, even though build()\'s '
        'own bootstrap already tried — that unawaited call can still be in '
        'flight (or have silently failed) when this runs', () async {
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
      when(
        () => authRepository.linkWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => null);

      await container.read(authControllerProvider.notifier).upgradeWithGoogle();

      verify(() => authRepository.ensureSignedIn()).called(1);
    });

    test('an already-linked Google identity returns alreadyLinked, not a '
        'thrown exception', () async {
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
      when(
        () => authRepository.linkWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenThrow(const GoogleAccountAlreadyLinkedException());

      final outcome = await container
          .read(authControllerProvider.notifier)
          .upgradeWithGoogle();

      expect(outcome, GoogleUpgradeOutcome.alreadyLinked);
      // A failed upgrade must not silently flip isAnonymous.
      expect(container.read(authControllerProvider).isAnonymous, isTrue);
    });
  });

  group('upgradeWithGoogle — default nickname from the Google email (§14)', () {
    ProviderContainer buildContainer({
      required _MockAuthRepository authRepository,
      required _MockGoogleAuthService googleAuthService,
      required _MockUserProfileRepository userProfileRepository,
      String uid = 'uid-1',
    }) {
      when(
        () => authRepository.ensureSignedIn(),
      ).thenAnswer((_) async => uid);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          googleAuthServiceProvider.overrideWithValue(googleAuthService),
          userProfileRepositoryProvider.overrideWithValue(
            userProfileRepository,
          ),
          authControllerProvider.overrideWith(
            () => _FixedAuthController(
              AuthState(uid: uid, isAnonymous: true),
            ),
          ),
        ],
      );
      return container;
    }

    test(
      'defaults the nickname to the email\'s local part when the profile '
      'still has the generated placeholder',
      () async {
        final authRepository = _MockAuthRepository();
        final googleAuthService = _MockGoogleAuthService();
        final userProfileRepository = _MockUserProfileRepository();
        when(() => googleAuthService.signIn()).thenAnswer(
          (_) async => const GoogleAuthTokens(idToken: 'id-token'),
        );
        when(
          () => authRepository.linkWithGoogleCredential(
            idToken: any(named: 'idToken'),
          ),
        ).thenAnswer((_) async => 'pupa@gmail.com');
        when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
          (_) => Stream.value(
            FriendProfile(
              uid: 'uid-1',
              nickname: defaultStarterNickname('uid-1'),
              avatarPresetIndex: 0,
            ),
          ),
        );
        when(
          () => userProfileRepository.updateNickname('uid-1', 'pupa'),
        ).thenAnswer((_) async {});

        final container = buildContainer(
          authRepository: authRepository,
          googleAuthService: googleAuthService,
          userProfileRepository: userProfileRepository,
        );
        addTearDown(container.dispose);

        final outcome = await container
            .read(authControllerProvider.notifier)
            .upgradeWithGoogle();

        expect(outcome, GoogleUpgradeOutcome.success);
        verify(
          () => userProfileRepository.updateNickname('uid-1', 'pupa'),
        ).called(1);
      },
    );

    test(
      'strips a Gmail "+tag" suffix from the default — it\'s an address '
      'filter, not part of the account',
      () async {
        final authRepository = _MockAuthRepository();
        final googleAuthService = _MockGoogleAuthService();
        final userProfileRepository = _MockUserProfileRepository();
        when(() => googleAuthService.signIn()).thenAnswer(
          (_) async => const GoogleAuthTokens(idToken: 'id-token'),
        );
        when(
          () => authRepository.linkWithGoogleCredential(
            idToken: any(named: 'idToken'),
          ),
        ).thenAnswer((_) async => 'pupa+journey@gmail.com');
        when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
          (_) => Stream.value(
            FriendProfile(
              uid: 'uid-1',
              nickname: defaultStarterNickname('uid-1'),
              avatarPresetIndex: 0,
            ),
          ),
        );
        when(
          () => userProfileRepository.updateNickname('uid-1', 'pupa'),
        ).thenAnswer((_) async {});

        final container = buildContainer(
          authRepository: authRepository,
          googleAuthService: googleAuthService,
          userProfileRepository: userProfileRepository,
        );
        addTearDown(container.dispose);

        await container.read(authControllerProvider.notifier).upgradeWithGoogle();

        verify(
          () => userProfileRepository.updateNickname('uid-1', 'pupa'),
        ).called(1);
      },
    );

    test(
      'never overwrites a nickname the user already customized',
      () async {
        final authRepository = _MockAuthRepository();
        final googleAuthService = _MockGoogleAuthService();
        final userProfileRepository = _MockUserProfileRepository();
        when(() => googleAuthService.signIn()).thenAnswer(
          (_) async => const GoogleAuthTokens(idToken: 'id-token'),
        );
        when(
          () => authRepository.linkWithGoogleCredential(
            idToken: any(named: 'idToken'),
          ),
        ).thenAnswer((_) async => 'pupa@gmail.com');
        when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
          (_) => Stream.value(
            const FriendProfile(
              uid: 'uid-1',
              nickname: 'Odysseus',
              avatarPresetIndex: 0,
            ),
          ),
        );

        final container = buildContainer(
          authRepository: authRepository,
          googleAuthService: googleAuthService,
          userProfileRepository: userProfileRepository,
        );
        addTearDown(container.dispose);

        final outcome = await container
            .read(authControllerProvider.notifier)
            .upgradeWithGoogle();

        expect(outcome, GoogleUpgradeOutcome.success);
        verifyNever(
          () => userProfileRepository.updateNickname(any(), any()),
        );
      },
    );

    test(
      'the derived nickname already being taken does not fail the upgrade',
      () async {
        final authRepository = _MockAuthRepository();
        final googleAuthService = _MockGoogleAuthService();
        final userProfileRepository = _MockUserProfileRepository();
        when(() => googleAuthService.signIn()).thenAnswer(
          (_) async => const GoogleAuthTokens(idToken: 'id-token'),
        );
        when(
          () => authRepository.linkWithGoogleCredential(
            idToken: any(named: 'idToken'),
          ),
        ).thenAnswer((_) async => 'pupa@gmail.com');
        when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
          (_) => Stream.value(
            FriendProfile(
              uid: 'uid-1',
              nickname: defaultStarterNickname('uid-1'),
              avatarPresetIndex: 0,
            ),
          ),
        );
        when(
          () => userProfileRepository.updateNickname('uid-1', 'pupa'),
        ).thenThrow(const NicknameTakenException('pupa'));

        final container = buildContainer(
          authRepository: authRepository,
          googleAuthService: googleAuthService,
          userProfileRepository: userProfileRepository,
        );
        addTearDown(container.dispose);

        final outcome = await container
            .read(authControllerProvider.notifier)
            .upgradeWithGoogle();

        expect(outcome, GoogleUpgradeOutcome.success);
      },
    );
  });

  group('currentUidProvider', () {
    test('mirrors the controller\'s uid', () {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FixedAuthController(
              const AuthState(uid: 'uid-1', isAnonymous: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentUidProvider), 'uid-1');
    });
  });

  group('build() / bootstrap — the real, un-overridden class', () {
    test(
      'signs in and then reflects further uidChanges (e.g. after linking)',
      () async {
        final authRepository = _MockAuthRepository();
        final uidController = StreamController<String?>.broadcast();
        addTearDown(uidController.close);

        when(() => authRepository.ensureSignedIn())
            .thenAnswer((_) async => 'anon-1');
        when(() => authRepository.isAnonymous).thenReturn(true);
        when(() => authRepository.uidChanges())
            .thenAnswer((_) => uidController.stream);

        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        );
        addTearDown(container.dispose);

        // A provider's build() is lazy, and _bootstrap() is fired
        // un-awaited from it — listen (which itself triggers build()) and
        // wait on a completer rather than guessing how many microtask/timer
        // turns the mocked chain needs.
        final signedIn = Completer<void>();
        container.listen<AuthState>(authControllerProvider, (_, next) {
          if (next.uid != null && !signedIn.isCompleted) {
            signedIn.complete();
          }
        }, fireImmediately: true);
        await signedIn.future;

        expect(container.read(authControllerProvider).uid, 'anon-1');

        uidController.add('anon-1'); // e.g. after a later re-emit
        await pumpEventQueue();

        expect(container.read(authControllerProvider).uid, 'anon-1');
      },
    );
  });
}
