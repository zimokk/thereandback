---
name: l10n
description: Add or change user-facing strings in There and Back — ARB files, localization keys, ru/en translations, plurals, number and date formatting. Use whenever UI text is added or edited, or when a hardcoded string needs extracting. CLAUDE.md §11 forbids string literals in UI.
---

# Localization

**No hardcoded strings in the UI** (§11). Every user-facing string goes through `lib/l10n/`. Languages: **`ru` and `en`** — both updated in the same commit, never one now and one later.

## Files

```
lib/l10n/app_en.arb    # template
lib/l10n/app_ru.arb
l10n.yaml              # generator config
```

Code language is English (§11). Russian appears **only** in `l10n/` strings and in `CLAUDE.md`.

## Adding a string

1. Add the key to `app_en.arb` with a `@key` description block explaining context for translators.
2. Add the same key to `app_ru.arb`.
3. Regenerate (`flutter gen-l10n`, or it runs as part of the build) and use `AppLocalizations.of(context)!.key` — never the literal.

Key naming: `<feature>_<element>_<meaning>`, e.g. `journey_anchor_start`, `map_eta_unknown`, `friends_request_pending`, `steps_permission_denied_title`.

## Plurals and interpolation

Use ICU syntax — Russian has `one/few/many/other`, so a naive `if (n == 1)` is wrong:

```json
"journey_day_counter": "{count, plural, one{День {count}} few{Дня {count}} many{Дней {count}} other{Дня {count}}}"
```

Never build a sentence by concatenating fragments — word order differs between ru and en.

## Numbers, dates, units

- Distances go through `core/formatters.dart` (§5.4) — the ARB gets the **unit label**, not the number formatting logic.
- The unit renders as a separate line under the number (§5.4, §9).
- Unit system (km / miles) is a user setting (§6.5) — the conversion is presentation-level; the domain stays in meters (§11).
- Dates (`Quest Started`, `Estimated Arrival`) use the locale's format, not a hand-rolled `dd.MM.yyyy`.
- ETA with zero pace renders a dash — give it its own key (§5.3).

## Narrative content is not UI strings (§11)

Quest narrative (`NarrativeBeat`) is **localizable content** authored per journey, written by a human — it belongs with the journey content (see the `journey-content` skill), not in `app_*.arb`, and it is never generated.

## Checks

```bash
grep -rnE "Text\(\s*'|Text\(\s*\"" lib/features       # literals that should be keys
flutter analyze && flutter test
```

Also verify: no key exists in one ARB and not the other, and the longest Russian strings do not overflow their layout (Russian typically runs ~15–30 % longer than English).
