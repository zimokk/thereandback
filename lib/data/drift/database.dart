import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

/// The single "currently active quest" row per local owner (CLAUDE.md §5.2,
/// §8): which quest, and when the user started it. Deliberately does
/// **not** store `progressMeters` or `lastSyncedAt` as their own mutable
/// columns — §5.2 says "work with deltas, not an accumulated total", so
/// both are *derived* from [StepIntervalRecords] at read time
/// (`progress_repository.dart`'s `loadSelectedQuest`). A single durable
/// write path (recording an interval) is inherently atomic and can never
/// drift out of sync with a separately-updated running total.
///
/// `ownerId` is a placeholder until Phase 8 wires Firebase Auth
/// (`core/local_owner.dart`) — every row today belongs to the one constant
/// local owner, one device, no multi-account support. MVP has no concurrent
/// multi-quest (§6.4), so unlike Firestore's future
/// `users/{uid}/progress/{journeyId}` this table keys on `ownerId` alone,
/// not `(ownerId, journeyId)`: starting a new quest overwrites the row
/// rather than adding a second one. (A previous journey's interval history
/// is untouched, though — nothing here reads it once a different
/// `journeyId` is active. Surfacing it as completed-quest history is Phase
/// 10 scope, §6.1 point 3.)
///
/// [startedAt] is stored as UTC (§5.2) — the local-to-UTC conversion
/// happens at the repository boundary, never in `domain/` or here.
class SelectedQuestRows extends Table {
  TextColumn get ownerId => text()();
  TextColumn get journeyId => text()();
  DateTimeColumn get startedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {ownerId};
}

/// Idempotency log for synced step intervals (§5.2): one row per
/// `(ownerId, journeyId, intervalStart)`. This **is** the progress store —
/// `progress_repository.dart` derives `progressMeters` as
/// `SUM(resolvedMeters)` and `lastSyncedAt` as `MAX(intervalEnd)` over these
/// rows, rather than keeping either as separate mutable state.
/// `features/steps/data/step_sample_repository.dart` inserts with
/// [InsertMode.insertOrIgnore] and checks whether a row was actually added
/// before crediting anything — a repeated sync of the same interval can
/// never double progress, even across an app restart that lost in-memory
/// state, or a race between two overlapping sync calls.
class StepIntervalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerId => text()();
  TextColumn get journeyId => text()();
  DateTimeColumn get intervalStart => dateTime()();
  DateTimeColumn get intervalEnd => dateTime()();
  IntColumn get steps => integer()();
  IntColumn get walkingDistanceMeters => integer().nullable()();
  IntColumn get resolvedMeters => integer()();
  BoolColumn get flaggedPace => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {ownerId, journeyId, intervalStart},
  ];
}

/// Whether the lock-screen/notification-shade toggle (§7) is turned on, per
/// local owner. `LockScreenState.enabled` (the in-memory Riverpod state) is
/// **not** durable on its own — a fresh `LockScreenController.build()`
/// after an app restart used to reset straight to `enabled: false` no
/// matter what the previous session had, which meant a permission revoked
/// while the app was closed was never detected: `refreshStatus()`'s
/// `if (state.enabled && !granted) revoke()` check never fired, because
/// `state.enabled` didn't know the feature had actually been on. This row
/// is read back into `state.enabled` before that first `refreshStatus()`
/// runs, the same way [SelectedQuestRows] is read back into
/// `selectedJourneyProvider` on restart.
///
/// The real notification and `workmanager` periodic task are OS-owned and
/// keep running across an app restart on their own either way — this row
/// only makes the *app's own* state agree with that reality again, so the
/// existing revoke-on-permission-loss logic actually gets a chance to run.
class LockScreenPreferenceRows extends Table {
  TextColumn get ownerId => text()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column> get primaryKey => {ownerId};
}

