import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/colors.dart';
import '../design/components/app_snackbar.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import '../features/friends/presentation/friends_providers.dart';
import '../features/journey/presentation/lock_screen_controller.dart';
import '../l10n/app_localizations.dart';

/// Index of the Друзья branch in [AppShell]'s `items`/the router's
/// branches (`app/router.dart`) — the one tab this task's requirement
/// gates on [friendsUnlockedProvider].
const int _friendsTabIndex = 3;

/// Index of the Путь branch — the one tab whose achievement-marker popup
/// (`journey_path_view.dart`'s `_showAchievementDetails`) needs closing on
/// the way out (styling fix regression, see that function's doc comment).
const int _journeyTabIndex = 0;

/// Compact bottom-nav height (styling fix — the stock `BottomNavigationBar`
/// read as visually heavy). Includes the row itself, not the `SafeArea`
/// inset below it.
const double _navBarHeight = 56;

/// Icon size for every nav item — smaller than `BottomNavigationBar`'s
/// default 24, part of the same "more compact" styling fix.
const double _navIconSize = 22;

/// Height of the invisible edge-swipe strip anchored to the very bottom of
/// the screen, on top of the device's safe-area inset. Kept thin so it
/// doesn't compete with vertical scrolling/dragging inside tab content —
/// only a touch that starts this close to the physical bottom edge can
/// reveal the nav bar (2026-08-31, hide-by-default nav, see CLAUDE.md §14).
const double _edgeSwipeZoneHeight = 20;

/// Vertical drag distance (logical px) that fully opens or closes the nav
/// bar — the drag is interactive up to this distance, then snaps to fully
/// open/closed on release based on position and velocity.
const double _dragExtent = 120;

/// Fling velocity (logical px/s) past which a single swipe snaps the nav
/// bar open/closed regardless of how far it was dragged.
const double _flingVelocity = 600;

/// The bottom nav overlay wrapping all five tab branches (§6). One nav item
/// per `StatefulShellBranch` in `router.dart`.
///
/// Hidden by default across the whole app (2026-08-31, direct request —
/// see CLAUDE.md §14): tab content fills the full screen, and the nav bar
/// is a temporary overlay revealed by swiping up from the bottom edge,
/// dismissed by tapping the content behind it or swiping back down. A
/// hand-rolled row rather than `BottomNavigationBar` (styling fix): stock
/// Material gave no way to both shrink the bar *and* paint a capsule behind
/// the active icon, and its label sizing had no fallback for a locale whose
/// longest label ("Настройки") clipped at the default font size.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  /// 0 = nav bar fully hidden (translated off-screen below), 1 = fully
  /// shown. Driven interactively by the edge-swipe drag, then animated to
  /// settle at either end.
  late final AnimationController _navController;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  void _openNav() => _navController.animateTo(1, curve: Curves.easeOutCubic);

  void _closeNav() => _navController.animateTo(0, curve: Curves.easeInCubic);

  void _handleDragUpdate(DragUpdateDetails details) {
    _navController.value =
        (_navController.value - details.delta.dy / _dragExtent).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_flingVelocity) {
      _openNav();
    } else if (velocity >= _flingVelocity) {
      _closeNav();
    } else if (_navController.value > 0.5) {
      _openNav();
    } else {
      _closeNav();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eagerly keeps `LockScreenController` alive (and its build()-time
    // restore-then-refreshStatus running) for the whole app session,
    // starting the moment the app opens — not only once the user happens to
    // visit Настройки. See that provider's doc comment for why a restart
    // needs this to reconcile a permission revoked while the app was
    // closed. The value itself isn't used here.
    ref.watch(lockScreenControllerProvider);

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

    void handleItemTap(int index) {
      // Blocks navigation into the locked tab entirely — a tap is never a
      // silent no-op (§7), it explains why with a snackbar instead.
      // `ChallengersTab` itself also guards its own content the same way,
      // in case this tab is ever reached by another path (e.g. a restored
      // navigation stack) — this is the primary gate the task asked for
      // ("кнопка... должна оставаться неактивной"). Left open on this path
      // — nothing navigated, so there's nothing for the overlay to reveal.
      if (index == _friendsTabIndex && !friendsUnlocked) {
        showAppSnackBar(context, l10n.friendsLockedBody);
        return;
      }
      // Closes an open achievement-marker popup before leaving the Путь
      // tab (styling fix regression) — it lives on the root Navigator (see
      // that popup's own doc comment for why), so popping it here, rather
      // than relying on the tab switch itself, is the only way it actually
      // closes instead of staying stacked over whichever tab the user
      // switches to.
      if (widget.navigationShell.currentIndex == _journeyTabIndex &&
          index != _journeyTabIndex) {
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        if (rootNavigator.canPop()) rootNavigator.pop();
      }
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
      // The nav bar is a temporary overlay (2026-08-31) — once it's done
      // its job of picking a destination, get out of the way of the full
      // screen again rather than lingering open.
      _closeNav();
    }

    final navBar = DecoratedBox(
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
                    selected: widget.navigationShell.currentIndex == index,
                    onTap: () => handleItemTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: widget.navigationShell),
          // The edge-swipe strip that opens the nav bar. Anchored to the
          // physical bottom edge (below the safe-area inset too, so it's
          // reachable even on gesture-nav devices) and kept thin — see
          // `_edgeSwipeZoneHeight`'s doc comment for why.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height:
                _edgeSwipeZoneHeight + MediaQuery.of(context).padding.bottom,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
            ),
          ),
          // The barrier that dismisses the nav bar: a tap anywhere on the
          // content behind it, or a swipe down, closes it. Only
          // hit-testable while the nav bar is at least partially open —
          // otherwise it would swallow every tap into tab content.
          AnimatedBuilder(
            animation: _navController,
            builder: (context, _) => IgnorePointer(
              ignoring: _navController.value == 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeNav,
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: _handleDragEnd,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _navController,
            builder: (context, child) => Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FractionalTranslation(
                translation: Offset(0, 1 - _navController.value),
                child: child,
              ),
            ),
            child: navBar,
          ),
        ],
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
