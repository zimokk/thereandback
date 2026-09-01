// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preference_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The drift-backed store for the Настройки toggles that persist across a
/// restart (§6.5, §14 — language, theme pin, background music, friends on
/// map): `app/` is the DI root (§4), and this repository is shared by four
/// different features' providers (`profile/`, `audio/`, `friends/`) rather
/// than owned by any one of them — same reasoning `database_provider.dart`
/// itself already documents for `appDatabaseProvider`. Overridden with an
/// in-memory `AppDatabase` in tests via `appDatabaseProvider` (`testing`
/// skill: never a real drift database in a test).

@ProviderFor(userPreferenceRepository)
final userPreferenceRepositoryProvider =
    UserPreferenceRepositoryProvider._();

/// The drift-backed store for the Настройки toggles that persist across a
/// restart (§6.5, §14 — language, theme pin, background music, friends on
/// map): `app/` is the DI root (§4), and this repository is shared by four
/// different features' providers (`profile/`, `audio/`, `friends/`) rather
/// than owned by any one of them — same reasoning `database_provider.dart`
/// itself already documents for `appDatabaseProvider`. Overridden with an
/// in-memory `AppDatabase` in tests via `appDatabaseProvider` (`testing`
/// skill: never a real drift database in a test).

final class UserPreferenceRepositoryProvider
    extends
        $FunctionalProvider<
          UserPreferenceRepository,
          UserPreferenceRepository,
          UserPreferenceRepository
        >
    with $Provider<UserPreferenceRepository> {
  /// The drift-backed store for the Настройки toggles that persist across a
  /// restart (§6.5, §14 — language, theme pin, background music, friends on
  /// map): `app/` is the DI root (§4), and this repository is shared by four
  /// different features' providers (`profile/`, `audio/`, `friends/`) rather
  /// than owned by any one of them — same reasoning `database_provider.dart`
  /// itself already documents for `appDatabaseProvider`. Overridden with an
  /// in-memory `AppDatabase` in tests via `appDatabaseProvider` (`testing`
  /// skill: never a real drift database in a test).
  UserPreferenceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userPreferenceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userPreferenceRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserPreferenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserPreferenceRepository create(Ref ref) {
    return userPreferenceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserPreferenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserPreferenceRepository>(value),
    );
  }
}

String _$userPreferenceRepositoryHash() =>
    r'1534a5489acd0ea71a614d43569ba1f0af3f3465';
