---
phase: 02-cat-logo-de-labels-cadeia-mkdocs-index
reviewed: 2026-09-29T17:30:57Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - README.md
  - README.pt-BR.md
  - agents/format-mkdocs.md
  - docs/chrome-inventory.md
  - scripts/generate-index.sh
  - scripts/generate-mkdocs.sh
  - templates/lang/en.lang
  - tests/fail-closed.sh
  - tests/regress.sh
findings:
  critical: 2
  warning: 4
  info: 1
  total: 7
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-09-29T17:30:57Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed the catalog-lookup refactor of `generate-index.sh`/`generate-mkdocs.sh`, the new `templates/lang/en.lang` catalog, the new `tests/fail-closed.sh` gate, and the accompanying doc updates. The CHROME-03 (fail-closed on missing key) and CHROME-04 (title-case passthrough stays catalog-free) invariants both hold and are correctly self-tested — verified independently with `comm`/`grep` against the actual catalog and script bodies, and by running `bash tests/fail-closed.sh` and `bash tests/regress.sh` (both green, the latter's single SKIP being the documented, expected `.ps1`/no-`pwsh` case).

Two Critical defects were found by tracing execution rather than reading the diff at face value, both of which are demonstrated with a live repro below, not inferred: (1) the `generated_by` catalog value is spliced directly into a `printf` **format string** rather than passed as a `%s` argument like every other catalog key in the same script — any future catalog value containing a literal `%` corrupts output and aborts the script; (2) `generate-index.sh`'s feature-table label goes through a locale-sensitive `sed` title-case pipeline with no locale pinned by the script itself or by the orchestrating `agents/format-mkdocs.md` — under a non-UTF-8 locale, accented directory names (e.g. `autenticação`, present in this repo's own fixture tree) are corrupted into mojibake. The project's own `tests/fixtures/manifest.md` already documents this exact failure mode as understood, but only the test harness works around it (`export LC_ALL=C.UTF-8`); the shipped script does not, which is the more consequential gap given this milestone's entire purpose is enabling accented PT-BR output.

Several Warning-level documentation/quality gaps were also found (a stale doc reference to a file deleted in this same phase, an incomplete README structure diagram, an undocumented catalog-quoting landmine, and a test-suite blind spot that let the two Critical bugs through undetected).

## Critical Issues

### CR-01: `generated_by` catalog value used as printf format string, not argument — corrupts output on any `%` in catalog content

**File:** `scripts/generate-index.sh:163`
**Issue:** Every other catalog key in this script is passed to `printf` as a `%s`-substituted **argument** (e.g. `printf '## %s\n\n%s\n\n' "${section_quick_start}" "$section"`, `printf -- "- [%s](%s)\n" "$1" "$2"`). Line 163 breaks that pattern: the catalog value `${generated_by}` is interpolated by the shell directly into the **format-string** literal itself, before `printf` ever runs:

```bash
printf -- "---\n*${generated_by}*\n" "$(date +%Y-%m-%d)" >> "$OUTPUT"
```

`shellcheck` independently flags this as SC2059 ("Don't use variables in the printf format string"). It is exploitable today, not just theoretically — a catalog value containing a literal `%` (very plausible in translated PT-BR prose, e.g. "100% automatizado", or any maintainer typo) makes `printf` misparse the format string, corrupt the emitted line, and return non-zero, which — because the script runs under `set -euo pipefail` — aborts the script immediately after `docs/index.md` already has a truncated/corrupted final line written to it (append mode, so earlier content is not visible as broken, only the tail). Reproduced directly:

