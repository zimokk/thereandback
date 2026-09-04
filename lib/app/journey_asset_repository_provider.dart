import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/drift/journey_asset_cache_repository.dart';
import '../data/firebase/firebase_providers.dart';
import '../data/storage/journey_storage_repository.dart';
import '../features/journey/data/journey_asset_repository.dart';
import 'database_provider.dart';

part 'journey_asset_repository_provider.g.dart';

/// The drift-backed local record of which quest content-version is
/// downloaded (§8, §14). `app/` is the DI root (§4) — same reasoning
/// `user_preference_repository_provider.dart` already documents for a
/// repository more than one feature might eventually read (today: only
/// `features/journey/`, but a per-quest theme track — the one already
/// planned in the manifest shape — is `features/audio/`'s concern too).
@riverpod
JourneyAssetCacheRepository journeyAssetCacheRepository(Ref ref) =>
    DriftJourneyAssetCacheRepository(ref.watch(appDatabaseProvider));

/// The Firebase Storage-backed download for a quest's not-bundled content.
/// Overridden with `firebase_storage_mocks` in tests (`testing` skill).
@riverpod
JourneyStorageRepository journeyStorageRepository(Ref ref) =>
    FirebaseJourneyStorageRepository(ref.watch(firebaseStorageProvider));

/// Orchestrates the two repositories above (§8, §14) — one instance for the
/// whole app session, so an in-flight download survives whatever widget
/// happened to trigger it being rebuilt or disposed.
@Riverpod(keepAlive: true)
JourneyAssetRepository journeyAssetRepository(Ref ref) =>
    JourneyAssetRepository(
      cache: ref.watch(journeyAssetCacheRepositoryProvider),
      storage: ref.watch(journeyStorageRepositoryProvider),
    );
