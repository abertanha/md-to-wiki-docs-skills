---
phase: 01-contrato-golden-fixtures
plan: 03
subsystem: [testing, fixtures]
tags: [golden-fixtures, dokuwiki, pandoc, regress, pwsh]

# Dependency graph
requires:
  - phase: 01-01
    provides: engine-less .sh golden fixtures and regress harness baseline
provides:
  - DokuWiki .sh golden fixtures (tests/fixtures/golden-sh/dokuwiki/) — 7 spec files converted via pandoc
  - run_dokuwiki_sh() function in regress.sh — pandoc-gated, same file list as PDF surface
  - Manifest updated with pandoc version pin and pwsh absence documented
  - regress.sh exit behavior: 4 legs OK, .ps1 SKIPPED → exit 3 (correct for Linux/WSL hosts)
affects: [phase-02, phase-03, phase-04]

actuals:
  tokens: 1800
  tasks: 2
  commits: 1

tech-stack:
  added: [pandoc 3.7.0.2 (dev-only)]
  patterns: [pandoc-gated-leg — command -v pandoc gates DokuWiki perna; SKIPPED/exit 3 for missing dev-only dep]

key-files:
  created:
    - tests/fixtures/golden-sh/dokuwiki/README.md
    - tests/fixtures/golden-sh/dokuwiki/data/pages/codebase:ARCHITECTURE.txt
    - tests/fixtures/golden-sh/dokuwiki/data/pages/features:autenticação:spec.txt
    - tests/fixtures/golden-sh/dokuwiki/data/pages/features:login:design.txt
    - tests/fixtures/golden-sh/dokuwiki/data/pages/features:login:spec.txt
    - tests/fixtures/golden-sh/dokuwiki/data/pages/project:PROJECT.txt
    - tests/fixtures/golden-sh/dokuwiki/data/pages/project:ROADMAP.txt
    - tests/fixtures/golden-sh/dokuwiki/data/pages/quick:fix-nav:spec.txt
  modified:
    - tests/regress.sh
    - tests/fixtures/manifest.md

key-decisions:
  - "PowerShell (.ps1 perna) é para usuários Windows — não é dependência de dev neste host WSL; golden-ps1 aguarda host com pwsh"
  - "exit 3 neste host é o resultado CORRETO: 4 legs OK, .ps1 SKIPPED por design (D-03/D-04)"
  - "DokuWiki perna version-pinned ao pandoc 3.7.0.2 — atualização de pandoc pode exigir nova captura"
  - "Golden DokuWiki não precisa de máscara de data — to-dokuwiki.sh não emite datas no output"

patterns-established:
  - "pandoc-gated leg: command -v pandoc gate + case $MODE (capture/regress) + mktemp fora do repo — mesmo regime da cadeia .sh principal"
  - "SKIPPED/exit 3 documenta dependência de dev ausente sem falhar o diff — machine-detectable e nunca silencioso"

requirements-completed: [QUAL-02]

coverage:
  - id: D1
    description: "DokuWiki .sh golden capturado: 7 arquivos de spec convertidos por pandoc, golden commitado e verificado byte-estável"
    requirement: QUAL-02
    verification:
      - kind: manual_procedural
        ref: "bash tests/regress.sh → OK: dokuwiki identical; exit 3 (SKIP .ps1 apenas)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Harness estendido: run_dokuwiki_sh() wired, regress/capture modes funcionais para DokuWiki .sh"
    requirement: QUAL-02
    verification:
      - kind: manual_procedural
        ref: "bash tests/regress.sh capture → Captured DokuWiki golden; bash tests/regress.sh → OK: dokuwiki identical"
        status: pass
    human_judgment: false
  - id: D3
    description: "Manifest atualizado: pandoc 3.7.0.2 registrado, pwsh absence documentada, version-pin da perna DokuWiki"
    requirement: QUAL-02
    verification:
      - kind: manual_procedural
        ref: "grep 'pandoc 3.7.0.2' tests/fixtures/manifest.md → 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "golden-ps1 e DokuWiki .ps1: SKIPPED neste host (Linux/WSL sem pwsh) — comportamento correto D-03/D-04"
    requirement: QUAL-02
    verification: []
    human_judgment: true
    rationale: "A ausência de golden-ps1 neste host é intencional e documentada; não pode ser auto-verificada sem pwsh. Requer confirmação humana de que o regime SKIPPED é aceitável para este milestone."

duration: 20min
completed: 2026-09-29
status: complete
---

# Phase 01 Plan 03 Summary

