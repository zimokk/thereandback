import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/friends/domain/friend_profile.dart';

/// Thrown by [UserProfileRepository.updateNickname] (and, in the extremely
/// unlikely event of a collision, [UserProfileRepository.createInitialProfileIfAbsent])
/// when a nickname is already claimed by a different uid.
class NicknameTakenException implements Exception {
  const NicknameTakenException(this.nickname);

  final String nickname;

  @override
  String toString() => 'NicknameTakenException($nickname)';
}

/// The starter nickname every fresh `users/{uid}` profile gets before
/// anyone customizes it (`ensureFriendProfile`,
/// `features/friends/presentation/friends_providers.dart`). Shared here —
/// rather than kept private to that provider — so another caller can tell
/// a still-default nickname apart from one the user chose: the Google
/// sign-in upgrade (`app/auth_provider.dart`, §6.5, §14) only overwrites
/// this exact placeholder, never a customized nickname.
String defaultStarterNickname(String uid) {
  final suffix = uid.length <= 6 ? uid : uid.substring(uid.length - 6);
  return 'Traveler-$suffix';
}

/// Firestore-backed `users/{uid}` (nickname, avatar preset — §8) plus the
/// `usernames/{nicknameLower}` reverse-lookup collection that "add friend by
/// nickname" needs (a fifth collection beyond CLAUDE.md §8's own
/// 4-collection draft — see the plan).
abstract class UserProfileRepository {
  /// Creates `users/{uid}` with a starter nickname/avatar if it doesn't
  /// already exist — a no-op on every later call for the same uid.
  Future<void> createInitialProfileIfAbsent(
    String uid, {
    required String nickname,
    required int avatarPresetIndex,
  });

  /// Renames a user, atomically releasing the old `usernames/{old}` claim
  /// and taking the new one.
  Future<void> updateNickname(String uid, String newNickname);

  Stream<FriendProfile?> watchProfile(String uid);

  /// Resolves a nickname to a uid, or `null` if nobody has claimed it.
  /// Case-insensitive — nicknames are looked up by their lowercased form.
  Future<String?> resolveUidForNickname(String nickname);
}

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');

  static String _lower(String nickname) => nickname.toLowerCase();

  @override
  Future<void> createInitialProfileIfAbsent(
    String uid, {
    required String nickname,
    required int avatarPresetIndex,
  }) async {
    final userDoc = _users.doc(uid);
    if ((await userDoc.get()).exists) return;

    final nicknameLower = _lower(nickname);
    final usernameDoc = _usernames.doc(nicknameLower);

    await _firestore.runTransaction((tx) async {
      // All reads before all writes — Firestore transactions require it.
      final usernameSnapshot = await tx.get(usernameDoc);
      if (usernameSnapshot.exists) {
        // Vanishingly unlikely for a freshly generated default nickname,
        // but never silently steal someone else's claim.
        throw NicknameTakenException(nickname);
      }

      tx.set(userDoc, {
        'nickname': nickname,
        'avatarPresetIndex': avatarPresetIndex,
      });
      tx.set(usernameDoc, {'uid': uid});
    });
  }

  @override
  Future<void> updateNickname(String uid, String newNickname) async {
    final newLower = _lower(newNickname);
    final newUsernameDoc = _usernames.doc(newLower);
    final userDoc = _users.doc(uid);

    await _firestore.runTransaction((tx) async {
      // Reads first (transaction requirement), including the read this
      // method's own claim-check depends on.
      final currentSnapshot = await tx.get(userDoc);
      final newUsernameSnapshot = await tx.get(newUsernameDoc);

      final claimedBy = newUsernameSnapshot.data()?['uid'] as String?;
      if (newUsernameSnapshot.exists && claimedBy != uid) {
        throw NicknameTakenException(newNickname);
      }

      final currentNickname = currentSnapshot.data()?['nickname'] as String?;
      if (currentNickname != null && _lower(currentNickname) != newLower) {
        tx.delete(_usernames.doc(_lower(currentNickname)));
      }
      tx.set(newUsernameDoc, {'uid': uid});
      // update(), not set(merge: true) — this must touch only `nickname`,
      // never clobber `avatarPresetIndex` or any other field.
      tx.update(userDoc, {'nickname': newNickname});
    });
  }

  @override
  Stream<FriendProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return FriendProfile(
        uid: uid,
        nickname: data['nickname'] as String? ?? '',
        avatarPresetIndex: (data['avatarPresetIndex'] as num?)?.toInt() ?? 0,
      );
    });
  }

  @override
  Future<String?> resolveUidForNickname(String nickname) async {
    final snapshot = await _usernames.doc(_lower(nickname)).get();
    if (!snapshot.exists) return null;
    return snapshot.data()?['uid'] as String?;
  }
}
