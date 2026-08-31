import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Named text styles for the whole app (CLAUDE.md §9).
///
/// Styling fix: the antiquarian serif set the right mood, but everywhere
/// read atmospheric to the point of hurting legibility for ordinary UI
/// text. The split is now: **serif** stays only for large screen/section
/// headings, the gold distance hero and its unit, and the italic narrative
/// line — the handful of places §9's referenced screenshots actually show
/// it large. Everything else — labels, body copy, descriptions, bottom-nav
/// captions — is a **modern sans-serif**, so the interface reads current
/// without losing the atmosphere where it matters.
///
/// The exact families are still an open decision (CLAUDE.md §14): both must
/// end up public-domain / OFL-licensed, verified before being embedded —
/// "looks old" is not a check. Until they're picked, every style below falls
/// back to its generic placeholder family, so nothing here needs to change
/// except the two `fontFamily` values once licensed fonts land.
abstract final class AppTypography {
  static const String _serifFontFamilyPlaceholder = 'serif';
  static const String _sansFontFamilyPlaceholder = 'sans-serif';

  /// The large gold distance number on the Путь tab (§5.4, §9). Serif —
  /// this is the number the whole screen is built around.
  static const TextStyle distanceHero = TextStyle(
    fontFamily: _serifFontFamilyPlaceholder,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    color: AppColors.gold,
    height: 1.0,
  );

  /// The small unit label under [distanceHero] ("kilometers"). Serif, to
  /// read as one unit with the number above it.
  static const TextStyle distanceUnit = TextStyle(
    fontFamily: _serifFontFamilyPlaceholder,
    fontSize: 16,
    color: AppColors.gold,
    letterSpacing: 0.5,
  );

  /// Screen / section headings ("Настройки", "Друзья", a quest's own
  /// title) — the "крупные заголовки" the styling fix keeps serif.
  static const TextStyle heading = TextStyle(
    fontFamily: _serifFontFamilyPlaceholder,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// "Day N" style counters, stat labels, small section-card captions —
  /// regular content, not a heading, so sans per the styling fix.
  static const TextStyle label = TextStyle(
    fontFamily: _sansFontFamilyPlaceholder,
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  /// Regular body text — sans per the styling fix ("обычный текст...
  /// современным sans-serif").
  static const TextStyle body = TextStyle(
    fontFamily: _sansFontFamilyPlaceholder,
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  /// Secondary / muted body text. Sans, same reasoning as [body].
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _sansFontFamilyPlaceholder,
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  /// A settings-style section header — small, uppercase, and a muted-gold
  /// tone rather than plain body text, so a section title reads as
  /// structure at a glance instead of blending into the paragraph under it
  /// (styling fix: "заголовки разделов... сделайте более заметными").
  /// Callers render the string through [String.toUpperCase] themselves —
  /// this style only sets the letter-spacing an all-caps label needs, not
  /// the transform, since the transform has to run on the localized string
  /// (§11), not live in a shared constant.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: _sansFontFamilyPlaceholder,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.goldMuted,
    letterSpacing: 1.2,
  );

  /// Narrative lines — serif italic (§9): this is atmosphere, not a UI
  /// label, so it stays exempt from the sans-serif switch above.
  static const TextStyle narrative = TextStyle(
    fontFamily: _serifFontFamilyPlaceholder,
    fontSize: 16,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );
}
