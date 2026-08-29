import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:test/test.dart';
import 'package:thereandback/data/firestore/friendship_repository.dart';
import 'package:thereandback/features/friends/domain/friendship.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FriendshipRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreFriendshipRepository(firestore);
  });

  test(
    'sendRequest creates a pending document keyed by the sorted pair id',
    () async {
      await repository.sendRequest(fromUid: 'bob', toUid: 'alice');

      final doc = await firestore
          .collection('friendships')
          .doc('alice_bob')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['status'], 'pending');
      expect(doc.data()!['initiatorUid'], 'bob');
      expect(doc.data()!['uids'], ['alice', 'bob']);
    },
  );

  test('acceptRequest flips status to accepted', () async {
    await repository.sendRequest(fromUid: 'bob', toUid: 'alice');

    await repository.acceptRequest(pairIdFor('alice', 'bob'));

    final doc = await firestore
        .collection('friendships')
        .doc('alice_bob')
        .get();
    expect(doc.data()!['status'], 'accepted');
  });

  test(
    'removeOrDecline deletes the document, allowing a fresh request after',
    () async {
      final pairId = pairIdFor('alice', 'bob');
      await repository.sendRequest(fromUid: 'bob', toUid: 'alice');

      await repository.removeOrDecline(pairId);
      final deleted = await firestore
          .collection('friendships')
          .doc(pairId)
          .get();
      expect(deleted.exists, isFalse);

      // Reversible: a new request for the same pair is not blocked by
      // leftover state.
      await repository.sendRequest(fromUid: 'alice', toUid: 'bob');
      final recreated = await firestore
          .collection('friendships')
          .doc(pairId)
          .get();
      expect(recreated.data()!['status'], 'pending');
      expect(recreated.data()!['initiatorUid'], 'alice');
    },
  );

  test('setHidden touches only the caller\'s own key in hiddenBy', () async {
    final pairId = pairIdFor('alice', 'bob');
    await repository.sendRequest(fromUid: 'bob', toUid: 'alice');
    await repository.acceptRequest(pairId);

    await repository.setHidden(pairId, ownerUid: 'alice', hidden: true);

    final doc = await firestore.collection('friendships').doc(pairId).get();
    final hiddenBy = Map<String, dynamic>.from(doc.data()!['hiddenBy'] as Map);
    expect(hiddenBy['alice'], isTrue);
    expect(hiddenBy['bob'], isNot(true));
  });

  test(
    'watchMyFriendships returns every friendship uids contains this uid',
    () async {
      await repository.sendRequest(fromUid: 'alice', toUid: 'bob');
      await repository.sendRequest(fromUid: 'alice', toUid: 'carol');
      await repository.sendRequest(
        fromUid: 'dave',
        toUid: 'erin',
      ); // unrelated pair

      final mine = await repository.watchMyFriendships('alice').first;

      expect(mine, hasLength(2));
      expect(mine.map((f) => f.otherUid('alice')).toSet(), {'bob', 'carol'});
    },
  );

  test(
    'a friendship round-trips through Firestore with matching fields',
    () async {
      await repository.sendRequest(fromUid: 'alice', toUid: 'bob');
      await repository.acceptRequest(pairIdFor('alice', 'bob'));

      final friendship =
          (await repository.watchMyFriendships('alice').first).single;

      expect(friendship.pairId, 'alice_bob');
      expect(friendship.uids, ['alice', 'bob']);
      expect(friendship.status, FriendshipStatus.accepted);
      expect(friendship.initiatorUid, 'alice');
      expect(friendship.isHiddenBy('alice'), isFalse);
    },
  );
}
