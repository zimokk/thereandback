# Typography style guide — one font for the whole app

Governs `lib/design/typography.dart` and `lib/app/theme.dart`. Referenced
from CLAUDE.md §9 and enforced by the `typography-style-guide` skill —
read that skill first if you're here to make a change, not just to
understand the history.

## The rule

CLAUDE.md §9: *"антиквенный serif с фэнтезийным характером для заголовков и
цифр; нарратив — тот же serif курсивом. **Один шрифт на всё приложение.**"*
One antiquarian serif, with fantasy character, for the whole app — headings,
distance numbers, narrative text, and ordinary UI copy (labels, body text,
descriptions) alike. Not "serif for the atmospheric bits, sans for the
rest" — the line "один шрифт на всё приложение" is explicit and was never
qualified.

The concrete font family itself is still unpicked (§9, §14 — Phase 1,
public-domain/OFL license required, verified before embedding — "looks old"
is not a check). Until then, every `AppTypography` style falls back to one
placeholder value, `AppTypography.fontFamilyPlaceholder = 'serif'`, so
picking the real family later means changing exactly one string.

## What happened (2026-08-27ish – 2026-08-31)

At some point, `typography.dart` grew a second font family: a
`_sansFontFamilyPlaceholder` used for `label`/`body`/`bodySecondary`,
alongside `_serifFontFamilyPlaceholder` for `distanceHero`/`distanceUnit`/
`heading`/`narrative`. `app/theme.dart`'s `ThemeData.fontFamily` was set to
`'sans-serif'` directly, as its own separate literal. The code comment at
the time called this a "styling fix": an all-serif UI reads atmospheric to
the point of hurting legibility for ordinary body text, so ordinary UI copy
was moved to a generic sans-serif placeholder and only headings/numbers/
narrative kept the serif.

That reasoning isn't wrong on its face — small serif body text genuinely can
be harder to read than sans at the same size, depending on the face. The
problem is procedural: **the change was made only in code.** CLAUDE.md §9
was never updated to say "two font families, split this way" — it kept
saying, unqualified, "один шрифт на всё приложение." So for a while the
actual design system (§9, the project's own documented source of truth) and
the actual code disagreed, and nothing caught it until a user reviewing the
Settings screen asked directly: *"шрифты изменены на шрифты с засечками?"*
(were the fonts changed to serif?), then *"Унифицируй по всему приложению в
соответствии со стайлгайдом"* (unify across the whole app per the style
guide) — pointing at exactly the gap between what §9 said and what the code
did.

**Resolved 2026-08-31 (CLAUDE.md §14):** the split was reverted.
`typography.dart` now has one public constant,
`AppTypography.fontFamilyPlaceholder`, used by every style in the file;
`app/theme.dart` reads that same constant for `ThemeData.fontFamily` instead
of its own hardcoded `'sans-serif'` literal. Code and CLAUDE.md §9 agree
again.

## Why this doc (and the skill) exist

Not to relitigate the legibility concern — it may well be real once an
actual font is chosen — but to make sure the *next* time someone considers
a second family, it isn't another silent code-only split. The skill's own
checklist (a `grep` for stray `fontFamily` literals, and the "say it in
words, update §9 in the same commit" process) is the actual guard; this
file is the "why," kept next to the skill rather than folded into
`typography.dart`'s doc comment so the full story survives even if that
comment gets trimmed later.

## Where things live

| What | Where |
|---|---|
| The one font family constant | `AppTypography.fontFamilyPlaceholder` (`lib/design/typography.dart`) |
| Every named text style | Same file — `distanceHero`, `distanceUnit`, `heading`, `label`, `body`, `bodySecondary`, `sectionLabel`, `narrative` |
| App-wide `ThemeData` default | `lib/app/theme.dart`'s `buildAppTheme()` — reads `AppTypography.fontFamilyPlaceholder` |
| The governing rule | `CLAUDE.md` §9 (font bullet) and §14 (2026-08-31 dated entry) |
| This history + rationale | This file |
| The enforcement checklist | `.claude/skills/typography-style-guide/SKILL.md` |

## The one legitimate exception

`quest_map_view.dart` paints landmark glyphs directly onto a `Canvas` via
`TextPainter`, using `icon.fontFamily`/`icon.fontPackage` from a
`MaterialIcons` `IconData`. That's rendering an icon glyph, not app text —
it was never part of the "one font for text" rule and isn't affected by any
of the above.
