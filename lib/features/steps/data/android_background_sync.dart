import 'package:workmanager/workmanager.dart';

import '../../../core/local_owner.dart';
import '../../../data/drift/database.dart';
import '../../journey/data/android_lock_screen_channel.dart';
import '../../journey/data/journey_catalog.dart';
import '../../journey/data/progress_repository.dart';
import '../../journey/domain/lock_screen_snapshot.dart';
import 'health_adapter.dart';
import 'step_sample_repository.dart';
import 'steps_sync_engine.dart';

/// The §7 background-sync mechanism, scoped to Android: a `workmanager`
/// periodic task that syncs steps and refreshes the lock-screen
/// notification even while the app isn't open.
///
/// 15 minutes is Android `WorkManager`'s own floor for periodic work — this
/// can lag live steps by up to that long, which is the accepted trade-off
/// of picking a mechanism now instead of staying foreground-only (see the
/// architecture plan this feature shipped with).
const Duration androidLockScreenSyncFrequency = Duration(minutes: 15);

const String androidLockScreenSyncUniqueName = 'android-lock-screen-sync';
const String androidLockScreenSyncTaskName = 'androidLockScreenSync';

/// Registers/cancels the periodic task. Owned by
/// `journey/presentation/lock_screen_controller.dart`: registered when the
/// feature is turned on, cancelled when it's turned off or the quest
/// completes.
class AndroidBackgroundSync {
  AndroidBackgroundSync([Workmanager? workmanager])
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  Future<void> register() {
    return _workmanager.registerPeriodicTask(
      androidLockScreenSyncUniqueName,
      androidLockScreenSyncTaskName,
      frequency: androidLockScreenSyncFrequency,
      // Already-scheduled work keeps running as-is; `lock_screen_controller`
      // only calls this once per "feature turned on" transition, never on
      // every sync, so there's nothing to replace.
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  Future<void> cancel() =>
      _workmanager.cancelByUniqueName(androidLockScreenSyncUniqueName);
}

/// Runs in a separate background isolate/engine that `workmanager` spins up
/// — no widget tree, no running `ProviderContainer`. Everything it needs is
/// constructed fresh here rather than read off a `Ref`, which is exactly
/// why `data/steps_sync_engine.dart` was extracted out of the foreground
/// provider: this callback and `StepsSync.sync()` share the same sync
/// algorithm and the same §5.2 idempotency key, so a background tick and a
/// later foreground sync of the same interval can never double-credit
/// distance.
///
/// Must stay a top-level function annotated `@pragma('vm:entry-point')` —
/// tree-shaking would otherwise drop it, since nothing in the normal
/// widget/provider graph calls it directly.
@pragma('vm:entry-point')
void androidBackgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != androidLockScreenSyncTaskName) return true;

    // Same on-disk file `_openConnection()` always resolves to (see
    // `data/drift/database.dart`) — safe to open a second, independent
    // connection to it from this isolate.
    final db = AppDatabase();
    try {
      final quest = await DriftProgressRepository(db)
          .loadSelectedQuest(localOwnerId);
      if (quest == null) return true; // no active quest — nothing to do.

      final journey = findJourney(quest.journeyId);
      if (journey == null) return true; // shouldn't happen; not this task's

      final healthAdapter = HealthPackageAdapter();
      await healthAdapter.configure();
      // Permission may have been revoked since this task was registered
      // (health onboarding is separate from the lock-screen toggle) — skip
      // this tick rather than let a health-plugin call throw.
      if (await healthAdapter.hasStepsPermission() != true) return true;

      final engine = StepsSyncEngine(
        healthAdapter: healthAdapter,
        stepSampleRepository: DriftStepSampleRepository(db),
      );
      final now = DateTime.now();
      final result = await engine.sync(quest: quest, now: now);

      final snapshot = buildLockScreenSnapshot(
        quest: quest.copyWith(
          progressMeters: result.progressMeters,
          lastSyncedAt: result.syncedAt,
        ),
        journey: journey,
        now: now,
      );
      await AndroidLockScreenChannel().update(snapshot);
      return true;
    } catch (_) {
      // Let WorkManager's own retry/backoff policy handle a transient
      // failure (e.g. the health plugin briefly unavailable) rather than
      // silently swallowing it.
      return false;
    } finally {
      await db.close();
    }
  });
}
