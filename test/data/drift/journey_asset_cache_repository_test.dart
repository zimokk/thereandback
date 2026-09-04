import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/drift/journey_asset_cache_repository.dart';

void main() {
  late AppDatabase db;
  late JourneyAssetCacheRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = DriftJourneyAssetCacheRepository(db);
  });
  tearDown(() => db.close());

  test('loadDownloadedVersion() is null for a (owner, journey) pair '
      'nothing was ever saved for', () async {
    expect(
      await repository.loadDownloadedVersion('owner-1', 'some-quest'),
      isNull,
    );
  });

  test('saveDownloadedVersion() then loadDownloadedVersion() round-trips '
      'the value', () async {
    await repository.saveDownloadedVersion('owner-1', 'some-quest', 1);
    expect(await repository.loadDownloadedVersion('owner-1', 'some-quest'), 1);
  });

  test('a later saveDownloadedVersion() overwrites, not adds', () async {
    await repository.saveDownloadedVersion('owner-1', 'some-quest', 1);
    await repository.saveDownloadedVersion('owner-1', 'some-quest', 2);

    expect(await repository.loadDownloadedVersion('owner-1', 'some-quest'), 2);
  });

  test('two different journeys for the same owner are tracked '
      'independently', () async {
    await repository.saveDownloadedVersion('owner-1', 'quest-a', 1);
    await repository.saveDownloadedVersion('owner-1', 'quest-b', 5);

    expect(await repository.loadDownloadedVersion('owner-1', 'quest-a'), 1);
    expect(await repository.loadDownloadedVersion('owner-1', 'quest-b'), 5);
  });

  test('two different owners for the same journey are tracked '
      'independently', () async {
    await repository.saveDownloadedVersion('owner-1', 'some-quest', 1);
    await repository.saveDownloadedVersion('owner-2', 'some-quest', 2);

    expect(await repository.loadDownloadedVersion('owner-1', 'some-quest'), 1);
    expect(await repository.loadDownloadedVersion('owner-2', 'some-quest'), 2);
  });
}
