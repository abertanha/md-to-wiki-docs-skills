---
phase: 04-g-meos-powershell-prosa-release
verified: 2026-10-01T00:00:00Z
status: passed
score: 10/10 must-haves verified
covered_files:
  - .planning/phases/04-g-meos-powershell-prosa-release/04-01-PLAN.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-01-SUMMARY.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-02-PLAN.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-02-SUMMARY.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-03-PLAN.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-03-SUMMARY.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-04-PLAN.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-04-SUMMARY.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-05-PLAN.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-05-SUMMARY.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-RESEARCH.md
  - .planning/phases/04-g-meos-powershell-prosa-release/04-REVIEW.md
  - CHANGELOG.md
  - CONTEXT.md
  - README.md
  - README.pt-BR.md
  - SKILL.md
  - agents/format-github-wiki.md
  - agents/references.md
  - docs/chrome-inventory.md
  - scripts/generate-index.ps1
  - scripts/generate-mkdocs.ps1
  - scripts/lib/catalog.ps1
  - scripts/to-dokuwiki.ps1
  - scripts/to-pdf.ps1
  - tests/fail-closed.sh
  - tests/fixtures/manifest.md
  - tests/no-calques.sh
  - tests/no-mixed-output.sh
  - tests/ps1-contract.sh
  - tests/regress.sh
  - tests/wiki-links.sh
covered_digest: "v2:sha256:7d9c51e0059ca10bbb20b14d05593b8f29250611fe433a2c76c777c149881462"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 04: Gêmeos PowerShell, Prosa & Release — Verification Report

**Phase Goal:** Entregar os quatro gêmeos PowerShell catalog-driven para os scripts bash, um gate de glossário anti-calque, um harness de regressão com golden fixtures `.ps1` reais, e fechamento de documentação do milestone.

**Verified:** 2026-10-01T00:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Os 4 gêmeos `.ps1` são catalog-driven (zero string de chrome hardcoded) | ✓ VERIFIED | `tests/ps1-contract.sh` gate `no_hardcoded_chrome`: OK. Manually confirmed all 4 twins (`generate-index.ps1`, `generate-mkdocs.ps1`, `to-pdf.ps1`, `to-dokuwiki.ps1`) dot-source `scripts/lib/catalog.ps1` and resolve labels via `Get-Catalog`/`Assert-CatalogKey` |
| 2 | `scripts/lib/catalog.ps1` existe e carrega `en.lang` / `pt-br.lang` | ✓ VERIFIED | File exists, 124 lines, defines exactly 6 functions: `Resolve-OutputLang`, `Get-CatalogPath`, `Get-Catalog`, `Assert-CatalogKey`, `Write-Utf8NoBom`, `Expand-CatalogEscapes` (`grep -E '^function '` confirms all 6, no extras) |
| 3 | `tests/no-calques.sh` existe e os gates rodam verde | ✓ VERIFIED | Live run: 6/6 gates `OK:` (`denylist_clean_prose`, `denylist_clean_ptbr_output`, `denylist_clean_catalog`, `gate_is_load_bearing`, `allowlist_is_load_bearing`, `glossary_is_inlined`), rc=0, zero `FAIL:` |
| 4 | `tests/ps1-contract.sh` tem 21 gates todos OK | ✓ VERIFIED | Live run (with `pwsh 7.6.5` via `/snap/bin`): exactly 21 lines `OK:`, zero `FAIL:`, rc=0. All 12 structural gates + 9 behavioral `pwsh_*` legs green (no `SKIPPED:` — pwsh was available) |
| 5 | `tests/regress.sh` inclui a perna `.ps1` e roda verde | ✓ VERIFIED | Live run: `OK: mkdocs .ps1 (docs/) identical (date-masked)`, `OK: pdf .ps1 (specs-book.md) identical (date-masked)`, `OK: dokuwiki .ps1 identical`, plus all 4 `.sh` surfaces green; rc=0 |
| 6 | `tests/fixtures/golden-ps1/` existe com arquivos de saída | ✓ VERIFIED | Directory exists with `mkdocs/docs/{mkdocs.yml,index.md}`, `pdf/specs-book.md`, `dokuwiki/README.md` + 7 converted DokuWiki pages, all committed (`7a82332`, `32f92fd`) |
| 7 | `CHANGELOG.md` existe na raiz com notas de release | ✓ VERIFIED | File exists; contains `## [OUTPUT_LANG] — 2026-09-30`, `### Nota de release`, `### Adicionado`, `### Alterado`, `### Corrigido`, `### Limitações conhecidas` |
| 8 | `README.md`/`README.pt-BR.md` atualizados, sem ressalva obsoleta de `.ps1` | ✓ VERIFIED | `grep -ciE 'later phase|fase futura|ainda não aceit|do not yet accept'` returns 0 in both files; both mention `output_lang` (2 hits each) and have a `## Tests`/`## Testes` section (line 170 in both) |
| 9 | `CONTEXT.md` tem seção `## Glossário anti-calque` | ✓ VERIFIED | Heading present at line 31; zero residual "later phase"/"fase futura/posterior" mentions (`grep -ciE` = 0) |
| 10 | `OUTPUT_LANG=en`: saída byte-idêntica aos fixtures `golden-sh/` | ✓ VERIFIED | `tests/regress.sh` live run: all 4 `.sh` surfaces (`mkdocs`, `pdf`, `swagger`, `dokuwiki`) print `OK: ... identical`; `git diff --stat <phase-base-commit> HEAD -- tests/fixtures/golden-sh/` is empty (zero bytes changed across the entire phase, not just vs HEAD) |

