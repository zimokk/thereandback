import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';

/// Schema sanity for Phase 3 (`testing` skill: "drift schema migration
/// test"). The real migration test itself (old schema → new schema,
/// verified with `package:drift_dev`'s schema tooling) is
/// `migration_test.dart`, alongside this file — it started once
/// `schemaVersion` first bumped past 1 (see the `codegen` skill's "Drift
/// migration test fails" row). This file locks in today's table-shape
/// baseline so a future change is visible as a diff, not a surprise.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  test('schemaVersion is 5 — JourneyAssetRows added on top of the v4 '
      'baseline (see migration_test.dart)', () {
    expect(db.schemaVersion, 5);
  });

  test('selectedQuestRows round-trips a row, keyed on ownerId', () async {
    await db
        .into(db.selectedQuestRows)
        .insert(
          SelectedQuestRowsCompanion.insert(
            ownerId: 'owner-1',
            journeyId: 'odyssey-ithaca',
            startedAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final row = await (db.select(
      db.selectedQuestRows,
    )..where((t) => t.ownerId.equals('owner-1'))).getSingle();

    expect(row.journeyId, 'odyssey-ithaca');
    expect(row.startedAt, DateTime.utc(2026, 1, 1));
  });

  test('starting a new quest for the same owner overwrites the row (§6.4: no '
      'concurrent multi-quest)', () async {
    final companion = SelectedQuestRowsCompanion.insert(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
      startedAt: DateTime.utc(2026, 1, 1),
    );
    await db.into(db.selectedQuestRows).insertOnConflictUpdate(companion);
    await db
        .into(db.selectedQuestRows)
        .insertOnConflictUpdate(
          SelectedQuestRowsCompanion.insert(
            ownerId: 'owner-1',
            journeyId: 'a-different-quest',
            startedAt: DateTime.utc(2026, 2, 1),
          ),
        );

    final rows = await db.select(db.selectedQuestRows).get();
    expect(rows, hasLength(1));
    expect(rows.single.journeyId, 'a-different-quest');
  });

  test('stepIntervalRecords enforces the (ownerId, journeyId, intervalStart) '
      'unique key (§5.2)', () async {
    final companion = StepIntervalRecordsCompanion.insert(
      ownerId: 'owner-1',
      journeyId: 'odyssey-ithaca',
      intervalStart: DateTime.utc(2026, 1, 1),
      intervalEnd: DateTime.utc(2026, 1, 1, 0, 10),
      steps: 100,
      resolvedMeters: 75,
      syncedAt: DateTime.utc(2026, 1, 1, 0, 10),
    );

    final first = await db
        .into(db.stepIntervalRecords)
        .insertReturningOrNull(companion, mode: InsertMode.insertOrIgnore);
    final second = await db
        .into(db.stepIntervalRecords)
        .insertReturningOrNull(companion, mode: InsertMode.insertOrIgnore);

    expect(first, isNotNull);
    expect(second, isNull);
    expect(await db.select(db.stepIntervalRecords).get(), hasLength(1));
  });

  test('lockScreenPreferenceRows round-trips a row, keyed on ownerId, and '
      'a second write for the same owner overwrites rather than adding a '
      'row', () async {
    await db
        .into(db.lockScreenPreferenceRows)
        .insertOnConflictUpdate(
          LockScreenPreferenceRowsCompanion.insert(
            ownerId: 'owner-1',
            enabled: true,
          ),
        );
    await db
        .into(db.lockScreenPreferenceRows)
        .insertOnConflictUpdate(
          LockScreenPreferenceRowsCompanion.insert(
            ownerId: 'owner-1',
            enabled: false,
          ),
        );

    final rows = await db.select(db.lockScreenPreferenceRows).get();
    expect(rows, hasLength(1));
    expect(rows.single.enabled, isFalse);
  });

  test('achievementUnlockRows allows one row per (ownerId, achievementId, '
      'unlockedLocalDate) — a daily trophy earning the same threshold '
      'again on a different day is a second row, not an overwrite', () async {
    await db
        .into(db.achievementUnlockRows)
        .insert(
          AchievementUnlockRowsCompanion.insert(
            ownerId: 'owner-1',
            achievementId: 'daily-1km',
            unlockedLocalDate: DateTime.utc(2026, 3, 10),
          ),
        );
    await db
        .into(db.achievementUnlockRows)
        .insert(
          AchievementUnlockRowsCompanion.insert(
            ownerId: 'owner-1',
            achievementId: 'daily-1km',
            unlockedLocalDate: DateTime.utc(2026, 3, 12),
          ),
        );

    final rows = await (db.select(
      db.achievementUnlockRows,
    )..where((t) => t.ownerId.equals('owner-1'))).get();
    expect(rows, hasLength(2));
  });

  test('userPreferenceRows round-trips a row, keyed on ownerId, and a '
      'second write for the same owner overwrites rather than adding a '
      'row (§14 — persisted Настройки toggles)', () async {
    await db
        .into(db.userPreferenceRows)
        .insertOnConflictUpdate(
          UserPreferenceRowsCompanion.insert(
            ownerId: 'owner-1',
            localeCode: const Value('en'),
            backgroundMusicEnabled: const Value(true),
          ),
        );
    await db
        .into(db.userPreferenceRows)
        .insertOnConflictUpdate(
          UserPreferenceRowsCompanion.insert(
            ownerId: 'owner-1',
            localeCode: const Value('ru'),
            backgroundMusicEnabled: const Value(false),
          ),
        );

    final rows = await db.select(db.userPreferenceRows).get();
    expect(rows, hasLength(1));
    expect(rows.single.localeCode, 'ru');
    expect(rows.single.backgroundMusicEnabled, isFalse);
  });

  test('journeyAssetRows round-trips a row, keyed on (ownerId, journeyId), '
      'and a second write for the same pair overwrites rather than adding '
      'a row (§8, §14 — on-demand quest content)', () async {
    await db
        .into(db.journeyAssetRows)
        .insertOnConflictUpdate(
          JourneyAssetRowsCompanion.insert(
            ownerId: 'owner-1',
            journeyId: 'some-quest',
            assetsVersion: 1,
            downloadedAt: DateTime.utc(2026, 9, 4),
          ),
        );
    await db
        .into(db.journeyAssetRows)
        .insertOnConflictUpdate(
          JourneyAssetRowsCompanion.insert(
            ownerId: 'owner-1',
            journeyId: 'some-quest',
            assetsVersion: 2,
            downloadedAt: DateTime.utc(2026, 9, 5),
          ),
        );

    final rows = await db.select(db.journeyAssetRows).get();
    expect(rows, hasLength(1));
    expect(rows.single.assetsVersion, 2);
    expect(rows.single.downloadedAt, DateTime.utc(2026, 9, 5));
  });
}
