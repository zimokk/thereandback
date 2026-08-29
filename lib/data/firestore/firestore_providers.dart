import 'package:riverpod_annotation/riverpod_annotation.dart';

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