**Score:** 10/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/lib/catalog.ps1` | Shared catalog loader, 6 functions | ✓ VERIFIED | Exists, 124 lines, all 6 functions present, `WriteAllText`+`UTF8Encoding($false)` confirmed |
| `scripts/generate-index.ps1` | Catalog-driven, positional `output_lang` | ✓ VERIFIED | Dot-sources lib, `Resolve-OutputLang` before `Get-CatalogPath` (gate `allowlist_before_path` OK) |
| `scripts/generate-mkdocs.ps1` | Catalog-driven, additive `theme.language` | ✓ VERIFIED | Gate `theme_language_ptbr_only` OK; live pt-br/en run via `pwsh_theme_language` leg OK |
| `scripts/to-pdf.ps1` | Catalog-driven, pandoc lang flags on all invocations | ✓ VERIFIED | Gate `pandoc_langopts_all_invocations` OK; `pwsh_pandoc_langopts` behavioral leg OK |
| `scripts/to-dokuwiki.ps1` | Catalog-driven, bootstrap before pandoc guard | ✓ VERIFIED | Gate `bootstrap_before_pandoc_guard` OK; `pwsh_dokuwiki_value_shape` OK |
| `tests/ps1-contract.sh` | 21-gate contract harness | ✓ VERIFIED | 21/21 `OK:`, rc=0 |
| `tests/no-calques.sh` | Anti-calque glossary gate | ✓ VERIFIED | 6/6 `OK:`, rc=0 |
| `tests/wiki-links.sh` | Link-conversion regression gate | ✓ VERIFIED | 4/4 `OK:`, rc=0 |
| `tests/regress.sh` | Regression harness incl. `.ps1` leg | ✓ VERIFIED | All surfaces `OK:`, rc=0 |
| `tests/fixtures/golden-ps1/` | Golden `.ps1` fixtures | ✓ VERIFIED | Present, committed, zero BOM in any captured file |
| `tests/fixtures/manifest.md` | Capture pins + pwsh version | ✓ VERIFIED | Contains pwsh version string, capture SHA, D-15/D-10 notes |
| `CHANGELOG.md` | Release note | ✓ VERIFIED | Present with required sections |
| `README.md` / `README.pt-BR.md` | Parity + test docs | ✓ VERIFIED | No stale caveat, `## Tests`/`## Testes` section present |
| `CONTEXT.md` | Glossary section, no future-phase prose | ✓ VERIFIED | Heading present, zero stale "later phase" mentions, ignore-region sentinels balanced |
| `SKILL.md` | Verified positional-parity table | ✓ VERIFIED | Companion Scripts table includes positional-signature column (manually spot-checked) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `templates/lang/{en,pt-br}.lang` | `scripts/lib/catalog.ps1` | `Get-Catalog` | ✓ WIRED | `pwsh_catalog_roundtrip` gate OK: key counts match grep vocabulary, quote-stripping + escape collapse confirmed |
| `scripts/lib/catalog.ps1` | 4 `.ps1` twins | dot-source + `Write-Utf8NoBom` | ✓ WIRED | `twins_dotsource_lib`, `bomless_writer` gates OK |
| `tests/ps1-contract.sh` | 4 `.ps1` twins | structural + behavioral gates | ✓ WIRED | 21/21 OK live |
| `tests/regress.sh` (capture mode) | `tests/fixtures/golden-ps1/` | sole writer | ✓ WIRED | Golden files present, match live regression run |
| `CONTEXT.md` (glossary) | `agents/format-github-wiki.md`, `agents/references.md` | inline copy | ✓ WIRED | `glossary_is_inlined` gate OK (≥3 denylist forms inside balanced ignore-region in both agent files) |
| `agents/format-github-wiki.md` sed block | `tests/wiki-links.sh` | expression extraction | ✓ WIRED | `sed_block_extraction` gate OK — extracts live expressions from the agent file, not a copy |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `.ps1` chain produces byte-identical `en` output vs golden-sh under regression | `bash tests/regress.sh` | All 7 lines `OK: ... identical`, rc=0 | ✓ PASS |
| `.ps1` structural + behavioral contract | `bash tests/ps1-contract.sh` | 21/21 `OK:`, rc=0 | ✓ PASS |
| Anti-calque glossary gate, including positive controls | `bash tests/no-calques.sh` | 6/6 `OK:`, rc=0 | ✓ PASS |
| Link-conversion regression (CR-01/D-17/D-26 fixes) | `bash tests/wiki-links.sh` | 4/4 `OK:`, rc=0 | ✓ PASS |
| Bash-side fail-closed contract unaffected | `bash tests/fail-closed.sh` | 23/23 `OK:`, rc=0 | ✓ PASS |
| No mixed-output regression on pt-br surfaces | `bash tests/no-mixed-output.sh` | 10/10 `OK:`, rc=0 | ✓ PASS |
| Golden-sh untouched across the whole phase | `git diff --stat <phase-base> HEAD -- tests/fixtures/golden-sh/` | empty output | ✓ PASS |
| golden-ps1 BOM-free | byte-level scan of all files under `tests/fixtures/golden-ps1/` | 0 BOM matches | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|--------------|--------|----------|
| CHROME-01 | 04-01, 04-03 | Zero hardcoded chrome strings in `.ps1` twins | ✓ SATISFIED | `no_hardcoded_chrome` gate OK |
| CHROME-03 | 04-01, 04-03 | Missing catalog key halts before output | ✓ SATISFIED | `pwsh_missing_key_halts`, `bootstrap_before_pandoc_guard` gates OK |
| PARAM-02 | 04-01, 04-03 | `output_lang` positional, allowlist before path | ✓ SATISFIED | `allowlist_before_path` gate OK across all 4 twins |
| QUAL-01 | 04-03 | Additive i18n projection (theme.language, pandoc lang flags) | ✓ SATISFIED | `theme_language_ptbr_only`, `pandoc_langopts_all_invocations` gates OK |
| QUAL-02 | 04-04 | Real `.ps1` regression leg with golden fixtures | ✓ SATISFIED | `tests/regress.sh` `.ps1` leg live, golden-ps1 committed |
| QUAL-03 | 04-02, 04-05 | Anti-calque glossary gate | ✓ SATISFIED | `tests/no-calques.sh` 6/6 OK, including load-bearing controls |
| PARAM-01 | 04-05 | `OUTPUT_LANG` documented as contract parameter with default | ✓ SATISFIED | README sections confirmed |

