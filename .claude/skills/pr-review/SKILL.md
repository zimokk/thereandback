---
name: pr-review
description: Review a pull request, branch, or working diff of There and Back against the project spec. Use when the user asks to review a PR, "посмотри PR", check a branch before merge, or prepare a PR description. Checks the CLAUDE.md hard rules (layer purity, stack, privacy, l10n, tests) that a generic review misses.
---

# PR review

Review changes against `CLAUDE.md`. A generic code review misses the rules that matter most here — walk this checklist explicitly.

## Gather the diff

```bash
git fetch origin main
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
gh pr view <n> --json title,body,files      # when reviewing a GitHub PR
gh pr diff <n>
```

For a deeper automated pass, `/code-review` is available; this skill is the project-specific layer on top of it.

## Hard rules — a violation blocks the merge

These are §13 "Правила для Claude". Flag each with the section number.

1. **Stack unchanged** — Flutter / Flame / Riverpod / Firebase / drift. A new state manager, HTTP client, or DB is a block unless the user approved it in writing.
2. **No Google Fit** (§3) — the API is dead and removed from `health` ≥ 11.0.0.
3. **No `flutter_map`, OSM, Google Maps, or any tile source** (§6.2) — the world is fictional, the map is a drawn asset.
4. **`domain/` is pure Dart** (§4) — no `package:flutter/*`, no Firebase, no `health` imports. Grep the diff:
   ```bash
   git diff origin/main...HEAD -- '*/domain/*' | grep -nE '^\+.*import .*(package:flutter|firebase|health)'
   ```
5. **UI never touches repositories directly** (§4) — only through a Riverpod provider.
6. **Firestore DTOs ≠ domain entities** (§4) — mapping lives in `data/`.
7. **No hardcoded UI strings** (§11) — everything through `l10n`, both `ru` and `en` updated.
8. **No hardcoded colors/sizes in widgets** (§9) — tokens from `lib/design/` only.
9. **No monetization** (§11) — no IAP, paywalls, premium quests.
10. **Progress math lives in `domain/` and ships with tests** (§13).
11. **No health data, coordinates, or identifiers in logs or analytics** (§13).
12. **Generated files not hand-edited** — `*.g.dart`, `*.freezed.dart` (§11).
13. **New dependency** — the PR must explain why nothing already in the project can do it (§13).
14. **Permissions / privacy / Firestore schema touched** → the plan must have been shown and agreed before the code (§13).

## Domain-correctness checks

The trust-critical math (§5, §12). If the diff touches any of it, verify the test exists — not just that code looks right:

- Steps → meters: default stride **0.75 m**, manual value wins, platform `DISTANCE_WALKING_RUNNING` beats `steps × stride` (§5.1).
- Progress is **monotonically non-decreasing**, even on a negative delta (§5.1).
- Deltas are **idempotent** on `(userId, journeyId, intervalStart)` (§5.2).
- Day boundaries in the user's **local** timezone, stored UTC (§5.2).
- Quest day = calendar-date difference + 1, **not** ms / 86400000 (§5.3).
- Pace = 7-day rolling mean, fallback to all-time under 3 days; zero pace → ETA shows a dash, never infinity (§5.3).
- Number formatting exactly per §5.4 (`196 meters` / `5.23 kilometers` / `2853 kilometers`); domain keeps integer meters.
- Unrealistic intervals (> 250 steps/min) are **flagged, not silently dropped** (§5.2).
- Route mapping meters ↔ point tested at both edges: 0 m and full length (§12).

## Quality pass

- Tests present for the §12 list; widget tests for touched tabs; rules tests when Security Rules change.
- `dart format . && flutter analyze && flutter test` green (§10).
- Feature-first placement matches §4; one PR, one feature (§11).
- Public domain-layer APIs documented with `///` (§11).
- Flame scene changes: parallax offset still linear to scroll, game loop paused on invisible tab, 60 fps target (§6.1, §12).

## Reporting

Order findings **blocking → should-fix → nit**, each with `file:line` and the §-reference. Say plainly when something is fine — do not invent findings to fill the list. If you ran no tests, say so rather than implying the branch is verified.

## Writing a PR description

Structure: what changed and why → which `CLAUDE.md` sections it implements → which Phase of `docs/implementation-plan.md` it advances → how it was tested → what is deliberately left out. End the body with:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
