import 'friendship.dart';

/// One row of the Challengers table (§6.4): either the signed-in user
/// themself, or one accepted friend. Plain data — no Flutter import — so
/// `friends_providers.dart` can hand these straight to the widget layer.
class FriendProgressRow {
  const FriendProgressRow({
    required this.uid,
    required this.nickname,
    required this.progressMeters,
    required this.isSelf,
  });

  final String uid;
  final String nickname;

  /// Running total for the currently selected quest (§8) — all-time only;
  /// there is no day/week windowed figure this phase (nothing in Firestore
  /// records history to diff against).
  final int progressMeters;
  final bool isSelf;

  /// Derived, never stored — see [pinColorIndexForUid].
  int get pinColorIndex => pinColorIndexForUid(uid);
}

/// §5.3 "Дельта друга": the friend's progress minus mine, signed. Positive
/// means the friend is ahead.
int friendDeltaMeters({required int myMeters, required int friendMeters}) =>
    friendMeters - myMeters;

/// Sorts the Challengers table: the caller's own row is always pinned first
/// (§6.4: "Собственная строка всегда закреплена"), everyone else ordered by
/// descending progress.
List<FriendProgressRow> sortFriendRows(List<FriendProgressRow> rows) {
  final self = rows.where((row) => row.isSelf);
  final others = rows.where((row) => !row.isSelf).toList()
    ..sort((a, b) => b.progressMeters.compareTo(a.progressMeters));
  return [...self, ...others];
}
