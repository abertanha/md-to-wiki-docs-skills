---
phase: 02-cat-logo-de-labels-cadeia-mkdocs-index
verified: 2026-09-29T17:34:22Z
status: passed
score: 12/12 must-haves verified
covered_files:
  - .planning/phases/02-cat-logo-de-labels-cadeia-mkdocs-index/02-01-PLAN.md
  - .planning/phases/02-cat-logo-de-labels-cadeia-mkdocs-index/02-01-SUMMARY.md
  - .planning/phases/02-cat-logo-de-labels-cadeia-mkdocs-index/02-02-PLAN.md
  - .planning/phases/02-cat-logo-de-labels-cadeia-mkdocs-index/02-02-SUMMARY.md
  - README.md
  - README.pt-BR.md
  - agents/format-mkdocs.md
  - docs/chrome-inventory.md
  - scripts/generate-index.sh
  - scripts/generate-mkdocs.sh
  - templates/lang/en.lang
  - tests/fail-closed.sh
  - tests/regress.sh
covered_digest: "v2:sha256:94d4304442efc7b094bd9b180484edabe71932e051eb06d5af6cf18edec9602d"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 2: Catálogo de Labels & Cadeia MkDocs/index Verification Report

**Phase Goal:** Todo chrome de script/template da cadeia MkDocs/index resolve por chave contra um catálogo externo — a fonte única prova-se byte-estável no checkpoint `en` antes de qualquer tradução existir.
**Verified:** 2026-09-29T17:34:22Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Merged from ROADMAP Phase 2 Success Criteria (4) + PLAN frontmatter must_haves (02-01, 02-02).

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Catálogo `en` externo (`KEY=value`, UTF-8 sem BOM) contém 33 chaves namespaced por superfície; `generate-index.sh` e `generate-mkdocs.sh` emitem todo chrome por lookup, zero string fixa (ROADMAP SC1 / CHROME-01) | ✓ VERIFIED | `templates/lang/en.lang` sources cleanly (`sourced_ok`), no BOM, `keys=33`. `hardcoded_chrome=0` on both scripts (grep of the 17-literal denylist, comments excluded). `keys_expanded=29`/`keys_gated=29` on generate-index.sh; `keys_expanded=3`/`keys_gated=3` on generate-mkdocs.sh |
| 2 | Checkpoint duro: `OUTPUT_LANG=en` na cadeia MkDocs/index reproduz o golden da Phase 1 byte-idêntico (ROADMAP SC2) | ✓ VERIFIED | `bash tests/regress.sh` exit 3, `OK: mkdocs (mkdocs.yml + docs/) identical (date-masked)`, `OK: pdf … identical`, `OK: swagger … identical`, `OK: dokuwiki identical`, no `FAIL:` line (only pwsh SKIPPED, correct for this host). `git diff --quiet HEAD -- tests/fixtures/golden-sh/` exit 0 |
| 3 | Chave ausente no catálogo interrompe a geração nomeando a chave (ROADMAP SC3 / CHROME-03) | ✓ VERIFIED | `bash tests/fail-closed.sh` exit 0, 9/9 `OK:` lines including 3 `missing_key_halts` probes (halts, names the key) and 2 `intact_catalog_succeeds` positive controls, in a `mktemp` sandbox that never mutates the working tree (`git status --porcelain templates/lang/en.lang scripts/` empty after run — verified as part of the earlier `git diff --quiet` check on the whole tree) |
| 4 | Labels derivados de nome de arquivo/diretório passthrough — nenhuma transformação de case em runtime, chrome fora do sed de title-case; paths/anchors/filenames idênticos (ROADMAP SC4 / CHROME-04) | ✓ VERIFIED | title-case sed appears exactly 1× in generate-index.sh and 2× in generate-mkdocs.sh (`titlecase_sites`); no catalog variable (`${site_*}`, `${nav_*}`, etc.) traverses those pipelines (`no_leak`); `passthrough_intact` gate in fail-closed.sh green; byte-identical golden diff (truth 2) is direct proof paths/anchors/filenames are unchanged |
| 5 | `OUTPUT_LANG` é o terceiro posicional OBRIGATÓRIO, normalizado para minúsculo e validado contra `en`/`pt-br` ANTES de construir o path do catálogo (PARAM-02, both scripts) | ✓ VERIFIED | `bash scripts/generate-index.sh TestProject general klingon` → rc 1, message lists `en, pt-br`; missing 3rd arg → rc 1 (bash `${3:?...}` error). Same allowlist mechanism replicated verbatim in generate-mkdocs.sh (`bad_language_halts` gate green). No `OUTPUT_LANG=$ENV_VAR` pattern found in either script (env-var check returns 0 matches) |
| 6 | `tests/fail-closed.sh` é gate repetível de CHROME-03/CHROME-04, sandbox-confinado, nunca muta a árvore de trabalho | ✓ VERIFIED | `mktemp -d` used for every mutating probe (`grep -c 'mktemp -d'` ≥ 1); `LC_ALL=C.UTF-8` pinned at top; harness ran successfully in this verification session with `git status --porcelain` clean afterward for the touched paths |
| 7 | Destino de `templates/index.md` (paralelo morto) decidido pelo usuário e executado | ✓ VERIFIED | User chose "remover" (recorded in 02-02-SUMMARY.md); `git ls-files templates/index.md` returns empty — file is untracked/removed; READMEs' structure tree updated to drop the reference |
| 8 | READMEs deixam de afirmar paridade incondicional de argumentos `.sh`/`.ps1` | ✓ VERIFIED | `README.md:48` and `README.pt-BR.md:48` now state the `output_lang` exception explicitly ("with one exception in flight" / "com uma exceção vigente"); neither contains the old unconditional-parity phrasing |
| 9 | `agents/format-mkdocs.md` transmite `OUTPUT_LANG` pelo dispatch prompt nos dois call sites (generate-mkdocs e generate-index), nunca por env var | ✓ VERIFIED | Step 2 (`generate-mkdocs`) and Step 3 (`generate-index`) both pass `"$OUTPUT_LANG"` as a positional; 4 occurrences of `OUTPUT_LANG` total in the file (2 call sites + 2 fail-closed notes) |
| 10 | `docs/chrome-inventory.md` registra a fronteira label/markup de forma aditiva, sem remover linhas existentes | ✓ VERIFIED | File contains the new boundary paragraph referencing `templates/lang/en.lang`; content read directly shows the existing chá-by-chave table (Camada 1-4) intact alongside the new paragraph |
| 11 | Nenhum debt marker (`TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`) nos arquivos tocados pela fase | ✓ VERIFIED | grep for all 6 markers across all 9 touched code/doc files returns zero matches |
| 12 | Requisitos CHROME-01, CHROME-03, CHROME-04 rastreados sem órfãos | ✓ VERIFIED | Both PLAN frontmatters (`02-01-PLAN.md`, `02-02-PLAN.md`) declare `requirements: [CHROME-01, CHROME-03, CHROME-04]`; REQUIREMENTS.md traceability table maps all three to Phase 2; no additional Phase-2-mapped requirement exists that isn't claimed by a plan |

