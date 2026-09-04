import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/journey_asset_status.dart';

void main() {
  group('journeyAssetNeedsDownload', () {
    test('no local record at all needs a download', () {
      expect(
        journeyAssetNeedsDownload(downloadedVersion: null, catalogVersion: 1),
        isTrue,
      );
    });

    test('local record behind the catalog version needs a redownload', () {
      expect(
        journeyAssetNeedsDownload(downloadedVersion: 1, catalogVersion: 2),
        isTrue,
      );
    });

    test('local record matching the catalog version is up to date', () {
      expect(
        journeyAssetNeedsDownload(downloadedVersion: 2, catalogVersion: 2),
        isFalse,
      );
    });

    test('local record ahead of the catalog version is left alone', () {
      // Never happens in practice (the catalog only ever moves forward),
      // but must never be read as "needs download" either.
      expect(
        journeyAssetNeedsDownload(downloadedVersion: 3, catalogVersion: 2),
        isFalse,
      );
    });
  });

  group('JourneyAssetStatus (sealed variants carry the data each state '
      'needs, nothing more)', () {
    test('JourneyAssetDownloading carries its progress', () {
      const status = JourneyAssetDownloading(0.42);
      expect(status.progress, 0.42);
    });

    test('JourneyAssetFailed carries its reason', () {
      const status = JourneyAssetFailed('network unreachable');
      expect(status.reason, 'network unreachable');
    });

    test('every variant is a JourneyAssetStatus, switchable exhaustively', () {
      const statuses = <JourneyAssetStatus>[
        JourneyAssetNotDownloaded(),
        JourneyAssetDownloading(0.5),
        JourneyAssetReady(),
        JourneyAssetFailed('x'),
      ];
      for (final status in statuses) {
        // A non-exhaustive switch would fail to compile (sealed class) —
        // this is really a compile-time guarantee, exercised here only to
        // prove every branch is reachable at runtime too.
        final label = switch (status) {
          JourneyAssetNotDownloaded() => 'not-downloaded',
          JourneyAssetDownloading() => 'downloading',
          JourneyAssetReady() => 'ready',
          JourneyAssetFailed() => 'failed',
        };
        expect(label, isNotEmpty);
      }
    });
  });

  group('JourneyAssetManifest', () {
    test('a plain record carries every field it declares', () {
      const manifest = (
        journeyId: 'foo',
        assetsVersion: 3,
        objectPaths: ['journeys/foo/map.webp', 'journeys/foo/map.json'],
        themeTrackObjectPath: 'journeys/foo/theme.wav',
      );
      expect(manifest.journeyId, 'foo');
      expect(manifest.assetsVersion, 3);
      expect(manifest.objectPaths, [
        'journeys/foo/map.webp',
        'journeys/foo/map.json',
      ]);
      expect(manifest.themeTrackObjectPath, 'journeys/foo/theme.wav');
    });

    test('themeTrackObjectPath is nullable — a quest with no theme of its '
        'own', () {
      const manifest = (
        journeyId: 'foo',
        assetsVersion: 1,
        objectPaths: <String>['journeys/foo/map.webp'],
        themeTrackObjectPath: null,
      );
      expect(manifest.themeTrackObjectPath, isNull);
    });
  });
}
