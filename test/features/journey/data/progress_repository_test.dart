import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/data/progress_repository.dart';

void main() {
  late AppDatabase db;
  late ProgressRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = DriftProgressRepository(db);
  });
  tearDown(() => db.close());

  test('no quest started yet loads as null', () async {
    expect(await repository.loadSelectedQuest('owner-1'), isNull);
  });

  test(
    'a freshly started quest loads back with zero progress and the '
    'lastSyncedAt seeded to the local calendar day it started on (§5.2)',
    () async {
      final startedAt = DateTime(2026, 3, 10, 21, 45);
      await repository.startQuest(
        'owner-1',
        journeyId: 'odyssey-ithaca',
        startedAt: startedAt,
      );

      final quest = await repository.loadSelectedQuest('owner-1');

      expect(quest, isNotNull);
      expect(quest!.journeyId, 'odyssey-ithaca');
      expect(quest.startedAt, startedAt);
      expect(quest.progressMeters, 0);
      expect(quest.lastSyncedAt, DateTime(2026, 3, 10));
    },
  );

  test(
    'progress is derived from recorded intervals, not stored as its own '
    'mutable total (§5.2: "work with deltas, not an accumulated total")',
    () async {
      final startedAt = DateTime(2026, 3, 10);
      await repository.startQuest(
        'owner-1',
        journeyId: 'odyssey-ithaca',
        startedAt: startedAt,
      );

      final intervals = db.stepIntervalRecords;
      await db
          .into(intervals)
          .insert(
            StepIntervalRecordsCompanion.insert(
              ownerId: 'owner-1',
              journeyId: 'odyssey-ithaca',
              intervalStart: DateTime.utc(2026, 3, 10),
              intervalEnd: DateTime.utc(2026, 3, 10, 0, 10),
              steps: 100,
              resolvedMeters: 75,
              syncedAt: DateTime.utc(2026, 3, 10, 0, 10),
            ),
          );
      await db
          .into(intervals)
          .insert(
            StepIntervalRecordsCompanion.insert(
              ownerId: 'owner-1',
              journeyId: 'odyssey-ithaca',
              intervalStart: DateTime.utc(2026, 3, 10, 0, 10),
              intervalEnd: DateTime.utc(2026, 3, 10, 0, 20),
              steps: 100,
              resolvedMeters: 75,
              syncedAt: DateTime.utc(2026, 3, 10, 0, 20),
            ),
          );

      final quest = await repository.loadSelectedQuest('owner-1');

      expect(quest!.progressMeters, 150);
      expect(quest.lastSyncedAt, DateTime.utc(2026, 3, 10, 0, 20).toLocal());
    },
  );

  test(
    'a different owner never sees this owner\'s quest or progress (§8, §13)',
    () async {
      await repository.startQuest(
        'owner-1',
        journeyId: 'odyssey-ithaca',
        startedAt: DateTime(2026, 3, 10),
      );

      expect(await repository.loadSelectedQuest('owner-2'), isNull);
    },
  );
}
