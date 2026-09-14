import '../data/scene_art_repository.dart';
import 'journey_scene_controller.dart';

/// Keeps the biome art the scene is currently drawing loaded, and lets go
/// of what has scrolled out of reach (§6.1, §9.1).
///
/// Sits between the game loop, which knows *which* biomes are on screen
/// (it has the pan position), and [SceneArtRepository], which knows how to
/// load them. Neither of those should grow the other's job: the loop must
/// not await anything mid-frame, and the repository must not guess what is
/// visible — disposing a `ui.Image` still being drawn would crash the frame.
///
/// A plain object with no Flutter, Riverpod or Flame import — the same
/// framework-agnostic seam [JourneySceneController] itself is, and for the
/// same reason: it is driven from the game loop but owned by the widget.
class SceneArtLoader {
  SceneArtLoader({
    required SceneArtRepository repository,
    required JourneySceneController controller,
  }) : _repository = repository, // ignore: prefer_initializing_formals
       _controller = controller; // ignore: prefer_initializing_formals

  final SceneArtRepository _repository;
  final JourneySceneController _controller;

  String _journeyId = '';
  String? _current;
  String? _next;

  /// Declares which biomes the scene needs right now — the one under the
  /// view and, mid-transition, the one being crossed into.
  ///
  /// Called every frame. Takes the two biomes as plain strings rather than a
  /// collection precisely because of that: comparing two fields allocates
  /// nothing on the overwhelming majority of frames, where nothing has
  /// changed and this returns immediately (the `flame-scene` skill's "no
  /// per-frame allocation" rule).
  ///
  /// The quest comes from the controller rather than the caller: the game
  /// loop that calls this is reading that same controller anyway, and one
  /// source for "which quest" is one fewer way for the loader and the scene
  /// to disagree about which folder of art they are on.
  void ensureFor({required String current, String? next}) {
    final journeyId = _controller.journeyId;
    if (journeyId == _journeyId && current == _current && next == _next) {
      return;
    }

    // A quest switch invalidates everything: the same biome name in another
    // quest is a different folder of art (`scene_art_catalog.dart`).
    if (journeyId != _journeyId) {
      _journeyId = journeyId;
      _controller.biomeArt = const {};
      _repository.retainOnly(const []);
    }

    _current = current;
    _next = next;

    // Drop what is no longer drawn *before* asking the repository to
    // dispose it: a frame must never reach a `ui.Image` that has already
    // been disposed, and this map is what the frame reads.
    _controller.biomeArt = {
      for (final entry in _controller.biomeArt.entries)
        if (entry.key == current || entry.key == next) entry.key: entry.value,
    };
    _repository.retainOnly([current, ?next]);

    _load(journeyId, current);
    if (next != null) _load(journeyId, next);
  }

  void _load(String journeyId, String biome) {
    if (_controller.biomeArt.containsKey(biome)) return;
    _repository.loadBiome(journeyId: journeyId, biome: biome).then((art) {
      // The quest (or the scene) may have moved on while this was in
      // flight — dropping a late arrival is cheaper than drawing art for a
      // route the user has left, and the repository has already disposed
      // it if it was evicted.
      if (art == null || journeyId != _journeyId) return;
      _controller.biomeArt = {..._controller.biomeArt, biome: art};
    });
  }
}
