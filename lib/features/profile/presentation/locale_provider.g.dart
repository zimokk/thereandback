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
/// In-memory only today — same placeholder-until-Phase-3 caveat as
/// `journey_providers.dart`'s selected quest (`docs/screens/settings.md`).

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

/// The app's current display language (§6.5). Defaults to Russian, this
/// repo's primary language (§11); switching is immediate, no restart.
///
/// In-memory only today — same placeholder-until-Phase-3 caveat as
/// `journey_providers.dart`'s selected quest (`docs/screens/settings.md`).
final class AppLocaleProvider extends $NotifierProvider<AppLocale, Locale> {
  /// The app's current display language (§6.5). Defaults to Russian, this
  /// repo's primary language (§11); switching is immediate, no restart.
  ///
  /// In-memory only today — same placeholder-until-Phase-3 caveat as
  /// `journey_providers.dart`'s selected quest (`docs/screens/settings.md`).
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
/// In-memory only today — same placeholder-until-Phase-3 caveat as
/// `journey_providers.dart`'s selected quest (`docs/screens/settings.md`).

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
