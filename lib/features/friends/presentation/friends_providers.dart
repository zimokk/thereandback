import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/auth_provider.dart';
import '../../../data/firestore/firestore_providers.dart';
import '../../../data/firestore/user_profile_repository.dart';
import '../../journey/presentation/journey_providers.dart';
import '../domain/friend_profile.dart';
import '../domain/friend_progress.dart';
import '../domain/friendship.dart';

part 'friends_providers.g.dart';

/// The signed-in user's own `users/{uid}` profile — `null` before it's been
/// created (see [ensureFriendProfile]) or before [currentUidProvider]
/// resolves a uid.
@riverpod
Stream<FriendProfile?> myProfile(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watchProfile(uid);
}

/// Creates a starter `users/{uid}` profile (default nickname + a fixed
/// preset avatar) the first time a uid is available — every user needs one
/// before "add friend by nickname" can find or be found by them. A no-op
/// once a profile already exists ([UserProfileRepository
/// .createInitialProfileIfAbsent]), and a collision on the generated
/// starter nickname (vanishingly unlikely — it embeds the uid) is swallowed
/// rather than surfaced, matching the rest of this feature's
/// fire-and-forget bootstrapping.
@riverpod
Future<void> ensureFriendProfile(Ref ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;

  try {
    await ref
        .watch(userProfileRepositoryProvider)
        .createInitialProfileIfAbsent(
          uid,
          nickname: defaultStarterNickname(uid),
          avatarPresetIndex: pinColorIndexForUid(uid),
        );
  } on NicknameTakenException {
    // See doc comment above.
  }
}

/// Every friendship (pending or accepted, either direction) involving the
/// signed-in user — a live Firestore stream, so an incoming accept or a
/// friend's own action is reflected without a manual refresh.
@riverpod
Stream<List<Friendship>> friendships(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendshipRepositoryProvider).watchMyFriendships(uid);
}

/// One pending request, either direction — enough for the Challengers tab
/// to name who it's with (§6.4).
class PendingFriendRequest {
  const PendingFriendRequest({
    required this.pairId,
    required this.otherUid,
    required this.otherNickname,
  });

  final String pairId;
  final String otherUid;
  final String otherNickname;
}

/// Everything the Challengers tab needs in one shape (§6.4): the sorted
/// comparison table (own row pinned first, §6.4) and the two pending-
/// request sections.
class FriendsViewData {
  const FriendsViewData({
    required this.rows,
    required this.incoming,
    required this.outgoing,
  });

  static const empty = FriendsViewData(rows: [], incoming: [], outgoing: []);

  final List<FriendProgressRow> rows;
  final List<PendingFriendRequest> incoming;
  final List<PendingFriendRequest> outgoing;
}

/// Composes [friendshipsProvider], [myProfileProvider] and each accepted
/// friend's profile/progress into one [FriendsViewData].
///
/// Deliberately a one-shot [Future] rebuilt on its watched dependencies
/// (§8: running-total progress only, no history) rather than a fully
/// reactive per-friend combine-latest — a friend's progress refreshes
/// whenever this rebuilds (the signed-in user's own sync, a friendship
/// change, pull-to-refresh), the same coarse "foreground sync" cadence the
/// rest of the app already uses (§7), not a live subscription to every
/// friend's every write.
@riverpod
Future<FriendsViewData> friendsView(Ref ref) async {
  final myUid = ref.watch(currentUidProvider);
  if (myUid == null) return FriendsViewData.empty;

  final journey = ref.watch(selectedJourneyProvider);
  final friendships = ref.watch(friendshipsProvider).value ?? const [];
  final myProfile = ref.watch(myProfileProvider).value;

  final profileRepository = ref.watch(userProfileRepositoryProvider);
  final progressRepository = ref.watch(progressSyncRepositoryProvider);

  final accepted = friendships.where(
    (f) => f.status == FriendshipStatus.accepted,
  );
  final incomingFriendships = friendships.where(
    (f) => f.isIncomingPendingFor(myUid),
  );
  final outgoingFriendships = friendships.where(
    (f) => f.isOutgoingPendingFor(myUid),
  );

  final friendRows = await Future.wait(
    accepted.map((friendship) async {
      final friendUid = friendship.otherUid(myUid);
      // The friend has hidden their own progress from me (§7) — Security
      // Rules would deny this read anyway; skip the row rather than let a
      // permission-denied error surface for one friend and break the rest.
      if (friendship.isHiddenBy(friendUid)) return null;

      final profile = await profileRepository.watchProfile(friendUid).first;
      final meters = journey == null
          ? 0
          : await progressRepository
                    .watchFriendProgress(friendUid, journey.journeyId)
                    .first ??
                0;
      return FriendProgressRow(
        uid: friendUid,
        nickname: profile?.nickname ?? friendUid,
        progressMeters: meters,
        isSelf: false,
        pairId: friendship.pairId,
      );
    }),
  );

  final incoming = await Future.wait(
    incomingFriendships.map(
      (f) => _toPendingRequest(f, myUid, profileRepository),
    ),
  );
  final outgoing = await Future.wait(
    outgoingFriendships.map(
      (f) => _toPendingRequest(f, myUid, profileRepository),
    ),
  );

  final rows = <FriendProgressRow>[
    FriendProgressRow(
      uid: myUid,
      nickname: myProfile?.nickname ?? '',
      progressMeters: journey?.progressMeters ?? 0,
      isSelf: true,
    ),
    for (final row in friendRows) ?row,
  ];

  return FriendsViewData(
    rows: sortFriendRows(rows),
    incoming: incoming,
    outgoing: outgoing,
  );
}