/// Durable store for the handful of Настройки toggles that used to reset to
/// their in-memory default on every cold start (§6.5, §14 — "сохраняй
/// настройки пользователя... чтобы при перезапуске приложения всё
/// загружалось как было настроено"): language, theme pin, background music,
/// friends-on-map. One row per local owner, same shape as
/// [LockScreenPreferenceRows] — just with four independent columns instead
/// of one, since these are four independent Настройки toggles that happen
/// to be cheap enough to share a single row rather than four single-column
/// tables.
///
/// Every column is nullable/defaulted to exactly the value its provider's
/// own in-memory default already was — `false` for the two toggles,
/// `null` (→ "use the caller's own default") for the two text columns — so
/// a device that has never written this row (fresh install, or one that
/// upgraded from before this table existed) behaves exactly as it did
/// before this table existed.
///
/// [localeCode] stores [Locale.languageCode] (`'ru'`/`'en'`, §11 — only
/// those two); [themeOverride] stores [AppThemeId.name] or `null` for
/// "follow the active quest" (§6.5, §14 "themes") — both are read back
/// through `UserPreferenceRepository`'s own parsing, never raw here, so an
/// unrecognized value from a future downgrade/rollback falls back to the
/// same default as "never set" instead of crashing.
class UserPreferenceRows extends Table {
  TextColumn get ownerId => text()();
  TextColumn get localeCode => text().nullable()();
  TextColumn get themeOverride => text().nullable()();
  BoolColumn get backgroundMusicEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showFriendsOnMap =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {ownerId};
}

/// One durable "this trophy was earned" event (§6.3, extended by the daily-
/// trophies task: trophies persisted in the DB, not only derived live from
/// current progress every time the Трофеи tab opens). `achievementId` is
/// either a quest achievement's catalog id or a daily achievement's
/// (`features/achievements/data/achievement_catalog.dart`'s
/// `achievementCatalog`/`dailyAchievementCatalog`) — one table serves both
/// Трофеи sections.
///
/// [unlockedLocalDate] is **not** a UTC instant like every other DateTime
/// column in this database (§5.2) — it encodes a local calendar date (the
/// date's own year/month/day, stored as that same triple at UTC midnight so
/// no timezone conversion can shift it), because "which day this was
/// earned" is what the UI shows, never a moment in time. Written and read
/// back by `DriftAchievementRepository`'s own conversion helpers — nothing
/// else should read or write this column directly.
///
/// A quest achievement earns at most one row ever (its unlock date, once
/// found, never changes); a daily achievement (1/5/10/20/50 km in a day)
/// can earn one row per calendar day it was reached — the primary key
/// allows exactly that, and doubles as the idempotency guard
/// `AchievementRepository.refreshUnlocks`'s `insertOrIgnore` relies on.
class AchievementUnlockRows extends Table {
  TextColumn get ownerId => text()();
  TextColumn get achievementId => text()();
  DateTimeColumn get unlockedLocalDate => dateTime()();

  @override
  Set<Column> get primaryKey => {ownerId, achievementId, unlockedLocalDate};
}

/// The app's local database (§8: drift/SQLite is the offline-first source
/// of truth; Firestore is a sync layer added later, never the only store).
///
/// Construct with no argument for the real, file-backed database (see
/// [_openConnection]); use [AppDatabase.forTesting] to get an in-memory
/// instance instead (`testing` skill: never a real drift database in a
/// test — always an explicit in-memory override via
/// `app/database_provider.dart`'s `appDatabaseProvider`).
@DriftDatabase(
  tables: [
    SelectedQuestRows,
    StepIntervalRecords,
    LockScreenPreferenceRows,
    AchievementUnlockRows,
    UserPreferenceRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// An in-memory database for tests — never persists to disk, never
  /// touches `path_provider`.
  factory AppDatabase.forTesting() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

  // v1 → v2: added LockScreenPreferenceRows (see its doc comment).
  // v2 → v3: added AchievementUnlockRows (see its doc comment).
  // v3 → v4: added UserPreferenceRows (see its doc comment). All purely
  // additive migrations — existing rows in every earlier table are
  // untouched; a device upgrading from an older version just gets the new
  // table(s) created empty, same as a fresh install.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(lockScreenPreferenceRows);
      }
      if (from < 3) {
        await m.createTable(achievementUnlockRows);
      }
      if (from < 4) {
        await m.createTable(userPreferenceRows);
      }
    },
  );

  // Explicit UTC-as-text storage (§5.2) — sidesteps sqlite's lack of a
  // native DateTime type and the ambiguity of drift's legacy unix-epoch
  // mode. Every DateTime handed to this database must already be `.toUtc()`
  // (enforced at the repository boundary, not here).
  @override
  DriftDatabaseOptions options = const DriftDatabaseOptions(
    storeDateTimeAsText: true,
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'thereandback.sqlite'));

    // sqlite needs a writable scratch directory for complex queries; the
    // app sandbox's default temp location isn't always writable on iOS
    // (drift's own "platforms" setup note).
    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

    return NativeDatabase.createInBackground(file);
  });
}
