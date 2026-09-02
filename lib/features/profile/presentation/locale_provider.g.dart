// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

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
final class AppLocaleProvider extends $NotifierProvider<AppLocale, Locale> {
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
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  AppLocale create() => AppLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$appLocaleHash() => r'c27941824285eabe6aa540dc5fe6b665ea5e5798';

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

abstract class _$AppLocale extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
