// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lifecycle.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's current [AppLifecycleState].
///
/// Lives in `app/` rather than in a feature because it is shared
/// infrastructure: OS permission state can change while the app is
/// backgrounded — Health Connect's permission screen and Android's app
/// settings are both separate activities — so more than one feature needs
/// to re-read the platform on resume.
///
/// Features `ref.listen` this instead of each installing its own
/// [WidgetsBindingObserver]: one observer for the whole app, no feature
/// importing another's presentation layer, and a test can override this
/// provider to drive a resume without touching the real binding.

@ProviderFor(AppLifecycle)
final appLifecycleProvider = AppLifecycleProvider._();

/// The app's current [AppLifecycleState].
///
/// Lives in `app/` rather than in a feature because it is shared
/// infrastructure: OS permission state can change while the app is
/// backgrounded — Health Connect's permission screen and Android's app
/// settings are both separate activities — so more than one feature needs
/// to re-read the platform on resume.
///
/// Features `ref.listen` this instead of each installing its own
/// [WidgetsBindingObserver]: one observer for the whole app, no feature
/// importing another's presentation layer, and a test can override this
/// provider to drive a resume without touching the real binding.
final class AppLifecycleProvider
    extends $NotifierProvider<AppLifecycle, AppLifecycleState> {
  /// The app's current [AppLifecycleState].
  ///
  /// Lives in `app/` rather than in a feature because it is shared
  /// infrastructure: OS permission state can change while the app is
  /// backgrounded — Health Connect's permission screen and Android's app
  /// settings are both separate activities — so more than one feature needs
  /// to re-read the platform on resume.
  ///
  /// Features `ref.listen` this instead of each installing its own
  /// [WidgetsBindingObserver]: one observer for the whole app, no feature
  /// importing another's presentation layer, and a test can override this
  /// provider to drive a resume without touching the real binding.
  AppLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLifecycleHash();

  @$internal
  @override
  AppLifecycle create() => AppLifecycle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLifecycleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLifecycleState>(value),
    );
  }
}

String _$appLifecycleHash() => r'e062174932f88875bf19e391e0caefe9774a96cc';

/// The app's current [AppLifecycleState].
///
/// Lives in `app/` rather than in a feature because it is shared
/// infrastructure: OS permission state can change while the app is
/// backgrounded — Health Connect's permission screen and Android's app
/// settings are both separate activities — so more than one feature needs
/// to re-read the platform on resume.
///
/// Features `ref.listen` this instead of each installing its own
/// [WidgetsBindingObserver]: one observer for the whole app, no feature
/// importing another's presentation layer, and a test can override this
/// provider to drive a resume without touching the real binding.

abstract class _$AppLifecycle extends $Notifier<AppLifecycleState> {
  AppLifecycleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppLifecycleState, AppLifecycleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppLifecycleState, AppLifecycleState>,
              AppLifecycleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
