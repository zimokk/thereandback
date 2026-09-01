import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/user_preference_repository_provider.dart';
import '../../../core/local_owner.dart';

part 'locale_provider.g.dart';

/// The app's current display language (§6.5). Defaults to Russian, this
/// repo's primary language (§11); switching is immediate, no restart.
///
/// Durable since §14 ("сохраняй настройки пользователя... чтобы при
/// перезапуске приложения всё загружалось как было настроено"): [build]
/// fires the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses — the widget
/// renders the `'ru'` default for one frame until the persisted value (if
/// any) resolves — and [setLocale] writes through
/// `UserPreferenceRepository` on every change.
@riverpod
class AppLocale extends _$AppLocale {
  @override
  Locale build() {
    unawaited(_restore());
    return const Locale('ru');
  }

  Future<void> _restore() async {
    final code = await ref
        .read(userPreferenceRepositoryProvider)
        .loadLocaleCode(localOwnerId);
    if (code != null) state = Locale(code);
  }

  void setLocale(Locale locale) {
    state = locale;
    // Fire-and-forget, like every other Настройки toggle's persistence
    // write (`theme_provider.dart`, `background_music_provider.dart`,
    // `friends_providers.dart`'s `ShowFriendsOnMap`) — the language switch
    // itself already took effect in [state] above; a failure to persist it
    // only affects the *next* cold start, not this one, so there is
    // nothing for the caller to await or a snackbar to show for it here.
    unawaited(
      ref
          .read(userPreferenceRepositoryProvider)
          .saveLocaleCode(localOwnerId, locale.languageCode)
          .catchError((Object error) {
            debugPrint('Failed to persist locale: $error');
          }),
    );
  }
}
