---
phase: 01-contrato-golden-fixtures
plan: 01
subsystem: testing
tags: [golden-fixtures, regression-harness, bash, fixtures, byte-identical]

# Dependency graph
requires:
  - phase: 00 (quality-alignment milestone)
    provides: cadeia `.sh` atual (generate-mkdocs/generate-index/to-pdf/to-dokuwiki) e fixture validada inventariada no 01-RESEARCH.md
provides:
  - tests/regress.sh — harness capture/regress com pin LC_ALL=C.UTF-8, workdir mktemp, máscara simétrica __DATE__ e regime SKIPPED/exit 3
  - tests/fixtures/tree/.specs/** — árvore de entrada commitada (7 arquivos, diretório acentuado features/autenticação/)
  - tests/fixtures/golden-sh/{mkdocs,pdf,swagger}/** — goldens engine-less da cadeia .sh congelados byte a byte
  - tests/fixtures/manifest.md — registro dos pins, da máscara e das invariantes da captura
affects: [01-02 (inventário de chrome), 01-03 (goldens dokuwiki + .ps1), phase-02 (checkpoint duro de byte-idêntico), phase-04 (wiring no fluxo de release)]

# Actuals (#2632)
actuals:
  tokens: 8748
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: [] # nenhuma dependência nova — bash + coreutils + sed + diff apenas
  patterns:
    - "Golden por geminho e por superfície: capture é o único escritor; diff mascarado simétrico é o guardião"
    - "Regime SKIPPED + exit 3 para perna dependente de dev-only engine (máquina-detectável, nunca silenciosa)"
    - "Pin LC_ALL=C.UTF-8 em tudo que roda a cadeia (title-case sed corrompe acento em locale C)"
    - "Captura sempre em mktemp -d fora de git (origin URL não vaza para o golden)"

key-files:
  created:
    - tests/regress.sh
    - tests/fixtures/tree/.specs/project/PROJECT.md
    - tests/fixtures/tree/.specs/project/ROADMAP.md
    - tests/fixtures/tree/.specs/codebase/ARCHITECTURE.md
    - tests/fixtures/tree/.specs/features/login/spec.md
    - tests/fixtures/tree/.specs/features/login/design.md
    - tests/fixtures/tree/.specs/features/autenticação/spec.md
    - tests/fixtures/tree/.specs/quick/fix-nav/spec.md
    - tests/fixtures/golden-sh/mkdocs/mkdocs.yml
    - tests/fixtures/golden-sh/mkdocs/docs/index.md
    - tests/fixtures/golden-sh/mkdocs/docs/specs/ (mirror, 8 arquivos)
    - tests/fixtures/golden-sh/pdf/specs-book.pdf
    - tests/fixtures/golden-sh/swagger/index.html
    - tests/fixtures/manifest.md
  modified: []

key-decisions:
  - "Tree reconstruída do inventário do 01-RESEARCH.md (fixture /tmp/mdw-sr3 irrecuperável) com prosa nova aprovada pelo usuário em checkpoint antes de prosseguir"
  - "AUDIENCE=general na captura (D-11) — a réplica não herda o developer da fixture original"
  - "Perna DokuWiki e perna .ps1 entram como SKIPPED/exit 3 neste plano; captura real chega na 01-03 (D-03/D-09)"

patterns-established:
  - "Exit 3 = execução parcial SKIPPED; exit 1 = diff; exit 0 = verde pleno"
  - "Máscara de data simétrica sobre cópias em tmp, nunca in-place"

requirements-completed: [QUAL-02]

coverage:
  - id: D1
    description: "Harness tests/regress.sh com modos capture/regress, pin LC_ALL=C.UTF-8, workdir mktemp fora do repo, máscara __DATE__ simétrica e exit codes 0/1/3"
    requirement: QUAL-02
    verification:
      - kind: integration
        ref: "bash tests/regress.sh → rc=3 com SKIPPED: pandoc + SKIPPED: pwsh e 3 superfícies OK (date-masked)"
        status: pass
      - kind: unit
        ref: "grep '# Usage: regress.sh [capture]' | 'set -euo pipefail' | 'LC_ALL=C.UTF-8' | '__DATE__' | 'MDW_INDEX_OUT'=0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Árvore de entrada commitada com 7 arquivos .md, conteúdo 100% ASCII, zero datas ISO e diretório acentuado features/autenticação/ atravessando a cadeia sem corrupção"
    requirement: QUAL-02
    verification:
      - kind: unit
        ref: "find tests/fixtures/tree -type f | wc -l = 7; grep -c 'Autenticação' golden docs/index.md = 1; grep ISO dates na tree = vazio"
        status: pass
      - kind: manual_procedural
        ref: "checkpoint humano: usuário aprovou o conteúdo reconstruído da tree como está"
        status: pass
    human_judgment: false
  - id: D3
    description: "Goldens engine-less congelados (mkdocs.yml + docs/index.md + mirror docs/specs, specs-book.pdf fallback, swagger-ui/index.html) byte a byte com a cadeia atual não modificada"
    requirement: QUAL-02
    verification:
      - kind: integration
        ref: "diff -r mascarado por superfície: 3× OK; repo_url vazio com espaço trailing congelado; sem github.com no mkdocs.yml; git diff scripts/ templates/ vazio"
        status: pass
    human_judgment: false
  - id: D4
    description: "manifest.md registrando pins (PROJECT_NAME/AUDIENCE/locale/cwd/ordem dos 7 arquivos), máscara com os 3 sítios datados, invariantes da tree e proibição de edição manual"
    requirement: QUAL-02
    verification:
      - kind: unit
        ref: "grep -E 'PROJECT_NAME=TestProject|AUDIENCE=general|LC_ALL=C.UTF-8|__DATE__|mktemp|autenticação' = 6; 'generate-index.ps1:84' = 1; 'to-pdf.ps1' = 2"
        status: pass
    human_judgment: false

# Metrics
duration: 14min
completed: 2026-09-29
status: complete
commits: 2
plan_head_before: 9f1ce3162d0563fa59932fcb17826e284909a96a
plan_head_after: ae0e411cc40272572283dca92056b18d0af9b0f2
---

# Phase 1 Plan 1: Contrato & Golden Fixtures — Tracer .sh Summary

**Walking skeleton da fase: árvore de specs commitada atravessa a cadeia `.sh` não modificada, goldens engine-less congelados (mkdocs/pdf/swagger) e harness de diff byte a byte com máscara simétrica de data — exit 3 com SKIPPED nomeado quando falta pwsh/pandoc (D-04).**

## Performance

- **Duration:** 14min
- **Started:** 2026-09-29T11:40:46Z
- **Completed:** 2026-09-29T11:54:58Z
- **Tasks:** 2/2
- **Files modified:** 20 (todos novos)

## Accomplishments
- Barra de regressão QUAL-02 (parcela engine-less) executável: `bash tests/regress.sh` valida as 3 superfícies engine-less como idênticas à cadeia atual, sem engines e sem tocar `scripts/`/`templates/`
- Árvore de teste permanente commitada com o diretório acentuado `features/autenticação/` — o label `Autenticação` chega íntegro ao golden sob o pin de locale (critério de corrupção de bytes da Phase 3 já ancorado)
- Regime SKIPPED/exit 3 provado por execução real: pernas DokuWiki e `.ps1` reportam motivo e o exit code distingue parcial (3) de falha (1)

## Task Commits

1. **Task 1: Árvore de fixture + harness regress.sh + captura dos goldens .sh engine-less** — `f2faeb9` (feat)
2. **Task 2: manifest.md — registro dos pins, da máscara e das invariantes** — `ae0e411` (docs)

**Plan metadata:** (commitado após este arquivo)

## Files Created/Modified
- `tests/regress.sh` — harness capture/regress; único código novo do plano
- `tests/fixtures/tree/.specs/**` — 7 arquivos .md de entrada (conteúdo ASCII, diretório acentuado)
- `tests/fixtures/golden-sh/{mkdocs,pdf,swagger}/**` — goldens congelados (11 arquivos)
- `tests/fixtures/manifest.md` — registro de captura reprodutível

## Decisions Made
- **Reconstrução da tree aprovada em checkpoint:** a fixture `/tmp/mdw-sr3` estava ausente (Pitfall 10 confirmado); a tree foi reconstruída pelo inventário do 01-RESEARCH.md com prosa nova, e o usuário aprovou o conteúdo como está antes da captura (branch desenhado pela própria precondition da Task 1)
- **AUDIENCE=general** na captura (D-11) — exercita a tabela de seções do index
- **Pernas DokuWiki/.ps1 como SKIPPED** neste plano, com mensagem nomeando a 01-03 quando a engine está presente mas a perna ainda não está wired

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Variável local referenciada antes da atribuição no compare_surface**
- **Found during:** Task 1 (primeira execução do regress)
- **Issue:** `local label="$1" rel="$2" g="$3/$rel"` — `$rel` expandido na mesma declaração `local`, antes da atribuição → `rel: unbound variable` sob `set -u`
- **Fix:** declaração separada (`local ... g f out` seguida de atribuições)
- **Files modified:** tests/regress.sh
- **Verification:** regress completo verde (rc=3, 3 superfícies OK)
- **Committed in:** f2faeb9

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug de shell)
**Impact on plan:** nenhum — corrigido antes da primeira captura válida

## Issues Encountered
- `/tmp/mdw-sr3` confirmado ausente no host — resolvido pelo branch desenhado na precondition (reconstrução + checkpoint humano aprovado). Registrado como decisão, não como bloqueio.

## User Setup Required
None - no external service configuration required. (pwsh/pandoc como dev-deps entram na 01-03, com passo sudo acompanhado.)

## Next Phase Readiness
- Ready for 01-02 (inventário de chrome) — não depende dos goldens
- 01-03 vai preencher o baseline do manifest (`pwsh --version`, `pandoc --version`) e capturar os goldens dokuwiki + `.ps1` (incl. a exceção D-10 já documentada)
- Phase 2 tem agora o checkpoint duro: `bash tests/regress.sh` deve continuar rc=3 com as 3 superfícies OK após qualquer refactor de strings

---
*Phase: 01-contrato-golden-fixtures*
*Completed: 2026-09-29*
