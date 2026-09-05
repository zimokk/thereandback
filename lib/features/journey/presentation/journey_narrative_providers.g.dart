// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_narrative_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The bundle a quest's narrative content is read from — a provider of its
/// own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one, same pattern as
/// `journey_timing_providers.dart`'s `journeyTimingBundle`.

@ProviderFor(journeyNarrativeBundle)
final journeyNarrativeBundleProvider = JourneyNarrativeBundleProvider._();

/// The bundle a quest's narrative content is read from — a provider of its
/// own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one, same pattern as
/// `journey_timing_providers.dart`'s `journeyTimingBundle`.

final class JourneyNarrativeBundleProvider
    extends $FunctionalProvider<AssetBundle, AssetBundle, AssetBundle>
    with $Provider<AssetBundle> {
  /// The bundle a quest's narrative content is read from — a provider of its
  /// own so a widget test can hand the screen a small in-memory
  /// `locations.json` instead of the real one, same pattern as
  /// `journey_timing_providers.dart`'s `journeyTimingBundle`.
  JourneyNarrativeBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyNarrativeBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyNarrativeBundleHash();

  @$internal
  @override
  $ProviderElement<AssetBundle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AssetBundle create(Ref ref) {
    return journeyNarrativeBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetBundle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetBundle>(value),
    );
  }
}

String _$journeyNarrativeBundleHash() =>
    r'2eec34e97a9ecf3efe50f11696fa1efa49823eb7';

/// The currently selected quest's narrative beats (§5, §6.1) — `null`
/// before a quest is picked, or when that quest ships no `locations.json`
/// content at all. `journey_flame_scene_view.dart` falls back to its
/// placeholder narrative line in both cases, and again when the scrolled-to
/// position sits before the first beat (`narrativeBeatFor`'s own `null`).
///
/// Re-reads whenever [appLocaleProvider] changes, so switching the app's
/// language in Настройки swaps in the translated overlay (today: `ru` on
/// `tower-of-lights`) without needing to leave and reopen the tab.

@ProviderFor(selectedJourneyNarrativeBeats)
final selectedJourneyNarrativeBeatsProvider =
    SelectedJourneyNarrativeBeatsProvider._();

/// The currently selected quest's narrative beats (§5, §6.1) — `null`
/// before a quest is picked, or when that quest ships no `locations.json`
/// content at all. `journey_flame_scene_view.dart` falls back to its
/// placeholder narrative line in both cases, and again when the scrolled-to
/// position sits before the first beat (`narrativeBeatFor`'s own `null`).
///
/// Re-reads whenever [appLocaleProvider] changes, so switching the app's
/// language in Настройки swaps in the translated overlay (today: `ru` on
/// `tower-of-lights`) without needing to leave and reopen the tab.

final class SelectedJourneyNarrativeBeatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NarrativeBeat>?>,
          List<NarrativeBeat>?,
          FutureOr<List<NarrativeBeat>?>
        >
    with
        $FutureModifier<List<NarrativeBeat>?>,
        $FutureProvider<List<NarrativeBeat>?> {
  /// The currently selected quest's narrative beats (§5, §6.1) — `null`
  /// before a quest is picked, or when that quest ships no `locations.json`
  /// content at all. `journey_flame_scene_view.dart` falls back to its
  /// placeholder narrative line in both cases, and again when the scrolled-to
  /// position sits before the first beat (`narrativeBeatFor`'s own `null`).
  ///
  /// Re-reads whenever [appLocaleProvider] changes, so switching the app's
  /// language in Настройки swaps in the translated overlay (today: `ru` on
  /// `tower-of-lights`) without needing to leave and reopen the tab.
  SelectedJourneyNarrativeBeatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedJourneyNarrativeBeatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedJourneyNarrativeBeatsHash();

  @$internal
  @override
  $FutureProviderElement<List<NarrativeBeat>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NarrativeBeat>?> create(Ref ref) {
    return selectedJourneyNarrativeBeats(ref);
  }
}

String _$selectedJourneyNarrativeBeatsHash() =>
    r'c891708ea3b262192ae011a5202ac4c23d2aa52e';
