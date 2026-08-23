## Summary

<!-- One feature per PR (CLAUDE.md §11). What does this change, and why? -->

## Checklist

- [ ] `dart format . && flutter analyze && flutter test` all green locally (CLAUDE.md §10)
- [ ] No hardcoded UI strings — new copy goes through `l10n/` (§11)
- [ ] `domain/` stays free of `package:flutter`, Firebase, and `health` imports (§4, §13)
- [ ] Touches permissions, privacy, or the Firestore schema? Plan posted before code (§13)
- [ ] `*.g.dart` / `*.freezed.dart` not hand-edited
