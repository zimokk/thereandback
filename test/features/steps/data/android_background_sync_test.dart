import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/features/steps/data/android_background_sync.dart';
import 'package:workmanager/workmanager.dart';

class _MockWorkmanager extends Mock implements Workmanager {}

void main() {
  late _MockWorkmanager workmanager;
  late AndroidBackgroundSync sync;

  setUp(() {
    workmanager = _MockWorkmanager();
    when(
      () => workmanager.registerPeriodicTask(
        any(),
        any(),
        frequency: any(named: 'frequency'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
        constraints: any(named: 'constraints'),
      ),
    ).thenAnswer((_) async {});
    when(() => workmanager.cancelByUniqueName(any())).thenAnswer((_) async {});
    sync = AndroidBackgroundSync(workmanager);
  });

  test(
    'register() schedules the periodic task by its stable unique name',
    () async {
      await sync.register();

      verify(
        () => workmanager.registerPeriodicTask(
          androidLockScreenSyncUniqueName,
          androidLockScreenSyncTaskName,
          frequency: androidLockScreenSyncFrequency,
          existingWorkPolicy: any(named: 'existingWorkPolicy'),
          constraints: any(named: 'constraints'),
        ),
      ).called(1);
    },
  );

  test('cancel() cancels by the same unique name register() used', () async {
    await sync.cancel();

    verify(
      () => workmanager.cancelByUniqueName(androidLockScreenSyncUniqueName),
    ).called(1);
  });
}
