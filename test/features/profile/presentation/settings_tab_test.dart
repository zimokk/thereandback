import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/auth_provider.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/core/app_theme_id.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/data/firebase/auth_repository.dart';
import 'package:thereandback/data/firebase/google_sign_in_service.dart';
import 'package:thereandback/data/firestore/firestore_providers.dart';
import 'package:thereandback/data/firestore/progress_sync_repository.dart';
import 'package:thereandback/data/firestore/user_profile_repository.dart';
import 'package:thereandback/features/audio/data/background_music_player.dart';
import 'package:thereandback/features/audio/presentation/background_music_provider.dart';
import 'package:thereandback/features/friends/domain/friend_profile.dart';
import 'package:thereandback/features/friends/presentation/friends_providers.dart';
import 'package:thereandback/features/journey/data/android_lock_screen_channel.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_controller.dart';
import 'package:thereandback/features/journey/presentation/lock_screen_state.dart';
import 'package:thereandback/features/profile/presentation/locale_provider.dart';
import 'package:thereandback/features/profile/presentation/settings_tab.dart';
import 'package:thereandback/features/profile/presentation/theme_provider.dart';
import 'package:thereandback/features/steps/data/android_background_sync.dart';
import 'package:thereandback/features/steps/data/step_counting_service.dart'
    show StepCountingService, RuntimePermissionResult;
import 'package:thereandback/features/steps/presentation/steps_providers.dart';
import 'package:thereandback/l10n/app_localizations.dart';

class _MockChannel extends Mock implements AndroidLockScreenChannel {}

class _MockBackgroundSync extends Mock implements AndroidBackgroundSync {}

class _MockStepCountingService extends Mock implements StepCountingService {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockProgressSyncRepository extends Mock
    implements ProgressSyncRepository {}

/// Never a real `audioplayers` `AudioPlayer` in a widget test (`testing`
/// skill) — `_wrap` overrides `backgroundMusicPlayerProvider` with this on
/// every test, the same "always override, whether or not the test cares"
/// stance it already takes for `androidLockScreenChannelProvider` and
/// `stepCountingServiceProvider`.
class _MockBackgroundMusicPlayer extends Mock
    implements BackgroundMusicPlayer {}

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
  final backgroundSync = _MockBackgroundSync();
  final stepCountingService = _MockStepCountingService();
  // `LockScreenController.enable()` registers this once every permission is
  // granted (`android_background_sync_test.dart`'s own real target) — never
  // the real `Workmanager()` here, which has no platform implementation in
  // a widget test (`lock_screen_controller_test.dart` uses the same fake).
  when(() => backgroundSync.register()).thenAnswer((_) async {});
  when(() => backgroundSync.cancel()).thenAnswer((_) async {});
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

  final musicPlayer = _MockBackgroundMusicPlayer();
  when(() => musicPlayer.start()).thenAnswer((_) async {});
  when(() => musicPlayer.stop()).thenAnswer((_) async {});
  when(() => musicPlayer.pause()).thenAnswer((_) async {});
  when(() => musicPlayer.resume()).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      lockScreenSupportedProvider.overrideWithValue(lockScreenSupported),
      backgroundMusicPlayerProvider.overrideWithValue(musicPlayer),
      androidLockScreenChannelProvider.overrideWithValue(channel),
      androidBackgroundSyncProvider.overrideWithValue(backgroundSync),
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

