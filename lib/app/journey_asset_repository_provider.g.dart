// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_asset_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The drift-backed local record of which quest content-version is
/// downloaded (§8, §14). `app/` is the DI root (§4) — same reasoning
/// `user_preference_repository_provider.dart` already documents for a
/// repository more than one feature might eventually read (today: only
/// `features/journey/`, but a per-quest theme track — the one already
/// planned in the manifest shape — is `features/audio/`'s concern too).

@ProviderFor(journeyAssetCacheRepository)
final journeyAssetCacheRepositoryProvider =
    JourneyAssetCacheRepositoryProvider._();

/// The drift-backed local record of which quest content-version is
/// downloaded (§8, §14). `app/` is the DI root (§4) — same reasoning
/// `user_preference_repository_provider.dart` already documents for a
/// repository more than one feature might eventually read (today: only
/// `features/journey/`, but a per-quest theme track — the one already
/// planned in the manifest shape — is `features/audio/`'s concern too).

final class JourneyAssetCacheRepositoryProvider
    extends
        $FunctionalProvider<
          JourneyAssetCacheRepository,
          JourneyAssetCacheRepository,
          JourneyAssetCacheRepository
        >
    with $Provider<JourneyAssetCacheRepository> {
  /// The drift-backed local record of which quest content-version is
  /// downloaded (§8, §14). `app/` is the DI root (§4) — same reasoning
  /// `user_preference_repository_provider.dart` already documents for a
  /// repository more than one feature might eventually read (today: only
  /// `features/journey/`, but a per-quest theme track — the one already
  /// planned in the manifest shape — is `features/audio/`'s concern too).
  JourneyAssetCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyAssetCacheRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyAssetCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<JourneyAssetCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JourneyAssetCacheRepository create(Ref ref) {
    return journeyAssetCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyAssetCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyAssetCacheRepository>(value),
    );
  }
}

String _$journeyAssetCacheRepositoryHash() =>
    r'de0a6bf3542e96b244d2b6250d77317a0b46e0ba';

/// The Firebase Storage-backed download for a quest's not-bundled content.
/// Overridden with `firebase_storage_mocks` in tests (`testing` skill).

@ProviderFor(journeyStorageRepository)
final journeyStorageRepositoryProvider = JourneyStorageRepositoryProvider._();

/// The Firebase Storage-backed download for a quest's not-bundled content.
/// Overridden with `firebase_storage_mocks` in tests (`testing` skill).

final class JourneyStorageRepositoryProvider
    extends
        $FunctionalProvider<
          JourneyStorageRepository,
          JourneyStorageRepository,
          JourneyStorageRepository
        >
    with $Provider<JourneyStorageRepository> {
  /// The Firebase Storage-backed download for a quest's not-bundled content.
  /// Overridden with `firebase_storage_mocks` in tests (`testing` skill).
  JourneyStorageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyStorageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyStorageRepositoryHash();

  @$internal
  @override
  $ProviderElement<JourneyStorageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JourneyStorageRepository create(Ref ref) {
    return journeyStorageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyStorageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyStorageRepository>(value),
    );
  }
}

String _$journeyStorageRepositoryHash() =>
    r'd6f353df7e4fac4609f9bdcb561e440ac378213f';

/// Orchestrates the two repositories above (§8, §14) — one instance for the
/// whole app session, so an in-flight download survives whatever widget
/// happened to trigger it being rebuilt or disposed.

@ProviderFor(journeyAssetRepository)
final journeyAssetRepositoryProvider = JourneyAssetRepositoryProvider._();

/// Orchestrates the two repositories above (§8, §14) — one instance for the
/// whole app session, so an in-flight download survives whatever widget
/// happened to trigger it being rebuilt or disposed.

final class JourneyAssetRepositoryProvider
    extends
        $FunctionalProvider<
          JourneyAssetRepository,
          JourneyAssetRepository,
          JourneyAssetRepository
        >
    with $Provider<JourneyAssetRepository> {
  /// Orchestrates the two repositories above (§8, §14) — one instance for the
  /// whole app session, so an in-flight download survives whatever widget
  /// happened to trigger it being rebuilt or disposed.
  JourneyAssetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyAssetRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyAssetRepositoryHash();

  @$internal
  @override
  $ProviderElement<JourneyAssetRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JourneyAssetRepository create(Ref ref) {
    return journeyAssetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyAssetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyAssetRepository>(value),
    );
  }
}

String _$journeyAssetRepositoryHash() =>
    r'73b024723f88ffc8f536c519ad80be11b66ba7ee';
