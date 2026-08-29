import 'package:test/test.dart';
import 'package:thereandback/features/friends/domain/friendship.dart';

void main() {
  group('pairIdFor (§8)', () {
    test('is order-independent — the same pair always yields the same id', () {
      expect(pairIdFor('alice', 'bob'), pairIdFor('bob', 'alice'));
    });

    test('sorts lexicographically', () {
      expect(pairIdFor('bob', 'alice'), 'alice_bob');
    });

    test('different pairs get different ids', () {
      expect(pairIdFor('alice', 'bob'), isNot(pairIdFor('alice', 'carol')));
    });
  });

  group('pinColorIndexForUid (§6.4: assigned once, stable everywhere)', () {
    test('is deterministic — the same uid always gives the same index', () {
      const uid = 'user-42';
      expect(pinColorIndexForUid(uid), pinColorIndexForUid(uid));
    });

    test('stays within the palette bounds', () {
      for (final uid in ['a', 'user-1', 'a-much-longer-uid-string-here']) {
        final index = pinColorIndexForUid(uid);
        expect(index, greaterThanOrEqualTo(0));
        expect(index, lessThan(friendPinPaletteSize));
      }
    });

    test('different uids typically land on different indices', () {
      // Not a hash-collision guarantee — just confirms the function isn't
      // accidentally constant.
      final indices = {
        for (var i = 0; i < friendPinPaletteSize * 2; i++)
          i: pinColorIndexForUid('user-$i'),
      };
      expect(indices.values.toSet().length, greaterThan(1));
    });
  });

  group('Friendship', () {
    final friendship = Friendship(
      pairId: pairIdFor('alice', 'bob'),
      uids: const ['alice', 'bob'],
      status: FriendshipStatus.accepted,
      initiatorUid: 'alice',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    test('otherUid returns the other side of the pair', () {
      expect(friendship.otherUid('alice'), 'bob');
      expect(friendship.otherUid('bob'), 'alice');
    });

    test('isHiddenBy is false when hiddenBy has no entry for that uid', () {
      expect(friendship.isHiddenBy('alice'), isFalse);
    });

    test('isHiddenBy reflects the flag for that specific uid only', () {
      final hidden = friendship.copyWith(hiddenBy: const {'alice': true});
      expect(hidden.isHiddenBy('alice'), isTrue);
      expect(hidden.isHiddenBy('bob'), isFalse);
    });
  });
}
