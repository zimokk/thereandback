import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/app/app_lifecycle.dart';
import 'package:thereandback/features/audio/data/background_music_player.dart';
import 'package:thereandback/features/audio/presentation/background_music_provider.dart';

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
  late ProviderContainer container;

  setUp(() {
    player = _MockPlayer();
    lifecycle = _FakeAppLifecycle(AppLifecycleState.resumed);
    when(() => player.start()).thenAnswer((_) async {});
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.resume()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        backgroundMusicPlayerProvider.overrideWithValue(player),
        appLifecycleProvider.overrideWith(() => lifecycle),
      ],
    );
    addTearDown(container.dispose);
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
}
