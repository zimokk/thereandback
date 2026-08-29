import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:test/test.dart';
import 'package:thereandback/data/firebase/auth_repository.dart';

void main() {
  group('ensureSignedIn (§8: silent anonymous sign-in)', () {
    test('signs in anonymously when there is no session yet', () async {
      final auth = MockFirebaseAuth();
      final repository = FirebaseAuthRepository(auth);

      final uid = await repository.ensureSignedIn();

      expect(uid, isNotEmpty);
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.isAnonymous, isTrue);
    });

    test('returns the existing uid without signing in again', () async {
      final mockUser = MockUser(isAnonymous: true, uid: 'already-here');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final repository = FirebaseAuthRepository(auth);

      final uid = await repository.ensureSignedIn();

      expect(uid, 'already-here');
    });
  });

  group('isAnonymous', () {
    test('true for a freshly anonymous session', () async {
      final mockUser = MockUser(isAnonymous: true);
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final repository = FirebaseAuthRepository(auth);

      expect(repository.isAnonymous, isTrue);
    });

    test('false once a permanent identity is attached', () async {
      final mockUser = MockUser(isAnonymous: false);
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final repository = FirebaseAuthRepository(auth);

      expect(repository.isAnonymous, isFalse);
    });
  });

  group('uidChanges', () {
    test('emits the current uid after signing in', () async {
      final auth = MockFirebaseAuth();
      final repository = FirebaseAuthRepository(auth);

      final future = repository.uidChanges().firstWhere((uid) => uid != null);
      await repository.ensureSignedIn();

      expect(await future, isNotEmpty);
    });
  });

  group('linkWithGoogleCredential (§8, §14 upgrade path)', () {
    test('upgrades the session — delegates to the current user', () async {
      // firebase_auth_mocks' own MockUser.linkWithCredential() asserts its
      // resulting MockUserCredential's `isAnonymous` (hardcoded `false`,
      // i.e. "no longer anonymous after linking") matches the user it was
      // called on — so this particular mock must already be `false` here,
      // even though a real upgrade starts from an anonymous session; that
      // mismatch is a quirk of the mock, not of `FirebaseAuthRepository`
      // itself (covered directly by `isAnonymous` above).
      final mockUser = MockUser(isAnonymous: false, uid: 'anon-success');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final repository = FirebaseAuthRepository(auth);

      // Just confirms this doesn't throw for the happy path — MockUser's
      // own linkWithCredential() always "succeeds" unless an exception was
      // registered against it (see the throwing case below).
      await repository.linkWithGoogleCredential(idToken: 'fake-id-token');
    });

    test(
      'maps Firebase\'s credential-already-in-use to '
      'GoogleAccountAlreadyLinkedException, not a raw FirebaseAuthException',
      () async {
        // A distinct uid per test — `MockUser` is `Equatable`, and
        // `mock_exceptions`' registry is a global map keyed by object
        // equality that nothing here clears, so two tests reusing the same
        // uid would share (and leak) each other's registered exceptions.
        final mockUser = MockUser(
          isAnonymous: true,
          uid: 'anon-already-in-use',
        );
        final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
        final repository = FirebaseAuthRepository(auth);

        whenCalling(Invocation.method(#linkWithCredential, [anything]))
            .on(mockUser)
            .thenThrow(
              FirebaseAuthException(code: 'credential-already-in-use'),
            );

        await expectLater(
          repository.linkWithGoogleCredential(idToken: 'fake-id-token'),
          throwsA(isA<GoogleAccountAlreadyLinkedException>()),
        );
      },
    );

    test('any other FirebaseAuthException is rethrown as-is', () async {
      final mockUser = MockUser(isAnonymous: true, uid: 'anon-other-error');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final repository = FirebaseAuthRepository(auth);

      whenCalling(Invocation.method(#linkWithCredential, [anything]))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await expectLater(
        repository.linkWithGoogleCredential(idToken: 'fake-id-token'),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'network-request-failed',
          ),
        ),
      );
    });

    test('throws a StateError if called with no signed-in user', () async {
      final auth = MockFirebaseAuth();
      final repository = FirebaseAuthRepository(auth);

      await expectLater(
        repository.linkWithGoogleCredential(idToken: 'fake-id-token'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
