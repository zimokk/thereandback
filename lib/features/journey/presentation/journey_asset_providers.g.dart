// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_asset_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The downloadable-content manifest catalog (§8, §14) — mirrors
/// `journey_providers.dart`'s `journeyCatalogEntriesProvider`. Empty today
/// (`journeyAssetManifests` is empty, §14), overridable in widget tests the
/// same way.

@ProviderFor(journeyAssetManifestEntries)
final journeyAssetManifestEntriesProvider =
    JourneyAssetManifestEntriesProvider._();

/// The downloadable-content manifest catalog (§8, §14) — mirrors
/// `journey_providers.dart`'s `journeyCatalogEntriesProvider`. Empty today
/// (`journeyAssetManifests` is empty, §14), overridable in widget tests the
/// same way.

final class JourneyAssetManifestEntriesProvider
    extends
        $FunctionalProvider<
          List<JourneyAssetManifest>,
          List<JourneyAssetManifest>,
          List<JourneyAssetManifest>
        >
    with $Provider<List<JourneyAssetManifest>> {
  /// The downloadable-content manifest catalog (§8, §14) — mirrors
  /// `journey_providers.dart`'s `journeyCatalogEntriesProvider`. Empty today
  /// (`journeyAssetManifests` is empty, §14), overridable in widget tests the
  /// same way.
  JourneyAssetManifestEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyAssetManifestEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyAssetManifestEntriesHash();

  @$internal
  @override
  $ProviderElement<List<JourneyAssetManifest>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<JourneyAssetManifest> create(Ref ref) {
    return journeyAssetManifestEntries(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<JourneyAssetManifest> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<JourneyAssetManifest>>(value),
    );
  }
}

String _$journeyAssetManifestEntriesHash() =>
    r'e0f32d45bc4bd2b98d8437e85b380c5c35249e89';

/// Whether [journeyId] has a manifest at all — `null` means it ships fully
/// bundled in the app binary (every quest today) and has nothing
/// downloadable; `quest_picker_view.dart` uses this to decide whether to
/// show a "Start quest"/"Download" branch at all.

@ProviderFor(journeyAssetManifestFor)
final journeyAssetManifestForProvider = JourneyAssetManifestForFamily._();

/// Whether [journeyId] has a manifest at all — `null` means it ships fully
/// bundled in the app binary (every quest today) and has nothing
/// downloadable; `quest_picker_view.dart` uses this to decide whether to
/// show a "Start quest"/"Download" branch at all.

