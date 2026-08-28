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
Today's catalog (`data/achievement_catalog.dart`) has thirteen entries
against the Odyssey's 2 850 000 m length, in ascending threshold order:

| id | threshold | kind | l10n title key |
|---|---|---|---|
| `first-steps` | 1 000 m | `distanceReached` | `achievementFirstStepsTitle` |
| `first-league` | 10 000 m | `distanceReached` | `achievementFirstLeagueTitle` |
| `half-day-march` | 50 000 m | `distanceReached` | `achievementHalfDayMarchTitle` |
| `century-mark` | 100 000 m | `distanceReached` | `achievementCenturyMarkTitle` |
| `seasoned-wanderer` | 500 000 m | `distanceReached` | `achievementSeasonedWandererTitle` |
| `reached-circe` | 561 921 m | `landmarkReached` | `achievementReachedCirceTitle` |
| `reached-lotus-eaters` | 1 215 166 m | `landmarkReached` | `achievementReachedLotusEatersTitle` |
| `halfway-there` | 1 425 000 m | `distanceReached` | `achievementHalfwayThereTitle` |
| `reached-calypso` | 1 804 508 m | `landmarkReached` | `achievementReachedCalypsoTitle` |
| `long-hauler` | 2 000 000 m | `distanceReached` | `achievementLongHaulerTitle` |
| `passed-scylla-charybdis` | 2 011 461 m | `landmarkReached` | `achievementPassedScyllaCharybdisTitle` |
| `passed-sirens` | 2 465 426 m | `landmarkReached` | `achievementPassedSirensTitle` |
| `journeys-end` | 2 850 000 m | `distanceReached` | `achievementJourneysEndTitle` |

`AchievementKind` has two cases: `distanceReached` for a plain milestone,
and `landmarkReached` for a threshold that's actually a specific landmark's
meters from `assets/journeys/odyssey-ithaca/map.json` — same unlock rule
(`progressMeters >= thresholdMeters`), evaluated in the same `switch` arm,
kept as its own case purely so the catalog records *why* each one unlocks.
There's no separate `reached-ithaca`/`reached-troy` entry: Troy is the
route's own start (0 m — nothing to unlock) and Ithaca's meters are
`journeys-end`'s threshold exactly, so a landmark-flavored duplicate there
would just unlock in lockstep with a milestone entry that already covers
it. Streaks and overtaking-a-friend conditions (§6.3) are still future
`AchievementKind` cases the evaluator's `switch` can grow to cover —
adding one still never touches a widget.

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

One title key per catalog row (see the table above), plus
`achievementUnlockedLabel` and `achievementRemainingLabel` (`{amount}`).
The `landmarkReached` titles name an actual Odyssey landmark (e.g.
"Reached Aeaea", "Passed the Sirens") — that's not narrative prose, the
same treatment the map screen already gives landmark names (§11, see
`quest_map_view.dart`'s "Ahead: {name}" caption) — but it does mean these
specific rows are Odyssey content, not catalog boilerplate a future quest
would want verbatim.

## Tests

`test/features/achievements/domain/achievement_evaluator_test.dart`:
locked-below-threshold with correct remaining meters, unlock-on-crossing,
full-catalog-unlocked, empty-catalog edge case, and `landmarkReached`
unlocking by the same rule as `distanceReached` (same threshold check, just
a different catalog entry's `kind`).

`test/features/achievements/presentation/achievements_tab_test.dart`:
whole catalog renders locked with no quest selected — including scrolling
to the grid's last tile to confirm the now-longer catalog actually renders
all the way through, not just what fits on one screen — and crossing a
threshold flips exactly that tile to unlocked.
