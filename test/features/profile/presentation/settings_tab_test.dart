import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/firebase/auth_repository.dart';
import 'package:thereandback/data/firebase/google_sign_in_service.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';
import 'package:thereandback/features/friends/domain/friend_profile.dart';
import 'package:thereandback/features/journey/data/android_lock_screen_channel.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_controller.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_state.dart';
import 'package:thereandback/features/profile/presentation/locale_provider.dart';
import 'package:thereandback/features/profile/presentation/settings_tab.dart';
import 'package:thereandback/features/steps/data/step_counting_service.dart'
    show StepCountingService, RuntimePermissionResult;
import 'package:thereandback/features/steps/presentation/steps_providers.dart';
import 'package:thereandback/l10n/app_localizations.dart';

class _MockChannel extends Mock implements AndroidLockScreenChannel {}

class _MockStepCountingService extends Mock implements StepCountingService {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockProgressSyncRepository extends Mock
    implements ProgressSyncRepository {}

/// An [AuthController] that starts from a fixed state and skips the real
/// `build()`'s Firebase bootstrap — same trick `auth_provider_test.dart`'s
/// `_FixedAuthController` uses, duplicated here rather than exported since
/// it's test-only scaffolding.
class _FixedAuthController extends AuthController {
  _FixedAuthController(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

/// A plain mutable counter, incremented each time [_RecoveringAuthController]
/// actually retries — read by the regression test below to assert the retry
/// path was exercised rather than some other code path recovering the uid.
class _Counter {
  int value = 0;
}

/// An `AuthController` that starts with no uid at all (mirroring
/// `_bootstrap()`'s own anonymous-sign-in-failed fallback) and only resolves
/// one once [retryBootstrap] actually runs — used by the regression test
/// below for the nickname row's retry, which must call *this* method, not
/// just re-invalidate [ensureFriendProfileProvider].
///
/// Overrides [retryBootstrap] rather than relying on `build()` being re-run
/// by `ref.invalidate` — the real retry path no longer invalidates the whole
/// controller (see `AuthController.retryBootstrap`'s own doc comment on why:
/// that used to blank `state` back to the signed-out default for the
/// duration of the retry, a visible flicker), so a fake exercising the same
/// path has to hook the same method.
class _RecoveringAuthController extends AuthController {
  _RecoveringAuthController(this._attempts);

  final _Counter _attempts;

  @override
  AuthState build() => const AuthState();

  @override
  Future<void> retryBootstrap() async {
    _attempts.value++;
    state = const AuthState(uid: 'uid-1', isAnonymous: false);
  }
}

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
  RuntimePermissionResult activityRecognitionResult =
      RuntimePermissionResult.granted,
  // Anonymous by default, and always through `_FixedAuthController` — same
  // "never a real platform plugin in a widget test" rule as the lock-screen
  // fakes below applies to `AuthController`'s real Firebase bootstrap.
  AuthState authState = const AuthState(isAnonymous: true),
  // Escape hatch for a test that needs its own `AuthController` subclass
  // (e.g. `_RecoveringAuthController`, which overrides `retryBootstrap()`)
  // rather than always answering with the same fixed `authState`.
  AuthController Function()? authControllerFactory,
  GoogleAuthService? googleAuthService,
  AuthRepository? authRepository,
  UserProfileRepository? userProfileRepository,
  ProgressSyncRepository? progressSyncRepository,
}) {
  final channel = _MockChannel();
  final stepCountingService = _MockStepCountingService();
  when(() => channel.hasNotificationPermission())
      .thenAnswer((_) async => notificationsGranted);
  when(() => stepCountingService.hasBackgroundHealthPermission())
      .thenAnswer((_) async => backgroundHealthGranted);
  // Same answers for the request path, so tapping the toggle resolves to the
  // permission picture the test asked for.
  when(() => channel.requestNotificationPermission())
      .thenAnswer((_) async => notificationsGranted);
  when(() => stepCountingService.requestActivityRecognitionPermission())
      .thenAnswer((_) async => activityRecognitionResult);
  when(() => stepCountingService.openAppSettings()).thenAnswer((_) async {});
  when(() => stepCountingService.hasStepsPermission())
      .thenAnswer((_) async => true);
  when(() => stepCountingService.requestStepsPermission())
      .thenAnswer((_) async => true);
  when(() => stepCountingService.requestBackgroundHealthPermission())
      .thenAnswer((_) async => backgroundHealthGranted);

  return ProviderScope(
    overrides: [
      lockScreenSupportedProvider.overrideWithValue(lockScreenSupported),
      androidLockScreenChannelProvider.overrideWithValue(channel),
      stepCountingServiceProvider.overrideWithValue(stepCountingService),
      authControllerProvider.overrideWith(
        authControllerFactory ?? () => _FixedAuthController(authState),
      ),
      if (googleAuthService != null)
        googleAuthServiceProvider.overrideWithValue(googleAuthService),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      if (userProfileRepository != null)
        userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
      if (progressSyncRepository != null)
        progressSyncRepositoryProvider.overrideWithValue(
          progressSyncRepository,
        ),
      // `testing` skill: never a real (file-backed) drift database in a
      // test — only reached if a test's flow gets far enough to touch
      // `AuthController._reconcileProgressWithCloud` (§8, §14), but always
      // safe to provide.
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
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

  testWidgets(
    'tapping sign-in while anonymous runs the real Google upgrade and '
    'shows a success snackbar',
    (tester) async {
      final googleAuthService = _MockGoogleAuthService();
      final authRepository = _MockAuthRepository();
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
      // upgradeWithGoogle() calls this itself before linking, guarding the
      // race where AuthController.build()'s own unawaited bootstrap hasn't
      // finished yet (auth_provider_test.dart covers that call directly).
      when(() => authRepository.ensureSignedIn())
          .thenAnswer((_) async => 'anon-1');
      when(
        () => authRepository.linkWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          googleAuthService: googleAuthService,
          authRepository: authRepository,
        ),
      );
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      verify(() => authRepository.linkWithGoogleCredential(idToken: 'id-token'))
          .called(1);
      expect(find.text('Вход через Google выполнен.'), findsOneWidget);
    },
  );

  testWidgets(
    'a Google identity already owned by an existing account switches into '
    'it ("repeat login", §8, §14) and shows that specific message rather '
    'than crashing',
    (tester) async {
      final googleAuthService = _MockGoogleAuthService();
      final authRepository = _MockAuthRepository();
      final progressSyncRepository = _MockProgressSyncRepository();
      when(() => googleAuthService.signIn())
          .thenAnswer((_) async => const GoogleAuthTokens(idToken: 'id-token'));
      when(() => authRepository.ensureSignedIn())
          .thenAnswer((_) async => 'anon-1');
      when(
        () => authRepository.linkWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenThrow(const GoogleAccountAlreadyLinkedException());
      when(
        () => authRepository.signInWithGoogleCredential(
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => 'existing-uid');
      when(() => progressSyncRepository.fetchCurrentProgress('existing-uid'))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          googleAuthService: googleAuthService,
          authRepository: authRepository,
          progressSyncRepository: progressSyncRepository,
        ),
      );
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      verify(
        () => authRepository.signInWithGoogleCredential(idToken: 'id-token'),
      ).called(1);
      expect(
        find.text(
          'Вход выполнен — синхронизировано с вашим существующим аккаунтом.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'once signed in, the row shows the signed-in state instead of the '
    'sign-in prompt',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          authState: const AuthState(uid: 'uid-1', isAnonymous: false),
        ),
      );
      await tester.pump();

      expect(find.text('Вы вошли'), findsOneWidget);
      expect(find.text('Войти'), findsNothing);
    },
  );

  testWidgets(
    'shows a loading placeholder before the profile has loaded, then the '
    'nickname once ensureFriendProfileProvider\'s stream emits it',
    (tester) async {
      final userProfileRepository = _MockUserProfileRepository();
      when(
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'uid-1',
            nickname: 'Odysseus',
            avatarPresetIndex: 0,
          ),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          authState: const AuthState(uid: 'uid-1', isAnonymous: false),
          userProfileRepository: userProfileRepository,
        ),
      );
      // Before the first pump settles, myProfileProvider is still on its
      // initial loading state.
      expect(find.text('—'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Odysseus'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    },
  );

  testWidgets(
    'editing the nickname calls updateNickname and shows a success message',
    (tester) async {
      final userProfileRepository = _MockUserProfileRepository();
      when(
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'uid-1',
            nickname: 'Odysseus',
            avatarPresetIndex: 0,
          ),
        ),
      );
      when(() => userProfileRepository.updateNickname('uid-1', 'Nobody'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          authState: const AuthState(uid: 'uid-1', isAnonymous: false),
          userProfileRepository: userProfileRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Odysseus'));
      await tester.pumpAndSettle();

      // The dialog's field starts pre-filled with the current nickname —
      // clear it and type the new one rather than appending to it.
      await tester.enterText(find.byType(TextField), 'Nobody');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      verify(() => userProfileRepository.updateNickname('uid-1', 'Nobody'))
          .called(1);
      expect(find.text('Ник изменён.'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the nickname row before the profile has loaded retries the '
    'bootstrap write and explains why, instead of doing nothing — the row '
    "used to just go dead (`onTap: null`) here, indistinguishable from a "
    'working one',
    (tester) async {
      final userProfileRepository = _MockUserProfileRepository();
      final profileController = StreamController<FriendProfile?>();
      addTearDown(profileController.close);
      when(
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      when(() => userProfileRepository.watchProfile('uid-1'))
          .thenAnswer((_) => profileController.stream);

      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          authState: const AuthState(uid: 'uid-1', isAnonymous: false),
          userProfileRepository: userProfileRepository,
        ),
      );
      await tester.pump();

      // The stream never emitted (simulating a bootstrap write that failed
      // or is still stuck) — the row still shows the loading placeholder.
      expect(find.text('—'), findsOneWidget);

      await tester.tap(find.text('—'));
      await tester.pumpAndSettle();

      expect(
        find.text('Профиль ещё загружается — попробуйте через секунду.'),
        findsOneWidget,
      );
      // Retried rather than left stuck — the bootstrap write ran again.
      verify(
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).called(greaterThanOrEqualTo(2));
    },
  );

  testWidgets(
    'tapping the nickname row when no uid ever resolved (the anonymous '
    'sign-in itself failed, e.g. no network on cold start) calls '
    'AuthController.retryBootstrap(), not just ensureFriendProfileProvider — '
    'regression: the retry used to invalidate only '
    'ensureFriendProfileProvider, which just no-ops forever on a null uid, '
    'so the row stayed stuck on "loading" even after being tapped',
    (tester) async {
      final userProfileRepository = _MockUserProfileRepository();
      when(
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'uid-1',
            nickname: 'Odysseus',
            avatarPresetIndex: 0,
          ),
        ),
      );

      final attempts = _Counter();
      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          authControllerFactory: () => _RecoveringAuthController(attempts),
          userProfileRepository: userProfileRepository,
        ),
      );
      await tester.pump();

      // No uid yet — the row shows the loading placeholder.
      expect(find.text('—'), findsOneWidget);

      await tester.tap(find.text('—'));
      await tester.pumpAndSettle();

      // The retried bootstrap now resolves a uid, whose profile stream
      // immediately has a real nickname — the row must actually recover,
      // not just re-show the same "not ready" snackbar forever.
      expect(find.text('Odysseus'), findsOneWidget);
      expect(attempts.value, 1);
    },
  );

  testWidgets(
    'a nickname already taken by someone else shows that specific message',
    (tester) async {
      final userProfileRepository = _MockUserProfileRepository();
      when(
        () => userProfileRepository.createInitialProfileIfAbsent(
          'uid-1',
          nickname: any(named: 'nickname'),
          avatarPresetIndex: any(named: 'avatarPresetIndex'),
        ),
      ).thenAnswer((_) async {});
      when(() => userProfileRepository.watchProfile('uid-1')).thenAnswer(
        (_) => Stream.value(
          const FriendProfile(
            uid: 'uid-1',
            nickname: 'Odysseus',
            avatarPresetIndex: 0,
          ),
        ),
      );
      when(() => userProfileRepository.updateNickname('uid-1', 'Penelope'))
          .thenThrow(const NicknameTakenException('Penelope'));

      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          authState: const AuthState(uid: 'uid-1', isAnonymous: false),
          userProfileRepository: userProfileRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Odysseus'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Penelope');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(
        find.text('Этот ник уже занят — попробуйте другой.'),
        findsOneWidget,
      );
    },
  );

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
        find.text(
          'Разрешение не получено, отображение на экране блокировки '
          'выключено. Его можно включить снова в любой момент.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'permanentlyDenied ACTIVITY_RECOGNITION offers an "open settings" '
    'button instead of the ordinary denial copy — the toggle can no longer '
    'trigger a dialog, so retrying it would be a dead end (§7)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          lockScreenSupported: true,
          notificationsGranted: true,
          activityRecognitionResult: RuntimePermissionResult.permanentlyDenied,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'После пары отказов Android больше не показывает запрос сам — '
          'откройте настройки приложения, разрешите «Физическая '
          'активность» и включите тумблер снова.',
        ),
        findsOneWidget,
      );
      expect(find.text('Открыть настройки'), findsOneWidget);
      expect(
        find.text(
          'Не хватает разрешения читать шаги в фоне. '
          'Оно выдаётся на экране разрешений Health Connect.',
        ),
        findsNothing,
      );

      // Tapping it must not throw — openAppSettings() is stubbed by _wrap,
      // so reaching it without a MissingStubError is what proves the button
      // is wired to the controller's openAppSettings(), not just painted.
      await tester.tap(find.text('Открыть настройки'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'once the toggle is on, a link opens the lock-screen troubleshooting '
    'sheet — every permission this app can request/check is granted at '
    'that point, so a manufacturer-specific display block (mainly MIUI) is '
    'the only thing left this app has no API to detect or fix (§7: never a '
    'dead end)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SettingsTab(),
          lockScreenSupported: true,
          notificationsGranted: true,
          backgroundHealthGranted: true,
        ),
      );
      await tester.pump();

      expect(find.text('Не видно на экране блокировки?'), findsNothing);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.text('Не видно на экране блокировки?'), findsOneWidget);

      await tester.tap(find.text('Не видно на экране блокировки?'));
      await tester.pumpAndSettle();

      // The link (still in the tree, under the sheet) and the sheet's own
      // title use the same copy by design — both match now.
      expect(find.text('Не видно на экране блокировки?'), findsNWidgets(2));
      expect(find.text('Закрыть'), findsOneWidget);
    },
  );
}
