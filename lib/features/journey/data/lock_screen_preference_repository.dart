import '../../../data/drift/database.dart';

/// Durable store for whether the lock-screen/notification-shade toggle is
/// on, per local owner (§7). See [LockScreenPreferenceRows] for why this
/// needs to be durable at all — the short version: `LockScreenState.enabled`
/// alone forgets everything on an app restart, so a permission revoked
/// while the app was closed was never detected.
abstract class LockScreenPreferenceRepository {
  /// `false` if nothing has ever been saved for [ownerId] (fresh install,
  /// or the feature was never turned on) — same default as
  /// [LockScreenState.enabled].
  Future<bool> loadEnabled(String ownerId);

  Future<void> saveEnabled(String ownerId, bool enabled);
}

class DriftLockScreenPreferenceRepository
    implements LockScreenPreferenceRepository {
  DriftLockScreenPreferenceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<bool> loadEnabled(String ownerId) async {
    final row = await (_db.select(
      _db.lockScreenPreferenceRows,
    )..where((t) => t.ownerId.equals(ownerId))).getSingleOrNull();
    return row?.enabled ?? false;
  }

  @override
  Future<void> saveEnabled(String ownerId, bool enabled) {
    return _db
        .into(_db.lockScreenPreferenceRows)
        .insertOnConflictUpdate(
          LockScreenPreferenceRowsCompanion.insert(
            ownerId: ownerId,
            enabled: enabled,
          ),
        );
  }
}
