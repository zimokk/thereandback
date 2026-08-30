import '../../../core/app_theme_id.dart';
import '../domain/journey.dart';

/// The quest catalog (CLAUDE.md §8, §14): read-only for the client. In the
/// real app this is Firestore metadata (`journeys/{journeyId}`) cached on
/// device; Phase 8 wires that up. Until then this static list stands in for
/// it, with values cross-checked against
/// `assets/journeys/odyssey-ithaca/locations.json`'s `journey` block so the
/// numbers match the real content draft.
///
/// One quest today, per §14 ("на MVP один квест («Одиссея»)").
const journeyCatalog = <Journey>[
  Journey(
    id: 'odyssey-ithaca',
    name: 'The Odyssey: Troy to Ithaca',
    pointA: 'Troy',
    pointB: 'Ithaca',
    totalMeters: 2850000,
    themeId: AppThemeId.odyssey,
  ),
];

/// Looks up a catalog entry by id, or `null` if it isn't in the catalog.
Journey? findJourney(String id) {
  for (final journey in journeyCatalog) {
    if (journey.id == id) return journey;
  }
  return null;
}
