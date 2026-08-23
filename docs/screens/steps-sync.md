# Feature: Steps sync (device activity)

Not a tab — a permission/sync flow embedded at the top of the Путь tab
(see [`journey.md`](journey.md)). Documented separately because it's a new
feature module with its own permissions/privacy surface (§13), added on
top of the original four-screen ask so the traveler actually moves off
real device activity ("как делают фитнес-трекеры") instead of a hardcoded
zero.

This implements a **foreground-only** slice of `docs/implementation-plan.md`'s
Phase 4 (permission flow, health-adapter wrapping, the realistic-pace flag)
together with Phase 3's local persistence (drift) — see
[below](#phase-3--durable-persistence-drift). Background delivery
(`workmanager`/`BGTaskScheduler`) is still out of scope; see that section
below.

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
| `steps/data/step_sample_repository.dart` | data | `StepSampleRepository` + `DriftStepSampleRepository` — the idempotency log (see below) |
| `data/drift/database.dart` | data (shared, not steps-specific) | `AppDatabase`: `SelectedQuestRows` + `StepIntervalRecords` tables |
| `features/journey/data/progress_repository.dart` | data | `ProgressRepository` — derives `SelectedQuest` from the interval log |
| `steps/presentation/steps_sync_state.dart` | presentation | `StepsPermissionStatus` enum + `StepsSyncState` (freezed) |
| `steps/presentation/steps_providers.dart` | presentation | `healthAdapterProvider`, `stepSampleRepositoryProvider`, `StepsSync` notifier (permission flow + `sync()`) |
| `steps/presentation/permission_gate.dart` | presentation | The three-state gate card |

## State — providers

| Provider | Shape | Notes |
|---|---|---|
| `healthAdapterProvider` | `HealthAdapter` | Defaults to `HealthPackageAdapter()`. **Always override with a fake in tests** — never the real plugin in a widget test (`testing` skill). |
| `stepsSyncProvider` | `StepsSyncState` (Notifier) | `permissionStatus` + `isSyncing` + `lastSyncFlagged` (§5.2 pace check result — surfaced by `_FlaggedPaceNotice`, doesn't affect crediting). |

## Phase 3 — durable persistence (drift)

Sync writes are idempotent, keyed on `(ownerId, journeyId, intervalStart)`
(§5.2), and survive an app restart — not just within one running session.

- **`ownerId`** is `core/local_owner.dart`'s `localOwnerId` placeholder
  today (one constant, one device) until Phase 8 wires Firebase Auth's
  anonymous `uid`. Swapping it in later is a data-layer change only.
- **`StepIntervalRecords`** (`data/drift/database.dart`) is the durable log:
  one row per synced interval, written by
  `StepSampleRepository.recordInterval()` with `InsertMode.insertOrIgnore`
  against the `(ownerId, journeyId, intervalStart)` unique key. If the row
  already exists, `recordInterval` returns `false` and `StepsSync.sync()`
  does **not** credit that delta again — a replay of the same interval
  (a background sync racing a foreground one, or a restart that lost
  in-memory `lastSyncedAt`) can never double progress.
- **`progressMeters` and `lastSyncedAt` are derived, not stored.** §5.2 says
  "work with deltas, not an accumulated total" — so `SelectedQuestRows`
  only stores `journeyId` and `startedAt`; `ProgressRepository.
  loadSelectedQuest()` computes `progressMeters` as `SUM(resolvedMeters)`
  and `lastSyncedAt` as the latest recorded `intervalEnd` (falling back to
  the local-day seed when no interval has synced yet). A single durable
  write path (recording an interval) can't drift out of sync with a
  separately-updated running total the way two independent writes could.
- `SelectedJourney.build()` (`journey_providers.dart`) restores the
  persisted quest asynchronously right after returning `null` synchronously
  — the same "fire an async check from a sync `build()`" idiom
  `StepsSync.build()` already used for `refreshStatus()`. `start()` writes
  through `progressRepositoryProvider`; `applySyncedProgress()` stays
  in-memory only, because the durable write already happened in
  `StepsSync.sync()` before it's called.
- Tests never touch a real drift database (`testing` skill) — every test
  overrides `appDatabaseProvider` with `AppDatabase.forTesting()`
  (in-memory), including the widget tests in `journey_tab_test.dart`,
  `steps_providers_test.dart`, `quest_stats_tab_test.dart` and
  `achievements_tab_test.dart` that call `.start()`/`.applySyncedProgress()`.

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
- **No `sqlite3_flutter_libs`.** That package is deprecated as of `sqlite3`
  3.x (bundling the native library is now handled by `sqlite3`'s own native
  assets/build hooks) — do not re-add it if a future dependency upgrade
  guide suggests otherwise; check the `sqlite3` package's own changelog
  first. Not yet verified building for a real iOS/Android device in this
  base (§ Cannot be verified below) — worth an extra look the first time
  this actually gets built for a device, not just analyzed/tested.

## Cannot be verified in this environment

This was built, typechecked (`flutter analyze` passes against the real
`health` package API), and — since a Flutter SDK was installed into this
particular sandbox — `flutter test` run in a cloud sandbox with **no
Android emulator or iOS simulator**: there is no HealthKit or Health
Connect runtime here to run `flutter test integration_test` against. Phase
4's own "Готово, когда" criterion (an integration test passing on at least
one real platform) is **not met by this base** and needs a real
device/emulator to close out. Phase 3's own criteria (drift schema test,
idempotent-sync test) are unit/widget-level and **are** covered and green
in this environment — see Tests below.

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
exercises `StepsSync.sync()` end to end against a mocked `HealthAdapter`
and an in-memory `AppDatabase` — a realistic pace leaves `lastSyncFlagged`
false, an implausible one (a huge step count over a short
`lastSyncedAt`-to-now window) sets it true, and **either way the distance
is credited to `selectedJourneyProvider`** (the test that would have caught
`isImplausiblePace` being unwired); a fourth test proves the Phase 3
durability claim directly — after a sync, reloading via
`progressRepositoryProvider` (what a restarted app's `build()` does)
matches what was just credited in memory.

Data layer (§12's mandatory "drift schema migration test" and "a repeated
sync of the same interval does not double progress"):
- `test/data/drift/app_database_test.dart` — schema baseline, the
  `SelectedQuestRows` overwrite-on-restart behavior, and the
  `StepIntervalRecords` unique-key insert-or-ignore check.
- `test/features/journey/data/progress_repository_test.dart` — a fresh
  quest loads with zero progress and the local-day-seeded `lastSyncedAt`;
  progress is proven derived (two recorded intervals sum correctly, nothing
  is stored as a running total); a different owner never sees another
  owner's quest (§8, §13).
- `test/features/steps/data/step_sample_repository_test.dart` — the
  idempotency guarantee directly: recording the same
  `(ownerId, journeyId, intervalStart)` twice returns `true` then `false`
  and never writes a second row; a different `journeyId` at the same
  `intervalStart` is correctly treated as distinct, not a duplicate.

No widget test exists solely for `permission_gate.dart` in isolation today
— its three states are exercised through
`test/features/journey/presentation/journey_tab_test.dart` (see
[`journey.md`](journey.md)), which overrides `stepsSyncProvider` directly
with a fixed `_FixedStepsSync` fake rather than touching the real
`health` plugin.
