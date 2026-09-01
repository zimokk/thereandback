// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AppThemeOverride)
final appThemeOverrideProvider = AppThemeOverrideProvider._();

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
final class AppThemeOverrideProvider
    extends $NotifierProvider<AppThemeOverride, AppThemeId?> {
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
  AppThemeOverrideProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeOverrideProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeOverrideHash();

  @$internal
  @override
  AppThemeOverride create() => AppThemeOverride();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemeId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeId?>(value),
    );
  }
}

String _$appThemeOverrideHash() => r'6d2f6f398bd0fcb96c41b7614110416096f0bac8';

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

abstract class _$AppThemeOverride extends $Notifier<AppThemeId?> {
  AppThemeId? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppThemeId?, AppThemeId?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppThemeId?, AppThemeId?>,
              AppThemeId?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The theme actually in effect right now: the user's pin if they set one,
/// otherwise the selected quest's own theme, otherwise [AppThemeId.classic]
/// (no quest selected yet — e.g. still on the quest picker).

@ProviderFor(effectiveTheme)
final effectiveThemeProvider = EffectiveThemeProvider._();

/// The theme actually in effect right now: the user's pin if they set one,
/// otherwise the selected quest's own theme, otherwise [AppThemeId.classic]
/// (no quest selected yet — e.g. still on the quest picker).

final class EffectiveThemeProvider
    extends $FunctionalProvider<AppThemeId, AppThemeId, AppThemeId>
    with $Provider<AppThemeId> {
  /// The theme actually in effect right now: the user's pin if they set one,
  /// otherwise the selected quest's own theme, otherwise [AppThemeId.classic]
  /// (no quest selected yet — e.g. still on the quest picker).
  EffectiveThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveThemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveThemeHash();

  @$internal
  @override
  $ProviderElement<AppThemeId> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppThemeId create(Ref ref) {
    return effectiveTheme(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemeId value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeId>(value),
    );
  }
}

String _$effectiveThemeHash() => r'4f3f54b1b5a9dcf9578900e22b72fd5ba16a8968';
