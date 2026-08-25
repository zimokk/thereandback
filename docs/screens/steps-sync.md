# Feature: Steps sync (device activity)

Not a tab — a permission/sync flow embedded at the top of the Путь tab
(see [`journey.md`](journey.md)). Documented separately because it's a new
feature module with its own permissions/privacy surface (§13), added on
top of the original four-screen ask so the traveler actually moves off
real device activity ("как делают фитнес-трекеры") instead of a hardcoded
zero.

This implements a slice of `docs/implementation-plan.md`'s Phase 4
(permission flow, health-adapter wrapping, the realistic-pace flag)
together with Phase 3's local persistence (drift) — see
[below](#phase-3--durable-persistence-drift). The sync **algorithm** below
is foreground-only in the sense that this doc describes it from
`StepsSync`'s point of view; the same algorithm also runs from an Android
background task now — see
[`lock-screen.md`](lock-screen.md#background-sync-workmanager) for that
half, added alongside the persistent lock-screen/notification-shade
feature. iOS background delivery (`BGTaskScheduler`/HealthKit background
delivery) is still out of scope.

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

## Foreground trigger — the algorithm this doc describes

Sync runs when the Путь tab is opened; there's no pull-to-refresh gesture
wired up yet either, so today "opening the tab" is the only *foreground*
trigger. §5.1/§5.2's sync algorithm itself (fetch delta → resolve meters →
record idempotently) was extracted into `steps/data/steps_sync_engine.dart`
(`StepsSyncEngine`) so it has no `Ref`/provider dependency — `StepsSync.sync()`
below is one caller of it; the Android background task described in
[`lock-screen.md`](lock-screen.md#background-sync-workmanager) is the other,
running the identical algorithm through the identical
`(ownerId, journeyId, intervalStart)` idempotency key so the two can never
double-credit the same interval. `READ_HEALTH_DATA_IN_BACKGROUND` (Android
manifest) is now declared because of that second caller — see
`lock-screen.md` for why and under what user action.

## Layers

| File | Layer | Responsibility |
|---|---|---|
| `steps/domain/stride.dart` | domain (pure Dart) | `stepsToMeters`, `resolveDistanceMeters` (platform distance beats steps×stride, §5.1), `clampNonDecreasing` (monotonic progress), `isImplausiblePace` (>250 steps/min flag, §5.2 — called from `StepsSyncEngine.sync()`, not just unit-tested in isolation) |
| `steps/data/health_adapter.dart` | data | `HealthAdapter` interface + `HealthPackageAdapter` wrapping the `health` package (HealthKit/Health Connect), including the background-permission pair used by `lock-screen.md` |
| `steps/data/step_sample_repository.dart` | data | `StepSampleRepository` + `DriftStepSampleRepository` — the idempotency log (see below) |
| `steps/data/steps_sync_engine.dart` | data | `StepsSyncEngine` — the fetch/resolve/record algorithm itself, no `Ref`; shared by `StepsSync.sync()` (below) and the Android background task (`lock-screen.md`) |
| `data/drift/database.dart` | data (shared, not steps-specific) | `AppDatabase`: `SelectedQuestRows` + `StepIntervalRecords` tables |
| `features/journey/data/progress_repository.dart` | data | `ProgressRepository` — derives `SelectedQuest` from the interval log |
| `steps/presentation/steps_sync_state.dart` | presentation | `StepsPermissionStatus` enum + `StepsSyncState` (freezed) |
| `steps/presentation/steps_providers.dart` | presentation | `healthAdapterProvider`, `stepSampleRepositoryProvider`, `StepsSync` notifier (permission flow; `sync()` now just builds a `StepsSyncEngine` and applies its result) |
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

## Android permission flow is two runtime prompts, not one

Health Connect's own consent screen for Steps/Distance ("Fitness and
wellness" in system settings) is not the only gate on Android. Reading step
data also needs `ACTIVITY_RECOGNITION` ("Physical activity" in system
settings) — a dangerous-protection-level OS permission since Android 10.
Declaring it in the manifest (already done, see below) is not enough: Android
never shows its runtime dialog unless the app explicitly requests it, and
Health Connect refuses to grant the Steps/Distance read while it's missing —
no matter how many times the Health Connect request itself runs. Before this
was wired up, `requestPermission()` only ever asked for the Health Connect
half, so `ACTIVITY_RECOGNITION` silently stayed ungranted forever: tapping
"Allow" in the app's own explanation card opened Health Connect's screen, the
user accepted it, and the gate still reported denied — because Health Connect
itself wasn't actually able to hand over the grant.

`HealthAdapter.hasActivityRecognitionPermission()` /
`requestActivityRecognitionPermission()` (via `permission_handler` — the
`health` package does not request this permission itself) wrap that OS
prompt. `StepsSync.requestPermission()` now requests it first and only asks
Health Connect for Steps/Distance if it was granted; a no-op `true` on iOS,
which has no equivalent permission.

Health Connect's permission screen is a separate activity, so a grant can
land while this app is backgrounded, resuming it mid-`await` inside
`requestPermission()` — which fires the `appLifecycleProvider` listener's
`refreshStatus()` before that `await` resolves. Both write
`permissionStatus`; without guarding against that, whichever finishes last
wins even when its answer is the stale one. `_permissionOpInFlight` (private
to `StepsSync`, not part of `StepsSyncState`) makes `refreshStatus()` a no-op
while a `requestPermission()` call it would race is still in flight, and vice
versa.

**Granting the permission through system Settings instead of the app's own
flow** (a symptom of the bug above, not a fix for it) can additionally show a
Health Connect notice that new data will only be visible "starting tomorrow"
— that's Health Connect's own settings-vs-in-app-request reconciliation, not
a limitation of what this app asks for. Once the OS prompt and the Health
Connect prompt both go through the app's actual `PermissionController`-backed
request (the fix above), Health Connect's normal 30-day read-back window
applies from the moment of grant — same-day backfill (§5.2's "seed
`lastSyncedAt` to the start of the local day") is not blocked by this.

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
  `READ_HEALTH_DATA_IN_BACKGROUND` **is** now declared — requested only
  from the lock-screen toggle, not here; see `lock-screen.md`.
  `android.permission.ACTIVITY_RECOGNITION` is also declared (added earlier,
  alongside the `FlutterFragmentActivity`/rationale-activity fix) — it needs
  no manifest entry of its own from `permission_handler`, which ships an
  empty plugin manifest and expects the consuming app to declare whatever it
  requests, same as the pattern already used here for `POST_NOTIFICATIONS`.
- **`permission_handler`** (`^13.0.1`) — added because `health` does not
  request `ACTIVITY_RECOGNITION` itself (confirmed against its README and
  community reports); nothing already in the project exposes a plain Android
  runtime-permission request, and writing a custom `MethodChannel` for it
  would just re-implement what this package already handles across OS
  versions. See "Android permission flow is two runtime prompts" above.
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

The `ACTIVITY_RECOGNITION` fix above was diagnosed from a real device's
symptoms (system settings showing "Physical activity"/"Fitness and wellness"
ungranted despite tapping Allow) but, same as everything else in this list,
implemented and tested without one — confirm on a real device that
`requestPermission()` now shows *two* system prompts in sequence and that
`hasStepsPermission()` reads `true` afterward, not just that the code
compiles and the mocked-adapter tests pass.

Every line of this module's own logic is covered except the lines that
structurally *require* a real device or a real file to run at all — these
are the same kind of gap as the health plugin itself, not oversights:

- `steps/data/health_adapter.dart` (0%) — `HealthPackageAdapter`, the real
  `health`-package wrapper. Never touched by a test, by policy (`testing`
  skill: never the real health plugin in a test). `hasActivityRecognitionPermission()`/
  `requestActivityRecognitionPermission()` (the `permission_handler` wrapper
  added for the two-runtime-prompts fix above) fall in the same excluded set
  for the same reason — real plugin, not unit-testable.
- `steps/presentation/steps_providers.dart`: `healthAdapterProvider`'s body
  (constructs the real `HealthPackageAdapter()`) — same reason. Also
  `refreshStatus()`'s `if (Platform.isAndroid)` branch — `Platform.isAndroid`
  reflects the machine actually running the test suite (Linux, here and in
  CI), not a simulated target, so this branch cannot be reached without
  refactoring the notifier to take an injectable platform check.
- `data/drift/database.dart`: the hand-written `SelectedQuestRows`/
  `StepIntervalRecords` column getters (`text()()`, `dateTime()()`, …) are
  read once by `drift_dev`'s builder at codegen time — they're schema
  declarations, not code that runs when the app does, so "0% coverage"
  there doesn't mean anything is untested. `_openConnection()`'s body (the
  real, file-backed `LazyDatabase` using `path_provider` and
  `sqlite3.tempDirectory`) is the file-I/O counterpart to the health-plugin
  gap above — untestable without touching a real filesystem through a
  platform channel, which unit/widget tests must not do.

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

Engine: `test/features/steps/data/steps_sync_engine_test.dart` covers
`StepsSyncEngine.sync()` directly against a mocked `HealthAdapter` and a
real in-memory `AppDatabase`-backed `StepSampleRepository` — realistic vs.
implausible pace, platform-distance preference over steps×stride, duplicate
intervals, and the non-decreasing clamp. This is what both `StepsSync.sync()`
and the Android background task (`lock-screen.md`) actually run.

Provider-level: `test/features/steps/presentation/steps_providers_test.dart`
exercises `StepsSync.sync()` end to end against a mocked `HealthAdapter`
and an in-memory `AppDatabase` — a realistic pace leaves `lastSyncFlagged`
false, an implausible one (a huge step count over a short
`lastSyncedAt`-to-now window) sets it true, and **either way the distance
is credited to `selectedJourneyProvider`** (the test that would have caught
`isImplausiblePace` being unwired); another proves the Phase 3 durability
claim directly — after a sync, reloading via `progressRepositoryProvider`
(what a restarted app's `build()` does) matches what was just credited in
memory; another proves a *genuine* duplicate interval (pre-recorded before
`sync()` runs, as a concurrent background/foreground sync would) is not
credited twice by `sync()` itself, not just by the repository it calls.
Two further groups cover `StepsSync`'s permission-flow methods through the
real class — `build()`/`refreshStatus()` (unknown → notRequested,
auto-sync when already granted) and `requestPermission()`/
`openHealthConnectInstall()` (on a fixed-`build()` fake, so the real
`build()`'s own background `refreshStatus()` microtask can't race these
tests) — previously only exercised via fakes that skipped this logic
entirely. That second group also covers the `ACTIVITY_RECOGNITION` fix: a
denied "Physical activity" prompt stops `requestPermission()` before Health
Connect is ever asked (`requestStepsPermission()` unstubbed and unverified,
proving it's never called), and a `Completer`-controlled test proves
`refreshStatus()` is a no-op while `requestPermission()` is still suspended
mid-`await` — the resume-races-the-request scenario described above.

`test/features/steps/presentation/permission_gate_test.dart` (new — none
existed before) covers all five `StepsPermissionGate` render states
(`unknown`, `notRequested`, `denied`, `healthConnectMissing`, granted with
and without a flagged-pace notice) plus tapping each card's button, proving
the gate is wired to the real `requestPermission()`/
`openHealthConnectInstall()` methods, not just rendering static text.

`test/features/journey/presentation/journey_providers_test.dart` (new)
covers `SelectedJourney.build()`'s restore branch directly: a database
populated *before* a provider container exists (simulating a real app
restart — same disk, fresh Riverpod graph) is correctly restored into
`selectedJourneyProvider`, and a container with nothing persisted stays
`null` rather than getting stuck. (`selectedJourneyProvider` is
`autoDispose` — these tests keep a listener attached, or the in-flight
restore has nothing keeping it alive to land its result.)

`test/app/database_provider_test.dart` (new) covers `appDatabaseProvider`'s
real, non-overridden body — every other test overrides it, so this was
otherwise never exercised — without touching the filesystem, since
`AppDatabase()`'s connection is lazy and this test never runs a query.

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

`test/features/journey/presentation/journey_tab_test.dart` (see
[`journey.md`](journey.md)) additionally exercises the `granted` and
`denied` states of `permission_gate.dart` in the context of the whole Путь
tab, overriding `stepsSyncProvider` directly with a fixed `_FixedStepsSync`
fake rather than touching the real `health` plugin.
