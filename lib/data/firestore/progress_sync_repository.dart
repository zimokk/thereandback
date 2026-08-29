import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed `users/{uid}/progress/{journeyId}` (§8). Running total
/// only — no history/snapshots, so there is no windowed (day/week) figure
/// to derive; the plan deliberately dropped that toggle rather than fake an
/// imprecise client-side estimate.
abstract class ProgressSyncRepository {
  /// Pushes the current running total for [journeyId] (§5.2: called after
  /// every successful foreground sync, not per pedometer tick — never on
  /// its own timer). Fire-and-forget from the caller's point of view: a
  /// failure here must never affect the local, already-durable drift write
  /// it follows (§8's full-offline requirement).
  Future<void> pushProgress({
    required String uid,
    required String journeyId,
    required int meters,
    required DateTime startedAt,
    required bool isCurrent,
  });

  /// A friend's current running total for [journeyId], or `null` if they
  /// have never pushed any (or the read is denied — see `firestore.rules`,
  /// which the caller is expected to have already checked via an accepted,
  /// not-hidden friendship before subscribing).
  Stream<int?> watchFriendProgress(String friendUid, String journeyId);
}

class FirestoreProgressSyncRepository implements ProgressSyncRepository {
  FirestoreProgressSyncRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _progressDoc(
    String uid,
    String journeyId,
  ) => _firestore
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc(journeyId);

  @override
  Future<void> pushProgress({
    required String uid,
    required String journeyId,
    required int meters,
    required DateTime startedAt,
    required bool isCurrent,
  }) {
    return _progressDoc(uid, journeyId).set({
      'meters': meters,
      'startedAt': Timestamp.fromDate(startedAt.toUtc()),
      'updatedAt': Timestamp.now(),
      'isCurrent': isCurrent,
    }, SetOptions(merge: true));
  }

  @override
  Stream<int?> watchFriendProgress(String friendUid, String journeyId) {
    return _progressDoc(friendUid, journeyId).snapshots().map((snapshot) {
      final meters = snapshot.data()?['meters'] as num?;
      return meters?.toInt();
    });
  }
}
