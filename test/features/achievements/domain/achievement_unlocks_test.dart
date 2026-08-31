import 'package:test/test.dart';
import 'package:thereandback/features/achievements/domain/achievement.dart';
import 'package:thereandback/features/achievements/domain/achievement_unlocks.dart';
import 'package:thereandback/features/journey/domain/quest_time_service.dart';

void main() {
  group('groupMetersByLocalDay', () {
    test('sums meters credited on the same local calendar day', () {
      final totals = groupMetersByLocalDay([
        MeteredInterval(end: DateTime(2026, 3, 10, 9), meters: 1000),
        MeteredInterval(end: DateTime(2026, 3, 10, 18), meters: 500),
        MeteredInterval(end: DateTime(2026, 3, 11, 8), meters: 2000),
      ]);

      expect(totals[DateTime(2026, 3, 10)], 1500);
      expect(totals[DateTime(2026, 3, 11)], 2000);
      expect(totals.length, 2);
    });

    test('an empty interval list groups to an empty map', () {
      expect(groupMetersByLocalDay(const []), isEmpty);
    });
  });

  group('computeJourneyAchievementUnlockDates', () {
    const catalog = [
      AchievementDef(
        id: 'first-steps',
        titleKey: 'achievementFirstStepsTitle',
        kind: AchievementKind.distanceReached,
        thresholdMeters: 1000,
      ),
      AchievementDef(
        id: 'seasoned-wanderer',
        titleKey: 'achievementSeasonedWandererTitle',
        kind: AchievementKind.distanceReached,
        thresholdMeters: 5000,
      ),
    ];

    test(
      'records the first day cumulative progress crosses each threshold',
      () {
        final unlocks = computeJourneyAchievementUnlockDates(
          orderedIntervals: [
            MeteredInterval(end: DateTime(2026, 3, 10), meters: 600),
            MeteredInterval(
              end: DateTime(2026, 3, 11),
              meters: 600,
            ), // crosses 1000
            MeteredInterval(
              end: DateTime(2026, 3, 15),
              meters: 4000,
            ), // crosses 5000
          ],
          catalog: catalog,
        );

        expect(unlocks['first-steps'], DateTime(2026, 3, 11));
        expect(unlocks['seasoned-wanderer'], DateTime(2026, 3, 15));
      },
    );

    test(
      'a threshold crossed on the very first interval unlocks on that day',
      () {
        final unlocks = computeJourneyAchievementUnlockDates(
          orderedIntervals: [
            MeteredInterval(end: DateTime(2026, 3, 10), meters: 1000),
          ],
          catalog: catalog,
        );

        expect(unlocks['first-steps'], DateTime(2026, 3, 10));
        expect(unlocks.containsKey('seasoned-wanderer'), isFalse);
      },
    );

    test('no history unlocks nothing', () {
      expect(
        computeJourneyAchievementUnlockDates(
          orderedIntervals: const [],
          catalog: catalog,
        ),
        isEmpty,
      );
    });

    test('multiple thresholds crossed by the same interval all unlock on '
        'that same day', () {
      final unlocks = computeJourneyAchievementUnlockDates(
        orderedIntervals: [
          MeteredInterval(end: DateTime(2026, 3, 12), meters: 6000),
        ],
        catalog: catalog,
      );

      expect(unlocks['first-steps'], DateTime(2026, 3, 12));
      expect(unlocks['seasoned-wanderer'], DateTime(2026, 3, 12));
    });
  });

  group('computeDailyAchievementUnlockDates', () {
    const catalog = [
      AchievementDef(
        id: 'daily-1km',
        titleKey: 'achievementDaily1kmTitle',
        kind: AchievementKind.dailyDistance,
        thresholdMeters: 1000,
      ),
      AchievementDef(
        id: 'daily-5km',
        titleKey: 'achievementDaily5kmTitle',
        kind: AchievementKind.dailyDistance,
        thresholdMeters: 5000,
      ),
    ];

    test('a day reaching a threshold is recorded under that achievement', () {
      final unlocks = computeDailyAchievementUnlockDates(
        dailyTotals: {DateTime(2026, 3, 10): 1200, DateTime(2026, 3, 11): 400},
        catalog: catalog,
      );

      expect(unlocks['daily-1km'], [DateTime(2026, 3, 10)]);
      expect(unlocks.containsKey('daily-5km'), isFalse);
    });

    test('every qualifying day is recorded, sorted ascending — this is what '
        'lets the same daily trophy be earned more than once', () {
      final unlocks = computeDailyAchievementUnlockDates(
        dailyTotals: {
          DateTime(2026, 3, 12): 1500,
          DateTime(2026, 3, 10): 1000,
          DateTime(2026, 3, 11): 999, // just under — excluded.
        },
        catalog: catalog,
      );

      expect(unlocks['daily-1km'], [
        DateTime(2026, 3, 10),
        DateTime(2026, 3, 12),
      ]);
    });

    test('no qualifying day for a threshold omits its key entirely', () {
      expect(
        computeDailyAchievementUnlockDates(
          dailyTotals: {DateTime(2026, 3, 10): 100},
          catalog: catalog,
        ),
        isEmpty,
      );
    });
  });

  group(
    'currentStreak / longestStreak (this task\'s requirement — "стрик")',
    () {
      test('never unlocked is a streak of 0, both current and longest', () {
        expect(currentStreak(const []), 0);
        expect(longestStreak(const []), 0);
      });

      test('a single unlocked day is a streak of 1', () {
        expect(currentStreak([DateTime(2026, 3, 10)]), 1);
        expect(longestStreak([DateTime(2026, 3, 10)]), 1);
      });

      test('three unlocked days in a row is a current and longest streak of '
          '3', () {
        final dates = [
          DateTime(2026, 3, 10),
          DateTime(2026, 3, 11),
          DateTime(2026, 3, 12),
        ];
        expect(currentStreak(dates), 3);
        expect(longestStreak(dates), 3);
      });

      test('a gap breaks the streak — currentStreak only counts the run ending '
          'at the most recent date, longestStreak still finds the earlier, '
          'longer run', () {
        final dates = [
          DateTime(2026, 3, 1),
          DateTime(2026, 3, 2),
          DateTime(2026, 3, 3),
          // Gap — 3/4 and 3/5 never unlocked.
          DateTime(2026, 3, 6),
        ];
        expect(currentStreak(dates), 1);
        expect(longestStreak(dates), 3);
      });

      test('unsorted input is handled the same as sorted input', () {
        final dates = [
          DateTime(2026, 3, 12),
          DateTime(2026, 3, 10),
          DateTime(2026, 3, 11),
        ];
        expect(currentStreak(dates), 3);
        expect(longestStreak(dates), 3);
      });

      test(
        'a date with a time-of-day component still compares by calendar day, '
        'not by exact instant',
        () {
          final dates = [DateTime(2026, 3, 10, 23), DateTime(2026, 3, 11, 1)];
          expect(currentStreak(dates), 2);
        },
      );
    },
  );
}
