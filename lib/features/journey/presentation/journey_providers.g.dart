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

/// The drift-backed store for the active quest (§5.2, §8). Overridden with
/// an in-memory `AppDatabase` in tests via `appDatabaseProvider`
/// (`testing` skill).

@ProviderFor(progressRepository)
final progressRepositoryProvider = ProgressRepositoryProvider._();

/// The drift-backed store for the active quest (§5.2, §8). Overridden with
/// an in-memory `AppDatabase` in tests via `appDatabaseProvider`
/// (`testing` skill).

final class ProgressRepositoryProvider
    extends
        $FunctionalProvider<
          ProgressRepository,
          ProgressRepository,
          ProgressRepository
        >
    with $Provider<ProgressRepository> {
  /// The drift-backed store for the active quest (§5.2, §8). Overridden with
  /// an in-memory `AppDatabase` in tests via `appDatabaseProvider`
  /// (`testing` skill).
  ProgressRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgressRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgressRepository create(Ref ref) {
    return progressRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressRepository>(value),
    );
  }
}

String _$progressRepositoryHash() =>
    r'38ea6184c71b13fed3c863d0acfa58eeb1503f71';

/// The currently selected/started quest, or `null` before the user picks
/// one, or before the persisted quest (if any) has finished loading.
///
/// Durable since Phase 3: [start] and [applySyncedProgress] write through
/// [progressRepositoryProvider], and [build] restores whatever was
/// persisted — a killed-and-restarted app no longer loses `lastSyncedAt`
/// or `progressMeters` (see `docs/screens/steps-sync.md`).

@ProviderFor(SelectedJourney)
final selectedJourneyProvider = SelectedJourneyProvider._();

