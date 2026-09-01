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
final class AppThemeOverrideProvider
    extends $NotifierProvider<AppThemeOverride, AppThemeId?> {
  /// The user's explicit theme pin (§6.5, §14), or `null` to follow the active
  /// quest's own theme — the default this task asked for ("по умолчанию —
  /// тема текущего похода").
  ///
  /// Durable since §14 ("сохраняй настройки пользователя..."): [build]
  /// fires the same "async check from a sync build()" idiom
  /// `journey_providers.dart`'s `SelectedJourney.build()` uses, and
  /// [setOverride] writes through `UserPreferenceRepository` on every
  /// change — including back to `null` ("follow the active quest" is
  /// itself a choice worth persisting, not just the two named themes).
  AppThemeOverrideProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeOverrideProvider',
        isAutoDispose: true,
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

String _$appThemeOverrideHash() => r'196c95744bba352afd1c11e7ab019e96ed9723d0';

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
