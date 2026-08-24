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
    verify(() => healthAdapter.requestBackgroundHealthPermission())
        .called(1);
    expect(
      container.read(lockScreenControllerProvider).permissionStatus,
      LockScreenPermissionStatus.granted,
    );
    expect(container.read(lockScreenControllerProvider).enabled, isTrue);
  });

  test('enable() never requests background permission when the base steps '
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
}
