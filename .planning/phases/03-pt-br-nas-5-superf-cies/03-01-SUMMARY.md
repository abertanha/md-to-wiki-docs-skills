---
phase: 03-pt-br-nas-5-superf-cies
plan: 01
subsystem: i18n
tags: [bash, mkdocs-material, label-catalog, fail-closed-gate]

# Dependency graph
requires:
  - phase: 02-cat-logo-de-labels-cadeia-mkdocs-index
    provides: "templates/lang/en.lang, bootstrap de catálogo em generate-index.sh/generate-mkdocs.sh, tests/fail-closed.sh (keyset_equality, missing_key_halts, intact_catalog_succeeds, bad_language_halts)"
provides:
  - "templates/lang/pt-br.lang — catálogo pt-br completo, 34 chaves, paridade com en.lang exceto pdf_toc_title (allowlisted)"
  - "scripts/generate-mkdocs.sh emite `language: pt-BR` sob theme: condicionalmente (D-12)"
  - "tests/fail-closed.sh ganha o gate catalog_parity (permanente) e cobertura pt-br das gates existentes"
affects: [03-02, 03-03]

# Actuals (#2632)
actuals:
  tokens: 3133
  tasks: 3
  commits: 3
  plan_head_before: f1f32be4da430edf21932739fa8eb1def10f8fc2
  plan_head_after: c1e5dae49347b9537cd5740f4b1eca6ce230e4f3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Emissão aditiva condicional via variável UPPERCASE fora do vocabulário de catálogo (THEME_LANGUAGE) — reutilizável por to-pdf.sh (D-13) nos próximos planos"
    - "Gate de paridade de keyset com allowlist explícita de chaves idioma-exclusivas (nunca default silencioso)"
    - "Disambiguação de parâmetro opcional por sufixo de nome de arquivo (*.lang) para manter call sites antigos intocados"

key-files:
  created:
    - templates/lang/pt-br.lang
    - .planning/phases/03-pt-br-nas-5-superf-cies/deferred-items.md
  modified:
    - scripts/generate-mkdocs.sh
    - tests/fail-closed.sh

key-decisions:
  - "pt-br.lang espelha ordem e agrupamentos de en.lang por superfície, para diff lado a lado legível (facilita auditoria de paridade em planos futuros)"
  - "THEME_LANGUAGE é variável de script MAIÚSCULA, não chave de catálogo — mantém o gate keyset_equality (filtro [a-z]) imune a falso positivo"
  - "missing_key_halts ganha 3º parâmetro opcional catalog_basename detectado pelo sufixo .lang, preservando as 3 chamadas antigas sem alteração"
  - "Divergência pré-existente de shfmt (estilo 2-espaços do repo vs default do shfmt) em generate-mkdocs.sh e fail-closed.sh não foi corrigida — fora do escopo desta tarefa (SCOPE BOUNDARY); registrada em deferred-items.md"

patterns-established:
  - "Allowlist de chave idioma-exclusiva declarada como array de topo (PTBR_ONLY_ALLOWLIST) e nunca oculta dentro da função de gate"

requirements-completed: [CHROME-02, QUAL-01]

coverage:
  - id: D1
    description: "templates/lang/pt-br.lang criado com 34 chaves, UTF-8 sem BOM, paridade com en.lang exceto pdf_toc_title"
    requirement: "CHROME-02"
    verification:
      - kind: unit
        ref: "verify automated block 1 (Tarefa 1) — bom/keys/only_pt/only_en/sourced_ok"
        status: pass
    human_judgment: false
  - id: D2
    description: "Cadeia MkDocs + index sobre a fixture produz saída 100% PT-BR (headings, nav, site_name) sem heading em inglês"
    requirement: "CHROME-02"
    verification:
      - kind: integration
        ref: "verify automated block 2 (Tarefa 1) — tracer_ok"
        status: pass
    human_judgment: false
  - id: D3
    description: "generate-mkdocs.sh emite language: pt-BR sob theme: somente com output_lang=pt-br; en permanece byte-idêntico ao golden"
    requirement: "QUAL-01"
    verification:
      - kind: integration
        ref: "verify automated block (Tarefa 2) — ptbr_language_ok, en_omits_language_ok"
        status: pass
      - kind: integration
        ref: "tests/regress.sh — OK: mkdocs (mkdocs.yml + docs/) identical"
        status: pass
    human_judgment: false
  - id: D4
    description: "tests/fail-closed.sh falha quando o keyset de pt-br.lang diverge de en.lang fora da allowlist explícita (pdf_toc_title)"
    requirement: "QUAL-01"
    verification:
      - kind: unit
        ref: "tests/fail-closed.sh — OK: catalog_parity"
        status: pass
      - kind: unit
        ref: "negative control (chave órfã injetada em sandbox) — negative_control_ok"
        status: pass
      - kind: unit
        ref: "negative control (allowlist esvaziada em sandbox) — allowlist_is_load_bearing_ok"
        status: pass
    human_judgment: false

duration: 57min
completed: 2026-09-29
status: complete
---

# Phase 03 Plan 01: Catálogo pt-br + tracer MkDocs/index + gate de paridade Summary

**Catálogo `templates/lang/pt-br.lang` (34 chaves) provado de ponta a ponta na cadeia MkDocs/index, `language: pt-BR` condicional em `generate-mkdocs.sh`, e gate `catalog_parity` permanente em `tests/fail-closed.sh` travando qualquer divergência de keyset fora da allowlist `pdf_toc_title`.**

## Performance

