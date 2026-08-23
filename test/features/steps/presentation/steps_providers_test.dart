import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/core/local_owner.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/steps/data/health_adapter.dart';
import 'package:thereandback/features/steps/presentation/steps_providers.dart';
import 'package:thereandback/features/steps/presentation/steps_sync_state.dart';

class _MockHealthAdapter extends Mock implements HealthAdapter {}

/// A [StepsSync] that starts out already granted, skipping the real
/// `build()`'s health-plugin-touching `refreshStatus()` call — this test
/// exercises `sync()` directly, not the permission flow (that's covered by
/// `journey_tab_test.dart`'s `_FixedStepsSync`).
class _GrantedStepsSync extends StepsSync {
  @override
  StepsSyncState build() =>
      const StepsSyncState(permissionStatus: StepsPermissionStatus.granted);
}

void main() {
  late _MockHealthAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    adapter = _MockHealthAdapter();
    container = ProviderContainer(
      overrides: [
        healthAdapterProvider.overrideWithValue(adapter),
        stepsSyncProvider.overrideWith(() => _GrantedStepsSync()),
        // `testing` skill: never a real drift database in a test.
        appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('a realistic pace syncs cleanly and is not flagged', () async {
    when(() => adapter.fetchDelta(any(), any()))
        .thenAnswer((_) async => const StepsDelta(steps: 100));

    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    // 100 steps over ~10 minutes is a normal walking pace.
    container
        .read(selectedJourneyProvider.notifier)
        .applySyncedProgress(
          progressMeters: 0,
          syncedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );

    await container.read(stepsSyncProvider.notifier).sync();

    expect(container.read(stepsSyncProvider).lastSyncFlagged, isFalse);
    expect(
      container.read(selectedJourneyProvider)!.progressMeters,
      greaterThan(0),
    );
  });

  test(
    'an implausible pace (§5.2) is flagged but the distance is still credited',
    () async {
      when(() => adapter.fetchDelta(any(), any()))
          .thenAnswer((_) async => const StepsDelta(steps: 10000));

      container
          .read(selectedJourneyProvider.notifier)
          .start('odyssey-ithaca', now: DateTime.now());
      // 10 000 steps over 30 seconds is far past 250 steps/min.
      container
          .read(selectedJourneyProvider.notifier)
          .applySyncedProgress(
            progressMeters: 0,
            syncedAt: DateTime.now().subtract(const Duration(seconds: 30)),
          );

      final progressBefore = container
          .read(selectedJourneyProvider)!
          .progressMeters;
      await container.read(stepsSyncProvider.notifier).sync();

      expect(container.read(stepsSyncProvider).lastSyncFlagged, isTrue);
      expect(
        container.read(selectedJourneyProvider)!.progressMeters,
        greaterThan(progressBefore),
      );
    },
  );

  test('syncing with no quest selected is a no-op', () async {
    when(() => adapter.fetchDelta(any(), any()))
        .thenAnswer((_) async => const StepsDelta(steps: 100));

    await container.read(stepsSyncProvider.notifier).sync();

    verifyNever(() => adapter.fetchDelta(any(), any()));
    expect(container.read(selectedJourneyProvider), isNull);
  });

  test('Phase 3: a credited sync is durable — reloading from the repository '
      '(what a restarted app does in `SelectedJourney.build()`) matches what '
      'was just credited in memory', () async {
    when(() => adapter.fetchDelta(any(), any()))
        .thenAnswer((_) async => const StepsDelta(steps: 100));

    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    container
        .read(selectedJourneyProvider.notifier)
        .applySyncedProgress(
          progressMeters: 0,
          syncedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );

    await container.read(stepsSyncProvider.notifier).sync();
    final credited = container.read(selectedJourneyProvider)!;
    expect(credited.progressMeters, greaterThan(0));

    final reloaded = await container
        .read(progressRepositoryProvider)
        .loadSelectedQuest(localOwnerId);

    expect(reloaded, isNotNull);
    expect(reloaded!.progressMeters, credited.progressMeters);
    expect(reloaded.lastSyncedAt, credited.lastSyncedAt);
  });
}
