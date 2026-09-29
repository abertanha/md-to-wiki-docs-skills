---
phase: 01-contrato-golden-fixtures
reviewed: 2026-09-29T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - tests/regress.sh
  - CONTEXT.md
  - agents/onboarding.md
  - docs/chrome-inventory.md
findings:
  critical: 2
  warning: 4
  info: 4
  total: 10
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-09-29
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four files reviewed: the regression harness (`tests/regress.sh`), the domain contract (`CONTEXT.md`), the onboarding subagent (`agents/onboarding.md`), and the chrome inventory (`docs/chrome-inventory.md`). The main chain regression infrastructure is sound. Two critical defects were found: the DokuWiki regression leg bypasses the date-mask protocol that the main chain enforces, and the `SKILL_DIR` discovery command silently resolves to `.` when no `SKILL.md` is found. Four warnings cover a temp-dir leak, binary-file misuse of `sed`, a dead interview question, and a cross-platform URL divergence. Four info items cover the always-skipping `.ps1` leg, dead template code, and seed/inventory mismatches that Phase 2 must reconcile.

---

## Critical Issues

### CR-01: DokuWiki regression diff runs without date masking

**File:** `tests/regress.sh:169`

**Issue:** The main chain regression (mkdocs, pdf, swagger legs) applies `mask_copy` symmetrically to both the golden and fresh trees before diffing, so ISO 8601 dates never produce spurious failures. The DokuWiki leg (lines 167-176) calls `diff -r` directly on the raw golden directory and raw fresh output — no masking. The file header (line 31-32) states the mask covers "every ISO 8601 date site in the chain chrome", but DokuWiki is exempt by omission. Currently `to-dokuwiki.sh` does not inject dates into its own chrome, so existing goldens are clean. However, pandoc passes through any dates present in source `.md` files, and a single date-bearing fixture entry (or any future chrome addition) will cause the DokuWiki leg to fail every time it runs on a different day than the capture. The asymmetry is a latent correctness defect in the test contract.

**Fix:**
```bash
# regress) DokuWiki leg — apply mask_copy before diffing, same as main chain
regress)
  [ -f "$GOLDEN_DW/README.md" ] || die "DokuWiki golden not found under $GOLDEN_DW — run 'tests/regress.sh capture' first"
  FRESH_DW=$(mktemp -d)
  MASKED_DW=$(mktemp -d)
  trap 'rm -rf "$FRESH_DW" "$MASKED_DW"' EXIT   # extend or add separate trap
  run_dokuwiki_sh "$FRESH_DW"
  mask_copy "$GOLDEN_DW"          "$MASKED_DW/golden"
  mask_copy "$FRESH_DW/dokuwiki"  "$MASKED_DW/fresh"
  out=$(diff -r "$MASKED_DW/golden" "$MASKED_DW/fresh" 2>&1) && {
    echo "OK: dokuwiki identical (date-masked)"
  } || {
    echo "FAIL: dokuwiki diverged"
    printf '%s\n' "$out" | sed 's/^/  /'
    FAIL=1
  }
  ;;
```

---

### CR-02: `SKILL_DIR` silently resolves to `.` when no `SKILL.md` is found

**File:** `agents/onboarding.md:23`

**Issue:** The SKILL_DIR discovery command is:
```bash
SKILL_DIR=$(dirname "$(find ... -name SKILL.md 2>/dev/null | head -1)")
```
When none of the three search paths exist or contain a `SKILL.md`, `find` produces no output. `head -1` returns an empty string. `dirname ""` returns `.` (POSIX-mandated). `SKILL_DIR` is then set to `.` — the current working directory. This value is non-empty, so the return criteria check `SKILL_DIR resolved non-empty` passes silently. Every subsequent script invocation of the form `$SCRIPT_RUNNER "$SKILL_DIR/scripts/<name>$SCRIPT_EXT"` will expand to `./scripts/…`, which only succeeds if the agent happens to be running from the repo root — a fragile coincidence, not a guarantee. The agent proceeds believing the skill is installed when it is not.

**Fix:**
```bash
# After the find command, validate that the result is a real directory:
_found=$(find ~/.config/opencode/skills/md-to-wiki \
              "$PWD/.opencode/skills/md-to-wiki" \
              "$PWD/.cursor/skills/md-to-wiki" \
              -name SKILL.md 2>/dev/null | head -1)

if [ -z "$_found" ]; then
  echo "ERROR: SKILL.md not found. Install the skill first (see README)."
  # stop — return criteria cannot be satisfied
else
  SKILL_DIR=$(dirname "$_found")
fi
```