Future<PendingFriendRequest> _toPendingRequest(
  Friendship friendship,
  String myUid,
  UserProfileRepository profileRepository,
) async {
  final otherUid = friendship.otherUid(myUid);
  final profile = await profileRepository.watchProfile(otherUid).first;
  return PendingFriendRequest(
    pairId: friendship.pairId,
    otherUid: otherUid,
    otherNickname: profile?.nickname ?? otherUid,
  );
}

/// The outcome of [FriendsController.addFriendByNickname] — the UI renders
/// each case explicitly (§6.4).
enum AddFriendOutcome {
  sent,
  nicknameNotFound,
  cannotAddSelf,
  alreadyExists,
  notSignedIn,
  googleUpgradeCancelled,
  googleUpgradeAlreadyLinked,
}

/// The outcome of [FriendsController.updateNickname] — the UI renders each
/// case explicitly, same shape as [AddFriendOutcome].
enum UpdateNicknameOutcome { success, nicknameTaken, notSignedIn }

/// Imperative actions for the Challengers tab (§6.4) and the Settings
/// nickname editor (§6.5): sending a request by nickname (triggering the
/// Google upgrade first if still anonymous), accepting, removing/declining,
/// the per-friend hide toggle (§7), and renaming the signed-in user's own
/// nickname.
@riverpod
class FriendsController extends _$FriendsController {
  @override
  void build() {}

  Future<AddFriendOutcome> addFriendByNickname(String nickname) async {
    if (ref.read(authControllerProvider).isAnonymous) {
      final upgrade = await ref
          .read(authControllerProvider.notifier)
          .upgradeWithGoogle();
      switch (upgrade) {
        case GoogleUpgradeOutcome.cancelled:
          return AddFriendOutcome.googleUpgradeCancelled;
        case GoogleUpgradeOutcome.alreadyLinked:
          return AddFriendOutcome.googleUpgradeAlreadyLinked;
        case GoogleUpgradeOutcome.success:
          break;
      }
    }

    final myUid = ref.read(currentUidProvider);
    if (myUid == null) return AddFriendOutcome.notSignedIn;

    final targetUid = await ref
        .read(userProfileRepositoryProvider)
        .resolveUidForNickname(nickname);
    if (targetUid == null) return AddFriendOutcome.nicknameNotFound;
    if (targetUid == myUid) return AddFriendOutcome.cannotAddSelf;

    final existing = ref.read(friendshipsProvider).value ?? const [];
    if (existing.any((f) => f.uids.contains(targetUid))) {
      return AddFriendOutcome.alreadyExists;
    }

    await ref
        .read(friendshipRepositoryProvider)
        .sendRequest(fromUid: myUid, toUid: targetUid);
    return AddFriendOutcome.sent;
  }

  Future<void> acceptRequest(String pairId) =>
      ref.read(friendshipRepositoryProvider).acceptRequest(pairId);

  /// Removes a friend, declines an incoming request, or cancels an
  /// outgoing one — all the same reversible delete (§6.4).
  Future<void> removeOrDecline(String pairId) =>
      ref.read(friendshipRepositoryProvider).removeOrDecline(pairId);

  /// Hides (or unhides) the signed-in user's own progress from the other
  /// side of [pairId] (§7). A no-op if somehow called before a uid exists.
  Future<void> setHidden(String pairId, {required bool hidden}) {
    final myUid = ref.read(currentUidProvider);
    if (myUid == null) return Future<void>.value();
    return ref
        .read(friendshipRepositoryProvider)
        .setHidden(pairId, ownerUid: myUid, hidden: hidden);
  }

  /// Renames the signed-in user's own nickname (§6.5's Settings editor).
  /// [UserProfileRepository.updateNickname] does the actual work — atomic
  /// release-old/claim-new against the `usernames/{nicknameLower}` registry
  /// (§8), so two people can never end up holding the same nickname.
  /// [myProfileProvider] picks up the rename on its own once it lands
  /// (a live Firestore stream), no manual refresh needed here.
  Future<UpdateNicknameOutcome> updateNickname(String newNickname) async {
    final myUid = ref.read(currentUidProvider);
    if (myUid == null) return UpdateNicknameOutcome.notSignedIn;

    try {
      await ref
          .read(userProfileRepositoryProvider)
          .updateNickname(myUid, newNickname);
    } on NicknameTakenException {
      return UpdateNicknameOutcome.nicknameTaken;
    }
    return UpdateNicknameOutcome.success;
  }
}
