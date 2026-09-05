import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:thereandback/features/journey/data/journey_narrative_repository.dart';
import 'package:thereandback/features/journey/data/journey_timing_repository.dart';
import 'package:thereandback/features/journey/domain/narrative_beat.dart';

String _json(List<Map<String, Object?>> landmarks) {
  return jsonEncode({'landmarks': landmarks});
}

Map<String, Object?> _landmark({
  required String id,
  required int meters,
  String narrative = 'default narrative',
}) {
  return {'id': id, 'meters': meters, 'narrative': narrative};
}

void main() {
  group('journeyNarrativeTranslationAssetPath', () {
    test('is null for the default language (en) — reads locations.json '
        'itself, never a self-translation', () {
      expect(
        journeyNarrativeTranslationAssetPath('odyssey-ithaca', 'en'),
        isNull,
      );
    });

    test('names the per-language overlay file for any other language', () {
      expect(
        journeyNarrativeTranslationAssetPath('tower-of-lights', 'ru'),
        'assets/journeys/tower-of-lights/locations.ru.json',
      );
    });
  });

  group('parseJourneyNarrativeBeats', () {
    test('parses landmarks into beats sorted by position', () {
      final beats = parseJourneyNarrativeBeats(
        _json([
          _landmark(id: 'b', meters: 2000, narrative: 'second'),
          _landmark(id: 'a', meters: 1000, narrative: 'first'),
        ]),
      );

      expect(beats, hasLength(2));
      expect(beats[0].meters, 1000);
      expect(beats[0].text, 'first');
      expect(beats[1].meters, 2000);
      expect(beats[1].text, 'second');
    });

    test('rejects an empty "landmarks" list', () {
      expect(
        () => parseJourneyNarrativeBeats(_json([])),
        throwsFormatException,
      );
    });

    test('rejects a landmark with an empty narrative', () {
      expect(
        () => parseJourneyNarrativeBeats(
          _json([_landmark(id: 'a', meters: 0, narrative: '')]),
        ),
        throwsFormatException,
      );
    });

    test(
      'overlays a translation\'s narrative by id, keeping the base text for '
      'ids the translation does not cover (§11 — a partial overlay file)',
      () {
        final translation = jsonEncode({
          'landmarks': [
            {'id': 'a', 'narrative': 'translated first'},
          ],
        });

        final beats = parseJourneyNarrativeBeats(
          _json([
            _landmark(id: 'a', meters: 0, narrative: 'first'),
            _landmark(id: 'b', meters: 1000, narrative: 'second'),
          ]),
          translationSource: translation,
        );

        expect(beats[0].text, 'translated first');
        expect(beats[1].text, 'second'); // no translation entry -> base text.
      },
    );

    test('rejects a malformed translation overlay', () {
      expect(
        () => parseJourneyNarrativeBeats(
          _json([_landmark(id: 'a', meters: 0)]),
          translationSource: jsonEncode({'landmarks': 'not a list'}),
        ),
        throwsFormatException,
      );
    });
  });

  group('the shipped Odyssey locations.json', () {
    late List<NarrativeBeat> beats;

    setUpAll(() {
      beats = parseJourneyNarrativeBeats(
        File(journeyTimingAssetPath('odyssey-ithaca')).readAsStringSync(),
      );
    });

    test('carries a narrative beat for all 120 landmarks', () {
      expect(beats, hasLength(120));
      for (final beat in beats) {
        expect(beat.text, isNotEmpty);
      }
    });

    test('the first beat is the smoking walls of Troy', () {
      expect(beats.first.meters, 11875);
      expect(
        beats.first.text,
        'Smoke still curls above the broken towers as the ships push off.',
      );
    });

    test('is sorted by position along the route', () {
      for (var i = 1; i < beats.length; i++) {
        expect(beats[i].meters, greaterThanOrEqualTo(beats[i - 1].meters));
      }
    });
  });

  group('the shipped Tower of Lights locations.json', () {
    late List<NarrativeBeat> enBeats;
    late List<NarrativeBeat> ruBeats;

    setUpAll(() {
      final source = File(journeyTimingAssetPath('tower-of-lights'))
          .readAsStringSync();
      enBeats = parseJourneyNarrativeBeats(source);
      final translationPath = journeyNarrativeTranslationAssetPath(
        'tower-of-lights',
        'ru',
      )!;
      ruBeats = parseJourneyNarrativeBeats(
        source,
        translationSource: File(translationPath).readAsStringSync(),
      );
    });

    test(
      'carries a narrative beat for all 56 landmarks, in both languages',
      () {
        expect(enBeats, hasLength(56));
        expect(ruBeats, hasLength(56));
        for (final beat in [...enBeats, ...ruBeats]) {
          expect(beat.text, isNotEmpty);
        }
      },
    );

    test('the first beat is the Bellglass Window, in each language', () {
      expect(enBeats.first.meters, 0);
      expect(
        enBeats.first.text,
        'For the first time, I can see the whole valley without bars '
        'between us.',
      );
      expect(ruBeats.first.meters, 0);
      expect(
        ruBeats.first.text,
        'Впервые я вижу всю долину без решёток между нами.',
      );
    });
  });
}
