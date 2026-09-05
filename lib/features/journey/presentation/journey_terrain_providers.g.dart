// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_terrain_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The bundle a quest's terrain/prop content is read from. A provider of
/// its own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one — same pattern as
/// `journey_timing_providers.dart`'s `journeyTimingBundle`.

@ProviderFor(journeyTerrainBundle)
final journeyTerrainBundleProvider = JourneyTerrainBundleProvider._();

/// The bundle a quest's terrain/prop content is read from. A provider of
/// its own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one — same pattern as
/// `journey_timing_providers.dart`'s `journeyTimingBundle`.

final class JourneyTerrainBundleProvider
    extends $FunctionalProvider<AssetBundle, AssetBundle, AssetBundle>
    with $Provider<AssetBundle> {
  /// The bundle a quest's terrain/prop content is read from. A provider of
  /// its own so a widget test can hand the screen a small in-memory
  /// `locations.json` instead of the real one — same pattern as
  /// `journey_timing_providers.dart`'s `journeyTimingBundle`.
  JourneyTerrainBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyTerrainBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyTerrainBundleHash();

  @$internal
  @override
  $ProviderElement<AssetBundle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AssetBundle create(Ref ref) {
    return journeyTerrainBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetBundle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetBundle>(value),
    );
  }
}

String _$journeyTerrainBundleHash() =>
    r'c33382f60e3694c087395c2e92bf723d9004369e';

/// The currently selected quest's terrain profile + anchored scene props
/// (§6.1) — `null` before a quest is picked, or when that quest ships no
/// `locations.json` content at all (today: any quest other than
/// `odyssey-ithaca`). `journey_flame_scene_view.dart` treats both cases the
/// same way: `terrain_layer.dart`'s placeholder sine wave, no anchored
/// props.

@ProviderFor(selectedJourneyTerrainContent)
final selectedJourneyTerrainContentProvider =
    SelectedJourneyTerrainContentProvider._();

/// The currently selected quest's terrain profile + anchored scene props
/// (§6.1) — `null` before a quest is picked, or when that quest ships no
/// `locations.json` content at all (today: any quest other than
/// `odyssey-ithaca`). `journey_flame_scene_view.dart` treats both cases the
/// same way: `terrain_layer.dart`'s placeholder sine wave, no anchored
/// props.

final class SelectedJourneyTerrainContentProvider
    extends
        $FunctionalProvider<
          AsyncValue<JourneyTerrainContent?>,
          JourneyTerrainContent?,
          FutureOr<JourneyTerrainContent?>
        >
    with
        $FutureModifier<JourneyTerrainContent?>,
        $FutureProvider<JourneyTerrainContent?> {
  /// The currently selected quest's terrain profile + anchored scene props
  /// (§6.1) — `null` before a quest is picked, or when that quest ships no
  /// `locations.json` content at all (today: any quest other than
  /// `odyssey-ithaca`). `journey_flame_scene_view.dart` treats both cases the
  /// same way: `terrain_layer.dart`'s placeholder sine wave, no anchored
  /// props.
  SelectedJourneyTerrainContentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedJourneyTerrainContentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedJourneyTerrainContentHash();

  @$internal
  @override
  $FutureProviderElement<JourneyTerrainContent?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JourneyTerrainContent?> create(Ref ref) {
    return selectedJourneyTerrainContent(ref);
  }
}

String _$selectedJourneyTerrainContentHash() =>
    r'fe5cce949633859ff13558e934f9fa77ff6dc885';
