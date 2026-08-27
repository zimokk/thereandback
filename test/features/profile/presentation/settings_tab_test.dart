import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/features/journey/data/android_lock_screen_channel.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_controller.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_state.dart';
import 'package:thereandback/features/profile/presentation/locale_provider.dart';
import 'package:thereandback/features/profile/presentation/settings_tab.dart';
import 'package:thereandback/features/steps/data/health_adapter.dart';
import 'package:thereandback/features/steps/presentation/steps_providers.dart';
import 'package:thereandback/l10n/app_localizations.dart';

class _MockChannel extends Mock implements AndroidLockScreenChannel {}

class _MockHealthAdapter extends Mock implements HealthAdapter {}

/// A `LockScreenController` with a fixed state — same fake pattern
/// `permission_gate_test.dart` uses for `StepsSync` — so the
/// `healthConnectMissing` render below doesn't depend on
/// `Platform.isAndroid` (which reflects the host actually running the
/// test, not a simulated target — see `steps_providers_test.dart`'s
/// equivalent note) ever steering the real controller into that state.
class _FixedLockScreenController extends LockScreenController {
  _FixedLockScreenController(this._state);

  final LockScreenState _state;

  @override
  LockScreenState build() => _state;
}

/// The lock-screen toggle re-reads both permissions as soon as its
/// controller is built, so these have to be faked even in tests that only
/// care about the layout — otherwise the real
/// `flutter_local_notifications` plugin is reached and throws
/// (`testing` skill: never a real platform plugin in a widget test).
Widget _wrap(
  Widget child, {
  bool lockScreenSupported = false,
  bool notificationsGranted = false,
  bool backgroundHealthGranted = false,
}) {
  final channel = _MockChannel();
  final healthAdapter = _MockHealthAdapter();
  when(() => channel.hasNotificationPermission())
      .thenAnswer((_) async => notificationsGranted);
  when(() => healthAdapter.hasBackgroundHealthPermission())
      .thenAnswer((_) async => backgroundHealthGranted);
  // Same answers for the request path, so tapping the toggle resolves to the
  // permission picture the test asked for.
  when(() => channel.requestNotificationPermission())
      .thenAnswer((_) async => notificationsGranted);
  when(() => healthAdapter.hasStepsPermission()).thenAnswer((_) async => true);
  when(() => healthAdapter.requestStepsPermission())
      .thenAnswer((_) async => true);
  when(() => healthAdapter.requestBackgroundHealthPermission())
      .thenAnswer((_) async => backgroundHealthGranted);

  return ProviderScope(
    overrides: [
      lockScreenSupportedProvider.overrideWithValue(lockScreenSupported),
      androidLockScreenChannelProvider.overrideWithValue(channel),
      healthAdapterProvider.overrideWithValue(healthAdapter),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(appLocaleProvider);
        return MaterialApp(
          theme: buildAppTheme(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        );
      },
    ),
  );
}

void main() {
  testWidgets('renders the sign-in row and both language options', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SettingsTab()));
    await tester.pump();

    // Russian is the default locale (§11), so the sign-in row starts out
    // in Russian ("Войти") — see the language-switch test below for the
    // English copy.
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('tapping sign-in shows the stub sheet, not a real sign-in flow', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SettingsTab()));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Скоро'), findsOneWidget);
  });

  testWidgets('switching language flips the rendered locale immediately', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SettingsTab()));
    await tester.pump();

    // Russian is the default locale (§11); the settings title is Russian.
    expect(find.text('Настройки'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Настройки'), findsNothing);
  });

  testWidgets(
    'the lock-screen toggle is hidden where the platform isn\'t supported '
    '(default lockScreenSupportedProvider — this suite runs on Linux)',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsTab()));
      await tester.pump();

      expect(
        find.text('Показывать прогресс на экране блокировки'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'on a platform where it is supported, the toggle renders off by default',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const SettingsTab(), lockScreenSupported: true),
      );
      await tester.pump();

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);
      expect(
        find.text('Показывать прогресс на экране блокировки'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a denial names the permission that is actually missing instead of '
    'claiming nothing was granted',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          lockScreenSupported: true,
          notificationsGranted: true,
        ),
      );
      await tester.pump();

      // Turning it on fails on the background-health half only; the
      // notification half is already held, so the copy must say so.
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Не хватает разрешения читать шаги в фоне. '
          'Оно выдаётся на экране разрешений Health Connect.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Не хватает разрешения на показ уведомлений.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Health Connect missing renders an install prompt, not a plain denial '
    "— the card used to say 'permission not granted' even when Health "
    "Connect wasn't installed for the permission to be granted on",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lockScreenSupportedProvider.overrideWithValue(true),
            lockScreenControllerProvider.overrideWith(
              () => _FixedLockScreenController(
                const LockScreenState(
                  permissionStatus:
                      LockScreenPermissionStatus.healthConnectMissing,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsTab(),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'Health Connect не установлен. Установите его, чтобы читать шаги '
          'в фоне и показывать прогресс на экране блокировки.',
        ),
        findsOneWidget,
      );
      expect(find.text('Установить Health Connect'), findsOneWidget);
      expect(
        find.text('Разрешение не получено, отображение на экране блокировки '
            'выключено. Его можно включить снова в любой момент.'),
        findsNothing,
      );
    },
  );
}
