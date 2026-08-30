import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/local_owner.dart';
import '../data/firebase/auth_repository.dart';
import '../data/firebase/firebase_providers.dart';
import '../data/firebase/google_sign_in_service.dart';
import '../data/firestore/firestore_providers.dart';
import '../data/firestore/user_profile_repository.dart';
import '../features/friends/domain/friendship.dart' show pinColorIndexForUid;
import '../features/journey/presentation/journey_providers.dart';

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
  /// A fresh anonymous session was upgraded (linked) to the chosen Google
  /// identity — nobody had used that identity before.
  success,

  /// The user closed the Google account picker without choosing one — not
  /// an error.
  cancelled,

  /// The chosen Google identity already owned a separate, existing Firebase
  /// account (`GoogleAccountAlreadyLinkedException`) — a real, expected
  /// case ("repeat login": a reinstall, or a second device, signing back
  /// into an account already used elsewhere), not a bug. The session has
  /// switched to that existing account — this device's own uid, and
  /// whatever this device had synced under it, are no longer current (§8,
  /// §14). Progress was reconciled by keeping whichever total (this
  /// device's local one, or the account's cloud one) was larger — see
  /// `AuthController._reconcileProgressWithCloud`.
  existingAccountRestored,
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

  /// Re-runs the [_bootstrap] sign-in attempt without discarding whatever
  /// [state] this controller already holds in the meantime — the nickname
  /// row's retry (`settings_tab.dart`'s `_retryProfileLoad`, §6.5) needs to
  /// give a stuck anonymous sign-in another chance, but calling
  /// `ref.invalidate(authControllerProvider)` for that re-runs [build]
  /// itself, which resets [state] to its bare default (`uid: null,
  /// isAnonymous: true`) for as long as the new [_bootstrap] call takes to
  /// resolve. Every uid-gated bit of UI (this row, the sign-in row, the
  /// Друзья tab) briefly flashes its signed-out look even when a uid was
  /// already known and the real problem was elsewhere (e.g. a transient
  /// profile write) — the retry's own visible "blink" a report of this bug
  /// described. Calling [_bootstrap] directly re-attempts
  /// [AuthRepository.ensureSignedIn] and re-subscribes to
  /// [AuthRepository.uidChanges] exactly as before, but only ever *sets*
  /// [state] on success — it never clears it first, so a session that was
  /// already resolved stays visibly signed in throughout the retry.
  Future<void> retryBootstrap() => _bootstrap();

  /// Upgrades the current anonymous session to a permanent one backed by a
  /// Google identity (§8, §14) — called from the friends feature's
  /// "Add friend" flow when [AuthState.isAnonymous] is still `true`.
  ///
  /// If that Google identity already owns a different, existing account
  /// ("repeat login" — a reinstall or a second device), this switches to
  /// that account instead of failing: see
  /// [_switchToExistingAccountAndReconcile].
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
    final uid = await repository.ensureSignedIn();

    final String? email;
    try {
      email = await repository.linkWithGoogleCredential(
        idToken: tokens.idToken,
      );
    } on GoogleAccountAlreadyLinkedException {
      return _switchToExistingAccountAndReconcile(tokens.idToken);
    }

    state = state.copyWith(isAnonymous: false);
    await _applyDefaultNicknameFromGoogleEmail(uid, email);
    return GoogleUpgradeOutcome.success;
  }

  /// Signs into the existing account that already owns [idToken]'s Google
  /// identity, then reconciles progress: keeps whichever total is larger,
  /// this device's own local one or the account's cloud one, and makes the
  /// loser match the winner (§8, §14 — "repeat login"). Friends and profile
  /// need no reconciliation of their own — `friends_providers.dart` and
  /// `myProfileProvider` already key everything off [currentUidProvider],
  /// so they pick up the new uid's data the moment [state] below updates.
  Future<GoogleUpgradeOutcome> _switchToExistingAccountAndReconcile(
    String idToken,
  ) async {
    final repository = ref.read(authRepositoryProvider);
    final uid = await repository.signInWithGoogleCredential(idToken: idToken);
    state = state.copyWith(uid: uid, isAnonymous: false);

    await _reconcileProgressWithCloud(uid);
    return GoogleUpgradeOutcome.existingAccountRestored;
  }

  /// Compares this device's local progress against [uid]'s cloud progress
  /// and keeps the larger of the two:
  /// - Cloud is bigger (or this device never started the quest) → pulled
  ///   into local drift via [ProgressRepository.restoreFromCloud], then
  ///   [SelectedJourney.reload] so the "Путь"/"Карта" tabs pick it up.
  /// - Local is bigger or equal (including "neither has any progress") →
  ///   local drift is left untouched; if it has *some* progress, it's
  ///   pushed to [uid]'s cloud doc so the account itself reflects the
  ///   larger total too — otherwise a third device reading this uid later
  ///   would still see the smaller, stale cloud figure.
  ///
  /// Best-effort: [uid] is already signed in and that must stand regardless
  /// of whether this reconciliation itself succeeds (offline, a transient
  /// Firestore error) — a failure here just means the next successful sync
  /// or app open reconciles it instead, same as any other fire-and-forget
  /// Firestore write in this app (§8).
  Future<void> _reconcileProgressWithCloud(String uid) async {
    try {
      final progressSync = ref.read(progressSyncRepositoryProvider);
      final remote = await progressSync.fetchCurrentProgress(uid);
      // `SelectedJourney.build()`'s own cold-start restore from drift is
      // unawaited — reading `selectedJourneyProvider` here without waiting
      // for it first could see `null` (and so treat real, not-yet-loaded
      // local progress as zero) even on a device that already has some.
      // See `SelectedJourney.ensureRestored`'s own doc comment.
      await ref.read(selectedJourneyProvider.notifier).ensureRestored();
      final local = ref.read(selectedJourneyProvider);
      final localMeters = local?.progressMeters ?? 0;

      if (remote != null && remote.meters > localMeters) {
        await ref
            .read(progressRepositoryProvider)
            .restoreFromCloud(
              localOwnerId,
              journeyId: remote.journeyId,
              startedAt: remote.startedAt,
              meters: remote.meters,
              asOf: DateTime.now(),
            );
        await ref.read(selectedJourneyProvider.notifier).reload();
        return;
      }

      if (local != null && local.progressMeters > 0) {
        await progressSync.pushProgress(
          uid: uid,
          journeyId: local.journeyId,
          meters: local.progressMeters,
          startedAt: local.startedAt,
          isCurrent: true,
        );
      }
    } catch (error) {
      // See doc comment above — never let this undo the sign-in that
      // already succeeded. Logged (debug builds only), no PII (§13): just
      // the caught error's own message, never meters or a nickname.
      debugPrint('Cloud progress reconciliation failed: $error');
    }
  }

  /// Defaults the nickname to the local part of the linked Gmail address
  /// (`pupa@gmail.com` → `pupa`) the first time a session upgrades to a
  /// Google identity — otherwise the anonymous-session placeholder
  /// (`defaultStarterNickname`, `data/firestore/user_profile_repository
  /// .dart`) sticks around forever unless the user edits it by hand (§14).
  /// A `+tag` suffix is stripped too — Gmail's own filtering convention,
  /// not part of the person's identity.
  ///
  /// Only ever replaces that exact generated placeholder, never a
  /// nickname the user already chose (§6.5's editor) — comparing the live
  /// profile against the same generator the starter profile was created
  /// with is what tells the two apart.
  ///
  /// If the email-derived nickname is already claimed by someone else,
  /// this does **not** give up and leave the anonymous placeholder in
  /// place — it retries with a numeric suffix (`pupa-1`, `pupa-2`, …)
  /// until one is free (this task's requirement: the Друзья tab unlocks
  /// once a real nickname exists, §6.4/§6.5, so first login must actually
  /// land on one rather than a `Traveler-xxxxxx` placeholder just because
  /// the exact email-derived name happened to be taken).
  ///
  /// Ensures `users/{uid}` exists (the same idempotent
  /// [UserProfileRepository.createInitialProfileIfAbsent] call
  /// `ensureFriendProfileProvider` makes) before deciding whether the
  /// nickname is still the default — **not** a former bug's own read-only
  /// check. That used to just read the profile and bail out on `null`,
  /// which raced `ensureFriendProfileProvider`'s own lazy bootstrap: on a
  /// fresh anonymous session, the Google upgrade can complete (cached
  /// account, no picker shown) before that background write ever lands, so
  /// this saw no profile, did nothing, and the placeholder created moments
  /// later by the other bootstrap never got renamed — no default nickname
  /// ever showed up. Calling it here too is safe either way it races:
  /// `createInitialProfileIfAbsent`'s own transaction already de-dupes two
  /// concurrent creators of the exact same uid+nickname (the loser throws
  /// `NicknameTakenException`, caught by whichever caller runs second).
  ///
  /// Best-effort and never lets a problem here undo the upgrade that
  /// already succeeded: no email, every numbered variant up to the cap
  /// also being taken, or any other failure (e.g. this device being
  /// offline) all just leave the placeholder in place silently — the user
  /// can still rename themselves by hand (§6.5), so this is a convenience,
  /// not a guarantee.
  Future<void> _applyDefaultNicknameFromGoogleEmail(
    String uid,
    String? email,
  ) async {
    if (email == null) return;
    final local = email.split('@').first.split('+').first;
    if (local.isEmpty) return;

    try {
      final profileRepository = ref.read(userProfileRepositoryProvider);
      try {
        await profileRepository.createInitialProfileIfAbsent(
          uid,
          nickname: defaultStarterNickname(uid),
          avatarPresetIndex: pinColorIndexForUid(uid),
        );
      } on NicknameTakenException {
        // Lost the create race to `ensureFriendProfileProvider`'s own
        // bootstrap running concurrently — the profile exists either way,
        // which is all this call needed; fall through to the rename check
        // below rather than treating this as a failure.
      }
      final profile = await profileRepository.watchProfile(uid).first;
      final isStillDefault =
          profile != null && profile.nickname == defaultStarterNickname(uid);
      if (!isStillDefault) return;
      await _updateNicknameResolvingCollisions(profileRepository, uid, local);
    } catch (error) {
      // Logged (debug builds only) for diagnosability — never the email
      // itself (§13: no PII in logs), only the caught error's own message.
      debugPrint('Google-email nickname default failed: $error');
    }
  }

  /// Tries [base], then `base-1`, `base-2`, … up to [maxSuffix] numbered
  /// variants, until [UserProfileRepository.updateNickname] accepts one —
  /// the default-nickname collision resolution this task asks for. Stops
  /// (rethrowing, so the caller's own catch-all leaves the placeholder in
  /// place) once every variant up to the cap is taken too — a bound is
  /// needed somewhere, and this many collisions on one email's exact local
  /// part is itself vanishingly unlikely.
  Future<void> _updateNicknameResolvingCollisions(
    UserProfileRepository profileRepository,
    String uid,
    String base, {
    int maxSuffix = 20,
  }) async {
    for (var suffix = 0; suffix <= maxSuffix; suffix++) {
      final candidate = suffix == 0 ? base : '$base-$suffix';
      try {
        await profileRepository.updateNickname(uid, candidate);
        return;
      } on NicknameTakenException {
        if (suffix == maxSuffix) rethrow;
        // else: try the next numbered variant.
      }
    }
  }
}

/// The current uid, or `null` before [AuthController] has resolved one.
@riverpod
String? currentUid(Ref ref) => ref.watch(authControllerProvider).uid;
