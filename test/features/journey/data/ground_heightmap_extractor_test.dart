import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:thereandback/features/journey/data/ground_heightmap_extractor.dart';

/// Builds a raw RGBA buffer from a per-column "topmost opaque row" map:
/// `null` means the column has no ground drawn in it at all.
ByteData _rgba({
  required int width,
  required int height,
  required List<int?> topRows,
}) {
  final data = ByteData(width * height * 4);
  for (var x = 0; x < width; x++) {
    final top = topRows[x];
    if (top == null) continue;
    for (var y = top; y < height; y++) {
      data.setUint8((y * width + x) * 4 + 3, 255);
    }
  }
  return data;
}

void main() {
  group('extractGroundHeightmap (§6.1 — relief read off the drawn tile)', () {
    test('one sample per pixel column', () {
      final map = extractGroundHeightmap(
        rgba: _rgba(width: 4, height: 8, topRows: const [4, 4, 4, 4]),
        width: 4,
        height: 8,
        tileMeters: 1000,
      );
      expect(map.samples, hasLength(4));
      expect(map.tileMeters, 1000);
    });

    test('a flat tile is flat, wherever on the tile it is drawn — absolute '
        'elevation is the authored profile\'s job, not the art\'s', () {
      for (final row in const [1, 4, 7]) {
        final map = extractGroundHeightmap(
          rgba: _rgba(width: 4, height: 8, topRows: [row, row, row, row]),
          width: 4,
          height: 8,
          tileMeters: 1000,
        );
        expect(map.samples, everyElement(closeTo(0.0, 1e-12)));
      }
    });

    test('a higher silhouette reads as higher ground, centred on the tile\'s '
        'own mean', () {
      // Two columns high (row 2), two low (row 6): mean sits at row 4.
      final map = extractGroundHeightmap(
        rgba: _rgba(width: 4, height: 8, topRows: const [2, 2, 6, 6]),
        width: 4,
        height: 8,
        tileMeters: 1000,
      );
      expect(map.samples[0], closeTo(0.5, 1e-12));
      expect(map.samples[1], closeTo(0.5, 1e-12));
      expect(map.samples[2], closeTo(-0.5, 1e-12));
      expect(map.samples[3], closeTo(-0.5, 1e-12));
      // Centred: the samples cancel out.
      expect(map.samples.reduce((a, b) => a + b), closeTo(0.0, 1e-12));
    });

    test('amplitude is not rescaled — a gently drawn biome stays gentle '
        'next to a dramatic one', () {
      final gentle = extractGroundHeightmap(
        rgba: _rgba(width: 4, height: 8, topRows: const [3, 3, 5, 5]),
        width: 4,
        height: 8,
        tileMeters: 1000,
      );
      final dramatic = extractGroundHeightmap(
        rgba: _rgba(width: 4, height: 8, topRows: const [0, 0, 7, 7]),
        width: 4,
        height: 8,
        tileMeters: 1000,
      );
      expect(gentle.samples[0].abs(), lessThan(dramatic.samples[0].abs()));
      expect(gentle.samples[0], closeTo(0.25, 1e-12));
    });

    test('a fully transparent column takes the nearest drawn column\'s '
        'height instead of becoming a hole', () {
      final map = extractGroundHeightmap(
        rgba: _rgba(width: 4, height: 8, topRows: const [2, null, 2, 2]),
        width: 4,
        height: 8,
        tileMeters: 1000,
      );
      expect(map.samples, everyElement(closeTo(0.0, 1e-12)));
    });

    test('gap filling wraps around the tile, which repeats', () {
      final map = extractGroundHeightmap(
        rgba: _rgba(width: 4, height: 8, topRows: const [null, 6, 6, 6]),
        width: 4,
        height: 8,
        tileMeters: 1000,
      );
      // The empty first column copies its neighbour, so nothing steps.
      expect(map.samples[0], closeTo(map.samples[1], 1e-12));
    });

    test('an entirely transparent tile is flat, not an error', () {
      final map = extractGroundHeightmap(
        rgba: _rgba(width: 3, height: 4, topRows: const [null, null, null]),
        width: 3,
        height: 4,
        tileMeters: 500,
      );
      expect(map.samples, [0.0, 0.0, 0.0]);
    });

    test('centerFraction marks where the tile\'s mean ground level sits, so '
        'presentation can line the drawn tile up with the walking line', () {
      // Mean of rows 2 and 6 is row 4, i.e. halfway down an 8-row tile.
      final centred = extractGroundHeightmap(
        rgba: _rgba(width: 4, height: 8, topRows: const [2, 2, 6, 6]),
        width: 4,
        height: 8,
        tileMeters: 1000,
      );
      expect(centred.centerFraction, closeTo(0.5, 1e-12));

      // Ground drawn high on the tile: its mean row is near the top.
      final high = extractGroundHeightmap(
        rgba: _rgba(width: 4, height: 8, topRows: const [2, 2, 2, 2]),
        width: 4,
        height: 8,
        tileMeters: 1000,
      );
      expect(high.centerFraction, closeTo(0.25, 1e-12));
    });

    test('a zero-sized image yields no samples', () {
      expect(
        extractGroundHeightmap(
          rgba: ByteData(0),
          width: 0,
          height: 0,
          tileMeters: 500,
        ).samples,
        isEmpty,
      );
    });

    test('a tile drawn to loop keeps looping after extraction — the seam '
        'between repetitions is no sharper than any other column', () {
      // First and last column drawn at the same height, a bump in between.
      final map = extractGroundHeightmap(
        rgba: _rgba(width: 6, height: 16, topRows: const [8, 6, 4, 4, 6, 8]),
        width: 6,
        height: 16,
        tileMeters: 1000,
      );
      final seamStep = (map.samples.first - map.samples.last).abs();
      final biggestInteriorStep = [
        for (var i = 1; i < map.samples.length; i++)
          (map.samples[i] - map.samples[i - 1]).abs(),
      ].reduce((a, b) => a > b ? a : b);
      expect(seamStep, lessThanOrEqualTo(biggestInteriorStep));
    });
  });
}
