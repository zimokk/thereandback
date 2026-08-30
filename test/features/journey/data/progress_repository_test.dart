import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  test('a freshly started quest loads back with zero progress and the '
      'lastSyncedAt seeded to the exact moment it started (§5.2) — steps '
      'taken earlier that same day are never counted', () async {
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
    expect(quest.lastSyncedAt, startedAt);
  });

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

  group('recentMeteredIntervals (§5.3 — raw history for the pace window)', () {
    test('an interval ending before `since` is excluded', () async {
      await db
          .into(db.stepIntervalRecords)
          .insert(
            StepIntervalRecordsCompanion.insert(
              ownerId: 'owner-1',
              journeyId: 'odyssey-ithaca',
              intervalStart: DateTime.utc(2026, 3, 1),
              intervalEnd: DateTime.utc(2026, 3, 1, 0, 10),
              steps: 100,
              resolvedMeters: 75,
              syncedAt: DateTime.utc(2026, 3, 1, 0, 10),
            ),
          );

      final result = await repository.recentMeteredIntervals(
        'owner-1',
        journeyId: 'odyssey-ithaca',
        since: DateTime.utc(2026, 3, 5),
      );

      expect(result, isEmpty);
    });

    test('returns matching intervals converted back to local time, ignoring '
        'other owners and other journeys', () async {
      await db
          .into(db.stepIntervalRecords)
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
      // A different owner — must never show up in owner-1's history.
      await db
          .into(db.stepIntervalRecords)
          .insert(
            StepIntervalRecordsCompanion.insert(
              ownerId: 'owner-2',
              journeyId: 'odyssey-ithaca',
              intervalStart: DateTime.utc(2026, 3, 10),
              intervalEnd: DateTime.utc(2026, 3, 10, 0, 10),
              steps: 100,
              resolvedMeters: 75,
              syncedAt: DateTime.utc(2026, 3, 10, 0, 10),
            ),
          );
      // A different, earlier journey for the same owner — must never
      // leak into the current journey's pace window.
      await db
          .into(db.stepIntervalRecords)
          .insert(
            StepIntervalRecordsCompanion.insert(
              ownerId: 'owner-1',
              journeyId: 'some-other-quest',
              intervalStart: DateTime.utc(2026, 3, 10),
              intervalEnd: DateTime.utc(2026, 3, 10, 0, 10),
              steps: 100,
              resolvedMeters: 75,
              syncedAt: DateTime.utc(2026, 3, 10, 0, 10),
            ),
          );

      final result = await repository.recentMeteredIntervals(
        'owner-1',
        journeyId: 'odyssey-ithaca',
        since: DateTime.utc(2026, 3, 1),
      );

      expect(result, hasLength(1));
      expect(result.single.meters, 75);
      expect(result.single.end, DateTime.utc(2026, 3, 10, 0, 10).toLocal());
    });
  });

  group('restoreFromCloud (§8, §14 — "repeat login")', () {
    test(
      'a fresh owner with no prior quest loads the cloud total back',
      () async {
        final startedAt = DateTime.utc(2026, 3, 1);
        final asOf = DateTime.utc(2026, 3, 10);

        await repository.restoreFromCloud(
          'owner-1',
          journeyId: 'odyssey-ithaca',
          startedAt: startedAt,
          meters: 5230,
          asOf: asOf,
        );

        final quest = await repository.loadSelectedQuest('owner-1');
        expect(quest, isNotNull);
        expect(quest!.journeyId, 'odyssey-ithaca');
        expect(quest.startedAt, startedAt.toLocal());
        expect(quest.progressMeters, 5230);
        expect(quest.lastSyncedAt, asOf.toLocal());
      },
    );

    test('clears this owner+journey\'s existing intervals first — the old '
        'local total never keeps summing alongside the restored one', () async {
      await repository.startQuest(
        'owner-1',
        journeyId: 'odyssey-ithaca',
        startedAt: DateTime.utc(2026, 3, 1),
      );
      await db
          .into(db.stepIntervalRecords)
          .insert(
            StepIntervalRecordsCompanion.insert(
              ownerId: 'owner-1',
              journeyId: 'odyssey-ithaca',
              intervalStart: DateTime.utc(2026, 3, 1),
              intervalEnd: DateTime.utc(2026, 3, 1, 0, 10),
              steps: 100,
              resolvedMeters: 75,
              syncedAt: DateTime.utc(2026, 3, 1, 0, 10),
            ),
          );

      await repository.restoreFromCloud(
        'owner-1',
        journeyId: 'odyssey-ithaca',
        startedAt: DateTime.utc(2026, 3, 5),
        meters: 400000,
        asOf: DateTime.utc(2026, 3, 20),
      );

      final quest = await repository.loadSelectedQuest('owner-1');
      // Not 400075 — the pre-restore 75 m local interval must be gone,
      // not summed alongside the cloud total.
      expect(quest!.progressMeters, 400000);
    });

    test(
      'a zero cloud total seeds no interval row, so the next real sync\'s '
      'own intervalStart (== lastSyncedAt) never collides with a seed row '
      'at the same instant and gets silently dropped by insertOrIgnore',
      () async {
        final startedAt = DateTime.utc(2026, 3, 1);

        await repository.restoreFromCloud(
          'owner-1',
          journeyId: 'odyssey-ithaca',
          startedAt: startedAt,
          meters: 0,
          asOf: startedAt,
        );

        final quest = await repository.loadSelectedQuest('owner-1');
        expect(quest!.progressMeters, 0);
        expect(quest.lastSyncedAt, startedAt.toLocal());

        final rows = await db.select(db.stepIntervalRecords).get();
        expect(rows, isEmpty);
      },
    );

    test(
      'a real sync recorded right after a non-zero restore is not dropped '
      'by the idempotency key — its intervalStart (the restore\'s asOf) '
      'never collides with the seed row\'s own intervalStart (startedAt)',
      () async {
        final startedAt = DateTime.utc(2026, 3, 1);
        final asOf = DateTime.utc(2026, 3, 10);

        await repository.restoreFromCloud(
          'owner-1',
          journeyId: 'odyssey-ithaca',
          startedAt: startedAt,
          meters: 5000,
          asOf: asOf,
        );

        final inserted = await db
            .into(db.stepIntervalRecords)
            .insertReturningOrNull(
              StepIntervalRecordsCompanion.insert(
                ownerId: 'owner-1',
                journeyId: 'odyssey-ithaca',
                intervalStart: asOf,
                intervalEnd: DateTime.utc(2026, 3, 10, 0, 10),
                steps: 100,
                resolvedMeters: 75,
                syncedAt: DateTime.utc(2026, 3, 10, 0, 10),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        expect(inserted, isNotNull);

        final quest = await repository.loadSelectedQuest('owner-1');
        expect(quest!.progressMeters, 5075);
      },
    );

    test('a different owner\'s progress is untouched by a restore', () async {
      await repository.startQuest(
        'owner-2',
        journeyId: 'odyssey-ithaca',
        startedAt: DateTime.utc(2026, 3, 1),
      );
      await db
          .into(db.stepIntervalRecords)
          .insert(
            StepIntervalRecordsCompanion.insert(
              ownerId: 'owner-2',
              journeyId: 'odyssey-ithaca',
              intervalStart: DateTime.utc(2026, 3, 1),
              intervalEnd: DateTime.utc(2026, 3, 1, 0, 10),
              steps: 100,
              resolvedMeters: 75,
              syncedAt: DateTime.utc(2026, 3, 1, 0, 10),
            ),
          );

      await repository.restoreFromCloud(
        'owner-1',
        journeyId: 'odyssey-ithaca',
        startedAt: DateTime.utc(2026, 3, 5),
        meters: 400000,
        asOf: DateTime.utc(2026, 3, 20),
      );

      final other = await repository.loadSelectedQuest('owner-2');
      expect(other!.progressMeters, 75);
    });
  });
}
