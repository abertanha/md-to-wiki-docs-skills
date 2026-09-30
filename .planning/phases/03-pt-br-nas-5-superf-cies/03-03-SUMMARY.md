---
phase: 03-pt-br-nas-5-superf-cies
plan: 03
subsystem: docs
tags: [bash, i18n, swagger-ui, shellcheck, shfmt, catalog-driven-chrome]

requires:
  - phase: 03-pt-br-nas-5-superf-cies
    provides: "catálogo pt-br.lang completo (03-01) e to-pdf.sh/to-dokuwiki.sh catalog-driven (03-02)"
provides:
  - "templates/swagger-ui.html parametrizado com {{LANG_ATTR}} e {{TITLE_SUFFIX}}"
  - "agents/format-swagger.md e agents/format-github-wiki.md sob o contrato de OUTPUT_LANG"
  - "tests/no-mixed-output.sh — gate permanente de zero saída mista (CHROME-02) nas 5 superfícies"
affects: [phase-04-gemeos-powershell-prosa-release]

actuals:
  tokens: 3868
  tasks: 3
  commits: 3
  plan_head_before: acf0988374dcd0c6831386c4d829ed1510e7794f
  plan_head_after: 0db75bc5df8173df6d7545a6b9270797e3fabfd4

tech-stack:
  added: []
  patterns:
    - "Placeholder aditivo em template HTML: {{LANG_ATTR}} carrega o atributo inteiro (espaço incluído), vazio em en, para preservar byte-identidade do golden — mesmo princípio de theme.language/-M lang já usado nas superfícies anteriores"
    - "Gate de zero saída mista por sandbox mktemp: gera as 5 superfícies com OUTPUT_LANG=pt-br, varre recortes de chrome nomeados (nunca conteúdo de specs), compara contra catálogo en com allowlist explícita"

key-files:
  created:
    - tests/no-mixed-output.sh
  modified:
    - templates/swagger-ui.html
    - tests/regress.sh
    - agents/format-swagger.md
    - agents/format-github-wiki.md

key-decisions:
  - "Desvio deliberado de D-09/D-10 (documentado no PLAN.md): {{LANG_ATTR}} carrega o atributo inteiro com espaço à esquerda, não só o valor — resolve o conflito entre 'lang aditivo' e o golden en byte-idêntico"
  - "Guarda fail-closed (: \"${swagger_title_suffix:?...}\") adicionada ao novo lookup dinâmico em tests/regress.sh para silenciar SC2154 introduzido pela própria mudança, seguindo o idioma :? já usado em todo o repo"
  - "tests/no-mixed-output.sh como harness dedicado (não extensão de fail-closed.sh) — decisão de estrutura delegada ao planner pelo D-14, resolvida a favor de um arquivo novo por ter contrato de saída (0/1/3) e escopo (5 superfícies) distintos dos gates existentes"

patterns-established:
  - "scan_surface()/check_positive() como par gate+controle-positivo reutilizável para qualquer harness de zero-saída-mista futuro (Phase 4, gêmeos .ps1)"

requirements-completed: [CHROME-02, QUAL-01]

coverage:
  - id: D1
    description: "templates/swagger-ui.html parametrizado — pt-br emite lang=\"pt-BR\" e título em PT-BR; en reproduz o golden byte a byte"
    requirement: "QUAL-01"
    verification:
      - kind: unit
        ref: "tests/regress.sh — OK: swagger (index.html) identical (date-masked)"
        status: pass
      - kind: unit
        ref: "manual pt-br render check (Task 1 verify) — <html lang=\"pt-BR\"> e <title>TestProject — Documentação da API</title>, zero {{ residual"
        status: pass
    human_judgment: false
  - id: D2
    description: "agents/format-swagger.md e agents/format-github-wiki.md reescritos sob o contrato de OUTPUT_LANG, com catálogo e limites documentados (D-11, CHROME-04)"
    requirement: "QUAL-01"
    verification:
      - kind: other
        ref: "grep de cobertura dos 4 placeholders + swagger_title_suffix + lang=\"pt-BR\" em format-swagger.md; das 6 chaves de catálogo + [[Page]] + en/pt-br em format-github-wiki.md (Task 2 verify)"
        status: pass
    human_judgment: false
  - id: D3
    description: "tests/no-mixed-output.sh — gate CHROME-02 de zero saída mista nas 5 superfícies pt-br, com allowlist explícita e dois controles negativos provados"
    requirement: "CHROME-02"
    verification:
      - kind: unit
        ref: "tests/no-mixed-output.sh — OK: mixed_output/positive_control × 5 superfícies, exit 0"
        status: pass
      - kind: unit
        ref: "negative control 1 — sandbox com nav_home='Home' produz FAIL: mixed_output mkdocs — chave nav_home, exit != 0"
        status: pass
      - kind: unit
        ref: "negative control 2 — sandbox com GLOSSARY_ALLOWLIST=() produz ao menos um FAIL:"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-09-30
status: complete
---

# Phase 3 Plan 3: Swagger UI parametrizado, agents sob contrato de OUTPUT_LANG e gate de zero saída mista Summary

