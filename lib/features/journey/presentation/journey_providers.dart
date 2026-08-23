import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/journey_catalog.dart';
import '../domain/journey.dart';
import '../domain/quest_selection.dart';

part 'journey_providers.g.dart';

/// The read-only quest catalog (§8). One entry today (§14: "на MVP один
/// квест («Одиссея»)"). Phase 8 swaps the data source for cached Firestore
/// metadata without changing this provider's shape.
@riverpod
List<Journey> journeyCatalogEntries(Ref ref) => journeyCatalog;

/// The currently selected/started quest, or `null` before the user picks
/// one. **In-memory only** — resets on app restart. Phase 3 (drift) is the
/// planned, durable replacement; see `docs/screens/journey.md`.
@riverpod
class SelectedJourney extends _$SelectedJourney {
  @override
  SelectedQuest? build() => null;

  /// Starts a quest. `lastSyncedAt` seeds to the start of the local
  /// calendar day (§5.2), not the exact moment, so steps already taken
  /// today are still counted once a sync runs.
  void start(String journeyId, {required DateTime now}) {
    state = SelectedQuest(
      journeyId: journeyId,
      startedAt: now,
      lastSyncedAt: DateTime(now.year, now.month, now.day),
      progressMeters: 0,
    );
  }

  /// Applies a synced progress total. Called by `steps/presentation`'s sync
  /// controller once it has resolved a delta through `stride.dart`.
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
