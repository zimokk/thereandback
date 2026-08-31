import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/steps/data/step_sample_repository.dart';

void main() {
  late AppDatabase db;
  late StepSampleRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = DriftStepSampleRepository(db);
  });
  tearDown(() => db.close());

  test('recording a new interval returns true', () async {
    final recorded = await repository.recordInterval(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
      intervalStart: DateTime(2026, 3, 10),
      intervalEnd: DateTime(2026, 3, 10, 0, 10),
      steps: 100,
      resolvedMeters: 75,
      flaggedPace: false,
      syncedAt: DateTime(2026, 3, 10, 0, 10),
    );

    expect(recorded, isTrue);
  });

  test('§5.2, Phase 3: a repeated sync of the same interval does not double '
      'progress — the second call to record it returns false and no second '
      'row is written', () async {
    final intervalStart = DateTime(2026, 3, 10);

    final first = await repository.recordInterval(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
      intervalStart: intervalStart,
      intervalEnd: DateTime(2026, 3, 10, 0, 10),
      steps: 100,
      resolvedMeters: 75,
      flaggedPace: false,
      syncedAt: DateTime(2026, 3, 10, 0, 10),
    );
    // A replay of the exact same interval — say, a background sync racing
    // a foreground one, or an app restart that lost in-memory
    // `lastSyncedAt` and refetched the same window.
    final second = await repository.recordInterval(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
      intervalStart: intervalStart,
      intervalEnd: DateTime(2026, 3, 10, 0, 12), // even a slightly
      // different intervalEnd doesn't matter — the key is intervalStart.
      steps: 100,
      resolvedMeters: 75,
      flaggedPace: false,
      syncedAt: DateTime(2026, 3, 10, 0, 12),
    );

    expect(first, isTrue);
    expect(second, isFalse);
    expect(await db.select(db.stepIntervalRecords).get(), hasLength(1));
  });

  test('a different journeyId for the same owner and intervalStart is a '
      'distinct interval, not a duplicate', () async {
    final intervalStart = DateTime(2026, 3, 10);

    final first = await repository.recordInterval(
      ownerId: 'owner-1',
      journeyId: 'quest-a',
      intervalStart: intervalStart,
      intervalEnd: DateTime(2026, 3, 10, 0, 10),
      steps: 100,
      resolvedMeters: 75,
      flaggedPace: false,
      syncedAt: DateTime(2026, 3, 10, 0, 10),
    );
    final second = await repository.recordInterval(
      ownerId: 'owner-1',
      journeyId: 'quest-b',
      intervalStart: intervalStart,
      intervalEnd: DateTime(2026, 3, 10, 0, 10),
      steps: 100,
      resolvedMeters: 75,
      flaggedPace: false,
      syncedAt: DateTime(2026, 3, 10, 0, 10),
    );

    expect(first, isTrue);
    expect(second, isTrue);
  });

  test(
    'an implausible-pace interval is still recorded, never dropped (§5.2)',
    () async {
      final recorded = await repository.recordInterval(
        ownerId: 'owner-1',
        journeyId: 'odyssey-ithaca',
        intervalStart: DateTime(2026, 3, 10),
        intervalEnd: DateTime(2026, 3, 10, 0, 0, 30),
        steps: 10000,
        resolvedMeters: 7500,
        flaggedPace: true,
        syncedAt: DateTime(2026, 3, 10, 0, 0, 30),
      );

      expect(recorded, isTrue);
      final row = await db.select(db.stepIntervalRecords).getSingle();
      expect(row.flaggedPace, isTrue);
      expect(row.resolvedMeters, 7500);
    },
  );

  group('totalResolvedMeters', () {
    test('nothing recorded yet sums to 0, not null', () async {
      expect(
        await repository.totalResolvedMeters(
          ownerId: 'owner-1',
          journeyId: 'odyssey-ithaca',
        ),
        0,
      );
    });

    test('sums every recorded interval for that owner+journey', () async {
      await repository.recordInterval(
        ownerId: 'owner-1',
        journeyId: 'odyssey-ithaca',
        intervalStart: DateTime(2026, 3, 10),
        intervalEnd: DateTime(2026, 3, 10, 0, 10),
        steps: 100,
        resolvedMeters: 75,
        flaggedPace: false,
        syncedAt: DateTime(2026, 3, 10, 0, 10),
      );
      await repository.recordInterval(
        ownerId: 'owner-1',
        journeyId: 'odyssey-ithaca',
        intervalStart: DateTime(2026, 3, 10, 0, 10),
        intervalEnd: DateTime(2026, 3, 10, 0, 20),
        steps: 100,
        resolvedMeters: 80,
        flaggedPace: false,
        syncedAt: DateTime(2026, 3, 10, 0, 20),
      );

      expect(
        await repository.totalResolvedMeters(
          ownerId: 'owner-1',
          journeyId: 'odyssey-ithaca',
        ),
        155,
      );
    });

    test('never mixes another owner or journey into the sum', () async {
      await repository.recordInterval(
        ownerId: 'owner-1',
        journeyId: 'odyssey-ithaca',
        intervalStart: DateTime(2026, 3, 10),
        intervalEnd: DateTime(2026, 3, 10, 0, 10),
        steps: 100,
        resolvedMeters: 75,
        flaggedPace: false,
        syncedAt: DateTime(2026, 3, 10, 0, 10),
      );
      await repository.recordInterval(
        ownerId: 'owner-2', // different owner.
        journeyId: 'odyssey-ithaca',
        intervalStart: DateTime(2026, 3, 10),
        intervalEnd: DateTime(2026, 3, 10, 0, 10),
        steps: 500,
        resolvedMeters: 400,
        flaggedPace: false,
        syncedAt: DateTime(2026, 3, 10, 0, 10),
      );
      await repository.recordInterval(
        ownerId: 'owner-1',
        journeyId: 'quest-b', // different journey.
        intervalStart: DateTime(2026, 3, 10),
        intervalEnd: DateTime(2026, 3, 10, 0, 10),
        steps: 500,
        resolvedMeters: 400,
        flaggedPace: false,
        syncedAt: DateTime(2026, 3, 10, 0, 10),
      );

      expect(
        await repository.totalResolvedMeters(
          ownerId: 'owner-1',
          journeyId: 'odyssey-ithaca',
        ),
        75,
      );
    });
  });
}
