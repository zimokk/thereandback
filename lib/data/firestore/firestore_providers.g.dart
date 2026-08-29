// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The three Firestore-backed repositories Phase 8 needs (§8), collected
/// here rather than under `features/friends/` or `features/steps/` since
/// both features consume [progressSyncRepositoryProvider] — one canonical
/// provider per data source, same `@riverpod` shape as
/// `app/database_provider.dart`.

@ProviderFor(friendshipRepository)
final friendshipRepositoryProvider = FriendshipRepositoryProvider._();

/// The three Firestore-backed repositories Phase 8 needs (§8), collected
/// here rather than under `features/friends/` or `features/steps/` since
/// both features consume [progressSyncRepositoryProvider] — one canonical
/// provider per data source, same `@riverpod` shape as
/// `app/database_provider.dart`.

final class FriendshipRepositoryProvider
    extends
        $FunctionalProvider<
          FriendshipRepository,
          FriendshipRepository,
          FriendshipRepository
        >
    with $Provider<FriendshipRepository> {
  /// The three Firestore-backed repositories Phase 8 needs (§8), collected
  /// here rather than under `features/friends/` or `features/steps/` since
  /// both features consume [progressSyncRepositoryProvider] — one canonical
  /// provider per data source, same `@riverpod` shape as
  /// `app/database_provider.dart`.
  FriendshipRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendshipRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendshipRepositoryHash();

  @$internal
  @override
  $ProviderElement<FriendshipRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FriendshipRepository create(Ref ref) {
    return friendshipRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FriendshipRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FriendshipRepository>(value),
    );
  }
}

String _$friendshipRepositoryHash() =>
    r'01c5d2d1ec4b17580d10b92db731303a9e2e50a5';

@ProviderFor(userProfileRepository)
final userProfileRepositoryProvider = UserProfileRepositoryProvider._();

final class UserProfileRepositoryProvider
    extends
        $FunctionalProvider<
          UserProfileRepository,
          UserProfileRepository,
          UserProfileRepository
        >
    with $Provider<UserProfileRepository> {
  UserProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserProfileRepository create(Ref ref) {
    return userProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileRepository>(value),
    );
  }
}

String _$userProfileRepositoryHash() =>
    r'7dc5cdc5f37fe7b38ab086579a61166b7902d1a4';

/// Pushes progress to `users/{uid}/progress/{journeyId}` after a
/// foreground sync (`features/steps/presentation/steps_providers.dart`'s
/// `StepsSync.sync()`) and reads a friend's progress
/// (`features/friends/presentation/friends_providers.dart`) — a sync layer
/// only, never the source of truth (drift is, §8).

@ProviderFor(progressSyncRepository)
final progressSyncRepositoryProvider = ProgressSyncRepositoryProvider._();

/// Pushes progress to `users/{uid}/progress/{journeyId}` after a
/// foreground sync (`features/steps/presentation/steps_providers.dart`'s
/// `StepsSync.sync()`) and reads a friend's progress
/// (`features/friends/presentation/friends_providers.dart`) — a sync layer
/// only, never the source of truth (drift is, §8).

final class ProgressSyncRepositoryProvider
    extends
        $FunctionalProvider<
          ProgressSyncRepository,
          ProgressSyncRepository,
          ProgressSyncRepository
        >
    with $Provider<ProgressSyncRepository> {
  /// Pushes progress to `users/{uid}/progress/{journeyId}` after a
  /// foreground sync (`features/steps/presentation/steps_providers.dart`'s
  /// `StepsSync.sync()`) and reads a friend's progress
  /// (`features/friends/presentation/friends_providers.dart`) — a sync layer
  /// only, never the source of truth (drift is, §8).
  ProgressSyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressSyncRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressSyncRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgressSyncRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgressSyncRepository create(Ref ref) {
    return progressSyncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressSyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressSyncRepository>(value),
    );
  }
}

String _$progressSyncRepositoryHash() =>
    r'd7e008a1ac6ffd424df9b053d326a6564b3f5512';
