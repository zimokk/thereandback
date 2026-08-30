/// Selectable app visual "flavor" (CLAUDE.md §6.5, §9, §14 — "добавь темы").
///
/// This is **not** a light/dark switch — §9 keeps a single dark palette,
/// that rule is unchanged. A theme here only picks which setting-specific
/// content flavor the app leans into (currently: how the Друзья empty state
/// reads, §6.4) — every screen still uses the one dark/gold design system in
/// `design/`. Each catalog `Journey` declares which theme matches its
/// setting (`journey_catalog.dart`); Настройки (§6.5) lets the user pin a
/// specific one instead of following the active quest.
///
/// Pure Dart, no Flutter import — `features/journey/domain/journey.dart`
/// references this and domain/ may not import `package:flutter/*` (§4).
enum AppThemeId {
  /// The setting-agnostic base look — used before a quest is selected, and
  /// for any future non-Odyssey quest until it gets its own themed flavor
  /// (§14: the original fantasy world's name/regions are still undecided).
  classic,

  /// The Odyssey-flavored skin (`assets/journeys/odyssey-ithaca/`) — Greek/
  /// nautical touches, most visible in the Друзья empty state illustration.
  odyssey,
}
