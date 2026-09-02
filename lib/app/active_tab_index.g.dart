// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_tab_index.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Index of the bottom-nav branch `AppShell` currently has selected
/// (`navigationShell.currentIndex`, `router.dart`'s branch order) — mirrored
/// here because `StatefulShellRoute.indexedStack` keeps every branch's
/// widget subtree mounted, just unpainted, when another tab is selected
/// (`journey_flame_scene_view.dart`'s own doc comment on this — the same
/// fact `app_shell.dart`'s achievement-sheet-close regression fix already
/// had to work around). That means a branch's own `State` never learns it
/// went off-screen on its own; this provider is the signal it's missing.
///
/// `keepAlive: true` — `AppShell` writes to this on every branch switch for
/// the whole app session, not only while something happens to be watching
/// it (the Путь tab's Flame scene may not even be mounted yet on a cold
/// start landing on a different tab).

@ProviderFor(ActiveTabIndex)
final activeTabIndexProvider = ActiveTabIndexProvider._();

/// Index of the bottom-nav branch `AppShell` currently has selected
/// (`navigationShell.currentIndex`, `router.dart`'s branch order) — mirrored
/// here because `StatefulShellRoute.indexedStack` keeps every branch's
/// widget subtree mounted, just unpainted, when another tab is selected
/// (`journey_flame_scene_view.dart`'s own doc comment on this — the same
/// fact `app_shell.dart`'s achievement-sheet-close regression fix already
/// had to work around). That means a branch's own `State` never learns it
/// went off-screen on its own; this provider is the signal it's missing.
///
/// `keepAlive: true` — `AppShell` writes to this on every branch switch for
/// the whole app session, not only while something happens to be watching
/// it (the Путь tab's Flame scene may not even be mounted yet on a cold
/// start landing on a different tab).
final class ActiveTabIndexProvider
    extends $NotifierProvider<ActiveTabIndex, int> {
  /// Index of the bottom-nav branch `AppShell` currently has selected
  /// (`navigationShell.currentIndex`, `router.dart`'s branch order) — mirrored
  /// here because `StatefulShellRoute.indexedStack` keeps every branch's
  /// widget subtree mounted, just unpainted, when another tab is selected
  /// (`journey_flame_scene_view.dart`'s own doc comment on this — the same
  /// fact `app_shell.dart`'s achievement-sheet-close regression fix already
  /// had to work around). That means a branch's own `State` never learns it
  /// went off-screen on its own; this provider is the signal it's missing.
  ///
  /// `keepAlive: true` — `AppShell` writes to this on every branch switch for
  /// the whole app session, not only while something happens to be watching
  /// it (the Путь tab's Flame scene may not even be mounted yet on a cold
  /// start landing on a different tab).
  ActiveTabIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeTabIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeTabIndexHash();

  @$internal
  @override
  ActiveTabIndex create() => ActiveTabIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeTabIndexHash() => r'4b2a6fbb0abff486a816c20785be508769aa0805';

/// Index of the bottom-nav branch `AppShell` currently has selected
/// (`navigationShell.currentIndex`, `router.dart`'s branch order) — mirrored
/// here because `StatefulShellRoute.indexedStack` keeps every branch's
/// widget subtree mounted, just unpainted, when another tab is selected
/// (`journey_flame_scene_view.dart`'s own doc comment on this — the same
/// fact `app_shell.dart`'s achievement-sheet-close regression fix already
/// had to work around). That means a branch's own `State` never learns it
/// went off-screen on its own; this provider is the signal it's missing.
///
/// `keepAlive: true` — `AppShell` writes to this on every branch switch for
/// the whole app session, not only while something happens to be watching
/// it (the Путь tab's Flame scene may not even be mounted yet on a cold
/// start landing on a different tab).

abstract class _$ActiveTabIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the Путь tab's Flame scene should currently be running its game
/// loop (CLAUDE.md §6.1/§12: "game loop stops on inactive tab") — true only
/// while the Путь branch is the one selected *and* the app itself is in the
/// foreground (`appLifecycleProvider`, the same signal
/// `BackgroundMusicController` already uses for its own pause-on-background
/// rule). `journey_flame_scene_view.dart` is the only reader.

@ProviderFor(journeySceneActive)
final journeySceneActiveProvider = JourneySceneActiveProvider._();

/// Whether the Путь tab's Flame scene should currently be running its game
/// loop (CLAUDE.md §6.1/§12: "game loop stops on inactive tab") — true only
/// while the Путь branch is the one selected *and* the app itself is in the
/// foreground (`appLifecycleProvider`, the same signal
/// `BackgroundMusicController` already uses for its own pause-on-background
/// rule). `journey_flame_scene_view.dart` is the only reader.

final class JourneySceneActiveProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the Путь tab's Flame scene should currently be running its game
  /// loop (CLAUDE.md §6.1/§12: "game loop stops on inactive tab") — true only
  /// while the Путь branch is the one selected *and* the app itself is in the
  /// foreground (`appLifecycleProvider`, the same signal
  /// `BackgroundMusicController` already uses for its own pause-on-background
  /// rule). `journey_flame_scene_view.dart` is the only reader.
  JourneySceneActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeySceneActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeySceneActiveHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return journeySceneActive(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$journeySceneActiveHash() =>
    r'aa1fd8ae931a641f12d82eff12d93c31c7796cad';
