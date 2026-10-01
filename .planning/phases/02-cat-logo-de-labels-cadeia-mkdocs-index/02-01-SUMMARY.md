---
phase: 02-cat-logo-de-labels-cadeia-mkdocs-index
plan: 01
subsystem: docs-generation
tags: [bash, i18n, chrome-catalog, mkdocs, generate-index, regression-fixture]

# Dependency graph
requires:
  - phase: 01-contrato-golden-fixtures
    provides: "Golden fixtures (tests/fixtures/golden-sh/) e tests/regress.sh como barra de regressão byte-idêntica"
provides:
  - "templates/lang/en.lang — catálogo `en` com 33 chaves, fonte única de chrome para as 5 superfícies"
  - "scripts/generate-index.sh refatorado: assinatura de 4 posicionais, bootstrap de catálogo, allowlist de idioma, gate fail-closed sobre 29 chaves"
  - "tests/regress.sh alinhado à nova assinatura da perna index"
  - "agents/format-mkdocs.md transmitindo OUTPUT_LANG pelo dispatch"
  - "docs/chrome-inventory.md com nota de fronteira label/markup"
affects: ["02-02 (generate-mkdocs.sh replica o mesmo padrão)", "Phase 3 (consumo de pdf_title, swagger_title_suffix, catálogo pt-br)"]

# Actuals (#2632)
actuals:
  tokens: 4036
  tasks: 2
  commits: 2
  plan_head_before: 4ff2cd02adf29eed90a0580529cd71d57f4fbd05
  plan_head_after: 5dbe8218116de0f69e6b9ef63cdb51a139e3ec9b

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Catálogo de labels KEY='value' carregado via `set -a; . \"$CATALOG\"; set +a` com path derivado de `${BASH_SOURCE[0]}`"
    - "Allowlist de idioma via `case` executada ANTES de compor o path do catálogo (barreira de path traversal)"
    - "Gate fail-closed up-front: uma linha `: \"${chave:?...}\"` por chave consumida, agrupada num bloco único no topo do script"
    - "Fronteira label/markup: valor da chave = texto do rótulo; markup (heading, separadores de tabela) fica no format string do gerador"

key-files:
  created:
    - templates/lang/en.lang
  modified:
    - scripts/generate-index.sh
    - tests/regress.sh
    - agents/format-mkdocs.md
    - docs/chrome-inventory.md

key-decisions:
  - "OUTPUT_LANG é o terceiro posicional obrigatório de generate-index.sh (sem default no script); AUDIENCE mantém seu default `general` inalterado"
  - "cell_absent vira chave de catálogo (glifo em-dash emitido quando arquivo ausente), preservando o comportamento exato do golden"
  - "generated_by expande como format string do printf (não como argumento %s) para que o %s do valor seja interpretado como specifier da data — evita a dupla-interpretação do Pitfall 5"
  - "Catálogo completo (33 chaves) criado nesta fase, mesmo com pdf_title e swagger_title_suffix sem consumidor ainda — ficam prontas para a Phase 3"

patterns-established:
  - "Bootstrap de catálogo replicável: SCRIPT_DIR via cd+pwd, CATALOG derivado, allowlist antes do path, set -a/./set +a, gate fail-closed em bloco — o plano 02-02 replica este padrão em generate-mkdocs.sh"

requirements-completed: [CHROME-01, CHROME-03, CHROME-04]

coverage:
  - id: D1
    description: "Catálogo templates/lang/en.lang com 33 chaves, UTF-8 sem BOM, carrega sem erro via set -a; . file; set +a"
    requirement: CHROME-01
    verification:
      - kind: other
        ref: "bash -c 'set -a; . templates/lang/en.lang; set +a' (sourced_ok); grep -oE dos 33 pares chave=' (keys=33); ausência de BOM (od -An -tx1)"
        status: pass
    human_judgment: false
  - id: D2
    description: "generate-index.sh emite 100% do chrome por lookup de catálogo — zero string de chrome fixa, 29 chaves expandidas, 29 gates fail-closed"
    requirement: CHROME-03
    verification:
      - kind: other
        ref: "grep de literais de chrome fora de comentário (hardcoded_chrome=0); contagem de chaves expandidas (keys_expanded=29); contagem de gates (keys_gated=29)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Allowlist de OUTPUT_LANG (en|pt-br) valida ANTES de compor o path do catálogo; idioma desconhecido ou ausente interrompe nomeando os suportados"
    requirement: CHROME-03
    verification:
      - kind: other
        ref: "bash scripts/generate-index.sh TestProject general klingon (rc!=0, mensagem cita pt-br); bash scripts/generate-index.sh TestProject general (rc!=0, $3 obrigatório)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Passthrough de labels derivados de diretório preservado: sed de title-case aparece 1 vez, nenhuma variável de catálogo atravessa o pipeline"
    requirement: CHROME-04
    verification:
      - kind: other
        ref: "grep -oF do sed title-case (titlecase_sites=1); grep negativo confirmando nenhuma ${catalog_var} no mesmo pipeline"
        status: pass
    human_judgment: false
  - id: D5
    description: "Regressão byte-idêntica: bash tests/regress.sh reproduz o golden da Phase 1 com OUTPUT_LANG=en explícito, goldens intocados"
    verification:
      - kind: other
        ref: "bash tests/regress.sh (rc=3, linha 'OK: mkdocs (mkdocs.yml + docs/) identical', nenhuma linha FAIL:); git diff --quiet HEAD -- tests/fixtures/golden-sh/ (rc=0); diff direto docs/index.md fresco vs golden (vazio)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Dispatch do agent transmite OUTPUT_LANG a generate-index (nunca env var); chamada de generate-mkdocs no passo 2 permanece intocada; inventário ganha nota aditiva de fronteira label/markup"
    verification:
      - kind: other
        ref: "grep 'generate-index' + OUTPUT_LANG em agents/format-mkdocs.md (dispatch_ok); grep negativo confirmando chamada de generate-mkdocs inalterada; git diff docs/chrome-inventory.md sem linhas removidas"
        status: pass
    human_judgment: false

