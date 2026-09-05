import '../../friends/domain/friend_progress.dart';
import '../domain/route_scale.dart';
import '../domain/scene_prop_anchor.dart';
import '../domain/terrain_profile.dart';

/// Mutable scene state, read by [JourneyScene]'s components every `update()`
/// tick — the seam between Riverpod and the long-lived `FlameGame` instance
/// (CLAUDE.md §6.1/§12: "Flame `Game` instance is long-lived; do not rebuild
/// it on every provider change. State flows in via Riverpod → a scene
/// controller, not by recreating components.").
///
/// Plain Dart, no Riverpod/Flutter/Flame import on its own — the same
/// framework-agnostic seam `BackgroundMusicController`
/// (`features/audio/presentation/background_music_provider.dart`) already
/// uses between a Riverpod listener and a plain player object.
/// `journey_flame_scene_view.dart` is the only place that writes to this;
/// every Flame component only ever reads it.
class JourneySceneController {
  /// The active journey's id — looks up this quest's own
  /// [metersPerScreenWidthFor] scale rather than a single app-wide constant
  /// (§6.1: the scale is per-quest config).
  String journeyId = '';

  /// The route's full length in meters — nothing is drawn past this (point
  /// B) or before `0` (point A).
  int totalMeters = 0;

  /// The traveler's real, current position, in meters — the forward bound a
  /// rewind can never cross (there is nothing to look at past it yet, §6.1).
  int progressMeters = 0;

  /// The traveler's *displayed* position — may lag [progressMeters] while
  /// catching up (CLAUDE.md §6.1: new steps interpolate over ~800–1200 ms,
  /// `journey_flame_scene_view.dart`'s `_startTravelerCatchUp`). Every
  /// world-space consumer (the solid marker, the rewind ghost's "at You?"
  /// check) reads this, not [progressMeters] directly — that field is the
  /// animation's *target*, this one is what's actually drawn.
  double displayedProgressMeters = 0;

  /// The route position, in meters, currently centered on screen —
  /// ephemeral view state, not progress (mirrors the CustomPaint
  /// placeholder's `_panMeters`; see `journey_flame_scene_view.dart`'s own
  /// doc comment for why this is written on every drag/animation tick, not
  /// just once per Riverpod rebuild).
  double panMeters = 0;

  /// The `GameWidget`'s current logical-pixel size, kept in sync by
  /// [JourneyScene.onGameResize] — the one source of truth
  /// [pixelsPerMeter] and every Flutter-side overlay share, instead of a
  /// second, independently-computed `LayoutBuilder` size that could drift
  /// from what the Flame canvas actually measured.
  double sceneWidth = 0;
  double sceneHeight = 0;

  /// Accepted friends currently visible on this scene (§6.5's "Друзья на
  /// карте" preference, off by default) — already filtered to
  /// `!row.isSelf` by the caller (`journey_flame_scene_view.dart`), so this
  /// list is exactly what should be drawn, nothing more.
  List<FriendProgressRow> friendRows = const [];

  /// Mirrors `showFriendsOnMapProvider` (§6.5, off by default) — gates
  /// whether [friendRows] is drawn at all, so [JourneyScene] doesn't have
  /// to infer "off" from an empty list (which would be indistinguishable
  /// from "on, but the user simply has no accepted friends yet").
  bool showFriends = false;

  /// The active quest's authored terrain profile (§6.1, §9.1) — `null`
  /// before a quest is picked, or when it ships no `locations.json` terrain
  /// content at all (today: any quest other than `odyssey-ithaca`, and even
  /// that one until content actually authors a `terrainHeight`).
  /// `terrain_layer.dart`'s `terrainHeightAt` falls back to its placeholder
  /// sine wave exactly in that case, so a quest with no authored profile
  /// renders unchanged from before this field existed.
  TerrainProfile? terrainProfile;

  /// Named background props anchored to a specific route position (§6.1 —
  /// e.g. a cyclops silhouette at its own landmark's meters), as opposed to
  /// [EnvironmentLayer]'s own procedural, randomly-scattered decorations.
  /// Empty exactly when [terrainProfile] is `null` or the quest authors no
  /// `prop` fields — `EnvironmentLayer` draws nothing extra in that case.
  List<ScenePropAnchor> sceneProps = const [];

  /// Whether the scene should currently be running its game loop — driven
  /// by tab visibility and app lifecycle (`lib/app/active_tab_index.dart`),
  /// not by anything Flame-internal. [JourneyScene] mirrors this onto its
  /// own `paused` field; this field is the input, not the effect.
  bool active = true;

  /// Pixels-per-meter at the current [sceneWidth], for [journeyId]'s fixed
  /// per-quest scale (`route_scale.dart`) — `0` before the first
  /// [JourneyScene.onGameResize] call (nothing to draw yet).
  double get pixelsPerMeter =>
      sceneWidth <= 0 ? 0 : sceneWidth / metersPerScreenWidthFor(journeyId);
}
