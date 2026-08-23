# Feature: Steps sync (device activity)

Not a tab — a permission/sync flow embedded at the top of the Путь tab
(see [`journey.md`](journey.md)). Documented separately because it's a new
feature module with its own permissions/privacy surface (§13), added on
top of the original four-screen ask so the traveler actually moves off
real device activity ("как делают фитнес-трекеры") instead of a hardcoded
zero.

This implements a **foreground-only** slice of
`docs/implementation-plan.md`'s Phase 4, ahead of Phase 3 (drift) landing
first — see the in-memory caveat below.

## What it does

1. On first read of `stepsSyncProvider`, `StepsSync.build()` kicks off
   `refreshStatus()`: configures the `health` plugin, checks Health Connect
   availability on Android, then checks (not requests) permission.
2. If already granted, it immediately runs `sync()`.
3. If not, `StepsPermissionGate` (`steps/presentation/permission_gate.dart`)
   renders one of three cards — explanation / denied / Health-Connect-
   missing — each with a button that drives the next step (§7: never a
   dead end).
4. `sync()` fetches the delta since the selected quest's `lastSyncedAt`,
   checks it against `stride.isImplausiblePace` (§5.2 — flagged, not
   dropped, so the credited distance is unaffected), resolves it to
   meters via `stride.dart`, and writes the new total into
   `selectedJourneyProvider` (see [`journey.md`](journey.md)).
5. If that check flagged the interval, `StepsPermissionGate` shows a small
   buttonless notice on the next build (`_FlaggedPaceNotice`) — purely
   informational, it doesn't block or undo the credited distance.

## Foreground only — background sync is explicitly out of scope here

§7 calls background delivery its own architectural decision that needs a
separate plan before any code — this module deliberately does not declare
`READ_HEALTH_DATA_IN_BACKGROUND` (Android manifest) and does not touch
`workmanager`/`BGTaskScheduler`. Sync runs when the Путь tab is opened;
there's no pull-to-refresh gesture wired up yet either, so today "opening
the tab" is the only trigger.

## Layers

| File | Layer | Responsibility |
|---|---|---|
| `steps/domain/stride.dart` | domain (pure Dart) | `stepsToMeters`, `resolveDistanceMeters` (platform distance beats steps×stride, §5.1), `clampNonDecreasing` (monotonic progress), `isImplausiblePace` (>250 steps/min flag, §5.2 — called from `StepsSync.sync()`, not just unit-tested in isolation) |
| `steps/data/health_adapter.dart` | data | `HealthAdapter` interface + `HealthPackageAdapter` wrapping the `health` package (HealthKit/Health Connect) |
| `steps/presentation/steps_sync_state.dart` | presentation | `StepsPermissionStatus` enum + `StepsSyncState` (freezed) |
| `steps/presentation/steps_providers.dart` | presentation | `healthAdapterProvider`, `StepsSync` notifier (permission flow + `sync()`) |
| `steps/presentation/permission_gate.dart` | presentation | The three-state gate card |

## State — providers

| Provider | Shape | Notes |
|---|---|---|
| `healthAdapterProvider` | `HealthAdapter` | Defaults to `HealthPackageAdapter()`. **Always override with a fake in tests** — never the real plugin in a widget test (`testing` skill). |
| `stepsSyncProvider` | `StepsSyncState` (Notifier) | `permissionStatus` + `isSyncing` + `lastSyncFlagged` (§5.2 pace check result — surfaced by `_FlaggedPaceNotice`, doesn't affect crediting). |

## The idempotency caveat (§5.2) — read before assuming this is durable

§5.2 requires sync writes to be idempotent, keyed on
`(userId, journeyId, intervalStart)`. That key needs a real database to
mean anything — Phase 3's drift layer isn't built yet in this base.
Today, `lastSyncedAt` lives only inside `SelectedQuest`, an in-memory
Riverpod notifier: a sync is idempotent *within one running app session*
(re-running `sync()` without new activity adds nothing new, since the next
fetch's `[lastSyncedAt, now)` window has advanced), but a killed-and-
restarted app loses `lastSyncedAt` and `progressMeters` entirely. Treat
this module's persistence claims as "correct once wired to Phase 3", not
as already durable.

## Platform setup done here

- **iOS** (`ios/Runner/Info.plist`): `NSHealthShareUsageDescription` added.
  **Not done**: enabling the HealthKit capability in Xcode (Signing &
  Capabilities → + HealthKit), which creates `Runner.entitlements` and
  touches `project.pbxproj` — that's a manual Xcode step, not safely
  automatable from a CLI edit without risking a malformed project file.
- **Android** (`android/app/src/main/AndroidManifest.xml`):
  `android.permission.health.READ_STEPS` / `READ_DISTANCE` declared;
  `com.google.android.apps.healthdata` added to `<queries>` for package
  visibility (needed for `isHealthConnectAvailable()`/
  `installHealthConnect()` to see the app at all on Android 11+).
  `READ_HEALTH_DATA_IN_BACKGROUND` is **not** declared (see above).
- **`android/app/build.gradle.kts`**: `minSdk` raised to **26**
  (from Flutter's default 24) — the `health` package's Android module
  itself requires API 26+ for Health Connect; leaving the default would
  fail the Gradle manifest merge.

## Cannot be verified in this environment

This was built and typechecked (`flutter analyze` passes against the real
`health` package API) in a cloud sandbox with **no Android emulator or iOS
simulator** — there is no HealthKit or Health Connect runtime here to run
`flutter test integration_test` against. Phase 4's own "Готово, когда"
criterion (an integration test passing on at least one real platform) is
**not met by this base** and needs a real device/emulator to close out.

## l10n keys

`stepsPermissionExplainTitle`, `stepsPermissionExplainBody`,
`stepsPermissionAllow`, `stepsPermissionDeniedTitle`,
`stepsPermissionDeniedBody`, `stepsPermissionRetry`,
`stepsHealthConnectMissingTitle`, `stepsHealthConnectMissingBody`,
`stepsHealthConnectInstall`, `stepsFlaggedPaceNotice`.

## Tests

Domain: `test/features/steps/domain/stride_test.dart` — the full §12
mandatory list for this module (platform-distance preference, monotonic
clamp on a negative delta, >250 steps/min flagged not dropped, threshold
boundary).

Provider-level: `test/features/steps/presentation/steps_providers_test.dart`
exercises `StepsSync.sync()` end to end against a mocked `HealthAdapter` —
a realistic pace leaves `lastSyncFlagged` false, an implausible one (a huge
step count over a short `lastSyncedAt`-to-now window) sets it true, and
**either way the distance is credited to `selectedJourneyProvider`** —
this is the test that would have caught `isImplausiblePace` being unwired.

No widget test exists solely for `permission_gate.dart` in isolation today
— its three states are exercised through
`test/features/journey/presentation/journey_tab_test.dart` (see
[`journey.md`](journey.md)), which overrides `stepsSyncProvider` directly
with a fixed `_FixedStepsSync` fake rather than touching the real
`health` plugin.
