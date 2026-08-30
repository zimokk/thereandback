import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/colors.dart';
import '../design/components/app_snackbar.dart';
import '../features/friends/presentation/friends_providers.dart';
import '../features/journey/presentation/lock_screen_controller.dart';
import '../l10n/app_localizations.dart';

/// Index of the Друзья branch in [AppShell]'s `items`/the router's
/// branches (`app/router.dart`) — the one tab this task's requirement
/// gates on [friendsUnlockedProvider].
const int _friendsTabIndex = 3;

/// The bottom nav shell wrapping all five tab branches (§6). One
/// `BottomNavigationBar` index per `StatefulShellBranch` in `router.dart`.
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

    final l10n = AppLocalizations.of(context)!;
    // This task's requirement: the Друзья tab stays inactive until the
    // user has logged in and has a nickname (§6.4/§6.5/§8) —
    // `friendsUnlockedProvider`'s own doc comment has the exact condition.
    final friendsUnlocked = ref.watch(friendsUnlockedProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: navigationShell.currentIndex,
            selectedItemColor: AppColors.gold,
            unselectedItemColor: AppColors.textSecondary,
            onTap: (index) {
              // Blocks navigation into the locked tab entirely — a tap is
              // never a silent no-op (§7), it explains why with a snackbar
              // instead. `ChallengersTab` itself also guards its own
              // content the same way, in case this tab is ever reached by
              // another path (e.g. a restored navigation stack) — this is
              // the primary gate the task asked for ("кнопка... должна
              // оставаться неактивной").
              if (index == _friendsTabIndex && !friendsUnlocked) {
                showAppSnackBar(context, l10n.friendsLockedBody);
                return;
              }
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.route_outlined),
                label: l10n.navJourney,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map_outlined),
                label: l10n.navQuestStats,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.emoji_events_outlined),
                label: l10n.navAchievements,
              ),
              BottomNavigationBarItem(
                // Dimmed below the normal unselected color while locked —
                // visibly different from every other (merely unselected)
                // item, not just unresponsive silently.
                icon: Icon(
                  Icons.people_outline,
                  color: friendsUnlocked
                      ? null
                      : AppColors.textSecondary.withValues(alpha: 0.35),
                ),
                label: l10n.navFriends,
                tooltip: friendsUnlocked ? null : l10n.navFriendsLockedTooltip,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                label: l10n.navSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
