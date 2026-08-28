import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:thereandback/data/drift/database.dart';
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

  test(
    'a genuinely duplicate interval is not credited a second time',
    () async {
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

      // No new credit — the interval was already recorded.
      expect(result.progressMeters, 0);
      expect(result.syncedAt, now);
    },
  );

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
