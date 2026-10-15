import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/journey/data/scene_art_catalog.dart';
import 'package:thereandback/features/journey/data/scene_art_repository.dart';
import 'package:thereandback/features/journey/domain/segment_biomes.dart';
import 'package:thereandback/features/journey/presentation/journey_scene_controller.dart';
import 'package:thereandback/features/journey/presentation/scene_art_loader.dart';

/// Records what the loader asks for and lets each test decide when a load
/// finishes.
class _FakeRepository implements SceneArtRepository {
  final Map<String, Completer<BiomeArt?>> pending = {};
  List<String> retained = [];

  @override
  Future<BiomeArt?> loadBiome({
    required String journeyId,
    required String biome,
  }) => pending.putIfAbsent(biome, Completer.new).future;

  @override
  void retainOnly(Iterable<String> biomes) {
    retained = biomes.toList();
    pending.removeWhere((key, _) => !retained.contains(key));
  }

  @override
  ui.Image? propSprite(String asset) => null;

  void finish(String biome) => pending[biome]!.complete((
    biome: biome,
    layers: const <SceneArtLayer, ui.Image>{},
    ground: null,
  ));
}

const _spans = [
  BiomeSpan(segmentId: 'a', biome: 'a', fromMeters: 0, toMeters: 10),
  BiomeSpan(segmentId: 'b', biome: 'b', fromMeters: 10, toMeters: 20),
  BiomeSpan(segmentId: 'c', biome: 'c', fromMeters: 20, toMeters: 30),
  BiomeSpan(segmentId: 'd', biome: 'd', fromMeters: 30, toMeters: 40),
];

void main() {
  late _FakeRepository repository;
  late JourneySceneController controller;
  late SceneArtLoader loader;

  setUp(() {
    repository = _FakeRepository();
    controller = JourneySceneController()
      ..journeyId = 'q'
      ..biomes = _spans;
    loader = SceneArtLoader(repository: repository, controller: controller);
  });

  test('loads every biome in the load range, not just the one under the '
      'view — the ground draws every biome on screen', () async {
    loader.ensureSpans(0, 2, 0, 3);
    expect(repository.pending.keys, unorderedEquals(['a', 'b', 'c']));

    repository
      ..finish('a')
      ..finish('b')
      ..finish('c');
    await Future<void>.delayed(Duration.zero);
    expect(controller.biomeArt.keys, unorderedEquals(['a', 'b', 'c']));
  });

  test('keeps what is between the load and keep ranges, releases only what '
      'is past the keep range — panning back and forth near an edge never '
      'evicts and re-decodes', () async {
    loader.ensureSpans(0, 1, 0, 2);
    repository
      ..finish('a')
      ..finish('b');
    await Future<void>.delayed(Duration.zero);

    // The view moves on: 'a' leaves the load range but is still kept.
    loader.ensureSpans(1, 2, 0, 3);
    expect(controller.biomeArt.keys, contains('a'));
    expect(repository.retained, contains('a'));

    // Further on: 'a' is past the keep range too, and only now released.
    loader.ensureSpans(2, 3, 1, 3);
    expect(controller.biomeArt.keys, isNot(contains('a')));
    expect(repository.retained, isNot(contains('a')));
  });

  test('a load that finishes after its biome was released is never '
      'published — its images are already disposed', () async {
    loader.ensureSpans(0, 0, 0, 0);
    final inFlight = repository.pending['a']!;
    loader.ensureSpans(3, 3, 3, 3);

    inFlight.complete((
      biome: 'a',
      layers: const <SceneArtLayer, ui.Image>{},
      ground: null,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(controller.biomeArt.keys, isNot(contains('a')));
  });

  test('the same ranges again is a no-op', () {
    loader.ensureSpans(0, 1, 0, 2);
    final retained = repository.retained;
    loader.ensureSpans(0, 1, 0, 2);
    expect(identical(repository.retained, retained), isTrue);
  });
}
