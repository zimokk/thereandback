import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/journey/data/scene_art_catalog.dart';
import 'package:thereandback/features/journey/data/scene_art_repository.dart';

/// Paints a tile whose ground silhouette is a step: the left half drawn
/// high, the right half low — so the extracted relief is unmistakable.
Future<Uint8List> _stepTilePng({int width = 16, int height = 16}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFF000000);
  canvas.drawRect(Rect.fromLTWH(0, 4, width / 2, height - 4.0), paint);
  canvas.drawRect(
    Rect.fromLTWH(width / 2, 12, width / 2, height - 12.0),
    paint,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// An [AssetBundle] holding exactly the paths it was given — anything else
/// throws, the way a real bundle does for an asset that is not declared.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);

  final Map<String, Uint8List> files;
  final List<String> requested = [];

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    final bytes = files[key];
    if (bytes == null) throw FlutterError('no asset: $key');
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List tile;

  setUpAll(() async {
    tile = await _stepTilePng();
  });

  String pathFor(SceneArtLayer layer) =>
      sceneArtAssetPath('q', 'pine_forest', layer);

  group('AssetSceneArtRepository', () {
    test('loads every layer a biome ships and extracts the ground relief '
        'from the drawn silhouette', () async {
      final bundle = _FakeBundle({
        for (final layer in SceneArtLayer.values) pathFor(layer): tile,
      });
      final repository = AssetSceneArtRepository(bundle: bundle);

      final art = await repository.loadBiome(
        journeyId: 'q',
        biome: 'pine_forest',
      );

      expect(art, isNotNull);
      expect(art!.layers.keys, containsAll(SceneArtLayer.values));
      expect(art.ground, isNotNull);
      expect(art.ground!.samples, hasLength(16));
      // Left half drawn higher than the right half.
      expect(art.ground!.samples.first, greaterThan(art.ground!.samples.last));
    });

    test('a biome part-way through being drawn loads what exists — the '
        'scene falls back per layer, so art can land file by file', () async {
      final bundle = _FakeBundle({pathFor(SceneArtLayer.ground): tile});
      final repository = AssetSceneArtRepository(bundle: bundle);

      final art = await repository.loadBiome(
        journeyId: 'q',
        biome: 'pine_forest',
      );

      expect(art!.layers.keys, [SceneArtLayer.ground]);
      expect(art.ground, isNotNull);
    });

    test('a biome with no art at all is null, not an empty result', () async {
      final repository = AssetSceneArtRepository(bundle: _FakeBundle({}));
      expect(
        await repository.loadBiome(journeyId: 'q', biome: 'pine_forest'),
        isNull,
      );
    });

    test('a biome without a ground layer has no relief but still draws its '
        'other layers', () async {
      final bundle = _FakeBundle({pathFor(SceneArtLayer.far): tile});
      final repository = AssetSceneArtRepository(bundle: bundle);

      final art = await repository.loadBiome(
        journeyId: 'q',
        biome: 'pine_forest',
      );

      expect(art!.ground, isNull);
      expect(art.layers.keys, [SceneArtLayer.far]);
    });

    test('repeated calls share one load instead of decoding again every '
        'frame the scene asks', () async {
      final bundle = _FakeBundle({
        for (final layer in SceneArtLayer.values) pathFor(layer): tile,
      });
      final repository = AssetSceneArtRepository(bundle: bundle);

      final first = repository.loadBiome(journeyId: 'q', biome: 'pine_forest');
      final second = repository.loadBiome(journeyId: 'q', biome: 'pine_forest');
      await Future.wait([first, second]);

      expect(bundle.requested, hasLength(SceneArtLayer.values.length));
      expect(identical(await first, await second), isTrue);
    });

    test(
      'a prop sprite loads on first ask and is there on the next frame — '
      'the render loop cannot await, so the first call returns null',
      () async {
        const asset = 'assets/journeys/q/props/cyclops.webp';
        final bundle = _FakeBundle({asset: tile});
        final repository = AssetSceneArtRepository(bundle: bundle);

        expect(repository.propSprite(asset), isNull);
        await pumpEventQueue();
        expect(repository.propSprite(asset), isNotNull);
      },
    );

    test('a prop the quest names but does not ship stays null instead of '
        'retrying the same missing file every frame', () async {
      const asset = 'assets/journeys/q/props/missing.webp';
      final bundle = _FakeBundle({});
      final repository = AssetSceneArtRepository(bundle: bundle);

      expect(repository.propSprite(asset), isNull);
      await pumpEventQueue();
      expect(repository.propSprite(asset), isNull);
      expect(repository.propSprite(asset), isNull);
      expect(bundle.requested.where((key) => key == asset), hasLength(1));
    });

    test('retainOnly drops what the scene no longer draws and keeps the '
        'rest loaded', () async {
      final bundle = _FakeBundle({
        sceneArtAssetPath('q', 'a', SceneArtLayer.far): tile,
        sceneArtAssetPath('q', 'b', SceneArtLayer.far): tile,
      });
      final repository = AssetSceneArtRepository(bundle: bundle);

      await repository.loadBiome(journeyId: 'q', biome: 'a');
      await repository.loadBiome(journeyId: 'q', biome: 'b');
      repository.retainOnly(['b']);
      bundle.requested.clear();

      await repository.loadBiome(journeyId: 'q', biome: 'b');
      expect(bundle.requested, isEmpty, reason: 'b was retained');

      await repository.loadBiome(journeyId: 'q', biome: 'a');
      expect(bundle.requested, isNotEmpty, reason: 'a was evicted');
    });
  });
}
