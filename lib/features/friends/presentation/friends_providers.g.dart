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

/// Whether the Друзья tab (§6.4) is unlocked yet — this task's requirement:
/// the tab stays inactive until the user has (1) logged in via Настройки
/// (§8's Google upgrade — a permanent, non-anonymous identity, not just the
/// silent anonymous session every install starts with) and (2) has a
/// nickname to actually be found by (§6.5) — which, since login itself
/// resolves one automatically (`AuthController
/// ._applyDefaultNicknameFromGoogleEmail`, retried past a taken name with a
/// numeric suffix), in practice becomes true moments after login rather
/// than needing its own separate manual step.
///
/// A `myProfile` still loading (or in an error state) reads as locked too
/// — `.value` is `null` for both `AsyncLoading`/`AsyncError`, so there is
/// nothing to distinguish here: either way, there is not yet a nickname to
/// unlock with.

@ProviderFor(friendsUnlocked)
final friendsUnlockedProvider = FriendsUnlockedProvider._();

/// Whether the Друзья tab (§6.4) is unlocked yet — this task's requirement:
/// the tab stays inactive until the user has (1) logged in via Настройки
/// (§8's Google upgrade — a permanent, non-anonymous identity, not just the
/// silent anonymous session every install starts with) and (2) has a
/// nickname to actually be found by (§6.5) — which, since login itself
/// resolves one automatically (`AuthController
/// ._applyDefaultNicknameFromGoogleEmail`, retried past a taken name with a
/// numeric suffix), in practice becomes true moments after login rather
/// than needing its own separate manual step.
///
/// A `myProfile` still loading (or in an error state) reads as locked too
/// — `.value` is `null` for both `AsyncLoading`/`AsyncError`, so there is
/// nothing to distinguish here: either way, there is not yet a nickname to
/// unlock with.

