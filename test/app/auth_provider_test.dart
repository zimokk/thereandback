import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/firebase/auth_repository.dart';
import 'package:thereandback/data/firebase/google_sign_in_service.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';
import 'package:thereandback/features/friends/domain/friend_profile.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockProgressSyncRepository extends Mock
    implements ProgressSyncRepository {}

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
  setUpAll(() {
    // mocktail needs a dummy instance for `any()` on a non-nullable
    // non-primitive parameter type — `pushProgress`'s `startedAt` below.
    registerFallbackValue(DateTime(2020));
  });

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
  });

  group('an already-linked Google identity — "repeat login" switches to the '
      'existing account instead of failing (§8, §14)', () {
    late _MockAuthRepository authRepository;
    late _MockGoogleAuthService googleAuthService;
    late _MockProgressSyncRepository progressSyncRepository;
    late AppDatabase db;

    ProviderContainer buildContainer({AuthState? initialState}) {
      when(() => authRepository.ensureSignedIn())
          .thenAnswer((_) async => 'anon-1');
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
      when(
        () => authRepository.linkWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenThrow(const GoogleAccountAlreadyLinkedException());
      when(
        () => authRepository.signInWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => 'existing-uid');
      when(
        () => progressSyncRepository.pushProgress(
          uid: any(named: 'uid'),
          journeyId: any(named: 'journeyId'),
          meters: any(named: 'meters'),
          startedAt: any(named: 'startedAt'),
          isCurrent: any(named: 'isCurrent'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          googleAuthServiceProvider.overrideWithValue(googleAuthService),
          progressSyncRepositoryProvider.overrideWithValue(
            progressSyncRepository,
          ),
          // `testing` skill: never a real drift database in a test.
          appDatabaseProvider.overrideWithValue(db),
          authControllerProvider.overrideWith(
            () => _FixedAuthController(
              initialState ?? const AuthState(uid: 'anon-1', isAnonymous: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() {
      authRepository = _MockAuthRepository();
      googleAuthService = _MockGoogleAuthService();
      progressSyncRepository = _MockProgressSyncRepository();
      db = AppDatabase.forTesting();
    });
    tearDown(() => db.close());

    test('switches the session — existingAccountRestored, uid updated, '
        'no longer anonymous', () async {
      when(() => progressSyncRepository.fetchCurrentProgress('existing-uid'))
          .thenAnswer((_) async => null);
      final container = buildContainer();

      final outcome = await container
          .read(authControllerProvider.notifier)
          .upgradeWithGoogle();

      expect(outcome, GoogleUpgradeOutcome.existingAccountRestored);
      final state = container.read(authControllerProvider);
      expect(state.uid, 'existing-uid');
      expect(state.isAnonymous, isFalse);
    });

    test(
      'the cloud total is bigger — it replaces local drift progress',
      () async {
        when(() => progressSyncRepository.fetchCurrentProgress('existing-uid'))
            .thenAnswer(
              (_) async => RemoteQuestProgress(
                journeyId: 'odyssey-ithaca',
                meters: 400000,
                startedAt: DateTime.utc(2026, 3, 1),
              ),
            );
        final container = buildContainer();
        // No quest started locally on this device — `selectedJourneyProvider`
        // starts at `null`, so its own progress is 0.

        await container
            .read(authControllerProvider.notifier)
            .upgradeWithGoogle();

        final quest = container.read(selectedJourneyProvider);
        expect(quest, isNotNull);
        expect(quest!.journeyId, 'odyssey-ithaca');
        expect(quest.progressMeters, 400000);
        verifyNever(
          () => progressSyncRepository.pushProgress(
            uid: any(named: 'uid'),
            journeyId: any(named: 'journeyId'),
            meters: any(named: 'meters'),
            startedAt: any(named: 'startedAt'),
            isCurrent: any(named: 'isCurrent'),
          ),
        );
      },
    );

    test('the local total is bigger — drift is left alone, cloud is pushed '
        'up to match it', () async {
      when(() => progressSyncRepository.fetchCurrentProgress('existing-uid'))
          .thenAnswer(
            (_) async => RemoteQuestProgress(
              journeyId: 'odyssey-ithaca',
              meters: 1000,
              startedAt: DateTime.utc(2026, 3, 1),
            ),
          );
      final container = buildContainer();
      final startedAt = DateTime(2026, 3, 1);
      container
          .read(selectedJourneyProvider.notifier)
          .start('odyssey-ithaca', now: startedAt);
      container
          .read(selectedJourneyProvider.notifier)
          .applySyncedProgress(
            progressMeters: 50000,
            syncedAt: DateTime(2026, 3, 15),
          );

      await container.read(authControllerProvider.notifier).upgradeWithGoogle();

      // Local drift/state untouched — still the locally-synced total.
      expect(container.read(selectedJourneyProvider)!.progressMeters, 50000);
      verify(
        () => progressSyncRepository.pushProgress(
          uid: 'existing-uid',
          journeyId: 'odyssey-ithaca',
          meters: 50000,
          startedAt: startedAt,
          isCurrent: true,
        ),
      ).called(1);
    });

    test(
      'neither side has any progress — no drift write, no cloud push',
      () async {
        when(() => progressSyncRepository.fetchCurrentProgress('existing-uid'))
            .thenAnswer((_) async => null);
        final container = buildContainer();

        await container
            .read(authControllerProvider.notifier)
            .upgradeWithGoogle();

        expect(container.read(selectedJourneyProvider), isNull);
        verifyNever(
          () => progressSyncRepository.pushProgress(
            uid: any(named: 'uid'),
            journeyId: any(named: 'journeyId'),
            meters: any(named: 'meters'),
            startedAt: any(named: 'startedAt'),
            isCurrent: any(named: 'isCurrent'),
          ),
        );
      },
    );

    test('a reconciliation failure (e.g. offline) never undoes the '
        'already-succeeded account switch', () async {
      when(() => progressSyncRepository.fetchCurrentProgress('existing-uid'))
          .thenThrow(Exception('offline'));
      final container = buildContainer();

      final outcome = await container
          .read(authControllerProvider.notifier)
          .upgradeWithGoogle();

      expect(outcome, GoogleUpgradeOutcome.existingAccountRestored);
      expect(container.read(authControllerProvider).uid, 'existing-uid');
    });
  });

  group('upgradeWithGoogle — default nickname from the Google email (§14)', () {
    ProviderContainer buildContainer({
      required _MockAuthRepository authRepository,
      required _MockGoogleAuthService googleAuthService,
      required _MockUserProfileRepository userProfileRepository,
      String uid = 'uid-1',
    }) {
      when(() => authRepository.ensureSignedIn()).thenAnswer((_) async => uid);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          googleAuthServiceProvider.overrideWithValue(googleAuthService),
          userProfileRepositoryProvider.overrideWithValue(
            userProfileRepository,
          ),
          authControllerProvider.overrideWith(
            () => _FixedAuthController(AuthState(uid: uid, isAnonymous: true)),
          ),
        ],
      );
      return container;
    }

    test('defaults the nickname to the email\'s local part when the profile '
        'still has the generated placeholder', () async {
      final authRepository = _MockAuthRepository();
      final googleAuthService = _MockGoogleAuthService();
      final userProfileRepository = _MockUserProfileRepository();
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
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
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      when(() => userProfileRepository.updateNickname('uid-1', 'pupa'))
          .thenAnswer((_) async {});

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
      verify(() => userProfileRepository.updateNickname('uid-1', 'pupa'))
          .called(1);
    });

    test('strips a Gmail "+tag" suffix from the default — it\'s an address '
        'filter, not part of the account', () async {
      final authRepository = _MockAuthRepository();
      final googleAuthService = _MockGoogleAuthService();
      final userProfileRepository = _MockUserProfileRepository();
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
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
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      when(() => userProfileRepository.updateNickname('uid-1', 'pupa'))
          .thenAnswer((_) async {});

      final container = buildContainer(
        authRepository: authRepository,
        googleAuthService: googleAuthService,
        userProfileRepository: userProfileRepository,
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).upgradeWithGoogle();

      verify(() => userProfileRepository.updateNickname('uid-1', 'pupa'))
          .called(1);
    });

    test('never overwrites a nickname the user already customized', () async {
      final authRepository = _MockAuthRepository();
      final googleAuthService = _MockGoogleAuthService();
      final userProfileRepository = _MockUserProfileRepository();
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
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
      when(
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
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
      verifyNever(() => userProfileRepository.updateNickname(any(), any()));
    });

    test('the derived nickname already being taken retries with a numeric '
        'suffix (this task\'s requirement) rather than giving up on the '
        'first collision', () async {
      final authRepository = _MockAuthRepository();
      final googleAuthService = _MockGoogleAuthService();
      final userProfileRepository = _MockUserProfileRepository();
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
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
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      // 'pupa' and 'pupa-1' are both already claimed by someone else;
      // 'pupa-2' is free.
      when(() => userProfileRepository.updateNickname('uid-1', 'pupa'))
          .thenThrow(const NicknameTakenException('pupa'));
      when(() => userProfileRepository.updateNickname('uid-1', 'pupa-1'))
          .thenThrow(const NicknameTakenException('pupa-1'));
      when(() => userProfileRepository.updateNickname('uid-1', 'pupa-2'))
          .thenAnswer((_) async {});

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
      verify(() => userProfileRepository.updateNickname('uid-1', 'pupa-2'))
          .called(1);
    });

    test('the profile doc doesn\'t exist yet (ensureFriendProfileProvider\'s '
        'own bootstrap hasn\'t landed) — still applies the email-derived '
        'default rather than leaving the generic placeholder for good '
        '(regression: used to only read the profile and bail out on null)',
        () async {
      final authRepository = _MockAuthRepository();
      final googleAuthService = _MockGoogleAuthService();
      final userProfileRepository = _MockUserProfileRepository();
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
      when(
        () => authRepository.linkWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => 'pupa@gmail.com');

      // Mirrors the real repository: `watchProfile` sees nothing until
      // `createInitialProfileIfAbsent` actually creates the doc.
      var created = false;
      when(
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {
        created = true;
      });
      when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
        (_) => Stream.value(
          created
              ? FriendProfile(
                  uid: 'uid-1',
                  nickname: defaultStarterNickname('uid-1'),
                  avatarPresetIndex: 0,
                )
              : null,
        ),
      );
      when(() => userProfileRepository.updateNickname('uid-1', 'pupa'))
          .thenAnswer((_) async {});

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
      verify(() => userProfileRepository.updateNickname('uid-1', 'pupa'))
          .called(1);
    });

    test('every numbered variant up to the cap also being taken still does '
        'not fail the upgrade — the placeholder is left in place rather than '
        'retrying forever', () async {
      final authRepository = _MockAuthRepository();
      final googleAuthService = _MockGoogleAuthService();
      final userProfileRepository = _MockUserProfileRepository();
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
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
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      // Every candidate this loop could ever try is taken.
      when(() => userProfileRepository.updateNickname('uid-1', any()))
          .thenThrow(const NicknameTakenException('taken'));

      final container = buildContainer(
        authRepository: authRepository,
        googleAuthService: googleAuthService,
        userProfileRepository: userProfileRepository,
      );
      addTearDown(container.dispose);

      final outcome = await container
          .read(authControllerProvider.notifier)
          .upgradeWithGoogle();

      // The best-effort nickname default failed entirely, but that alone
      // must never fail the upgrade itself (§8's own outcome is about
      // the account switch, not the nickname convenience on top of it).
      expect(outcome, GoogleUpgradeOutcome.success);
    });
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