- **Duration:** 57 min
- **Started:** 2026-09-29T16:05:40-03:00
- **Completed:** 2026-09-29T17:02:23-03:00
- **Tasks:** 3/3
- **Files modified:** 4 (1 criado, 2 modificados, 1 log de itens deferidos)

## Accomplishments
- `templates/lang/pt-br.lang` criado com as 34 chaves canônicas do plano (33 espelhando `en.lang` + `pdf_toc_title` exclusiva), UTF-8 sem BOM, fonte limpa via `set -a; . …; set +a`
- Tracer de ponta a ponta: `generate-mkdocs.sh` e `generate-index.sh` com `OUTPUT_LANG=pt-br` sobre a fixture produzem `site_name`, nav e headings 100% em PT-BR, incluindo `Autenticação` sem mojibake (SC4)
- `generate-mkdocs.sh` emite `language: pt-BR` sob `theme:` apenas quando `output_lang=pt-br`, via variável de script `THEME_LANGUAGE` (fora do vocabulário de catálogo) — saída `en` continua byte-idêntica ao golden
- `tests/fail-closed.sh` ganha o gate `catalog_parity` (permanente, com allowlist explícita `PTBR_ONLY_ALLOWLIST=(pdf_toc_title)`), `keyset_equality` generalizado para a união dos dois catálogos, e `missing_key_halts` com `catalog_basename` opcional — todas as gates existentes agora exercitadas também no branch `pt-br`

## Task Commits

Each task was committed atomically:

1. **Tarefa 1: Tracer — catálogo pt-br.lang e cadeia MkDocs/index 100% PT-BR de ponta a ponta** - `d6cdf60` (feat)
2. **Tarefa 2: theme.language pt-BR condicional em generate-mkdocs.sh** - `4cf4242` (feat)
3. **Tarefa 3: Gate de paridade en↔pt-br e probes pt-br em tests/fail-closed.sh** - `c1e5dae` (test)

**Plan metadata:** commit pendente (docs: complete plan) — ver `<final_commit>` desta execução.

## Files Created/Modified
- `templates/lang/pt-br.lang` - Catálogo pt-br, 34 chaves, espelha ordem/agrupamento de `en.lang`
- `scripts/generate-mkdocs.sh` - `THEME_LANGUAGE` condicional por `case "$OUTPUT_LANG"`, expandido no heredoc entre `name: material` e `features:`
- `tests/fail-closed.sh` - `CATALOG_PTBR`, `PTBR_ONLY_ALLOWLIST`, função `catalog_parity`, `keyset_equality` generalizado, `missing_key_halts` com `catalog_basename` opcional, 5 novas invocações no bloco final
- `.planning/phases/03-pt-br-nas-5-superf-cies/deferred-items.md` - Log de divergência pré-existente de `shfmt` (não corrigida, fora de escopo)

## Decisions Made
- Manter a MESMA ordem/agrupamento de `en.lang` em `pt-br.lang` para diff lado a lado legível entre catálogos (facilita auditoria de paridade nos próximos planos da fase)
- `THEME_LANGUAGE` é MAIÚSCULA de propósito — não é chave de catálogo (D-12), evitando falso positivo no filtro `[a-z]` do gate `keyset_equality`
- `missing_key_halts` detecta o parâmetro opcional `catalog_basename` pelo sufixo `.lang`, preservando as 3 chamadas pré-existentes sem alteração de assinatura visível

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - fora de escopo, apenas registrado] Divergência pré-existente de `shfmt`/`shellcheck` em `scripts/generate-mkdocs.sh` e `tests/fail-closed.sh`**
- **Found during:** Tarefa 2 e Tarefa 3
- **Issue:** `shfmt -d` reporta diff de estilo (2 espaços do repo vs. default de tabs do `shfmt`) e `shellcheck` reporta SC2018/SC2019 (info) em `generate-mkdocs.sh` — ambos confirmados **pré-existentes** via `git stash` (idênticos antes de qualquer edição desta plano). Nenhuma correção foi aplicada: reformatar o arquivo inteiro é fora do escopo da tarefa (SCOPE BOUNDARY) e arriscaria um diff desnecessariamente grande.
- **Fix:** Nenhuma — código novo segue a convenção de 2 espaços já estabelecida no arquivo, para não introduzir uma forma de divergência nova.
- **Files modified:** nenhum (apenas documentado)
- **Verification:** `git stash`/`shfmt -d`/`shellcheck` comparados antes e depois da edição — diff idêntico em ambos os pontos
- **Committed in:** `4cf4242` e `c1e5dae` (registro em `deferred-items.md` incluído em cada commit de tarefa)

---

**Total deviations:** 1 achado documentado, não corrigido (fora de escopo)
**Impact on plan:** Nenhum — não é regressão introduzida por este plano; `shellcheck` de `tests/fail-closed.sh` está limpo (exit 0), e o `shfmt` diverge apenas no estilo de indentação pré-existente do repositório.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `templates/lang/pt-br.lang` está pronto para ser consumido por `to-pdf.sh`, `to-dokuwiki.sh` e `templates/swagger-ui.html` nos planos 03-02/03-03
- O gate `catalog_parity` protege qualquer chave nova adicionada a `en.lang` sem contraparte em `pt-br.lang` (ou vice-versa, fora da allowlist) — os próximos planos que adicionarem chaves (`dokuwiki_readme_*`, etc.) precisam adicioná-las aos dois catálogos no mesmo commit
- Sem bloqueios conhecidos para 03-02

---
*Phase: 03-pt-br-nas-5-superf-cies*
*Completed: 2026-09-29*

## Self-Check: PASSED

All created/modified files found on disk; all 3 task commit hashes (`d6cdf60`, `4cf4242`, `c1e5dae`) found in git history.
