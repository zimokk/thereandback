/// Placeholder identity for the local drift store (CLAUDE.md §8, §13) until
/// Phase 8 wires Firebase Auth's anonymous `uid`. Every persisted row today
/// belongs to this single constant — one device, one implicit local user,
/// no multi-account support and no sign-in flow to produce a real id yet.
///
/// Swapping this for the real Firebase `uid` at Phase 8 is a data-layer
/// change only: `domain/` and `presentation/` never reference this constant
/// directly, only the repositories in `data/` do.
const String localOwnerId = 'local-device';
