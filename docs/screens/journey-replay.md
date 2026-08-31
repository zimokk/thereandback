# Feature: Journey replay (planned — data model only, no code yet)

**Status: design decision, not implemented.** Nothing in this doc exists in
`lib/` yet. It's captured here *before* the code so the one part of it that
can't be retrofitted — durable daily checkpoints, see below — starts
recording from the first quest created after this lands, rather than
being bolted on later once the early history is already gone.

## What it is

A play-back of an entire quest at compressed real time — the traveler
moving along the route the same way §6.1's Путь tab already renders a
position from `progressMeters`, except driven by a timer instead of a
finger, watching the whole walk unfold from start to finish. Design target
used while sizing this: **1 real day → 2 seconds** of playback (i.e. a
90-day quest replays in three minutes) — an example ratio, not a fixed
constant; see "Not decided yet" below.

## Why it needs its own data, not just what already exists

`StepIntervalRecords` (drift, §5.2) already has real timestamps and
per-interval meters, dense enough on its own for this — even a wide
15-minute background-sync interval compresses to a fraction of a frame at a
1-day-in-2-seconds ratio, so raw interval granularity was never the
problem.

The problem is durability. Two things already in this codebase quietly
destroy that history:

- `ProgressRepository.restoreFromCloud` (§8, §14 "Решено 2026-08-30" —
  repeat login) **deletes** the device's entire local `StepIntervalRecords`
  history for a quest and replaces it with one seed interval
  `[startedAt, asOf] → totalMeters`. A replay reconstructed after that
  point would show the whole walk happening in a single instant.
- Firestore never stores per-interval history at all — only the running
  total in `users/{uid}/progress/{journeyId}` (§14, same date, the pace/ETA
  fallback note). It was never meant to be a backup for a data shape this
  detailed.

So the raw interval log can't be the source of truth for a replay; it
survives exactly as long as one device's local SQLite does, which today is
explicitly allowed to get collapsed.

## The decision

- **Already-active quests: no backfill, no special-casing.** Deliberately
  out of scope — a quest already in progress when this ships just never
  gets a replay (or a partial one, if a later change chooses to render
  whatever raw `StepIntervalRecords` history a given device still happens
  to have — not decided, not required).
- **Any quest started after this ships:** record one durable checkpoint per
  local calendar day (§5.3's calendar-day convention, the same one "День N"
  already uses) — cumulative meters walked as of the end of that day,
  starting from day 1 (quest start), building on nothing that requires a
  from-scratch design:
  - Derivable today from `StepIntervalRecords` via the exact day-grouping
    `achievement_unlocks.dart`'s `groupMetersByLocalDay` already does —
    reuse, not a new algorithm.
  - Needs a **durable store of its own**, separate from the interval table,
    specifically so it survives the same reinstall/repeat-login path that's
    already allowed to erase the raw log — most likely a small Firestore
    subcollection next to `users/{uid}/progress/{journeyId}`, written in
    daily batches (§8's existing "batches, not every tick" rule), never the
    interval table itself. One row per day is small enough that a
    multi-year quest is still trivial — nothing like the row count raw
    intervals would produce over the same span.
- **Playback smoothing is a presentation-layer concern, not a data one.**
  The traveler animates continuously between two consecutive days' points
  rather than jump-cutting once per day — plain interpolation over the
  existing `metersToPoint` map math (§6.2) and `progressFraction` (§5.3),
  reusing what the Путь tab's own scroll-driven position already does. No
  extra data granularity is needed to make it look smooth.

## Not decided yet

- **Where this lives in the UI** — its own screen, a mode inside the Путь
  tab, a button off Quest Stats' "Quest Started" — nothing chosen.
- **The exact playback ratio as a real, user-facing control** — "1 real day
  → 2 seconds" was this design pass's working example, not a shipped
  constant.
- **Whether a replay is strictly one quest** (matching how
  `StepIntervalRecords`/the new checkpoint log are already scoped by
  `journeyId`) **or can ever chain multiple completed quests** back to back.

## Before this gets built

Touches the Firestore schema and adds a new drift table/sync path — per
CLAUDE.md §13 that needs its own plan (`architecture-plan` skill) before
any code, same as every other schema-touching feature in this directory.
