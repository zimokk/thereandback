// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_timing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The bundle a quest's fictional-time content is read from. A provider of
/// its own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one — same pattern as
/// `quest_map_providers.dart`'s `questMapBundle`.

@ProviderFor(journeyTimingBundle)
final journeyTimingBundleProvider = JourneyTimingBundleProvider._();

/// The bundle a quest's fictional-time content is read from. A provider of
/// its own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one — same pattern as
/// `quest_map_providers.dart`'s `questMapBundle`.

final class JourneyTimingBundleProvider
    extends $FunctionalProvider<AssetBundle, AssetBundle, AssetBundle>
    with $Provider<AssetBundle> {
  /// The bundle a quest's fictional-time content is read from. A provider of
  /// its own so a widget test can hand the screen a small in-memory
  /// `locations.json` instead of the real one — same pattern as
  /// `quest_map_providers.dart`'s `questMapBundle`.
  JourneyTimingBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyTimingBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyTimingBundleHash();

  @$internal
  @override
  $ProviderElement<AssetBundle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AssetBundle create(Ref ref) {
    return journeyTimingBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetBundle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetBundle>(value),
    );
  }
}

String _$journeyTimingBundleHash() =>
    r'7c73f1a76c4a55f8f8d1c9e2d1e0a4b8e6c9f2a1';

/// The currently selected quest's in-fiction segment timings (§6.1) —
/// `null` before a quest is picked, or when that quest ships no
/// `locations.json` timing content at all (today: any quest other than
/// `odyssey-ithaca`). `journey_flame_scene_view.dart` treats both cases the
/// same way: fall back to the real device clock for the sky.

@ProviderFor(selectedJourneySegmentTimings)
final selectedJourneySegmentTimingsProvider =
    SelectedJourneySegmentTimingsProvider._();

/// The currently selected quest's in-fiction segment timings (§6.1) —
/// `null` before a quest is picked, or when that quest ships no
/// `locations.json` timing content at all (today: any quest other than
/// `odyssey-ithaca`). `journey_flame_scene_view.dart` treats both cases the
/// same way: fall back to the real device clock for the sky.

final class SelectedJourneySegmentTimingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JourneySegmentTiming>?>,
          List<JourneySegmentTiming>?,
          FutureOr<List<JourneySegmentTiming>?>
        >
    with
        $FutureModifier<List<JourneySegmentTiming>?>,
        $FutureProvider<List<JourneySegmentTiming>?> {
  /// The currently selected quest's in-fiction segment timings (§6.1) —
  /// `null` before a quest is picked, or when that quest ships no
  /// `locations.json` timing content at all (today: any quest other than
  /// `odyssey-ithaca`). `journey_flame_scene_view.dart` treats both cases the
  /// same way: fall back to the real device clock for the sky.
  SelectedJourneySegmentTimingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedJourneySegmentTimingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$selectedJourneySegmentTimingsHash();

  @$internal
  @override
  $FutureProviderElement<List<JourneySegmentTiming>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JourneySegmentTiming>?> create(Ref ref) {
    return selectedJourneySegmentTimings(ref);
  }
}

String _$selectedJourneySegmentTimingsHash() =>
    r'9b1e3a2c7d4f6058a1b2c3d4e5f60718293a4b5c';
