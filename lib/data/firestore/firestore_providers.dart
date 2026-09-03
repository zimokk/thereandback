import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/auth_provider.dart' show currentUidProvider;
import '../firebase/firebase_providers.dart';
import 'friendship_repository.dart';
import 'progress_sync_repository.dart';
import 'user_profile_repository.dart';

part 'firestore_providers.g.dart';

/// The three Firestore-backed repositories Phase 8 needs (§8), collected
/// here rather than under `features/friends/` or `features/steps/` since
/// both features consume [progressSyncRepositoryProvider] — one canonical
/// provider per data source, same `@riverpod` shape as
/// `app/database_provider.dart`.
@riverpod
FriendshipRepository friendshipRepository(Ref ref) =>
    FirestoreFriendshipRepository(ref.watch(firestoreProvider));

@riverpod
UserProfileRepository userProfileRepository(Ref ref) =>
    FirestoreUserProfileRepository(ref.watch(firestoreProvider));

/// Pushes progress to `users/{uid}/progress/{journeyId}` after a
/// foreground sync (`features/steps/presentation/steps_providers.dart`'s
/// `StepsSync.sync()`) and reads a friend's progress
/// (`features/friends/presentation/friends_providers.dart`) — a sync layer
/// only, never the source of truth (drift is, §8).
@riverpod
ProgressSyncRepository progressSyncRepository(Ref ref) =>
    FirestoreProgressSyncRepository(ref.watch(firestoreProvider));

/// Best-effort push of a quest's running total to `users/{uid}/progress/
/// {journeyId}`. Shared by two call sites that would otherwise duplicate
/// the same uid-gate + swallow-errors idiom: `SelectedJourney.start()`
/// (`features/journey/presentation/journey_providers.dart`) pushes an
/// initial `progressMeters: 0` row the instant "Начать квест" is tapped,
/// so a friend's row/pin and `AuthController`'s repeat-login reconciliation
/// (§8, §14) see the quest exists in Firestore without waiting on the
/// first steps sync; `StepsSync.sync()`
/// (`features/steps/presentation/steps_providers.dart`) pushes the updated
/// total after every later foreground sync.
///
/// Fire-and-forget from the caller's point of view: a Firestore failure
/// (offline, permission not yet granted, no signed-in uid yet on a very
/// fresh cold start) must never affect the caller's own result — the local
/// drift write it follows is already durable regardless of whether this
/// succeeds (§8's full-offline requirement).
Future<void> pushProgressBestEffort(
  Ref ref, {
  required String journeyId,
  required DateTime startedAt,
  required int progressMeters,
}) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) return;

  try {
    await ref
        .read(progressSyncRepositoryProvider)
        .pushProgress(
          uid: uid,
          journeyId: journeyId,
          meters: progressMeters,
          startedAt: startedAt,
          isCurrent: true,
        );
  } catch (_) {
    // See doc comment above — never let this surface to the caller.
  }
}
