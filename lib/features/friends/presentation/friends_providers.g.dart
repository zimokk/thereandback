// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friends_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's own `users/{uid}` profile — `null` before it's been
/// created (see [ensureFriendProfile]) or before [currentUidProvider]
/// resolves a uid.

@ProviderFor(myProfile)
final myProfileProvider = MyProfileProvider._();

/// The signed-in user's own `users/{uid}` profile — `null` before it's been
/// created (see [ensureFriendProfile]) or before [currentUidProvider]
/// resolves a uid.

final class MyProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<FriendProfile?>,
          FriendProfile?,
          Stream<FriendProfile?>
        >
    with $FutureModifier<FriendProfile?>, $StreamProvider<FriendProfile?> {
  /// The signed-in user's own `users/{uid}` profile — `null` before it's been
  /// created (see [ensureFriendProfile]) or before [currentUidProvider]
  /// resolves a uid.
  MyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileHash();

  @$internal
  @override
  $StreamProviderElement<FriendProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<FriendProfile?> create(Ref ref) {
    return myProfile(ref);
  }
}

String _$myProfileHash() => r'e8fd9f30186e79ad20248a9fdb20b374e5542c92';

/// Creates a starter `users/{uid}` profile (default nickname + a fixed
/// preset avatar) the first time a uid is available — every user needs one
/// before "add friend by nickname" can find or be found by them. A no-op
/// once a profile already exists ([UserProfileRepository
/// .createInitialProfileIfAbsent]), and a collision on the generated
/// starter nickname (vanishingly unlikely — it embeds the uid) is swallowed
/// rather than surfaced, matching the rest of this feature's
/// fire-and-forget bootstrapping.

@ProviderFor(ensureFriendProfile)
final ensureFriendProfileProvider = EnsureFriendProfileProvider._();

/// Creates a starter `users/{uid}` profile (default nickname + a fixed
/// preset avatar) the first time a uid is available — every user needs one
/// before "add friend by nickname" can find or be found by them. A no-op
/// once a profile already exists ([UserProfileRepository
/// .createInitialProfileIfAbsent]), and a collision on the generated
/// starter nickname (vanishingly unlikely — it embeds the uid) is swallowed
/// rather than surfaced, matching the rest of this feature's
/// fire-and-forget bootstrapping.

final class EnsureFriendProfileProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Creates a starter `users/{uid}` profile (default nickname + a fixed
  /// preset avatar) the first time a uid is available — every user needs one
  /// before "add friend by nickname" can find or be found by them. A no-op
  /// once a profile already exists ([UserProfileRepository
  /// .createInitialProfileIfAbsent]), and a collision on the generated
  /// starter nickname (vanishingly unlikely — it embeds the uid) is swallowed
  /// rather than surfaced, matching the rest of this feature's
  /// fire-and-forget bootstrapping.
  EnsureFriendProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ensureFriendProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ensureFriendProfileHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return ensureFriendProfile(ref);
  }
}

String _$ensureFriendProfileHash() =>
    r'2049b340fbd3c61ad639a187d43ee08bc09a2508';

/// Every friendship (pending or accepted, either direction) involving the
/// signed-in user — a live Firestore stream, so an incoming accept or a
/// friend's own action is reflected without a manual refresh.

@ProviderFor(friendships)
final friendshipsProvider = FriendshipsProvider._();

/// Every friendship (pending or accepted, either direction) involving the
/// signed-in user — a live Firestore stream, so an incoming accept or a
/// friend's own action is reflected without a manual refresh.

final class FriendshipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Friendship>>,
          List<Friendship>,
          Stream<List<Friendship>>
        >
    with $FutureModifier<List<Friendship>>, $StreamProvider<List<Friendship>> {
  /// Every friendship (pending or accepted, either direction) involving the
  /// signed-in user — a live Firestore stream, so an incoming accept or a
  /// friend's own action is reflected without a manual refresh.
  FriendshipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendshipsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendshipsHash();

  @$internal
  @override
  $StreamProviderElement<List<Friendship>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Friendship>> create(Ref ref) {
    return friendships(ref);
  }
}

String _$friendshipsHash() => r'8f37c5b06e9dc73b977216cdc3b1f854965399d0';

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

@ProviderFor(friendsView)
final friendsViewProvider = FriendsViewProvider._();

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

final class FriendsViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<FriendsViewData>,
          FriendsViewData,
          FutureOr<FriendsViewData>
        >
    with $FutureModifier<FriendsViewData>, $FutureProvider<FriendsViewData> {
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
  FriendsViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendsViewHash();

  @$internal
  @override
  $FutureProviderElement<FriendsViewData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FriendsViewData> create(Ref ref) {
    return friendsView(ref);
  }
}

String _$friendsViewHash() => r'e06b794e97ebdfea433ba8a1332dbe64fba69954';

/// Imperative actions for the Challengers tab (§6.4): sending a request by
/// nickname (triggering the Google upgrade first if still anonymous),
/// accepting, removing/declining, and the per-friend hide toggle (§7).

@ProviderFor(FriendsController)
final friendsControllerProvider = FriendsControllerProvider._();

/// Imperative actions for the Challengers tab (§6.4): sending a request by
/// nickname (triggering the Google upgrade first if still anonymous),
/// accepting, removing/declining, and the per-friend hide toggle (§7).
final class FriendsControllerProvider
    extends $NotifierProvider<FriendsController, void> {
  /// Imperative actions for the Challengers tab (§6.4): sending a request by
  /// nickname (triggering the Google upgrade first if still anonymous),
  /// accepting, removing/declining, and the per-friend hide toggle (§7).
  FriendsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendsControllerHash();

  @$internal
  @override
  FriendsController create() => FriendsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$friendsControllerHash() => r'3a8bd89c8860923215bb9f1979489b9e466ebc23';

/// Imperative actions for the Challengers tab (§6.4): sending a request by
/// nickname (triggering the Google upgrade first if still anonymous),
/// accepting, removing/declining, and the per-friend hide toggle (§7).

abstract class _$FriendsController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
