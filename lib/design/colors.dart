import 'package:flutter/widgets.dart';

/// Semantic color tokens for the dark/gold antiquarian theme (CLAUDE.md §9).
///
/// Dark theme is the only theme — there is no light variant to branch on.
/// Feature widgets must reference these tokens, never a literal `Color(0x…)`.
abstract final class AppColors {
  /// Near-black background, the darkest layer of the app.
  static const Color background = Color(0xFF000000);

  /// Slightly lighter background, used for large surfaces that need to be
  /// distinguished from [background] without a hard edge.
  static const Color backgroundElevated = Color(0xFF0B0B0D);

  /// Cards, app bars, sheets — the middle rung of the
  /// [background] → [surface] → [surfaceActive] ladder (styling fix: closer
  /// to black than the previous `#1B1B1E`, so a card reads as a distinct
  /// surface rather than a plain grey rectangle).
  static const Color surface = Color(0xFF141416);

  /// The active/selected element — one rung above [surface] (a highlighted
  /// row, the pill behind the active bottom-nav icon). Never used as a base
  /// card color; only for the one element on a card that's currently active.
  static const Color surfaceActive = Color(0xFF232227);

  /// Thin hairline border for cards (styling fix: a flat color fill alone
  /// read as generic Material design) — a faint warm gold/bronze tint
  /// rather than solid [gold], so every card gets *some* edge definition
  /// without gold turning into visual noise (§9 "не использовать золото
  /// слишком часто").
  static const Color cardBorder = Color(0x26E0AE3F);

  /// Warm gold accent — numbers, active icons, primary buttons. The
  /// *primary* rung of the two-step gold scale (§9 styling fix); see
  /// [goldMuted] for the secondary one.
  static const Color gold = Color(0xFFE0AE3F);

  /// Muted, less saturated gold — secondary/decorative accents (a utility
  /// icon, a hairline) that shouldn't compete with [gold]'s primary actions
  /// and active states for attention.
  static const Color goldMuted = Color(0xFFA6884C);

  /// Muted white — primary text color.
  static const Color textPrimary = Color(0xFFEDE7DA);

  /// Secondary text — [textPrimary] at 60% opacity, per §9.
  static const Color textSecondary = Color(0x99EDE7DA);

  /// Divider / hairline color, low-contrast against [background].
  static const Color divider = Color(0x33EDE7DA);

  /// Warm, near-black bronze/brown backdrop for the Путь tab's scene only
  /// (§6.1, §9 styling fix) — a flat [background] "killed the atmosphere"
  /// there. Every other screen keeps the neutral [background]/
  /// [backgroundElevated] pair; this is deliberately scoped to
  /// `AppSceneBackdrop` (`design/components/app_scene_backdrop.dart`), not a
  /// replacement for [background] app-wide.
  static const Color journeySceneBackground = Color(0xFF12100E);

  /// Monochrome "engraved ink" tone for landmark markers on the drawn quest
  /// map (§6.2 styling fix) — replaces per-landmark colour emoji, which read
  /// as out of place against the map's ink/parchment illustration style.
  static const Color mapLandmarkInk = Color(0xFFC9C2B3);

  /// Fixed palette for friend pins on the map and in the Challengers table
  /// (§6.2, §6.4) — deliberately distinct from [gold], which stays reserved
  /// for the player's own position/accents. Indexed by
  /// `features/friends/domain/friendship.dart`'s `pinColorIndexForUid`
  /// (`friendPinPaletteSize` there must match this list's length).
  static const List<Color> friendPinPalette = [
    Color(0xFFE05C4F), // terracotta red
    Color(0xFF4FA8E0), // sky blue
    Color(0xFF6FCF97), // sage green
    Color(0xFFBB86FC), // lavender
    Color(0xFFE0954F), // amber orange
    Color(0xFF4FE0CB), // teal
    Color(0xFFE04F9E), // rose pink
    Color(0xFFA0A0E0), // periwinkle
  ];
}
