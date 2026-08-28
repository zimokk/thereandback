import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/core/local_owner.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/data/android_lock_screen_channel.dart';
import 'package:thereandback/features/journey/data/lock_screen_preference_repository.dart';
import 'package:thereandback/features/journey/domain/lock_screen_snapshot.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_controller.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_state.dart';
import 'package:thereandback/features/steps/data/android_background_sync.dart';
import 'package:thereandback/features/steps/data/step_counting_service.dart'
    show
        StepCountingService,
        HealthConnectAvailability,
        RuntimePermissionResult;
import 'package:thereandback/features/steps/presentation/steps_providers.dart';

/// `enable()`/`refreshStatus()`'s `Platform.isAndroid` guard around
/// [LockScreenPermissionStatus.healthConnectMissing] is not exercised in
/// this file: `Platform.isAndroid` reflects the host actually running the
/// test (Linux, here), not a simulated target, so that branch can't be
/// reached without refactoring the notifier to take an injectable platform
/// check — same limitation `steps_providers_test.dart` documents for
/// `StepsSync`. `settings_tab_test.dart` covers that state's *rendering*
/// directly via a fixed-state fake instead.
class _MockChannel extends Mock implements AndroidLockScreenChannel {}

class _MockBackgroundSync extends Mock implements AndroidBackgroundSync {}

class _MockStepCountingService extends Mock implements StepCountingService {}

