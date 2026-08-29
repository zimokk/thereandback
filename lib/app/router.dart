import 'package:go_router/go_router.dart';

import '../features/achievements/presentation/achievements_tab.dart';
import '../features/friends/presentation/challengers_tab.dart';
import '../features/journey/presentation/journey_tab.dart';
import '../features/profile/presentation/settings_tab.dart';
import '../features/quest_map/presentation/quest_stats_tab.dart';
import 'app_shell.dart';

/// Five bottom-tab branches (§6). Each branch keeps its own navigation
/// stack via `StatefulShellRoute.indexedStack`, so switching tabs doesn't
/// lose a branch's scroll/nav state.
final GoRouter appRouter = GoRouter(
  initialLocation: '/journey',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journey',
              builder: (context, state) => const JourneyTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quest-stats',
              builder: (context, state) => const QuestStatsTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/achievements',
              builder: (context, state) => const AchievementsTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/friends',
              builder: (context, state) => const ChallengersTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsTab(),
            ),
          ],
        ),
      ],
    ),
  ],
);
