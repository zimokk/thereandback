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
/// Durable since §14 ("сохраняй настройки пользователя..."): [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses — the widget
/// renders the `'ru'` default for one frame until the persisted value (if
/// any) resolves — and [setLocale] writes through
/// `UserPreferenceRepository` on every change.

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

/// The app's current display language (§6.5). Defaults to Russian, this
/// repo's primary language (§11); switching is immediate, no restart.
///
/// Durable since §14 ("сохраняй настройки пользователя..."): [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses — the widget
/// renders the `'ru'` default for one frame until the persisted value (if
/// any) resolves — and [setLocale] writes through
/// `UserPreferenceRepository` on every change.
final class AppLocaleProvider extends $NotifierProvider<AppLocale, Locale> {
  /// The app's current display language (§6.5). Defaults to Russian, this
  /// repo's primary language (§11); switching is immediate, no restart.
  ///
  /// Durable since §14 ("сохраняй настройки пользователя..."): [build]
  /// fires the same "async check from a sync build()" idiom
  /// `journey_providers.dart`'s `SelectedJourney.build()` uses — the widget
  /// renders the `'ru'` default for one frame until the persisted value
  /// (if any) resolves — and [setLocale] writes through
  /// `UserPreferenceRepository` on every change.
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: true,
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

String _$appLocaleHash() => r'd4ec2a0abd214741f9b33dfcb20cbaa12eb560e2';

/// The app's current display language (§6.5). Defaults to Russian, this
/// repo's primary language (§11); switching is immediate, no restart.
///
/// Durable since §14 ("сохраняй настройки пользователя..."): [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses — the widget
/// renders the `'ru'` default for one frame until the persisted value (if
/// any) resolves — and [setLocale] writes through
/// `UserPreferenceRepository` on every change.

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