class _FakeSnapshot extends Fake implements LockScreenSnapshot {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSnapshot());
  });

  late _MockChannel channel;
  late _MockBackgroundSync backgroundSync;
  late _MockStepCountingService stepCountingService;
  late ProviderContainer container;

  setUp(() {
    channel = _MockChannel();
    backgroundSync = _MockBackgroundSync();
    stepCountingService = _MockStepCountingService();

    when(() => channel.start(any())).thenAnswer((_) async {});
    when(() => channel.update(any())).thenAnswer((_) async {});
    when(() => channel.end()).thenAnswer((_) async {});
    when(() => channel.requestNotificationPermission())
        .thenAnswer((_) async => true);
    when(() => backgroundSync.register()).thenAnswer((_) async {});
    when(() => backgroundSync.cancel()).thenAnswer((_) async {});
    when(() => stepCountingService.requestActivityRecognitionPermission())
        .thenAnswer((_) async => RuntimePermissionResult.granted);
    when(() => stepCountingService.openAppSettings()).thenAnswer((_) async {});
    when(() => stepCountingService.hasStepsPermission())
        .thenAnswer((_) async => true);
    when(() => stepCountingService.requestStepsPermission())
        .thenAnswer((_) async => true);
    when(() => stepCountingService.requestBackgroundHealthPermission())
        .thenAnswer((_) async => true);
    when(() => stepCountingService.healthConnectAvailability())
        .thenAnswer((_) async => HealthConnectAvailability.available);
    // `build()` kicks off a status read immediately, so these are reached by
    // every test here, not only the ones that assert on them.
    when(() => channel.hasNotificationPermission())
        .thenAnswer((_) async => true);
    when(() => stepCountingService.hasBackgroundHealthPermission())
        .thenAnswer((_) async => true);

    container = ProviderContainer(
      overrides: [
        androidLockScreenChannelProvider.overrideWithValue(channel),
        androidBackgroundSyncProvider.overrideWithValue(backgroundSync),
        stepCountingServiceProvider.overrideWithValue(stepCountingService),
        appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('enable() with both permissions granted registers background sync '
      'and shows the already-active quest', () async {
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());

    await container.read(lockScreenControllerProvider.notifier).enable();

    expect(
      container.read(lockScreenControllerProvider).permissionStatus,
      LockScreenPermissionStatus.granted,
    );
    expect(container.read(lockScreenControllerProvider).enabled, isTrue);
    verify(() => backgroundSync.register()).called(1);
    verify(() => channel.start(any())).called(1);
  });

  test('enable() requests base steps permission first when Health Connect '
      "hasn't granted it yet, then background permission — matching "
      'Health Connect requiring the read permission before it will grant '
      'background access', () async {
    when(() => stepCountingService.hasStepsPermission())
        .thenAnswer((_) async => false);

    await container.read(lockScreenControllerProvider.notifier).enable();

    verify(() => stepCountingService.requestStepsPermission()).called(1);
    verify(() => stepCountingService.requestBackgroundHealthPermission())
        .called(1);
    expect(
      container.read(lockScreenControllerProvider).permissionStatus,
      LockScreenPermissionStatus.granted,
    );
    expect(container.read(lockScreenControllerProvider).enabled, isTrue);
  });

  test(
    'enable() never requests background permission when the base steps '
    "permission request fails — Health Connect wouldn't grant it anyway",
    () async {
      when(() => stepCountingService.hasStepsPermission())
          .thenAnswer((_) async => false);
      when(() => stepCountingService.requestStepsPermission())
          .thenAnswer((_) async => false);

      await container.read(lockScreenControllerProvider.notifier).enable();

      verifyNever(
        () => stepCountingService.requestBackgroundHealthPermission(),
      );
      expect(
        container.read(lockScreenControllerProvider).permissionStatus,
        LockScreenPermissionStatus.denied,
      );
      expect(container.read(lockScreenControllerProvider).enabled, isFalse);
    },
  );

  test(
    'enable() requests ACTIVITY_RECOGNITION before the base steps '
    "permission — Health Connect won't grant Steps/Distance while it's "
    'missing no matter how many times requestStepsPermission() runs',
    () async {
      await container.read(lockScreenControllerProvider.notifier).enable();

      verify(() => stepCountingService.requestActivityRecognitionPermission())
          .called(1);
      verify(() => stepCountingService.hasStepsPermission()).called(1);
    },
  );

  test('enable() never touches the base steps permission when '
      'ACTIVITY_RECOGNITION is denied (not permanently) — Health Connect '
      "wouldn't grant it anyway, and status is the ordinary denied, not "
      'permanentlyDenied', () async {
    when(() => stepCountingService.requestActivityRecognitionPermission())
        .thenAnswer((_) async => RuntimePermissionResult.denied);

    await container.read(lockScreenControllerProvider.notifier).enable();

    verifyNever(() => stepCountingService.hasStepsPermission());
    verifyNever(() => stepCountingService.requestStepsPermission());
    expect(
      container.read(lockScreenControllerProvider).permissionStatus,
      LockScreenPermissionStatus.denied,
    );
    expect(container.read(lockScreenControllerProvider).enabled, isFalse);
  });

  test(
    'enable() surfaces permanentlyDenied — distinct from denied — when '
    "ACTIVITY_RECOGNITION hit Android's two-denials 'don't ask again' rule, "
    'so the UI can offer settings instead of another dead-end retry',
    () async {
      when(() => stepCountingService.requestActivityRecognitionPermission())
          .thenAnswer((_) async => RuntimePermissionResult.permanentlyDenied);

      await container.read(lockScreenControllerProvider.notifier).enable();

      verifyNever(() => stepCountingService.hasStepsPermission());
      expect(
        container.read(lockScreenControllerProvider).permissionStatus,
        LockScreenPermissionStatus.permanentlyDenied,
      );
      expect(container.read(lockScreenControllerProvider).enabled, isFalse);
      verifyNever(() => backgroundSync.register());
    },
  );

  test('openAppSettings() delegates to the health adapter — the only way '
      'left to grant ACTIVITY_RECOGNITION once permanentlyDenied is '
      'reached', () async {
    await container
        .read(lockScreenControllerProvider.notifier)
        .openAppSettings();

    verify(() => stepCountingService.openAppSettings()).called(1);
    // Drains build()'s own restore-then-refresh microtask before
    // container.dispose() runs in tearDown — same reason the
    // refreshStatus() tests above do this (see their comment).
    await pumpEventQueue();
  });

  test('pressing the toggle again after a denial re-requests both permissions '
      "— a refusal is never a dead end (§7), so enable() being callable again "
      "is what makes the retry actually reach the OS dialogs", () async {
    when(() => channel.requestNotificationPermission())
        .thenAnswer((_) async => false);

    await container.read(lockScreenControllerProvider.notifier).enable();
    expect(container.read(lockScreenControllerProvider).enabled, isFalse);

    when(() => channel.requestNotificationPermission())
        .thenAnswer((_) async => true);
    await container.read(lockScreenControllerProvider.notifier).enable();

    verify(() => channel.requestNotificationPermission()).called(2);
    verify(() => stepCountingService.requestActivityRecognitionPermission())
        .called(2);
    expect(container.read(lockScreenControllerProvider).enabled, isTrue);
  });

  test('enable() waits for an in-flight refreshStatus() instead of silently '
      "bailing out — a resume-triggered background check (Health Connect's "
      "and Android's own permission screens are separate activities, so "
      'returning from either resumes this app right before the next tap) '
      'must never eat the toggle tap with no dialog, no state change, and '
      'nothing in the logs', () async {
    // Let build()'s own restore-then-refresh microtask finish first, so
    // it doesn't interleave with the race set up below.
    container.read(lockScreenControllerProvider);
    await pumpEventQueue();

    final refreshGate = Completer<bool>();
    when(() => channel.hasNotificationPermission())
        .thenAnswer((_) => refreshGate.future);

    final notifier = container.read(lockScreenControllerProvider.notifier);
    final refreshFuture = notifier.refreshStatus();
    // refreshStatus() is now suspended awaiting hasNotificationPermission()
    // — exactly the window where the old shared `isBusy` guard used to
    // make enable() bail out silently.
    final enableFuture = notifier.enable();

    refreshGate.complete(true);
    await refreshFuture;
    await enableFuture;

    expect(container.read(lockScreenControllerProvider).enabled, isTrue);
    verify(() => channel.requestNotificationPermission()).called(1);
    verify(() => backgroundSync.register()).called(1);
  });

  test('enable() denied leaves the feature off and never registers '
      'background sync', () async {
    when(() => channel.requestNotificationPermission())
        .thenAnswer((_) async => false);

    await container.read(lockScreenControllerProvider.notifier).enable();

    expect(
      container.read(lockScreenControllerProvider).permissionStatus,
      LockScreenPermissionStatus.denied,
    );
    expect(container.read(lockScreenControllerProvider).enabled, isFalse);
    verifyNever(() => backgroundSync.register());
    verifyNever(() => channel.start(any()));
  });

  test('a progress update on the same quest calls update(), not start() '
      'again', () async {
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    await container.read(lockScreenControllerProvider.notifier).enable();
    clearInteractions(channel);

    container
        .read(selectedJourneyProvider.notifier)
        .applySyncedProgress(progressMeters: 500, syncedAt: DateTime.now());
    await pumpEventQueue();

    verify(() => channel.update(any())).called(1);
    verifyNever(() => channel.start(any()));
  });

  test(
    'quest completion hides the display and cancels background sync',
    () async {
      container
          .read(selectedJourneyProvider.notifier)
          .start('odyssey-ithaca', now: DateTime.now());
      await container.read(lockScreenControllerProvider.notifier).enable();
      clearInteractions(channel);
      clearInteractions(backgroundSync);

      final journey = container.read(selectedJourneyDetailsProvider)!;
      container
          .read(selectedJourneyProvider.notifier)
          .applySyncedProgress(
            progressMeters: journey.totalMeters,
            syncedAt: DateTime.now(),
          );
      await pumpEventQueue();

      verify(() => channel.end()).called(1);
      verify(() => backgroundSync.cancel()).called(1);
    },
  );

  test('disable() cancels background sync and hides the display', () async {
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    await container.read(lockScreenControllerProvider.notifier).enable();
    clearInteractions(channel);
    clearInteractions(backgroundSync);

    await container.read(lockScreenControllerProvider.notifier).disable();

    expect(container.read(lockScreenControllerProvider).enabled, isFalse);
    verify(() => backgroundSync.cancel()).called(1);
    verify(() => channel.end()).called(1);
  });

  test('openHealthConnectInstall() delegates to the adapter', () async {
    when(() => stepCountingService.openHealthConnectInstall())
        .thenAnswer((_) async {});

    await container
        .read(lockScreenControllerProvider.notifier)
        .openHealthConnectInstall();

    verify(() => stepCountingService.openHealthConnectInstall()).called(1);
  });

  test('refreshStatus() reads both permissions back from the platform instead '
      'of trusting the last request — the toggle used to claim "no permission" '
      'while Android settings showed it granted', () async {
    await container.read(lockScreenControllerProvider.notifier).refreshStatus();

    final state = container.read(lockScreenControllerProvider);
    expect(state.notificationsGranted, isTrue);
    expect(state.backgroundHealthGranted, isTrue);
    expect(state.permissionStatus, LockScreenPermissionStatus.granted);
    // build()'s own restore-then-refresh microtask (see LockScreenController
    // doc comment) is still in flight at this point — reading the notifier
    // above triggered it, and it's slower now than a bare refreshStatus()
    // (one more await, for the drift read). Draining it here, rather than
    // leaving it to resolve after `container.dispose()` in tearDown, is
    // what a fixed-state fake buys the equivalent `steps_providers_test.dart`
    // tests (`docs/screens/steps-sync.md`); this file exercises the real
    // class throughout instead, so it drains explicitly.
    await pumpEventQueue();
  });

  test(
    'refreshStatus() never turns the feature on by itself — holding the '
    'permissions is not the same as asking for a standing notification',
    () async {
      await container
          .read(lockScreenControllerProvider.notifier)
          .refreshStatus();

      expect(container.read(lockScreenControllerProvider).enabled, isFalse);
      verifyNever(() => backgroundSync.register());
      await pumpEventQueue();
    },
  );

  test('refreshStatus() records which half is missing, so the UI can name it '
      'rather than reporting a flat "not granted"', () async {
    when(() => stepCountingService.hasBackgroundHealthPermission())
        .thenAnswer((_) async => false);

    await container.read(lockScreenControllerProvider.notifier).refreshStatus();

    final state = container.read(lockScreenControllerProvider);
    expect(state.notificationsGranted, isTrue);
    expect(state.backgroundHealthGranted, isFalse);
    await pumpEventQueue();
  });

  test('refreshStatus() leaves an untouched toggle on notRequested, not denied '
      "— the user hasn't refused anything yet", () async {
    when(() => channel.hasNotificationPermission())
        .thenAnswer((_) async => false);

    await container.read(lockScreenControllerProvider.notifier).refreshStatus();

    expect(
      container.read(lockScreenControllerProvider).permissionStatus,
      LockScreenPermissionStatus.notRequested,
    );
    await pumpEventQueue();
  });

  test('refreshStatus() turns a running feature off when access was revoked '
      'while the app was backgrounded', () async {
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    await container.read(lockScreenControllerProvider.notifier).enable();
    expect(container.read(lockScreenControllerProvider).enabled, isTrue);
    clearInteractions(channel);
    clearInteractions(backgroundSync);

    when(() => stepCountingService.hasBackgroundHealthPermission())
        .thenAnswer((_) async => false);
    await container.read(lockScreenControllerProvider.notifier).refreshStatus();

    final state = container.read(lockScreenControllerProvider);
    expect(state.enabled, isFalse);
    expect(state.permissionStatus, LockScreenPermissionStatus.denied);
    verify(() => backgroundSync.cancel()).called(1);
    verify(() => channel.end()).called(1);
  });

  test('enable() persists enabled=true and disable() persists enabled=false '
      '— restoring on the next build() (below) depends on this actually '
      'landing in drift, not just in memory', () async {
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    final repository = DriftLockScreenPreferenceRepository(
      container.read(appDatabaseProvider),
    );

    await container.read(lockScreenControllerProvider.notifier).enable();
    expect(await repository.loadEnabled(localOwnerId), isTrue);

    await container.read(lockScreenControllerProvider.notifier).disable();
    expect(await repository.loadEnabled(localOwnerId), isFalse);
  });

  test("build() restores a persisted enabled=true — a cold restart's fresh "
      'state no longer starts from a blank `enabled: false` that could never '
      'notice a permission revoked while the app was closed — and, when that '
      'permission actually was revoked, the resulting refreshStatus() turns '
      'the feature off instead of leaving a stale background task/display '
      'running forever undetected', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    await DriftLockScreenPreferenceRepository(db)
        .saveEnabled(localOwnerId, true);
    when(() => stepCountingService.hasBackgroundHealthPermission())
        .thenAnswer((_) async => false);

    final restarted = ProviderContainer(
      overrides: [
        androidLockScreenChannelProvider.overrideWithValue(channel),
        androidBackgroundSyncProvider.overrideWithValue(backgroundSync),
        stepCountingServiceProvider.overrideWithValue(stepCountingService),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(restarted.dispose);

    // build() fires its restore-then-refreshStatus() microtask; let it
    // resolve, same as the real app renders `unknown` for one frame.
    restarted.read(lockScreenControllerProvider);
    await pumpEventQueue();

    final state = restarted.read(lockScreenControllerProvider);
    expect(state.enabled, isFalse);
    verify(() => backgroundSync.cancel()).called(1);
    verify(() => channel.end()).called(1);
  });

  test('build() restores a persisted enabled=true and, when permission still '
      'holds, leaves the feature enabled without touching the background '
      'task or display at all', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    await DriftLockScreenPreferenceRepository(db)
        .saveEnabled(localOwnerId, true);

    final restarted = ProviderContainer(
      overrides: [
        androidLockScreenChannelProvider.overrideWithValue(channel),
        androidBackgroundSyncProvider.overrideWithValue(backgroundSync),
        stepCountingServiceProvider.overrideWithValue(stepCountingService),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(restarted.dispose);

    restarted.read(lockScreenControllerProvider);
    await pumpEventQueue();

    expect(restarted.read(lockScreenControllerProvider).enabled, isTrue);
    verifyNever(() => backgroundSync.cancel());
    verifyNever(() => channel.end());
  });
}
