---
name: commit
description: Stage and commit changes in There and Back. Use whenever the user asks to commit, "закоммить", save work to git, or create a feature branch for a change. Runs the mandatory pre-commit gate (format/analyze/test) and enforces the repo's commit conventions.
---

# Commit

Commit workflow for this repo. Rules come from `CLAUDE.md` §10 (commands) and §11 (conventions).

## 1. Look before you commit

```bash
git status --short
git diff --stat
git branch --show-current
```

- **Never commit on `main`.** Feature branches only, branched from `main`: `feat/…`, `fix/…`, `docs/…`, `chore/…`, `refactor/…`, `test/…`.
  If you are on `main` with changes: `git switch -c <type>/<short-slug>` first.
- **One PR — one feature** (§11). If the working tree mixes unrelated changes, commit them separately (`git add -p` / per-path `git add`) instead of one blob commit.
- Commit or push **only when the user asks**.

## 2. Pre-commit gate — mandatory

`CLAUDE.md` §10: everything green before a commit.

```bash
dart format .
flutter analyze
flutter test
```

Run codegen first if any `freezed` / `riverpod` / `drift` / `json_serializable` source changed (see the `codegen` skill):

```bash
dart run build_runner build --delete-conflicting-outputs
```

If a step fails: **fix the cause, do not commit.** Never use `--no-verify`. Report failures to the user with the actual output rather than working around them.

Skip only the steps that cannot apply — e.g. before Phase 0 there is no Flutter project yet, so a docs-only change has nothing to analyze. Say so explicitly instead of silently skipping.

## 3. What must never be committed

- `.env`, any secret, any Firebase service-account key (`.gitignore` covers `.env*`, keep it that way).
- Generated files edited by hand — `*.g.dart`, `*.freezed.dart` are generated, never hand-patched (§11).
- Real health data, coordinates, user identifiers in fixtures or test data (§13).

## 4. Message format

Conventional Commits, **in English** (§11 — code, comments, names and commits are English; Russian only in `l10n/` and `CLAUDE.md`).

```
<type>(<scope>): <imperative summary, <=72 chars>

<why, wrapped at 72 — optional but preferred for non-trivial changes>
```

- `type`: `feat` `fix` `docs` `refactor` `test` `chore` `perf` `build` `ci`
- `scope`: the feature or layer touched — `journey`, `steps`, `quest_map`, `achievements`, `friends`, `profile`, `design`, `domain`, `data`, `l10n`, `journeys` (content).
- Body explains **why**, not a restatement of the diff.
- Reference spec sections when the change implements one: `Implements CLAUDE.md §5.3.`

Examples from this repo's history: `feat(journeys): add Odyssey: Troy to Ithaca quest content`, `docs: allow public-domain settings alongside original fantasy`.

## 5. Commit

Use a heredoc so the message keeps its line breaks, and always append the trailers:

```bash
git commit -m @'
feat(journey): add quest-day and pace calculation

Day counting uses local calendar dates, not millisecond division,
so a DST shift cannot skip or repeat a quest day.
Implements CLAUDE.md §5.3.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
'@
```

(Bash tool: use a normal `<<'EOF'` heredoc instead. PowerShell here-strings need `'@` at column 0.)

Then `git status` to confirm the tree is clean, and report the commit hash and subject to the user.
