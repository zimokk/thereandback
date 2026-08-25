import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/journey/data/android_lock_screen_channel.dart';
import 'package:thereandback/features/journey/domain/lock_screen_snapshot.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_controller.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_state.dart';
import 'package:thereandback/features/steps/data/android_background_sync.dart';
import 'package:thereandback/features/steps/data/health_adapter.dart';
import 'package:thereandback/features/steps/presentation/steps_providers.dart';

class _MockChannel extends Mock implements AndroidLockScreenChannel {}

class _MockBackgroundSync extends Mock implements AndroidBackgroundSync {}

class _MockHealthAdapter extends Mock implements HealthAdapter {}

class _FakeSnapshot extends Fake implements LockScreenSnapshot {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSnapshot());
  });

  late _MockChannel channel;
  late _MockBackgroundSync backgroundSync;
  late _MockHealthAdapter healthAdapter;
  late ProviderContainer container;

  setUp(() {
    channel = _MockChannel();
    backgroundSync = _MockBackgroundSync();
    healthAdapter = _MockHealthAdapter();

    when(() => channel.start(any())).thenAnswer((_) async {});
    when(() => channel.update(any())).thenAnswer((_) async {});
    when(() => channel.end()).thenAnswer((_) async {});
    when(() => channel.requestNotificationPermission())
        .thenAnswer((_) async => true);
    when(() => backgroundSync.register()).thenAnswer((_) async {});
    when(() => backgroundSync.cancel()).thenAnswer((_) async {});
    when(() => healthAdapter.hasStepsPermission())
        .thenAnswer((_) async => true);
    when(() => healthAdapter.requestStepsPermission())
        .thenAnswer((_) async => true);
    when(() => healthAdapter.requestBackgroundHealthPermission())
        .thenAnswer((_) async => true);
    // `build()` kicks off a status read immediately, so these are reached by
    // every test here, not only the ones that assert on them.
    when(() => channel.hasNotificationPermission())
        .thenAnswer((_) async => true);
    when(() => healthAdapter.hasBackgroundHealthPermission())
        .thenAnswer((_) async => true);

    container = ProviderContainer(
      overrides: [
        androidLockScreenChannelProvider.overrideWithValue(channel),
        androidBackgroundSyncProvider.overrideWithValue(backgroundSync),
        healthAdapterProvider.overrideWithValue(healthAdapter),
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
    when(() => healthAdapter.hasStepsPermission())
        .thenAnswer((_) async => false);

    await container.read(lockScreenControllerProvider.notifier).enable();

    verify(() => healthAdapter.requestStepsPermission()).called(1);
    verify(() => healthAdapter.requestBackgroundHealthPermission()).called(1);
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
      when(() => healthAdapter.hasStepsPermission())
          .thenAnswer((_) async => false);
      when(() => healthAdapter.requestStepsPermission())
          .thenAnswer((_) async => false);

      await container.read(lockScreenControllerProvider.notifier).enable();

      verifyNever(() => healthAdapter.requestBackgroundHealthPermission());
      expect(
        container.read(lockScreenControllerProvider).permissionStatus,
        LockScreenPermissionStatus.denied,
      );
      expect(container.read(lockScreenControllerProvider).enabled, isFalse);
    },
  );

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

  test('refreshStatus() reads both permissions back from the platform instead '
      'of trusting the last request — the toggle used to claim "no permission" '
      'while Android settings showed it granted', () async {
    await container.read(lockScreenControllerProvider.notifier).refreshStatus();

    final state = container.read(lockScreenControllerProvider);
    expect(state.notificationsGranted, isTrue);
    expect(state.backgroundHealthGranted, isTrue);
    expect(state.permissionStatus, LockScreenPermissionStatus.granted);
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
    },
  );

  test('refreshStatus() records which half is missing, so the UI can name it '
      'rather than reporting a flat "not granted"', () async {
    when(() => healthAdapter.hasBackgroundHealthPermission())
        .thenAnswer((_) async => false);

    await container.read(lockScreenControllerProvider.notifier).refreshStatus();

    final state = container.read(lockScreenControllerProvider);
    expect(state.notificationsGranted, isTrue);
    expect(state.backgroundHealthGranted, isFalse);
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

    when(() => healthAdapter.hasBackgroundHealthPermission())
        .thenAnswer((_) async => false);
    await container.read(lockScreenControllerProvider.notifier).refreshStatus();

    final state = container.read(lockScreenControllerProvider);
    expect(state.enabled, isFalse);
    expect(state.permissionStatus, LockScreenPermissionStatus.denied);
    verify(() => backgroundSync.cancel()).called(1);
    verify(() => channel.end()).called(1);
  });
}
