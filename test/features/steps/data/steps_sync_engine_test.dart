import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/achievements/data/achievement_repository.dart';
import 'package:thereandback/features/journey/domain/quest_selection.dart';
import 'package:thereandback/features/steps/data/step_counting_service.dart';
import 'package:thereandback/features/steps/data/step_sample_repository.dart';
import 'package:thereandback/features/steps/data/steps_sync_engine.dart';

class _MockStepCountingService extends Mock implements StepCountingService {}

void main() {
  late _MockStepCountingService adapter;
  late AppDatabase db;
  late StepSampleRepository repository;
  late StepsSyncEngine engine;

  setUp(() {
    adapter = _MockStepCountingService();
    // `testing` skill: never a real drift database in a test — same
    // in-memory pattern `step_sample_repository_test.dart` uses.
    db = AppDatabase.forTesting();
    repository = DriftStepSampleRepository(db);
    engine = StepsSyncEngine(
      stepCountingService: adapter,
      stepSampleRepository: repository,
      // Real, in-memory-backed repository, not a mock — this task's own
      // achievement-persistence behavior is exercised for real, the same
      // way `repository` above already is.
      achievementRepository: DriftAchievementRepository(db),
    );
  });
  tearDown(() => db.close());

  test(
    'resolves a realistic pace and credits the distance, unflagged',
    () async {
      when(() => adapter.fetchDelta(any(), any()))
          .thenAnswer((_) async => const StepsDelta(steps: 100));

      final quest = SelectedQuest(
        journeyId: 'odyssey-ithaca',
        startedAt: DateTime(2026, 3, 10),
        lastSyncedAt: DateTime(2026, 3, 10),
        progressMeters: 0,
      );

      final result = await engine.sync(
        quest: quest,
        now: DateTime(2026, 3, 10, 0, 10), // 100 steps / 10 min is realistic.
      );

      expect(result.flagged, isFalse);
      expect(result.progressMeters, greaterThan(0));
    },
  );

  test(
    '§5.2: an implausible pace is flagged but distance is still credited',
    () async {
      when(() => adapter.fetchDelta(any(), any()))
          .thenAnswer((_) async => const StepsDelta(steps: 10000));

      final quest = SelectedQuest(
        journeyId: 'odyssey-ithaca',
        startedAt: DateTime(2026, 3, 10),
        lastSyncedAt: DateTime(2026, 3, 10),
        progressMeters: 0,
      );

      final result = await engine.sync(
        quest: quest,
        now: DateTime(2026, 3, 10, 0, 0, 30), // 10 000 steps / 30 s.
      );

      expect(result.flagged, isTrue);
      expect(result.progressMeters, greaterThan(0));
    },
  );

  test(
    'platform-reported walking distance is preferred over steps × stride',
    () async {
      when(() => adapter.fetchDelta(any(), any())).thenAnswer(
        (_) async => const StepsDelta(steps: 100, walkingDistanceMeters: 250),
      );

      final quest = SelectedQuest(
        journeyId: 'odyssey-ithaca',
        startedAt: DateTime(2026, 3, 10),
        lastSyncedAt: DateTime(2026, 3, 10),
        progressMeters: 0,
      );

      final result = await engine.sync(
        quest: quest,
        now: DateTime(2026, 3, 10, 0, 10),
      );

      // 100 steps at the 0.75 m default stride would be 75 m — the platform's
      // own 250 m reading must win (§5.1).
      expect(result.progressMeters, 250);
    },
  );

  test('a genuinely duplicate interval is not credited a second time, but the '
      'result still reflects the database\'s real total rather than the '
      "caller's stale one — this task's fix: the caller's `quest"
      '.progressMeters` (0 here, as if the in-memory `SelectedJourney` state '
      "hadn't caught up yet) is not trusted as gospel; the database's actual "
      'sum (75, from the pre-recorded interval below) wins because it\'s the '
      'bigger of the two ("если в базе данных шагов больше — выбираем '
      'большее значение")', () async {
    when(() => adapter.fetchDelta(any(), any()))
        .thenAnswer((_) async => const StepsDelta(steps: 100));

    final intervalStart = DateTime(2026, 3, 10);
    final now = DateTime(2026, 3, 10, 0, 10);

    // Pre-record the exact interval sync() is about to fetch — as if a
    // concurrent sync (background/foreground race) already claimed it.
    await repository.recordInterval(
      ownerId: 'local-device',
      journeyId: 'odyssey-ithaca',
      intervalStart: intervalStart,
      intervalEnd: now,
      steps: 100,
      resolvedMeters: 75,
      flaggedPace: false,
      syncedAt: now,
    );

    final quest = SelectedQuest(
      journeyId: 'odyssey-ithaca',
      startedAt: intervalStart,
      lastSyncedAt: intervalStart,
      progressMeters: 0,
    );

    final result = await engine.sync(quest: quest, now: now);

    // No *new* credit — the interval was already recorded — but the
    // database already had 75 m from it, and that's what comes back.
    expect(result.progressMeters, 75);
    expect(result.syncedAt, now);
  });

  test("app-load scenario: a stale caller-supplied `quest.progressMeters` is "
      "overridden by the database's bigger total even when this sync's own "
      'interval credits nothing new — e.g. a background sync (§7, '
      '`android_background_sync.dart`) recorded distance while this app '
      "process wasn't running, and the in-memory `SelectedJourney` state "
      "this test's `quest` stands in for hasn't caught up yet", () async {
    when(() => adapter.fetchDelta(any(), any()))
        .thenAnswer((_) async => const StepsDelta(steps: 0));

    // An earlier interval already sitting in the database — as if a
    // background sync recorded it before this app process started.
    await repository.recordInterval(
      ownerId: 'local-device',
      journeyId: 'odyssey-ithaca',
      intervalStart: DateTime(2026, 3, 9),
      intervalEnd: DateTime(2026, 3, 10),
      steps: 1000,
      resolvedMeters: 800,
      flaggedPace: false,
      syncedAt: DateTime(2026, 3, 10),
    );

    final quest = SelectedQuest(
      journeyId: 'odyssey-ithaca',
      startedAt: DateTime(2026, 3, 9),
      lastSyncedAt: DateTime(2026, 3, 10), // matches the interval above.
      progressMeters: 0, // stale — doesn't know about the 800 m above.
    );

    final result = await engine.sync(
      quest: quest,
      now: DateTime(2026, 3, 10, 0, 10),
    );

    // No new steps credited this tick, but the database's real total (800
    // m, from the interval seeded above) wins over the caller's stale 0.
    expect(result.progressMeters, 800);
  });

  test('progress never decreases even if the platform hands back a weird '
      'delta', () async {
    when(() => adapter.fetchDelta(any(), any()))
        .thenAnswer((_) async => const StepsDelta(steps: 0));

    final quest = SelectedQuest(
      journeyId: 'odyssey-ithaca',
      startedAt: DateTime(2026, 3, 10),
      lastSyncedAt: DateTime(2026, 3, 10),
      progressMeters: 5000,
    );

    final result = await engine.sync(
      quest: quest,
      now: DateTime(2026, 3, 10, 0, 10),
    );

    expect(result.progressMeters, 5000);
  });
}
