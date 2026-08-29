import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:test/test.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProgressSyncRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreProgressSyncRepository(firestore);
  });

  test('pushProgress writes meters, startedAt and isCurrent', () async {
    final startedAt = DateTime.utc(2026, 3, 1);
    await repository.pushProgress(
      uid: 'uid-1',
      journeyId: 'odyssey-ithaca',
      meters: 5230,
      startedAt: startedAt,
      isCurrent: true,
    );

    final doc = await firestore
        .collection('users')
        .doc('uid-1')
        .collection('progress')
        .doc('odyssey-ithaca')
        .get();
    expect(doc.data()!['meters'], 5230);
    expect(doc.data()!['isCurrent'], isTrue);
  });

  test('pushProgress merges rather than overwriting other fields', () async {
    await repository.pushProgress(
      uid: 'uid-1',
      journeyId: 'odyssey-ithaca',
      meters: 1000,
      startedAt: DateTime.utc(2026, 3, 1),
      isCurrent: true,
    );
    await repository.pushProgress(
      uid: 'uid-1',
      journeyId: 'odyssey-ithaca',
      meters: 2000,
      startedAt: DateTime.utc(2026, 3, 1),
      isCurrent: true,
    );

    final doc = await firestore
        .collection('users')
        .doc('uid-1')
        .collection('progress')
        .doc('odyssey-ithaca')
        .get();
    expect(doc.data()!['meters'], 2000);
  });

  test('watchFriendProgress emits null before any push', () async {
    expect(
      repository.watchFriendProgress('nobody-yet', 'odyssey-ithaca'),
      emits(isNull),
    );
  });

  test('watchFriendProgress reflects a pushed total', () async {
    await repository.pushProgress(
      uid: 'friend-1',
      journeyId: 'odyssey-ithaca',
      meters: 340000,
      startedAt: DateTime.utc(2026, 3, 1),
      isCurrent: true,
    );

    final meters = await repository
        .watchFriendProgress('friend-1', 'odyssey-ithaca')
        .first;
    expect(meters, 340000);
  });
}
