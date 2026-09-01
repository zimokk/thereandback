import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/user_preference_repository_provider.dart';
import '../../../core/app_theme_id.dart';
import '../../../core/local_owner.dart';
import '../../journey/presentation/journey_providers.dart';

part 'theme_provider.g.dart';

/// The user's explicit theme pin (§6.5, §14), or `null` to follow the active
/// quest's own theme — the default this task asked for ("по умолчанию —
/// тема текущего похода").
///
/// Durable since §14 ("сохраняй настройки пользователя..."): [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses, and
/// [setOverride] writes through `UserPreferenceRepository` on every change
/// — including back to `null` ("follow the active quest" is itself a
/// choice worth persisting, not just the two named themes).
///
/// `keepAlive: true` — same reason `friends_providers.dart`'s
/// `ShowFriendsOnMap` needs it (see that doc comment for the mechanism):
/// [setOverride] is called via `ref.read(...).notifier` from a widget
/// event handler in `settings_tab.dart`'s `_ThemeSection`, which also
/// `ref.watch`es this provider in the very same `build()` — a *read*, not
/// a *watch*, so it doesn't itself count as a listener. Plain
/// `@riverpod`'s default autoDispose can tear this element down in the gap
/// between that call and the watching widget's next build re-establishing
/// its own subscription, discarding the just-set value (or throwing
/// "Cannot use Ref after disposed" if the write itself loses the race) —
/// found the hard way here too: `theme_provider_test.dart`'s restart test
/// for `setOverride(null)` after a previous pin hit exactly this.
@Riverpod(keepAlive: true)
class AppThemeOverride extends _$AppThemeOverride {
  @override
  AppThemeId? build() {
    unawaited(_restore());
    return null;
  }

  Future<void> _restore() async {
    final saved = await ref
        .read(userPreferenceRepositoryProvider)
        .loadThemeOverride(localOwnerId);
    if (saved != null) state = saved;
  }

  void setOverride(AppThemeId? themeId) {
    state = themeId;
    // Fire-and-forget — same reasoning as `locale_provider.dart`'s
    // `setLocale`: the pin already took effect in [state] above, and a
    // persistence failure only affects the next cold start.
    unawaited(
      ref
          .read(userPreferenceRepositoryProvider)
          .saveThemeOverride(localOwnerId, themeId)
          .catchError((Object error) {
            debugPrint('Failed to persist theme override: $error');
          }),
    );
  }
}

/// The theme actually in effect right now: the user's pin if they set one,
/// otherwise the selected quest's own theme, otherwise [AppThemeId.classic]
/// (no quest selected yet — e.g. still on the quest picker).
@riverpod
AppThemeId effectiveTheme(Ref ref) {
  final override = ref.watch(appThemeOverrideProvider);
  if (override != null) return override;
  return ref.watch(selectedJourneyDetailsProvider)?.themeId ??
      AppThemeId.classic;
}
