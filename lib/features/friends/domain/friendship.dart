import 'package:freezed_annotation/freezed_annotation.dart';

part 'friendship.freezed.dart';

/// A friendship's lifecycle state (CLAUDE.md §5, §6.4).
///
/// Only `pending`/`accepted` this phase — the plan's remove/decline flow is
/// a plain, reversible delete of the document (a new request can be sent
/// from scratch afterward), so there is no permanent "blocked" state to
/// model yet. Adding one later, if a real abuse-blocking feature is asked
/// for, is a small addition on top of this — not a rework.
enum FriendshipStatus { pending, accepted }

/// A friendship between two users (CLAUDE.md §5: "связь двух пользователей,
/// статус"). Firestore document shape at `friendships/{pairId}` — this is
/// the domain type; the Firestore DTO and the mapping between them live in
/// `data/firestore/friendship_repository.dart` (§4 layer rule).
@freezed
abstract class Friendship with _$Friendship {
  const factory Friendship({
    required String pairId,

    /// Always exactly two uids, in the same sorted order [pairIdFor] would
    /// produce — the repository and the Security Rules both rely on that.
    required List<String> uids,
    required FriendshipStatus status,
    required String initiatorUid,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// uid -> hidden. A uid present with `true` means *that* user has chosen
    /// to hide their own progress from the other party (§7: "может скрыть
    /// свой прогресс от конкретного друга") — never the reverse.
    @Default(<String, bool>{}) Map<String, bool> hiddenBy,
  }) = _Friendship;

  const Friendship._();

  /// The uid on the other side of this friendship from [myUid].
  String otherUid(String myUid) => uids.firstWhere((uid) => uid != myUid);

  /// Whether [myUid] has chosen to hide their own progress from the other
  /// party of this friendship.
  bool isHiddenBy(String myUid) => hiddenBy[myUid] == true;
}

/// The one canonical friendship document id for an unordered pair of uids —
/// sorted so `pairIdFor(a, b) == pairIdFor(b, a)`. Both
/// `friendship_repository.dart` and `firestore.rules` derive it this exact
/// same way; a client can never end up with two documents for the same
/// pair, or a document keyed differently than the rules expect.
String pairIdFor(String uidA, String uidB) =>
    uidA.compareTo(uidB) < 0 ? '${uidA}_$uidB' : '${uidB}_$uidA';

/// Size of the fixed pin-color palette (§6.2, §6.4) — the actual colors live
/// in `design/colors.dart`; this is only the count [pinColorIndexForUid]
/// picks among.
const int friendPinPaletteSize = 8;

/// A small, stable palette index derived deterministically from [uid].
///
/// Deliberately **not** `String.hashCode` — Dart does not guarantee that
/// stays the same across platforms or SDK versions, and a friend's pin
/// color must be identical on the map and in the table (§6.4) for as long
/// as the friendship exists. FNV-1a over the uid's UTF-16 code units is
/// fully specified and portable, so this never needs to be stored or
/// written anywhere: recomputing it always gives the same answer for the
/// same uid, and "assigned once" falls out for free.
int pinColorIndexForUid(String uid) {
  const fnvOffsetBasis = 0x811c9dc5;
  const fnvPrime = 0x01000193;
  const mask32 = 0xFFFFFFFF;

  var hash = fnvOffsetBasis;
  for (final codeUnit in uid.codeUnits) {
    hash = (hash ^ codeUnit) & mask32;
    hash = (hash * fnvPrime) & mask32;
  }
  return hash % friendPinPaletteSize;
}