final class JourneyAssetManifestForProvider
    extends
        $FunctionalProvider<
          JourneyAssetManifest?,
          JourneyAssetManifest?,
          JourneyAssetManifest?
        >
    with $Provider<JourneyAssetManifest?> {
  /// Whether [journeyId] has a manifest at all — `null` means it ships fully
  /// bundled in the app binary (every quest today) and has nothing
  /// downloadable; `quest_picker_view.dart` uses this to decide whether to
  /// show a "Start quest"/"Download" branch at all.
  JourneyAssetManifestForProvider._({
    required JourneyAssetManifestForFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journeyAssetManifestForProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journeyAssetManifestForHash();

  @override
  String toString() {
    return r'journeyAssetManifestForProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<JourneyAssetManifest?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JourneyAssetManifest? create(Ref ref) {
    final argument = this.argument as String;
    return journeyAssetManifestFor(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyAssetManifest? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyAssetManifest?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyAssetManifestForProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyAssetManifestForHash() =>
    r'57dc647a699313a2324d4c59489f455035faacbd';

/// Whether [journeyId] has a manifest at all — `null` means it ships fully
/// bundled in the app binary (every quest today) and has nothing
/// downloadable; `quest_picker_view.dart` uses this to decide whether to
/// show a "Start quest"/"Download" branch at all.

final class JourneyAssetManifestForFamily extends $Family
    with $FunctionalFamilyOverride<JourneyAssetManifest?, String> {
  JourneyAssetManifestForFamily._()
    : super(
        retry: null,
        name: r'journeyAssetManifestForProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [journeyId] has a manifest at all — `null` means it ships fully
  /// bundled in the app binary (every quest today) and has nothing
  /// downloadable; `quest_picker_view.dart` uses this to decide whether to
  /// show a "Start quest"/"Download" branch at all.

  JourneyAssetManifestForProvider call(String journeyId) =>
      JourneyAssetManifestForProvider._(argument: journeyId, from: this);

  @override
  String toString() => r'journeyAssetManifestForProvider';
}

/// Per-journey download state (§8, §14) — the presentation-facing
/// counterpart of `JourneyAssetRepository`. [build] follows the same
/// "sync default now, async correction shortly after" idiom
/// `SelectedJourney.build()`/`BackgroundMusicController.build()` already
/// use: a bundled quest (no manifest) resolves synchronously to
/// [JourneyAssetReady] with no async work at all, so it never flashes a
/// wrong status; a quest with a manifest starts at
/// [JourneyAssetNotDownloaded] and is corrected the moment the drift lookup
/// resolves.

@ProviderFor(JourneyAssetStatusController)
final journeyAssetStatusControllerProvider =
    JourneyAssetStatusControllerFamily._();

/// Per-journey download state (§8, §14) — the presentation-facing
/// counterpart of `JourneyAssetRepository`. [build] follows the same
/// "sync default now, async correction shortly after" idiom
/// `SelectedJourney.build()`/`BackgroundMusicController.build()` already
/// use: a bundled quest (no manifest) resolves synchronously to
/// [JourneyAssetReady] with no async work at all, so it never flashes a
/// wrong status; a quest with a manifest starts at
/// [JourneyAssetNotDownloaded] and is corrected the moment the drift lookup
/// resolves.
final class JourneyAssetStatusControllerProvider
    extends
        $NotifierProvider<JourneyAssetStatusController, JourneyAssetStatus> {
  /// Per-journey download state (§8, §14) — the presentation-facing
  /// counterpart of `JourneyAssetRepository`. [build] follows the same
  /// "sync default now, async correction shortly after" idiom
  /// `SelectedJourney.build()`/`BackgroundMusicController.build()` already
  /// use: a bundled quest (no manifest) resolves synchronously to
  /// [JourneyAssetReady] with no async work at all, so it never flashes a
  /// wrong status; a quest with a manifest starts at
  /// [JourneyAssetNotDownloaded] and is corrected the moment the drift lookup
  /// resolves.
  JourneyAssetStatusControllerProvider._({
    required JourneyAssetStatusControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journeyAssetStatusControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journeyAssetStatusControllerHash();

  @override
  String toString() {
    return r'journeyAssetStatusControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JourneyAssetStatusController create() => JourneyAssetStatusController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyAssetStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyAssetStatus>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyAssetStatusControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyAssetStatusControllerHash() =>
    r'29f910629907b3ee4c67fee67ff3ba2f2b03e8c0';

/// Per-journey download state (§8, §14) — the presentation-facing
/// counterpart of `JourneyAssetRepository`. [build] follows the same
/// "sync default now, async correction shortly after" idiom
/// `SelectedJourney.build()`/`BackgroundMusicController.build()` already
/// use: a bundled quest (no manifest) resolves synchronously to
/// [JourneyAssetReady] with no async work at all, so it never flashes a
/// wrong status; a quest with a manifest starts at
/// [JourneyAssetNotDownloaded] and is corrected the moment the drift lookup
/// resolves.

final class JourneyAssetStatusControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          JourneyAssetStatusController,
          JourneyAssetStatus,
          JourneyAssetStatus,
          JourneyAssetStatus,
          String
        > {
  JourneyAssetStatusControllerFamily._()
    : super(
        retry: null,
        name: r'journeyAssetStatusControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-journey download state (§8, §14) — the presentation-facing
  /// counterpart of `JourneyAssetRepository`. [build] follows the same
  /// "sync default now, async correction shortly after" idiom
  /// `SelectedJourney.build()`/`BackgroundMusicController.build()` already
  /// use: a bundled quest (no manifest) resolves synchronously to
  /// [JourneyAssetReady] with no async work at all, so it never flashes a
  /// wrong status; a quest with a manifest starts at
  /// [JourneyAssetNotDownloaded] and is corrected the moment the drift lookup
  /// resolves.

  JourneyAssetStatusControllerProvider call(String journeyId) =>
      JourneyAssetStatusControllerProvider._(argument: journeyId, from: this);

  @override
  String toString() => r'journeyAssetStatusControllerProvider';
}

/// Per-journey download state (§8, §14) — the presentation-facing
/// counterpart of `JourneyAssetRepository`. [build] follows the same
/// "sync default now, async correction shortly after" idiom
/// `SelectedJourney.build()`/`BackgroundMusicController.build()` already
/// use: a bundled quest (no manifest) resolves synchronously to
/// [JourneyAssetReady] with no async work at all, so it never flashes a
/// wrong status; a quest with a manifest starts at
/// [JourneyAssetNotDownloaded] and is corrected the moment the drift lookup
/// resolves.

abstract class _$JourneyAssetStatusController
    extends $Notifier<JourneyAssetStatus> {
  late final _$args = ref.$arg as String;
  String get journeyId => _$args;

  JourneyAssetStatus build(String journeyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<JourneyAssetStatus, JourneyAssetStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JourneyAssetStatus, JourneyAssetStatus>,
              JourneyAssetStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
