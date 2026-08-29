import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_profile.freezed.dart';

/// The public-facing slice of `users/{uid}` (§8): nickname and avatar only.
///
/// Deliberately not the full CLAUDE.md §5 `UserProfile` (stride length,
/// privacy settings) — those stay local/drift-backed, owned by the
/// `profile` feature, and never leave the device. This is only what the
/// friends feature needs to show about another user, and what
/// `firestore.rules` treats as non-sensitive and readable by any signed-in
/// user (§7: nickname/avatar aren't health-adjacent).
///
/// [avatarPresetIndex] indexes a small local palette of preset
/// avatars/colors, not an uploaded photo (plan: avoids `firebase_storage`
/// and a moderation surface this phase).
@freezed
abstract class FriendProfile with _$FriendProfile {
  const factory FriendProfile({
    required String uid,
    required String nickname,
    required int avatarPresetIndex,
  }) = _FriendProfile;
}
