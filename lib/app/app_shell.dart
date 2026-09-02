import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/colors.dart';
import '../design/components/app_snackbar.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import '../features/audio/presentation/background_music_provider.dart';
import '../features/friends/presentation/friends_providers.dart';
import '../features/journey/presentation/lock_screen_controller.dart';
import '../l10n/app_localizations.dart';
import 'active_tab_index.dart';

/// Index of the Друзья branch in [AppShell]'s `items`/the router's
/// branches (`app/router.dart`) — the one tab this task's requirement
/// gates on [friendsUnlockedProvider].
const int _friendsTabIndex = 3;

/// Index of the Путь branch — the one tab whose achievement-marker popup
/// (`achievement_overlay.dart`'s `_showAchievementDetails`) needs closing on
/// the way out (styling fix regression, see that function's doc comment).
/// Same value as `active_tab_index.dart`'s own `journeyTabIndex` — kept as a
/// separate private constant here since it predates that file and serves
/// this different concern (closing a stray sheet, not pausing a game loop).
const int _journeyTabIndex = 0;

/// Compact bottom-nav height (styling fix — the stock `BottomNavigationBar`
/// read as visually heavy). Includes the row itself, not the `SafeArea`
/// inset below it.
const double _navBarHeight = 56;

/// Icon size for every nav item — smaller than `BottomNavigationBar`'s
/// default 24, part of the same "more compact" styling fix.
const double _navIconSize = 22;

/// The bottom nav shell wrapping all five tab branches (§6). One nav item
/// per `StatefulShellBranch` in `router.dart`.
///
/// A hand-rolled row rather than `BottomNavigationBar` (styling fix): stock
/// Material gave no way to both shrink the bar *and* paint a capsule behind
/// the active icon, and its label sizing had no fallback for a locale whose
/// longest label ("Настройки") clipped at the default font size.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly keeps `LockScreenController` alive (and its build()-time
    // restore-then-refreshStatus running) for the whole app session,
    // starting the moment the app opens — not only once the user happens to
    // visit Настройки. See that provider's doc comment for why a restart
    // needs this to reconcile a permission revoked while the app was
    // closed. The value itself isn't used here.
    ref.watch(lockScreenControllerProvider);

    // Same reasoning, for the background-music lifecycle guard (§6.5):
    // built once here so the pause-on-background/resume-on-foreground rule
    // (`BackgroundMusicController`'s `appLifecycleProvider` listener) is
    // live for the whole session the moment the app opens, not only once
    // the user happens to visit Настройки and flips the toggle on.
    ref.watch(backgroundMusicControllerProvider);

    // Pushes the currently selected branch into `activeTabIndexProvider`
    // (`active_tab_index.dart`) so `journey_flame_scene_view.dart` knows
    // when to pause its Flame game loop — deferred to a post-frame callback
    // rather than written synchronously here, since Riverpod refuses a
    // provider write from inside another widget's own `build()`. Cheap to
    // call on every rebuild: `ActiveTabIndex.set` no-ops once the value
    // already matches.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activeTabIndexProvider.notifier)
          .set(navigationShell.currentIndex);
    });

    final l10n = AppLocalizations.of(context)!;
    // This task's requirement: the Друзья tab stays inactive until the
    // user has logged in and has a nickname (§6.4/§6.5/§8) —
    // `friendsUnlockedProvider`'s own doc comment has the exact condition.
    final friendsUnlocked = ref.watch(friendsUnlockedProvider);

    final items = [
      _NavItemData(icon: Icons.route_outlined, label: l10n.navJourney),
      _NavItemData(icon: Icons.map_outlined, label: l10n.navQuestStats),
      _NavItemData(
        icon: Icons.emoji_events_outlined,
        label: l10n.navAchievements,
      ),
      _NavItemData(
        icon: Icons.people_outline,
        label: l10n.navFriends,
        enabled: friendsUnlocked,
        disabledTooltip: friendsUnlocked ? null : l10n.navFriendsLockedTooltip,
      ),
      _NavItemData(icon: Icons.settings_outlined, label: l10n.navSettings),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _navBarHeight,
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: _NavItem(
                      data: items[index],
                      selected: navigationShell.currentIndex == index,
                      onTap: () {
                        // Blocks navigation into the locked tab entirely — a
                        // tap is never a silent no-op (§7), it explains why
                        // with a snackbar instead. `ChallengersTab` itself
                        // also guards its own content the same way, in case
                        // this tab is ever reached by another path (e.g. a
                        // restored navigation stack) — this is the primary
                        // gate the task asked for ("кнопка... должна
                        // оставаться неактивной").
                        if (index == _friendsTabIndex && !friendsUnlocked) {
                          showAppSnackBar(context, l10n.friendsLockedBody);
                          return;
                        }
                        // Closes an open achievement-marker popup before
                        // leaving the Путь tab (styling fix regression) — it
                        // lives on the root Navigator (see that popup's own
                        // doc comment for why), so popping it here, rather
                        // than relying on the tab switch itself, is the only
                        // way it actually closes instead of staying stacked
                        // over whichever tab the user switches to.
                        if (navigationShell.currentIndex == _journeyTabIndex &&
                            index != _journeyTabIndex) {
                          final rootNavigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          if (rootNavigator.canPop()) rootNavigator.pop();
                        }
                        navigationShell.goBranch(
                          index,
                          initialLocation:
                              index == navigationShell.currentIndex,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Static content for one nav item — kept separate from [_NavItem] so
/// [AppShell] can build the whole `items` list up front, the same shape the
/// old `BottomNavigationBarItem` list had.
class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.disabledTooltip,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final String? disabledTooltip;
}

/// One tab: an icon (in a gold capsule behind it while [selected]) above an
/// adaptively-sized label. `FittedBox` + `maxLines: 1` is the "адаптация
/// размера текста" the styling fix asked for — "Настройки"/"Settings" (this
/// tab set's longest label) shrinks to fit rather than clipping, instead of
/// swapping in a shorter, less specific word.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = data.enabled;
    final color = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : selected
        ? AppColors.gold
        : AppColors.textSecondary;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            // The capsule behind the active icon (styling fix — "капсула
            // за иконкой"), not just a color swap on the icon itself.
            color: selected ? AppColors.surfaceActive : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Icon(data.icon, size: _navIconSize, color: color),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.label,
              maxLines: 1,
              style: AppTypography.bodySecondary.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );

    final tappable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );

    return data.disabledTooltip == null
        ? tappable
        : Tooltip(message: data.disabledTooltip!, child: tappable);
  }
}
