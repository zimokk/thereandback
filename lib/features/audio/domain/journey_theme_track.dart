/// Per-quest override for the app's one background track (§6.5, §14
/// "background music"). A plain `Map`, not a field on `Journey`, mirrors
/// `route_scale.dart`'s `metersPerScreenWidthFor`: no `build_runner` pass
/// needed to give a quest its own track, and a quest that authors none
/// stays exactly as before.
///
/// Paths are relative to `AudioCache`'s default `assets/` prefix (the same
/// convention `BackgroundMusicPlayer._defaultTrackAssetPath` already
/// uses), pointing into that quest's own asset directory (§4) — a
/// quest-specific track is quest content, unlike the shared placeholder in
/// `assets/media/` (see `assets/media/README.md`).
const Map<String, String> _journeyThemeTrackAssetPaths = {
  'tower-of-lights': 'journeys/tower-of-lights/theme.mp3',
};

/// The background-music asset path for [journeyId], or `null` when that
/// quest authors no track of its own (today: any quest other than
/// `tower-of-lights`, `journeyId == null` included) — the caller falls
/// back to the shared app-wide track.
String? journeyThemeTrackAssetPath(String? journeyId) =>
    journeyId == null ? null : _journeyThemeTrackAssetPaths[journeyId];
