import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Downloads a quest's not-bundled content (CLAUDE.md §8, §14) from Firebase
/// Storage — the sync layer for `assets/journeys/{journeyId}/` content that
/// stopped shipping in the app binary, mirroring how `data/firestore/`
/// wraps Firestore for progress/friends. Never the source of truth on its
/// own: once downloaded, the file on disk is what every reader
/// (`quest_map_repository.dart`, the Flame scene, the theme-track player)
/// actually uses — this repository is only ever consulted again to check
/// for a newer `JourneyAssetManifest.assetsVersion`
/// (`journey_asset_status.dart`).
abstract class JourneyStorageRepository {
  /// Downloads the object at [objectPath] (e.g.
  /// `"journeys/some-quest/map.webp"`) and writes it to [localFile],
  /// creating its parent directory if needed and overwriting anything
  /// already there. Throws whatever `firebase_storage` throws on a missing
  /// object, a permission error, or no network — the caller
  /// (`journey_asset_repository.dart`) turns that into
  /// `JourneyAssetFailed`, never a silent drop (§7).
  Future<void> downloadObject({
    required String objectPath,
    required File localFile,
  });
}

class FirebaseJourneyStorageRepository implements JourneyStorageRepository {
  FirebaseJourneyStorageRepository(this._storage);

  final FirebaseStorage _storage;

  /// Generous ceiling for a single quest asset (parallax layer, map
  /// illustration, or theme track) — comfortably above anything §9.1's
  /// planned ~4096px WebP maps or a short ambient loop would produce, while
  /// still bounding memory use per file: [Reference.getData] buffers the
  /// whole object in memory at once, so this can't be left unbounded.
  static const _maxObjectBytes = 100 * 1024 * 1024; // 100 MB

  @override
  Future<void> downloadObject({
    required String objectPath,
    required File localFile,
  }) async {
    final data = await _storage.ref(objectPath).getData(_maxObjectBytes);
    if (data == null) {
      throw StateError('No data at Storage path "$objectPath"');
    }
    await localFile.parent.create(recursive: true);
    await localFile.writeAsBytes(data);
  }
}
