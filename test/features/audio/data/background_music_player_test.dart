import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thereandback/features/audio/data/background_music_player.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _FakeSource extends Fake implements Source {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSource());
    registerFallbackValue(ReleaseMode.loop);
  });

  late _MockAudioPlayer audioPlayer;
  late BackgroundMusicPlayer player;

  setUp(() {
    audioPlayer = _MockAudioPlayer();
    when(() => audioPlayer.setReleaseMode(any())).thenAnswer((_) async {});
    when(() => audioPlayer.play(any())).thenAnswer((_) async {});
    when(() => audioPlayer.pause()).thenAnswer((_) async {});
    when(() => audioPlayer.resume()).thenAnswer((_) async {});
    when(() => audioPlayer.stop()).thenAnswer((_) async {});
    when(() => audioPlayer.dispose()).thenAnswer((_) async {});
    player = BackgroundMusicPlayer(player: audioPlayer);
  });

  test('start() sets loop mode and plays the bundled asset', () async {
    await player.start();

    verify(() => audioPlayer.setReleaseMode(ReleaseMode.loop)).called(1);
    verify(() => audioPlayer.play(any())).called(1);
  });

  test(
    'start() is idempotent — a second call does not restart playback',
    () async {
      await player.start();
      await player.start();

      verify(() => audioPlayer.play(any())).called(1);
    },
  );

  test('pause()/resume() are no-ops until start() has run', () async {
    await player.pause();
    await player.resume();

    verifyNever(() => audioPlayer.pause());
    verifyNever(() => audioPlayer.resume());
  });

  test('pause()/resume() delegate to the player once started', () async {
    await player.start();

    await player.pause();
    await player.resume();

    verify(() => audioPlayer.pause()).called(1);
    verify(() => audioPlayer.resume()).called(1);
  });

  test('stop() before start() is a no-op', () async {
    await player.stop();

    verifyNever(() => audioPlayer.stop());
  });

  test(
    'stop() releases playback, and start() can begin fresh after it',
    () async {
      await player.start();
      await player.stop();
      verify(() => audioPlayer.stop()).called(1);

      await player.start();
      verify(() => audioPlayer.play(any())).called(2);
    },
  );
}
