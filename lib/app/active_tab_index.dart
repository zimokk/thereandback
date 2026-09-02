import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_lifecycle.dart';

part 'active_tab_index.g.dart';

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
@Riverpod(keepAlive: true)
class ActiveTabIndex extends _$ActiveTabIndex {
  /// Matches `router.dart`'s `initialLocation: '/journey'` — the Путь
  /// branch (index 0) is what's selected before `AppShell` ever gets a
  /// chance to push a real value.
  @override
  int build() => 0;

  void set(int index) {
    if (state == index) return; // cheap to call on every AppShell rebuild.
    state = index;
  }
}

/// Index of the Путь branch in `router.dart`'s `StatefulShellRoute` — the
/// one tab [journeySceneActiveProvider] gates on. Same value as
/// `app_shell.dart`'s own `_journeyTabIndex` constant; kept as a separate
/// constant here (rather than importing that private one) since the two
/// files serve different concerns and `app_shell.dart`'s stays private to
/// its own achievement-sheet-close regression fix.
const int journeyTabIndex = 0;

/// Whether the Путь tab's Flame scene should currently be running its game
/// loop (CLAUDE.md §6.1/§12: "game loop stops on inactive tab") — true only
/// while the Путь branch is the one selected *and* the app itself is in the
/// foreground (`appLifecycleProvider`, the same signal
/// `BackgroundMusicController` already uses for its own pause-on-background
/// rule). `journey_flame_scene_view.dart` is the only reader.
@riverpod
bool journeySceneActive(Ref ref) {
  final activeIndex = ref.watch(activeTabIndexProvider);
  final lifecycle = ref.watch(appLifecycleProvider);
  return activeIndex == journeyTabIndex &&
      lifecycle == AppLifecycleState.resumed;
}
