/// Identity for the local drift store (CLAUDE.md §5.2, §8) — every
/// persisted row keys on this single constant: one device, one local
/// profile.
///
/// This is **not** replaced by the Firebase uid Phase 8 introduces.
/// `signInAnonymously()` needs a network round-trip on a device's very
/// first launch, and CLAUDE.md §8 requires the app to work fully offline
/// from that first launch on — starting a quest can't wait on, or be keyed
/// by, a uid that doesn't exist yet without one. The constant already
/// correctly models "one local profile per device", which is all the MVP
/// ever needs (§6.4: no concurrent multi-quest, no multi-account). The
/// Firebase uid (`app/auth_provider.dart`'s `currentUidProvider`) is a
/// separate concept, used only by the Firestore-facing repositories in
/// `data/firestore/` (doc ids, `pairId` construction, the progress push
/// target) — it never becomes drift's `ownerId`.
///
/// Referenced directly from a few `presentation/` call sites too (e.g.
/// `journey_providers.dart`, `lock_screen_controller.dart`), not only from
/// `data/` repositories — there is exactly one local owner for the whole
/// app, so there is no meaningful "wrong" caller to guard against here.
const String localOwnerId = 'local-device';
