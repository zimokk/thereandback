// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_scene_art_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The bundle biome art is read from. A provider of its own so a widget
/// test can hand the scene an empty bundle and get the placeholder path
/// deterministically — same pattern as `journey_terrain_providers.dart`'s
/// `journeyTerrainBundle`.

@ProviderFor(sceneArtBundle)
final sceneArtBundleProvider = SceneArtBundleProvider._();

/// The bundle biome art is read from. A provider of its own so a widget
/// test can hand the scene an empty bundle and get the placeholder path
/// deterministically — same pattern as `journey_terrain_providers.dart`'s
/// `journeyTerrainBundle`.

final class SceneArtBundleProvider
    extends $FunctionalProvider<AssetBundle, AssetBundle, AssetBundle>
    with $Provider<AssetBundle> {
  /// The bundle biome art is read from. A provider of its own so a widget
  /// test can hand the scene an empty bundle and get the placeholder path
  /// deterministically — same pattern as `journey_terrain_providers.dart`'s
  /// `journeyTerrainBundle`.
  SceneArtBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sceneArtBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sceneArtBundleHash();

  @$internal
  @override
  $ProviderElement<AssetBundle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AssetBundle create(Ref ref) {
    return sceneArtBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetBundle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetBundle>(value),
    );
  }
}

String _$sceneArtBundleHash() => r'5568b41c045554af75eba84ca3938f1e0ee0cbcf';

/// The one [SceneArtRepository] the scene loads biome art through (§6.1,
/// §9.1).
///
/// `keepAlive` on purpose, unlike most providers here: it owns decoded
/// `ui.Image`s and a cache of which biomes are loaded. Letting it be
/// disposed and rebuilt on an unrelated rebuild would throw that away and
/// re-decode the art the scene is drawing right now.

@ProviderFor(sceneArtRepository)
final sceneArtRepositoryProvider = SceneArtRepositoryProvider._();

/// The one [SceneArtRepository] the scene loads biome art through (§6.1,
/// §9.1).
///
/// `keepAlive` on purpose, unlike most providers here: it owns decoded
/// `ui.Image`s and a cache of which biomes are loaded. Letting it be
/// disposed and rebuilt on an unrelated rebuild would throw that away and
/// re-decode the art the scene is drawing right now.

final class SceneArtRepositoryProvider
    extends
        $FunctionalProvider<
          SceneArtRepository,
          SceneArtRepository,
          SceneArtRepository
        >
    with $Provider<SceneArtRepository> {
  /// The one [SceneArtRepository] the scene loads biome art through (§6.1,
  /// §9.1).
  ///
  /// `keepAlive` on purpose, unlike most providers here: it owns decoded
  /// `ui.Image`s and a cache of which biomes are loaded. Letting it be
  /// disposed and rebuilt on an unrelated rebuild would throw that away and
  /// re-decode the art the scene is drawing right now.
  SceneArtRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sceneArtRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sceneArtRepositoryHash();

  @$internal
  @override
  $ProviderElement<SceneArtRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SceneArtRepository create(Ref ref) {
    return sceneArtRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SceneArtRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SceneArtRepository>(value),
    );
  }
}

String _$sceneArtRepositoryHash() =>
    r'09af4b98dcc7b0212373385093a63b4ea58fcc63';
