import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/journey.dart';
import 'package:thereandback/features/journey/domain/lock_screen_snapshot.dart';
import 'package:thereandback/features/journey/domain/quest_selection.dart';

void main() {
  const journey = Journey(
    id: 'odyssey-ithaca',
    name: 'The Odyssey: Troy to Ithaca',
    pointA: 'Troy',
    pointB: 'Ithaca',
    totalMeters: 100000,
  );

  group('buildLockScreenSnapshot', () {
    test('reuses questDay so it never drifts from the Путь tab counter', () {
      final quest = SelectedQuest(
        journeyId: journey.id,
        startedAt: DateTime(2026, 3, 10),
        lastSyncedAt: DateTime(2026, 3, 10),
        progressMeters: 5000,
      );

      final snapshot = buildLockScreenSnapshot(
        quest: quest,
        journey: journey,
        now: DateTime(2026, 3, 14), // Day 5, matching quest_time_service_test.
      );

      expect(snapshot.questDay, 5);
      expect(snapshot.progressMeters, 5000);
      expect(snapshot.totalMeters, 100000);
    });

    test(
      'positionLabel falls back to pointB — no Segment/Landmark data yet',
      () {
        final quest = SelectedQuest(
          journeyId: journey.id,
          startedAt: DateTime(2026, 3, 10),
          lastSyncedAt: DateTime(2026, 3, 10),
          progressMeters: 42000,
        );

        final snapshot = buildLockScreenSnapshot(
          quest: quest,
          journey: journey,
          now: DateTime(2026, 3, 11),
        );

        expect(snapshot.positionLabel, '→ Ithaca');
      },
    );

    test('zero progress on the day the quest starts', () {
      final quest = SelectedQuest(
        journeyId: journey.id,
        startedAt: DateTime(2026, 3, 10),
        lastSyncedAt: DateTime(2026, 3, 10),
        progressMeters: 0,
      );

      final snapshot = buildLockScreenSnapshot(
        quest: quest,
        journey: journey,
        now: DateTime(2026, 3, 10),
      );

      expect(snapshot.questDay, 1);
      expect(snapshot.progressMeters, 0);
    });

    test('progress at or past totalMeters is passed through untouched', () {
      final quest = SelectedQuest(
        journeyId: journey.id,
        startedAt: DateTime(2026, 3, 10),
        lastSyncedAt: DateTime(2026, 3, 10),
        progressMeters: 120000,
      );

      final snapshot = buildLockScreenSnapshot(
        quest: quest,
        journey: journey,
        now: DateTime(2026, 4, 1),
      );

      expect(snapshot.progressMeters, 120000);
      expect(snapshot.progressMeters >= snapshot.totalMeters, isTrue);
    });
  });
}
