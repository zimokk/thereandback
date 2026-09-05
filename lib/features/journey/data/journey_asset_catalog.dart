import '../domain/journey_asset_status.dart';

/// Downloadable-content manifests, parallel to `journey_catalog.dart`'s
/// `journeyCatalog` (CLAUDE.md §8, §14). **Empty today** — both catalog
/// entries (the Odyssey and, since 2026-09-05, "The Road to the Skyfire",
/// §14) ship fully bundled in the app binary and have no manifest here —
/// but wired end to end so the next quest only needs an entry in this list,
/// never a change to the download machinery itself
/// (`journey_asset_repository.dart`, `journey_asset_providers.dart`,
/// `quest_picker_view.dart`'s download UI).
///
/// In the real app this list is Firestore metadata under `journeys/
/// {journeyId}` (§8), same status as `journeyCatalog` itself pending Phase
/// 8's Firestore hookup — a static list stands in for it until then.
///
/// A future entry looks like:
/// ```dart
/// (
///   journeyId: 'some-new-quest',
///   assetsVersion: 1,
///   objectPaths: [
///     'journeys/some-new-quest/map.webp',
///     'journeys/some-new-quest/map.json',
///   ],
///   themeTrackObjectPath: 'journeys/some-new-quest/theme.wav',
/// ),
/// ```
const journeyAssetManifests = <JourneyAssetManifest>[];

/// Looks up a manifest by journey id, or `null` if that journey has nothing
/// downloadable — either it isn't in the catalog at all, or (every quest
/// today) it ships fully bundled in the app binary.
JourneyAssetManifest? findJourneyAssetManifest(String journeyId) {
  for (final manifest in journeyAssetManifests) {
    if (manifest.journeyId == journeyId) return manifest;
  }
  return null;
}
