import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/app/theme.dart';
import 'package:thereandback/features/profile/presentation/locale_provider.dart';
import 'package:thereandback/features/profile/presentation/settings_tab.dart';
import 'package:thereandback/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
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
}