```bash
$ bash -c 'val="Gerado 100% por [md-to-wiki] — %s"; printf -- "---\n*${val}*\n" "2026-09-29"; echo "exit=$?"'
---
bash: line 1: printf: `p': invalid format character
*Gerado 100exit=1
```

This is a regression in robustness introduced by moving this string from a hardcoded, code-reviewed literal (safe, because whoever touches it sees it lives inside a printf format string) to an externally-editable catalog file (`templates/lang/*.lang`) whose authors — translators writing Phase 3's `pt-br.lang` — have no reason to know this one key is special.

**Fix:** Do the `%s` substitution in bash, not in `printf`'s format string, so the outer `printf`'s format string stays a fixed, safe literal:

```bash
today="$(date +%Y-%m-%d)"
message="${generated_by/\%s/$today}"
printf -- '---\n*%s*\n' "$message" >> "$OUTPUT"
```

## Warnings

### WR-01: Feature-table labels corrupt under non-UTF-8 locale — no guard in the shipped script or its orchestrator

**File:** `scripts/generate-index.sh:137` (also see `scripts/generate-mkdocs.sh:61,67`), `agents/format-mkdocs.md`
**Issue:** The feature-table row label is produced by a locale-sensitive multi-byte-unsafe `sed` pipeline:

```bash
name=$(basename "$dir" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')
```

Under a non-UTF-8 locale, `\u`/`\b` word-boundary matching operates byte-wise instead of character-wise and corrupts accented UTF-8 basenames. Reproduced directly against this repo's own fixture tree (`tests/fixtures/tree/.specs/features/autenticação/`):

```
LC_ALL=C   → | Autentica��ãO | ...   (mojibake)
LC_ALL=C.UTF-8 → | Autenticação | ...  (correct)
```

Neither `generate-index.sh` nor `generate-mkdocs.sh` sets/requires a UTF-8 locale itself, and `agents/format-mkdocs.md` (the orchestrator that dispatches both scripts) never mentions a locale precondition either — it only forwards `OUTPUT_LANG`. The only place `LC_ALL=C.UTF-8` is pinned is inside `tests/regress.sh` and `tests/fail-closed.sh`, and `tests/fixtures/manifest.md:37` explicitly documents that this is *because* "o sed de title-case da cadeia corrompe acentos em locale C (o `ç` de `autenticação` vira lixo)" — i.e. the maintainers already know about this exact corruption and only worked around it in the test harness, not in the shipped script. Since this milestone's stated goal is PT-BR output, and PT-BR spec trees are exactly the case most likely to have accented directory/feature names, this is a live correctness gap in the product path, not just a test-fixture curiosity. Unlike the `OUTPUT_LANG` allowlist (which fails closed on a bad value), there is no equivalent guard here — the script silently emits garbled markdown and still exits 0.

**Fix:** Either (a) have `generate-index.sh`/`generate-mkdocs.sh` set a UTF-8 locale themselves at the top (e.g. `export LC_ALL="${LC_ALL:-C.UTF-8}"`, falling back through a small allowlist of known-good UTF-8 locales and failing closed with a clear message if none is available), or (b) document the `LC_ALL` precondition as a hard requirement in `agents/format-mkdocs.md` dispatch steps and add a fail-closed check at the top of both scripts (`locale -a | grep -qi 'C\.utf-\?8\|UTF-8'` style check) so a misconfigured host errors loudly instead of emitting corrupted output.

### WR-02: `docs/chrome-inventory.md` still documents `templates/index.md` as present, but this phase deleted it

**File:** `docs/chrome-inventory.md:69-76`
**Issue:** Camada 3 of the inventory still lists `templates/index.md` (with specific line numbers 1,3,7-25 and a content description) as a live, if `unconsumed`, file, and D-12's note says "decidir usar-ou-remover o template é decisão da Phase 2". This phase *made* that decision — `templates/index.md` was removed via `git rm` in commit `37c87bd` (confirmed: `git ls-files templates/index.md` returns nothing) and the corresponding README entries were updated — but `docs/chrome-inventory.md` itself was not updated to reflect the resolution, so it now describes a file and line numbers that no longer exist in the tree.
**Fix:** Update the Camada 3 row and the D-12 note to record the outcome (file removed, decision resolved), or strike the row entirely, so the inventory doesn't point future readers at a deleted file.

### WR-03: README structure diagrams weren't updated for the new `templates/lang/` catalog

**File:** `README.md:82-84`, `README.pt-BR.md:82-84`
**Issue:** This same diff edits the `templates/` entry in both READMEs' "Skill Set Structure" tree (removing the `templates/index.md` line), but neither tree gains an entry for `templates/lang/en.lang` — the actual primary deliverable of this phase. A reader using the README as the map of the repo has no way to discover the catalog directory exists.
**Fix:** Add e.g. `├── templates/lang/en.lang   # EN chrome label catalog` (and pt-br.lang note it lands in Phase 3) to both trees.

### WR-04: No test exercises catalog-content robustness (the `%` and non-UTF-8-locale scenarios that produced CR-01/CR-02)

**File:** `tests/fail-closed.sh`, `tests/regress.sh`
**Issue:** `tests/fail-closed.sh` thoroughly covers CHROME-03 (missing key halts) and CHROME-04 (title-case sites stay catalog-free), and matches the plan's minimum probe matrix exactly (index-exclusive key, mkdocs-exclusive key, one shared-key probe). However, no gate in either harness exercises what happens when a catalog *value itself* is adversarial/unusual content — e.g. a value containing a literal `%` (which would have caught CR-01), or running the chain under a non-UTF-8 locale without the harness's own `LC_ALL=C.UTF-8` override (which would have caught CR-02, and which `tests/fixtures/manifest.md` shows the maintainers are already aware is a distinct risk from the CHROME-03/04 gates). Both bugs above shipped past a fully-green `bash tests/fail-closed.sh` and `bash tests/regress.sh`.
**Fix:** Add two probes to `tests/fail-closed.sh` (sandboxed, per its own mutation discipline): (1) substitute a `generated_by` value containing a bare `%` in a sandbox catalog and assert the script still exits 0 with correct output; (2) run `generate-index.sh` once under `LC_ALL=C` against the accented fixture directory and assert either a fail-closed error or byte-correct output (currently: neither — it silently corrupts and exits 0).

## Info

### IN-01: Inconsistent helper parameter order — `link()` vs `cell()`

**File:** `scripts/generate-index.sh:80-86`
**Issue:** `link(label, relpath)` takes the label first, but `cell(relpath, label)` takes the relpath first — same script, same purpose (conditionally emit a markdown link), reversed argument order. Not a bug (call sites are correct), but a readability trap for the next editor.
**Fix:** Align the parameter order of `cell()` with `link()` (`cell(label, relpath)`), updating the three call sites at lines 139-141.

---

_Reviewed: 2026-09-29T17:30:57Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
