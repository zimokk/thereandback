/// Whether a quest's downloadable content (its drawn map, and — once real
/// parallax art exists, §9.1 — its layer files, plus an optional
/// per-quest theme track) is present on this device (CLAUDE.md §14 — "не
/// увеличивать размер приложения при добавлении нового квеста").
///
/// A quest with no [JourneyAssetManifest] entry at all — every quest today,
/// since the Odyssey ships fully bundled in the app binary
/// (`journey_asset_catalog.dart`'s `journeyAssetManifests` is empty) —
/// never produces anything but [JourneyAssetReady]; this type only carries
/// meaningful state once a quest actually has something to download.
///
/// Plain Dart sealed classes, not `@freezed` (CLAUDE.md §4's domain rule —
/// no Flutter import — is satisfied either way, but this avoids adding a
/// fifth generated-file dependency to a feature that is otherwise
/// hand-verifiable without `build_runner`).
sealed class JourneyAssetStatus {
  const JourneyAssetStatus();
}

/// Nothing has been downloaded yet, and nothing is in flight. The catalog
/// card shows a "Download" affordance instead of "Start quest".
final class JourneyAssetNotDownloaded extends JourneyAssetStatus {
  const JourneyAssetNotDownloaded();
}

/// A download is in progress. [progress] is 0..1 across the manifest's
/// whole file list (map, parallax layers, optional theme track) — one
/// combined bar, weighted evenly per file (`journey_asset_repository.dart`
/// advances it file by file, not byte by byte — see that file's own doc
/// comment for why).
final class JourneyAssetDownloading extends JourneyAssetStatus {
  const JourneyAssetDownloading(this.progress);

  final double progress;
}

/// The locally cached version matches (or exceeds — never happens in
/// practice, but never blocks either) the catalog's current
/// [JourneyAssetManifest.assetsVersion] — everything the quest needs is on
/// disk and playable fully offline (§8). Also the status of every quest
/// with no manifest at all (bundled in the app binary — nothing to
/// download in the first place).
final class JourneyAssetReady extends JourneyAssetStatus {
  const JourneyAssetReady();
}

/// The last download attempt failed. [reason] is a short, already-safe-to-
/// show diagnostic string (never raw health data, coordinates or anything
/// identifying, §13) — `journey_asset_repository.dart` populates it from
/// the caught exception's `toString()`, the same "never a silent dead end"
/// bar §7 holds permission/network failures to elsewhere in this app.
final class JourneyAssetFailed extends JourneyAssetStatus {
  const JourneyAssetFailed(this.reason);

  final String reason;
}

/// One journey's downloadable content — deliberately separate from
/// `Journey` itself (`journey.dart`) rather than new fields on it, so a
/// quest with nothing to download (every quest today) carries no download
/// bookkeeping at all, and every existing call site that only cares about
/// `Journey` stays untouched by this feature.
///
/// In the real app this is Firestore metadata under `journeys/{journeyId}`
/// (§8), same status as `Journey`'s own catalog pending Phase 8's Firestore
/// hookup — `journey_asset_catalog.dart`'s static list stands in for it
/// until then.
typedef JourneyAssetManifest = ({
  String journeyId,

  /// Bumped in the catalog whenever this quest's downloadable content
  /// changes — a locally cached version below this number means "stale,
  /// redownload" ([journeyAssetNeedsDownload]).
  int assetsVersion,

  /// Firebase Storage object paths under `journeys/{journeyId}/` — the
  /// drawn map (`map.webp`, `map.json`) and, once real parallax art exists
  /// (§9.1), its layer files.
  List<String> objectPaths,

  /// Storage object path of this quest's own theme track, or `null` — a
  /// quest with no theme of its own keeps using the shared app-wide track
  /// (§6.5) instead of downloading one.
  String? themeTrackObjectPath,
});

/// Whether a journey's downloadable content needs (re)downloading: no local
/// record at all, or one behind the catalog's current
/// [JourneyAssetManifest.assetsVersion].
bool journeyAssetNeedsDownload({
  required int? downloadedVersion,
  required int catalogVersion,
}) => downloadedVersion == null || downloadedVersion < catalogVersion;