  testWidgets(
    'section headers render uppercase, so they stand apart from the body '
    'copy under them (styling fix)',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsTab()));
      await tester.pump();

      expect(find.text('ЯЗЫК'), findsOneWidget);
      expect(find.text('Язык'), findsNothing);
      // The Theme section is the last one on the screen — with the extra
      // padding/spacing this task's styling fix added, it now sits past
      // the test surface's default viewport + cache extent, so `ListView`
      // (a Sliver underneath, lazy about which children it mounts
      // regardless of `children:` vs `.builder`) never builds it without
      // an explicit scroll — same reason `achievements_tab_test.dart`
      // scrolls to its own last tile.
      await tester.dragUntilVisible(
        find.text('ТЕМА'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('ТЕМА'), findsOneWidget);
    },
  );

  testWidgets(
    'the Odyssey theme option names itself as the active quest, so it '
    "reads as distinct from the default 'Тема похода' option instead of a "
    'confusing duplicate',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsTab()));
      await tester.pump();

      await tester.dragUntilVisible(
        find.text('Одиссея (активный поход)'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Одиссея (активный поход)'), findsOneWidget);
    },
  );

  testWidgets('tapping a theme option pins that theme override', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SettingsTab()));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsTab)),
    );
    expect(container.read(appThemeOverrideProvider), isNull);

    await tester.dragUntilVisible(
      find.text('Классическая'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    // One more section (§6.5's "Друзья на карте") now sits above Theme
    // than when this test was written, so `dragUntilVisible`'s own found
    // element can land right at the viewport edge — settle once more
    // before tapping, so the offset `tap()` derives is fully on-screen.
    await tester.pumpAndSettle();
    await tester.tap(find.text('Классическая'));
    await tester.pump();

    expect(container.read(appThemeOverrideProvider), AppThemeId.classic);
  });

  testWidgets("the lock-screen toggle's subtitle uses short, journey-progress "
      'language, not a raw step count (§5.4)', (tester) async {
    await tester.pumpWidget(
      _wrap(const SettingsTab(), lockScreenSupported: true),
    );
    await tester.pump();

    expect(
      find.text(
        'Показывать прогресс похода в шторке уведомлений и на экране '
        'блокировки.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'the background-music toggle renders off by default — this task\'s own '
    'requirement',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsTab()));
      await tester.pump();

      // Last section on the screen (after Theme) — same "past the test
      // surface's default viewport + cache extent" situation the Theme
      // section tests above already work around.
      await tester.dragUntilVisible(
        find.text('Играть фоновую музыку'),
        find.byType(ListView),
        const Offset(0, -300),
      );

      final tile = tester.widget<SwitchListTile>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SwitchListTile &&
              widget.title is Text &&
              (widget.title! as Text).data == 'Играть фоновую музыку',
        ),
      );
      expect(tile.value, isFalse);
    },
  );

  testWidgets(
    'tapping the background-music toggle starts playback and flips it on, '
    'tapping again stops it',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsTab()));
      await tester.pump();

      final musicToggle = find.byWidgetPredicate(
        (widget) =>
            widget is SwitchListTile &&
            widget.title is Text &&
            (widget.title! as Text).data == 'Играть фоновую музыку',
      );
      await tester.dragUntilVisible(
        musicToggle,
        find.byType(ListView),
        const Offset(0, -300),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsTab)),
      );
      final musicPlayer = container.read(
        backgroundMusicPlayerProvider,
      ) as _MockBackgroundMusicPlayer;

      await tester.tap(musicToggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(musicToggle).value, isTrue);
      verify(() => musicPlayer.start()).called(1);

      await tester.tap(musicToggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(musicToggle).value, isFalse);
      verify(() => musicPlayer.stop()).called(1);
    },
  );

  testWidgets(
    'a failure starting the music shows an error message and leaves the '
    'toggle off (§7: never a silent dead end)',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsTab()));
      await tester.pump();

      final musicToggle = find.byWidgetPredicate(
        (widget) =>
            widget is SwitchListTile &&
            widget.title is Text &&
            (widget.title! as Text).data == 'Играть фоновую музыку',
      );
      await tester.dragUntilVisible(
        musicToggle,
        find.byType(ListView),
        const Offset(0, -300),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsTab)),
      );
      final musicPlayer = container.read(
        backgroundMusicPlayerProvider,
      ) as _MockBackgroundMusicPlayer;
      when(() => musicPlayer.start()).thenThrow(Exception('asset missing'));

      await tester.tap(musicToggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(musicToggle).value, isFalse);
      expect(
        find.text('Не удалось включить музыку. Попробуйте ещё раз.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the friends-on-map toggle renders off by default — this task\'s own '
    'requirement',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsTab()));
      await tester.pump();

      await tester.dragUntilVisible(
        find.text('Показывать друзей на карте'),
        find.byType(ListView),
        const Offset(0, -300),
      );

      final tile = tester.widget<SwitchListTile>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SwitchListTile &&
              widget.title is Text &&
              (widget.title! as Text).data == 'Показывать друзей на карте',
        ),
      );
      expect(tile.value, isFalse);
    },
  );

  testWidgets('tapping the friends-on-map toggle flips showFriendsOnMap '
      'Provider on, tapping again flips it back off', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsTab()));
    await tester.pump();

    final friendsToggle = find.byWidgetPredicate(
      (widget) =>
          widget is SwitchListTile &&
          widget.title is Text &&
          (widget.title! as Text).data == 'Показывать друзей на карте',
    );
    await tester.dragUntilVisible(
      friendsToggle,
      find.byType(ListView),
      const Offset(0, -300),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsTab)),
    );
    expect(container.read(showFriendsOnMapProvider), isFalse);

    await tester.tap(friendsToggle);
    await tester.pump();

    expect(container.read(showFriendsOnMapProvider), isTrue);
    expect(tester.widget<SwitchListTile>(friendsToggle).value, isTrue);

    await tester.tap(friendsToggle);
    await tester.pump();

    expect(container.read(showFriendsOnMapProvider), isFalse);
  });

  group(
    'the debug "resync from cloud" button (kDebugMode-only — always on '
    'under `flutter test`, so it renders in every widget test run '
    'regardless of the flag)',
    () {
      testWidgets(
        'force-overwrites local progress with whatever the cloud has, even '
        'downward — unlike sign-in-time reconciliation '
        '(auth_provider_test.dart), which only ever keeps the larger total',
        (tester) async {
          final progressSyncRepository = _MockProgressSyncRepository();
          when(() => progressSyncRepository.fetchCurrentProgress('uid-1'))
              .thenAnswer(
                (_) async => RemoteQuestProgress(
                  journeyId: 'odyssey-ithaca',
                  meters: 500,
                  startedAt: DateTime.utc(2026, 3, 1),
                ),
              );

          await tester.pumpWidget(
            _wrap(
              const SettingsTab(),
              authState: const AuthState(uid: 'uid-1', isAnonymous: false),
              progressSyncRepository: progressSyncRepository,
            ),
          );
          await tester.pump();

          final container = ProviderScope.containerOf(
            tester.element(find.byType(SettingsTab)),
          );
          // Local progress starts out bigger than the cloud's 500m — proves
          // the button really overwrites downward rather than keeping the
          // larger of the two.
          container
              .read(selectedJourneyProvider.notifier)
              .start('odyssey-ithaca', now: DateTime(2026, 3, 1));
          container
              .read(selectedJourneyProvider.notifier)
              .applySyncedProgress(
                progressMeters: 90000,
                syncedAt: DateTime(2026, 3, 15),
              );

          await tester.dragUntilVisible(
            find.text('Синхронизировать из облака'),
            find.byType(ListView),
            const Offset(0, -300),
          );
          await tester.tap(find.text('Синхронизировать из облака'));
          await tester.pumpAndSettle();

          expect(container.read(selectedJourneyProvider)!.progressMeters, 500);
          expect(
            find.text('Локальный прогресс заменён значением из облака.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'nothing ever pushed to the cloud shows that specific message',
        (tester) async {
          final progressSyncRepository = _MockProgressSyncRepository();
          when(() => progressSyncRepository.fetchCurrentProgress('uid-1'))
              .thenAnswer((_) async => null);

          await tester.pumpWidget(
            _wrap(
              const SettingsTab(),
              authState: const AuthState(uid: 'uid-1', isAnonymous: false),
              progressSyncRepository: progressSyncRepository,
            ),
          );
          await tester.pump();

          await tester.dragUntilVisible(
            find.text('Синхронизировать из облака'),
            find.byType(ListView),
            const Offset(0, -300),
          );
          await tester.tap(find.text('Синхронизировать из облака'));
          await tester.pumpAndSettle();

          expect(
            find.text('В облаке нет сохранённого прогресса.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'a Firestore failure shows an error message rather than a silent '
        'dead end (§7)',
        (tester) async {
          final progressSyncRepository = _MockProgressSyncRepository();
          when(() => progressSyncRepository.fetchCurrentProgress('uid-1'))
              .thenThrow(Exception('offline'));

          await tester.pumpWidget(
            _wrap(
              const SettingsTab(),
              authState: const AuthState(uid: 'uid-1', isAnonymous: false),
              progressSyncRepository: progressSyncRepository,
            ),
          );
          await tester.pump();

          await tester.dragUntilVisible(
            find.text('Синхронизировать из облака'),
            find.byType(ListView),
            const Offset(0, -300),
          );
          await tester.tap(find.text('Синхронизировать из облака'));
          await tester.pumpAndSettle();

          expect(
            find.text(
              'Не удалось получить прогресс из облака. Попробуйте ещё раз.',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}
