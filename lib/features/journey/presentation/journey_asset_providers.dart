import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/journey_asset_repository_provider.dart';
import '../data/journey_asset_catalog.dart';
import '../domain/journey_asset_status.dart';

part 'journey_asset_providers.g.dart';

/// The downloadable-content manifest catalog (§8, §14) — mirrors
/// `journey_providers.dart`'s `journeyCatalogEntriesProvider`. Empty today
/// (`journeyAssetManifests` is empty, §14), overridable in widget tests the
/// same way.
@riverpod
List<JourneyAssetManifest> journeyAssetManifestEntries(Ref ref) =>
    journeyAssetManifests;

/// Whether [journeyId] has a manifest at all — `null` means it ships fully
/// bundled in the app binary (every quest today) and has nothing
/// downloadable; `quest_picker_view.dart` uses this to decide whether to
/// show a "Start quest"/"Download" branch at all.
@riverpod
JourneyAssetManifest? journeyAssetManifestFor(Ref ref, String journeyId) {
  for (final manifest in ref.watch(journeyAssetManifestEntriesProvider)) {
    if (manifest.journeyId == journeyId) return manifest;
  }
  return null;
}

/// Per-journey download state (§8, §14) — the presentation-facing
/// counterpart of `JourneyAssetRepository`. [build] follows the same
/// "sync default now, async correction shortly after" idiom
/// `SelectedJourney.build()`/`BackgroundMusicController.build()` already
/// use: a bundled quest (no manifest) resolves synchronously to
/// [JourneyAssetReady] with no async work at all, so it never flashes a
/// wrong status; a quest with a manifest starts at
/// [JourneyAssetNotDownloaded] and is corrected the moment the drift lookup
/// resolves.
@riverpod
class JourneyAssetStatusController extends _$JourneyAssetStatusController {
  @override
  JourneyAssetStatus build(String journeyId) {
    if (ref.watch(journeyAssetManifestForProvider(journeyId)) == null) {
      return const JourneyAssetReady(); // bundled, nothing to check
    }
    unawaited(_restore());
    return const JourneyAssetNotDownloaded();
  }

  Future<void> _restore() async {
    final status = await ref
        .read(journeyAssetRepositoryProvider)
        .statusFor(journeyId);
    state = status;
  }

  /// Starts (or retries, from [JourneyAssetFailed]) the download. A no-op
  /// while already [JourneyAssetDownloading] — the catalog card's button is
  /// hidden in that state, but a double-tap racing the rebuild must not
  /// start two overlapping downloads of the same quest.
  Future<void> download() async {
    if (state is JourneyAssetDownloading) return;

    state = const JourneyAssetDownloading(0);
    try {
      await ref
          .read(journeyAssetRepositoryProvider)
          .download(
            journeyId,
            onProgress: (progress) {
              state = JourneyAssetDownloading(progress);
            },
          );
      state = const JourneyAssetReady();
    } catch (error) {
      state = JourneyAssetFailed(error.toString());
    }
  }
}
