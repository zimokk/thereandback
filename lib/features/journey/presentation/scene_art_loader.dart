import '../data/scene_art_repository.dart';
import '../domain/segment_biomes.dart';
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
  List<BiomeSpan>? _spans;
  int _loadFirst = -1;
  int _loadLast = -1;
  int _keepFirst = -1;
  int _keepLast = -1;

  /// Every biome in the keep range — what a load finishing late is checked
  /// against.
  Set<String> _keep = const {};

  /// Declares which stretch of the route the scene needs art for, as
  /// inclusive index ranges into `controller.biomes`:
  ///
  /// - `[loadFirst, loadLast]` — every span that is on screen or about to
  ///   be (the scene adds a prefetch margin). Each one's art is loaded.
  /// - `[keepFirst, keepLast]` — a wider range, containing the first. Art
  ///   for anything outside it is released; anything between the two
  ///   ranges is neither loaded nor released.
  ///
  /// Ranges, not "the biome under the view and the next one": the ground
  /// and every parallax layer draw *every* biome on screen, and a screen at
  /// 20 km wide routinely shows two or three. Loading only the biome at the
  /// centre left the rest of the screen without ground or relief until the
  /// centre reached the boundary — then it popped in, and the line the
  /// traveler walks jumped by its full relief; crossing the boundary
  /// released the biome just left while half the screen still showed it.
  /// The gap between the two ranges is hysteresis: panning back and forth
  /// across the edge of the load range never evicts and re-decodes the same
  /// four images on every swing.
  ///
  /// Called every frame. Four integer comparisons on the overwhelming
  /// majority of frames, where nothing has changed (the `flame-scene`
  /// skill's "no per-frame allocation" rule).
  ///
  /// The quest and its spans come from the controller rather than the
  /// caller: the game loop that calls this is reading that same controller
  /// anyway, and one source for "which quest" is one fewer way for the
  /// loader and the scene to disagree about which folder of art they are on.
  void ensureSpans(int loadFirst, int loadLast, int keepFirst, int keepLast) {
    final journeyId = _controller.journeyId;
    final spans = _controller.biomes;
    if (journeyId == _journeyId &&
        identical(spans, _spans) &&
        loadFirst == _loadFirst &&
        loadLast == _loadLast &&
        keepFirst == _keepFirst &&
        keepLast == _keepLast) {
      return;
    }

    // A quest switch invalidates everything: the same biome name in another
    // quest is a different folder of art (`scene_art_catalog.dart`).
    if (journeyId != _journeyId) {
      _journeyId = journeyId;
      _controller.biomeArt = const {};
      _repository.retainOnly(const []);
    }

    _spans = spans;
    _loadFirst = loadFirst;
    _loadLast = loadLast;
    _keepFirst = keepFirst;
    _keepLast = keepLast;

    final load = _biomesIn(spans, loadFirst, loadLast);
    final keep = _keep = {...load, ..._biomesIn(spans, keepFirst, keepLast)};

    // Drop what is no longer drawn *before* asking the repository to
    // dispose it: a frame must never reach a `ui.Image` that has already
    // been disposed, and this map is what the frame reads.
    _controller.biomeArt = {
      for (final entry in _controller.biomeArt.entries)
        if (keep.contains(entry.key)) entry.key: entry.value,
    };
    _repository.retainOnly(keep);

    for (final biome in load) {
      _load(journeyId, biome);
    }
  }

  static Set<String> _biomesIn(List<BiomeSpan> spans, int first, int last) => {
    for (var i = first < 0 ? 0 : first; i <= last && i < spans.length; i++)
      spans[i].biome,
  };

  void _load(String journeyId, String biome) {
    if (_controller.biomeArt.containsKey(biome)) return;
    _repository.loadBiome(journeyId: journeyId, biome: biome).then((art) {
      // The quest (or the view) may have moved on while this was in
      // flight. A biome released since then has already had its images
      // disposed by the repository — publishing it would hand the next
      // frame a disposed `ui.Image` to draw.
      if (art == null || journeyId != _journeyId || !_keep.contains(biome)) {
        return;
      }
      _controller.biomeArt = {..._controller.biomeArt, biome: art};
    });
  }
}
