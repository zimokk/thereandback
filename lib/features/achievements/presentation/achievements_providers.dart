import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/database_provider.dart';
import '../../../core/local_owner.dart';
import '../data/achievement_repository.dart';

part 'achievements_providers.g.dart';

/// The drift-backed trophy store (§6.3). Overridden with an in-memory
/// `AppDatabase` in tests via `appDatabaseProvider` (`testing` skill).
@riverpod
AchievementRepository achievementRepository(Ref ref) =>
    DriftAchievementRepository(ref.watch(appDatabaseProvider));

/// Every persisted trophy unlock, read fresh whenever the Трофеи tab is
/// watching (autoDispose default — leaving the tab drops this, so the next
/// visit re-queries current data rather than showing a stale cache).
/// `steps_providers.dart`'s `StepsSync.sync()` also invalidates this
/// explicitly for the one case autoDispose doesn't cover on its own: the
/// tab open and watching *while* a sync lands.
@riverpod
Future<Map<String, List<DateTime>>> achievementUnlocks(Ref ref) =>
    ref.watch(achievementRepositoryProvider).loadUnlocks(localOwnerId);
