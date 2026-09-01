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
@riverpod
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
