# Feature: Persistent lock-screen / notification-shade progress

Not a tab — an off-by-default toggle in Настройки (§6.5) that turns on an
ongoing Android notification showing quest progress, visible both on the
lock screen and when pulling down the notification shade. Implements
CLAUDE.md §7's "постоянное отображение прогресса на заблокированном
экране", which isn't its own phase in `docs/implementation-plan.md` — it
was added as a standalone, plan-first change (§13: new dependencies +
permissions require a plan before code) rather than folded into an existing
phase, since none of Phase 4–10 covers it.

**Android only in this slice.** iOS needs a Live Activity, which needs a
native Swift Widget Extension Xcode target — not something this repo's
tooling can safely add without Xcode open to verify the `project.pbxproj`
edit. Every seam below (`LockScreenChannel`, `LockScreenSnapshot`, the
controller) is written so an iOS follow-up only adds
`ios_lock_screen_channel.dart` behind the existing interface, not a
rewrite.

## What it does

1. Настройки shows the toggle only where `lockScreenSupportedProvider`
   returns `true` (`Platform.isAndroid` today — see
   `journey/presentation/lock_screen_controller.dart`).
2. Turning it on (`LockScreenController.enable()`) requests two OS
   permissions — `POST_NOTIFICATIONS` and Health Connect's background-read
   permission — and only turns the feature on if both are granted (§7:
   explain before asking, never a dead end on denial). Health Connect only
   grants the background-read permission once the base `READ_STEPS`/
   `READ_DISTANCE` permissions are already held — requesting it first fails
   even if the user taps "Allow" — so `enable()` checks/requests those first
   via the same `HealthAdapter.requestStepsPermission()` the Путь tab uses,
   in case this toggle is reached without ever visiting that tab.
