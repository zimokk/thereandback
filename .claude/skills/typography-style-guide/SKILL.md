---
name: typography-style-guide
description: Enforce the "one font for the whole app" rule (CLAUDE.md §9) whenever a change touches lib/design/typography.dart, app/theme.dart, or adds a TextStyle/fontFamily anywhere in lib/. Use before adding a second font family, a per-widget font override, or any text style that bypasses AppTypography. Also load when asked to unify, audit, or fix app-wide font/typography consistency.
---

# Typography style guide

CLAUDE.md §9 says it in five words: **«Один шрифт на всё приложение»** — one
font family, for every text style, app-wide. No exceptions carved out for
"just the headings" or "just the body text." This skill exists because that
rule was violated once already, silently: a past change split
`AppTypography` into a serif family (headings/numbers/narrative) and a
sans-serif family (body/labels) for legibility reasons that were real, but
the change was never written back into CLAUDE.md §9 — so the code and the
spec quietly disagreed until a user noticed and asked for a fix (2026-08-31,
CLAUDE.md §14). Full account of what happened and why:
`docs/design/typography-style-guide.md`.

## The rule, mechanically

- **One font family constant.** `lib/design/typography.dart`'s
  `AppTypography.fontFamilyPlaceholder` is the *only* font family literal
  in the app. Every `AppTypography.*` `TextStyle` sets
  `fontFamily: fontFamilyPlaceholder`. `app/theme.dart`'s
  `ThemeData.fontFamily` reads the exact same constant — never a second
  string literal (`'sans-serif'`, `'serif'`, anything) written out again.
- **No feature widget sets `fontFamily`.** Text styling in a feature widget
  goes through an `AppTypography` token (`styling` skill's own rule) or,
  when a new named style is genuinely needed, a new constant added to
  `typography.dart` — never a local `TextStyle(fontFamily: ...)` in
  `lib/features/`.
- **The one narrow exception:** painting a `MaterialIcons` glyph onto a
  `Canvas` via `TextPainter` (`quest_map_view.dart`'s landmark icons use
  `icon.fontFamily`/`icon.fontPackage`) — that's the icon's own font, not
  app text, and isn't part of this rule.

Verify before committing a typography change:

```bash
grep -rn "fontFamily" lib/ --include="*.dart" | grep -v lib/design/typography.dart
```

Every hit should be either `app/theme.dart` reading
`AppTypography.fontFamilyPlaceholder`, or an `icon.fontFamily`/
`icon.fontPackage` glyph-painting call. Anything else is a second family
sneaking back in.

## If you actually need a second family

Maybe a real, licensed font gets picked (Phase 1, CLAUDE.md §14) and it
turns out illegible at 14–15px body-text sizes — that's a legitimate reason
to reconsider, not a reason to just add a second `fontFamily` string and
move on. If that happens:

1. Say so in words first (CLAUDE.md §13's own rule for a stack/design choice
   you think is wrong) — this is a design-system decision, not a
   drive-by fix.
2. If the user agrees, change **both** `CLAUDE.md §9`'s font paragraph and
   `typography.dart`/`docs/design/typography-style-guide.md` in the same
   commit. The bug this skill guards against was exactly a code change that
   didn't update the spec next to it.
3. Prefer solving it inside the *one* family first — a lighter weight or
   larger size for small body text — before reaching for a second family at
   all.

## Scope note

This skill is narrower than the `styling` skill on purpose: `styling`
covers the whole design system (colors, spacing, icons, art direction);
this one only guards the font-family rule, because that's the specific
thing that already drifted once. Load both when the task is "restyle a
screen"; this one alone is enough for "does this change respect the
one-font rule."
