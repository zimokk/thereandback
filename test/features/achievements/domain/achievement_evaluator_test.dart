import 'package:test/test.dart';
import 'package:thereandback/features/achievements/domain/achievement.dart';

void main() {
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
      thresholdMeters: 500000,
    ),
  ];

  test('below every threshold, everything is locked with remaining meters', () {
    final states = evaluateAchievements(progressMeters: 500, catalog: catalog);

    expect(states[0].unlocked, isFalse);
    expect(states[0].remainingMeters, 500);
    expect(states[1].unlocked, isFalse);
    expect(states[1].remainingMeters, 499500);
  });

  test('crossing a threshold unlocks it and zeroes its remaining meters', () {
    final states = evaluateAchievements(progressMeters: 1000, catalog: catalog);

    expect(states[0].unlocked, isTrue);
    expect(states[0].remainingMeters, 0);
    expect(states[1].unlocked, isFalse);
    expect(states[1].remainingMeters, 499000);
  });

  test('progress past every threshold unlocks the whole catalog', () {
    final states = evaluateAchievements(
      progressMeters: 600000,
      catalog: catalog,
    );

    expect(states.every((s) => s.unlocked), isTrue);
    expect(states.every((s) => s.remainingMeters == 0), isTrue);
  });

  test('an empty catalog evaluates to an empty list', () {
    expect(
      evaluateAchievements(progressMeters: 100, catalog: const []),
      isEmpty,
    );
  });

  test('landmarkReached unlocks the same way distanceReached does — same rule, '
      'different reason', () {
    const landmarkCatalog = [
      AchievementDef(
        id: 'reached-circe',
        titleKey: 'achievementReachedCirceTitle',
        kind: AchievementKind.landmarkReached,
        thresholdMeters: 561921,
      ),
    ];

    final before = evaluateAchievements(
      progressMeters: 561920,
      catalog: landmarkCatalog,
    );
    expect(before.single.unlocked, isFalse);
    expect(before.single.remainingMeters, 1);

    final atThreshold = evaluateAchievements(
      progressMeters: 561921,
      catalog: landmarkCatalog,
    );
    expect(atThreshold.single.unlocked, isTrue);
    expect(atThreshold.single.remainingMeters, 0);
  });

  test('a dailyDistance def is a caller bug, not something this cumulative '
      'evaluator can answer — see achievement_unlocks.dart instead', () {
    const dailyCatalog = [
      AchievementDef(
        id: 'daily-1km',
        titleKey: 'achievementDaily1kmTitle',
        kind: AchievementKind.dailyDistance,
        thresholdMeters: 1000,
      ),
    ];

    expect(
      () => evaluateAchievements(progressMeters: 1000, catalog: dailyCatalog),
      throwsArgumentError,
    );
  });

  group('achievementsForJourney (§14, 2026-09-05 — per-quest scoping)', () {
    const scopedCatalog = [
      AchievementDef(
        id: 'generic',
        titleKey: 'achievementFirstStepsTitle',
        kind: AchievementKind.distanceReached,
        thresholdMeters: 1000,
      ),
      AchievementDef(
        id: 'odyssey-only',
        titleKey: 'achievementReachedCirceTitle',
        kind: AchievementKind.landmarkReached,
        thresholdMeters: 561921,
        journeyId: 'odyssey-ithaca',
      ),
      AchievementDef(
        id: 'tower-only',
        titleKey: 'achievementLeftTheTowerTitle',
        kind: AchievementKind.landmarkReached,
        thresholdMeters: 20000,
        journeyId: 'tower-of-lights',
      ),
    ];

    test('journeyId null (no quest selected) returns the whole catalog '
        'unchanged — the catalog-browsing preview', () {
      expect(achievementsForJourney(scopedCatalog, null), same(scopedCatalog));
    });

    test('a quest sees its own scoped entries plus every generic one, never '
        "another quest's", () {
      final forOdyssey = achievementsForJourney(
        scopedCatalog,
        'odyssey-ithaca',
      );
      expect(forOdyssey.map((d) => d.id), ['generic', 'odyssey-only']);

      final forTower = achievementsForJourney(scopedCatalog, 'tower-of-lights');
      expect(forTower.map((d) => d.id), ['generic', 'tower-only']);
    });

    test('an unknown journeyId still gets every generic entry, no scoped '
        'ones', () {
      final result = achievementsForJourney(scopedCatalog, 'no-such-quest');
      expect(result.map((d) => d.id), ['generic']);
    });
  });
}
