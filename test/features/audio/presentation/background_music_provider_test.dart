import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/app_lifecycle.dart';
import 'package:thereandback/app/database_provider.dart';
import 'package:thereandback/data/drift/database.dart';
import 'package:thereandback/features/audio/data/background_music_player.dart';
import 'package:thereandback/features/audio/presentation/background_music_provider.dart';
import 'package:thereandback/features/journey/presentation/journey_providers.dart';

class _MockPlayer extends Mock implements BackgroundMusicPlayer {}

/// A controllable stand-in for the real lifecycle listener (which needs a
/// live `WidgetsBinding` to receive real transitions) — same
/// subclass-and-override-`build()` shape `steps_providers_test.dart` uses
/// for `StepsSync` (`_GrantedStepsSync`/`_FixedStepsSync`). [emit] drives
/// `BackgroundMusicController`'s `ref.listen` callback the same way a real
/// foreground/background transition would.
class _FakeAppLifecycle extends AppLifecycle {
  _FakeAppLifecycle(this._initial);

  final AppLifecycleState _initial;

  @override
  AppLifecycleState build() => _initial;

  void emit(AppLifecycleState next) => state = next;
}

void main() {
  late _MockPlayer player;
  late _FakeAppLifecycle lifecycle;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    player = _MockPlayer();
    lifecycle = _FakeAppLifecycle(AppLifecycleState.resumed);
    when(() => player.start()).thenAnswer((_) async {});
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.resume()).thenAnswer((_) async {});
    when(() => player.selectTrack(any())).thenAnswer((_) async {});

    // `testing` skill: never a real (file-backed) drift database in a
    // test — `BackgroundMusicController.build()` now reads
    // `userPreferenceRepositoryProvider` (§14 — persisted Настройки
    // toggles), which depends on `appDatabaseProvider` transitively even in
    // tests that don't care about persistence themselves.
    db = AppDatabase.forTesting();
    container = ProviderContainer(
      overrides: [
        backgroundMusicPlayerProvider.overrideWithValue(player),
        appLifecycleProvider.overrideWith(() => lifecycle),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
  });

  test('starts off by default — this task\'s own requirement', () {
    expect(container.read(backgroundMusicControllerProvider), isFalse);
    verifyNever(() => player.start());
  });

  test('setEnabled(true) starts playback and flips state on', () async {
    await container
        .read(backgroundMusicControllerProvider.notifier)
        .setEnabled(true);

    expect(container.read(backgroundMusicControllerProvider), isTrue);
    verify(() => player.start()).called(1);
  });

  test('setEnabled(false) stops playback and flips state off', () async {
    final notifier = container.read(backgroundMusicControllerProvider.notifier);
    await notifier.setEnabled(true);

    await notifier.setEnabled(false);

    expect(container.read(backgroundMusicControllerProvider), isFalse);
    verify(() => player.stop()).called(1);
  });

  test('setEnabled() with the value already in effect is a no-op', () async {
    await container
        .read(backgroundMusicControllerProvider.notifier)
        .setEnabled(false);

    verifyNever(() => player.start());
    verifyNever(() => player.stop());
  });

  test('a start() failure leaves state off and propagates to the caller — the '
      'toggle must never read "on" while nothing is actually playing (§7: '
      'never a silent dead end)', () async {
    when(() => player.start()).thenThrow(Exception('asset missing'));

    await expectLater(
      container
          .read(backgroundMusicControllerProvider.notifier)
          .setEnabled(true),
      throwsException,
    );

    expect(container.read(backgroundMusicControllerProvider), isFalse);
  });

  test(
    'backgrounding the app pauses playback while the feature is on',
    () async {
      await container
          .read(backgroundMusicControllerProvider.notifier)
          .setEnabled(true);

      lifecycle.emit(AppLifecycleState.paused);
      await pumpEventQueue();

      verify(() => player.pause()).called(1);
    },
  );

  test(
    'returning to the foreground resumes playback while the feature is on',
    () async {
      await container
          .read(backgroundMusicControllerProvider.notifier)
          .setEnabled(true);
      lifecycle.emit(AppLifecycleState.paused);
      await pumpEventQueue();

      lifecycle.emit(AppLifecycleState.resumed);
      await pumpEventQueue();

      verify(() => player.resume()).called(1);
    },
  );

  test('lifecycle transitions are ignored while the feature is off', () async {
    // Reads the controller so build() (and its ref.listen registration)
    // actually runs before the transitions below fire.
    container.read(backgroundMusicControllerProvider);

    lifecycle.emit(AppLifecycleState.paused);
    await pumpEventQueue();
    lifecycle.emit(AppLifecycleState.resumed);
    await pumpEventQueue();

    verifyNever(() => player.pause());
    verifyNever(() => player.resume());
  });

  test('setEnabled(true) persists the toggle, and a fresh controller reading '
      'the same database restores it on build() — this task\'s own '
      'requirement: settings survive a restart (§14)', () async {
    await container
        .read(backgroundMusicControllerProvider.notifier)
        .setEnabled(true);

    // A second, independent container simulates the app cold-starting
    // again against the same on-disk database — same "restart"
    // simulation `journey_providers_test.dart` uses for
    // `SelectedJourney`.
    final restartedPlayer = _MockPlayer();
    when(() => restartedPlayer.start()).thenAnswer((_) async {});
    when(() => restartedPlayer.stop()).thenAnswer((_) async {});
    when(() => restartedPlayer.pause()).thenAnswer((_) async {});
    when(() => restartedPlayer.resume()).thenAnswer((_) async {});
    when(() => restartedPlayer.selectTrack(any())).thenAnswer((_) async {});
    final restartedContainer = ProviderContainer(
      overrides: [
        backgroundMusicPlayerProvider.overrideWithValue(restartedPlayer),
        appLifecycleProvider.overrideWith(
          () => _FakeAppLifecycle(AppLifecycleState.resumed),
        ),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(restartedContainer.dispose);

    restartedContainer.read(backgroundMusicControllerProvider);
    await pumpEventQueue();

    expect(restartedContainer.read(backgroundMusicControllerProvider), isTrue);
    verify(() => restartedPlayer.start()).called(1);
  });

  test(
    'a controller reading an empty database (nothing ever saved for '
    'localOwnerId) stays off — same default as before persistence existed',
    () async {
      expect(await db.select(db.userPreferenceRows).getSingleOrNull(), isNull);

      container.read(backgroundMusicControllerProvider);
      await pumpEventQueue();

      expect(container.read(backgroundMusicControllerProvider), isFalse);
      verifyNever(() => player.start());
    },
  );

  test('setEnabled(false) persists off too — a toggle turned back off '
      'before a restart must not resume on the next one', () async {
    final notifier = container.read(backgroundMusicControllerProvider.notifier);
    await notifier.setEnabled(true);
    await notifier.setEnabled(false);

    final restartedPlayer = _MockPlayer();
    when(() => restartedPlayer.start()).thenAnswer((_) async {});
    when(() => restartedPlayer.stop()).thenAnswer((_) async {});
    when(() => restartedPlayer.selectTrack(any())).thenAnswer((_) async {});
    final restartedContainer = ProviderContainer(
      overrides: [
        backgroundMusicPlayerProvider.overrideWithValue(restartedPlayer),
        appLifecycleProvider.overrideWith(
          () => _FakeAppLifecycle(AppLifecycleState.resumed),
        ),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(restartedContainer.dispose);

    restartedContainer.read(backgroundMusicControllerProvider);
    await pumpEventQueue();

    expect(restartedContainer.read(backgroundMusicControllerProvider), isFalse);
    verifyNever(() => restartedPlayer.start());
  });

  group('per-quest track (`journey_theme_track.dart`)', () {
    test(
      'no quest selected — selectTrack(null) at build, the shared default',
      () async {
        container.read(backgroundMusicControllerProvider);
        await pumpEventQueue();

        verify(() => player.selectTrack(null)).called(1);
      },
    );

    test(
      'a quest already selected before this controller ever builds picks '
      'its own track immediately, not only on the next switch',
      () async {
        container
            .read(selectedJourneyProvider.notifier)
            .start('tower-of-lights', now: DateTime(2026, 3, 10));

        container.read(backgroundMusicControllerProvider);
        await pumpEventQueue();

        verify(
          () => player.selectTrack('journeys/tower-of-lights/theme.mp3'),
        ).called(1);
      },
    );

    test(
      'switching the active quest while the controller is alive switches '
      'the track live, on or off',
      () async {
        container.read(backgroundMusicControllerProvider);
        await pumpEventQueue();
        clearInteractions(player);
        when(() => player.selectTrack(any())).thenAnswer((_) async {});

        container
            .read(selectedJourneyProvider.notifier)
            .start('tower-of-lights', now: DateTime(2026, 3, 10));
        await pumpEventQueue();

        verify(
          () => player.selectTrack('journeys/tower-of-lights/theme.mp3'),
        ).called(1);
      },
    );

    test(
      'a quest with no track of its own falls back to the shared default',
      () async {
        container
            .read(selectedJourneyProvider.notifier)
            .start('odyssey-ithaca', now: DateTime(2026, 3, 10));

        container.read(backgroundMusicControllerProvider);
        await pumpEventQueue();

        verify(() => player.selectTrack(null)).called(1);
      },
    );
  });
}
