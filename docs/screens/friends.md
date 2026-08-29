# Screen: Друзья (Challengers)

Bottom tab 4 of 5 (§6.4). Route: **`/friends`**. Entry widget:
`ChallengersTab` (`lib/features/friends/presentation/challengers_tab.dart`).
Backed by Firebase Auth + Firestore (Phase 8) — the first screen in the app
that isn't purely local/drift.

## Auth, quietly, first

Firebase Auth's anonymous sign-in (§8) is silent and automatic
(`AuthController`, `lib/app/auth_provider.dart`) — it runs the moment
anything reads `currentUidProvider`, not specifically when this tab opens.
`ChallengersTab` also fires `ensureFriendProfileProvider` on build, which
creates a starter `users/{uid}` profile (a generated `Traveler-xxxxxx`
nickname, a preset avatar index) the first time a uid exists, so "add
friend by nickname" has something to find and be found by.

## What it shows

- **Your nickname card** — pinned above everything else, always visible:
  the caller's own nickname plus a copy-to-clipboard button
  (`_MyNicknameCard`). "Add friend by nickname" only works once a friend
  actually *has* the nickname to type in, and before this card the only
  place it appeared was the caller's own row further down the same table —
  easy to miss, and not copyable. Copying shows a confirmation `SnackBar`;
  the button is disabled while the nickname hasn't loaded yet (`—`
  placeholder instead of a blank).
- **Incoming requests** — a pending friendship where the caller is *not*
  the initiator (`Friendship.isIncomingPendingFor`). Accept or decline.
- **Outgoing requests** — a pending friendship the caller *did* initiate
  (`isOutgoingPendingFor`). Cancel only (no accept — you sent it).
- **The comparison table** — one row per accepted friend plus the caller's
  own row, always pinned first (§6.4) via `sortFriendRows`: pin color dot
  (`pinColorIndexForUid`, deterministic, never stored), nickname, current
  running-total distance, and a signed delta vs. the caller
  (`formatSignedDistance`) — skipped on the caller's own row. The own row
  is gold-bordered and suffixed "(You)"; friend rows get a small remove
  button.
- **Empty state** when there are no friends and no pending requests either
  direction.
- **Add friend** — the app-bar person-add icon opens a nickname dialog. If
  the session is still anonymous, submitting first runs the Google upgrade
  (`AuthController.upgradeWithGoogle`) before resolving the nickname. Every
  outcome (sent / nickname not found / that's your own nickname / already
  connected / upgrade cancelled / that Google account is already linked to
  someone else) surfaces as a `SnackBar`, one l10n string per
  `AddFriendOutcome` case.

## Firestore-enforced visibility, not just UI logic

`firestore.rules` is the actual boundary (§7, §8) — the client never trusts
its own checks:

- Nicknames/avatars (`users/{uid}`) are readable by any signed-in user —
  Bob must see Alice's nickname on his own incoming-request row before the
  friendship is even accepted.
- Progress (`users/{uid}/progress/{journeyId}`) is readable only by its
  owner, or by an **accepted** friend the owner hasn't hidden it from
  (`hiddenBy`). A friend the owner has hidden from is silently skipped when
  building the table (`friendsView`), not shown as a permission error.
- `friendships/{pairId}` creation, acceptance, the hide toggle, and
  deletion each have their own narrow allow condition — see
  `firebase/rules-tests/firestore.test.js` for the full allow/deny matrix,
  run against the real Firestore emulator, not a fake that skips rules
  entirely.

## Deliberately not built here

Scope calls made explicitly during planning (`floofy-hatching-allen` plan),
not oversights:

- **No deep-link invites.** Nickname only, this phase.
- **No day/week period toggle.** The table shows the running total only —
  it already updates "live" in the sense that it refreshes whenever the
  caller's own progress changes or the friend list changes (see below);
  there is no historical snapshot to diff against for a real windowed
  figure, so the toggle was dropped rather than faked.
- **No friend pins on the quest map (§6.2).** `quest_map`'s
  `metersToPoint` already has the math to place them; wiring it in is a
  fast-follow, not bundled into this phase.
- **No background (app-closed) progress push.** `StepsSync.sync()`
  (`features/steps/presentation/steps_providers.dart`) pushes to Firestore
  after every **foreground** sync only; the Android `workmanager` task
  doesn't yet initialize Firebase in its background isolate.
- **No permanent "blocked" status.** Remove/decline/cancel are all a plain
  reversible delete of the `friendships/{pairId}` doc — a fresh request can
  be sent from scratch afterward. `Friendship.status` is `pending`/
  `accepted` only this phase.
- **No photo avatars.** `avatarPresetIndex` indexes a small local
  preset/color palette — no `firebase_storage`, no upload/moderation
  surface.

## State — providers

All in `lib/features/friends/presentation/friends_providers.dart`:

