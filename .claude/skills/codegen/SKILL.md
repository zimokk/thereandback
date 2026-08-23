---
name: codegen
description: Run or debug code generation in There and Back — build_runner, freezed, json_serializable, riverpod_generator, drift, gen-l10n. Use when models or providers change, when *.g.dart / *.freezed.dart are stale or conflicting, or when analyze fails with missing generated symbols.
---

# Code generation

Four generators run through `build_runner`: `freezed`, `json_serializable`, `riverpod_generator`, `drift` (§3). Localization uses `gen-l10n` separately.

## Command

```bash
dart run build_runner build --delete-conflicting-outputs
```

Use `watch` instead of `build` during a long editing session. Run it after touching any of:

- a `@freezed` model or its `fromJson`
- a `@riverpod` provider
- a drift table, DAO or database class
- an ARB file → `flutter gen-l10n`

## Rules

- **Never hand-edit `*.g.dart` or `*.freezed.dart`** (§11). If a generated file is wrong, the annotated source is wrong.
- Generated files are committed alongside their source, in the same commit — a diff where the model changed but the generated file did not will fail CI.
- Generation runs **before** `flutter analyze` and `flutter test` in the pre-commit gate (§10).

## Common failures

| Symptom | Cause / fix |
|---|---|
| `Could not find part '…g.dart'` | missing `part 'x.g.dart';` — add it, rerun |
| Conflicting outputs | rerun with `--delete-conflicting-outputs` |
| Provider symbol not found | `@riverpod` on a private function, or the file is not under `lib/`; check the annotation and path |
| Stale output after a rename | `dart run build_runner clean` then build |
| `fromJson` missing | add `json_serializable` annotation / `factory X.fromJson` to the freezed class |
| Drift migration test fails | schema changed without a `schemaVersion` bump + migration step (§12, Phase 3) |

## Boundaries (§4)

`domain/` entities are pure Dart — freezed there must not pull Flutter, Firebase or `health` in. Firestore DTOs are **separate generated types** from domain entities; the mapping between them is handwritten code in `data/`, not a generator shortcut.

## After generating

```bash
dart format . && flutter analyze && flutter test
```
