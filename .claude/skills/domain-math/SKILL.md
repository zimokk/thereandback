---
name: domain-math
description: Implement or change progress math in There and Back — steps to distance, stride, progress deltas, quest day, pace, ETA, number formatting, meters-to-map-point mapping, achievement evaluation. Use whenever a change touches lib/features/*/domain/ or core/formatters.dart. These are the trust-critical rules from CLAUDE.md §5 and they ship with tests, always.
---

# Domain math

This is the layer users trust. `CLAUDE.md` §13: all progress math lives in `domain/`, and only together with tests.

## Layer purity (§4)

`domain/` imports **pure Dart only** — no `package:flutter/*`, no Firebase, no `health`. No `DateTime.now()` inside a pure function either: pass the clock in, so tests can control it. Public APIs get `///` docs (§11).

Units in the domain are **integer meters and seconds** (§11). Formatting happens in presentation.

## Steps → distance (§5.1) — `features/journey/domain/stride.dart`

The single conversion point in the app.

- Default stride **0.75 m** for everyone. Onboarding asks **nothing** about height, sex or stride.
- A manually set stride (profile, §6.5) always beats the default.
- The height formulas (`height * 0.415` / `0.413`) are a placeholder for future auto-calibration — **not used in MVP**, not in onboarding.
- If the platform provides `DISTANCE_WALKING_RUNNING` / `DISTANCE`, **use it** — it is more accurate than `steps × stride`. Steps are the fallback.
- **Progress never decreases.** A negative delta from the source clamps to zero movement — never rewind the traveler.

Only steps and walking distance move the traveler (§5.1.1). Cycling, running as a distinct activity, swimming — not counted. `StepSample.source` enumerates **pedometer sources** (HealthKit, Health Connect), not activity types.

## Accounting (§5.2)

- Work in **deltas**: keep `lastSyncedAt`, query `[lastSyncedAt, now]`. Never re-add a cumulative total.
- On quest start, seed `lastSyncedAt` to the **start of the current local day** (00:00), not the start moment itself — steps taken earlier that same day still count. Backfill is by calendar day, not by the second the quest began (§5.2, resolved 2026-08-23).
- **Idempotent** writes keyed on `(userId, journeyId, intervalStart)`. Re-syncing the same interval must not double progress.
- Day boundaries in the user's **local timezone**; everything stored in **UTC**.
- Source dedup: if HealthKit and a third-party app both wrote the interval, take one — system source wins.
- Sanitizer: intervals above **250 steps/min** are **flagged**, not silently dropped.

## Derived values (§5.3)

- **Quest day** = difference in **local calendar dates** between start and now, + 1. Never `ms / 86400000` — DST and travel break that.
- **Pace** = rolling mean meters/day over the last 7 calendar days; with fewer than 3 days of data, mean over the whole quest.
- **ETA** = `now + remainingMeters / pace` days. Pace zero → render a **dash**, never infinity or NaN.
- **Friend delta** = `friend.meters - my.meters`, always signed: `+229 km`.

## Formatting (§5.4) — `core/formatters.dart`

`< 1 000 m` → whole meters; `1–100 km` → two decimals; `> 100 km` → whole. Unit label is a separate small line under the number. **Metric only — no miles setting exists or is planned** (§5.4, §6.5).

## Route mapping (§6.2) — `features/quest_map/domain/route_mapping.dart`

Polyline in normalized `(0..1, 0..1)` coordinates over `map.webp`, with cumulative distance at each vertex in `map.json`. Provide both directions: meters → point, point → meters. Test the edges: **0 m and full length**, plus exactly-on-a-vertex and past-the-end inputs.

## Achievements (§6.3)

Conditions are **data in a config**, evaluated by one pure evaluator. Adding an achievement must require editing config only — no `if` per achievement in a widget.

## Required tests (§12) — none of these are optional

- steps → distance conversion, including the distance-beats-steps preference
- progress monotonicity under a negative delta
- delta idempotency on repeat sync of one interval
- day boundaries and timezone handling (include a DST transition)
- quest day, pace, ETA — including zero pace → dash
- number formatter at each boundary: 999 / 1 000 / 100 000 m
- meters ↔ map point at 0 m and full length
- sanitizer flags (not drops) a > 250 steps/min interval

Write the test with the function, in the same commit. Then `dart format . && flutter analyze && flutter test`.
