import '../../../core/app_theme_id.dart';
import '../domain/journey.dart';

/// The quest catalog (CLAUDE.md §8, §14): read-only for the client. In the
/// real app this is Firestore metadata (`journeys/{journeyId}`) cached on
/// device; Phase 8 wires that up. Until then this static list stands in for
/// it, with values cross-checked against each quest's own
/// `assets/journeys/{id}/locations.json`'s `journey` block so the numbers
/// match the real content draft.
///
/// Two quests as of §14's 2026-09-05 decision (superseding the earlier "on
/// MVP один квест («Одиссея»)" — the second, "The Road to the Skyfire", uses
/// [AppThemeId.classic] rather than a themed flavor of its own, same as
/// every future non-Odyssey quest until it gets one (§14).
const journeyCatalog = <Journey>[
  Journey(
    id: 'odyssey-ithaca',
    name: 'The Odyssey: Troy to Ithaca',
    pointA: 'Troy',
    pointB: 'Ithaca',
    totalMeters: 2850000,
    themeId: AppThemeId.odyssey,
  ),
  Journey(
    id: 'tower-of-lights',
    name: 'The Road to the Skyfire',
    pointA: 'The Bellglass Tower',
    pointB: 'The Lantern Fields',
    totalMeters: 240000,
    themeId: AppThemeId.classic,
  ),
];

/// Looks up a catalog entry by id, or `null` if it isn't in the catalog.
Journey? findJourney(String id) {
  for (final journey in journeyCatalog) {
    if (journey.id == id) return journey;
  }
  return null;
}