**A quinta superfície publicável (Swagger UI) sai `lang="pt-BR"` e título PT-BR sem quebrar o golden `en`, e `tests/no-mixed-output.sh` prova por grep, com dois controles negativos, que nenhum valor `en` do catálogo vaza nas 5 superfícies pt-br.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3/3 completed
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments

- `templates/swagger-ui.html` ganhou os placeholders `{{LANG_ATTR}}` (atributo `lang` aditivo — vazio em `en`, ` lang="pt-BR"` em pt-br) e `{{TITLE_SUFFIX}}` (sufixo de título por catálogo), resolvendo o conflito documentado entre D-09/D-10 e o requisito de byte-identidade do golden `en`
- `tests/regress.sh` resolve o título Swagger pelo catálogo `en` no mesmo passo de sed que já rendeirza o template, mantendo `OK: swagger (index.html) identical` no golden
- `agents/format-swagger.md` e `agents/format-github-wiki.md` reescritos sob o contrato de `OUTPUT_LANG`: o primeiro com um procedimento determinístico de 4 passos (catálogo → atributo derivado por `case` → sed único → verificação de `{{` residual) e a nota de limite upstream D-11; o segundo com as 6 chaves de catálogo para o chrome de `Home.md`/`_Sidebar.md` e a proibição explícita de traduzir nomes de página/diretório e alvos `[[Page]]` (CHROME-04)
- `tests/no-mixed-output.sh` (novo, executável, 176 linhas) gera as 5 superfícies com `OUTPUT_LANG=pt-br` em sandbox `mktemp -d`, varre exatamente os recortes de chrome do plano (nunca `docs/specs/**`) e falha fechado quando qualquer valor `en` do catálogo (fora da allowlist `label_stack`/`label_roadmap`/`table_design`/`cell_absent`) aparece na saída pt-br — com controles positivos por superfície e dois controles negativos provados no verify

## Task Commits

Each task was committed atomically:

1. **Tarefa 1: swagger-ui.html parametrizado e a perna Swagger de tests/regress.sh** - `0769e5a` (feat)
2. **Tarefa 2: format-swagger.md e format-github-wiki.md sob o contrato de OUTPUT_LANG** - `dad654b` (docs)
3. **Tarefa 3: tests/no-mixed-output.sh — gate de zero saída mista** - `0db75bc` (test)

## Files Created/Modified

- `templates/swagger-ui.html` - dois placeholders novos (`{{LANG_ATTR}}`, `{{TITLE_SUFFIX}}`), nenhuma outra linha alterada
- `tests/regress.sh` - perna Swagger resolve `swagger_title_suffix` pelo catálogo `en` (com guarda fail-closed) e substitui `{{LANG_ATTR}}` por vazio (comportamento aditivo `en`)
- `agents/format-swagger.md` - step 4 reescrito como procedimento determinístico de 4 substituições; frase de contrato `OUTPUT_LANG`; nota de limite upstream D-11
- `agents/format-github-wiki.md` - chrome de `Home.md`/`_Sidebar.md` sob `$OUTPUT_LANG` e catálogo; proibição explícita de tradução de paths (CHROME-04); frase de contrato nos prerequisites
- `tests/no-mixed-output.sh` (novo) - gate CHROME-02 de zero saída mista, com `GLOSSARY_ALLOWLIST` explícito e dois controles negativos

## Decisions Made

- Aplicado o desvio deliberado já registrado no PLAN.md (seção "Desvio deliberado de D-09/D-10"): `{{LANG_ATTR}}` carrega o atributo inteiro (com o espaço à esquerda), não apenas o valor de `lang`, para que a substituição por vazio em `en` reproduza `<html>` byte a byte
- `tests/no-mixed-output.sh` implementado como harness dedicado (não extensão de `fail-closed.sh`), decisão delegada ao planner pelo D-14 — o contrato de saída (0/1/3) e o escopo (5 superfícies geradas do zero em sandbox) são suficientemente distintos dos gates estruturais existentes para justificar um arquivo próprio
- O catálogo `en.lang` é sourced no processo do próprio `tests/no-mixed-output.sh` SEM `set -a` (variáveis não exportadas) especificamente para que os processos `bash scripts/*.sh` filhos, invocados em seguida com `OUTPUT_LANG=pt-br`, nunca herdem um valor `en` do ambiente — a fonte da verdade de cada geração continua sendo o catálogo que o próprio script companion sourcea internamente

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] `shellcheck` SC2154 introduzido pela própria mudança em `tests/regress.sh`**
- **Found during:** Tarefa 1 (verify: `shellcheck tests/regress.sh`)
- **Issue:** o novo lookup dinâmico `${swagger_title_suffix}` dentro do bloco de sed, alimentado por `set -a; . "$TEMPLATES/lang/en.lang"; set +a`, não é estaticamente resolvível pelo shellcheck, que reportou "referenced but not assigned" (SC2154) — um achado NOVO, causado pelo diff desta própria tarefa (distinto dos achados SC2015/shfmt pré-existentes no arquivo, documentados como deferred)
- **Fix:** adicionada a guarda fail-closed `: "${swagger_title_suffix:?key swagger_title_suffix not found in catalog}"` antes do uso, seguindo o idioma `:?` já usado em todo o repo (`generate-mkdocs.sh`, `generate-index.sh`, `to-pdf.sh`, `to-dokuwiki.sh`) — confirmado experimentalmente que esse idioma é o que silencia o SC2154 nesses scripts, e que faltava aqui
- **Files modified:** `tests/regress.sh`
- **Verification:** `shellcheck tests/regress.sh` retorna limpo quanto a SC2154 (permanecem apenas os 2 achados SC2015 pré-existentes, confirmados via `git show HEAD` antes desta tarefa)
- **Committed in:** `0769e5a` (parte do commit da Tarefa 1)

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Correção mínima e localizada; não afeta o comportamento do harness, apenas silencia um alerta estático real causado pela própria mudança.

