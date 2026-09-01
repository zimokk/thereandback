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
///
/// `keepAlive: true` — same reason `friends_providers.dart`'s
/// `ShowFriendsOnMap` needs it (see that doc comment for the mechanism):
/// [setLocale] is called via `ref.read(...).notifier` from a widget event
/// handler in `settings_tab.dart`, which also `ref.watch`es this provider
/// in the very same `build()` — a *read*, not a *watch*, so it doesn't
/// itself count as a listener. Plain `@riverpod`'s default autoDispose can
/// tear this element down in the gap between that call and the watching
/// widget's next build re-establishing its own subscription, discarding
/// the just-set value (or throwing "Cannot use Ref after disposed" if the
/// write itself loses the race) — caught by
/// `theme_provider_test.dart`'s sibling restart test for
/// `AppThemeOverride`, fixed here the same way before it could bite this
/// provider too.
@Riverpod(keepAlive: true)
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
