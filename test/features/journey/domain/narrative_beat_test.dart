import 'package:test/test.dart';
import 'package:thereandback/features/journey/domain/narrative_beat.dart';

void main() {
  group('narrativeBeatFor', () {
    test('returns null for an empty beat list', () {
      expect(narrativeBeatFor(const [], 5000), isNull);
    });

    test('returns null before the very first beat — nothing reached yet', () {
      final beats = [const NarrativeBeat(meters: 1000, text: 'first')];
      expect(narrativeBeatFor(beats, 0), isNull);
      expect(narrativeBeatFor(beats, 999), isNull);
    });

    test('returns the most recent beat at or before the position', () {
      final beats = [
        const NarrativeBeat(meters: 0, text: 'start'),
        const NarrativeBeat(meters: 1000, text: 'middle'),
        const NarrativeBeat(meters: 2000, text: 'end'),
      ];

      expect(narrativeBeatFor(beats, 0)?.text, 'start');
      expect(narrativeBeatFor(beats, 500)?.text, 'start');
      expect(narrativeBeatFor(beats, 1000)?.text, 'middle');
      expect(narrativeBeatFor(beats, 1999)?.text, 'middle');
      expect(narrativeBeatFor(beats, 2000)?.text, 'end');
      expect(narrativeBeatFor(beats, 5000)?.text, 'end'); // clamps forward.
    });
  });
}
