import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
}
