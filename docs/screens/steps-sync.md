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
| `steps/data/step_counting_service.dart` | data | `StepCountingService` interface + shared types + the `HealthPackagePedometer` mixin both platform classes use, including the background-permission pair used by `lock-screen.md` |
| `steps/data/android_step_counting_service.dart` | data | `AndroidStepCountingService` — Health Connect via the `health` package. Shipped, no account gate (see the architecture plan this split came from). |
| `steps/data/ios_step_counting_service.dart` | data | `IosStepCountingService` — **temporarily** Core Motion (`CMPedometer`, via a first-party `MethodChannel`, not a pub package — see below) instead of HealthKit: HealthKit needs a paid Apple Developer Program membership CMPedometer doesn't (§3, §7, CLAUDE.md §14). TODO in the file itself covers migrating back. |
| `steps/data/ios_pedometer_channel.dart` | data | `IosPedometerChannel` — thin wrapper over the `com.zimokk.thereandback/pedometer` `MethodChannel`, the Dart half of `ios/Runner/AppDelegate.swift`'s `CMPedometer` handler. |
| `steps/data/step_sample_repository.dart` | data | `StepSampleRepository` + `DriftStepSampleRepository` — the idempotency log (see below) |
| `steps/data/steps_sync_engine.dart` | data | `StepsSyncEngine` — the fetch/resolve/record algorithm itself, no `Ref`; shared by `StepsSync.sync()` (below) and the Android background task (`lock-screen.md`) |
| `data/drift/database.dart` | data (shared, not steps-specific) | `AppDatabase`: `SelectedQuestRows` + `StepIntervalRecords` tables |
| `features/journey/data/progress_repository.dart` | data | `ProgressRepository` — derives `SelectedQuest` from the interval log |
| `steps/presentation/steps_sync_state.dart` | presentation | `StepsPermissionStatus` enum + `StepsSyncState` (freezed) |
| `steps/presentation/steps_providers.dart` | presentation | `createStepCountingService` (the one `Platform.isAndroid` switch in this feature), `stepCountingServiceProvider`, `stepSampleRepositoryProvider`, `StepsSync` notifier (permission flow; `sync()` now just builds a `StepsSyncEngine` and applies its result) |
| `steps/presentation/permission_gate.dart` | presentation | The three-state gate card |

## State — providers

| Provider | Shape | Notes |
|---|---|---|
| `stepCountingServiceProvider` | `StepCountingService` | Defaults to `createStepCountingService()` — `AndroidStepCountingService()` or `IosStepCountingService()` by platform. **Always override with a fake in tests** — never the real plugin in a widget test (`testing` skill). |
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

### `sync()` used to trust a stale caller-supplied total

Bug report: "если при загрузке приложения в базе данных шагов больше — то
выбираем большее значение". `StepsSyncEngine.sync()` computed its result as
`quest.progressMeters + deltaMeters`, where `quest` is whatever the caller
passed in — the foreground path (`StepsSync.sync()`) passes
`ref.read(selectedJourneyProvider)`, the in-memory `SelectedJourney` state.
That state can be genuinely stale relative to what `StepIntervalRecords`
(the "steps database") already has — most concretely, right after the
Android background-sync task (`android_background_sync.dart`) wrote new
intervals directly to the database while this app process wasn't running to
see them, before the foreground app's own state catches up. Trusting the
caller's total as the base for `clampNonDecreasing` meant it could win even
when it was the *smaller* of the two numbers.

`sync()` now re-derives its result from `StepSampleRepository
.totalResolvedMeters()` (new — the same `SUM(resolvedMeters)` query
`ProgressRepository.loadSelectedQuest()` already ran, now shared by both so
they can't quietly disagree) instead of `quest.progressMeters + deltaMeters`,
and still runs that through `clampNonDecreasing(quest.progressMeters,
dbTotal)` — the caller's own total is still the floor (progress genuinely
never goes backwards), but the database's fresher total wins whenever it's
the bigger one. Covered in `steps_sync_engine_test.dart` and
`steps_providers_test.dart`: a duplicate-interval case and a dedicated
"app-load" case where the database already has more than the caller's
`quest.progressMeters` believes.

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

`StepCountingService.hasActivityRecognitionPermission()` /
`requestActivityRecognitionPermission()` (via `permission_handler` — the
`health` package does not request this permission itself) wrap that OS
prompt. `StepsSync.requestPermission()` now requests it first and only asks
Health Connect for Steps/Distance if it was granted; a no-op grant on iOS,
which has no equivalent permission.

