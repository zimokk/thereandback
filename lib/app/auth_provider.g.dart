// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Firebase Auth repository (§8) — swappable in tests via mocktail
/// (`testing` skill), same interface+impl pattern as
/// `features/steps/data/step_sample_repository.dart`.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// The Firebase Auth repository (§8) — swappable in tests via mocktail
/// (`testing` skill), same interface+impl pattern as
/// `features/steps/data/step_sample_repository.dart`.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// The Firebase Auth repository (§8) — swappable in tests via mocktail
  /// (`testing` skill), same interface+impl pattern as
  /// `features/steps/data/step_sample_repository.dart`.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'59cd170a1a734819a50e935a4986b72225fdc494';

/// Interactive Google sign-in (§8's upgrade path) — swappable in tests.

@ProviderFor(googleAuthService)
final googleAuthServiceProvider = GoogleAuthServiceProvider._();

/// Interactive Google sign-in (§8's upgrade path) — swappable in tests.

final class GoogleAuthServiceProvider
    extends
        $FunctionalProvider<
          GoogleAuthService,
          GoogleAuthService,
          GoogleAuthService
        >
    with $Provider<GoogleAuthService> {
  /// Interactive Google sign-in (§8's upgrade path) — swappable in tests.
  GoogleAuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleAuthServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleAuthServiceHash();

  @$internal
  @override
  $ProviderElement<GoogleAuthService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GoogleAuthService create(Ref ref) {
    return googleAuthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleAuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleAuthService>(value),
    );
  }
}

String _$googleAuthServiceHash() => r'b7b4f41be20d8ecc59467c6cf34091466074e2e2';

/// Bootstraps and owns the current Firebase Auth session (§8): silent
/// anonymous sign-in on first read, and the interactive Google upgrade
/// triggered when the user goes to add a friend (§8, §14).

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Bootstraps and owns the current Firebase Auth session (§8): silent
/// anonymous sign-in on first read, and the interactive Google upgrade
/// triggered when the user goes to add a friend (§8, §14).
final class AuthControllerProvider
    extends $NotifierProvider<AuthController, AuthState> {
  /// Bootstraps and owns the current Firebase Auth session (§8): silent
  /// anonymous sign-in on first read, and the interactive Google upgrade
  /// triggered when the user goes to add a friend (§8, §14).
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authControllerHash() => r'592f6e7ba97f47fcbd5d9e9c1830cdbf2549cdb7';

/// Bootstraps and owns the current Firebase Auth session (§8): silent
/// anonymous sign-in on first read, and the interactive Google upgrade
/// triggered when the user goes to add a friend (§8, §14).

abstract class _$AuthController extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The current uid, or `null` before [AuthController] has resolved one.

@ProviderFor(currentUid)
final currentUidProvider = CurrentUidProvider._();

/// The current uid, or `null` before [AuthController] has resolved one.

final class CurrentUidProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The current uid, or `null` before [AuthController] has resolved one.
  CurrentUidProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUidProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUidHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentUid(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUidHash() => r'eae42bb52b935a2767bfa905684d3104dd52ba91';
