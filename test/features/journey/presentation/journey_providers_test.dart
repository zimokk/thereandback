import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/core/local_owner.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';
import 'package:thereandback/features/journey/data/progress_repository.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/steps/data/step_sample_repository.dart';

class _MockProgressSyncRepository extends Mock
    implements ProgressSyncRepository {}

/// `SelectedJourney.build()`'s restore branch (`if (restored != null) state
/// = restored;`) is the actual "survives a restart" behavior the drift
/// persistence layer exists for — every other test in this project starts a
/// fresh in-memory database with nothing in it, so `_restore()` always
/// finds `null` there and this branch never runs. This file constructs the
/// database *before* the provider container, the same way a real app
/// restart hands an already-populated file to a fresh process.
void main() {
  test('a fresh container restores a previously started quest from the '
      'database — the actual restart-survival path, not just the repository '
      'that backs it', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    // Simulate "a previous app session already did this" directly
    // through the repository, before any provider container exists.
    final seedRepository = DriftProgressRepository(db);
    final startedAt = DateTime(2026, 3, 10);
    await seedRepository.startQuest(
      localOwnerId,
      journeyId: 'odyssey-ithaca',
      startedAt: startedAt,
    );
    await DriftStepSampleRepository(db).recordInterval(
      ownerId: localOwnerId,
      journeyId: 'odyssey-ithaca',
      intervalStart: startedAt,
      intervalEnd: startedAt.add(const Duration(minutes: 10)),
      steps: 100,
      resolvedMeters: 75,
      flaggedPace: false,
      syncedAt: startedAt.add(const Duration(minutes: 10)),
    );

    // A brand-new provider container, wired to the *same* database
    // instance — this is the restart: fresh Riverpod graph, same disk.
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    // `selectedJourneyProvider` is `@riverpod` (autoDispose) — without an
    // active listener, a bare `.read()` can leave it eligible for
    // disposal with nothing keeping the in-flight `_restore()` alive to
    // actually land its `state = restored;` write.
    container.listen(selectedJourneyProvider, (_, _) {});

    expect(container.read(selectedJourneyProvider), isNull);

    // build()'s restore runs in a microtask (`unawaited(_restore())`),
    // and its query goes through drift's own async connection machinery
    // (more than one event-loop turn even against an in-memory
    // database) — pump several times rather than guess a single flush
    // is enough.
    await _pumpMicrotasks();

    final restored = container.read(selectedJourneyProvider);
    expect(restored, isNotNull);
    expect(restored!.journeyId, 'odyssey-ithaca');
    expect(restored.progressMeters, 75);
    expect(restored.startedAt, startedAt);
  });

  test('a fresh container with nothing persisted stays null after the restore '
      'check resolves — not stuck on a permanent "unknown" state', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(selectedJourneyProvider), isNull);
    await _pumpMicrotasks();
    expect(container.read(selectedJourneyProvider), isNull);
  });

  group('start() also pushes an initial progress row to Firestore', () {
    late _MockProgressSyncRepository progressSyncRepository;

    setUp(() {
      progressSyncRepository = _MockProgressSyncRepository();
      when(
        () => progressSyncRepository.pushProgress(
          uid: any(named: 'uid'),
          journeyId: any(named: 'journeyId'),
          meters: any(named: 'meters'),
          startedAt: any(named: 'startedAt'),
          isCurrent: any(named: 'isCurrent'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'a signed-in uid gets an immediate meters: 0 push, not just after the '
      'first steps sync',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            currentUidProvider.overrideWithValue('uid-1'),
            progressSyncRepositoryProvider.overrideWithValue(
              progressSyncRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final startedAt = DateTime(2026, 3, 10);
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: startedAt);

        // No pump needed: `unawaited(pushProgressBestEffort(...))` still
        // synchronously *invokes* `pushProgress()` — evaluating that call
        // is part of reaching its own `await` — so the mock call is
        // already registered by the time `start()` returns (same reasoning
        // as `steps_providers_test.dart`'s equivalent comment).
        verify(
          () => progressSyncRepository.pushProgress(
            uid: 'uid-1',
            journeyId: 'odyssey-ithaca',
            meters: 0,
            startedAt: startedAt,
            isCurrent: true,
          ),
        ).called(1);
      },
    );

    test(
      'no signed-in uid yet is a no-op — the repository is never called',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
            currentUidProvider.overrideWithValue(null),
            progressSyncRepositoryProvider.overrideWithValue(
              progressSyncRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime(2026, 3, 10));

        verifyNever(
          () => progressSyncRepository.pushProgress(
            uid: any(named: 'uid'),
            journeyId: any(named: 'journeyId'),
            meters: any(named: 'meters'),
            startedAt: any(named: 'startedAt'),
            isCurrent: any(named: 'isCurrent'),
          ),
        );
      },
    );
  });
}

/// Flushes several event-loop turns so an `unawaited()` background Future
/// (here, `SelectedJourney._restore()`) gets a real chance to finish before
/// a test asserts on its result — a single `await Future(() {})` isn't
/// reliably enough turns for a drift query's own internal async hops.
Future<void> _pumpMicrotasks({int times = 20}) async {
  for (var i = 0; i < times; i++) {
    await Future(() {});
  }
}
