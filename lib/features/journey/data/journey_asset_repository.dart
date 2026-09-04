import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/local_owner.dart';
import '../../../data/drift/journey_asset_cache_repository.dart';
import '../../../data/storage/journey_storage_repository.dart';
import '../domain/journey_asset_status.dart';
import 'journey_asset_catalog.dart';

/// Orchestrates a quest's downloadable content (§8, §14): consults the
/// catalog manifest (`journey_asset_catalog.dart`) and the local cache
/// record ([JourneyAssetCacheRepository]) to know whether anything needs
/// downloading, and drives [JourneyStorageRepository] to fetch it into a
/// per-journey directory under the app's own support directory.
///
/// A quest with no [JourneyAssetManifest] entry — every quest today, since
/// the Odyssey ships fully bundled in the app binary — is always
/// [JourneyAssetReady] and every method here is a no-op for it: this class
/// only ever does real work for a quest that actually has something to
/// download.
class JourneyAssetRepository {
  // Named, not positional initializing formals (`this._cache`): two
  // same-shaped repository dependencies are easy to swap by accident
  // positionally, and a private initializing formal's parameter name can't
  // be referenced from another library anyway (`app/
  // journey_asset_repository_provider.dart` constructs this class) — so
  // this intentionally keeps the public `cache`/`storage` names distinct
  // from the private fields they populate.
  JourneyAssetRepository({
    required JourneyAssetCacheRepository cache,
    required JourneyStorageRepository storage,
    Future<Directory> Function()? cacheDirectory,
    JourneyAssetManifest? Function(String journeyId)? findManifest,
  }) : _cache = cache, // ignore: prefer_initializing_formals
       _storage = storage, // ignore: prefer_initializing_formals
       _cacheDirectory = cacheDirectory ?? getApplicationSupportDirectory,
       _findManifest = findManifest ?? findJourneyAssetManifest;

  final JourneyAssetCacheRepository _cache;
  final JourneyStorageRepository _storage;

  /// Overridable in tests (`journey_asset_repository_test.dart`) so a unit
  /// test never touches the real `path_provider` plugin — same reasoning
  /// `database.dart`'s own `_openConnection` keeps `path_provider` out of
  /// `AppDatabase.forTesting()`.
  final Future<Directory> Function() _cacheDirectory;

  /// Overridable in tests for the same reason as [_cacheDirectory]: the
  /// real `journeyAssetManifests` (`journey_asset_catalog.dart`) is a
  /// `const` list, empty until a quest with real downloadable content
  /// exists — a unit test exercising an actual download needs to supply a
  /// manifest of its own rather than wait for one.
  final JourneyAssetManifest? Function(String journeyId) _findManifest;

  /// The status a quest is in *without* starting a download — safe to call
  /// any time, e.g. to render a catalog card before the user has tapped
  /// anything.
  Future<JourneyAssetStatus> statusFor(String journeyId) async {
    final manifest = _findManifest(journeyId);
    if (manifest == null) return const JourneyAssetReady(); // bundled

    final downloadedVersion = await _cache.loadDownloadedVersion(
      localOwnerId,
      journeyId,
    );
    return journeyAssetNeedsDownload(
          downloadedVersion: downloadedVersion,
          catalogVersion: manifest.assetsVersion,
        )
        ? const JourneyAssetNotDownloaded()
        : const JourneyAssetReady();
  }

  /// The local directory a journey's downloaded files live in (not
  /// guaranteed to exist yet — [download] creates it) — `null` for a quest
  /// with no manifest (bundled, nothing is ever downloaded for it).
  Future<Directory?> localDirectoryFor(String journeyId) async {
    if (_findManifest(journeyId) == null) return null;
    final base = await _cacheDirectory();
    return Directory('${base.path}/journeys/$journeyId');
  }

  /// Downloads everything the manifest lists for [journeyId] — a no-op if
  /// the quest has no manifest (bundled) or is already at the current
  /// [JourneyAssetManifest.assetsVersion]. Not resumable file-by-file (a
  /// retry after a failure redownloads from the first file) — acceptable
  /// for the handful of files one quest's manifest lists (a map, its JSON
  /// description, an optional theme track), not worth the complexity of
  /// per-file resume bookkeeping for that count.
  ///
  /// [onProgress], when given, is called with a value in 0..1 — advanced
  /// one file at a time (`(filesDone) / totalFiles`), not weighted by byte
  /// size: `JourneyStorageRepository.downloadObject` fetches a whole object
  /// in one call with no intermediate byte-level callback
  /// (`getData` has no progress stream, unlike an upload/download `Task`),
  /// so file-count granularity is the finest this can honestly report.
  /// Coarse, but a manifest is a handful of files, not hundreds — the bar
  /// moves visibly either way.
  Future<void> download(
    String journeyId, {
    void Function(double progress)? onProgress,
  }) async {
    final manifest = _findManifest(journeyId);
    if (manifest == null) return; // bundled quest, nothing to do

    final downloadedVersion = await _cache.loadDownloadedVersion(
      localOwnerId,
      journeyId,
    );
    if (!journeyAssetNeedsDownload(
      downloadedVersion: downloadedVersion,
      catalogVersion: manifest.assetsVersion,
    )) {
      onProgress?.call(1);
      return;
    }

    final dir = (await localDirectoryFor(journeyId))!;
    await dir.create(recursive: true);

    final objectPaths = [
      ...manifest.objectPaths,
      ?manifest.themeTrackObjectPath,
    ];

    if (objectPaths.isEmpty) {
      await _cache.saveDownloadedVersion(
        localOwnerId,
        journeyId,
        manifest.assetsVersion,
      );
      onProgress?.call(1);
      return;
    }

    onProgress?.call(0);
    for (var i = 0; i < objectPaths.length; i++) {
      final objectPath = objectPaths[i];
      await _storage.downloadObject(
        objectPath: objectPath,
        localFile: File('${dir.path}/${objectPath.split('/').last}'),
      );
      onProgress?.call((i + 1) / objectPaths.length);
    }

    await _cache.saveDownloadedVersion(
      localOwnerId,
      journeyId,
      manifest.assetsVersion,
    );
  }
}
