import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/firebase/auth_repository.dart';
import '../data/firebase/firebase_providers.dart';
import '../data/firebase/google_sign_in_service.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

/// The Firebase Auth repository (§8) — swappable in tests via mocktail
/// (`testing` skill), same interface+impl pattern as
/// `features/steps/data/step_sample_repository.dart`.
@riverpod
AuthRepository authRepository(Ref ref) =>
    FirebaseAuthRepository(ref.watch(firebaseAuthProvider));

/// Interactive Google sign-in (§8's upgrade path) — swappable in tests.
@riverpod
GoogleAuthService googleAuthService(Ref ref) => PluginGoogleAuthService();

/// `AuthController`'s state: the current uid, once known, and whether that
/// session is still anonymous.
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({String? uid, @Default(true) bool isAnonymous}) =
      _AuthState;
}

/// The outcome of [AuthController.upgradeWithGoogle] — the UI renders each
/// case explicitly rather than only ever seeing a bare success/exception.
enum GoogleUpgradeOutcome {
  /// The session is now backed by the chosen Google identity.
  success,

  /// The user closed the Google account picker without choosing one — not
  /// an error.
  cancelled,

  /// The chosen Google identity already owns a separate Firebase account
  /// (`GoogleAccountAlreadyLinkedException`) — a real, expected case (a
  /// reinstall that previously upgraded with the same Google account), not
  /// a bug.
  alreadyLinked,
}

/// Bootstraps and owns the current Firebase Auth session (§8): silent
/// anonymous sign-in on first read, and the interactive Google upgrade
/// triggered when the user goes to add a friend (§8, §14).
@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    // Same "fire an async check from a sync build()" idiom as
    // `SelectedJourney.build()` (journey/presentation/journey_providers.dart)
    // — the widget renders the initial (signed-out) state for one frame
    // until this resolves.
    unawaited(_bootstrap());
    return const AuthState();
  }

  Future<void> _bootstrap() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final uid = await repository.ensureSignedIn();
      state = state.copyWith(uid: uid, isAnonymous: repository.isAnonymous);

      final subscription = repository.uidChanges().listen((uid) {
        state = state.copyWith(uid: uid, isAnonymous: repository.isAnonymous);
      });
      ref.onDispose(subscription.cancel);
    } catch (_) {
      // Anonymous sign-in can fail (no network on a device's very first
      // launch). Leave [state] at build()'s default (`uid: null`) rather
      // than letting an unhandled error escape this un-awaited bootstrap —
      // every consumer of [currentUidProvider] already treats `null` as
      // "no session yet", the same state a slow-but-eventually-successful
      // sign-in passes through anyway.
    }
  }

  /// Upgrades the current anonymous session to a permanent one backed by a
  /// Google identity (§8, §14) — called from the friends feature's
  /// "Add friend" flow when [AuthState.isAnonymous] is still `true`.
  Future<GoogleUpgradeOutcome> upgradeWithGoogle() async {
    final tokens = await ref.read(googleAuthServiceProvider).signIn();
    if (tokens == null) return GoogleUpgradeOutcome.cancelled;

    final repository = ref.read(authRepositoryProvider);
    // build()'s own _bootstrap() call already does this, but it's
    // unawaited and can still be in flight (or have silently failed and
    // be retrying) when the user reaches this point — the Google account
    // picker alone can take longer than the anonymous sign-in round trip,
    // but nothing guarantees it always will. linkWithGoogleCredential
    // requires a signed-in user; ensureSignedIn() is a no-op once one
    // already exists, so this is never wasted work, only ever a safety
    // net for that race.
    await repository.ensureSignedIn();

    try {
      await repository.linkWithGoogleCredential(idToken: tokens.idToken);
    } on GoogleAccountAlreadyLinkedException {
      return GoogleUpgradeOutcome.alreadyLinked;
    }

    state = state.copyWith(isAnonymous: false);
    return GoogleUpgradeOutcome.success;
  }
}

/// The current uid, or `null` before [AuthController] has resolved one.
@riverpod
String? currentUid(Ref ref) => ref.watch(authControllerProvider).uid;
