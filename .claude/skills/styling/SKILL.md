---
name: styling
description: Style anything in There and Back — colors, typography, spacing, icons, theme, or a design-system component in lib/design/. Use when the user asks about look and feel, "стилизуй", asks for a palette or font decision, or when a widget needs visual polish. Encodes the dark/gold antiquarian design language from CLAUDE.md §9.
---

# Styling

The visual language is fixed by §9. It lives in `lib/design/` — **never** in a feature widget.

## Tokens

Everything comes from `lib/design/`:

- `colors.dart` — named semantic tokens, not raw hex at call sites.
- `typography.dart` — named text styles.
- spacing / radii / stroke widths — named constants, no magic numbers in widgets.
- reusable components (buttons, cards, stat blocks, tab icons) — one place, reused.

A feature widget that writes `Color(0xFF…)`, `TextStyle(fontSize: 34)` or `EdgeInsets.all(13)` is wrong: add or reuse a token instead.

## Palette (§9)

| Role | Value |
|---|---|
| Background | near-black `#000000` … `#0B0B0D` |
| Cards / app bars | `#1B1B1E` |
| Accent — warm gold | ≈ `#E0AE3F` |
| Primary text | muted white `#EDE7DA` |
| Secondary text | primary at 60 % opacity |

Gold is for **numbers, active icons and buttons** — it is an accent, not a fill. **Dark theme is the only theme; there is no light theme.** Do not add `ThemeMode.light`, do not branch on `MediaQuery.platformBrightness`.

## Type (§9)

- One antiquarian serif with a fantasy character across the whole app — headings, distances, body, everything.
- Narrative lines: the same serif, *italic*.
- Distance numbers: large, gold. The unit label is a **separate, smaller line beneath the number** (§5.4) — never `5.23 km` on one line.
- **License: public domain / free (OFL-style) only — never a paid embedding license** (§9, resolved 2026-08-23). The exact family is still unpicked (§14) — before adding one, verify its license; "looks old" is not a check.
- Register the font in `pubspec.yaml`; no runtime font downloads (offline-first, §8).

## Iconography (§9)

Thin line icons, gold, uniform stroke width, one family across the five tabs. The active tab is highlighted. If an icon is missing from the set, draw it to match the stroke weight rather than importing a second icon pack.

## Art direction (§9)

- Silhouettes: flat solid fills, **no gradient inside an object**.
- Gradients only in the sky (procedural, driven by the user's real time of day — §6.1).
- Layers are distinguished by **lightness, not detail**.
- Layer palettes shift with time of day; keep the shift in one place so biomes stay consistent.
- Parallax layers must tile seamlessly horizontally (§9.1) or `ParallaxComponent` shows a seam.

## Numbers in the UI (§5.4)

Always through `core/formatters.dart`:

- `< 1 000 m` → whole meters — `196 meters`
- `1–100 km` → two decimals — `5.23 kilometers`
- `> 100 km` → whole — `2853 kilometers`

Domain stays integer meters; formatting is presentation-only.

## Tone

Numbers are wrapped in journey language (§1): "День 5 · 5.23 kilometers · Halfling Country" — not fitness metrics. Never surface a raw step count as the hero number.

## Before finishing

- `flutter analyze` clean, `dart format .` applied.
- Grep the diff for hardcoded visuals: `grep -nE 'Color\(0x|fontSize:|EdgeInsets\.(all|symmetric)\([0-9]' -r lib/features`
- Check contrast of secondary text (60 % on near-black) at the smallest size you used.
