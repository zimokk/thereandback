import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';
import 'package:thereandback/features/journey/presentation/journey_tab.dart';
import 'package:thereandback/features/steps/presentation/steps_providers.dart';
import 'package:thereandback/features/steps/presentation/steps_sync_state.dart';
import 'package:thereandback/l10n/app_localizations.dart';

/// A [StepsSync] with a fixed state and no health-plugin side effects — the
/// real notifier kicks off a platform-channel call from `build()`, which
/// has nothing to talk to in a widget test (`testing` skill: never a real
/// health plugin here).
class _FixedStepsSync extends StepsSync {
  _FixedStepsSync(this._state);

  final StepsSyncState _state;

  @override
  StepsSyncState build() => _state;
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );
}

void main() {
  testWidgets('shows the quest catalog when no quest is selected', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(child: _app(const JourneyTab())));
    await tester.pump();

    expect(find.text('Choose your quest'), findsOneWidget);
    expect(find.text('Start quest'), findsOneWidget);
  });

  testWidgets('shows the path scene once a quest is selected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stepsSyncProvider.overrideWith(
            () => _FixedStepsSync(
              const StepsSyncState(
                permissionStatus: StepsPermissionStatus.granted,
              ),
            ),
          ),
        ],
        child: _app(const JourneyTab()),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(JourneyTab)),
    );
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    await tester.pump();

    expect(find.text('Choose your quest'), findsNothing);
    expect(find.text('Troy → Ithaca'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
  });

  testWidgets('permission-denied state renders the gate, not a blank screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stepsSyncProvider.overrideWith(
            () => _FixedStepsSync(
              const StepsSyncState(
                permissionStatus: StepsPermissionStatus.denied,
              ),
            ),
          ),
        ],
        child: _app(const JourneyTab()),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(JourneyTab)),
    );
    container
        .read(selectedJourneyProvider.notifier)
        .start('odyssey-ithaca', now: DateTime.now());
    await tester.pump();

    expect(find.text('No step data yet'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
