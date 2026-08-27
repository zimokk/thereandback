import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/route_mapping.dart';

/// A quest's drawn map as the app actually got it: the parsed `map.json`
/// plus whether the illustration it points at is really in this build.
///
/// The two travel together because the Карта tab renders differently when
/// the art is missing — it still draws the route line and the traveler's
/// position, over a plain background instead of the illustration — and
/// deciding that at paint time would mean guessing from a failed image
/// load mid-build.
class QuestMapAssets {
  const QuestMapAssets({required this.map, required this.hasIllustration});

  final QuestMap map;

  /// Whether [QuestMap.imageAsset] is bundled in this build.
  final bool hasIllustration;
}

/// Path of a quest's map description, by convention (§4).
String questMapAssetPath(String journeyId) =>
    'assets/journeys/$journeyId/map.json';

/// Loads and parses `assets/journeys/{journeyId}/map.json`, and checks
/// whether the illustration it names is bundled.
///
/// Throws whatever [AssetBundle.loadString] throws when the quest has no
/// `map.json` at all, and a [FormatException] when it has one that doesn't
/// describe a usable route — a caller shows its own fallback either way.
Future<QuestMapAssets> loadQuestMap(
  AssetBundle bundle,
  String journeyId,
) async {
  final map = parseQuestMap(
    await bundle.loadString(questMapAssetPath(journeyId)),
  );
  return QuestMapAssets(
    map: map,
    hasIllustration: await _isBundled(bundle, map.imageAsset),
  );
}

/// Parses `map.json` content into a [QuestMap] (§6.2).
///
/// Validates what the overlay math relies on rather than trusting the file:
/// at least two vertices, normalized coordinates, non-decreasing meters
/// starting at 0 and ending at the declared total. Content authored by
/// hand is exactly the kind that drifts, and a silently bent route would
/// show up as a traveler walking off the drawn line.
QuestMap parseQuestMap(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('map.json must be a JSON object');
  }

  final journeyId = _string(decoded, 'journeyId');
  final totalMeters = _int(decoded, 'totalMeters');
  final image = decoded['image'];
  if (image is! Map<String, dynamic>) {
    throw const FormatException('map.json needs an "image" object');
  }

  final rawPath = decoded['path'];
  if (rawPath is! List || rawPath.length < 2) {
    throw const FormatException('map.json "path" needs at least 2 vertices');
  }

  final vertices = <RouteVertex>[];
  for (final entry in rawPath) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('every "path" entry must be an object');
    }
    final meters = _int(entry, 'meters');
    if (vertices.isNotEmpty && meters < vertices.last.cumulativeMeters) {
      throw FormatException(
        'path meters must not decrease (found $meters after '
        '${vertices.last.cumulativeMeters})',
      );
    }
    vertices.add(
      RouteVertex(
        x: _normalized(entry, 'x'),
        y: _normalized(entry, 'y'),
        cumulativeMeters: meters,
      ),
    );
  }

  if (vertices.first.cumulativeMeters != 0) {
    throw const FormatException('the first path vertex must sit at 0 m');
  }
  if (vertices.last.cumulativeMeters != totalMeters) {
    throw FormatException(
      'the last path vertex must sit at totalMeters ($totalMeters), '
      'found ${vertices.last.cumulativeMeters}',
    );
  }

  final rawLandmarks = decoded['landmarks'];
  if (rawLandmarks is! List) {
    throw const FormatException('map.json needs a "landmarks" list');
  }
  final landmarks = <MapLandmark>[];
  for (final entry in rawLandmarks) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('every "landmarks" entry must be an object');
    }
    final meters = _int(entry, 'meters');
    if (meters < 0 || meters > totalMeters) {
      throw FormatException('landmark meters $meters is off the route');
    }
    landmarks.add(
      MapLandmark(
        id: _string(entry, 'id'),
        name: _string(entry, 'name'),
        x: _normalized(entry, 'x'),
        y: _normalized(entry, 'y'),
        meters: meters,
      ),
    );
  }
  landmarks.sort((a, b) => a.meters.compareTo(b.meters));

  return QuestMap(
    journeyId: journeyId,
    imageAsset: _string(image, 'asset'),
    imageWidth: _int(image, 'width'),
    imageHeight: _int(image, 'height'),
    totalMeters: totalMeters,
    polyline: RoutePolyline(vertices: vertices),
    landmarks: landmarks,
  );
}

Future<bool> _isBundled(AssetBundle bundle, String asset) async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return manifest.listAssets().contains(asset);
  } catch (_) {
    // A bundle with no readable asset manifest (a test bundle, say) can
    // resolve nothing — the caller falls back to drawing the route without
    // art. Deliberately catching everything: a missing bundle entry surfaces
    // as a `FlutterError`, which is an `Error`, not an `Exception`.
    return false;
  }
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('"$key" must be a non-empty string');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('"$key" must be a whole number');
  return value;
}

double _normalized(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) throw FormatException('"$key" must be a number');
  final normalized = value.toDouble();
  if (normalized < 0 || normalized > 1) {
    throw FormatException('"$key" must be normalized to 0..1, got $value');
  }
  return normalized;
}
