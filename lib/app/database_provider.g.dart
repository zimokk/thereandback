// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app-wide drift database (CLAUDE.md §4: `app/` is the DI root; §8:
/// drift is the offline-first source of truth). Every feature repository
/// depends on this instead of constructing its own [AppDatabase], so a
/// single override replaces the whole local storage layer with an
/// in-memory instance in tests (`testing` skill: never a real drift
/// database in a test).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The app-wide drift database (CLAUDE.md §4: `app/` is the DI root; §8:
/// drift is the offline-first source of truth). Every feature repository
/// depends on this instead of constructing its own [AppDatabase], so a
/// single override replaces the whole local storage layer with an
/// in-memory instance in tests (`testing` skill: never a real drift
/// database in a test).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The app-wide drift database (CLAUDE.md §4: `app/` is the DI root; §8:
  /// drift is the offline-first source of truth). Every feature repository
  /// depends on this instead of constructing its own [AppDatabase], so a
  /// single override replaces the whole local storage layer with an
  /// in-memory instance in tests (`testing` skill: never a real drift
  /// database in a test).
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';
