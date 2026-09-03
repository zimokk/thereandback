import 'package:cloud_firestore/cloud_firestore.dart';

/// The signed-in user's own currently-active quest, as last pushed to
/// Firestore from *some* device (§8, §14 — "repeat login"). Read back by
/// `AuthController` when switching to an existing account, to reconcile
/// against this device's local progress (`ProgressRepository.
/// restoreFromCloud`) rather than silently keeping whichever one happened
/// to be in local drift.
class RemoteQuestProgress {
  const RemoteQuestProgress({
    required this.journeyId,
    required this.meters,
    required this.startedAt,
  });

  final String journeyId;
  final int meters;
  final DateTime startedAt;
}

/// Firestore-backed `users/{uid}/progress/{journeyId}` (§8). Running total
/// only — no history/snapshots, so there is no windowed (day/week) figure
/// to derive; the plan deliberately dropped that toggle rather than fake an
/// imprecise client-side estimate.
abstract class ProgressSyncRepository {
  /// Pushes the current running total for [journeyId] (§5.2: called once
  /// with `meters: 0` the instant a quest starts, and again after every
  /// successful foreground sync — never per pedometer tick or on its own
  /// timer; see `data/firestore/firestore_providers.dart`'s
  /// `pushProgressBestEffort`, the shared caller for both). Fire-and-forget
  /// from the caller's point of view: a failure here must never affect the
  /// local, already-durable drift write it follows (§8's full-offline
  /// requirement).
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

  /// [uid]'s own currently-active quest (`isCurrent == true`), or `null` if
  /// they have never pushed any progress. Reading one's own data — always
  /// allowed by `firestore.rules`' `isSelf(uid)` clause, no rule change
  /// needed. MVP has one journey in the catalog (§14), so at most one doc
  /// can ever have `isCurrent == true`; `limit(1)` is a safety margin, not
  /// a real ambiguity today.
  Future<RemoteQuestProgress?> fetchCurrentProgress(String uid);
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

  @override
  Future<RemoteQuestProgress?> fetchCurrentProgress(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .where('isCurrent', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data();
    final startedAt = data['startedAt'] as Timestamp?;
    if (startedAt == null) return null;

    return RemoteQuestProgress(
      journeyId: doc.id,
      meters: (data['meters'] as num?)?.toInt() ?? 0,
      startedAt: startedAt.toDate(),
    );
  }
}
