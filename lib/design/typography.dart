import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Named text styles for the whole app (CLAUDE.md §9).
///
/// **One font family for every style below** — §9's own words: "Один шрифт
/// на всё приложение." A past, undocumented "styling fix" split this into a
/// serif family for headings/numbers/narrative and a second sans-serif
/// family for everything else, reasoning that an all-serif UI hurt
/// legibility for ordinary body text. That reasoning may well resurface once
/// a real family is picked (Phase 1, CLAUDE.md §14) — a genuinely illegible
/// body face is a real problem — but it was never written back into
/// CLAUDE.md as the governing decision, so the code quietly drifted from its
/// own spec. Reverted here so code and CLAUDE.md agree again; see
/// `.claude/skills/typography-style-guide/` before reintroducing a second
/// family, so the next change updates both places together.
///
/// The exact family is still an open decision (CLAUDE.md §14): it must end
/// up public-domain / OFL-licensed, verified before being embedded — "looks
/// old" is not a check. Until it's picked, every style below falls back to
/// [fontFamilyPlaceholder]'s generic family, so nothing here needs to change
/// except that one value once a licensed font lands.
abstract final class AppTypography {
  /// The one font family every style below applies, and the same value
  /// `app/theme.dart`'s `ThemeData.fontFamily` reads — one shared constant
  /// rather than two independent literals that can drift apart the way this
  /// file's old serif/sans split once did.
  static const String fontFamilyPlaceholder = 'serif';

  /// The large gold distance number on the Путь tab (§5.4, §9) — the number
  /// the whole screen is built around.
  static const TextStyle distanceHero = TextStyle(
    fontFamily: fontFamilyPlaceholder,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    color: AppColors.gold,
    height: 1.0,
  );

  /// The small unit label under [distanceHero] ("kilometers") — reads as one
  /// unit with the number above it.
  static const TextStyle distanceUnit = TextStyle(
    fontFamily: fontFamilyPlaceholder,
    fontSize: 16,
    color: AppColors.gold,
    letterSpacing: 0.5,
  );

  /// Screen / section headings ("Настройки", "Друзья", a quest's own title).
  static const TextStyle heading = TextStyle(
    fontFamily: fontFamilyPlaceholder,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// "Day N" style counters, stat labels, small section-card captions —
  /// regular content, not a heading.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamilyPlaceholder,
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  /// Regular body text.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamilyPlaceholder,
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  /// Secondary / muted body text.
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamilyPlaceholder,
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
    fontFamily: fontFamilyPlaceholder,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.goldMuted,
    letterSpacing: 1.2,
  );

  /// Narrative lines — italic (§9): atmosphere, not a UI label, but still
  /// the one shared family, only slanted.
  static const TextStyle narrative = TextStyle(
    fontFamily: fontFamilyPlaceholder,
    fontSize: 16,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );
}
