import 'package:flutter/material.dart' show IconData, Icons;

import '../../../core/app_theme_id.dart';
import '../domain/achievement.dart';

/// A small icon illustrating what one achievement actually *is* (this
/// task's requirement — "на каждое достижение добавь небольшую иллюстрацию
/// в стиле выбранной темы") — shown next to its title, alongside (not
/// instead of) the big trophy glyph that already carries the locked/
/// unlocked state.
///
/// Only the journey catalog's `landmarkReached`/`distanceReached` entries
/// vary by [theme]: they're the ones actually tied to the Odyssey's own
/// lore (§1.1), so [AppThemeId.odyssey] gets per-landmark glyphs matching
/// `quest_map_view.dart`'s own icons for the same landmarks, and
/// [AppThemeId.classic] gets setting-neutral equivalents — a future
/// fantasy quest's achievements would want the neutral set, not Circe's
/// transformation icon. The daily catalog (`dailyAchievementCatalog`) is
/// plain activity metrics with no narrative behind it, so it gets one
/// universal set regardless of theme — inventing a theme distinction for
/// "10 km in a day" would be noise, not signal.
///
/// No source asset exists yet for a real illustration (§9.1 is still an
/// open decision) — an icon is the same cheap-to-replace placeholder
/// `quest_map_view.dart`'s landmarks and `challengers_tab.dart`'s empty
/// state already use.
IconData achievementIllustration(AchievementDef def, AppThemeId theme) {
  return _dailyIllustrations[def.id] ??
      (theme == AppThemeId.odyssey
          ? _odysseyIllustrations[def.id]
          : _classicIllustrations[def.id]) ??
      Icons.flag;
}

/// Distance-only milestones, ascending by grandeur — shared by both themes
/// (see the doc comment above).
const Map<String, IconData> _dailyIllustrations = {
  'daily-1km': Icons.directions_walk,
  'daily-5km': Icons.hiking,
  'daily-10km': Icons.directions_run,
  'daily-20km': Icons.sports_score,
  'daily-50km': Icons.military_tech,
};

/// Setting-neutral icons for the journey catalog — no Odyssey-specific
/// lore reference, so a future non-Odyssey quest's achievements read fine
/// under this same set (§14: the original fantasy world isn't named yet).
const Map<String, IconData> _classicIllustrations = {
  'first-steps': Icons.directions_walk,
  'first-league': Icons.hiking,
  'half-day-march': Icons.terrain,
  'century-mark': Icons.military_tech,
  'seasoned-wanderer': Icons.explore,
  'reached-circe': Icons.outlined_flag,
  'reached-lotus-eaters': Icons.tour,
  'halfway-there': Icons.flag_circle,
  'reached-calypso': Icons.location_on,
  'long-hauler': Icons.landscape,
  'passed-scylla-charybdis': Icons.route,
  'passed-sirens': Icons.flag,
  'journeys-end': Icons.emoji_events,
};

/// Odyssey-flavored icons — the `landmarkReached` entries reuse the exact
/// glyph `quest_map_view.dart` paints for that same landmark id (minus the
/// `reached-`/`passed-` prefix), so a trophy and its map marker never
/// disagree on what represents it.
const Map<String, IconData> _odysseyIllustrations = {
  'first-steps': Icons.directions_walk,
  'first-league': Icons.sailing,
  'half-day-march': Icons.rowing,
  'century-mark': Icons.anchor,
  'seasoned-wanderer': Icons.explore,
  'reached-circe': Icons.change_circle_outlined,
  'reached-lotus-eaters': Icons.spa,
  'halfway-there': Icons.waves,
  'reached-calypso': Icons.terrain,
  'long-hauler': Icons.sailing,
  'passed-scylla-charybdis': Icons.cyclone,
  'passed-sirens': Icons.music_note,
  'journeys-end': Icons.home,
};