**Two denials, not infinite retries.** Android auto-treats a *second* denial
of the same dangerous permission as "don't ask again" (`USER_FIXED`,
Android 11+): a third call to the request API shows no dialog at all and
resolves straight back to denied, with zero UI — so a naive "Try again"
button would look broken from the third tap on. `requestActivityRecognitionPermission()`
returns a three-way `RuntimePermissionResult` (`granted` / `denied` /
`permanentlyDenied`), not a bool, so `requestPermission()` can tell the two
apart: `permanentlyDenied` routes to its own `StepsPermissionStatus`, whose
gate card offers `StepCountingService.openAppSettings()` (this app's OS settings
page — the only place left to grant it) instead of another request that
would never show anything.

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
applies from the moment of grant — `lastSyncedAt` seeding to the exact quest-
start moment (§5.2, changed 2026-08-27 from the earlier start-of-day seed) is
not blocked by this.

## Platform setup done here

- **iOS — HealthKit setup is done but currently disabled** (§3, §14: iOS is
  temporarily on CMPedometer, see below). `ios/Runner/Info.plist`'s
  `NSHealthShareUsageDescription` and `ios/Runner/Runner.entitlements`'
  `com.apple.developer.healthkit`/`com.apple.developer.healthkit.access`
  keys are both **commented out, not deleted** — restoring HealthKit (see
  `ios_step_counting_service.dart`'s TODO) is uncommenting them, not
  redoing the setup. Reason for disabling: leaving the HealthKit
  entitlement active blocks signing *any* iOS build without a paid Apple
  Developer Program membership — `CODE_SIGN_STYLE = Automatic` tries to
  enable that capability on the App ID regardless of whether the Dart code
  actually calls HealthKit, so a free/Personal-Team build would fail before
  ever reaching the health feature. `CODE_SIGN_ENTITLEMENTS = Runner/
  Runner.entitlements;` itself (all three Debug/Release/Profile
  configurations in `project.pbxproj`) stays wired either way — an
  entitlements file with everything commented out is a valid, capability-
  free entitlements file.
  **Still not done, either direction**: the Apple Developer portal side
  (the App ID needs the HealthKit capability enabled there too, via a paid
  account) — that's account configuration outside this repo.
- **iOS — CMPedometer setup, added for the temporary swap**:
  `ios/Runner/Info.plist`'s `NSMotionUsageDescription` added (Core Motion's
  own usage string — unrelated to `NSHealthShareUsageDescription` above).
  `ios/Runner/AppDelegate.swift` gained the `com.zimokk.thereandback/pedometer`
  `MethodChannel` (see above) — the only iOS-native file this touches; no
  new Xcode target, no `Info.plist` background-mode entries.
  **Not done, and cannot be done in this sandbox (no Xcode/CocoaPods)**:
  `ios/Podfile` does not exist yet in this repo — Flutter generates it on
  the first `pod install`/`flutter build ios`. Once it exists, its
  `post_install` block needs a `GCC_PREPROCESSOR_DEFINITIONS` entry
  enabling `permission_handler`'s `sensors` permission group —
  `'PERMISSION_SENSORS=1'` — per `permission_handler`'s own README
  (`https://github.com/Baseflow/flutter-permission-handler`, "iOS" setup
  section: the same file lists every other permission group's flag and
  Info.plist key, e.g. `PERMISSION_CAMERA`/`NSCameraUsageDescription`, in
  case another permission is ever added the same way). Without that flag,
  `Permission.sensors` calls silently do the wrong thing on iOS
  (unimplemented/always-denied, depending on the plugin version) even
  though `NSMotionUsageDescription` is present — the two are independent
  gates and both are required.
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
  Now also used for iOS's `Permission.sensors` (see `IosStepCountingService`)
  — one dependency covering the runtime-permission side of both platforms.
