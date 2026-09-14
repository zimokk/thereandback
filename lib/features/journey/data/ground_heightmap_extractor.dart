import 'dart:typed_data';

import '../domain/ground_heightmap.dart';

/// Alpha value, `0..255`, at or above which a pixel counts as part of the
/// drawn ground rather than the transparent sky above it.
///
/// Halfway: the art's own edge is drawn as a hard silhouette (§9 — "силуэты
/// сплошной заливкой"), so the only pixels near this value are the
/// anti-aliased edge itself, and the traveler's feet land in the middle of
/// that one-pixel ramp either way.
const int groundAlphaThreshold = 128;

/// Reads one biome's relief straight off its drawn ground tile — the "в
/// зависимости от арта — рельеф" half of the ground line (§6.1, §9.1).
///
/// Walks each pixel column top-down and records where the silhouette
/// starts: that boundary, column by column, *is* the line the traveler
/// walks on, so the figure can never drift off the hills that are drawn.
///
/// [rgba] is the image's raw pixels, 4 bytes per pixel, row-major — what
/// `ui.Image.toByteData(format: rawRgba)` returns. Pure and byte-level on
/// purpose: extraction is testable against a hand-built buffer without
/// decoding a real file or running an engine.
///
/// Heights come out unitless, centred on the tile's own mean, positive
/// upwards, with the tile's full height spanning `-1..1`:
///
/// - **Centred**, so two neighbouring biomes whose ground happens to be
///   drawn at different heights on their tiles do not produce a step in the
///   line where one ends and the next begins. Absolute elevation is the
///   authored `TerrainProfile`'s job (`scene_ground.dart`), not the art's.
/// - **Not rescaled** to fill `-1..1`, so a deliberately flat biome stays
///   flat instead of being stretched into looking as dramatic as a mountain
///   pass. What the illustration draws is what the traveler walks.
///
/// A fully transparent column (no ground drawn at all there) takes its
/// height from the nearest column that does have ground, scanning both ways
/// and wrapping around the tile — a gap in the art becomes a plateau rather
/// than a hole the traveler falls into. An image with no opaque pixel
/// anywhere yields a flat profile.
GroundHeightmap extractGroundHeightmap({
  required ByteData rgba,
  required int width,
  required int height,
  required int tileMeters,
}) {
  if (width <= 0 || height <= 0) {
    return GroundHeightmap(samples: const [], tileMeters: tileMeters);
  }

  // Topmost opaque row per column, or null where the column is empty.
  final topRows = List<int?>.filled(width, null);
  for (var x = 0; x < width; x++) {
    for (var y = 0; y < height; y++) {
      final alpha = rgba.getUint8((y * width + x) * 4 + 3);
      if (alpha >= groundAlphaThreshold) {
        topRows[x] = y;
        break;
      }
    }
  }

  _fillGapsFromNearestNeighbour(topRows);
  if (topRows.first == null) {
    // Nothing opaque anywhere — a flat tile, not an error: the caller
    // decides whether art this empty is worth drawing at all.
    return GroundHeightmap(
      samples: List<double>.filled(width, 0),
      tileMeters: tileMeters,
    );
  }

  // Row index -> height, positive upwards, the tile's full height spanning
  // -1..1 before centring.
  final halfHeight = height / 2;
  final raw = [for (final row in topRows) (halfHeight - row!) / halfHeight];

  final mean = raw.reduce((a, b) => a + b) / raw.length;
  final samples = [for (final value in raw) (value - mean).clamp(-1.0, 1.0)];

  // Where the mean row sits down the tile — see [GroundHeightmap.
  // centerFraction]. Derived from the same mean the samples are centred on,
  // so the drawn tile and the walking line cannot be offset from each other.
  final meanRow = halfHeight - mean * halfHeight;

  return GroundHeightmap(
    samples: samples,
    tileMeters: tileMeters,
    centerFraction: (meanRow / height).clamp(0.0, 1.0),
  );
}

/// Replaces every `null` (fully transparent column) with the nearest
/// non-null value, measuring distance around the tile rather than along it
/// — the tile repeats, so its first and last columns are neighbours.
///
/// Leaves the list untouched when every entry is `null`; the caller reads
/// that case off the first element.
void _fillGapsFromNearestNeighbour(List<int?> rows) {
  final width = rows.length;
  if (!rows.contains(null)) return;
  final filled = List<int?>.of(rows);

  for (var x = 0; x < width; x++) {
    if (rows[x] != null) continue;
    for (var distance = 1; distance <= width ~/ 2 + 1; distance++) {
      final before = rows[(x - distance) % width];
      if (before != null) {
        filled[x] = before;
        break;
      }
      final after = rows[(x + distance) % width];
      if (after != null) {
        filled[x] = after;
        break;
      }
    }
  }

  rows.setAll(0, filled);
}
