import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/database_provider.dart';
import '../../../core/local_owner.dart';
import '../data/journey_catalog.dart';
import '../data/progress_repository.dart';
import '../domain/journey.dart';
import '../domain/quest_selection.dart';
import '../domain/quest_time_service.dart';

part 'journey_providers.g.dart';

/// The read-only quest catalog (§8). One entry today (§14: "на MVP один
/// квест («Одиссея»)"). Phase 8 swaps the data source for cached Firestore
/// metadata without changing this provider's shape.
@riverpod
List<Journey> journeyCatalogEntries(Ref ref) => journeyCatalog;

/// The drift-backed store for the active quest (§5.2, §8). Overridden with
/// an in-memory `AppDatabase` in tests via `appDatabaseProvider`
/// (`testing` skill).
@riverpod
ProgressRepository progressRepository(Ref ref) =>
    DriftProgressRepository(ref.watch(appDatabaseProvider));

/// The currently selected/started quest, or `null` before the user picks
/// one, or before the persisted quest (if any) has finished loading.
///
/// Durable since Phase 3: [start] and [applySyncedProgress] write through
/// [progressRepositoryProvider], and [build] restores whatever was
/// persisted — a killed-and-restarted app no longer loses `lastSyncedAt`
/// or `progressMeters` (see `docs/screens/steps-sync.md`).
@riverpod
class SelectedJourney extends _$SelectedJourney {
  @override
  SelectedQuest? build() {
    // Same "fire an async check from a sync build()" idiom as
    // `StepsSync.build()` (steps/presentation/steps_providers.dart) — the
    // widget renders `null` for one frame until this resolves.
    unawaited(_restore());
    return null;
  }

  Future<void> _restore() async {
    final restored = await ref
        .read(progressRepositoryProvider)
        .loadSelectedQuest(localOwnerId);
    if (restored != null) state = restored;
  }

  /// Starts a quest. `lastSyncedAt` seeds to the exact moment the user
  /// tapped "Start quest" (§5.2) — steps taken earlier that day, before the
  /// quest existed, are never counted.
  void start(String journeyId, {required DateTime now}) {
    state = SelectedQuest(
      journeyId: journeyId,
      startedAt: now,
      lastSyncedAt: now,
      progressMeters: 0,
    );
    unawaited(
      ref
          .read(progressRepositoryProvider)
          .startQuest(localOwnerId, journeyId: journeyId, startedAt: now),
    );
  }

  /// Applies a synced progress total. Called by `steps/presentation`'s sync
  /// controller once it has resolved a delta through `stride.dart`.
  ///
  /// In-memory only — no persistence write here. The durable, idempotent
  /// record was already written by `StepsSync.sync()` via
  /// `stepSampleRepositoryProvider` *before* this is called; progress is
  /// derived from that log, not stored as its own mutable total (§5.2, see
  /// `progress_repository.dart`), so there is nothing left to persist.
  void applySyncedProgress({
    required int progressMeters,
    required DateTime syncedAt,
  }) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      progressMeters: progressMeters,
      lastSyncedAt: syncedAt,
    );
  }
}

/// The catalog [Journey] record matching the currently selected quest, or
/// `null` if nothing is selected (or the id somehow isn't in the catalog).
@riverpod
Journey? selectedJourneyDetails(Ref ref) {
  final selected = ref.watch(selectedJourneyProvider);
  if (selected == null) return null;
  return findJourney(selected.journeyId);
}

/// Raw interval history for the active quest, wide enough to cover
/// `QuestTimeService.paceMetersPerDay`'s 7-day rolling window (§5.3)
/// regardless of timezone offset. Re-fetches whenever
/// [selectedJourneyProvider] changes, so a fresh sync tick keeps the Quest
/// Stats pace/ETA current.
///
/// 8 days of margin, not 7: the window is computed on **local** calendar
/// days, and the query filter is a plain UTC instant comparison — one extra
/// day covers the largest realistic UTC offset, and `QuestTimeService` does
/// the exact local-day filtering afterwards (§13: the DB query lives here in
/// `data/`, the calendar math stays in `domain/`).
@riverpod
Future<List<MeteredInterval>> recentMeteredIntervals(Ref ref) async {
  final quest = ref.watch(selectedJourneyProvider);
  if (quest == null) return const [];
  return ref
      .watch(progressRepositoryProvider)
      .recentMeteredIntervals(
        localOwnerId,
        journeyId: quest.journeyId,
        since: DateTime.now().subtract(const Duration(days: 8)),
      );
}
