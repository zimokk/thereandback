---
name: architecture-plan
description: Plan the architecture or implementation approach for a change in There and Back before writing code. Use when the user asks how to structure a feature, where code should live, to plan a phase from docs/implementation-plan.md, or when the change touches permissions, privacy, or the Firestore schema (CLAUDE.md §13 requires a plan first).
---

# Architecture planning

Produce a plan, not code. Some changes in this repo **require** an approved plan before any code is written (§13): anything touching **permissions, privacy, or the Firestore schema**. Also plan first for: a new dependency, a change to the layer rules, anything that alters the domain model or the stack.

## Sources of truth, in order

1. `CLAUDE.md` — authoritative on stack, architecture, product decisions. Cite sections as §N.
2. `docs/implementation-plan.md` — sequences CLAUDE.md into Phase 0–12 with "Готово, когда" criteria and dependencies. Locate the change in a phase; respect its dependencies.
3. Existing code. Read it before proposing structure — do not plan against an imagined tree.

If the two docs disagree, `CLAUDE.md` wins, and say so in the plan.

## Non-negotiable constraints to design within

- **Stack is fixed** (§3, §13): Flutter ≥ 3.47 / Dart ≥ 3.13, Flame, Riverpod (+ generator), freezed + json_serializable, go_router, drift, `health` ^13, Firebase (Auth/Firestore/Functions/FCM), Analytics + Crashlytics, flutter_test/mocktail/integration_test. Disagree in words, never by rewriting.
- **Feature-first, three layers** (§4): `domain/` pure Dart (no flutter/firebase/health), `data/` repositories + mappers, `presentation/` widgets + providers. UI → provider → repository. Firestore DTOs and domain entities are distinct types.
- **Offline-first** (§8): drift is the source of truth; Firestore is a sync layer. Every screen works with no network.
- **Domain units**: integer meters and seconds (§11). Formatting only in presentation.
- **All progress math in `domain/`, with tests** (§13).
- **MVP exclusions** — do not design them in "for later": no route builder (§8), no group quests/party/competition (§6.4), no monetization (§11), no activities other than steps (§5.1.1), no generated narrative (§11), no tile maps (§6.2).
- **Privacy** (§7): only aggregated per-quest progress leaves the device. Raw health data, geolocation and medical metrics never reach Firestore, logs, or analytics.

## Plan shape

Write it as:

1. **Goal** — one paragraph, and which §-sections and which Phase it implements.
2. **Files** — every file to create or change, by exact path in the §4 tree, with one line each on responsibility.
3. **Data flow** — where a value enters (health adapter / Firestore / user input), how it crosses layers, where it is persisted, what it renders as.
4. **Domain decisions** — entities and pure functions touched; state the invariants (monotonic progress, idempotent deltas, local-timezone day boundaries) the change must preserve.
5. **Tests** — the §12 list that applies, named per file. A plan without tests is incomplete.
6. **Risks / open questions** — including anything from §14 that this change bumps into.
7. **Out of scope** — explicitly.

## Working style (§13)

Small steps, layer by layer, with `flutter analyze` and tests after each. Order that works here: domain + tests → data + tests → providers → UI + widget test → integration.

For a plan the user must approve before implementation, present it with `ExitPlanMode` (load it via ToolSearch first) rather than starting to edit files.

## Open questions (§14) — do not silently resolve

Still unresolved: the name of the original fantasy world and its regions; the art source for parallax layers and quest maps (§9.1); narrative-beat density per quest. If a plan depends on one of these, mark it, propose a placeholder that is cheap to replace, and keep going — do not invent a final answer as if it were decided.
