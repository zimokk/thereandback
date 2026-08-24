import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';

/// Schema sanity for Phase 3 (`testing` skill: "drift schema migration
/// test"). `schemaVersion` is 1 — the first shipped schema — so there is no
/// migration *step* to exercise yet; a real migration test (old schema →
/// new schema, verified with `package:drift_dev`'s schema tooling) lands the
/// first time `schemaVersion` bumps past 1 (see the `codegen` skill's
/// "Drift migration test fails" row). This locks in today's baseline so
/// that future change is visible as a diff, not a surprise.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  test('schemaVersion is 1 — the first shipped schema', () {
    expect(db.schemaVersion, 1);
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
}