/// The currently selected/started quest, or `null` before the user picks
/// one, or before the persisted quest (if any) has finished loading.
///
/// Durable since Phase 3: [start] and [applySyncedProgress] write through
/// [progressRepositoryProvider], and [build] restores whatever was
/// persisted — a killed-and-restarted app no longer loses `lastSyncedAt`
/// or `progressMeters` (see `docs/screens/steps-sync.md`).
final class SelectedJourneyProvider
    extends $NotifierProvider<SelectedJourney, SelectedQuest?> {
  /// The currently selected/started quest, or `null` before the user picks
  /// one, or before the persisted quest (if any) has finished loading.
  ///
  /// Durable since Phase 3: [start] and [applySyncedProgress] write through
  /// [progressRepositoryProvider], and [build] restores whatever was
  /// persisted — a killed-and-restarted app no longer loses `lastSyncedAt`
  /// or `progressMeters` (see `docs/screens/steps-sync.md`).
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

String _$selectedJourneyHash() => r'5e4796d6dab4d1d82b68141eddd33175942f1f6b';

/// The currently selected/started quest, or `null` before the user picks
/// one, or before the persisted quest (if any) has finished loading.
///
/// Durable since Phase 3: [start] and [applySyncedProgress] write through
/// [progressRepositoryProvider], and [build] restores whatever was
/// persisted — a killed-and-restarted app no longer loses `lastSyncedAt`
/// or `progressMeters` (see `docs/screens/steps-sync.md`).

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

/// Raw interval history for the active quest, wide enough to cover
/// `QuestTimeService.paceMetersPerDay`'s 7-day rolling window (§5.3)
/// regardless of timezone offset. Re-fetches whenever
/// [selectedJourneyProvider] changes, so a fresh sync tick keeps the Quest
/// Stats pace/ETA current.
///
/// 8 days of margin, not 7: the window is computed on **local** calendar
/// days, and the query filter is a plain UTC instant comparison — one extra
/// day covers the largest realistic UTC offset, and `QuestTimeService` does
/// the exact local-day filtering afterwards (§13: the DB query lives here in
/// `data/`, the calendar math stays in `domain/`).

@ProviderFor(recentMeteredIntervals)
final recentMeteredIntervalsProvider = RecentMeteredIntervalsProvider._();

/// Raw interval history for the active quest, wide enough to cover
/// `QuestTimeService.paceMetersPerDay`'s 7-day rolling window (§5.3)
/// regardless of timezone offset. Re-fetches whenever
/// [selectedJourneyProvider] changes, so a fresh sync tick keeps the Quest
/// Stats pace/ETA current.
///
/// 8 days of margin, not 7: the window is computed on **local** calendar
/// days, and the query filter is a plain UTC instant comparison — one extra
/// day covers the largest realistic UTC offset, and `QuestTimeService` does
/// the exact local-day filtering afterwards (§13: the DB query lives here in
/// `data/`, the calendar math stays in `domain/`).

final class RecentMeteredIntervalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MeteredInterval>>,
          List<MeteredInterval>,
          FutureOr<List<MeteredInterval>>
        >
    with
        $FutureModifier<List<MeteredInterval>>,
        $FutureProvider<List<MeteredInterval>> {
  /// Raw interval history for the active quest, wide enough to cover
  /// `QuestTimeService.paceMetersPerDay`'s 7-day rolling window (§5.3)
  /// regardless of timezone offset. Re-fetches whenever
  /// [selectedJourneyProvider] changes, so a fresh sync tick keeps the Quest
  /// Stats pace/ETA current.
  ///
  /// 8 days of margin, not 7: the window is computed on **local** calendar
  /// days, and the query filter is a plain UTC instant comparison — one extra
  /// day covers the largest realistic UTC offset, and `QuestTimeService` does
  /// the exact local-day filtering afterwards (§13: the DB query lives here in
  /// `data/`, the calendar math stays in `domain/`).
  RecentMeteredIntervalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentMeteredIntervalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentMeteredIntervalsHash();

  @$internal
  @override
  $FutureProviderElement<List<MeteredInterval>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MeteredInterval>> create(Ref ref) {
    return recentMeteredIntervals(ref);
  }
}

String _$recentMeteredIntervalsHash() =>
    r'cce3357ac381a9f3f6fe919edcc1c42638a94254';

/// Whether the Путь tab is showing the quest catalog (`QuestPickerView`)
/// even though a quest is already active (this task's requirement: "кнопка
/// возврата к выбору других маршрутов") — distinct from `selectedJourneyProvider
/// == null`, which means no quest has ever been started. Browsing never
/// touches the active quest itself; picking a *different* journey from the
/// catalog still goes through the ordinary `SelectedJourney.start()` (§6.4:
/// only one quest active at a time), which itself exits browsing mode.
///
/// In-memory only, same placeholder-until-Phase-3 caveat as
/// `locale_provider.dart`'s `AppLocale` — this is UI navigation state, not
/// anything worth persisting across a restart.

@ProviderFor(BrowsingCatalog)
final browsingCatalogProvider = BrowsingCatalogProvider._();

/// Whether the Путь tab is showing the quest catalog (`QuestPickerView`)
/// even though a quest is already active (this task's requirement: "кнопка
/// возврата к выбору других маршрутов") — distinct from `selectedJourneyProvider
/// == null`, which means no quest has ever been started. Browsing never
/// touches the active quest itself; picking a *different* journey from the
/// catalog still goes through the ordinary `SelectedJourney.start()` (§6.4:
/// only one quest active at a time), which itself exits browsing mode.
///
/// In-memory only, same placeholder-until-Phase-3 caveat as
/// `locale_provider.dart`'s `AppLocale` — this is UI navigation state, not
/// anything worth persisting across a restart.
final class BrowsingCatalogProvider
    extends $NotifierProvider<BrowsingCatalog, bool> {
  /// Whether the Путь tab is showing the quest catalog (`QuestPickerView`)
  /// even though a quest is already active (this task's requirement: "кнопка
  /// возврата к выбору других маршрутов") — distinct from `selectedJourneyProvider
  /// == null`, which means no quest has ever been started. Browsing never
  /// touches the active quest itself; picking a *different* journey from the
  /// catalog still goes through the ordinary `SelectedJourney.start()` (§6.4:
  /// only one quest active at a time), which itself exits browsing mode.
  ///
  /// In-memory only, same placeholder-until-Phase-3 caveat as
  /// `locale_provider.dart`'s `AppLocale` — this is UI navigation state, not
  /// anything worth persisting across a restart.
  BrowsingCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browsingCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browsingCatalogHash();

  @$internal
  @override
  BrowsingCatalog create() => BrowsingCatalog();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$browsingCatalogHash() => r'd05289a64c1524e2644c2a48427e8201d494de9a';

/// Whether the Путь tab is showing the quest catalog (`QuestPickerView`)
/// even though a quest is already active (this task's requirement: "кнопка
/// возврата к выбору других маршрутов") — distinct from `selectedJourneyProvider
/// == null`, which means no quest has ever been started. Browsing never
/// touches the active quest itself; picking a *different* journey from the
/// catalog still goes through the ordinary `SelectedJourney.start()` (§6.4:
/// only one quest active at a time), which itself exits browsing mode.
///
/// In-memory only, same placeholder-until-Phase-3 caveat as
/// `locale_provider.dart`'s `AppLocale` — this is UI navigation state, not
/// anything worth persisting across a restart.

abstract class _$BrowsingCatalog extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// How far along [journeyId] the local device's own step history already
/// is, in `[0.0, 1.0]` (this task's requirement: "показывай процент
/// пройденного пути для каждого маршрута" on the catalog cards) — derived
/// straight from `StepIntervalRecords` via `StepSampleRepository
/// .totalResolvedMeters()`, the same ground truth `StepsSyncEngine.sync()`
/// itself trusts (§5.2 "derive, don't duplicate"), not from
/// `selectedJourneyProvider` — that only ever holds the *one* currently
/// active quest, but every catalog card needs its own answer, including
/// ones the user isn't on right now. A journey never started reads `0.0`,
/// same as [progressFraction]'s own `0`-meters case.

@ProviderFor(journeyProgressFraction)
final journeyProgressFractionProvider = JourneyProgressFractionFamily._();

/// How far along [journeyId] the local device's own step history already
/// is, in `[0.0, 1.0]` (this task's requirement: "показывай процент
/// пройденного пути для каждого маршрута" on the catalog cards) — derived
/// straight from `StepIntervalRecords` via `StepSampleRepository
/// .totalResolvedMeters()`, the same ground truth `StepsSyncEngine.sync()`
/// itself trusts (§5.2 "derive, don't duplicate"), not from
/// `selectedJourneyProvider` — that only ever holds the *one* currently
/// active quest, but every catalog card needs its own answer, including
/// ones the user isn't on right now. A journey never started reads `0.0`,
/// same as [progressFraction]'s own `0`-meters case.

final class JourneyProgressFractionProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// How far along [journeyId] the local device's own step history already
  /// is, in `[0.0, 1.0]` (this task's requirement: "показывай процент
  /// пройденного пути для каждого маршрута" on the catalog cards) — derived
  /// straight from `StepIntervalRecords` via `StepSampleRepository
  /// .totalResolvedMeters()`, the same ground truth `StepsSyncEngine.sync()`
  /// itself trusts (§5.2 "derive, don't duplicate"), not from
  /// `selectedJourneyProvider` — that only ever holds the *one* currently
  /// active quest, but every catalog card needs its own answer, including
  /// ones the user isn't on right now. A journey never started reads `0.0`,
  /// same as [progressFraction]'s own `0`-meters case.
  JourneyProgressFractionProvider._({
    required JourneyProgressFractionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journeyProgressFractionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journeyProgressFractionHash();

  @override
  String toString() {
    return r'journeyProgressFractionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    final argument = this.argument as String;
    return journeyProgressFraction(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyProgressFractionProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyProgressFractionHash() =>
    r'c1bb26b9c761d35973dae07d63ee846e2f5812da';

/// How far along [journeyId] the local device's own step history already
/// is, in `[0.0, 1.0]` (this task's requirement: "показывай процент
/// пройденного пути для каждого маршрута" on the catalog cards) — derived
/// straight from `StepIntervalRecords` via `StepSampleRepository
/// .totalResolvedMeters()`, the same ground truth `StepsSyncEngine.sync()`
/// itself trusts (§5.2 "derive, don't duplicate"), not from
/// `selectedJourneyProvider` — that only ever holds the *one* currently
/// active quest, but every catalog card needs its own answer, including
/// ones the user isn't on right now. A journey never started reads `0.0`,
/// same as [progressFraction]'s own `0`-meters case.

final class JourneyProgressFractionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double>, String> {
  JourneyProgressFractionFamily._()
    : super(
        retry: null,
        name: r'journeyProgressFractionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How far along [journeyId] the local device's own step history already
  /// is, in `[0.0, 1.0]` (this task's requirement: "показывай процент
  /// пройденного пути для каждого маршрута" on the catalog cards) — derived
  /// straight from `StepIntervalRecords` via `StepSampleRepository
  /// .totalResolvedMeters()`, the same ground truth `StepsSyncEngine.sync()`
  /// itself trusts (§5.2 "derive, don't duplicate"), not from
  /// `selectedJourneyProvider` — that only ever holds the *one* currently
  /// active quest, but every catalog card needs its own answer, including
  /// ones the user isn't on right now. A journey never started reads `0.0`,
  /// same as [progressFraction]'s own `0`-meters case.

  JourneyProgressFractionProvider call(String journeyId) =>
      JourneyProgressFractionProvider._(argument: journeyId, from: this);

  @override
  String toString() => r'journeyProgressFractionProvider';
}