- `myProfileProvider` — the caller's own `users/{uid}` doc, live.
- `ensureFriendProfileProvider` — the starter-profile bootstrap above.
- `friendshipsProvider` — every friendship (pending or accepted, either
  direction) involving the caller, a live Firestore stream.
- `friendsView` (`FutureProvider`) — composes the above plus each accepted
  friend's own profile/progress into one `FriendsViewData` (rows +
  incoming + outgoing). Deliberately a one-shot rebuild-on-dependency-
  change, not a fully reactive per-friend combine-latest: it recomputes
  whenever `friendshipsProvider`, `myProfileProvider`, or the caller's own
  `selectedJourneyProvider` changes — the same coarse "foreground sync"
  cadence the rest of the app already uses (§7), not a live subscription
  to every friend's every write. A friend who has hidden their progress
  from the caller is skipped rather than surfacing the resulting
  permission-denied read as an error.
- `FriendsController` — `addFriendByNickname`, `acceptRequest`,
  `removeOrDecline`, `setHidden`. All delegate to
  `data/firestore/friendship_repository.dart` /
  `data/firestore/user_profile_repository.dart`
  (`data/firestore/firestore_providers.dart` wires the repositories).

`app/auth_provider.dart`'s `currentUidProvider`/`authControllerProvider`
sit underneath all of the above; `features/steps/presentation/
steps_providers.dart`'s `StepsSync.sync()` is the other consumer of
`data/firestore/progress_sync_repository.dart` (the push side; this tab
only reads).

## Domain

- `features/friends/domain/friendship.dart`: `Friendship`, `pairIdFor`
  (sorted pair id — the same derivation `firestore.rules` uses),
  `pinColorIndexForUid` (FNV-1a over the uid — deterministic across
  platforms/SDK versions, unlike `String.hashCode`), `isIncomingPendingFor`/
  `isOutgoingPendingFor`.
- `features/friends/domain/friend_progress.dart`: `FriendProgressRow`,
  `friendDeltaMeters` (§5.3), `sortFriendRows` (own row pinned first).
- `features/friends/domain/friend_profile.dart`: `FriendProfile` — only
  the public nickname/avatar slice of a user, not the full CLAUDE.md §5
  `UserProfile` (stride length, privacy settings stay local/drift-owned).
- `core/formatters.dart`: `formatSignedDistance` — reuses `formatDistance`'s
  §5.4 precision rule on the magnitude, prefixes the sign.

## l10n keys

`navFriends`, `friendsTitle`, `friendsYouLabel`, `friendsAddButton`,
`friendsAddDialogTitle`, `friendsAddNicknameLabel`, `friendsAddSubmit`,
`friendsAddCancel`, `friendsMyNicknameLabel`, `friendsMyNicknameCopyTooltip`,
`friendsMyNicknameCopied`, `friendsPendingIncomingTitle`,
`friendsPendingOutgoingTitle`, `friendsIncomingRequestLabel` (`{name}`),
`friendsOutgoingRequestLabel` (`{name}`), `friendsAcceptButton`,
`friendsDeclineButton`, `friendsCancelRequestButton`, `friendsRemoveButton`,
`friendsEmptyTitle`, `friendsEmptyBody`, and one `friendsOutcomeXxx` string
per `AddFriendOutcome` case.

## Tests

`test/features/friends/domain/{friendship,friend_progress}_test.dart` —
`pairIdFor`, `pinColorIndexForUid` (deterministic, in-bounds),
`isIncomingPendingFor`/`isOutgoingPendingFor`, `friendDeltaMeters`,
`sortFriendRows`.

`test/data/firebase/auth_repository_test.dart`,
`test/data/firestore/{friendship,progress_sync,user_profile}_repository_test.dart`
— against `firebase_auth_mocks`/`fake_cloud_firestore` (repository logic
and DTO↔domain mapping only — these fakes don't evaluate Security Rules at
all; that's `firebase/rules-tests/` below).

`test/app/auth_provider_test.dart` — `AuthController` bootstrap and
`upgradeWithGoogle`'s three outcomes.

`test/features/friends/presentation/friends_providers_test.dart` —
`friendsView`'s composition (sorting, a hidden-friend row excluded,
pending split into incoming/outgoing) and `FriendsController
.addFriendByNickname`'s outcomes, all against mocked repositories.

`test/features/friends/presentation/challengers_tab_test.dart` — empty
state, a populated table with the own row pinned (now alongside the
pinned nickname card, so the caller's nickname renders twice on that
screen), an incoming request's accept button calling the repository, the
copy-nickname button copying and confirming, and the anonymous add-friend
flow triggering (and, on cancellation, short-circuiting) the Google
upgrade prompt.

`firebase/rules-tests/firestore.test.js` (Node.js, `@firebase/rules-unit-
testing`, run via `firebase emulators:exec --only firestore`) — the real
Security Rules allow/deny matrix, against the actual Firestore emulator.
