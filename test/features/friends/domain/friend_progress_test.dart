import 'package:test/test.dart';
import 'package:thereandback/features/friends/domain/friend_progress.dart';

void main() {
  group('friendDeltaMeters (§5.3)', () {
    test('positive when the friend is ahead', () {
      expect(friendDeltaMeters(myMeters: 1000, friendMeters: 1229000), 1228000);
    });

    test('negative when the friend is behind', () {
      expect(friendDeltaMeters(myMeters: 5000, friendMeters: 2000), -3000);
    });

    test('zero when tied', () {
      expect(friendDeltaMeters(myMeters: 5000, friendMeters: 5000), 0);
    });
  });

  group('sortFriendRows (§6.4: own row always pinned first)', () {
    test('own row comes first even when far behind everyone else', () {
      final rows = [
        const FriendProgressRow(
          uid: 'me',
          nickname: 'Me',
          progressMeters: 100,
          isSelf: true,
        ),
        const FriendProgressRow(
          uid: 'bob',
          nickname: 'Bob',
          progressMeters: 5000,
          isSelf: false,
        ),
        const FriendProgressRow(
          uid: 'carol',
          nickname: 'Carol',
          progressMeters: 9000,
          isSelf: false,
        ),
      ];

      final sorted = sortFriendRows(rows);

      expect(sorted.map((r) => r.uid), ['me', 'carol', 'bob']);
    });

    test('other rows are ordered by descending progress', () {
      final rows = [
        const FriendProgressRow(
          uid: 'bob',
          nickname: 'Bob',
          progressMeters: 100,
          isSelf: false,
        ),
        const FriendProgressRow(
          uid: 'carol',
          nickname: 'Carol',
          progressMeters: 300,
          isSelf: false,
        ),
        const FriendProgressRow(
          uid: 'dave',
          nickname: 'Dave',
          progressMeters: 200,
          isSelf: false,
        ),
      ];

      final sorted = sortFriendRows(rows);

      expect(sorted.map((r) => r.uid), ['carol', 'dave', 'bob']);
    });

    test(
      'no own row present is not an error — just an unpinned sorted list',
      () {
        final rows = [
          const FriendProgressRow(
            uid: 'bob',
            nickname: 'Bob',
            progressMeters: 100,
            isSelf: false,
          ),
          const FriendProgressRow(
            uid: 'carol',
            nickname: 'Carol',
            progressMeters: 300,
            isSelf: false,
          ),
        ];

        expect(sortFriendRows(rows).map((r) => r.uid), ['carol', 'bob']);
      },
    );
  });
}
