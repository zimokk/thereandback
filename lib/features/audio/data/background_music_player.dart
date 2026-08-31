import 'package:audioplayers/audioplayers.dart';

/// Thin wrapper around a single `audioplayers` [AudioPlayer] looping the
/// app's one background track (§6.5 — "фоновая музыка"). One instance for
/// the whole app session (`backgroundMusicPlayerProvider`, `keepAlive:
/// true`) — a shared player, not a fresh one per toggle, is what lets
/// [pause]/[resume] act on the same playback position across an
/// app-lifecycle transition instead of restarting the track from the top
/// every time the user switches away and back.
class BackgroundMusicPlayer {
  BackgroundMusicPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  /// Relative to `AudioCache`'s default `assets/` prefix, so this resolves
  /// to `assets/media/journey_theme.wav` — kept separate from
  /// `assets/journeys/{id}/` (§4) since it isn't quest content, this task's
  /// own instruction. See `assets/media/README.md` for the file's status
  /// (placeholder track, not final art).
  static const _trackAssetPath = 'media/journey_theme.wav';

  /// Whether [start] has run without a matching [stop] — not the same as
  /// "audio is audibly playing right now" (a paused session still counts):
  /// it's what [pause]/[resume] guard on, so an app-lifecycle transition
  /// that arrives while the feature is off is a no-op instead of touching a
  /// player that was never asked to play anything.
  bool _started = false;

  /// Starts the track from the beginning and loops it indefinitely.
  /// Idempotent — [BackgroundMusicController] only calls this on an
  /// off→on transition, but a repeat call costs nothing.
  Future<void> start() async {
    if (_started) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource(_trackAssetPath));
    _started = true;
  }

  /// Stops and releases playback outright — the on→off transition (the
  /// Настройки toggle), not the foreground→background one below.
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _player.stop();
  }

  /// Pauses without releasing — called on every app-lifecycle transition
  /// away from `resumed` while the feature is on, so the track is never
  /// heard while the user isn't looking at the app (this task: "играть
  /// будет... когда пользователь находится в приложении").
  Future<void> pause() async {
    if (!_started) return;
    await _player.pause();
  }

  /// Resumes from wherever [pause] left off — the foreground-return half of
  /// the same lifecycle guard.
  Future<void> resume() async {
    if (!_started) return;
    await _player.resume();
  }

  Future<void> dispose() => _player.dispose();
}