- **`CMPedometer` access is a first-party `MethodChannel`, not a pub
  package** (§3, §14). `health` doesn't cover this — on iOS it only wraps
  HealthKit, and Core Motion is a different framework entirely. The more
  popular `pedometer` package was considered and rejected on its own
  merits first: it only exposes a live step-count *stream* from whenever
  the app starts listening, with no way to query an arbitrary historical
  `[from, to)` range, so it can't answer "how many steps since
  `lastSyncedAt`" across an app restart the way this app's delta-sync
  model needs. `CMPedometer.queryPedometerData(from:to:)` is the one-shot
  historical query that actually fits — `cm_pedometer` (`^1.2.0`) wraps
  exactly that and was added first, but **broke CI**: `flutter pub get`
  failed with "The plugin `cm_pedometer` doesn't have a main class
  defined" — its own `pubspec.yaml` declares `androidPackage:
  com.hieutv.cm_pedometer` pointing at a Java/Kotlin class that doesn't
  exist in the published package. Flutter's plugin resolution checks every
  platform a plugin claims to support, not just the ones the app's own
  code touches — so this Android-side bug broke the build even though
  nothing here uses `cm_pedometer` on Android at all. Removed from
  `pubspec.yaml`.
  Replaced with `com.zimokk.thereandback/pedometer`: a plain
  `FlutterMethodChannel` registered in `ios/Runner/AppDelegate.swift`
  (holds one `CMPedometer()`, answers a `queryPedometerData` call with
  `{steps, distanceMeters}`), wrapped on the Dart side by
  `IosPedometerChannel` (`ios_pedometer_channel.dart`). Core Motion is a
  system framework — this needs no CocoaPods entry, so `ios/Podfile` is
  now only relevant for `PERMISSION_SENSORS` below, not for CMPedometer
  access itself.
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

**The CMPedometer swap is a level below that**: unlike the rest of this
document, it was written in a sandbox with no Dart/Flutter SDK at all — not
just no simulator/emulator, no `flutter analyze`/`flutter pub get` either.
This caveat was not theoretical: the first version of this swap added
`cm_pedometer` as a dependency, confirmed only against its pub.dev
documentation — and that package turned out to have a real, CI-breaking
bug (its Android plugin registration doesn't match its own file layout;
see above). It was caught by an actual `flutter pub get` run in GitHub
Actions CI, not by anything checkable in this sandbox. The replacement
(`ios/Runner/AppDelegate.swift` + `IosPedometerChannel`) avoids third-party
plugin registration entirely, but its own correctness — the exact
`CMPedometer.queryPedometerData(from:to:)`/`CMPedometerData` Swift API,
the `FlutterImplicitEngineBridge.applicationRegistrar.messenger()` channel
setup for this project's UIScene-based `AppDelegate`, and the
`MethodChannel` argument/result encoding on both sides — is likewise
confirmed only against documentation and public code samples, not a
compiled build. `permission_handler`'s `Permission.sensors` ↔
`NSMotionUsageDescription` mapping is the one piece here that *was*
cross-checked directly against `permission_handler`'s own README.
Treat `ios_step_counting_service.dart`, `ios_pedometer_channel.dart`, and
`AppDelegate.swift` as unverified until they've been built and run once on
a machine with Xcode.

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

- `steps/data/android_step_counting_service.dart`,
  `ios_step_counting_service.dart`, and `ios_pedometer_channel.dart` (0%
  each) — the real platform wrappers, one per platform (split out of a
  single `HealthPackageAdapter` by the architecture plan this session;
  `IosStepCountingService`'s internals later swapped from `health`/
  HealthKit to Core Motion, see above). Never touched by a test, by policy
  (`testing` skill: never the real health/motion plugin in a test).
  `hasActivityRecognitionPermission()`/
  `requestActivityRecognitionPermission()`/`openAppSettings()` (the
  `permission_handler` wrapper added for the two-runtime-prompts fix above)
  fall in the same excluded set for the same reason — real plugin, not
  unit-testable.
- `steps/presentation/steps_providers.dart`: `stepCountingServiceProvider`'s
  body (`createStepCountingService()`, constructing whichever of the two
  real services matches the platform) — same reason. Also
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
`stepsPermissionPermanentlyDeniedTitle`,
`stepsPermissionPermanentlyDeniedBody`, `stepsPermissionOpenSettings`,
`stepsHealthConnectMissingTitle`, `stepsHealthConnectMissingBody`,
`stepsHealthConnectInstall`, `stepsFlaggedPaceNotice`.

## Tests

Domain: `test/features/steps/domain/stride_test.dart` — the full §12
mandatory list for this module (platform-distance preference, monotonic
clamp on a negative delta, >250 steps/min flagged not dropped, threshold
boundary).

Engine: `test/features/steps/data/steps_sync_engine_test.dart` covers
`StepsSyncEngine.sync()` directly against a mocked `StepCountingService` and a
real in-memory `AppDatabase`-backed `StepSampleRepository` — realistic vs.
implausible pace, platform-distance preference over steps×stride, duplicate
intervals, and the non-decreasing clamp. This is what both `StepsSync.sync()`
and the Android background task (`lock-screen.md`) actually run.

Provider-level: `test/features/steps/presentation/steps_providers_test.dart`
exercises `StepsSync.sync()` end to end against a mocked `StepCountingService`
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
`openHealthConnectInstall()`/`openAppSettings()` (on a fixed-`build()` fake,
so the real `build()`'s own background `refreshStatus()` microtask can't
race these tests) — previously only exercised via fakes that skipped this
logic entirely. That second group also covers the `ACTIVITY_RECOGNITION`
fix: a plain-`denied` prompt stops `requestPermission()` before Health
Connect is ever asked (`requestStepsPermission()` unstubbed and unverified,
proving it's never called), a separate case does the same for
`permanentlyDenied` and asserts the distinct `StepsPermissionStatus`, and a
`Completer`-controlled test proves `refreshStatus()` is a no-op while
`requestPermission()` is still suspended mid-`await` — the
resume-races-the-request scenario described above.
`permission_gate_test.dart` covers the `permanentlyDenied` card rendering
("Open settings", no "Try again") and that tapping it calls
`openAppSettings()` without ever calling `requestActivityRecognitionPermission()`
again.

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
