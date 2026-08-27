import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';

import '../../generated_migrations/schema.dart';
import '../../generated_migrations/schema_v1.dart' as v1;

/// The real drift schema migration test `app_database_test.dart` promised
/// would land once `schemaVersion` moved past 1 (§12, Phase 3's "drift
/// schema migration test"). Snapshots regenerated via `dart run drift_dev
/// schema dump lib/data/drift/database.dart drift_schemas/` (v1, before
/// `LockScreenPreferenceRows` existed, and again after adding it for v2);
/// `dart run drift_dev schema generate --data-classes --companions
/// drift_schemas/ test/generated_migrations/` produced the versioned
/// schema classes (`v1.DatabaseAtV1` etc.) this file verifies against.
///
/// Uses `SchemaVerifier.testWithDataIntegrity` rather than opening one
/// connection by hand and reusing it across database wrappers: drift's
/// migration handshake only runs on a connection's *first* open, so
/// re-wrapping an already-opened connection in a new `GeneratedDatabase`
/// silently skips `MigrationStrategy.onUpgrade` entirely — this helper
/// hands each wrapper (old-schema writer, migration target, post-migration
/// reader) its own fresh connection onto the same underlying database.
///
/// `validateColumnConstraints: false`: `drift_dev schema dump` doesn't see
/// this database's `storeDateTimeAsText: true` runtime option (that's a
/// `DriftDatabaseOptions` field this class sets, not something the static
/// dump tool executes), so the generated `v1`/`v2` helper classes declare
/// `DateTime` columns as plain `int` — a real mismatch against this app's
/// actual `TEXT`-stored columns that has nothing to do with whether the
/// migration step itself is correct, and would otherwise fail strict
/// column-type comparison. Table/column *existence* is still validated;
/// only the exact-constraint-text comparison is relaxed.
void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  test(
    'v1 → v2 preserves existing data and the new table works',
    () => verifier.testWithDataIntegrity<v1.DatabaseAtV1, AppDatabase>(
      createOld: v1.DatabaseAtV1.new,
      createNew: AppDatabase.new,
      openTestedDatabase: AppDatabase.new,
      // Raw SQL, not `v1.SelectedQuestRowsCompanion`: the generated `v1`
      // helper models `startedAt` as a plain `int` (see this file's top
      // comment), but the column this app's real `AppDatabase` actually
      // created at v1 stores it as ISO-8601 text. Using the wrongly-typed
      // helper to write the fixture would create data no real v1 install
      // could have had, and the read-back in `validateItems` below would
      // fail on a format it never needed to handle.
      createItems: (batch, oldDb) => batch.customStatement(
        'INSERT INTO selected_quest_rows (owner_id, journey_id, started_at) '
        'VALUES (?, ?, ?)',
        [
          'owner-1',
          'odyssey-ithaca',
          DateTime.utc(2026, 1, 1).toIso8601String(),
        ],
      ),
      validateItems: (newDb) async {
        // The table that already existed at v1 — the migration must have
        // left it untouched.
        final rows = await newDb.select(newDb.selectedQuestRows).get();
        expect(rows, hasLength(1));
        expect(rows.single.journeyId, 'odyssey-ithaca');
        expect(rows.single.startedAt, DateTime.utc(2026, 1, 1));

        // The new table exists and is usable post-migration — the actual
        // point of adding it.
        await newDb
            .into(newDb.lockScreenPreferenceRows)
            .insertOnConflictUpdate(
              LockScreenPreferenceRowsCompanion.insert(
                ownerId: 'owner-1',
                enabled: true,
              ),
            );
        final preference = await (newDb.select(
          newDb.lockScreenPreferenceRows,
        )..where((t) => t.ownerId.equals('owner-1'))).getSingle();
        expect(preference.enabled, isTrue);
      },
      oldVersion: 1,
      newVersion: 2,
      options: const ValidationOptions(validateColumnConstraints: false),
    ),
  );

  test('a fresh (never-migrated) database opens directly at the latest '
      'schema and has the new table available immediately', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.lockScreenPreferenceRows)
        .insertOnConflictUpdate(
          LockScreenPreferenceRowsCompanion.insert(
            ownerId: 'owner-1',
            enabled: false,
          ),
        );
    final row = await (db.select(
      db.lockScreenPreferenceRows,
    )..where((t) => t.ownerId.equals('owner-1'))).getSingle();
    expect(row.enabled, isFalse);
    await db.close();
  });
}
