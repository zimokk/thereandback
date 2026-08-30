import 'package:test/test.dart';
import 'package:thereandback/features/achievements/domain/achievement.dart';
import 'package:thereandback/features/achievements/domain/daily_achievement.dart';

void main() {
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

  test('a catalog def with no matching unlock gets an empty, locked state', () {
    final states = buildDailyAchievementStates(
      catalog: catalog,
      unlocks: const {},
    );

    expect(states, hasLength(2));
    expect(states[0].unlocked, isFalse);
    expect(states[0].unlockedCount, 0);
    expect(states[0].unlockedDates, isEmpty);
  });

  test('a single unlock date marks it unlocked with a count of one', () {
    final states = buildDailyAchievementStates(
      catalog: catalog,
      unlocks: {
        'daily-1km': [DateTime(2026, 3, 10)],
      },
    );

    expect(states[0].unlocked, isTrue);
    expect(states[0].unlockedCount, 1);
    expect(states[1].unlocked, isFalse);
  });

  test('several unlock dates count every one of them — this is what the '
      'Трофеи tab badges once it is more than one', () {
    final states = buildDailyAchievementStates(
      catalog: catalog,
      unlocks: {
        'daily-1km': [
          DateTime(2026, 3, 10),
          DateTime(2026, 3, 12),
          DateTime(2026, 3, 15),
        ],
      },
    );

    expect(states[0].unlockedCount, 3);
  });

  test('an empty catalog builds no states', () {
    expect(
      buildDailyAchievementStates(catalog: const [], unlocks: const {}),
      isEmpty,
    );
  });
}
