---
name: health-steps
description: Integrate or change step/health data in There and Back — the health package, HealthKit, Health Connect, permission flows, sync deltas, privacy of health data. Use whenever the task touches features/steps/, platform permission manifests, or asks how steps reach the app. CLAUDE.md §13 requires a plan before code when permissions or privacy are involved.
---

# Steps & health integration

`health` ^13.x wraps Health Connect on Android (§3). iOS is **temporarily** on Core Motion (`cm_pedometer`, `CMPedometer.queryPedometerData`) instead of `health`'s HealthKit path — HealthKit needs a paid Apple Developer Program membership to sign at all, CMPedometer doesn't (§3, §14, decided 2026-08-28 by explicit request). `ios_step_counting_service.dart` carries the TODO for migrating back once that membership exists; the HealthKit-based implementation it replaced is in git history, not deleted code to rewrite. **Never propose Google Fit**: the API is dead (new registrations closed 2024-05-01) and support was removed from `health` in 11.0.0 (§3, §13).

**Plan first.** Permissions and privacy are §13 plan-before-code territory. Show the approach and get agreement before editing.

## Permission flow (§7)

- Ask **at quest start**, not at app launch, behind a screen explaining *why*.
- iOS (current, CMPedometer): `NSMotionUsageDescription` in `Info.plist`, requested through `permission_handler`'s `Permission.sensors` — not `Permission.activityRecognition`, which has no iOS mapping at all. `NSHealthShareUsageDescription` and the HealthKit entitlement are commented out, not deleted, for the same reason as below.
- iOS (HealthKit, disabled for now — see above): `NSHealthShareUsageDescription` in `Info.plist`. The app **only reads** — no HealthKit write permission, ever.
- Android: Health Connect permissions `READ_STEPS`, `READ_DISTANCE`; background reads need `READ_HEALTH_DATA_IN_BACKGROUND`.
- **Health Connect may not be installed** — handle it explicitly with a deep link to the Play Store listing.
- **Denial is not a dead end**: the app keeps working, shows a "no step data" state and a re-request button. Cover this path with a widget test (§12, Phase 4).

## Reading data (§5.1, §5.1.1)

- Prefer `DISTANCE_WALKING_RUNNING` / `DISTANCE` when the platform offers it; steps × stride is the fallback.
- Only pedometer-shaped data moves the traveler. Cycling, running-as-activity, swimming: **not counted**. Adding another activity type is a separate domain decision, never a default.
- `StepSample.source` names the **pedometer source** (HealthKit / Health Connect), not the activity.

## Sync (§5.2, §8)

- Query **deltas**: keep `lastSyncedAt`, request `[lastSyncedAt, now]`.
- Writes idempotent on `(userId, journeyId, intervalStart)` — a repeated sync must not double progress.
- Dedup overlapping sources; the system source wins.
- Flag intervals above **250 steps/min**; do not drop them silently.
- Persist to **drift first** (source of truth, §8), then push to Firestore in **batches** — at most once every few minutes, never per sensor tick.
- Store UTC; compute day boundaries in the user's local timezone.
- On quest start, seed `lastSyncedAt` to the start of the current local day, not the start moment — same-day steps before quest start still count (§5.2).

## Background sync — enabled, needs a plan first (§7, §13, resolved 2026-08-23)

Background sync is turned **on**: the app is meant to sync periodically even when not foregrounded, not only on open, so friend pins and pushes don't lag a full day behind. `READ_HEALTH_DATA_IN_BACKGROUND` is declared for real use, not left unused.

The **mechanism is still an open decision** (`workmanager`, or platform APIs directly — WorkManager / `BGTaskScheduler`) — per §13, write the `architecture-plan` before adding the dependency or wiring background execution. Do not start coding a background sync path off this skill alone.

## Offline / multi-device merge (§8, resolved 2026-08-23)

No "which device wins" logic needed — merging is additive through the existing idempotency key. Online: write locally then push immediately. Offline: queue the delta on-device and flush it to Firestore once connectivity returns, using the same `(userId, journeyId, intervalStart)` key so a retried flush cannot double-count.

## Privacy — hard rules (§7, §13)

- Only **aggregated per-quest progress** leaves the device. Raw health samples, geolocation and medical metrics **never** reach Firestore.
- **Never** log health data, coordinates or user identifiers, and never send them to Analytics or Crashlytics. Check every `debugPrint`/`log` you add.
- Users can hide progress from a specific friend (§6.4) — respect that flag at the sync layer, not only in the UI.

## Layering (§4)

`StepCountingService` (`features/steps/data/step_counting_service.dart`) is the interface, one per-platform class implementing it — `AndroidStepCountingService` (shipped, Health Connect via `health`, no account gate) and `IosStepCountingService` (shipped, CMPedometer via `cm_pedometer`, temporarily replacing HealthKit — see above). `HealthPackagePedometer` (same file) is the shared `health`-package plumbing, used only by the Android class today; kept general so a future HealthKit-based `IosStepCountingService` can mix it back in. `createStepCountingService()` (`steps/presentation/steps_providers.dart`) is the only `Platform.isAndroid` check in the feature. Conversion and progress math stay in `domain/` (see `domain-math`). The permission gate is `features/steps/presentation/permission_gate.dart`; UI reads a Riverpod provider (`stepCountingServiceProvider`), never a concrete service class.

## Testing (§12, Phase 4)

- Unit-test the adapter's mapping and dedup with `mocktail` fakes — no real device data in unit tests, and no real personal data in fixtures.
- Widget-test permission-denied and Health-Connect-missing paths.
- `integration_test` on at least one real platform before calling the phase done.