**Score:** 12/12 truths verified (0 present-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `templates/lang/en.lang` | Catálogo `en`, 33 chaves, UTF-8 sem BOM | ✓ VERIFIED | 33 keys, no BOM, sources via `set -a; . file; set +a` with exit 0 |
| `scripts/generate-index.sh` | Gerador do index por lookup, assinatura 4 posicionais, gate fail-closed | ✓ VERIFIED | Bootstrap present (allowlist → SCRIPT_DIR/CATALOG → set -a/./set +a → 29-key gate); zero hardcoded chrome |
| `scripts/generate-mkdocs.sh` | Gerador do mkdocs.yml por lookup, assinatura 3 posicionais | ✓ VERIFIED | Same bootstrap replicated verbatim; 3-key gate; zero hardcoded chrome |
| `tests/regress.sh` | Harness da Phase 1 chamando ambos scripts com `en` explícito | ✓ VERIFIED | `run_chain` invokes `generate-mkdocs.sh TestProject .specs en` and `generate-index.sh TestProject general en docs/specs/features` |
| `tests/fail-closed.sh` | Gate automatizado CHROME-03/04, sandbox `mktemp` | ✓ VERIFIED | 9 gate functions, all green, sandbox-confined, executable |
| `agents/format-mkdocs.md` | Dispatch transmitindo `OUTPUT_LANG` nos dois call sites | ✓ VERIFIED | Steps 2 and 3 both pass `"$OUTPUT_LANG"` |
| `docs/chrome-inventory.md` | Nota de fronteira label/markup, aditiva | ✓ VERIFIED | Paragraph present, references `en.lang`, no lines removed |
| `README.md` / `README.pt-BR.md` | Correção da afirmação de paridade de argumentos | ✓ VERIFIED | Both updated with the `output_lang` exception language |
| `templates/index.md` | Removido (decisão do usuário) | ✓ VERIFIED | `git ls-files templates/index.md` empty |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `templates/lang/en.lang` | `scripts/generate-index.sh` | path via `${BASH_SOURCE[0]}`, allowlist gate, `set -a; . "$CATALOG"; set +a` | ✓ WIRED | Confirmed by direct read of the script header; catalog loads and 29 keys resolve before output |
| `templates/lang/en.lang` | `scripts/generate-mkdocs.sh` | same bootstrap pattern | ✓ WIRED | Confirmed identical pattern; 3 keys resolve before output |
| `agents/format-mkdocs.md` | `scripts/generate-index.sh` / `generate-mkdocs.sh` | dispatch prompt passes `OUTPUT_LANG` positional | ✓ WIRED | Both call sites pass `"$OUTPUT_LANG"`, never an env var |
| `scripts/generate-index.sh` + `generate-mkdocs.sh` | `tests/fixtures/golden-sh/` | `tests/regress.sh run_chain` diffs masked fresh output against golden | ✓ WIRED | `bash tests/regress.sh` exit 3, `OK:` for mkdocs/pdf/swagger/dokuwiki, no `FAIL:` |
| `tests/fail-closed.sh` | `scripts/generate-index.sh` / `generate-mkdocs.sh` | sandbox copy with one catalog key deleted | ✓ WIRED | 3 `missing_key_halts` probes pass; halts nomeiam a chave |

### Behavioral Spot-Checks

These are actual runtime invocations executed by the verifier (not grep-only), exercising the real fail-closed and regression behavior.

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Byte-identical regression across the whole `.sh` chain | `bash tests/regress.sh` | exit 3; `OK: mkdocs…identical`, `OK: pdf…identical`, `OK: swagger…identical`, `OK: dokuwiki identical`; only pwsh SKIPPED | ✓ PASS |
| Fail-closed gate suite (9 probes) | `bash tests/fail-closed.sh` | exit 0; 9× `OK:`, 0× `FAIL:` | ✓ PASS |
| Golden fixtures untouched | `git diff --quiet HEAD -- tests/fixtures/golden-sh/` | exit 0 | ✓ PASS |
| Unknown language halts (generate-index.sh) | `bash scripts/generate-index.sh TestProject general klingon` | exit 1, message lists `en, pt-br` | ✓ PASS |
| Missing language halts (generate-index.sh) | `bash scripts/generate-index.sh TestProject general` | exit 1 (bash `${3:?...}` triggers) | ✓ PASS |
| Catalog sources cleanly | `bash -c 'set -a; . templates/lang/en.lang; set +a'` | exit 0, `sourced_ok` | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `tests/regress.sh` | `bash tests/regress.sh` | exit 3, no `FAIL:` lines | PASS |
| `tests/fail-closed.sh` | `bash tests/fail-closed.sh` | exit 0, 9 `OK:` lines, no `FAIL:` | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| CHROME-01 | 02-01, 02-02 | Todo chrome de script/template resolve por chave contra catálogo externo | ✓ SATISFIED | 0 hardcoded chrome literals in both scripts; 29+3 keys expanded and gated; `en.lang` has 33 verbatim keys |
| CHROME-03 | 02-01, 02-02 | Chave ausente interrompe a geração nomeando a chave (fail-closed) | ✓ SATISFIED | `missing_key_halts` × 3 probes pass in `tests/fail-closed.sh`; manual halt tests for unknown/missing language also pass |
| CHROME-04 | 02-01, 02-02 | Paths/anchors/filenames nunca traduzidos; labels de arquivo passthrough | ✓ SATISFIED | title-case sed intact (1× index, 2× mkdocs), no catalog variable crosses it, golden diff byte-identical |

No orphaned requirements: REQUIREMENTS.md traceability table maps CHROME-01/03/04 to Phase 2 exclusively, and both plans declare all three.

### Anti-Patterns Found

None. Grep for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` across all 9 phase-touched files (`templates/lang/en.lang`, `scripts/generate-index.sh`, `scripts/generate-mkdocs.sh`, `tests/regress.sh`, `tests/fail-closed.sh`, `agents/format-mkdocs.md`, `docs/chrome-inventory.md`, `README.md`, `README.pt-BR.md`) returned zero matches.

### Human Verification Required

None. All must-haves are verifiable programmatically (file presence, catalog sourcing, grep-based literal/keyset checks, and direct execution of the regression and fail-closed harnesses).

### Gaps Summary

No gaps. All 12 merged truths (4 ROADMAP Success Criteria + PLAN-specific must-haves from both 02-01 and 02-02) verified against the actual codebase, not just SUMMARY.md claims. Both required commands ran clean:

- `bash tests/regress.sh` → exit 3 (correct — only the pwsh leg is SKIPPED on this Linux host, which is the expected result per the harness's own documented SKIPPED/exit-3 contract), `OK: mkdocs (mkdocs.yml + docs/) identical` present, no `FAIL:` lines.
- `bash tests/fail-closed.sh` → exit 0, 9 `OK:` lines (≥8 required), no `FAIL:` lines.
- `git diff --quiet HEAD -- tests/fixtures/golden-sh/` → exit 0 (goldens untouched).

Note (non-blocking, informational): `.planning/REQUIREMENTS.md` still shows CHROME-01/03/04 as unchecked (`- [ ]`) despite being satisfied by this phase — this is a traceability-doc staleness item typically closed during `/gsd-ship`/`/gsd-complete-milestone`, not a phase-goal gap.

---

_Verified: 2026-09-29T17:34:22Z_
_Verifier: Claude (gsd-verifier)_