final class FriendsUnlockedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the Друзья tab (§6.4) is unlocked yet — this task's requirement:
  /// the tab stays inactive until the user has (1) logged in via Настройки
  /// (§8's Google upgrade — a permanent, non-anonymous identity, not just the
  /// silent anonymous session every install starts with) and (2) has a
  /// nickname to actually be found by (§6.5) — which, since login itself
  /// resolves one automatically (`AuthController
  /// ._applyDefaultNicknameFromGoogleEmail`, retried past a taken name with a
  /// numeric suffix), in practice becomes true moments after login rather
  /// than needing its own separate manual step.
  ///
  /// A `myProfile` still loading (or in an error state) reads as locked too
  /// — `.value` is `null` for both `AsyncLoading`/`AsyncError`, so there is
  /// nothing to distinguish here: either way, there is not yet a nickname to
  /// unlock with.
  FriendsUnlockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsUnlockedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendsUnlockedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return friendsUnlocked(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$friendsUnlockedHash() => r'ad3f04cb111c1198c629860c7c2d9b874f5f0358';

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
    r'2b01d20e99031f42a25101f5e9ac8917159d43f9';

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

String _$friendsViewHash() => r'41a1882b2251013508d179c8ee7416e305ebd9fa';

/// Imperative actions for the Challengers tab (§6.4) and the Settings
/// nickname editor (§6.5): sending a request by nickname (triggering the
/// Google upgrade first if still anonymous), accepting, removing/declining,
/// the per-friend hide toggle (§7), and renaming the signed-in user's own
/// nickname.
///
/// `keepAlive: true`, not the `@riverpod` default — every call site reaches
/// this only via `ref.read(friendsControllerProvider.notifier)`, never
/// `ref.watch`, so nothing ever keeps a listener on it. An autoDispose
/// provider with zero listeners can be torn down while one of its own
/// methods is still mid-`await` (bug found running this file's own test
/// suite: `addFriendByNickname` crashed with "Cannot use the Ref... after
/// it has been disposed" between its `resolveUidForNickname` and
/// `sendRequest` awaits) — same reason `lock_screen_controller.dart`'s main
/// controller is `keepAlive: true` rather than relying on a watcher that
/// may not exist.

@ProviderFor(FriendsController)
final friendsControllerProvider = FriendsControllerProvider._();

/// Imperative actions for the Challengers tab (§6.4) and the Settings
/// nickname editor (§6.5): sending a request by nickname (triggering the
/// Google upgrade first if still anonymous), accepting, removing/declining,
/// the per-friend hide toggle (§7), and renaming the signed-in user's own
/// nickname.
///
/// `keepAlive: true`, not the `@riverpod` default — every call site reaches
/// this only via `ref.read(friendsControllerProvider.notifier)`, never
/// `ref.watch`, so nothing ever keeps a listener on it. An autoDispose
/// provider with zero listeners can be torn down while one of its own
/// methods is still mid-`await` (bug found running this file's own test
/// suite: `addFriendByNickname` crashed with "Cannot use the Ref... after
/// it has been disposed" between its `resolveUidForNickname` and
/// `sendRequest` awaits) — same reason `lock_screen_controller.dart`'s main
/// controller is `keepAlive: true` rather than relying on a watcher that
/// may not exist.
final class FriendsControllerProvider
    extends $NotifierProvider<FriendsController, void> {
  /// Imperative actions for the Challengers tab (§6.4) and the Settings
  /// nickname editor (§6.5): sending a request by nickname (triggering the
  /// Google upgrade first if still anonymous), accepting, removing/declining,
  /// the per-friend hide toggle (§7), and renaming the signed-in user's own
  /// nickname.
  ///
  /// `keepAlive: true`, not the `@riverpod` default — every call site reaches
  /// this only via `ref.read(friendsControllerProvider.notifier)`, never
  /// `ref.watch`, so nothing ever keeps a listener on it. An autoDispose
  /// provider with zero listeners can be torn down while one of its own
  /// methods is still mid-`await` (bug found running this file's own test
  /// suite: `addFriendByNickname` crashed with "Cannot use the Ref... after
  /// it has been disposed" between its `resolveUidForNickname` and
  /// `sendRequest` awaits) — same reason `lock_screen_controller.dart`'s main
  /// controller is `keepAlive: true` rather than relying on a watcher that
  /// may not exist.
  FriendsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsControllerProvider',
        isAutoDispose: false,
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

String _$friendsControllerHash() => r'6fb253b83ae788525ca960f3a8943fcab8376fab';

/// Imperative actions for the Challengers tab (§6.4) and the Settings
/// nickname editor (§6.5): sending a request by nickname (triggering the
/// Google upgrade first if still anonymous), accepting, removing/declining,
/// the per-friend hide toggle (§7), and renaming the signed-in user's own
/// nickname.
///
/// `keepAlive: true`, not the `@riverpod` default — every call site reaches
/// this only via `ref.read(friendsControllerProvider.notifier)`, never
/// `ref.watch`, so nothing ever keeps a listener on it. An autoDispose
/// provider with zero listeners can be torn down while one of its own
/// methods is still mid-`await` (bug found running this file's own test
/// suite: `addFriendByNickname` crashed with "Cannot use the Ref... after
/// it has been disposed" between its `resolveUidForNickname` and
/// `sendRequest` awaits) — same reason `lock_screen_controller.dart`'s main
/// controller is `keepAlive: true` rather than relying on a watcher that
/// may not exist.

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

/// Settings-page preference (§6.5, user request): whether accepted friends'
/// positions render on the Путь and Карта tabs — a colored figure with
/// their nickname on Путь (`journey_path_view.dart`'s `_FriendMarker`/
/// `_FriendNicknameLabel`), a colored helmet on Карта
/// (`quest_map_view.dart`'s `_RouteOverlayPainter`; the nickname *there* is
/// a separate map-local legend toggle, not this preference — see that
/// file's `_legendVisible`). Off by default — nothing about rendering a
/// friend's already-shared progress needs a permission (§7), but every
/// display preference added since the lock-screen toggle (background
/// music, the theme override) starts off, and this follows the same
/// convention rather than surprising the user with friends suddenly
/// appearing on a screen they haven't asked for.
///
/// Durable since §14 ("сохраняй настройки пользователя..."), like
/// `AppThemeOverride`/`AppLocale`/`BackgroundMusicController`: [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses, and
/// [setEnabled] writes through `UserPreferenceRepository` on every change.
///
/// `keepAlive: true` — found the hard way (a widget test caught it, real
/// bug, not just a test artifact): plain `@riverpod`'s default autoDispose
/// tears this element down the instant its listener count reads zero, and
/// [setEnabled] is called via `ref.read(...).notifier` from a widget event
/// handler — a *read*, not a *watch* — so it doesn't itself count as a
/// listener. The window between that call finishing and the watching
/// widget's *next* build re-establishing its own `ref.watch` subscription
/// was long enough for the disposal check to fire, discard the just-set
/// `true`, and hand the next build a freshly rebuilt provider back at its
/// `false` default — the toggle would flip on then silently flip itself
/// back off. Same shape `LockScreenController`/`FriendsController`/
/// `BackgroundMusicController` already avoid this way, for the same reason.

@ProviderFor(ShowFriendsOnMap)
final showFriendsOnMapProvider = ShowFriendsOnMapProvider._();

/// Settings-page preference (§6.5, user request): whether accepted friends'
/// positions render on the Путь and Карта tabs — a colored figure with
/// their nickname on Путь (`journey_path_view.dart`'s `_FriendMarker`/
/// `_FriendNicknameLabel`), a colored helmet on Карта
/// (`quest_map_view.dart`'s `_RouteOverlayPainter`; the nickname *there* is
/// a separate map-local legend toggle, not this preference — see that
/// file's `_legendVisible`). Off by default — nothing about rendering a
/// friend's already-shared progress needs a permission (§7), but every
/// display preference added since the lock-screen toggle (background
/// music, the theme override) starts off, and this follows the same
/// convention rather than surprising the user with friends suddenly
/// appearing on a screen they haven't asked for.
///
/// Durable since §14 ("сохраняй настройки пользователя..."), like
/// `AppThemeOverride`/`AppLocale`/`BackgroundMusicController`: [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses, and
/// [setEnabled] writes through `UserPreferenceRepository` on every change.
///
/// `keepAlive: true` — found the hard way (a widget test caught it, real
/// bug, not just a test artifact): plain `@riverpod`'s default autoDispose
/// tears this element down the instant its listener count reads zero, and
/// [setEnabled] is called via `ref.read(...).notifier` from a widget event
/// handler — a *read*, not a *watch* — so it doesn't itself count as a
/// listener. The window between that call finishing and the watching
/// widget's *next* build re-establishing its own `ref.watch` subscription
/// was long enough for the disposal check to fire, discard the just-set
/// `true`, and hand the next build a freshly rebuilt provider back at its
/// `false` default — the toggle would flip on then silently flip itself
/// back off. Same shape `LockScreenController`/`FriendsController`/
/// `BackgroundMusicController` already avoid this way, for the same reason.
final class ShowFriendsOnMapProvider
    extends $NotifierProvider<ShowFriendsOnMap, bool> {
  /// Settings-page preference (§6.5, user request): whether accepted friends'
  /// positions render on the Путь and Карта tabs — a colored figure with
  /// their nickname on Путь (`journey_path_view.dart`'s `_FriendMarker`/
  /// `_FriendNicknameLabel`), a colored helmet on Карта
  /// (`quest_map_view.dart`'s `_RouteOverlayPainter`; the nickname *there* is
  /// a separate map-local legend toggle, not this preference — see that
  /// file's `_legendVisible`). Off by default — nothing about rendering a
  /// friend's already-shared progress needs a permission (§7), but every
  /// display preference added since the lock-screen toggle (background
  /// music, the theme override) starts off, and this follows the same
  /// convention rather than surprising the user with friends suddenly
  /// appearing on a screen they haven't asked for.
  ///
  /// Durable since §14 ("сохраняй настройки пользователя..."), like
  /// `AppThemeOverride`/`AppLocale`/`BackgroundMusicController`: [build] fires
  /// the same "async check from a sync build()" idiom
  /// `journey_providers.dart`'s `SelectedJourney.build()` uses, and
  /// [setEnabled] writes through `UserPreferenceRepository` on every change.
  ///
  /// `keepAlive: true` — found the hard way (a widget test caught it, real
  /// bug, not just a test artifact): plain `@riverpod`'s default autoDispose
  /// tears this element down the instant its listener count reads zero, and
  /// [setEnabled] is called via `ref.read(...).notifier` from a widget event
  /// handler — a *read*, not a *watch* — so it doesn't itself count as a
  /// listener. The window between that call finishing and the watching
  /// widget's *next* build re-establishing its own `ref.watch` subscription
  /// was long enough for the disposal check to fire, discard the just-set
  /// `true`, and hand the next build a freshly rebuilt provider back at its
  /// `false` default — the toggle would flip on then silently flip itself
  /// back off. Same shape `LockScreenController`/`FriendsController`/
  /// `BackgroundMusicController` already avoid this way, for the same reason.
  ShowFriendsOnMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showFriendsOnMapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showFriendsOnMapHash();

  @$internal
  @override
  ShowFriendsOnMap create() => ShowFriendsOnMap();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showFriendsOnMapHash() => r'4ae81ff033bf43b077203b89e0cc968059f0be49';

/// Settings-page preference (§6.5, user request): whether accepted friends'
/// positions render on the Путь and Карта tabs — a colored figure with
/// their nickname on Путь (`journey_path_view.dart`'s `_FriendMarker`/
/// `_FriendNicknameLabel`), a colored helmet on Карта
/// (`quest_map_view.dart`'s `_RouteOverlayPainter`; the nickname *there* is
/// a separate map-local legend toggle, not this preference — see that
/// file's `_legendVisible`). Off by default — nothing about rendering a
/// friend's already-shared progress needs a permission (§7), but every
/// display preference added since the lock-screen toggle (background
/// music, the theme override) starts off, and this follows the same
/// convention rather than surprising the user with friends suddenly
/// appearing on a screen they haven't asked for.
///
/// Durable since §14 ("сохраняй настройки пользователя..."), like
/// `AppThemeOverride`/`AppLocale`/`BackgroundMusicController`: [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses, and
/// [setEnabled] writes through `UserPreferenceRepository` on every change.
///
/// `keepAlive: true` — found the hard way (a widget test caught it, real
/// bug, not just a test artifact): plain `@riverpod`'s default autoDispose
/// tears this element down the instant its listener count reads zero, and
/// [setEnabled] is called via `ref.read(...).notifier` from a widget event
/// handler — a *read*, not a *watch* — so it doesn't itself count as a
/// listener. The window between that call finishing and the watching
/// widget's *next* build re-establishing its own `ref.watch` subscription
/// was long enough for the disposal check to fire, discard the just-set
/// `true`, and hand the next build a freshly rebuilt provider back at its
/// `false` default — the toggle would flip on then silently flip itself
/// back off. Same shape `LockScreenController`/`FriendsController`/
/// `BackgroundMusicController` already avoid this way, for the same reason.

abstract class _$ShowFriendsOnMap extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
