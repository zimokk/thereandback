import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/features/journey/data/android_lock_screen_channel.dart';
import 'package:thereandback/features/journey/domain/lock_screen_snapshot.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeInitializationSettings());
    registerFallbackValue(_FakeNotificationDetails());
  });

  late _MockPlugin plugin;
  late AndroidLockScreenChannel channel;

  const snapshot = LockScreenSnapshot(
    questDay: 5,
    progressMeters: 5230,
    totalMeters: 100000,
    positionLabel: '→ Ithaca',
  );

  setUp(() {
    plugin = _MockPlugin();
    when(() => plugin.initialize(settings: any(named: 'settings')))
        .thenAnswer((_) async => true);
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).thenAnswer((_) async {});
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    channel = AndroidLockScreenChannel(plugin);
  });

  test(
    'start() initializes the plugin once and shows the notification',
    () async {
      await channel.start(snapshot);

      verify(() => plugin.initialize(settings: any(named: 'settings')))
          .called(1);
      verify(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
        ),
      ).called(1);
    },
  );

  test('update() shows a body carrying the day and distance', () async {
    await channel.update(snapshot);

    final captured =
        verify(
              () => plugin.show(
                id: any(named: 'id'),
                title: any(named: 'title'),
                body: captureAny(named: 'body'),
                notificationDetails: any(named: 'notificationDetails'),
              ),
            ).captured.single
            as String;

    expect(captured, contains('5')); // Day 5
    expect(captured, contains('5.23')); // formatDistance(5230) -> 5.23 km
  });

  test('initialize() only runs once across multiple calls', () async {
    await channel.start(snapshot);
    await channel.update(snapshot);
    await channel.end();

    verify(() => plugin.initialize(settings: any(named: 'settings'))).called(1);
  });

  test('end() cancels the notification', () async {
    await channel.end();

    verify(() => plugin.cancel(id: any(named: 'id'))).called(1);
  });
}
