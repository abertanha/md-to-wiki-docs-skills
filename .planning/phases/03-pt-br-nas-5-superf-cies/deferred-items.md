# Deferred Items — Phase 03

Items discovered during execution that are out of scope for the current
plan (pre-existing, unrelated to the task's own diff). Not fixed per the
SCOPE BOUNDARY rule; logged here for future cleanup.

## 03-03 — Tarefa 1: `shellcheck`/`shfmt` pre-existing divergence in `tests/regress.sh`

- **Found during:** Tarefa 1 (swagger-ui.html parametrizado + perna Swagger
  de `tests/regress.sh`)
- **Observation:** confirmed via `git show HEAD:tests/regress.sh` (pre-edit
  copy): `shellcheck` already reported two SC2015 info-level findings
  (`A && B || C is not if-then-else`, lines 112 and 169 of the original) and
  `shfmt -d` already reported a 276-line diff (2-space indentation vs
  shfmt's default tab/space rules) before any edit in this task — the same
  repo-wide condition documented for `scripts/generate-mkdocs.sh` and
  `tests/fail-closed.sh` in the 03-01 entries below. The new Swagger-leg
  code added in this task follows the file's existing 2-space convention,
  so it extends the same pre-existing diff shape rather than introducing a
  new one (confirmed: `shfmt -d` diff grew only by the added lines,
  reformatted in the same style as the surrounding, already-divergent code).
  One NEW shellcheck finding (SC2154, `swagger_title_suffix` referenced but
  not assigned) WAS introduced by this task's own diff and WAS fixed here —
  a `: "${swagger_title_suffix:?...}"` fail-closed guard was added before
  use, matching the `:?` idiom already used across the codebase, which
  shellcheck recognizes as a declaration and which silences the warning.
- **Decision:** Pre-existing SC2015/shfmt divergence not fixed — reformatting
  the whole file is an unrelated, large-surface change (violates "menor
  diff correto"). The new SC2154 caused by this task's own change was
  fixed, per SCOPE BOUNDARY ("only auto-fix issues directly caused by the
  current task's changes").
- **Recommendation:** same as the 03-01 entry below — a dedicated
  formatting-only plan should decide on and apply a repo-wide `shfmt`
  config across `scripts/*.sh` and `tests/*.sh`.

## 03-01 — Tarefa 3: `shfmt` pre-existing divergence in `tests/fail-closed.sh`

- **Found during:** Tarefa 3 (gate de paridade en↔pt-br e probes pt-br)
- **Observation:** same repo-wide 2-space-indent-vs-shfmt-default divergence
  as the item below, confirmed pre-existing via `git stash` (251-line
  `shfmt -d` diff present before any Tarefa 3 edit). `shellcheck
  tests/fail-closed.sh` exits 0 clean — only `shfmt` diverges.
- **Decision:** not fixed here, for the same reason as the item below. New
  code (`catalog_parity`, the `missing_key_halts` catalog_basename branch)
  follows the file's existing 2-space convention.

## 03-01 — Tarefa 2: `shfmt`/`shellcheck` pre-existing divergence in `scripts/generate-mkdocs.sh`

- **Found during:** Tarefa 2 (theme.language pt-BR condicional)
- **Observation:** `shfmt -d scripts/generate-mkdocs.sh` already reported a
  diff (2-space indentation style vs shfmt's default tab/space rules) and
  `shellcheck` already reported SC2018/SC2019 (info-level, `tr 'A-Z' 'a-z'`
  not using `[:upper:]`/`[:lower:]`) on the file as committed at the start
  of this plan (`git stash` verified: identical warnings/diff present
  before any edit in this plan). Confirmed the same condition exists on
  `scripts/generate-index.sh` (touched in Phase 2, plan 02-02) — this is a
  repo-wide style convention (2-space case/if bodies) that predates Phase 3
  and was never flagged in 02-01/02-02 SUMMARY.md either.
- **Decision:** Not fixed here — reformatting the whole file to satisfy
  `shfmt`'s default style is an unrelated, large-surface change (violates
  "menor diff correto" from `.claude/CLAUDE.md` and risks perturbing the
  byte-identical `en` golden via heredoc-adjacent indentation changes). The
  two new lines added in Tarefa 2 (`THEME_LANGUAGE` case statement) follow
  the file's existing 2-space convention for consistency, so they add to
  the same pre-existing diff shape rather than introducing a new one.
- **Recommendation:** A dedicated formatting-only plan (not part of a
  bugfix/feature) should decide on and apply a repo-wide `shfmt` config
  (e.g. `.editorconfig` with `shfmt -i 2 -ci`) across `scripts/*.sh` and
  `tests/*.sh` in one atomic, review-able commit.
