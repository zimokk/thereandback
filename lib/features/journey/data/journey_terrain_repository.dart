import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/scene_prop_anchor.dart';
import '../domain/terrain_profile.dart';
import 'journey_timing_repository.dart' show journeyTimingAssetPath;

/// A quest's terrain profile plus its anchored scene props (§6.1, §9.1) —
/// what `journey_terrain_repository.dart` parses out of `locations.json`'s
/// `landmarks[]`. A typedef record, not a new class, the same choice
/// `route_mapping.dart`'s `SplitRoute` already makes for "just a bundle of
/// two already-existing domain types".
typedef JourneyTerrainContent = ({
  TerrainProfile profile,
  List<ScenePropAnchor> props,
});

/// Height (§domain — unitless, scaled to pixels only in presentation)
/// implicitly assigned to the route's very start/end when no landmark there
/// authors one explicitly — a neutral baseline, not a claim that point A/B
/// are literally at sea level.
const double _defaultEndpointHeight = 0.0;

/// Loads and parses `assets/journeys/{journeyId}/locations.json`'s
/// `landmarks[].terrainHeight`/`landmarks[].prop` fields (§6.1).
///
/// Reuses `journey_timing_repository.dart`'s [journeyTimingAssetPath] — this
/// is the same file, just a different, narrowly-scoped subset of its
/// fields (that repository reads `segments[]` timing; this one reads two
/// per-landmark technical fields, ignoring `narrative`/`historicalNote`,
/// which stay Phase 11's job).
///
/// Returns `null` specifically when the journey ships no `locations.json`
/// at all — today, any journey other than `odyssey-ithaca` — so a caller
/// falls back to `terrain_layer.dart`'s placeholder sine wave and draws no
/// anchored props. A `locations.json` that *is* present but malformed still
/// throws (a content bug to fix, not a silent fallback) — mirroring
/// `journey_timing_repository.dart`/`quest_map_repository.dart`.
Future<JourneyTerrainContent?> tryLoadJourneyTerrainContent(
  AssetBundle bundle,
  String journeyId,
) async {
  final String source;
  try {
    source = await bundle.loadString(journeyTimingAssetPath(journeyId));
  } catch (error) {
    // Only "does this journey even have a locations.json" is caught here —
    // parsing happens outside this try block, so a malformed file that *is*
    // present still throws `FormatException` uncaught, per this function's
    // own contract.
    if (error is FormatException) rethrow;
    return null;
  }
  return parseJourneyTerrainContent(source);
}

/// Parses `locations.json`'s `landmarks[].terrainHeight`/`landmarks[].prop`
/// into a [JourneyTerrainContent] (§6.1).
///
/// The route's total length comes from the same file's own `journey.
/// totalMeters` — not a caller-supplied parameter — so there is exactly one
/// number this parsing trusts for "where does the route end", the same way
/// `map.json`'s own `totalMeters` is self-contained rather than checked
/// against a value from elsewhere.
///
/// Validates: every landmark's `meters` is within `[0, totalMeters]`;
/// `terrainHeight`, where present, is a number; `prop`, where present, has a
/// non-empty `asset` and a `layer` that is exactly `"behind"` or `"front"`;
/// the `meters` of landmarks that author a `terrainHeight` never decrease
/// (mirrors `quest_map_repository.dart`'s "path meters must not decrease").
/// The resulting [TerrainProfile] always spans the whole route: a synthetic
/// point is added at `0` and at `totalMeters` whenever no authored landmark
/// already sits exactly there, so the line returns to a neutral baseline at
/// point A/B even when every authored point is mid-route.
JourneyTerrainContent parseJourneyTerrainContent(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('locations.json must be a JSON object');
  }

  final journey = decoded['journey'];
  if (journey is! Map<String, dynamic>) {
    throw const FormatException('locations.json needs a "journey" object');
  }
  final totalMeters = _int(journey, 'totalMeters');

  final rawLandmarks = decoded['landmarks'];
  if (rawLandmarks is! List) {
    throw const FormatException('locations.json needs a "landmarks" list');
  }

  final terrainPoints = <TerrainPoint>[];
  final props = <ScenePropAnchor>[];

  for (final entry in rawLandmarks) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('every "landmarks" entry must be an object');
    }

    final id = _string(entry, 'id');
    final meters = _int(entry, 'meters');
    if (meters < 0 || meters > totalMeters) {
      throw FormatException('landmark "$id" meters $meters is off the route');
    }

    final terrainHeight = entry['terrainHeight'];
    if (terrainHeight != null) {
      if (terrainHeight is! num) {
        throw FormatException('landmark "$id" terrainHeight must be a number');
      }
      if (terrainPoints.isNotEmpty && meters < terrainPoints.last.meters) {
        throw FormatException(
          'landmark "$id" terrainHeight point ($meters m) comes before the '
          'previous one (${terrainPoints.last.meters} m) — terrain points '
          'must not decrease',
        );
      }
      terrainPoints.add(
        TerrainPoint(meters: meters, height: terrainHeight.toDouble()),
      );
    }

    final rawProp = entry['prop'];
    if (rawProp != null) {
      if (rawProp is! Map<String, dynamic>) {
        throw FormatException('landmark "$id" prop must be an object');
      }
      final asset = _string(rawProp, 'asset');
      final layerName = _string(rawProp, 'layer');
      final layer = _parsePropLayer(layerName);
      if (layer == null) {
        throw FormatException(
          'landmark "$id" prop layer must be "behind" or "front", got '
          '"$layerName"',
        );
      }
      props.add(
        ScenePropAnchor(id: id, meters: meters, asset: asset, layer: layer),
      );
    }
  }

  if (terrainPoints.isEmpty || terrainPoints.first.meters != 0) {
    terrainPoints.insert(
      0,
      const TerrainPoint(meters: 0, height: _defaultEndpointHeight),
    );
  }
  if (terrainPoints.last.meters != totalMeters) {
    terrainPoints.add(
      TerrainPoint(meters: totalMeters, height: _defaultEndpointHeight),
    );
  }

  return (profile: TerrainProfile(points: terrainPoints), props: props);
}

/// Matches a `prop.layer` string against [ScenePropLayer]'s own names
/// (`"behind"`/`"front"`) — `null` for anything else, left to the caller to
/// turn into a `FormatException` with the offending landmark's id in it.
ScenePropLayer? _parsePropLayer(String name) {
  for (final layer in ScenePropLayer.values) {
    if (layer.name == name) return layer;
  }
  return null;
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
