// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The read-only quest catalog (§8). One entry today (§14: "на MVP один
/// квест («Одиссея»)"). Phase 8 swaps the data source for cached Firestore
/// metadata without changing this provider's shape.

@ProviderFor(journeyCatalogEntries)
final journeyCatalogEntriesProvider = JourneyCatalogEntriesProvider._();

/// The read-only quest catalog (§8). One entry today (§14: "на MVP один
/// квест («Одиссея»)"). Phase 8 swaps the data source for cached Firestore
/// metadata without changing this provider's shape.

final class JourneyCatalogEntriesProvider
    extends $FunctionalProvider<List<Journey>, List<Journey>, List<Journey>>
    with $Provider<List<Journey>> {
  /// The read-only quest catalog (§8). One entry today (§14: "на MVP один
  /// квест («Одиссея»)"). Phase 8 swaps the data source for cached Firestore
  /// metadata without changing this provider's shape.
  JourneyCatalogEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyCatalogEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyCatalogEntriesHash();

  @$internal
  @override
  $ProviderElement<List<Journey>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Journey> create(Ref ref) {
    return journeyCatalogEntries(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Journey> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Journey>>(value),
    );
  }
}

String _$journeyCatalogEntriesHash() =>
    r'15d45c76e847d5a6133dadc260c18ee4444fd102';

/// The currently selected/started quest, or `null` before the user picks
/// one. **In-memory only** — resets on app restart. Phase 3 (drift) is the
/// planned, durable replacement; see `docs/screens/journey.md`.

@ProviderFor(SelectedJourney)
final selectedJourneyProvider = SelectedJourneyProvider._();

/// The currently selected/started quest, or `null` before the user picks
/// one. **In-memory only** — resets on app restart. Phase 3 (drift) is the
/// planned, durable replacement; see `docs/screens/journey.md`.
final class SelectedJourneyProvider
    extends $NotifierProvider<SelectedJourney, SelectedQuest?> {
  /// The currently selected/started quest, or `null` before the user picks
  /// one. **In-memory only** — resets on app restart. Phase 3 (drift) is the
  /// planned, durable replacement; see `docs/screens/journey.md`.
  SelectedJourneyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedJourneyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedJourneyHash();

  @$internal
  @override
  SelectedJourney create() => SelectedJourney();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SelectedQuest? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SelectedQuest?>(value),
    );
  }
}

String _$selectedJourneyHash() => r'9a5b3ae85645d60ed3ce9ce0498b4d7ff9f837fa';

/// The currently selected/started quest, or `null` before the user picks
/// one. **In-memory only** — resets on app restart. Phase 3 (drift) is the
/// planned, durable replacement; see `docs/screens/journey.md`.

abstract class _$SelectedJourney extends $Notifier<SelectedQuest?> {
  SelectedQuest? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SelectedQuest?, SelectedQuest?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SelectedQuest?, SelectedQuest?>,
              SelectedQuest?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The catalog [Journey] record matching the currently selected quest, or
/// `null` if nothing is selected (or the id somehow isn't in the catalog).

@ProviderFor(selectedJourneyDetails)
final selectedJourneyDetailsProvider = SelectedJourneyDetailsProvider._();

/// The catalog [Journey] record matching the currently selected quest, or
/// `null` if nothing is selected (or the id somehow isn't in the catalog).

final class SelectedJourneyDetailsProvider
    extends $FunctionalProvider<Journey?, Journey?, Journey?>
    with $Provider<Journey?> {
  /// The catalog [Journey] record matching the currently selected quest, or
  /// `null` if nothing is selected (or the id somehow isn't in the catalog).
  SelectedJourneyDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedJourneyDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedJourneyDetailsHash();

  @$internal
  @override
  $ProviderElement<Journey?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Journey? create(Ref ref) {
    return selectedJourneyDetails(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Journey? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Journey?>(value),
    );
  }
}

String _$selectedJourneyDetailsHash() =>
    r'9bb2a75a0e35422d782a72f5a8ee26cb3f4252be';
