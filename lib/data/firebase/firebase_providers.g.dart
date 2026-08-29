// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Firebase Auth instance (§8). Overridden in tests with
/// `firebase_auth_mocks`' `MockFirebaseAuth` (`testing` skill: never the
/// real Firebase SDK in a test) — same `keepAlive` shape as
/// `app/database_provider.dart`'s `appDatabaseProvider`.

@ProviderFor(firebaseAuth)
final firebaseAuthProvider = FirebaseAuthProvider._();

/// The Firebase Auth instance (§8). Overridden in tests with
/// `firebase_auth_mocks`' `MockFirebaseAuth` (`testing` skill: never the
/// real Firebase SDK in a test) — same `keepAlive` shape as
/// `app/database_provider.dart`'s `appDatabaseProvider`.

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  /// The Firebase Auth instance (§8). Overridden in tests with
  /// `firebase_auth_mocks`' `MockFirebaseAuth` (`testing` skill: never the
  /// real Firebase SDK in a test) — same `keepAlive` shape as
  /// `app/database_provider.dart`'s `appDatabaseProvider`.
  FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'8c3e9d11b27110ca96130356b5ef4d5d34a5ffc2';

/// The Firestore instance — a sync layer, never the source of truth (drift
/// on-device is, §8). Overridden in tests with `fake_cloud_firestore`.

@ProviderFor(firestore)
final firestoreProvider = FirestoreProvider._();

/// The Firestore instance — a sync layer, never the source of truth (drift
/// on-device is, §8). Overridden in tests with `fake_cloud_firestore`.

final class FirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  /// The Firestore instance — a sync layer, never the source of truth (drift
  /// on-device is, §8). Overridden in tests with `fake_cloud_firestore`.
  FirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firestoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firestoreHash() => r'864285def6284159b44f9598dcde96347e0c1dce';
