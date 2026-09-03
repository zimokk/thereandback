import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/fictional_time.dart';

/// Path of a quest's segment content, by convention (§4) — the same file
/// `quest_map`'s landmark work will eventually read narrative/landmarks
/// from; this repository only reads the `segments[]` timing fields.
String journeyTimingAssetPath(String journeyId) =>
    'assets/journeys/$journeyId/locations.json';

/// No more than 1 in-fiction day may elapse per this many real meters of a
/// segment — the pace-safety rule [parseJourneySegmentTimings] enforces, so
/// an ordinary walk can never flip the sky through several story-days at
/// once (CLAUDE.md §6.1's "не должно быть так, что я хожу 2 часа, а прошло
/// несколько дней").
const int minMetersPerFictionalDay = 10000;

/// Loads and parses `assets/journeys/{journeyId}/locations.json`'s segment
/// timing fields.
///
/// Returns `null` specifically when the journey ships no `locations.json`
/// at all — today, any journey other than `odyssey-ithaca` — so a caller
/// falls back to the real device clock. A `locations.json` that *is*
/// present but malformed still throws (a content bug to fix, not a
/// silent fallback) — mirroring `quest_map_repository.dart`'s
/// `loadQuestMap`.
Future<List<JourneySegmentTiming>?> tryLoadJourneySegmentTimings(
  AssetBundle bundle,
  String journeyId,
) async {
  final String source;
  try {
    source = await bundle.loadString(journeyTimingAssetPath(journeyId));
  } catch (error) {
    // Only the "does this journey even have a locations.json" question is
    // caught here — parsing happens outside this try block, so a malformed
    // file that *is* present still throws `FormatException` uncaught, per
    // this function's own contract. A missing asset surfaces as
    // `FlutterError` from `PlatformAssetBundle.load` in a real app and as
    // other `Exception`/`Error` shapes from a bundle standing in for one in
    // a test — caught broadly here for that reason, not to hide a real bug.
    if (error is FormatException) rethrow;
    return null;
  }
  return parseJourneySegmentTimings(source);
}

/// Parses `locations.json`'s `segments[]` timing fields into
/// [JourneySegmentTiming]s (§6.1).
///
/// Validates what [fictionalHourFor] relies on rather than trusting the
/// file: at least one segment, sorted and contiguous `fromMeters`/
/// `toMeters` (no gaps or overlaps, first segment starting at 0),
/// `departureHour` within `[0, 24)`, non-negative `durationDays`, and the
/// pace-safety cap `durationDays <= (toMeters - fromMeters) /
/// minMetersPerFictionalDay`. Content authored by hand is exactly the kind
/// that drifts, and an ungapped/unchecked route would either crash
/// `fictionalHourFor` on an unmapped position or let a short segment
/// flicker through several story-days on an ordinary walk.
List<JourneySegmentTiming> parseJourneySegmentTimings(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('locations.json must be a JSON object');
  }

  final rawSegments = decoded['segments'];
  if (rawSegments is! List || rawSegments.isEmpty) {
    throw const FormatException(
      'locations.json needs a non-empty "segments" list',
    );
  }

  final segments = <JourneySegmentTiming>[];
  for (final entry in rawSegments) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('every "segments" entry must be an object');
    }

    final id = _string(entry, 'id');
    final fromMeters = _int(entry, 'fromMeters');
    final toMeters = _int(entry, 'toMeters');
    if (toMeters < fromMeters) {
      throw FormatException('segment "$id" has toMeters < fromMeters');
    }

    if (segments.isNotEmpty && fromMeters != segments.last.toMeters) {
      throw FormatException(
        'segment "$id" must start ($fromMeters m) exactly where the '
        'previous segment ends (${segments.last.toMeters} m) — no gaps or '
        'overlaps',
      );
    }

    final departureHour = _double(entry, 'departureHour');
    if (departureHour < 0 || departureHour >= 24) {
      throw FormatException(
        'segment "$id" departureHour must be in [0, 24), got $departureHour',
      );
    }

    final durationDays = _double(entry, 'durationDays');
    if (durationDays < 0) {
      throw FormatException('segment "$id" durationDays must be >= 0');
    }
    final paceLimit = (toMeters - fromMeters) / minMetersPerFictionalDay;
    if (durationDays > paceLimit) {
      throw FormatException(
        'segment "$id" durationDays ($durationDays) exceeds the '
        'pace-safety cap ($paceLimit days for ${toMeters - fromMeters} m) '
        '— an ordinary walk through this segment would skip several '
        'in-fiction days at once',
      );
    }

    segments.add(
      JourneySegmentTiming(
        id: id,
        fromMeters: fromMeters,
        toMeters: toMeters,
        departureHour: departureHour,
        durationDays: durationDays,
      ),
    );
  }

  if (segments.first.fromMeters != 0) {
    throw const FormatException('the first segment must start at 0 m');
  }

  return segments;
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

double _double(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) throw FormatException('"$key" must be a number');
  return value.toDouble();
}
