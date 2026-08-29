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

  /// Cards, app bars, sheets.
  static const Color surface = Color(0xFF1B1B1E);

  /// Warm gold accent — numbers, active icons, primary buttons.
  static const Color gold = Color(0xFFE0AE3F);

  /// Muted white — primary text color.
  static const Color textPrimary = Color(0xFFEDE7DA);

  /// Secondary text — [textPrimary] at 60% opacity, per §9.
  static const Color textSecondary = Color(0x99EDE7DA);

  /// Divider / hairline color, low-contrast against [background].
  static const Color divider = Color(0x33EDE7DA);

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
