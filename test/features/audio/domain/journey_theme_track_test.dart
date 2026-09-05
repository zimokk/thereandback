import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/features/audio/domain/journey_theme_track.dart';

void main() {
  test('tower-of-lights has its own track', () {
    expect(
      journeyThemeTrackAssetPath('tower-of-lights'),
      'journeys/tower-of-lights/theme.mp3',
    );
  });

  test('a quest with no authored track returns null', () {
    expect(journeyThemeTrackAssetPath('odyssey-ithaca'), isNull);
    expect(journeyThemeTrackAssetPath('some-future-quest'), isNull);
  });

  test('no selected quest (null id) returns null', () {
    expect(journeyThemeTrackAssetPath(null), isNull);
  });
}
