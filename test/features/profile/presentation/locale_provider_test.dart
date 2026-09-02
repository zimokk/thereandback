import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/drift/user_preference_repository.dart';
import 'package:thereandback/features/profile/presentation/locale_provider.dart';

/// `AppLocale` is `@riverpod` (autoDispose) — a bare `container.read(...)`
/// isn't enough to keep its in-flight `_restore()` alive long enough to
/// land `state = Locale(code)`, the same reason
/// `journey_providers_test.dart`'s restart test for `SelectedJourney`
/// (also autoDispose) needs `container.listen(...)` instead.
void main() {
  test('the default locale (\'ru\', §11) is unaffected when nothing was '
      'ever saved for localOwnerId', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.listen(appLocaleProvider, (_, _) {});

    await pumpEventQueue();

    expect(container.read(appLocaleProvider), const Locale('ru'));
  });

  test('setLocale(en) persists the choice, and a fresh container reading the '
      'same database restores it on build() — this task\'s own requirement: '
      'settings survive a restart (§14)', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    container.read(appLocaleProvider.notifier).setLocale(const Locale('en'));
    // setLocale()'s own persistence write is fire-and-forget — give it a
    // turn to land before simulating the restart below.
    await pumpEventQueue();

    // A brand-new provider container wired to the *same* database
    // instance — this is the restart: fresh Riverpod graph, same disk
    // (`journey_providers_test.dart`'s own restart-simulation shape).
    final restartedContainer = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(restartedContainer.dispose);
    restartedContainer.listen(appLocaleProvider, (_, _) {});

    await pumpEventQueue();

    expect(restartedContainer.read(appLocaleProvider), const Locale('en'));
  });

  test('a previously saved locale for a different owner never leaks into '
      'localOwnerId\'s restore (§8, §13)', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    await DriftUserPreferenceRepository(db)
        .saveLocaleCode('some-other-owner', 'en');

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.listen(appLocaleProvider, (_, _) {});

    await pumpEventQueue();

    expect(container.read(appLocaleProvider), const Locale('ru'));
  });
}
