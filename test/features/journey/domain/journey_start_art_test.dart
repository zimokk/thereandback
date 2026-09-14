import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/journey/domain/journey_start_art.dart';

void main() {
  test('odyssey-ithaca has its own start art — Troy', () {
    expect(
      startArtAssetPathFor('odyssey-ithaca'),
      'assets/journeys/odyssey-ithaca/start_art.webp',
    );
  });

  test('tower-of-lights has its own start art — the Bellglass Tower', () {
    expect(
      startArtAssetPathFor('tower-of-lights'),
      'assets/journeys/tower-of-lights/start_art.webp',
    );
  });

  test('a quest with no authored start art returns null', () {
    expect(startArtAssetPathFor('some-future-quest'), isNull);
  });
}
