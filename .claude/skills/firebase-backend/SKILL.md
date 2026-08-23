---
name: firebase-backend
description: Work on the There and Back backend — Firestore schema and Security Rules, Firebase Auth, Cloud Functions, FCM pushes, friends sync, emulator tests. Use whenever the task touches the Firestore data model, rules, functions, or friend visibility. CLAUDE.md §13 requires showing a plan before writing code here.
---

# Firebase backend

Firebase covers Auth, Firestore, Functions and FCM for the MVP (§3). Firestore is a **sync layer, not the source of truth** — drift on the device is (§8).

**Plan before code.** §13: any change to the Firestore schema, permissions, or privacy gets a written plan and the user's agreement first.

## Auth (§8, resolved 2026-08-23)

**Anonymous sign-in by default** (`signInAnonymously`) — no login screen in MVP, the account is created silently on first launch. A permanent login is a **future upgrade** of the anonymous session (`linkWithCredential`) triggered when the user goes to add a friend — `Friendship` needs a stable identifier that survives a reinstall, an anonymous uid alone does not. Provider choice (email/Google/Apple) is still open (§14); don't build a login screen speculatively, but don't do anything that would make the anonymous uid unlinkable later either.

## Offline / multi-device merge (§8, resolved 2026-08-23)

Merging across devices is **additive**, via the existing delta idempotency key `(userId, journeyId, intervalStart)` — no "which device wins" logic to design. Online, a device writes locally then pushes immediately; offline, deltas queue on-device and flush on reconnect, safe to retry because of the idempotency key.

## Schema (§8)

```
users/{uid}                       # nickname, avatar, privacy settings
users/{uid}/progress/{journeyId}  # meters, startedAt, updatedAt, isCurrent
friendships/{pairId}              # sorted uid pair, status, initiator
journeys/{journeyId}              # quest catalog — read-only for clients
```

- The quest catalog is **editorial content**: clients read, never write. Users do not build routes (no length, no biome picking) — a route builder is possible future work, not MVP (§8).
- Heavy assets (map, layers) live in Firebase Storage and are cached on device after first download.
- `pairId` is the two uids **sorted**, so the pair has one canonical document.

## What may be stored — and what may not (§7)

- Allowed: aggregated per-quest progress, nickname, avatar, privacy flags.
- **Forbidden**: raw health samples, geolocation, any medical metric, anything identifying beyond what the user chose to show. These never leave the device.

## Security Rules — mandatory (§8)

- Reading another user's progress is allowed **only** when an `accepted` friendship exists between the two uids.
- A friend request needs **mutual confirmation**; before `accepted`, progress is invisible.
- A user can hide progress from a specific friend (§6.4) — the rule must honor that, not just the UI.
- `journeys/{journeyId}` is read-only for clients.
- Users write only their own `users/{uid}/**`.

Rules ship with **emulator tests** (§8, §12) — both the allowed and the denied case for every rule. Run:

```bash
firebase emulators:start        # Firestore + Functions
```

## Writes from the client (§8)

Progress is written in **batches**, no more than once every few minutes — never per pedometer tick. Local drift write happens first; a failed upload must not lose local progress or double-count on retry (idempotency key `(userId, journeyId, intervalStart)`, §5.2).

## Cloud Functions (§9 of the plan, §8)

For pushes ("a friend passed you", "a friend reached a landmark") and aggregations. Keep them thin; no health data in function logs (§13).

## Client layering (§4)

Firestore DTOs and domain entities are **different types**; mapping lives in `data/`. UI never touches a repository directly — Riverpod providers in between. The app must work fully offline with Firestore unreachable (§8).

## Friends (§6.4)

Passive comparison only — no teams, parties, group quests or competitions in MVP, and do not model a `team` entity "just in case". A friend's pin color is assigned once and stays identical on the map and in the table.
