import 'package:drift/drift.dart';

import 'database.dart';

/// The locally cached "which version of a quest's downloadable content is
/// on this device" record, backed by [JourneyAssetRows] (`database.dart`) —
/// the drift half of the download feature (§8, §14), paired with
/// `data/storage/journey_storage_repository.dart` for the actual Storage
/// download. One row per `(ownerId, journeyId)`, same shape
/// `DriftUserPreferenceRepository` already proved for a single-owner row.
abstract class JourneyAssetCacheRepository {
  /// The locally cached `assetsVersion` for `(ownerId, journeyId)`, or
  /// `null` if nothing has ever been downloaded for that pair — the caller
  /// (`journey_asset_repository.dart`) feeds this straight into
  /// `journeyAssetNeedsDownload`.
  Future<int?> loadDownloadedVersion(String ownerId, String journeyId);

  /// Records that [version] of `journeyId`'s content is now fully on disk.
  /// Called only after every file in the manifest has downloaded
  /// successfully — never partway through, so a crash mid-download leaves
  /// no stale "done" record behind.
  Future<void> saveDownloadedVersion(
    String ownerId,
    String journeyId,
    int version,
  );
}

class DriftJourneyAssetCacheRepository implements JourneyAssetCacheRepository {
  DriftJourneyAssetCacheRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int?> loadDownloadedVersion(String ownerId, String journeyId) async {
    final row =
        await (_db.select(_db.journeyAssetRows)..where(
              (t) => t.ownerId.equals(ownerId) & t.journeyId.equals(journeyId),
            ))
            .getSingleOrNull();
    return row?.assetsVersion;
  }

  @override
  Future<void> saveDownloadedVersion(
    String ownerId,
    String journeyId,
    int version,
  ) {
    return _db
        .into(_db.journeyAssetRows)
        .insertOnConflictUpdate(
          JourneyAssetRowsCompanion.insert(
            ownerId: ownerId,
            journeyId: journeyId,
            assetsVersion: version,
            downloadedAt: DateTime.now().toUtc(),
          ),
        );
  }
}