**DokuWiki `.sh` golden capturado com pandoc 3.7.0.2 e harness estendido; perna `.ps1` permanece SKIPPED neste host Linux/WSL por design — exit 3 é o resultado correto.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-29
- **Completed:** 2026-09-29
- **Tasks:** 2 (Task 1 = gate humano resolvido: pandoc instalado, pwsh não aplicável; Task 2 = captura + harness)
- **Files modified:** 10 (1 regress.sh + 1 manifest.md + 8 golden DokuWiki)

## Accomplishments

- `tests/regress.sh` estendido com `run_dokuwiki_sh()` e lógica real de capture/regress para perna DokuWiki (substituindo placeholder SKIP do 01-01)
- `tests/fixtures/golden-sh/dokuwiki/` capturado: 7 arquivos de specs convertidos para DokuWiki syntax via pandoc, incluindo `features:autenticação:spec.txt` (UTF-8 preservado)
- `tests/fixtures/manifest.md` atualizado: pandoc 3.7.0.2 registrado, ausência de pwsh documentada como regime correto para host Linux/WSL, perna DokuWiki marcada como version-pinned
- `bash tests/regress.sh` resulta em exit 3 neste host: 4 legs OK (`mkdocs`, `pdf`, `swagger`, `dokuwiki`), 1 SKIPPED (`.ps1`) — comportamento correto por D-03/D-04

## Task Commits

1. **Task 1: gate humano** — pandoc ✓ disponível; pwsh ✗ não aplicável para este ambiente WSL
2. **Task 2: captura e harness** — `e26cd0f` (feat(01-03))

## Files Created/Modified

- `tests/regress.sh` — adicionada função `run_dokuwiki_sh()` e lógica real de DokuWiki capture/regress; .ps1 SKIP atualizado com mensagem de host Linux/WSL
- `tests/fixtures/golden-sh/dokuwiki/README.md` — instrução de importação DokuWiki
- `tests/fixtures/golden-sh/dokuwiki/data/pages/*.txt` — 7 arquivos de spec em DokuWiki syntax
- `tests/fixtures/manifest.md` — baseline de versão, documentação do regime SKIPPED .ps1, version-pin DokuWiki

## Decisions Made

- **pwsh não instalado no WSL**: os gêmeos `.ps1` são para usuários Windows — não faz sentido instalar pwsh só para captura de golden neste ambiente. O regime SKIPPED/exit 3 é o comportamento correto e documentado.
- **Golden-ps1 diferido**: a captura dos goldens `.ps1` (golden-ps1/{mkdocs,pdf,dokuwiki,swagger}) requer host com pwsh. Deferred para quando o CI ou um host Windows executar o harness pela primeira vez.
- **DokuWiki sem máscara de data**: `to-dokuwiki.sh` não emite datas — nenhuma máscara necessária para esta superfície.

## Deviations from Plan

### golden-ps1 não capturado (SKIPPED intencional)

- **Previsto no plano:** captura dos goldens `.ps1` (MkDocs, PDF, DokuWiki, Swagger) via pwsh no Linux
- **Decisão do usuário:** `pwsh` não é dependência deste ambiente (WSL) — a skill `.ps1` é para Windows
- **Impacto:** exit 3 em vez de exit 0 neste host. O plano previa exit 0 com pwsh E pandoc. exit 3 com só pandoc é o resultado CORRETO para este host class.
- **Documentado em:** manifest.md, este SUMMARY, STATE.md

---

**Total deviations:** 1 — golden-ps1 diferido (intencional, acordado com usuário)
**Impact on plan:** exit 3 em vez de exit 0, mas o comportamento de regressão é correto. QUAL-02 atendido parcialmente: golden-sh completo (5 superfícies .sh), golden-ps1 aguarda host com pwsh.

## Issues Encountered

Nenhum problema técnico. A ausência de pwsh foi esclarecida pelo usuário como decisão de ambiente, não bloqueador.

## User Setup Required

None — pandoc já instalado. Para capturar golden-ps1 futuramente: instalar pwsh em host Windows ou Linux com pwsh e rodar `bash tests/regress.sh capture`.

## Next Phase Readiness

- **Phase 01 encerrada:** golden-sh completo (5 superfícies), DokuWiki capturado, manifest com baseline
- **Phase 02 (Catálogo de Labels & Cadeia MkDocs/index):** pode iniciar — `docs/chrome-inventory.md` e CONTEXT.md estão prontos como input
- **Gap registrado:** golden-ps1 aguarda host com pwsh (não bloqueador para Phase 2-3)

---
*Phase: 01-contrato-golden-fixtures*
*Completed: 2026-09-29*
