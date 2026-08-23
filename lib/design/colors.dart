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
}
