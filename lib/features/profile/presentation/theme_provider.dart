import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/app_theme_id.dart';
import '../../journey/presentation/journey_providers.dart';

part 'theme_provider.g.dart';

/// The user's explicit theme pin (§6.5, §14), or `null` to follow the active
/// quest's own theme — the default this task asked for ("по умолчанию —
/// тема текущего похода").
///
/// In-memory only today — same placeholder-until-Phase-3 caveat as
/// `locale_provider.dart`'s `AppLocale` (`docs/screens/settings.md`).
@riverpod
class AppThemeOverride extends _$AppThemeOverride {
  @override
  AppThemeId? build() => null;

  void setOverride(AppThemeId? themeId) => state = themeId;
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
