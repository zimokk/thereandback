---
name: testing
description: Write or run tests for There and Back — unit tests for domain math, widget tests for the five tabs, Flame scene tests, drift migration tests, Firestore Security Rules emulator tests, integration_test. Use when the user asks to add tests, fix a failing test, or check coverage of a change.
---

# Testing

`CLAUDE.md` §12 lists what is **mandatory**, not aspirational. A change to any item below ships with its test in the same commit.

## Commands (§10)

```bash
flutter test                       # unit + widget
flutter test integration_test      # on a device/emulator
firebase emulators:start           # then run the rules tests
dart run build_runner build --delete-conflicting-outputs
dart format . && flutter analyze
```

## Mandatory coverage (§12)

**Domain (pure, fast, no Flutter):**
- steps → distance conversion, including platform distance beating `steps × stride` (§5.1)
- progress monotonicity — a negative delta never rewinds (§5.1)
- delta idempotency on `(userId, journeyId, intervalStart)` (§5.2)
- day boundaries and timezones, including a DST transition (§5.2)
- quest day, pace, ETA — zero pace renders a dash, not infinity (§5.3)
- number formatter at each boundary: 999 / 1 000 / 100 000 m (§5.4)
- sanitizer flags a > 250 steps/min interval instead of dropping it (§5.2)
- meters ↔ map point along the polyline, **including 0 m and full length** (§6.2)

**Widget:** all five tabs render; plus each non-happy state — permission denied, no step data, no friends, quest completed (§6.1, §7).

**Flame:** parallax offset is linear in scroll position; the game loop stops on an inactive tab (§6.1).

**Data:** drift schema migration test; a repeated sync of the same interval does not double progress (Phase 3).

**Firestore Security Rules:** emulator tests, allowed *and* denied case per rule — reading a friend's progress works only with an `accepted` friendship (§8).

**Integration:** at least one platform passing for the steps flow (Phase 4).

## How to write them here

- Domain tests import **no Flutter** — if a domain test needs `flutter_test`'s binding, the code under test has a layer violation (§4).
- Inject the clock. No `DateTime.now()` inside pure functions; pass time in so day/pace/ETA are deterministic.
- Fakes with `mocktail`. Widget tests override Riverpod providers via `ProviderScope(overrides: […])` — never a real drift database, health plugin or Firestore.
- **No real personal data in fixtures**: no real health samples, coordinates or identifiers (§13). Invent numbers.
- **No copyrighted names in test data** either — no Tolkien/Rowling place names in a fixture journey (§1.1, §13). Use the Odyssey quest or a neutral placeholder.
- Golden tests are optional; if used, keep them off the parallax scene (time-of-day sky makes them flaky) — test the math, not the pixels.

## Failing tests

Fix the cause. Do not weaken an assertion, add a `skip`, or loosen a tolerance to get green, and never report a task complete with a red test — quote the failure output to the user instead.
