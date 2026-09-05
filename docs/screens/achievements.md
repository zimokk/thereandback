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
Today's catalog (`data/achievement_catalog.dart`) has twenty entries, in
ascending threshold order within each quest's own group:

**Generic** (`journeyId: null`) — apply to whichever quest is active, no
matter its length:

| id | threshold | kind | l10n title key |
|---|---|---|---|
| `first-steps` | 1 000 m | `distanceReached` | `achievementFirstStepsTitle` |
| `first-league` | 10 000 m | `distanceReached` | `achievementFirstLeagueTitle` |
| `half-day-march` | 50 000 m | `distanceReached` | `achievementHalfDayMarchTitle` |
| `century-mark` | 100 000 m | `distanceReached` | `achievementCenturyMarkTitle` |
| `seasoned-wanderer` | 500 000 m | `distanceReached` | `achievementSeasonedWandererTitle` |
| `long-hauler` | 2 000 000 m | `distanceReached` | `achievementLongHaulerTitle` |

**`odyssey-ithaca`** (2 850 000 m) — thresholds are this quest's own
landmark meters or a fraction of its own length:

| id | threshold | kind | l10n title key |
|---|---|---|---|
| `reached-circe` | 561 921 m | `landmarkReached` | `achievementReachedCirceTitle` |
| `reached-lotus-eaters` | 1 215 166 m | `landmarkReached` | `achievementReachedLotusEatersTitle` |
| `halfway-there` | 1 425 000 m | `distanceReached` | `achievementHalfwayThereTitle` |
| `reached-calypso` | 1 804 508 m | `landmarkReached` | `achievementReachedCalypsoTitle` |
| `passed-scylla-charybdis` | 2 011 461 m | `landmarkReached` | `achievementPassedScyllaCharybdisTitle` |
| `passed-sirens` | 2 465 426 m | `landmarkReached` | `achievementPassedSirensTitle` |
| `journeys-end` | 2 850 000 m | `distanceReached` | `achievementJourneysEndTitle` |

**`tower-of-lights`** (240 000 m, §14 2026-09-05) — same pattern, its own
landmark meters or a fraction of its own length:

| id | threshold | kind | l10n title key |
|---|---|---|---|
| `left-the-tower` | 20 000 m | `landmarkReached` | `achievementLeftTheTowerTitle` |
| `crossed-the-pines` | 50 000 m | `landmarkReached` | `achievementCrossedThePinesTitle` |
| `tower-halfway` | 120 000 m | `distanceReached` | `achievementTowerHalfwayTitle` |
| `reached-mountain-gate` | 145 000 m | `landmarkReached` | `achievementReachedMountainGateTitle` |
| `reached-sea-horizon` | 180 000 m | `landmarkReached` | `achievementReachedSeaHorizonTitle` |
| `reached-lantern-hill` | 215 000 m | `landmarkReached` | `achievementReachedLanternHillTitle` |
| `under-the-skyfire` | 240 000 m | `landmarkReached` | `achievementUnderTheSkyfireTitle` |

`AchievementKind` has two cases: `distanceReached` for a plain milestone,
and `landmarkReached` for a threshold that's actually a specific landmark's
meters from that quest's own `map.json` — same unlock rule
(`progressMeters >= thresholdMeters`), evaluated in the same `switch` arm,
kept as its own case purely so the catalog records *why* each one unlocks.
There's no separate `reached-ithaca`/`reached-troy` entry: Troy is the
route's own start (0 m — nothing to unlock) and Ithaca's meters are
`journeys-end`'s threshold exactly, so a landmark-flavored duplicate there
would just unlock in lockstep with a milestone entry that already covers
it — the same reasoning gave `under-the-skyfire` its landmark-flavored
title *instead of* a second neutral "Journey's End", so the two quests'
completion trophies never share identical displayed text (`journeys-end`'s
own doc comment explains why that specifically matters here). Streaks and
overtaking-a-friend conditions (§6.3) are still future `AchievementKind`
cases the evaluator's `switch` can grow to cover — adding one still never
touches a widget.

### Per-quest scoping (§14, 2026-09-05)

`AchievementDef.journeyId` says which quest an entry belongs to (`null` for
a generic one); `achievementsForJourney(catalog, journeyId)` narrows the
catalog before it reaches `evaluateAchievements`
(`achievements_tab.dart`) or `computeJourneyAchievementUnlockDates`
(`achievement_repository.dart`'s `refreshUnlocks`). With no quest selected
this returns the catalog **unchanged** — the "browse every trophy that
exists" preview the Трофеи tab shows before any quest is picked; once a
quest is active, a different quest's scoped entries are filtered out of the
grid entirely rather than shown forever-locked, since their thresholds
don't describe anything on the active route.

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
[`journey.md`](journey.md)) for `progressMeters` and `journeyId` — the
latter feeds `achievementsForJourney`'s scoping (above). Owns no provider
itself.

## l10n keys

One title key per catalog row (see the tables above), plus
`achievementUnlockedLabel` and `achievementRemainingLabel` (`{amount}`).
Every `landmarkReached` title names an actual landmark on its own quest
(e.g. "Reached Aeaea", "Reached the Mountain Gate") — that's not narrative
prose, the same treatment the map screen already gives landmark names (§11,
see `quest_map_view.dart`'s "Ahead: {name}" caption) — but it does mean
these specific rows are that quest's own content, not catalog boilerplate a
future quest would want verbatim; a new quest wanting the same treatment
adds its own entries and title keys rather than reusing another quest's.

## Tests

`test/features/achievements/domain/achievement_evaluator_test.dart`:
locked-below-threshold with correct remaining meters, unlock-on-crossing,
full-catalog-unlocked, empty-catalog edge case, `landmarkReached` unlocking
by the same rule as `distanceReached` (same threshold check, just a
different catalog entry's `kind`), and `achievementsForJourney`'s scoping
(null returns everything unchanged, a quest gets its own entries plus every
generic one, an unrecognized quest id gets only the generic ones).

`test/features/achievements/presentation/achievements_tab_test.dart`:
whole catalog renders locked with no quest selected — including scrolling
to the grid's last tile to confirm the now-longer catalog actually renders
all the way through, not just what fits on one screen — and crossing a
threshold flips exactly that tile to unlocked. A `'per-quest scoping'`
group covers `tower-of-lights`: its own entries render (scrolled into
view), `odyssey-ithaca`'s never do, and its own unlock rows read back
correctly.

`test/features/achievements/data/achievement_repository_test.dart`: a
quest-specific threshold never unlocks against another quest's recorded
history, even past its raw meters value, and each quest's own scoped
achievement does unlock from its own history.