---

## Warnings

### WR-01: `mask_copy` runs `sed -i` over binary PDF files

**File:** `tests/regress.sh:105`

**Issue:** `mask_copy` applies date masking by running `find "$2" -type f -exec sed -i -E "$MASK" {} +` over the entire destination tree. For the `pdf` surface this includes `specs-book.pdf`, a binary file. GNU `sed` processes binary data as a byte stream and may silently corrupt or truncate it around null bytes. The corruption is symmetric (both golden and fresh copies are mutated identically), so `diff` comparisons still pass — but if `sed` exits non-zero on binary input on any platform (BSD sed, musl sed), `mask_copy` will fail under `set -euo pipefail` and abort the regression run.

**Fix:** Exclude non-text files from the mask pass:
```bash
mask_copy() { # <src_tree> <dst_tree> — masked copy, source untouched
  rm -rf "$2"
  mkdir -p "$2"
  cp -r "$1/." "$2/"
  # Restrict to text files only; -I makes GNU sed skip binary input safely,
  # but portable fix is to exclude by extension.
  find "$2" -type f ! -name "*.pdf" -exec sed -i -E "$MASK" {} +
}
```

---

### WR-02: `FRESH_DW` temp directories are not covered by any cleanup trap

**File:** `tests/regress.sh:158,167`

**Issue:** The main chain's temp directories (`FRESH`, `MASKED`) are cleaned by an `EXIT` trap set at lines 126/139. The DokuWiki leg creates `FRESH_DW` with `mktemp -d` in both the `capture` branch (line 158) and the `regress` branch (line 167), but neither is added to any trap. If `run_dokuwiki_sh` raises an error (e.g., pandoc exits non-zero), `set -euo pipefail` causes the script to terminate and `FRESH_DW` is leaked on disk. In CI environments with constrained `/tmp`, repeated leaks can exhaust space.

**Fix:** Extend the existing `EXIT` trap to include `FRESH_DW`, or add a dedicated trap inside each pandoc block before creating `FRESH_DW`:
```bash
# Inside the pandoc block, immediately after pandoc check:
if command -v pandoc >/dev/null 2>&1; then
  FRESH_DW=""
  trap 'rm -rf "$FRESH_DW"' EXIT   # guard DokuWiki temp; overrides earlier trap — combine instead
  case "$MODE" in
    capture)
      FRESH_DW=$(mktemp -d)
      ...
```
The cleaner fix is to declare `FRESH_DW=""` before the `case` at line 123 and reference it in the existing trap, then assign `FRESH_DW=$(mktemp -d)` inside each branch.

---

### WR-03: Interview question 6 ("Deployment") is not mapped to any CONTEXT.md variable

**File:** `agents/onboarding.md:18`

**Issue:** The onboarding interview has six questions. Questions 1–5 map to CONTEXT.md variables (`PROJECT_NAME`, `SOURCES`, `AUDIENCE`, `OUTPUT_LANG`, `FORMAT`). Question 6 asks "Deployment — hosted or local-only?" but this information is not assigned to any variable and is not listed in the return criteria (line 51). An agent that faithfully completes the interview will ask the user a question, collect the answer, and then discard it. The question also subtly conflicts with the declared scope: the skill's job is to generate publishable artifacts, and deployment logistics are out of scope. The dead question adds interview friction without contributing to the contract.

