import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/core/app_theme_id.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/profile/presentation/theme_provider.dart';

/// `AppThemeOverride` is `@riverpod` (autoDispose) — a bare
/// `container.read(...)` isn't enough to keep its in-flight `_restore()`
/// alive long enough to land `state = saved;`, the same reason
/// `journey_providers_test.dart`'s restart test for `SelectedJourney` (also
/// autoDispose) needs `container.listen(...)` instead.
void main() {
  test('the default override (null — "follow the active quest") is '
      'unaffected when nothing was ever saved for localOwnerId', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.listen(appThemeOverrideProvider, (_, _) {});

    await pumpEventQueue();

    expect(container.read(appThemeOverrideProvider), isNull);
  });

  test(
    'setOverride(classic) persists the pin, and a fresh container reading '
    'the same database restores it on build() — this task\'s own '
    'requirement: settings survive a restart (§14)',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      container
          .read(appThemeOverrideProvider.notifier)
          .setOverride(AppThemeId.classic);
      // setOverride()'s own persistence write is fire-and-forget — give it
      // a turn to land before simulating the restart below.
      await pumpEventQueue();

      // A brand-new provider container wired to the *same* database
      // instance — this is the restart: fresh Riverpod graph, same disk
      // (`journey_providers_test.dart`'s own restart-simulation shape).
      final restartedContainer = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(restartedContainer.dispose);
      restartedContainer.listen(appThemeOverrideProvider, (_, _) {});

      await pumpEventQueue();

      expect(
        restartedContainer.read(appThemeOverrideProvider),
        AppThemeId.classic,
      );
    },
  );

  test(
    'setOverride(null) after a previous pin persists "follow the active '
    'quest" explicitly — a fresh container restores null, not the earlier '
    'pin',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(appThemeOverrideProvider.notifier);
      notifier.setOverride(AppThemeId.odyssey);
      await pumpEventQueue();
      notifier.setOverride(null);
      await pumpEventQueue();

      final restartedContainer = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(restartedContainer.dispose);
      restartedContainer.listen(appThemeOverrideProvider, (_, _) {});

      await pumpEventQueue();

      expect(restartedContainer.read(appThemeOverrideProvider), isNull);
    },
  );
}
