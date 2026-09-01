import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';

import '../../generated_migrations/schema.dart';
import '../../generated_migrations/schema_v1.dart' as v1;
import '../../generated_migrations/schema_v2.dart' as v2;
import '../../generated_migrations/schema_v3.dart' as v3;

/// The real drift schema migration test `app_database_test.dart` promised
/// would land once `schemaVersion` moved past 1 (§12, Phase 3's "drift
/// schema migration test"). Snapshots regenerated via `dart run drift_dev
/// schema dump lib/data/drift/database.dart drift_schemas/` (v1, before
/// `LockScreenPreferenceRows` existed; v2, after adding it; v3, after
/// adding `AchievementUnlockRows`); `dart run drift_dev schema generate
/// --data-classes --companions drift_schemas/ test/generated_migrations/`
/// produced the versioned schema classes (`v1.DatabaseAtV1` etc.) this file
/// verifies against.
///
/// Uses `SchemaVerifier.testWithDataIntegrity` rather than opening one
/// connection by hand and reusing it across database wrappers: drift's
/// migration handshake only runs on a connection's *first* open, so
/// re-wrapping an already-opened connection in a new `GeneratedDatabase`
/// silently skips `MigrationStrategy.onUpgrade` entirely — this helper
/// hands each wrapper (old-schema writer, migration target, post-migration
/// reader) its own fresh connection onto the same underlying database.
///
/// `build.yaml`'s `store_date_time_values_as_text: true` (must match this
/// database's own `storeDateTimeAsText: true` runtime option) is what makes
/// `drift_dev schema dump` capture `DateTime` columns' real on-disk type —
/// without it, dumped snapshots wrongly bake in `INTEGER` (drift's default)
/// for a column this app actually stores as `TEXT`, which fails the v2 → v3
/// test below the moment a migration adds a table with its own `DateTime`
/// column (`AchievementUnlockRows` was the first; neither v1 → v2's only
/// new table, `LockScreenPreferenceRows`, nor a "fresh install" test happen
/// to touch one). `drift_schemas/drift_schema_v1.json` and `_v2.json`
/// predate `build.yaml` and were hand-corrected once (their frozen
/// `fixed_sql` literally said `INTEGER` for `started_at`/`interval_start`/
/// `interval_end`/`synced_at` — a wrong recording of a setting that was
/// always `true` at runtime, not a real historical schema difference)
/// rather than re-dumped, since re-dumping needs `database.dart` checked
/// out as it existed at each of those versions.
///
/// `validateColumnConstraints: false`: even with the above fix, the
/// generated `v1`/`v2`/`v3` helper classes expose a `DateTime` column as a
/// raw `String` (the storage primitive), never a real `DateTime` — a
/// mismatch against this app's actual typed columns that has nothing to do
/// with whether the migration step itself is correct, and would otherwise
/// fail strict constraint-text comparison. Table/column *existence* and
/// *type* are still validated; only the exact-constraint-text comparison is
/// relaxed.
void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  test(
    'v1 → v2 preserves existing data and the new table works',
    () => verifier.testWithDataIntegrity<v1.DatabaseAtV1, AppDatabase>(
      createOld: v1.DatabaseAtV1.new,
      createNew: AppDatabase.new,
      openTestedDatabase: AppDatabase.new,
      // Raw SQL, not `v1.SelectedQuestRowsCompanion`: the generated `v1`
      // helper models `startedAt` as a plain `String` (see this file's top
      // comment) — the raw ISO-8601 text this app's real `AppDatabase`
      // actually stores, but with no `DateTime` parsing/formatting applied
      // by the helper itself. Passing a `DateTime` there would need
      // `.toIso8601String()` first either way, so this stays explicit raw
      // SQL for symmetry with `validateItems`' own read-back below.
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

  test(
    'v2 → v3 preserves existing data and the new AchievementUnlockRows '
    'table works',
    () => verifier.testWithDataIntegrity<v2.DatabaseAtV2, AppDatabase>(
      createOld: v2.DatabaseAtV2.new,
      createNew: AppDatabase.new,
      openTestedDatabase: AppDatabase.new,
      // `enabled: 1`, not `true`: the schema-dump tool models `BoolColumn`
      // as a raw `int` in this generated helper (same class of quirk as
      // this file's top comment already documents for `DateTime` columns)
      // — the real `AppDatabase`'s own generated table still exposes it as
      // a proper `bool`, which `validateItems` below reads back.
      createItems: (batch, oldDb) => batch.insert(
        oldDb.lockScreenPreferenceRows,
        v2.LockScreenPreferenceRowsCompanion.insert(
          ownerId: 'owner-1',
          enabled: 1,
        ),
      ),
      validateItems: (newDb) async {
        // The table that already existed at v2 — the migration must have
        // left it untouched.
        final rows = await newDb.select(newDb.lockScreenPreferenceRows).get();
        expect(rows, hasLength(1));
        expect(rows.single.enabled, isTrue);

        // The new table exists and is usable post-migration — the actual
        // point of adding it.
        await newDb
            .into(newDb.achievementUnlockRows)
            .insert(
              AchievementUnlockRowsCompanion.insert(
                ownerId: 'owner-1',
                achievementId: 'first-steps',
                unlockedLocalDate: DateTime.utc(2026, 3, 10),
              ),
            );
        final unlock = await (newDb.select(
          newDb.achievementUnlockRows,
        )..where((t) => t.ownerId.equals('owner-1'))).getSingle();
        expect(unlock.achievementId, 'first-steps');
        expect(unlock.unlockedLocalDate, DateTime.utc(2026, 3, 10));
      },
      oldVersion: 2,
      newVersion: 3,
      options: const ValidationOptions(validateColumnConstraints: false),
    ),
  );

  test('a fresh (never-migrated) database has AchievementUnlockRows '
      'available immediately', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.achievementUnlockRows)
        .insert(
          AchievementUnlockRowsCompanion.insert(
            ownerId: 'owner-1',
            achievementId: 'first-steps',
            unlockedLocalDate: DateTime.utc(2026, 3, 10),
          ),
        );
    final row = await (db.select(
      db.achievementUnlockRows,
    )..where((t) => t.ownerId.equals('owner-1'))).getSingle();
    expect(row.achievementId, 'first-steps');
    await db.close();
  });

  test(
    'v3 → v4 preserves existing data and the new UserPreferenceRows table '
    'works — §14, persisted Настройки toggles',
    () => verifier.testWithDataIntegrity<v3.DatabaseAtV3, AppDatabase>(
      createOld: v3.DatabaseAtV3.new,
      createNew: AppDatabase.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) => batch.insert(
        oldDb.lockScreenPreferenceRows,
        v3.LockScreenPreferenceRowsCompanion.insert(
          ownerId: 'owner-1',
          enabled: 1,
        ),
      ),
      validateItems: (newDb) async {
        // The table that already existed at v3 — the migration must have
        // left it untouched.
        final rows = await newDb.select(newDb.lockScreenPreferenceRows).get();
        expect(rows, hasLength(1));
        expect(rows.single.enabled, isTrue);

        // The new table exists and is usable post-migration — the actual
        // point of adding it.
        await newDb
            .into(newDb.userPreferenceRows)
            .insertOnConflictUpdate(
              UserPreferenceRowsCompanion.insert(
                ownerId: 'owner-1',
                localeCode: const Value('en'),
                backgroundMusicEnabled: const Value(true),
              ),
            );
        final preference = await (newDb.select(
          newDb.userPreferenceRows,
        )..where((t) => t.ownerId.equals('owner-1'))).getSingle();
        expect(preference.localeCode, 'en');
        expect(preference.themeOverride, isNull);
        expect(preference.backgroundMusicEnabled, isTrue);
        expect(preference.showFriendsOnMap, isFalse);
      },
      oldVersion: 3,
      newVersion: 4,
      options: const ValidationOptions(validateColumnConstraints: false),
    ),
  );

  test('a fresh (never-migrated) database has UserPreferenceRows available '
      'immediately', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.userPreferenceRows)
        .insertOnConflictUpdate(
          UserPreferenceRowsCompanion.insert(
            ownerId: 'owner-1',
            showFriendsOnMap: const Value(true),
          ),
        );
    final row = await (db.select(
      db.userPreferenceRows,
    )..where((t) => t.ownerId.equals('owner-1'))).getSingle();
    expect(row.showFriendsOnMap, isTrue);
    // Untouched columns keep their own defaults, same as a fresh install
    // that never wrote this row at all.
    expect(row.backgroundMusicEnabled, isFalse);
    expect(row.localeCode, isNull);
    await db.close();
  });
}
