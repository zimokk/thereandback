import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/steps/data/step_counting_service.dart';
import 'package:thereandback/features/steps/presentation/permission_gate.dart';
import 'package:thereandback/features/steps/presentation/steps_providers.dart';
import 'package:thereandback/features/steps/presentation/steps_sync_state.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// Standalone widget coverage for `StepsPermissionGate`'s five render
/// states, listed in `docs/screens/steps-sync.md` as previously exercised
/// only incidentally through `journey_tab_test.dart` (which only ever hit
/// `granted` and `denied`). `notRequested`, `healthConnectMissing`, and the
/// granted-and-flagged notice were never rendered by any test at all — the
/// gap this file closes.
class _MockStepCountingService extends Mock implements StepCountingService {}

/// A [StepsSync] with a fixed state — same fake pattern
/// `journey_tab_test.dart` uses, so these tests exercise the widget's
/// rendering of each `StepsSyncState`, not the business logic that
/// produces it (that's `steps_providers_test.dart`'s job).
class _FixedStepsSync extends StepsSync {
  _FixedStepsSync(this._state);

  final StepsSyncState _state;

  @override
  StepsSyncState build() => _state;
}

Widget _wrap(Widget child, StepsSyncState fixedState) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      stepsSyncProvider.overrideWith(() => _FixedStepsSync(fixedState)),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets(
    'unknown renders nothing — no flash before the first check resolves',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const StepsPermissionGate(), const StepsSyncState()),
      );

      expect(find.byType(StepsPermissionGate), findsOneWidget);
      expect(find.text('Let your steps move you'), findsNothing);
    },
  );

  testWidgets('notRequested renders the pre-permission explanation card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const StepsPermissionGate(),
        const StepsSyncState(
          permissionStatus: StepsPermissionStatus.notRequested,
        ),
      ),
    );

    expect(find.text('Let your steps move you'), findsOneWidget);
    expect(find.text('Allow access'), findsOneWidget);
  });

  testWidgets('healthConnectMissing renders the Health Connect install card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const StepsPermissionGate(),
        const StepsSyncState(
          permissionStatus: StepsPermissionStatus.healthConnectMissing,
        ),
      ),
    );

    expect(find.text('Health Connect required'), findsOneWidget);
    expect(find.text('Install Health Connect'), findsOneWidget);
  });

  testWidgets(
    'permanentlyDenied renders the "open settings" card, not a retry',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StepsPermissionGate(),
          const StepsSyncState(
            permissionStatus: StepsPermissionStatus.permanentlyDenied,
          ),
        ),
      );

      expect(find.text('Permission needs a settings change'), findsOneWidget);
      expect(find.text('Open settings'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    },
  );

  testWidgets('granted with no flagged pace renders nothing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StepsPermissionGate(),
        const StepsSyncState(permissionStatus: StepsPermissionStatus.granted),
      ),
    );

    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  testWidgets(
    'granted with a flagged pace (§5.2) shows the informational notice, '
    'not a blocking card',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StepsPermissionGate(),
          const StepsSyncState(
            permissionStatus: StepsPermissionStatus.granted,
            lastSyncFlagged: true,
          ),
        ),
      );

      expect(
        find.text(
          "Your last sync included an unusually fast stretch — it's still "
          'counted, just flagged for review.',
        ),
        findsOneWidget,
      );
      // Informational only — no button, unlike the gate cards (§5.2: still
      // credited, never blocks anything).
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets('tapping "Try again" on the denied card re-requests permission', (
    tester,
  ) async {
    final adapter = _MockStepCountingService();
    when(() => adapter.requestActivityRecognitionPermission())
        .thenAnswer((_) async => RuntimePermissionResult.granted);
    when(() => adapter.requestStepsPermission()).thenAnswer((_) async => true);

    await tester.pumpWidget(
      _wrapWithAdapter(StepsPermissionStatus.denied, adapter),
    );

    await tester.tap(find.text('Try again'));
    await tester.pump();

    // requestPermission() isn't overridden by `_FixedStepsSync` (only
    // build() is) — tapping the real button really calls the real method,
    // proving the gate is wired to the notifier, not just rendering text.
    verify(() => adapter.requestStepsPermission()).called(1);
  });

  testWidgets(
    'tapping "Allow access" on the notRequested card requests permission',
    (tester) async {
      final adapter = _MockStepCountingService();
      when(() => adapter.requestActivityRecognitionPermission())
          .thenAnswer((_) async => RuntimePermissionResult.granted);
      when(() => adapter.requestStepsPermission())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(
        _wrapWithAdapter(StepsPermissionStatus.notRequested, adapter),
      );

      await tester.tap(find.text('Allow access'));
      await tester.pump();

      verify(() => adapter.requestStepsPermission()).called(1);
    },
  );

  testWidgets('tapping "Open settings" on the permanentlyDenied card opens app '
      "settings, not another permission request", (tester) async {
    final adapter = _MockStepCountingService();
    when(() => adapter.openAppSettings()).thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrapWithAdapter(StepsPermissionStatus.permanentlyDenied, adapter),
    );

    expect(find.text('Open settings'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    await tester.pump();

    verify(() => adapter.openAppSettings()).called(1);
    verifyNever(() => adapter.requestActivityRecognitionPermission());
  });

  testWidgets('tapping "Install Health Connect" delegates to the adapter', (
    tester,
  ) async {
    final adapter = _MockStepCountingService();
    when(() => adapter.openHealthConnectInstall()).thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrapWithAdapter(StepsPermissionStatus.healthConnectMissing, adapter),
    );

    await tester.tap(find.text('Install Health Connect'));
    await tester.pump();

    verify(() => adapter.openHealthConnectInstall()).called(1);
  });
}

/// Like [_wrap], but with an injectable [StepCountingService] mock so a tap
/// test can verify which real `StepsSync` method a button actually calls —
/// `_FixedStepsSync` only overrides `build()`, so tapping a button in these
/// tests exercises the real `requestPermission()`/`openHealthConnectInstall()`.
Widget _wrapWithAdapter(
  StepsPermissionStatus status,
  StepCountingService adapter,
) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      stepCountingServiceProvider.overrideWithValue(adapter),
      stepsSyncProvider.overrideWith(
        () => _FixedStepsSync(StepsSyncState(permissionStatus: status)),
      ),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: StepsPermissionGate()),
    ),
  );
}
