import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/colors.dart';
import '../features/journey/presentation/lock_screen_controller.dart';
import '../l10n/app_localizations.dart';

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
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
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
                icon: const Icon(Icons.people_outline),
                label: l10n.navFriends,
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
