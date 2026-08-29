import 'package:google_sign_in/google_sign_in.dart';

/// The Google identity token needed for Firebase's `GoogleAuthProvider`
/// (§8). Only an ID token — `google_sign_in` v7's `authenticate()` hands
/// that back directly; an access token needs a separate authorization-scope
/// round trip (`GoogleSignInAccount.authorizationClient`) this app has no
/// use for, since `GoogleAuthProvider.credential` works from an ID token
/// alone.
class GoogleAuthTokens {
  const GoogleAuthTokens({required this.idToken});

  final String idToken;
}

/// Interactive Google sign-in (the §8 upgrade path), behind an interface so
/// `AuthController` can be unit-tested without the real plugin — mirrors
/// `features/steps/data/step_counting_service.dart`'s
/// interface-over-a-plugin shape.
abstract class GoogleAuthService {
  /// Prompts the user to pick/authorize a Google account. Returns `null` if
  /// the user cancels — never throws for a plain cancellation.
  Future<GoogleAuthTokens?> signIn();
}

/// Wraps `package:google_sign_in`'s v7 singleton API
/// (`GoogleSignIn.instance`).
///
/// [clientId]/[serverClientId] are only needed on platforms that don't pick
/// them up from a configuration file (`flutterfire configure`'s generated
/// `google-services.json`/`GoogleService-Info.plist` cover Android/iOS) —
/// left `null` by default; only set them if a specific platform later needs
/// an explicit override.
class PluginGoogleAuthService implements GoogleAuthService {
  PluginGoogleAuthService({this.clientId, this.serverClientId});

  final String? clientId;
  final String? serverClientId;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // `GoogleSignIn.instance.initialize` must complete exactly once before
    // any other call on the singleton (package's own contract) — guarded
    // here so callers never have to remember to do this themselves.
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _initialized = true;
  }

  @override
  Future<GoogleAuthTokens?> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return null;
      return GoogleAuthTokens(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}
