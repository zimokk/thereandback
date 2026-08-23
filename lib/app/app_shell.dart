import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/colors.dart';
import '../l10n/app_localizations.dart';

/// The bottom nav shell wrapping all four tab branches (§6, trimmed to the
/// four this base ships — no Friends tab yet). One `BottomNavigationBar`
/// index per `StatefulShellBranch` in `router.dart`.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
