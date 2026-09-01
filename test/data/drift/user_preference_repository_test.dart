import 'package:drift/drift.dart';
import 'package:test/test.dart';
import 'package:thereandback/core/app_theme_id.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/drift/user_preference_repository.dart';

void main() {
  late AppDatabase db;
  late UserPreferenceRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = DriftUserPreferenceRepository(db);
  });
  tearDown(() => db.close());

  group('localeCode', () {
    test('loadLocaleCode() is null for an owner nothing was ever saved for '
        '— the caller (AppLocale.build()) keeps its own default in that '
        'case', () async {
      expect(await repository.loadLocaleCode('owner-1'), isNull);
    });

    test('saveLocaleCode() then loadLocaleCode() round-trips the value', () async {
      await repository.saveLocaleCode('owner-1', 'en');
      expect(await repository.loadLocaleCode('owner-1'), 'en');
    });

    test('a later saveLocaleCode() overwrites, not adds', () async {
      await repository.saveLocaleCode('owner-1', 'en');
      await repository.saveLocaleCode('owner-1', 'ru');

      expect(await repository.loadLocaleCode('owner-1'), 'ru');
    });
  });

  group('themeOverride', () {
    test('loadThemeOverride() is null for an owner nothing was ever saved '
        'for — same default as AppThemeOverride.build()', () async {
      expect(await repository.loadThemeOverride('owner-1'), isNull);
    });

    test('saveThemeOverride() then loadThemeOverride() round-trips the '
        'value', () async {
      await repository.saveThemeOverride('owner-1', AppThemeId.odyssey);
      expect(
        await repository.loadThemeOverride('owner-1'),
        AppThemeId.odyssey,
      );
    });

    test('saveThemeOverride(null) persists "follow the active quest" '
        'explicitly, distinct from never having saved anything but reading '
        'back the same null', () async {
      await repository.saveThemeOverride('owner-1', AppThemeId.classic);
      await repository.saveThemeOverride('owner-1', null);

      expect(await repository.loadThemeOverride('owner-1'), isNull);
    });

    test('an unrecognized stored value falls back to null ("follow the '
        'active quest") instead of throwing — a future AppThemeId this '
        'build predates, after a rollback', () async {
      // Bypasses the repository's own enum-only save() to simulate a value
      // written by a newer build this one doesn't know about.
      await db
          .into(db.userPreferenceRows)
          .insertOnConflictUpdate(
            UserPreferenceRowsCompanion.insert(
              ownerId: 'owner-1',
              themeOverride: const Value('some-future-theme'),
            ),
          );

      expect(await repository.loadThemeOverride('owner-1'), isNull);
    });
  });

  group('backgroundMusicEnabled', () {
    test('loadBackgroundMusicEnabled() is false for an owner nothing was '
        'ever saved for — same default as BackgroundMusicController.build()',
        () async {
      expect(await repository.loadBackgroundMusicEnabled('owner-1'), isFalse);
    });

    test('saveBackgroundMusicEnabled() round-trips true', () async {
      await repository.saveBackgroundMusicEnabled('owner-1', true);
      expect(await repository.loadBackgroundMusicEnabled('owner-1'), isTrue);
    });
  });

  group('showFriendsOnMap', () {
    test('loadShowFriendsOnMap() is false for an owner nothing was ever '
        'saved for — same default as ShowFriendsOnMap.build()', () async {
      expect(await repository.loadShowFriendsOnMap('owner-1'), isFalse);
    });

    test('saveShowFriendsOnMap() round-trips true', () async {
      await repository.saveShowFriendsOnMap('owner-1', true);
      expect(await repository.loadShowFriendsOnMap('owner-1'), isTrue);
    });
  });

  test('saving one field leaves the other three exactly as they were — the '
      'four toggles are independent Настройки switches, not one combined '
      'value', () async {
    await repository.saveLocaleCode('owner-1', 'en');
    await repository.saveThemeOverride('owner-1', AppThemeId.odyssey);
    await repository.saveBackgroundMusicEnabled('owner-1', true);

    // Only showFriendsOnMap is set last — the three writes above must
    // survive it.
    await repository.saveShowFriendsOnMap('owner-1', true);

    expect(await repository.loadLocaleCode('owner-1'), 'en');
    expect(
      await repository.loadThemeOverride('owner-1'),
      AppThemeId.odyssey,
    );
    expect(await repository.loadBackgroundMusicEnabled('owner-1'), isTrue);
    expect(await repository.loadShowFriendsOnMap('owner-1'), isTrue);
  });

  test('a different owner never sees another owner\'s saved values (§8, '
      '§13)', () async {
    await repository.saveLocaleCode('owner-1', 'en');
    await repository.saveThemeOverride('owner-1', AppThemeId.odyssey);
    await repository.saveBackgroundMusicEnabled('owner-1', true);
    await repository.saveShowFriendsOnMap('owner-1', true);

    expect(await repository.loadLocaleCode('owner-2'), isNull);
    expect(await repository.loadThemeOverride('owner-2'), isNull);
    expect(await repository.loadBackgroundMusicEnabled('owner-2'), isFalse);
    expect(await repository.loadShowFriendsOnMap('owner-2'), isFalse);
  });
}
