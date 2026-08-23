# Screen: Трофеи (Achievements)

Bottom tab 3 of 4 in this base (CLAUDE.md §6.3). Route:
**`/achievements`**. Entry widget: `AchievementsTab`
(`lib/features/achievements/presentation/achievements_tab.dart`).

## What it shows

A two-column grid, one tile per entry in `achievementCatalog`
(`data/achievement_catalog.dart`), each evaluated against the current
quest's `progressMeters` (`0` if no quest is selected — the grid still
renders, fully locked, rather than being empty/blank).

- **Unlocked**: gold border + gold trophy icon + `achievementUnlockedLabel`
  ("Unlocked" / "Получено").
- **Locked**: muted icon + `achievementRemainingLabel` — e.g. "620 meters
  left" / "осталось 620 метров". Word order is locale-specific text in the
  ARB file, not string concatenation (§11) — English puts the amount
  first, Russian puts "осталось" first.

## Data-driven, per §6.3 — adding a trophy means editing the catalog

`evaluateAchievements` (`domain/achievement.dart`) is the **one** evaluator
for the whole catalog — there is no per-achievement `if` in the widget.
Today's catalog (`data/achievement_catalog.dart`) has four sample,
distance-threshold entries against the Odyssey's 2 850 000 m length:

| id | threshold | l10n title key |
|---|---|---|
| `first-steps` | 1 000 m | `achievementFirstStepsTitle` |
| `half-day-march` | 50 000 m | `achievementHalfDayMarchTitle` |
| `seasoned-wanderer` | 500 000 m | `achievementSeasonedWandererTitle` |
| `journeys-end` | 2 850 000 m | `achievementJourneysEndTitle` |

`AchievementKind` has one case (`distanceReached`) today; streaks,
landmarks-reached and overtaking-a-friend conditions (§6.3) are future
`AchievementKind` cases the evaluator's `switch` grows to cover — adding
one still never touches a widget.

### Known contract wrinkle: title lookup

`AchievementDef.titleKey` is a `String` naming an `AppLocalizations`
getter; `_AchievementTile._title()` is a hand-written `switch` mapping that
string back to the actual localized getter (Dart has no reflection to do
this generically). **Adding a catalog entry means adding both an ARB key
and a case in that switch** — the switch's `default` falls back to
rendering the raw key so a forgotten case is visible instead of silently
blank, but it should still be treated as a bug to fix, not a feature.

## State

Reads `selectedJourneyProvider` (`journey_providers.dart`, see
[`journey.md`](journey.md)) for `progressMeters`. Owns no provider itself.

## l10n keys

`achievementFirstStepsTitle`, `achievementHalfDayMarchTitle`,
`achievementSeasonedWandererTitle`, `achievementJourneysEndTitle`,
`achievementUnlockedLabel`, `achievementRemainingLabel` (`{amount}`).

## Tests

`test/features/achievements/domain/achievement_evaluator_test.dart`:
locked-below-threshold with correct remaining meters, unlock-on-crossing,
full-catalog-unlocked, empty-catalog edge case.

`test/features/achievements/presentation/achievements_tab_test.dart`:
whole catalog renders locked with no quest selected; crossing a threshold
flips exactly that tile to unlocked.
