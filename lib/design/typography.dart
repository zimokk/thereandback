import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Named text styles for the whole app (CLAUDE.md §9). One antiquarian serif
/// everywhere — headings, distances, narrative.
///
/// The exact font family is an open decision (CLAUDE.md §14): the final
/// choice must be public-domain / OFL-licensed, verified before it is
/// embedded — "looks old" is not a check. Until that's picked, every style
/// below falls back to the generic `serif` font family so nothing here needs
/// to change except the `fontFamily` value once a licensed font lands.
abstract final class AppTypography {
  static const String _fontFamilyPlaceholder = 'serif';

  /// The large gold distance number on the Путь tab (§5.4, §9).
  static const TextStyle distanceHero = TextStyle(
    fontFamily: _fontFamilyPlaceholder,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    color: AppColors.gold,
    height: 1.0,
  );

  /// The small unit label under [distanceHero] ("kilometers").
  static const TextStyle distanceUnit = TextStyle(
    fontFamily: _fontFamilyPlaceholder,
    fontSize: 16,
    color: AppColors.gold,
    letterSpacing: 0.5,
  );

  /// Screen / section headings.
  static const TextStyle heading = TextStyle(
    fontFamily: _fontFamilyPlaceholder,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// "Day N" style counters and stat labels.
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamilyPlaceholder,
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  /// Regular body text.
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamilyPlaceholder,
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  /// Secondary / muted body text.
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _fontFamilyPlaceholder,
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  /// Narrative lines — same serif, italic (§9).
  static const TextStyle narrative = TextStyle(
    fontFamily: _fontFamilyPlaceholder,
    fontSize: 16,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );
}