No orphaned requirements found for this phase in `.planning/REQUIREMENTS.md` beyond those claimed above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `scripts/to-pdf.ps1` | 94-122 | Pandoc exit code unchecked after `& $pandoc ...` invocation; script reports success even when pandoc fails (CR-01, code review) | ⚠️ Warning | Known issue, documented in 04-REVIEW.md. Does not block the catalog-driven i18n goal; pre-existing defect surfaced (not introduced) by this phase's rewrite |
| `scripts/to-dokuwiki.ps1` | 70-71 | Per-file pandoc exit code unchecked; loop continues and reports "Converted" even on failed conversion (CR-02, code review) | ⚠️ Warning | Same disposition as CR-01 — known, documented, non-blocking for this phase's goal |

No debt markers (`TBD`/`FIXME`/`XXX`) found in any phase-touched file. No stub patterns, no hardcoded empty-data patterns, no placeholder prose found in the scanned surfaces.

### Human Verification Required

None. All must-haves were verified live against the actual codebase: `pwsh 7.6.5` (via `/snap/bin/pwsh`) and `pandoc 3.7.0.2` were both available in this verification session, so every behavioral leg that the plans marked as `pwsh`-conditional ran for real rather than being skipped. No `⚠️ PRESENT_BEHAVIOR_UNVERIFIED` truths were produced.

### Gaps Summary

No gaps. All 10 must-haves verified against live test execution, not SUMMARY.md narrative. The two code-review findings (CR-01, CR-02 — unchecked pandoc exit codes in `to-pdf.ps1` and `to-dokuwiki.ps1`) remain present in the code as of this verification and are recorded here as known issues per the task's explicit instruction: they are pre-existing defects that survive this phase's rewrite, documented in `04-REVIEW.md` and in `CHANGELOG.md`'s "Limitações conhecidas" section, and do not block achievement of this phase's actual goal (catalog-driven i18n across all 4 PowerShell twins + test coverage + documentation closure).

---

_Verified: 2026-10-01T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
