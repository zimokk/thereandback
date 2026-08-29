import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:test/test.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserProfileRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreUserProfileRepository(firestore);
  });

  group('createInitialProfileIfAbsent', () {
    test('creates the user doc and claims the nickname', () async {
      await repository.createInitialProfileIfAbsent(
        'uid-1',
        nickname: 'Odysseus',
        avatarPresetIndex: 2,
      );

      final userDoc = await firestore.collection('users').doc('uid-1').get();
      expect(userDoc.data()!['nickname'], 'Odysseus');
      expect(userDoc.data()!['avatarPresetIndex'], 2);

      final usernameDoc = await firestore
          .collection('usernames')
          .doc('odysseus')
          .get();
      expect(usernameDoc.data()!['uid'], 'uid-1');
    });

    test('is a no-op on a uid that already has a profile', () async {
      await repository.createInitialProfileIfAbsent(
        'uid-1',
        nickname: 'Odysseus',
        avatarPresetIndex: 2,
      );
      await repository.createInitialProfileIfAbsent(
        'uid-1',
        nickname: 'SomeoneElse',
        avatarPresetIndex: 5,
      );

      final userDoc = await firestore.collection('users').doc('uid-1').get();
      expect(userDoc.data()!['nickname'], 'Odysseus');
    });
  });

  group('updateNickname', () {
    test('releases the old claim and takes the new one', () async {
      await repository.createInitialProfileIfAbsent(
        'uid-1',
        nickname: 'Odysseus',
        avatarPresetIndex: 2,
      );

      await repository.updateNickname('uid-1', 'Nobody');

      final userDoc = await firestore.collection('users').doc('uid-1').get();
      expect(userDoc.data()!['nickname'], 'Nobody');
      // avatarPresetIndex must survive the rename untouched (tx.update, not
      // a full set that would have clobbered it).
      expect(userDoc.data()!['avatarPresetIndex'], 2);

      final oldUsernameDoc = await firestore
          .collection('usernames')
          .doc('odysseus')
          .get();
      expect(oldUsernameDoc.exists, isFalse);

      final newUsernameDoc = await firestore
          .collection('usernames')
          .doc('nobody')
          .get();
      expect(newUsernameDoc.data()!['uid'], 'uid-1');
    });

    test(
      'throws when the new nickname is already claimed by someone else',
      () async {
        await repository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: 'Odysseus',
          avatarPresetIndex: 2,
        );
        await repository.createInitialProfileIfAbsent(
          'uid-2',
          nickname: 'Penelope',
          avatarPresetIndex: 1,
        );

        await expectLater(
          repository.updateNickname('uid-1', 'Penelope'),
          throwsA(isA<NicknameTakenException>()),
        );

        // The original claim must be untouched by the failed attempt.
        final userDoc = await firestore.collection('users').doc('uid-1').get();
        expect(userDoc.data()!['nickname'], 'Odysseus');
      },
    );

    test(
      'renaming to the same nickname (case-insensitively) is fine',
      () async {
        await repository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: 'Odysseus',
          avatarPresetIndex: 2,
        );

        await repository.updateNickname('uid-1', 'ODYSSEUS');

        final userDoc = await firestore.collection('users').doc('uid-1').get();
        expect(userDoc.data()!['nickname'], 'ODYSSEUS');
      },
    );
  });

  group('watchProfile', () {
    test('emits null before any profile exists', () async {
      expect(repository.watchProfile('nobody-yet'), emits(isNull));
    });

    test('emits the profile once created', () async {
      await repository.createInitialProfileIfAbsent(
        'uid-1',
        nickname: 'Odysseus',
        avatarPresetIndex: 3,
      );
      // fake_cloud_firestore's transaction shim fires each write without
      // awaiting it internally, so the doc can still be mid-write for a
      // tick after `runTransaction` itself resolves — this is a quirk of
      // the fake, not of the repository (a direct `.get()` a moment later,
      // as the other tests in this file do, never observes it).
      await Future<void>.delayed(Duration.zero);

      final profile = await repository.watchProfile('uid-1').first;
      expect(profile!.uid, 'uid-1');
      expect(profile.nickname, 'Odysseus');
      expect(profile.avatarPresetIndex, 3);
    });
  });

  group('resolveUidForNickname', () {
    test('returns null for an unclaimed nickname', () async {
      expect(await repository.resolveUidForNickname('nobody'), isNull);
    });

    test('resolves case-insensitively', () async {
      await repository.createInitialProfileIfAbsent(
        'uid-1',
        nickname: 'Odysseus',
        avatarPresetIndex: 0,
      );

      expect(await repository.resolveUidForNickname('odysseus'), 'uid-1');
      expect(await repository.resolveUidForNickname('ODYSSEUS'), 'uid-1');
    });
  });
}
