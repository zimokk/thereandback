// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steps_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `health` package wrapper. Overridden with a fake in tests (`testing`
/// skill: never the real health plugin in a widget test).

@ProviderFor(healthAdapter)
final healthAdapterProvider = HealthAdapterProvider._();

/// The `health` package wrapper. Overridden with a fake in tests (`testing`
/// skill: never the real health plugin in a widget test).

final class HealthAdapterProvider
    extends $FunctionalProvider<HealthAdapter, HealthAdapter, HealthAdapter>
    with $Provider<HealthAdapter> {
  /// The `health` package wrapper. Overridden with a fake in tests (`testing`
  /// skill: never the real health plugin in a widget test).
  HealthAdapterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthAdapterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthAdapterHash();

  @$internal
  @override
  $ProviderElement<HealthAdapter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HealthAdapter create(Ref ref) {
    return healthAdapter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthAdapter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthAdapter>(value),
    );
  }
}

String _$healthAdapterHash() => r'402c1287b3aae4c179073c0f700e32e018152b49';

/// Drives the foreground steps-sync flow: permission checks, the Health
/// Connect "not installed" case, and syncing a delta into
/// `selectedJourneyProvider` through the pure `stride.dart` math.
///
/// Foreground only — no background delivery/WorkManager here. §7 calls
/// background sync its own architectural decision that needs a separate
/// plan; this syncs when the Путь tab opens and on pull-to-refresh
/// (see `docs/screens/steps-sync.md`).

@ProviderFor(StepsSync)
final stepsSyncProvider = StepsSyncProvider._();

/// Drives the foreground steps-sync flow: permission checks, the Health
/// Connect "not installed" case, and syncing a delta into
/// `selectedJourneyProvider` through the pure `stride.dart` math.
///
/// Foreground only — no background delivery/WorkManager here. §7 calls
/// background sync its own architectural decision that needs a separate
/// plan; this syncs when the Путь tab opens and on pull-to-refresh
/// (see `docs/screens/steps-sync.md`).
final class StepsSyncProvider
    extends $NotifierProvider<StepsSync, StepsSyncState> {
  /// Drives the foreground steps-sync flow: permission checks, the Health
  /// Connect "not installed" case, and syncing a delta into
  /// `selectedJourneyProvider` through the pure `stride.dart` math.
  ///
  /// Foreground only — no background delivery/WorkManager here. §7 calls
  /// background sync its own architectural decision that needs a separate
  /// plan; this syncs when the Путь tab opens and on pull-to-refresh
  /// (see `docs/screens/steps-sync.md`).
  StepsSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stepsSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stepsSyncHash();

  @$internal
  @override
  StepsSync create() => StepsSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StepsSyncState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StepsSyncState>(value),
    );
  }
}

String _$stepsSyncHash() => r'2c79fc96993cd98f93e5626ed7742046f8a42c77';

/// Drives the foreground steps-sync flow: permission checks, the Health
/// Connect "not installed" case, and syncing a delta into
/// `selectedJourneyProvider` through the pure `stride.dart` math.
///
/// Foreground only — no background delivery/WorkManager here. §7 calls
/// background sync its own architectural decision that needs a separate
/// plan; this syncs when the Путь tab opens and on pull-to-refresh
/// (see `docs/screens/steps-sync.md`).

abstract class _$StepsSync extends $Notifier<StepsSyncState> {
  StepsSyncState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StepsSyncState, StepsSyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StepsSyncState, StepsSyncState>,
              StepsSyncState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