3. If granted: registers the `workmanager` periodic background task
   ([below](#background-sync-workmanager)) and, if a quest is already
   active, shows the notification immediately.
4. While enabled, the controller listens to `selectedJourneyProvider` and
   keeps the notification in sync: a progress update calls
   `LockScreenChannel.update`, quest completion
   (`progressMeters >= totalMeters`, matching §6.1's "the scene goes
   static") calls `end()` and cancels the background task.
5. Turning it off (`disable()`) cancels the background task and clears the
   notification. It does not revoke the OS permissions — same as every
   other permission in this app, the system owns that.

## `LockScreenSnapshot` — what actually gets shown

`features/journey/domain/lock_screen_snapshot.dart`'s pure
`buildLockScreenSnapshot()` reduces the live quest to: `questDay` (reusing
`quest_time_service.dart`'s `QuestTimeService.questDay()`, so it never
drifts from the Путь tab's own counter), `progressMeters`/`totalMeters`,
and a `positionLabel`.

**`positionLabel` is a placeholder** — `"→ {pointB}"` — because
`Segment`/`Landmark`/`map.json` (§6.2, Phase 6/11) don't exist yet; there is
no real "where on the route" data to show. Swap this once that phase lands;
nothing else here depends on the shape changing.

## Android notification — `android_lock_screen_channel.dart`

`AndroidLockScreenChannel` wraps `flutter_local_notifications`:
`ongoing: true, autoCancel: false` so it survives backgrounding,
`NotificationVisibility.public` so it shows in full on the lock screen, and
`BigTextStyleInformation` for the three-line shape the design asked for —
`contentTitle` (the app name, "There and Back" — CLAUDE.md §14's fixed
brand name, not an l10n key, same literal `app/app.dart`'s `MaterialApp`
title uses), `bigText` (day + formatted distance, prominent), `summaryText`
(the position line, at the bottom).

**Not a foreground service.** `flutter_local_notifications`' Android
implementation can update an ongoing notification in place with a plain
`show()` call — there's no need to keep a service alive just to hold a
notification open, and doing so would add an always-on status-bar
indicator nobody asked for. `startForegroundService`/
`FOREGROUND_SERVICE_DATA_SYNC` were deliberately not used for this reason.

"Thin app name" (the design ask) has no real lever on stock Android
notification chrome — there's no font-weight knob exposed. The three-line
shape is built from what the platform template actually offers; the visual
weight contrast comes from the title being small/system-styled while
`bigText` is the prominent line, not from a chosen font weight.

Two drawable resources back this:
- `android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_notification_status.png`
  — a real alpha-mask silhouette (§9.1's first real art, not a placeholder
  anymore), derived from `assets/branding/notification_icon_source.jpg`: the
  source line art's dark pixels become opaque white, everything else
  transparent, at the 24dp status-bar-icon base size per density. Android
  re-tints whatever's opaque regardless of source color — no gradients, no
  color, a single flat silhouette — so this couldn't reuse the full-color
  launcher icon even if it wanted to. Replaced the old placeholder chevron
  vector (`drawable/ic_notification_status.xml`, deleted).
- `android/app/src/main/res/drawable/ic_launcher_notification.xml` — a
  `drawable`-type alias for `@mipmap/ic_launcher`, needed because
  `flutter_local_notifications` resolves bitmap/icon names only under the
  `drawable` resource type (`Resources.getIdentifier(name, "drawable", …)`
  — checked directly against the plugin's Java source, not assumed), so the
  mipmap launcher icon isn't reachable by name without this alias. This is
  what renders as the notification's large icon, on the right — now the
  real launcher artwork too (§9.1): `android/app/src/main/res/mipmap-*/ic_launcher.png`
  and `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`, both generated
  from `assets/branding/app_icon_source.png` at each required density/size.
  That source image already has rounded corners baked in — iOS re-applies
  its own corner mask on top of that, so the corners may read as slightly
  double-rounded there; worth a real device/simulator look before treating
  this as final. Android has no equivalent re-masking (no adaptive-icon XML
  in this project), so it's unaffected.

## Background sync — `workmanager`

`features/steps/data/android_background_sync.dart` registers a
`workmanager` periodic task (`AndroidBackgroundSync.register()`/`cancel()`,
called by the controller) at a 15-minute interval — Android `WorkManager`'s
own floor for periodic work. This is §7's background-sync mechanism,
decided and implemented for Android as part of this feature (the open
question in CLAUDE.md §14/§7 is now closed for Android; iOS's mechanism —
HealthKit background delivery / `BGTaskScheduler` — is still open, tied to
the same Live Activity follow-up).

The callback dispatcher (`androidBackgroundSyncCallbackDispatcher`, a
top-level `@pragma('vm:entry-point')` function `Workmanager().initialize()`
registers in `main.dart`) runs in a separate background isolate with no
widget tree and no running `ProviderContainer` — everything it needs is
constructed fresh: a new `AppDatabase()` connection (same on-disk file
`_openConnection()` always resolves to, per `steps-sync.md`), a real
`HealthPackageAdapter`, and a `StepsSyncEngine` — the exact same class
`StepsSync.sync()` uses in the foreground (see `steps-sync.md`). Both paths
write through the identical `(ownerId, journeyId, intervalStart)`
idempotency key, so a background tick and a later foreground sync of the
same interval can never double-credit distance. On success it rebuilds a
`LockScreenSnapshot` and calls `AndroidLockScreenChannel().update(...)`
directly — this path does **not** go through `LockScreenController` (there
is no running app to hold that state); it only reuses the same channel/
snapshot types.

**Known limitation, not a bug**: progress on the lock screen can lag real
steps by up to ~15 minutes while the app is closed, and aggressive OEM
battery managers can still kill the task early — both are inherent to
`WorkManager` periodic work, not something this feature's code can fix.

## Permissions

- `POST_NOTIFICATIONS` (Android 13+) and Health Connect's background-read
  permission (`android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND`)
  are both declared in `AndroidManifest.xml` and both requested together
  from `LockScreenController.enable()` — neither is useful alone for this
  feature, so there's one toggle, one explanation, one pair of prompts.
- `HealthAdapter` gained `hasBackgroundHealthPermission()`/
  `requestBackgroundHealthPermission()`, thin wrappers over the `health`
  package's own `isHealthDataInBackgroundAuthorized()`/
  `requestHealthDataInBackgroundAuthorization()` (both already `true` on
  iOS in the package itself — there's no equivalent gate there).
- Raw health data and geolocation never appear in the notification — only
  what's already shown in-app (day, distance, a coarse position label),
  consistent with §7's privacy rule.

## Health Connect missing/just-installed — the card used to lie

Two related gaps, both traced from a real device report where the card kept
saying "permission not granted" no matter what was actually granted:

- **Health Connect not installed at all.** Unlike the Путь tab's
  `StepsPermissionGate` (`steps_sync_state.dart`'s
  `StepsPermissionStatus.healthConnectMissing`), `LockScreenController`
  never checked `HealthAdapter.healthConnectAvailability()` before
  `enable()`/`refreshStatus()` went straight to requesting/checking
  permissions Health Connect had nowhere to grant. The result collapsed
  into a plain `denied`, sending the user back to a permission screen that
  didn't exist yet instead of telling them to install Health Connect.
  `LockScreenPermissionStatus` gained `healthConnectMissing` (mirroring the
  Путь tab's enum) — checked first in both `enable()` and `refreshStatus()`
  — and the Настройки card renders it as an install prompt
  (`lockScreenHealthConnectMissingBody` + a button calling the controller's
  new `openHealthConnectInstall()`, which just forwards to
  `HealthAdapter.openHealthConnectInstall()`, same as `StepsSync`'s).
- **Health Connect installed *after* this app's process already started.**
  The `health` plugin's native side only (re-)creates its Health-Connect-
  backed helper objects inside the handler for `getHealthConnectSdkStatus`
  — which `hasStepsPermission()`/`requestStepsPermission()` trigger as
  their own first step (via `_checkIfHealthConnectAvailableOnAndroid()`
  inside the `health` package), so they self-heal once Health Connect
  becomes available. `hasBackgroundHealthPermission()`/
  `requestBackgroundHealthPermission()` did not — they called straight into
  the native background-permission methods, which stayed silently
  uninitialized (swallowed to `false`, not thrown) for the rest of that
  process's lifetime if Health Connect wasn't installed yet when the app
  first launched. A user who installed Health Connect afterward, granted
  every permission it offered, and even fully restarted the app while it
  was still in that state would keep seeing "no access" — because the
  restart that would have fixed it needs to happen *after* Health Connect
  is installed, and nothing in the UI said so. `HealthPackageAdapter` now
  calls `_health.isHealthConnectAvailable()` (which triggers that native
  re-init) before both background-permission calls, closing the gap
  without requiring a special restart sequence to work around it.

## `enabled` is now durable — a cold restart used to forget it was ever on

`LockScreenState.enabled` is in-memory Riverpod state; the real notification
and the `workmanager` periodic task are OS-owned constructs that keep
running across an app restart on their own regardless. Before this, a fresh
`LockScreenController.build()` after a restart always started from
`enabled: false` no matter what the previous session had — so
`refreshStatus()`'s `if (state.enabled && !granted) revoke()` check could
never fire on a cold start: it had no way to know there was anything
running to revoke. A permission revoked while the app was closed (Health
Connect, Android app settings — both separate activities/apps) went
undetected until the user happened to open Настройки, at which point
`build()` ran again and (for the same reason) still started from
`enabled: false`.

`LockScreenPreferenceRows` (`data/drift/database.dart`, schemaVersion 2 —
see `test/data/drift/migration_test.dart` for the migration test this
change shipped with) and `LockScreenPreferenceRepository`
(`features/journey/data/lock_screen_preference_repository.dart`) persist the
flag, keyed on `ownerId` (same placeholder-until-Phase-8 pattern as
`SelectedQuestRows`, §8/§13). `enable()`, `disable()`, and the auto-revoke
path in `refreshStatus()` all write through it; `build()` reads it back
before running `refreshStatus()` for the first time (`_restoreThenRefresh()`
— folded into `refreshStatus()`'s own `isBusy` guard via an optional
`restoredEnabled` parameter, not a separate unguarded write, since a
build()-time restore racing an in-flight `enable()`/`disable()` call could
otherwise stomp whichever `state.enabled` write loses the race).

`LockScreenController` changed from `@riverpod` to
`@Riverpod(keepAlive: true)`, and `app/app_shell.dart` — the shell every tab
route is nested under — now unconditionally `ref.watch`es it. Both are
needed together: keeping the provider alive doesn't make it run *earlier*
on its own, so without the shell's eager watch this restore would still
only happen the first time the user opened Настройки, same gap as before.

## Platform setup done here

- **Android** (`android/app/src/main/AndroidManifest.xml`):
  `READ_HEALTH_DATA_IN_BACKGROUND` and `POST_NOTIFICATIONS` declared (the
  latter is also pulled in transitively by `workmanager_android`'s own
  manifest, but kept explicit here for the same reason `READ_STEPS`/
  `READ_DISTANCE` are — this app's manifest should say what it asks users
  for). `workmanager_android` also merges in `FOREGROUND_SERVICE`/
  `FOREGROUND_SERVICE_SHORT_SERVICE` and a `SystemForegroundService` entry
  automatically for its own expedited-work support; this feature doesn't
  use expedited work or a foreground service, so nothing extra was added
  for that here.
- **`lib/main.dart`**: `Workmanager().initialize(...)` called once at
  startup, gated to `Platform.isAndroid` — cheap and idempotent, safe
  before the feature is ever turned on; `AndroidBackgroundSync.register()`
  is what actually schedules work.
- **Not done**: anything iOS. No `NSSupportsLiveActivities` Info.plist key,
  no Widget Extension target, no `live_activities` (or equivalent)
  dependency — all deferred to the follow-up this doc keeps pointing at.

## Cannot be verified in this environment

Same constraint as `steps-sync.md`: no Android emulator here, so the actual
on-screen notification (layout, icons, lock-screen visibility) and the real
`workmanager` periodic firing were never seen running, only typechecked and
covered at the unit/provider level. `AndroidLockScreenChannel`'s
`flutter_local_notifications` calls are tested against a mock plugin, not
the real platform channel — by the same `testing`-skill policy that keeps
`HealthPackageAdapter` out of tests in `steps-sync.md`.

## l10n keys

`settingsLockScreenSectionTitle`, `settingsLockScreenToggleTitle`,
`settingsLockScreenToggleSubtitle`, `lockScreenPermissionExplainTitle`,
`lockScreenPermissionExplainBody`, `lockScreenPermissionAllow`,
`lockScreenPermissionDeniedBody`, `lockScreenPermissionMissingNotifications`,
`lockScreenPermissionMissingBackgroundHealth`,
`lockScreenHealthConnectMissingBody`, `lockScreenChannelName`,
`lockScreenChannelDescription`, `lockScreenBody`.

## Tests

- `test/features/journey/domain/lock_screen_snapshot_test.dart` —
  `buildLockScreenSnapshot`: day-counter reuse, the `positionLabel`
  fallback, zero progress, progress at/past `totalMeters`.
- `test/features/journey/data/android_lock_screen_channel_test.dart` —
  `start`/`update`/`end` against a mocked `FlutterLocalNotificationsPlugin`:
  the plugin initializes once across repeated calls, `update()`'s body
  carries the day and formatted distance, `end()` cancels by id.
- `test/features/steps/data/android_background_sync_test.dart` —
  `AndroidBackgroundSync.register()`/`cancel()` call the mocked
  `Workmanager` with the expected stable unique name (the callback
  dispatcher's own internals are exercised indirectly through
  `steps_sync_engine_test.dart` and `lock_screen_snapshot_test.dart`, not
  directly — it needs a real background isolate to run for real, which
  this environment can't provide).
- `test/features/journey/presentation/lock_screen_controller_test.dart` —
  the state machine against fake `LockScreenChannel`/`AndroidBackgroundSync`/
  `HealthAdapter`: enable with both permissions granted (registers
  background sync, shows the already-active quest), enable denied (stays
  off, never registers), a same-quest progress update (`update()`, not
  `start()` again), quest completion (`end()` + background-sync
  `cancel()`), and `disable()`. Extended for the durable-`enabled` fix
  above: `enable()`/`disable()` persist through
  `DriftLockScreenPreferenceRepository`; a fresh `build()` (a new
  `ProviderContainer` over a database pre-seeded with `enabled: true`,
  simulating a real restart, not just re-reading the same in-memory
  session) restores it and — when the mocked permission is now denied —
  runs the same revoke path `refreshStatus()`'s resume-triggered case
  already covered, proving it also fires from a cold start; a second case
  proves it leaves the feature alone when permission still holds.
- `test/features/journey/data/lock_screen_preference_repository_test.dart`
  (new) — `loadEnabled()`/`saveEnabled()` round-trip, defaulting to `false`
  for an owner nothing was ever saved for, a later save overwriting rather
  than adding a row, and per-owner isolation (§8, §13).
- `test/data/drift/migration_test.dart` (new) — the real drift schema
  migration test (§12) `app_database_test.dart` promised once
  `schemaVersion` moved past 1: v1 → v2 preserves a pre-existing
  `selectedQuestRows` row and leaves the new `lockScreenPreferenceRows`
  table usable, via `SchemaVerifier.testWithDataIntegrity` (drift_dev's
  schema-snapshot tooling — `drift_schemas/`, `test/generated_migrations/`,
  both committed). Runs with `validateColumnConstraints: false` and writes
  its v1 fixture via raw SQL rather than the generated v1 helper's typed
  companion — see that file's own top comment for why: `drift_dev schema
  dump` doesn't see this database's `storeDateTimeAsText: true` runtime
  option, so the generated helper models `DateTime` columns as plain `int`,
  a mismatch against this app's real `TEXT`-stored columns that has
  nothing to do with whether the migration itself is correct.
- `test/features/profile/presentation/settings_tab_test.dart` — extended:
  the toggle is hidden where `lockScreenSupportedProvider` is `false`
  (this suite's own host, Linux, by default) and renders off by default
  where it's overridden to `true`; and (for the Health-Connect-missing fix
  above) `healthConnectMissing` renders the install prompt instead of the
  plain-denial text, via a fixed-state `LockScreenController` fake —
  `enable()`/`refreshStatus()`'s own `Platform.isAndroid` guard around that
  branch can't be reached from this host, same limitation `steps-sync.md`
  documents for `StepsSync`'s equivalent check.
- `test/features/journey/presentation/lock_screen_controller_test.dart` —
  also extended: `openHealthConnectInstall()` delegates to the adapter
  (mirroring `StepsSync`'s own test for the same method).
- `test/features/steps/data/steps_sync_engine_test.dart` (see
  `steps-sync.md`) — the algorithm this feature's background task actually
  runs.
