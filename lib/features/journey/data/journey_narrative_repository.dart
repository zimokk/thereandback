import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/narrative_beat.dart';
import 'journey_timing_repository.dart' show journeyTimingAssetPath;

/// Path of a quest's translated `landmarks[].narrative`/`name` overlay
/// (§11, the same file `assets/journeys/tower-of-lights/README.md`
/// describes for `locations.ru.json`) — `null` for the app's default
/// language (`en`), which reads straight off `locations.json` itself, so
/// there is never a self-referential "translate English to English" load.
String? journeyNarrativeTranslationAssetPath(
  String journeyId,
  String languageCode,
) {
  if (languageCode == 'en') return null;
  return 'assets/journeys/$journeyId/locations.$languageCode.json';
}

/// Loads [journeyId]'s narrative beats (§5's `NarrativeBeat`) for the given
/// [languageCode], applying a translation overlay when one is bundled.
///
/// Returns `null` specifically when the journey ships no `locations.json`
/// at all — same convention as `journey_timing_repository.dart`'s
/// `tryLoadJourneySegmentTimings` — so a caller falls back to its own
/// placeholder narrative. A `locations.json` that *is* present but
/// malformed still throws.
Future<List<NarrativeBeat>?> tryLoadJourneyNarrativeBeats(
  AssetBundle bundle,
  String journeyId,
  String languageCode,
) async {
  final String source;
  try {
    source = await bundle.loadString(journeyTimingAssetPath(journeyId));
  } catch (error) {
    if (error is FormatException) rethrow;
    return null;
  }

  String? translationSource;
  final translationPath = journeyNarrativeTranslationAssetPath(
    journeyId,
    languageCode,
  );
  if (translationPath != null) {
    try {
      translationSource = await bundle.loadString(translationPath);
    } catch (_) {
      // No translation shipped for this journey/language yet (today: every
      // language other than `ru` on `tower-of-lights`, and `ru` itself on
      // `odyssey-ithaca` — CLAUDE.md §14's still-open "translate the
      // Odyssey narrative" item) — fall back to the base-file text rather
      // than treating a missing overlay as a content bug.
      translationSource = null;
    }
  }

  return parseJourneyNarrativeBeats(
    source,
    translationSource: translationSource,
  );
}

/// Parses `locations.json`'s `landmarks[]` into [NarrativeBeat]s, sorted by
/// position, optionally overlaying [translationSource]'s own
/// `landmarks[].narrative` by matching `id` (§11 — `locations.ru.json`'s
/// documented shape: a partial file keyed by the same ids, not a full
/// duplicate).
///
/// Validates the same way `journey_timing_repository.dart`'s
/// `parseJourneySegmentTimings` does: a missing/empty `narrative` on a
/// landmark that exists is a content bug to fix, not a silent fallback.
List<NarrativeBeat> parseJourneyNarrativeBeats(
  String source, {
  String? translationSource,
}) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('locations.json must be a JSON object');
  }

  final rawLandmarks = decoded['landmarks'];
  if (rawLandmarks is! List || rawLandmarks.isEmpty) {
    throw const FormatException(
      'locations.json needs a non-empty "landmarks" list',
    );
  }

  final translatedNarratives = translationSource == null
      ? const <String, String>{}
      : _translatedNarratives(translationSource);

  final beats = <NarrativeBeat>[];
  for (final entry in rawLandmarks) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('every "landmarks" entry must be an object');
    }
    final id = _string(entry, 'id');
    final meters = _int(entry, 'meters');
    final narrative = translatedNarratives[id] ?? _string(entry, 'narrative');
    beats.add(NarrativeBeat(meters: meters, text: narrative));
  }

  beats.sort((a, b) => a.meters.compareTo(b.meters));
  return beats;
}

Map<String, String> _translatedNarratives(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('locations.<lang>.json must be a JSON object');
  }
  final rawLandmarks = decoded['landmarks'];
  if (rawLandmarks is! List) {
    throw const FormatException(
      'locations.<lang>.json needs a "landmarks" list',
    );
  }

  final narratives = <String, String>{};
  for (final entry in rawLandmarks) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException(
        'every "landmarks" entry in locations.<lang>.json must be an object',
      );
    }
    final id = _string(entry, 'id');
    final narrative = entry['narrative'];
    // A translated landmark may carry only a translated `name` and no
    // `narrative` override — the base file's own text is used for that one
    // (same partial-overlay contract §11 documents), so this key is
    // optional rather than required like the base file's own field.
    if (narrative is String && narrative.isNotEmpty) {
      narratives[id] = narrative;
    }
  }
  return narratives;
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
