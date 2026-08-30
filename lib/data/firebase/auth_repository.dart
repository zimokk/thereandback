import 'package:firebase_auth/firebase_auth.dart';

/// Thrown by [AuthRepository.linkWithGoogleCredential] when the Google
/// identity being linked already owns a separate Firebase account —
/// Firebase's own `credential-already-in-use`. A real, expected case (the
/// same person reinstalled the app and got a fresh anonymous session, then
/// tried to upgrade with the Google account they used before) that the UI
/// must render explicitly, not a bug to let a raw `FirebaseAuthException`
/// leak into.
class GoogleAccountAlreadyLinkedException implements Exception {
  const GoogleAccountAlreadyLinkedException();

  @override
  String toString() => 'GoogleAccountAlreadyLinkedException';
}

/// Firebase Auth, behind an interface (§8, §13's "plan before permissions/
/// auth" already covered — this is the code that plan approved).
///
/// Anonymous sign-in is silent and automatic (§8: no login screen); the
/// only interactive step is the Google upgrade, triggered from the friends
/// feature (`AuthController.upgradeWithGoogle`, `app/auth_provider.dart`).
abstract class AuthRepository {
  /// Emits the current uid (`null` before any session exists — briefly, on
  /// a device's very first launch, before [ensureSignedIn] completes).
  Stream<String?> uidChanges();

  /// Returns the current uid, signing in anonymously first if there is no
  /// session yet.
  Future<String> ensureSignedIn();

  /// Whether the current session is still anonymous (no permanent identity
  /// linked). `true` (never `false`) when there is no session at all yet —
  /// callers that care should await [ensureSignedIn] first.
  bool get isAnonymous;

  /// Upgrades the current anonymous session to a permanent one backed by
  /// the given Google identity (§8, §14). Returns the linked account's
  /// email (`null` if Google didn't hand one back) — `AuthController` uses
  /// it to default the nickname to the account's local part (§6.5, §14).
  Future<String?> linkWithGoogleCredential({required String idToken});

  /// Switches the current Firebase Auth session to the existing permanent
  /// account owned by the given Google identity, abandoning whatever
  /// session (anonymous or otherwise) was active before. Used by
  /// `AuthController` when [linkWithGoogleCredential] fails with
  /// [GoogleAccountAlreadyLinkedException] — the same Google account was
  /// already used to upgrade a session on a different device or a previous
  /// install, and the user is signing back into it rather than upgrading a
  /// fresh one (§8, §14 — "repeat login").
  ///
  /// TODO(§14): the anonymous Firebase Auth user this device was on before
  /// this call is never signed out of explicitly — `signInWithCredential`
  /// simply replaces `_auth.currentUser` — nor is it deleted. Its uid, and
  /// whatever `users/{uid}` / `users/{uid}/progress` / `friendships/{...}`
  /// documents it already wrote to Firestore, are left behind as orphaned
  /// data with no cleanup path. Needs a plan before implementing (§13) —
  /// likely a scheduled Cloud Function that reaps anonymous accounts with
  /// no linked identity past some age.
  ///
  /// Returns the switched-to account's uid.
  Future<String> signInWithGoogleCredential({required String idToken});
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<String?> uidChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  @override
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  @override
  Future<String?> linkWithGoogleCredential({required String idToken}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'linkWithGoogleCredential called with no signed-in user — '
        'call ensureSignedIn() first',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    try {
      final userCredential = await user.linkWithCredential(credential);
      return userCredential.user?.email;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw const GoogleAccountAlreadyLinkedException();
      }
      rethrow;
    }
  }

  @override
  Future<String> signInWithGoogleCredential({required String idToken}) async {
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user!.uid;
  }
}
