// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievements_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The drift-backed trophy store (§6.3). Overridden with an in-memory
/// `AppDatabase` in tests via `appDatabaseProvider` (`testing` skill).

@ProviderFor(achievementRepository)
final achievementRepositoryProvider = AchievementRepositoryProvider._();

/// The drift-backed trophy store (§6.3). Overridden with an in-memory
/// `AppDatabase` in tests via `appDatabaseProvider` (`testing` skill).

final class AchievementRepositoryProvider
    extends
        $FunctionalProvider<
          AchievementRepository,
          AchievementRepository,
          AchievementRepository
        >
    with $Provider<AchievementRepository> {
  /// The drift-backed trophy store (§6.3). Overridden with an in-memory
  /// `AppDatabase` in tests via `appDatabaseProvider` (`testing` skill).
  AchievementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementRepositoryHash();

  @$internal
  @override
  $ProviderElement<AchievementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AchievementRepository create(Ref ref) {
    return achievementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AchievementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AchievementRepository>(value),
    );
  }
}

String _$achievementRepositoryHash() =>
    r'fc0c3d1d1147a5c9f435714f8567f1c5d40bf04a';

/// Every persisted trophy unlock, read fresh whenever the Трофеи tab is
/// watching (autoDispose default — leaving the tab drops this, so the next
/// visit re-queries current data rather than showing a stale cache).
/// `steps_providers.dart`'s `StepsSync.sync()` also invalidates this
/// explicitly for the one case autoDispose doesn't cover on its own: the
/// tab open and watching *while* a sync lands.

@ProviderFor(achievementUnlocks)
final achievementUnlocksProvider = AchievementUnlocksProvider._();

/// Every persisted trophy unlock, read fresh whenever the Трофеи tab is
/// watching (autoDispose default — leaving the tab drops this, so the next
/// visit re-queries current data rather than showing a stale cache).
/// `steps_providers.dart`'s `StepsSync.sync()` also invalidates this
/// explicitly for the one case autoDispose doesn't cover on its own: the
/// tab open and watching *while* a sync lands.

final class AchievementUnlocksProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<DateTime>>>,
          Map<String, List<DateTime>>,
          FutureOr<Map<String, List<DateTime>>>
        >
    with
        $FutureModifier<Map<String, List<DateTime>>>,
        $FutureProvider<Map<String, List<DateTime>>> {
  /// Every persisted trophy unlock, read fresh whenever the Трофеи tab is
  /// watching (autoDispose default — leaving the tab drops this, so the next
  /// visit re-queries current data rather than showing a stale cache).
  /// `steps_providers.dart`'s `StepsSync.sync()` also invalidates this
  /// explicitly for the one case autoDispose doesn't cover on its own: the
  /// tab open and watching *while* a sync lands.
  AchievementUnlocksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementUnlocksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementUnlocksHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, List<DateTime>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<DateTime>>> create(Ref ref) {
    return achievementUnlocks(ref);
  }
}

String _$achievementUnlocksHash() =>
    r'5a46204d3c009f3877a284825a95730e2f71a509';

/// Today's total distance across every quest — the live number a daily
/// trophy's progress line needs (this task's requirement: "для ежедневных —
/// прогресс за сегодняшний день"), as opposed to [achievementUnlocksProvider]'s
/// forever-cumulative unlock history. autoDispose default, same as
/// [achievementUnlocksProvider]: leaving the Трофеи tab drops the cached
/// read, so the next visit re-queries current data. `steps_providers.dart`'s
/// `StepsSync.sync()` invalidates this alongside [achievementUnlocksProvider]
/// for the one case autoDispose doesn't cover on its own — the tab open and
/// watching while a sync lands.

@ProviderFor(todayAllQuestsMeters)
final todayAllQuestsMetersProvider = TodayAllQuestsMetersProvider._();

/// Today's total distance across every quest — the live number a daily
/// trophy's progress line needs (this task's requirement: "для ежедневных —
/// прогресс за сегодняшний день"), as opposed to [achievementUnlocksProvider]'s
/// forever-cumulative unlock history. autoDispose default, same as
/// [achievementUnlocksProvider]: leaving the Трофеи tab drops the cached
/// read, so the next visit re-queries current data. `steps_providers.dart`'s
/// `StepsSync.sync()` invalidates this alongside [achievementUnlocksProvider]
/// for the one case autoDispose doesn't cover on its own — the tab open and
/// watching while a sync lands.

final class TodayAllQuestsMetersProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Today's total distance across every quest — the live number a daily
  /// trophy's progress line needs (this task's requirement: "для ежедневных —
  /// прогресс за сегодняшний день"), as opposed to [achievementUnlocksProvider]'s
  /// forever-cumulative unlock history. autoDispose default, same as
  /// [achievementUnlocksProvider]: leaving the Трофеи tab drops the cached
  /// read, so the next visit re-queries current data. `steps_providers.dart`'s
  /// `StepsSync.sync()` invalidates this alongside [achievementUnlocksProvider]
  /// for the one case autoDispose doesn't cover on its own — the tab open and
  /// watching while a sync lands.
  TodayAllQuestsMetersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayAllQuestsMetersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayAllQuestsMetersHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return todayAllQuestsMeters(ref);
  }
}

String _$todayAllQuestsMetersHash() =>
    r'e8d0279b099852e2729095f1dd4313b4763aa2a5';
