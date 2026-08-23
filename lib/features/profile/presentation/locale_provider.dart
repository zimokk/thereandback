import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// The app's current display language (§6.5). Defaults to Russian, this
/// repo's primary language (§11); switching is immediate, no restart.
///
/// In-memory only today — same placeholder-until-Phase-3 caveat as
/// `journey_providers.dart`'s selected quest (`docs/screens/settings.md`).
@riverpod
class AppLocale extends _$AppLocale {
  @override
  Locale build() => const Locale('ru');

  void setLocale(Locale locale) => state = locale;
}
