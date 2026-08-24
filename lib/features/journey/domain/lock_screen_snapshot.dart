import 'package:freezed_annotation/freezed_annotation.dart';

import 'journey.dart';
import 'quest_progress.dart';
import 'quest_selection.dart';

part 'lock_screen_snapshot.freezed.dart';

/// Everything the persistent lock-screen / notification-shade display (§7
/// "постоянное отображение прогресса на заблокированном экране") needs to
/// render, already reduced to display-ready values so the platform layer
/// (`features/journey/data/lock_screen_channel.dart`) never has to know
/// about [SelectedQuest] or [Journey] directly.
///
/// Carries only what the app already shows on-screen — day, meters, a
/// coarse position label — never raw health data or geolocation (§7's
/// privacy rule).
@freezed
abstract class LockScreenSnapshot with _$LockScreenSnapshot {
  const factory LockScreenSnapshot({
    /// "Day N" (§5.3), same counter as the Путь tab.
    required int questDay,

    /// Meters credited so far. Domain units — integer meters (§11);
    /// formatting for display happens in presentation, same as everywhere
    /// else (§5.4).
    required int progressMeters,

    required int totalMeters,

    /// A short line describing where the traveler currently is.
    ///
    /// Placeholder today: `Segment`/`Landmark`/`map.json` (§6.2) don't exist
    /// yet (Phase 6/11), so there is no real region/landmark data to show.
    /// [buildLockScreenSnapshot] falls back to "→ {pointB}" — cheap to swap
    /// for a real landmark string once that data lands, not a fake answer.
    required String positionLabel,
  }) = _LockScreenSnapshot;
}

/// Reduces the live quest state to a [LockScreenSnapshot] — the one place
/// that decides what the lock screen / notification shows.
///
/// Pure: no platform channel, no I/O. Reuses [questDay] from
/// `quest_progress.dart` so the "Day N" counter never drifts from the one
/// shown on the Путь tab.
LockScreenSnapshot buildLockScreenSnapshot({
  required SelectedQuest quest,
  required Journey journey,
  required DateTime now,
}) {
  return LockScreenSnapshot(
    questDay: questDay(startedAt: quest.startedAt, now: now),
    progressMeters: quest.progressMeters,
    totalMeters: journey.totalMeters,
    // TODO(Phase 6/11): replace with the real landmark/region the traveler
    // is currently passing once `Segment`/`Landmark`/`map.json` exist.
    positionLabel: '→ ${journey.pointB}',
  );
}
