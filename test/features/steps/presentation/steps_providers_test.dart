import 'dart:async';

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

/// A [StepsSync] with a fixed starting state and no build()-triggered
/// background work — like [_GrantedStepsSync], but with a configurable
/// initial [StepsSyncState] for tests that exercise `requestPermission()`/
/// `openHealthConnectInstall()` starting from `notRequested`.
class _FixedStepsSync extends StepsSync {
  _FixedStepsSync(this._state);

  final StepsSyncState _state;

  @override
  StepsSyncState build() => _state;
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

  test('a genuinely duplicate interval (same intervalStart already recorded) '
      'is not credited a second time by sync() itself, not just the '
      'repository it calls', () async {
    when(() => adapter.fetchDelta(any(), any()))
        .thenAnswer((_) async => const StepsDelta(steps: 100));

    final intervalStart = DateTime.now().subtract(const Duration(minutes: 10));
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    container
        .read(selectedJourneyProvider.notifier)
        .applySyncedProgress(progressMeters: 0, syncedAt: intervalStart);

    // Pre-record the exact interval sync() is about to fetch — as if a
    // concurrent sync (background/foreground race) already claimed it.
    await container
        .read(stepSampleRepositoryProvider)
        .recordInterval(
          ownerId: localOwnerId,
          journeyId: 'odyssey-ithaca',
          intervalStart: intervalStart,
          intervalEnd: DateTime.now(),
          steps: 100,
          resolvedMeters: 75,
          flaggedPace: false,
          syncedAt: DateTime.now(),
        );

    await container.read(stepsSyncProvider.notifier).sync();

    // No new credit — the interval was already recorded, so sync()'s
    // own `isNewInterval` branch must not add another 75 m on top.
    expect(container.read(selectedJourneyProvider)!.progressMeters, 0);
  });

  _realStepsSyncGroup();
}

