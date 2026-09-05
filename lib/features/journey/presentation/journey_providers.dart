import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/database_provider.dart';
import '../../../core/local_owner.dart';
import '../../../data/firestore/firestore_providers.dart'
    show pushProgressBestEffort;
import '../../steps/presentation/steps_providers.dart'
    show stepSampleRepositoryProvider;
import '../data/journey_catalog.dart';
import '../data/progress_repository.dart';
import '../domain/journey.dart';
import '../domain/progress_fraction.dart';
import '../domain/quest_selection.dart';
import '../domain/quest_time_service.dart';

part 'journey_providers.g.dart';

/// The read-only quest catalog (§8). Two entries as of §14's 2026-09-05
/// decision (superseding the earlier "на MVP один квест («Одиссея»)"). Phase
/// 8 swaps the data source for cached Firestore metadata without changing
/// this provider's shape.
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
  /// [build]'s own cold-start restore — kept around so [ensureRestored] can
  /// await the exact same one-shot operation rather than firing a second,
  /// redundant read. Defaults to an already-completed future (rather than
  /// `late`) so a test double that overrides [build] without going through
  /// this class's own — e.g. `friends_providers_test.dart`'s
  /// `_FixedSelectedJourney` — still has [ensureRestored] resolve instantly
  /// instead of throwing on an unset `late` field.
  Future<void> _initialRestore = Future<void>.value();

  @override
  SelectedQuest? build() {
    // Same "fire an async check from a sync build()" idiom as
    // `StepsSync.build()` (steps/presentation/steps_providers.dart) — the
    // widget renders `null` for one frame until this resolves.
    _initialRestore = _restore();
    unawaited(_initialRestore);
    return null;
  }

  Future<void> _restore() async {
    final restored = await ref
        .read(progressRepositoryProvider)
        .loadSelectedQuest(localOwnerId);
    if (restored != null) state = restored;
  }

  /// Waits for [build]'s own cold-start restore to finish, if it hasn't
  /// already — for a caller that needs to *read* [state] and treat it as
  /// authoritative rather than possibly still the pre-restore `null`.
  ///
  /// `AuthController._reconcileProgressWithCloud` (`app/auth_provider.dart`,
  /// §8, §14 — "repeat login") is the motivating case: it compares this
  /// device's local progress against the cloud account's own total to
  /// decide which one wins. Reading [state] with a bare `ref.read` there
  /// used to race this provider's own unawaited startup restore — on a
  /// device that already had real progress from a previous session, a
  /// Google sign-in fired quickly enough (small quest catalog, cached
  /// account, no picker shown) could read `state` while it was still
  /// `null`, treat the device's actual progress as zero, and let a smaller
  /// (or absent) cloud total silently overwrite it via `restoreFromCloud`.
  /// Awaiting this first closes that window — safe even for a caller that
  /// doesn't need it: once the initial restore has already resolved,
  /// awaiting it again is an instant no-op, and it never re-fires the read
  /// or touches [state] itself (unlike [reload], see below).
  Future<void> ensureRestored() => _initialRestore;

  /// Re-reads the persisted quest from drift, discarding whatever is
  /// currently in memory. Used by `AuthController`
  /// (`app/auth_provider.dart`, §8, §14 — "repeat login") after it writes a
  /// reconciled cloud total into drift via `ProgressRepository
  /// .restoreFromCloud` behind this provider's back — this state needs to
  /// be told to catch up, the same way [build]'s own [_restore] call
  /// populates it on a cold start.
  Future<void> reload() => _restore();

  /// Starts a quest. `lastSyncedAt` seeds to the exact moment the user
  /// tapped "Start quest" (§5.2) — steps taken earlier that day, before the
  /// quest existed, are never counted.
  ///
  /// Two durable writes fire alongside the in-memory state, both
  /// fire-and-forget: the local drift row (source of truth, §8) and an
  /// initial `progressMeters: 0` push to Firestore via
  /// [pushProgressBestEffort] — so `users/{uid}/progress/{journeyId}`
  /// reflects the quest existing from this same tap, rather than only
  /// appearing after the first steps sync lands. A friend's row/pin and
  /// `AuthController`'s repeat-login reconciliation (§8, §14) both read
  /// that document, so waiting on the first sync left a window where a
  /// just-started quest was invisible to both.
  ///
  /// No-op when [journeyId] is already the active quest (bug fix: the
  /// catalog's card button re-fires this same call when the user reopens
  /// the catalog via "browsing" mode — §6.1's own return-to-catalog button —
  /// and taps the card of the quest they're already on; without this guard
  /// that reset `startedAt`/`lastSyncedAt` to `now` and `progressMeters` to
  /// `0` both in memory and, via the Firestore push above, in the cloud
  /// document too — wiping real progress until the next steps sync happened
  /// to catch up). Starting a genuinely *different* quest is unaffected —
  /// see `quest_picker_view.dart`'s own comment on why that must still go
  /// through the full reset below.
  void start(String journeyId, {required DateTime now}) {
    if (state?.journeyId == journeyId) return;
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
    unawaited(
      pushProgressBestEffort(
        ref,
        journeyId: journeyId,
        startedAt: now,
        progressMeters: 0,
      ),
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

/// Whether the Путь tab is showing the quest catalog (`QuestPickerView`)
/// even though a quest is already active (this task's requirement: "кнопка
/// возврата к выбору других маршрутов") — distinct from `selectedJourneyProvider
/// == null`, which means no quest has ever been started. Browsing never
/// touches the active quest itself; picking a *different* journey from the
/// catalog still goes through the ordinary `SelectedJourney.start()` (§6.4:
/// only one quest active at a time), which itself exits browsing mode.
///
/// In-memory only, same placeholder-until-Phase-3 caveat as
/// `locale_provider.dart`'s `AppLocale` — this is UI navigation state, not
/// anything worth persisting across a restart.
@riverpod
class BrowsingCatalog extends _$BrowsingCatalog {
  @override
  bool build() => false;

  void enter() => state = true;
  void exit() => state = false;
}

/// How far along [journeyId] the local device's own step history already
/// is, in `[0.0, 1.0]` (this task's requirement: "показывай процент
/// пройденного пути для каждого маршрута" on the catalog cards) — derived
/// straight from `StepIntervalRecords` via `StepSampleRepository
/// .totalResolvedMeters()`, the same ground truth `StepsSyncEngine.sync()`
/// itself trusts (§5.2 "derive, don't duplicate"), not from
/// `selectedJourneyProvider` — that only ever holds the *one* currently
/// active quest, but every catalog card needs its own answer, including
/// ones the user isn't on right now. A journey never started reads `0.0`,
/// same as [progressFraction]'s own `0`-meters case.
@riverpod
Future<double> journeyProgressFraction(Ref ref, String journeyId) async {
  final journey = findJourney(journeyId);
  if (journey == null) return 0;
  final meters = await ref
      .watch(stepSampleRepositoryProvider)
      .totalResolvedMeters(ownerId: localOwnerId, journeyId: journeyId);
  return progressFraction(
    progressMeters: meters,
    totalMeters: journey.totalMeters,
  );
}
