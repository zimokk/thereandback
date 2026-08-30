import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/achievements/data/achievement_repository.dart';

void main() {
  late AppDatabase db;
  late AchievementRepository repository;

  setUp(() {
    // `testing` skill: never a real drift database in a test.
    db = AppDatabase.forTesting();
    repository = DriftAchievementRepository(db);
  });
  tearDown(() => db.close());

  Future<void> recordInterval({
    required String journeyId,
    required DateTime end,
    required int meters,
  }) {
    return db
        .into(db.stepIntervalRecords)
        .insert(
          StepIntervalRecordsCompanion.insert(
            ownerId: 'owner-1',
            journeyId: journeyId,
            intervalStart: end.subtract(const Duration(hours: 1)),
            intervalEnd: end,
            steps: 0,
            resolvedMeters: meters,
            syncedAt: end,
          ),
        );
  }

  test('an owner with no history has no unlocks', () async {
    await repository.refreshUnlocks(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
    );
    expect(await repository.loadUnlocks('owner-1'), isEmpty);
  });

  test('crossing a quest threshold records the day it happened', () async {
    await recordInterval(
      journeyId: 'odyssey-ithaca',
      end: DateTime.utc(2026, 3, 10, 12),
      meters: 1000, // crosses "first-steps" (1000 m).
    );

    await repository.refreshUnlocks(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
    );
    final unlocks = await repository.loadUnlocks('owner-1');

    // The repository stores/reads back a *local calendar date* (see
    // `AchievementUnlockRows.unlockedLocalDate`'s doc comment) — plain
    // `DateTime(y, m, d)`, never a `.toLocal()`-shifted instant.
    expect(unlocks['first-steps'], [DateTime(2026, 3, 10)]);
  });

  test('a daily threshold crossed on two different days records both — '
      'this is what lets the same daily trophy repeat', () async {
    await recordInterval(
      journeyId: 'odyssey-ithaca',
      end: DateTime.utc(2026, 3, 10, 12),
      meters: 1200, // crosses "daily-1km" (1000 m) on day 1.
    );
    await recordInterval(
      journeyId: 'odyssey-ithaca',
      end: DateTime.utc(2026, 3, 12, 12),
      meters: 1500, // crosses "daily-1km" again on day 3.
    );

    await repository.refreshUnlocks(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
    );
    final unlocks = await repository.loadUnlocks('owner-1');

    expect(unlocks['daily-1km'], [
      DateTime(2026, 3, 10),
      DateTime(2026, 3, 12),
    ]);
  });

  test('daily achievements count steps across every journey, quest '
      'achievements only this journey\'s own history', () async {
    await recordInterval(
      journeyId: 'odyssey-ithaca',
      end: DateTime.utc(2026, 3, 10, 6),
      meters: 600,
    );
    await recordInterval(
      journeyId: 'some-other-quest',
      end: DateTime.utc(2026, 3, 10, 12),
      meters: 600, // 600 + 600 = 1200 m same day, across two quests.
    );

    await repository.refreshUnlocks(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
    );
    final unlocks = await repository.loadUnlocks('owner-1');

    // Daily: sees both journeys' steps together, crosses 1000 m.
    expect(unlocks['daily-1km'], [DateTime(2026, 3, 10)]);
    // Quest ("odyssey-ithaca" only): 600 m alone never reaches 1000 m.
    expect(unlocks.containsKey('first-steps'), isFalse);
  });

  test(
    'refreshing twice never duplicates a recorded unlock (idempotency)',
    () async {
      await recordInterval(
        journeyId: 'odyssey-ithaca',
        end: DateTime.utc(2026, 3, 10),
        meters: 1000,
      );

      await repository.refreshUnlocks(
        ownerId: 'owner-1',
        journeyId: 'odyssey-ithaca',
      );
      await repository.refreshUnlocks(
        ownerId: 'owner-1',
        journeyId: 'odyssey-ithaca',
      );

      final unlocks = await repository.loadUnlocks('owner-1');
      expect(unlocks['first-steps'], hasLength(1));
    },
  );

  test('a different owner never sees another owner\'s unlocks', () async {
    await recordInterval(
      journeyId: 'odyssey-ithaca',
      end: DateTime.utc(2026, 3, 10),
      meters: 1000,
    );
    await repository.refreshUnlocks(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
    );

    expect(await repository.loadUnlocks('owner-2'), isEmpty);
  });
}