/// Covers `StepsSync`'s permission-flow methods (`build()`/`refreshStatus()`,
/// `requestPermission()`, `openHealthConnectInstall()`) through the real
/// class — every other group in this file swaps it for a fixed-state fake,
/// which left this logic completely untested (see `docs/screens/steps-sync.md`).
///
/// `refreshStatus()`'s `Platform.isAndroid` branch is not exercised here:
/// `Platform.isAndroid` reflects the host actually running the test (this
/// suite runs on Linux, in CI and locally), not a simulated target, so the
/// Health-Connect-missing path can't be reached without refactoring the
/// notifier to take an injectable platform check — out of scope for a
/// coverage pass. `permission_gate_test.dart` covers that state's
/// *rendering* directly via a fixed-state fake instead.
void _realStepsSyncGroup() {
  group(
    'StepsSync.build() / refreshStatus() — the real, un-overridden class',
    () {
      late _MockHealthAdapter adapter;
      late ProviderContainer container;

      setUp(() {
        adapter = _MockHealthAdapter();
        container = ProviderContainer(
          overrides: [
            healthAdapterProvider.overrideWithValue(adapter),
            appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          ],
        );
        addTearDown(container.dispose);
      });

      test('build() starts unknown; refreshStatus() resolves to notRequested '
          'when permission was never granted', () async {
        when(() => adapter.configure()).thenAnswer((_) async {});
        when(() => adapter.hasStepsPermission()).thenAnswer((_) async => false);

        expect(
          container.read(stepsSyncProvider).permissionStatus,
          StepsPermissionStatus.unknown,
        );

        await container.read(stepsSyncProvider.notifier).refreshStatus();

        expect(
          container.read(stepsSyncProvider).permissionStatus,
          StepsPermissionStatus.notRequested,
        );
        verifyNever(() => adapter.fetchDelta(any(), any()));
      });

      test(
        'refreshStatus() auto-syncs when permission is already granted',
        () async {
          when(() => adapter.configure()).thenAnswer((_) async {});
          when(() => adapter.hasStepsPermission())
              .thenAnswer((_) async => true);
          when(() => adapter.fetchDelta(any(), any()))
              .thenAnswer((_) async => const StepsDelta(steps: 100));

          container
              .read(selectedJourneyProvider.notifier)
              .start('odyssey-ithaca', now: DateTime.now());

          await container.read(stepsSyncProvider.notifier).refreshStatus();

          expect(
            container.read(stepsSyncProvider).permissionStatus,
            StepsPermissionStatus.granted,
          );
          expect(
            container.read(selectedJourneyProvider)!.progressMeters,
            greaterThan(0),
          );
        },
      );
    },
  );

  group('StepsSync.requestPermission() / openHealthConnectInstall() — real '
      'methods on a fixed-build fake', () {
    late _MockHealthAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      adapter = _MockHealthAdapter();
      container = ProviderContainer(
        overrides: [
          healthAdapterProvider.overrideWithValue(adapter),
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          // Only build() is faked here (same pattern as `_GrantedStepsSync`
          // above) — the real build() would kick off its own
          // refreshStatus() microtask in the background with no stubs of
          // its own, racing these tests and outliving them into
          // `tearDown`'s container.dispose(). requestPermission() and
          // openHealthConnectInstall() below are the real, inherited
          // methods; only their starting state is fixed.
          stepsSyncProvider.overrideWith(
            () => _FixedStepsSync(
              const StepsSyncState(
                permissionStatus: StepsPermissionStatus.notRequested,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test(
      'requestPermission(): granted transitions to granted and syncs',
      () async {
        when(() => adapter.requestActivityRecognitionPermission())
            .thenAnswer((_) async => RuntimePermissionResult.granted);
        when(() => adapter.requestStepsPermission())
            .thenAnswer((_) async => true);
        when(() => adapter.fetchDelta(any(), any()))
            .thenAnswer((_) async => const StepsDelta(steps: 100));
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime.now());

        await container.read(stepsSyncProvider.notifier).requestPermission();

        expect(
          container.read(stepsSyncProvider).permissionStatus,
          StepsPermissionStatus.granted,
        );
        expect(
          container.read(selectedJourneyProvider)!.progressMeters,
          greaterThan(0),
        );
      },
    );

    test(
      'requestPermission(): denied transitions to denied without syncing',
      () async {
        when(() => adapter.requestActivityRecognitionPermission())
            .thenAnswer((_) async => RuntimePermissionResult.granted);
        when(() => adapter.requestStepsPermission())
            .thenAnswer((_) async => false);

        await container.read(stepsSyncProvider.notifier).requestPermission();

        expect(
          container.read(stepsSyncProvider).permissionStatus,
          StepsPermissionStatus.denied,
        );
        verifyNever(() => adapter.fetchDelta(any(), any()));
      },
    );

    test(
      'requestPermission(): ACTIVITY_RECOGNITION ("Physical activity") '
      'denied stops before Health Connect is ever asked — Health Connect '
      "refuses the Steps/Distance grant without it, so asking would just "
      'surface the same confusing "denied despite tapping Allow" bug',
      () async {
        when(() => adapter.requestActivityRecognitionPermission())
            .thenAnswer((_) async => RuntimePermissionResult.denied);

        await container.read(stepsSyncProvider.notifier).requestPermission();

        expect(
          container.read(stepsSyncProvider).permissionStatus,
          StepsPermissionStatus.denied,
        );
        verifyNever(() => adapter.requestStepsPermission());
        verifyNever(() => adapter.fetchDelta(any(), any()));
      },
    );

    test('requestPermission(): ACTIVITY_RECOGNITION permanently denied (two '
        "prior refusals — Android's own \"don't ask again\" rule) goes "
        'straight to permanentlyDenied, not another dialog-less "denied" '
        'that a "try again" button could never recover from', () async {
      when(() => adapter.requestActivityRecognitionPermission())
          .thenAnswer((_) async => RuntimePermissionResult.permanentlyDenied);

      await container.read(stepsSyncProvider.notifier).requestPermission();

      expect(
        container.read(stepsSyncProvider).permissionStatus,
        StepsPermissionStatus.permanentlyDenied,
      );
      verifyNever(() => adapter.requestStepsPermission());
      verifyNever(() => adapter.fetchDelta(any(), any()));
    });

    test('refreshStatus() is a no-op while requestPermission() is still '
        'in flight — guards the race where Health Connect\'s permission '
        'screen resumes the app (firing the lifecycle-triggered '
        'refreshStatus()) before the awaited request itself resolves, so '
        'a stale check can\'t overwrite the real answer', () async {
      final activityRecognitionCompleter = Completer<RuntimePermissionResult>();
      when(() => adapter.requestActivityRecognitionPermission())
          .thenAnswer((_) => activityRecognitionCompleter.future);
      when(() => adapter.requestStepsPermission())
          .thenAnswer((_) async => true);
      when(() => adapter.configure()).thenAnswer((_) async {});
      when(() => adapter.hasStepsPermission()).thenAnswer((_) async => true);
      when(() => adapter.fetchDelta(any(), any()))
          .thenAnswer((_) async => const StepsDelta(steps: 100));

      final requestFuture = container
          .read(stepsSyncProvider.notifier)
          .requestPermission();

      // requestPermission() is now suspended awaiting
      // requestActivityRecognitionPermission() — simulate the app-resume
      // lifecycle listener firing refreshStatus() in that window.
      await container.read(stepsSyncProvider.notifier).refreshStatus();

      verifyNever(() => adapter.configure());
      verifyNever(() => adapter.hasStepsPermission());
      expect(
        container.read(stepsSyncProvider).permissionStatus,
        StepsPermissionStatus.notRequested,
      );

      activityRecognitionCompleter.complete(RuntimePermissionResult.granted);
      await requestFuture;

      expect(
        container.read(stepsSyncProvider).permissionStatus,
        StepsPermissionStatus.granted,
      );
    });

    test('openAppSettings() delegates to the adapter', () async {
      when(() => adapter.openAppSettings()).thenAnswer((_) async {});

      await container.read(stepsSyncProvider.notifier).openAppSettings();

      verify(() => adapter.openAppSettings()).called(1);
    });

    test('openHealthConnectInstall() delegates to the adapter', () async {
      when(() => adapter.openHealthConnectInstall()).thenAnswer((_) async {});

      await container
          .read(stepsSyncProvider.notifier)
          .openHealthConnectInstall();

      verify(() => adapter.openHealthConnectInstall()).called(1);
    });
  });
}
