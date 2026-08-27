// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_map_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The bundle quest map assets are read from. A provider of its own so a
/// widget test can hand the screen a small in-memory `map.json` instead of
/// the real one (`testing` skill), the same way `appDatabaseProvider` keeps
/// drift out of tests.

@ProviderFor(questMapBundle)
final questMapBundleProvider = QuestMapBundleProvider._();

/// The bundle quest map assets are read from. A provider of its own so a
/// widget test can hand the screen a small in-memory `map.json` instead of
/// the real one (`testing` skill), the same way `appDatabaseProvider` keeps
/// drift out of tests.

final class QuestMapBundleProvider
    extends $FunctionalProvider<AssetBundle, AssetBundle, AssetBundle>
    with $Provider<AssetBundle> {
  /// The bundle quest map assets are read from. A provider of its own so a
  /// widget test can hand the screen a small in-memory `map.json` instead of
  /// the real one (`testing` skill), the same way `appDatabaseProvider` keeps
  /// drift out of tests.
  QuestMapBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questMapBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questMapBundleHash();

  @$internal
  @override
  $ProviderElement<AssetBundle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AssetBundle create(Ref ref) {
    return questMapBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetBundle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetBundle>(value),
    );
  }
}

String _$questMapBundleHash() => r'41071b554d3c8068d73564baf246eb383b2a85db';

/// The drawn map (§6.2) of the currently selected quest: `null` before a
/// quest is picked, an error when that quest ships no usable `map.json` —
/// the Карта tab renders its own fallback for both.

@ProviderFor(selectedQuestMap)
final selectedQuestMapProvider = SelectedQuestMapProvider._();

/// The drawn map (§6.2) of the currently selected quest: `null` before a
/// quest is picked, an error when that quest ships no usable `map.json` —
/// the Карта tab renders its own fallback for both.

final class SelectedQuestMapProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuestMapAssets?>,
          QuestMapAssets?,
          FutureOr<QuestMapAssets?>
        >
    with $FutureModifier<QuestMapAssets?>, $FutureProvider<QuestMapAssets?> {
  /// The drawn map (§6.2) of the currently selected quest: `null` before a
  /// quest is picked, an error when that quest ships no usable `map.json` —
  /// the Карта tab renders its own fallback for both.
  SelectedQuestMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedQuestMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedQuestMapHash();

  @$internal
  @override
  $FutureProviderElement<QuestMapAssets?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuestMapAssets?> create(Ref ref) {
    return selectedQuestMap(ref);
  }
}

String _$selectedQuestMapHash() => r'2a404d44dfb5bb3aaa29272bad24c570175fcad9';
