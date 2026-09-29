---
phase: 02-cat-logo-de-labels-cadeia-mkdocs-index
fixed_at: 2026-09-29T18:00:12Z
fix_scope: critical_warning
findings_in_scope: 5
fixed: 5
skipped: 0
iteration: 1
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-09-29T18:00:12Z
**Source review:** `.planning/phases/02-cat-logo-de-labels-cadeia-mkdocs-index/02-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope (critical_warning): 5
- Fixed: 5
- Skipped: 0

Verification: all fixes were applied and verified inside an isolated git worktree
(`.claude/worktrees/rf-02-94273-1790704386`, branch `gsd-reviewfix/02-94273`,
forked from `ft/gsd-pattern-align`). `bash tests/fail-closed.sh` and
`bash tests/regress.sh` were run after every fix and once more at the end with
all fixes applied together — both green (`fail-closed.sh` rc=0, `regress.sh`
rc=3 with the single expected `SKIPPED: pwsh not found` line and no `FAIL:`
lines). `shellcheck` and `shfmt -d` were run on every `.sh` file touched;
remaining shellcheck output (`SC2018`/`SC2019` on the `tr 'A-Z' 'a-z'` line)
and the `shfmt` diff (tabs vs. this project's 2-space style) are pre-existing
and unrelated to these edits — confirmed by diffing against the pre-fix
committed version of each file.

## Fixed Issues

### CR-01: `generated_by` catalog value used as printf format string, not argument — corrupts output on any `%` in catalog content

**Files modified:** `scripts/generate-index.sh`
**Commits:** `9f8c86b`, `259992a`
**Applied fix:** Moved the `%s`→date substitution out of `printf`'s format
string into a bash parameter expansion (`message="${generated_by_line/\%s/$today}"`),
so the outer `printf -- '---\n*%s*\n' "$message"` format string is now a
fixed, safe literal that can never be corrupted by catalog content. A second,
small follow-up commit (`259992a`) introduced an intermediate
`generated_by_line="${generated_by}"` assignment: the first pass wrote
`${generated_by/\%s/$today}` directly, which broke the project's own
`keyset_equality` fail-closed gate in `tests/fail-closed.sh` (that gate's
regex only recognizes bare `${key}` expansions, not parameter-expansion
substitutions) — caught during verification, fixed, and re-verified before
committing.
**Verified:** Reproduced the exact repro from the review
(`generated_by='Gerado 100% por [md-to-wiki] — %s'`) against the fixed
script — exits 0, emits `*Gerado 100% por [md-to-wiki] — 2026-09-29*`
correctly instead of aborting. `shellcheck` no longer flags SC2059 on this
line. `bash tests/regress.sh` and `bash tests/fail-closed.sh` both pass.

### WR-01: Feature-table labels corrupt under non-UTF-8 locale — no guard in the shipped script or its orchestrator

**Files modified:** `scripts/generate-index.sh`, `scripts/generate-mkdocs.sh`
**Commit:** `8db9fd6`
**Applied fix:** Added `export LC_ALL="${LC_ALL:-C.UTF-8}"` near the top of
both scripts (after `set -euo pipefail`, before catalog loading), matching
the fix text exactly as specified. This defaults the locale used by the
title-case `sed` pipeline to `C.UTF-8` whenever the caller has not
explicitly set `LC_ALL`, while still honoring an explicit caller override.
**Verified:** Reproduced the review's repro against the fixture directory
`tests/fixtures/tree/.specs/features/autenticação/`: with `LC_ALL`/`LANG`
unset (the realistic "host has no locale configured" scenario this finding
describes), the script now emits `Autenticação` correctly instead of
mojibake. Note for the record: if a caller *explicitly* exports
`LC_ALL=C` before invoking the script, that explicit choice is still
honored (by design, per the literal fix text — `${LC_ALL:-C.UTF-8}` only
substitutes when unset/empty) and mojibake can still occur in that specific
case; this is a known, intentional boundary of the exact fix requested, not
an oversight. `bash tests/regress.sh` and `bash tests/fail-closed.sh` both
pass.

### WR-02: `docs/chrome-inventory.md` still documents `templates/index.md` as present, but this phase deleted it

**Files modified:** `docs/chrome-inventory.md`
**Commit:** `7d4bf3d`
**Applied fix:** Struck the Camada 3 row for `templates/index.md` (marked
removed, referencing the `git rm` commit `37c87bd`) and rewrote the D-12
note to record the resolved decision (file removed because no consumer was
found; the Phase 2 catalog values were extracted from the scripts, not this
dead template).
**Verified:** Re-read the updated section; table column counts unchanged
(6 columns per row, confirmed via `awk -F'|'`), no other references to
`templates/index.md` remain misleading.

### WR-03: README structure diagrams weren't updated for the new `templates/lang/` catalog

**Files modified:** `README.md`, `README.pt-BR.md`
**Commit:** `4670906`
**Applied fix:** Added a `templates/lang/en.lang` entry (with a note that
`pt-br.lang` lands in Phase 3) to the `templates/` branch of the "Skill Set
Structure" tree diagram in both READMEs, ahead of the existing
`swagger-ui.html` entry.
**Verified:** Re-read both diagrams; tree connectors (`├──`/`│`/`└──`)
remain consistent and the block still renders as a valid tree.

### WR-04: No test exercises catalog-content robustness (the `%` and non-UTF-8-locale scenarios that produced CR-01/WR-01)

**Files modified:** `tests/fail-closed.sh`
**Commit:** `0ee3253`
**Applied fix:** Added two new gates:
1. `catalog_percent_value_safe` — sandbox-mutates `generated_by` to contain
   a bare `%` and asserts `generate-index.sh` exits 0 with the literal `%`
   preserved and the date substituted (this is the regression gate for
   CR-01; it would have caught that bug before it shipped).
2. `accented_name_survives_default_locale` — runs `generate-index.sh` with
   `LC_ALL`/`LANG`/`LC_CTYPE`/`LC_COLLATE`/`LC_MESSAGES` all unset (the
   realistic "no UTF-8 locale configured" host scenario) against the
   accented fixture directory and asserts the script's own default produces
   byte-correct `Autenticação` output (this is the regression gate for
   WR-01).

   Note on scope: the finding's suggested probe description said "under
   `LC_ALL=C`". Given the exact WR-01 fix applied
   (`${LC_ALL:-C.UTF-8}`, which only substitutes when the variable is unset
   or empty), a caller that *explicitly* exports `LC_ALL=C` bypasses the
   default entirely — reproduced directly during this fix — so a probe
   built around an explicit `LC_ALL=C` override would neither fail closed
   nor produce byte-correct output, and could never pass. The probe instead
   targets the scenario the finding is actually about (a host with no
   locale configured), which is what the applied WR-01 fix protects
   against, and does pass.
**Verified:** `bash tests/fail-closed.sh` — both new gates plus all
pre-existing gates pass (`rc=0`). `shellcheck tests/fail-closed.sh` clean.
`bash tests/regress.sh` still passes after this change (`rc=3`, no `FAIL:`
lines).

## Skipped Issues

None — all 5 in-scope findings (CR-01, WR-01 through WR-04) were fixed.

IN-01 (parameter order of `link()`/`cell()`) was out of scope for this run
(`fix_scope: critical_warning` excludes Info-level findings) and was left
untouched.

---

_Fixed: 2026-09-29T18:00:12Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
