import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/friends/domain/friendship.dart';

/// Firestore-backed `friendships/{pairId}` (§8, §6.4). `firestore.rules` is
/// the real enforcement (mutual confirmation, self-only hide-toggle,
/// reversible delete) — this repository only shapes the reads/writes the
/// app needs and never assumes a write it makes is actually allowed, same
/// as any other Firestore client.
abstract class FriendshipRepository {
  /// Sends a friend request. The document id is [pairIdFor]'s sorted pair
  /// id, so a second request for the same pair while one already exists
  /// fails at the rules layer (create requires the document not already
  /// exist) rather than silently overwriting anything.
  Future<void> sendRequest({required String fromUid, required String toUid});

  /// Accepts a pending request — must be called by the non-initiator; the
  /// rules reject any other caller.
  Future<void> acceptRequest(String pairId);

  /// Removes a friend, declines an incoming request, or cancels your own
  /// outgoing request — all the same operation (§6.4: reversible; a new
  /// request can be sent from scratch afterward).
  Future<void> removeOrDecline(String pairId);

  /// Hides (or unhides) [ownerUid]'s own progress from the other side of
  /// this friendship (§7). [ownerUid] must be the caller — the rules only
  /// allow touching your own key in `hiddenBy`.
  Future<void> setHidden(
    String pairId, {
    required String ownerUid,
    required bool hidden,
  });

  /// All friendships (pending or accepted, either direction) involving
  /// [myUid].
  Stream<List<Friendship>> watchMyFriendships(String myUid);
}

class FirestoreFriendshipRepository implements FriendshipRepository {
  FirestoreFriendshipRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _friendships =>
      _firestore.collection('friendships');

  @override
  Future<void> sendRequest({required String fromUid, required String toUid}) {
    final pairId = pairIdFor(fromUid, toUid);
    final sortedUids = [fromUid, toUid]..sort();
    final now = Timestamp.now();

    return _friendships.doc(pairId).set({
      'uids': sortedUids,
      'status': 'pending',
      'initiatorUid': fromUid,
      'createdAt': now,
      'updatedAt': now,
      'hiddenBy': <String, bool>{},
    });
  }

  @override
  Future<void> acceptRequest(String pairId) {
    return _friendships.doc(pairId).update({
      'status': 'accepted',
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> removeOrDecline(String pairId) {
    return _friendships.doc(pairId).delete();
  }

  @override
  Future<void> setHidden(
    String pairId, {
    required String ownerUid,
    required bool hidden,
  }) {
    return _friendships.doc(pairId).update({
      'hiddenBy.$ownerUid': hidden,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Stream<List<Friendship>> watchMyFriendships(String myUid) {
    return _friendships
        .where('uids', arrayContains: myUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  Friendship _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Friendship(
      pairId: doc.id,
      uids: List<String>.from(data['uids'] as List),
      status: (data['status'] as String) == 'accepted'
          ? FriendshipStatus.accepted
          : FriendshipStatus.pending,
      initiatorUid: data['initiatorUid'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      hiddenBy: (data['hiddenBy'] as Map?)?.cast<String, bool>() ?? const {},
    );
  }
}
