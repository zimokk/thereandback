import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:test/test.dart';
import 'package:thereandback/core/local_owner.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/drift/journey_asset_cache_repository.dart';
import 'package:thereandback/data/storage/journey_storage_repository.dart';
import 'package:thereandback/features/journey/data/journey_asset_repository.dart';
import 'package:thereandback/features/journey/domain/journey_asset_status.dart';

const _testManifest = (
  journeyId: 'some-quest',
  assetsVersion: 1,
  objectPaths: ['journeys/some-quest/map.webp', 'journeys/some-quest/map.json'],
  themeTrackObjectPath: 'journeys/some-quest/theme.wav',
);

void main() {
  late AppDatabase db;
  late MockFirebaseStorage mockStorage;
  late Directory tempDir;
  late JourneyAssetRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting();
    mockStorage = MockFirebaseStorage();
    tempDir = await Directory.systemTemp.createTemp('journey_asset_test');

    // Seed every object the test manifest lists, so a download has
    // something real to fetch — `MockFirebaseStorage`'s `getData` only
    // implements read-back of whatever was previously `putData`'d.
    for (final objectPath in [
      ..._testManifest.objectPaths,
      _testManifest.themeTrackObjectPath,
    ]) {
      await mockStorage
          .ref(objectPath)
          .putData(Uint8List.fromList(objectPath.codeUnits));
    }

    repository = JourneyAssetRepository(
      cache: DriftJourneyAssetCacheRepository(db),
      storage: FirebaseJourneyStorageRepository(mockStorage),
      cacheDirectory: () async => tempDir,
      findManifest: (journeyId) =>
          journeyId == _testManifest.journeyId ? _testManifest : null,
    );
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  group('a quest with no manifest (bundled in the app binary)', () {
    test('statusFor() is always ready — nothing to download', () async {
      expect(
        await repository.statusFor('odyssey-ithaca'),
        isA<JourneyAssetReady>(),
      );
    });

    test(
      'localDirectoryFor() is null — nothing is ever downloaded for it',
      () async {
        expect(await repository.localDirectoryFor('odyssey-ithaca'), isNull);
      },
    );

    test('download() is a no-op', () async {
      await repository.download('odyssey-ithaca');
      expect(
        await DriftJourneyAssetCacheRepository(db)
            .loadDownloadedVersion(localOwnerId, 'odyssey-ithaca'),
        isNull,
      );
    });
  });

  group('a quest with a manifest, nothing downloaded yet', () {
    test('statusFor() reports not-downloaded', () async {
      expect(
        await repository.statusFor(_testManifest.journeyId),
        isA<JourneyAssetNotDownloaded>(),
      );
    });

    test('download() fetches every object (including the theme track) and '
        'records the version', () async {
      await repository.download(_testManifest.journeyId);

      final dir = (await repository.localDirectoryFor(
        _testManifest.journeyId,
      ))!;
      expect(File('${dir.path}/map.webp').existsSync(), isTrue);
      expect(File('${dir.path}/map.json').existsSync(), isTrue);
      expect(File('${dir.path}/theme.wav').existsSync(), isTrue);

      expect(
        await repository.statusFor(_testManifest.journeyId),
        isA<JourneyAssetReady>(),
      );
    });

    test('download() reports progress from 0 to 1, monotonically', () async {
      final progressValues = <double>[];
      await repository.download(
        _testManifest.journeyId,
        onProgress: progressValues.add,
      );

      expect(progressValues.first, 0);
      expect(progressValues.last, 1);
      for (var i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThan(progressValues[i - 1]));
      }
    });
  });

  group('a quest with a manifest, already downloaded and current', () {
    test('download() is a no-op — statusFor() stays ready', () async {
      await repository.download(_testManifest.journeyId);
      final dir = (await repository.localDirectoryFor(
        _testManifest.journeyId,
      ))!;
      final mapFile = File('${dir.path}/map.webp');
      final firstWriteTime = mapFile.statSync().modified;

      await repository.download(_testManifest.journeyId);

      // Re-running download must not re-fetch — the file's mtime is
      // untouched, proving the second call short-circuited before ever
      // reaching the storage repository.
      expect(mapFile.statSync().modified, firstWriteTime);
      expect(
        await repository.statusFor(_testManifest.journeyId),
        isA<JourneyAssetReady>(),
      );
    });
  });

  group('a quest whose manifest version moved on', () {
    test('statusFor() reports not-downloaded again, and download() '
        'refetches', () async {
      final cache = DriftJourneyAssetCacheRepository(db);
      await cache.saveDownloadedVersion(
        localOwnerId,
        _testManifest.journeyId,
        _testManifest.assetsVersion - 1,
      );

      expect(
        await repository.statusFor(_testManifest.journeyId),
        isA<JourneyAssetNotDownloaded>(),
      );

      await repository.download(_testManifest.journeyId);
      expect(
        await cache.loadDownloadedVersion(
          localOwnerId,
          _testManifest.journeyId,
        ),
        _testManifest.assetsVersion,
      );
    });
  });
}
