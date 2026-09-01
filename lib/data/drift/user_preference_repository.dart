import 'package:drift/drift.dart';

import '../../core/app_theme_id.dart';
import 'database.dart';

/// Durable store for the handful of Настройки toggles that used to reset to
/// their in-memory default on every cold start (§6.5, §14): the display
/// language, the theme pin, whether background music is on, and whether
/// friends show on the map — all four backed by [UserPreferenceRows]
/// (`database.dart`), one row per local owner, the same shape
/// `LockScreenPreferenceRepository` already proved for a single toggle.
///
/// Every `load*` returns the same in-memory default its provider already
/// used before this repository existed (`false` for the two toggles, `null`
/// — "use the caller's own default" — for locale/theme) when nothing has
/// ever been saved for `ownerId`, so a fresh install or a device upgrading
/// from before this table existed behaves exactly as it did before.
abstract class UserPreferenceRepository {
  /// The saved [Locale.languageCode] (`'ru'`/`'en'`, §11), or `null` if
  /// never set — the caller (`AppLocale.build()`) keeps its own default in
  /// that case.
  Future<String?> loadLocaleCode(String ownerId);

  Future<void> saveLocaleCode(String ownerId, String localeCode);

  /// The saved [AppThemeId.name], parsed back to an [AppThemeId], or `null`
  /// if never set or unrecognized (a future value this build predates) —
  /// both fall back to "follow the active quest" (§6.5, §14 "themes")
  /// rather than crashing.
  Future<AppThemeId?> loadThemeOverride(String ownerId);

  /// `themeOverride: null` persists "follow the active quest" explicitly —
  /// behaviorally identical to never having saved anything, but still a
  /// legitimate user action ("вернуться к теме похода") worth writing
  /// through like any other choice.
  Future<void> saveThemeOverride(String ownerId, AppThemeId? themeOverride);

  Future<bool> loadBackgroundMusicEnabled(String ownerId);

  Future<void> saveBackgroundMusicEnabled(String ownerId, bool enabled);

  Future<bool> loadShowFriendsOnMap(String ownerId);

  Future<void> saveShowFriendsOnMap(String ownerId, bool enabled);
}

class DriftUserPreferenceRepository implements UserPreferenceRepository {
  DriftUserPreferenceRepository(this._db);

  final AppDatabase _db;

  Future<UserPreferenceRow?> _loadRow(String ownerId) {
    return (_db.select(
      _db.userPreferenceRows,
    )..where((t) => t.ownerId.equals(ownerId))).getSingleOrNull();
  }

  @override
  Future<String?> loadLocaleCode(String ownerId) async {
    return (await _loadRow(ownerId))?.localeCode;
  }

  @override
  Future<void> saveLocaleCode(String ownerId, String localeCode) {
    return _upsert(ownerId, localeCode: Value(localeCode));
  }

  @override
  Future<AppThemeId?> loadThemeOverride(String ownerId) async {
    final saved = (await _loadRow(ownerId))?.themeOverride;
    if (saved == null) return null;
    // A value from a future build this one predates (a new AppThemeId
    // added later, then rolled back to this version) falls back to "follow
    // the active quest" instead of throwing — same "never a dead end" bar
    // §7 sets for a bad platform/permission response, applied here to a
    // bad stored value.
    for (final id in AppThemeId.values) {
      if (id.name == saved) return id;
    }
    return null;
  }

  @override
  Future<void> saveThemeOverride(String ownerId, AppThemeId? themeOverride) {
    return _upsert(ownerId, themeOverride: Value(themeOverride?.name));
  }

  @override
  Future<bool> loadBackgroundMusicEnabled(String ownerId) async {
    return (await _loadRow(ownerId))?.backgroundMusicEnabled ?? false;
  }

  @override
  Future<void> saveBackgroundMusicEnabled(String ownerId, bool enabled) {
    return _upsert(ownerId, backgroundMusicEnabled: Value(enabled));
  }

  @override
  Future<bool> loadShowFriendsOnMap(String ownerId) async {
    return (await _loadRow(ownerId))?.showFriendsOnMap ?? false;
  }

  @override
  Future<void> saveShowFriendsOnMap(String ownerId, bool enabled) {
    return _upsert(ownerId, showFriendsOnMap: Value(enabled));
  }

  /// Writes only the field(s) the caller passed a present [Value] for,
  /// leaving the rest of the row exactly as it already was — a
  /// read-modify-write, not a partial `ON CONFLICT DO UPDATE`, deliberately:
  /// every existing `insertOnConflictUpdate` call elsewhere in this codebase
  /// always specifies the *whole* row, so this stays inside that same
  /// proven shape rather than leaning on upsert semantics nothing here has
  /// exercised before. Four independent Настройки toggles changed one at a
  /// time from the Настройки screen, never concurrently by the same user,
  /// so the read-then-write round trip races against nothing that matters
  /// in practice.
  Future<void> _upsert(
    String ownerId, {
    Value<String?> localeCode = const Value.absent(),
    Value<String?> themeOverride = const Value.absent(),
    Value<bool> backgroundMusicEnabled = const Value.absent(),
    Value<bool> showFriendsOnMap = const Value.absent(),
  }) async {
    final current = await _loadRow(ownerId);
    await _db
        .into(_db.userPreferenceRows)
        .insertOnConflictUpdate(
          UserPreferenceRowsCompanion.insert(
            ownerId: ownerId,
            localeCode: Value(
              localeCode.present ? localeCode.value : current?.localeCode,
            ),
            themeOverride: Value(
              themeOverride.present
                  ? themeOverride.value
                  : current?.themeOverride,
            ),
            backgroundMusicEnabled: Value(
              backgroundMusicEnabled.present
                  ? backgroundMusicEnabled.value
                  : (current?.backgroundMusicEnabled ?? false),
            ),
            showFriendsOnMap: Value(
              showFriendsOnMap.present
                  ? showFriendsOnMap.value
                  : (current?.showFriendsOnMap ?? false),
            ),
          ),
        );
  }
}