duration: ~25min
completed: 2026-09-29
status: complete
---

# Phase 2 Plan 1: Catálogo `en` + generate-index.sh por lookup Summary

**Catálogo `templates/lang/en.lang` (33 chaves) extraído verbatim dos scripts vivos, `generate-index.sh` refatorado para emitir 100% do chrome por lookup com gate fail-closed e allowlist de idioma, `bash tests/regress.sh` reproduzindo o golden da Phase 1 byte-idêntico.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-09-29T17:08:33Z
- **Tasks:** 2
- **Files modified:** 5 (1 criado, 4 modificados)

## Accomplishments
- Criado `templates/lang/en.lang`: 33 chaves namespaced por superfície (`site_*`/`nav_*` MkDocs, `index_*`/`section_*`/`label_*`/`table_*`/`desc_*`/`cell_absent`/`generated_by` index, `pdf_*` e `swagger_*` prontas para a Phase 3), UTF-8 sem BOM, valores copiados linha a linha dos sítios vivos
- `scripts/generate-index.sh` refatorado com assinatura `<project_name> <audience> <output_lang> [feature_base_dirs...]`, bootstrap de catálogo via `${BASH_SOURCE[0]}`, allowlist `case` de idioma ANTES de compor o path (barreira T-02-01), gate fail-closed cobrindo as 29 chaves expandidas, zero string de chrome fixa
- `tests/regress.sh` alinhado (perna index passa `en` explicitamente); `agents/format-mkdocs.md` transmite `$OUTPUT_LANG` no dispatch; `docs/chrome-inventory.md` ganha nota aditiva de fronteira label/markup
- Barreira dura da fase confirmada: `bash tests/regress.sh` sai 3 (mkdocs/pdf/swagger/dokuwiki OK, apenas pwsh SKIPPED) com a saída `docs/index.md` byte-idêntica ao golden mesmo comparada diretamente fora do harness

## Task Commits

Each task was committed atomically:

1. **Task 1: Catálogo en.lang + generate-index.sh por lookup + regressão byte-idêntica** - `6f406ce` (feat)
2. **Task 2: Transmissão do idioma pelo dispatch do agent + nota de fronteira no inventário** - `5dbe821` (docs)

_Nenhuma task TDD nesta fase — commits únicos por task._

## Files Created/Modified
- `templates/lang/en.lang` - Catálogo `en` novo, 33 chaves `KEY='value'`, UTF-8 sem BOM
- `scripts/generate-index.sh` - Refatorado: bootstrap de catálogo, allowlist de idioma, gate fail-closed, zero chrome fixo
- `tests/regress.sh` - Perna index passa `en` explicitamente na terceira posição
- `agents/format-mkdocs.md` - Passo 3 transmite `$OUTPUT_LANG`; nota de fail-closed sem fallback
- `docs/chrome-inventory.md` - Nota aditiva registrando a fronteira label/markup e o ponteiro para `en.lang`

## Decisions Made
- `OUTPUT_LANG` como terceiro posicional obrigatório (sem default no script) — o default `pt-br` vive só no contrato/onboarding, nunca no script, para não reintroduzir o mecanismo de saída mista
- `cell_absent` promovido a chave de catálogo (era literal `printf '—'`) para cobrir o glifo em-dash emitido no ramo "arquivo ausente" — mantém CHROME-01 (todo chrome por lookup) sem quebrar o comportamento do golden
- `generated_by` expande como o próprio format string do `printf` (aspas duplas), não como argumento — é o único jeito do `%s` do valor ser interpretado como specifier da data (Pitfall 5 da research)
- Catálogo completo (33 chaves, incluindo `pdf_title` e `swagger_title_suffix` sem consumidor nesta fase) criado de uma vez, evitando um segundo round de extração verbatim na Phase 3

## Deviations from Plan

None - plan executado exatamente como escrito. Todas as 29 chaves expandidas, 29 gates fail-closed, 33 chaves no catálogo, allowlist de idioma antes do path, sed de title-case intocado, regressão byte-idêntica confirmada tanto pelo harness quanto por diff direto do `docs/index.md` fresco contra o golden.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- O padrão de bootstrap de catálogo (allowlist → SCRIPT_DIR/CATALOG → set -a/./set +a → gate fail-closed) está provado e pronto para o plano 02-02 replicar em `scripts/generate-mkdocs.sh`
- `site_name_suffix` já está no catálogo compartilhado, pronta para o consumo do 02-02
- `pdf_title` e `swagger_title_suffix` estão no catálogo, aguardando consumo na Phase 3
- Nenhum bloqueio conhecido para o próximo plano

---
*Phase: 02-cat-logo-de-labels-cadeia-mkdocs-index*
*Completed: 2026-09-29*

## Self-Check: PASSED

- FOUND: templates/lang/en.lang
- FOUND: scripts/generate-index.sh
- FOUND: tests/regress.sh
- FOUND: agents/format-mkdocs.md
- FOUND: docs/chrome-inventory.md
- FOUND: commit 6f406ce (Task 1)
- FOUND: commit 5dbe821 (Task 2)
- FOUND: commit fe04da2 (this SUMMARY.md)
