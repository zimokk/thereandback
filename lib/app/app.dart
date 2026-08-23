import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/presentation/locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

/// App root: dark theme only (§9), locale driven by `appLocaleProvider`
/// (§6.5) so the settings language switch takes effect immediately.
class ThereAndBackApp extends ConsumerWidget {
  const ThereAndBackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'There and Back',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: appRouter,
    );
  }
}