**Fix:** Remove question 6, or — if deployment mode genuinely affects output — define a `DEPLOY` variable in CONTEXT.md and add it to the return criteria and dispatch prompt. If the question is meant for UX only (informing the agent's prose explanations), document that explicitly so agents know not to include it in the returned variable set.

---

### WR-04: `generated_by` URL diverges between `.sh` and `.ps1` scripts

**File:** `docs/chrome-inventory.md:61`

**Issue:** The inventory documents that the `generated_by` chrome key has different URLs by platform:
- `.sh` emits: `Generated by [md-to-wiki](https://github.com/abertanha/md-to-wiki-docs-skills) — %s`
- `.ps1` emits: `Generated by [md-to-wiki](https://opencode.ai) — $(Get-Date …)`

Every document generated on Windows attributes the tool to `opencode.ai`, while Unix-generated documents attribute it to the GitHub repository. This is an attribution inconsistency visible in published output. The inventory marks it "equal" in the Divergence column, which is incorrect — the URLs are different. Phase 2 must assign a single canonical URL to `generated_by` in both `.lang` files; whichever platform generates the doc, attribution should be the same.

**Fix:** Align both scripts to the same canonical URL before Phase 2 extracts en values. The GitHub repository URL (`https://github.com/abertanha/md-to-wiki-docs-skills`) is the version-stable reference; `opencode.ai` is a third-party host. Update `scripts/generate-index.ps1:84` to match the `.sh` value, then correct the divergence annotation in the inventory from "igual" to the actual difference.

---

## Info

### IN-01: `.ps1` regression leg unconditionally skips when `pwsh` is present

**File:** `tests/regress.sh:186-190`

**Issue:** The logic at lines 186-190 is:
```bash
if command -v pwsh >/dev/null 2>&1; then
  skip "pwsh present but .ps1 golden capture not yet implemented in this harness"
else
  skip "pwsh not found on host …"
fi
```
Both branches call `skip`, so exit code 3 (partial) is always emitted. On a developer machine with `pwsh` installed, every run is marked partial, which pollutes CI status and desensitizes developers to the `SKIPPED` signal. The branch also defeats the purpose of the pandoc-gating pattern used for DokuWiki.

**Fix:** Remove the `if`/`else` and keep only the single unconditional `skip` call that explains the "not yet implemented" status. This makes the skip reason consistent and removes the misleading runtime check on `pwsh`.

---

### IN-02: `templates/index.md` is dead code — no consumer

**File:** `docs/chrome-inventory.md:72-74`

**Issue:** The inventory explicitly documents (D-12 note) that `templates/index.md` has no consumer: `generate-index.sh` uses its own heredoc, and no agent, script, or SKILL.md references the template. The chrome values in it are extracted in Phase 2 from the live scripts, not from this template. The template is a parallel dead artifact and adds maintenance surface without value.

**Fix:** Remove `templates/index.md` in Phase 2, or add a comment header marking it explicitly as "reference only, not consumed by any script" until the cleanup decision is made. Either way, document the outcome in this inventory.

---

### IN-03: Section labels in CLAUDE.md seed omit the `##` heading prefix that scripts actually emit

**File:** `docs/chrome-inventory.md:21-26` vs `CLAUDE.md` (Seed do glossário)

**Issue:** The chrome inventory records verbatim values including the Markdown heading marker:
- `section_quick_start` → `## Quick Start`
- `section_overview` → `## Overview`
- `section_features` → `## Features`
- etc.

The CLAUDE.md seed glossary lists only the bare text (`Quick Start`, `Overview`, `Features`, …) without `## `. Phase 2 will use the seed as input for building `templates/lang/en.lang`. If the label is stored as `section_quick_start=Quick Start` and the script sources the label and emits it verbatim, the `## ` prefix must come from the script itself. If the script currently emits `## Quick Start` as one hardcoded string that will be replaced wholesale by the label value, the `## ` must be included in the label. The two representations are incompatible. The inventory (which reads the live scripts) is authoritative; the seed must be corrected to match.

**Fix:** Update the CLAUDE.md seed table to include the `## ` prefix on all `section_*` keys, or explicitly document in both the seed and the inventory that the `## ` is emitted by the script and the label holds only the text portion. Pick one convention and apply it consistently before Phase 2 writes `en.lang`.

---

### IN-04: `label_architecture` key present in chrome inventory but absent from CLAUDE.md seed

**File:** `docs/chrome-inventory.md:34` vs `CLAUDE.md` (Seed do glossário)

**Issue:** The inventory lists `label_architecture` with value `Architecture` at `scripts/generate-index.sh:42,58`. The CLAUDE.md seed glossary does not include `label_architecture` — the seed jumps from `label_conventions` to `label_roadmap`. If Phase 2 builds `en.lang` from the seed, this key will be missing, causing a silent regression in the index nav (architecture link label will fall back to hardcoded or be absent).

**Fix:** Add the missing entry to the CLAUDE.md seed:

| Chave | `en` | `pt-br` |
|-------|------|---------|
| `label_architecture` | `Architecture` | `Arquitetura` |

---

_Reviewed: 2026-09-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