**Pré-existentes NÃO corrigidos (fora de escopo, SCOPE BOUNDARY):** `tests/regress.sh` já carregava 2 achados `shellcheck` SC2015 (info) e um diff `shfmt` de 276 linhas (convenção de indentação 2-espaços vs. o default de tabs do shfmt) antes de qualquer edição desta tarefa — confirmado via `git show HEAD:tests/regress.sh`. Documentado em `.planning/phases/03-pt-br-nas-5-superf-cies/deferred-items.md` (entrada "03-03 — Tarefa 1"), seguindo exatamente o precedente já estabelecido em 03-01 para `scripts/generate-mkdocs.sh` e `tests/fail-closed.sh`. As linhas novas desta tarefa seguem a convenção de 2 espaços já existente no arquivo, então estendem a mesma forma de divergência pré-existente em vez de introduzir uma nova (confirmado: o diff do `shfmt -d` cresceu apenas pelas linhas adicionadas, formatadas no mesmo estilo do código já divergente ao redor).

## Auditoria delta — `docs/skill-quality-rubric.md` (agents/format-swagger.md, agents/format-github-wiki.md)

Auditoria leve (self-audit do executor, proporcional ao tamanho da mudança: 2 arquivos, ~40 linhas de diff no total). Dimensões relevantes à mudança:

| File | Dim | Verdict | Evidence | Nota |
|------|-----|---------|----------|------|
| agents/format-swagger.md | HIE-2 (rung placement) | ✅ Pass | step 4 reescrito inline | O procedimento de 4 passos é universal a toda invocação do step (não é conteúdo de branch específico) — inline é o rung correto |
| agents/format-swagger.md | STE-1 (critério checável) | ✅ Pass | "Done when swagger-ui/ contains both index.html and openapi.yml" preservado | Critério de done do step 4 não mudou, apenas o procedimento interno |
| agents/format-swagger.md | PRU-1 (duplicação) | ✅ Pass | frase de contrato idêntica ao molde de `agents/format-mkdocs.md:31` | Reaproveita a frase-molde já estabelecida, sem reescrever o mecanismo `OUTPUT_LANG` em prosa nova |
| agents/format-github-wiki.md | HIE-2 / PRU-1 | ✅ Pass | mesmo padrão, mesma frase-molde | idem |
| agents/format-github-wiki.md | STE-5 (negação com alvo positivo) | ✅ Pass | "são PATHS e são NEVER traduzidos... traduzi-los quebraria a resolução de links" | A proibição vem emparelhada com o motivo/consequência, não é uma proibição solta |

Nenhuma dimensão MET-1 aplicável (mudança mecânica de step + duas frases de contrato, não uma reestruturação de skill). Nenhum achado ⚠️/❌.

## Issues Encountered

None além do já documentado em Deviations.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- As 5 superfícies publicáveis emitem chrome 100% PT-BR com locale projetado em cada consumer, com gate permanente (`tests/no-mixed-output.sh`) provando zero saída mista — Phase 3 (`pt-br-nas-5-superf-cies`) está completa
- Phase 4 (Gêmeos PowerShell, Prosa & Release) pode reutilizar diretamente o padrão `scan_surface()`/`check_positive()` para qualquer harness de paridade que precise no lado `.ps1`, e o padrão de placeholder aditivo (`{{LANG_ATTR}}`) para qualquer novo template que precise da mesma regra "aditivo-só-quando-não-default"
- Nenhum bloqueador identificado; os itens em `deferred-items.md` (divergências `shellcheck`/`shfmt` pré-existentes) seguem recomendados para um plano de formatação dedicado, fora do escopo de qualquer feature

---
*Phase: 03-pt-br-nas-5-superf-cies*
*Completed: 2026-09-30*

## Self-Check: PASSED

- Todos os arquivos citados (`templates/swagger-ui.html`, `tests/regress.sh`, `agents/format-swagger.md`, `agents/format-github-wiki.md`, `tests/no-mixed-output.sh`) confirmados presentes no disco
- Todos os 3 commits de task (`0769e5a`, `dad654b`, `0db75bc`) confirmados em `git log`
