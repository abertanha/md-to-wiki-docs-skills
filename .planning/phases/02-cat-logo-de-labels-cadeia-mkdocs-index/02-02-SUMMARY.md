---
phase: 02-cat-logo-de-labels-cadeia-mkdocs-index
plan: 02
subsystem: docs-generation
tags: [bash, i18n, chrome-catalog, mkdocs, fail-closed, regression-fixture]

# Dependency graph
requires:
  - phase: 02-cat-logo-de-labels-cadeia-mkdocs-index
    provides: "Plano 02-01: templates/lang/en.lang, bootstrap de catálogo provado em generate-index.sh, tests/regress.sh alinhado"
provides:
  - "scripts/generate-mkdocs.sh refatorado: assinatura de 3 posicionais, mesmo bootstrap de catálogo do 02-01, gate fail-closed sobre 3 chaves, zero chrome fixo"
  - "tests/fail-closed.sh — harness novo, gate repetível e automatizado de CHROME-03 (halt nomeando a chave) e CHROME-04 (passthrough intacto)"
  - "tests/regress.sh e agents/format-mkdocs.md completos: cadeia inteira transmite OUTPUT_LANG"
  - "READMEs corrigidos: paridade de argumentos .sh/.ps1 deixou de ser afirmada incondicionalmente"
  - "templates/index.md removido (decisão do usuário: remover) — fim da segunda fonte de verdade"
affects: ["Phase 3 (catálogo pt-br, pdf_title, swagger_title_suffix, theme.language)", "Phase 4 (gêmeos .ps1, wiring de tests/fail-closed.sh no fluxo de release, doc de release dos READMEs)"]

# Actuals (#2632)
actuals:
  tokens: 3575
  tasks: 3
  commits: 2
  plan_head_before: 14864743b2e35d8820c539ea17320e2047d2d488
  plan_head_after: 46d1b065fe80cfd7d4a0763301c3c9307275126d

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bootstrap de catálogo replicado sem variação de scripts/generate-index.sh para scripts/generate-mkdocs.sh: allowlist antes do path, SCRIPT_DIR via BASH_SOURCE, set -a/./set +a, gate fail-closed em bloco"
    - "keyset_equality: gate permanente comparando o conjunto declarado no gate up-front contra o conjunto expandido no corpo, filtrado pela vocabulário de chaves do próprio catálogo (evita falso-positivo com variáveis internas minúsculas do script)"
    - "Sondas de fail-closed em sandbox mktemp -d com cópia de scripts/, templates/ e .specs — a árvore de trabalho real nunca é mutada"

key-files:
  created:
    - tests/fail-closed.sh
  modified:
    - scripts/generate-mkdocs.sh
    - tests/regress.sh
    - agents/format-mkdocs.md
    - README.md
    - README.pt-BR.md
  removed:
    - templates/index.md

key-decisions:
  - "templates/index.md removido via git rm (checkpoint da Task 1 — usuário escolheu `remover`): espelho desatualizado do heredoc de generate-index.sh, sem nenhum consumidor (D-12 da Phase 1), reversível pelo histórico do git"
  - "keyset_equality distingue chave de catálogo de variável interna do script (dir, label, rel, section, ...) interseccionando o conjunto ${...} expandido contra o vocabulário real de chaves definidas em templates/lang/en.lang — evita falso-positivo sem exigir prefixo hardcoded na lógica do gate"
  - "bad_language_halts roda apenas uma vez (contra generate-mkdocs.sh) — a allowlist en|pt-br já é validada de forma idêntica nos dois scripts (mesmo padrão do 02-01), então uma sonda basta para provar o mecanismo compartilhado"
  - "Correção dos READMEs registra a divergência .sh/.ps1 como fato vigente (output_lang só existe no .sh por ora), não como atualização de release — essa é tarefa da Phase 4"

patterns-established:
  - "tests/fail-closed.sh como segundo harness (ao lado de tests/regress.sh): mesmo molde estrutural (header, Usage, exit codes, LC_ALL pin, REPO_ROOT via BASH_SOURCE), mas provando ausência de regressão de comportamento fail-closed em vez de ausência de regressão de bytes"

requirements-completed: [CHROME-01, CHROME-03, CHROME-04]

coverage:
  - id: D1
    description: "generate-mkdocs.sh emite as 3 chaves de chrome (site_name_suffix, site_description, nav_home) por lookup de catálogo — zero string de chrome fixa, gate fail-closed cobrindo exatamente as 3 chaves"
    requirement: CHROME-01
    verification:
      - kind: other
        ref: "grep de literais Specifications|Auto-generated|- Home: fora de comentário (hardcoded_chrome=0, baseline pré-refatoração 3); keys_expanded=3 e keys_gated=3"
        status: pass
    human_judgment: false
  - id: D2
    description: "tests/fail-closed.sh prova halt nomeando a chave ausente nos dois scripts da cadeia (3 sondas), com controle positivo e sem mutar a árvore de trabalho"
    requirement: CHROME-03
    verification:
      - kind: other
        ref: "bash tests/fail-closed.sh (rc=0, 9 linhas OK:, 0 linhas FAIL:); git status --porcelain templates/lang/en.lang scripts/ vazio após a execução"
        status: pass
    human_judgment: false
  - id: D3
    description: "Sed de title-case intacto: 1 sítio em generate-index.sh, 2 em generate-mkdocs.sh, nenhum atravessado por variável de catálogo — provado tanto no verify da task quanto como gate permanente em fail-closed.sh"
    requirement: CHROME-04
    verification:
      - kind: other
        ref: "titlecase_sites=2 em generate-mkdocs.sh; gate passthrough_intact do harness (index=1, mkdocs=2, catalog_leak=0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Regressão byte-idêntica da cadeia inteira (mkdocs.yml + docs/) com generate-mkdocs.sh e generate-index.sh ambos recebendo en explícito, golden intocado"
    verification:
      - kind: other
        ref: "bash tests/regress.sh (rc=3, 'OK: mkdocs (mkdocs.yml + docs/) identical', nenhuma linha FAIL:); git diff --quiet HEAD -- tests/fixtures/golden-sh/ (rc=0); repo_url wart preservado"
        status: pass
    human_judgment: false
  - id: D5
    description: "templates/index.md removido por decisão explícita do usuário no checkpoint da Task 1, registrada aqui"
    verification:
      - kind: other
        ref: "git ls-files templates/index.md (saída vazia); git log mostra 'delete mode 100644 templates/index.md' no commit 37c87bd"
        status: pass
    human_judgment: false
  - id: D6
    description: "Dispatch do agent transmite OUTPUT_LANG no passo 2 (generate-mkdocs) e READMEs deixam de afirmar paridade incondicional de argumentos .sh/.ps1"
    verification:
      - kind: other
        ref: "grep -c OUTPUT_LANG agents/format-mkdocs.md = 4 (>= 3); grep negativo confirma ausência de 'identical positional arguments'/'argumentos posicionais idênticos' nos dois READMEs"
        status: pass
    human_judgment: false

duration: ~15min
completed: 2026-09-29
status: complete
---

# Phase 2 Plan 2: generate-mkdocs.sh por lookup + fail-closed.sh Summary

**`generate-mkdocs.sh` refatorado para consumir o catálogo com o mesmo bootstrap provado no 02-01, `tests/fail-closed.sh` novo transformando CHROME-03/CHROME-04 em gate automatizado repetível, e `templates/index.md` removido por decisão do usuário — fecha o critério 1 do ROADMAP Phase 2.**

## Performance

- **Duration:** ~15 min (continuação pós-checkpoint da Task 1)
- **Completed:** 2026-09-29T17:20:22Z
- **Tasks:** 3 (Task 1 checkpoint de decisão + Task 2 auto + Task 3 auto)
- **Files modified:** 7 (1 criado, 5 modificados, 1 removido)

## Accomplishments
- `scripts/generate-mkdocs.sh` replicou o bootstrap de catálogo do 02-01 sem variação: allowlist `case en|pt-br` antes de compor o path, `SCRIPT_DIR` via `BASH_SOURCE`, `set -a; . "$CATALOG"; set +a`, gate fail-closed cobrindo exatamente as 3 chaves que o script expande (`site_name_suffix`, `site_description`, `nav_home`) — zero literal de chrome fixo restante
- `tests/fail-closed.sh` criado: 9 gates verdes (`keyset_equality` × 2 scripts, `missing_key_halts` × 3 sondas, `intact_catalog_succeeds` × 2 scripts, `bad_language_halts` × 1, `passthrough_intact` × 1), toda mutação confinada a sandbox `mktemp -d`, árvore de trabalho comprovadamente limpa após a execução
- `tests/regress.sh` e `agents/format-mkdocs.md` alinhados — a cadeia inteira agora transmite `OUTPUT_LANG` explicitamente nos dois scripts; READMEs corrigidos para não afirmarem mais paridade incondicional de argumentos `.sh`/`.ps1`
- `templates/index.md` removido via `git rm` (decisão do usuário no checkpoint da Task 1: `remover`) — eliminada a segunda fonte de verdade que competia com o catálogo
- Barreira dura da fase confirmada duas vezes nesta sessão: `bash tests/regress.sh` sai 3 (byte-idêntico, apenas pwsh SKIPPED) tanto antes quanto depois de `tests/fail-closed.sh` rodar

## Task Commits

Each task was committed atomically:

1. **Task 1: Decisão — destino de templates/index.md** - checkpoint:decision, sem commit próprio (decisão registrada aqui; a remoção do arquivo entrou no commit da Task 2 conforme o `<done>` do plano)
2. **Task 2: generate-mkdocs.sh por lookup + cadeia inteira alinhada + READMEs corrigidos** - `37c87bd` (feat)
3. **Task 3: tests/fail-closed.sh — CHROME-03 e CHROME-04 como gate repetível** - `46d1b06` (test)

_Nenhuma task TDD nesta fase — commits únicos por task._

## Files Created/Modified
- `scripts/generate-mkdocs.sh` - Refatorado: bootstrap de catálogo, allowlist de idioma, gate fail-closed sobre 3 chaves, zero chrome fixo
- `tests/fail-closed.sh` - Harness novo: 9 gates cobrindo keyset equality, halt de chave ausente, controle positivo, idioma inválido e passthrough
- `tests/regress.sh` - Invocação de `generate-mkdocs.sh` na cadeia passa a receber `en` explícito
- `agents/format-mkdocs.md` - Passo 2 transmite `$OUTPUT_LANG`; nota de fail-closed acrescentada
- `README.md` / `README.pt-BR.md` - Afirmação de paridade de argumentos corrigida, citando a exceção `output_lang` até a Phase 4; listagem da estrutura de `templates/` atualizada
- `templates/index.md` - Removido (`git rm`), decisão do usuário registrada nesta SUMMARY

## Decisions Made
- **templates/index.md: `remover`.** O usuário confirmou explicitamente no checkpoint bloqueante da Task 1 a opção recomendada pela pesquisa da fase — o arquivo era um espelho desatualizado do heredoc de `generate-index.sh`, sem nenhum consumidor (grep em `agents/`, `scripts/`, `SKILL.md` e `CONTEXT.md` não encontrou referência), e mantê-lo contradiria o objetivo do catálogo de ser fonte única. A remoção é integralmente reversível por `git restore`/`git revert` — nenhum consumidor foi afetado.
- `keyset_equality` filtra o conjunto `${...}` expandido no corpo do script contra o vocabulário real de chaves definidas em `templates/lang/en.lang`, em vez de uma lista de prefixos hardcoded — assim variáveis internas minúsculas do script (`dir`, `label`, `rel`, `section`, `rows`...) nunca são confundidas com referência a catálogo, sem exigir manutenção da lista de prefixos a cada chave nova.
- `bad_language_halts` roda uma única vez (contra `generate-mkdocs.sh`): a allowlist `en|pt-br` é validada pelo mesmo mecanismo `case` nos dois scripts (padrão idêntico ao provado no 02-01), então uma sonda já comprova o mecanismo compartilhado sem duplicar cobertura.
- A correção dos READMEs registra a divergência `.sh`/`.ps1` de `output_lang` como fato vigente da fase atual, não como a atualização de documentação de release completa — essa é tarefa explícita da Phase 4.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Listagem da estrutura de `templates/` nos READMEs desatualizada após a remoção**
- **Found during:** Task 2, ao remover `templates/index.md`
- **Issue:** A árvore ASCII de `README.md` e `README.pt-BR.md` (seção "Skill Set Structure"/"Estrutura do Skill Set") ainda listava `templates/index.md` como arquivo existente, o que se tornaria uma afirmação falsa assim que o `git rm` fosse commitado
- **Fix:** Removida a linha `index.md` da árvore em ambos os READMEs, mantendo apenas `swagger-ui.html` sob `templates/`
- **Files modified:** README.md, README.pt-BR.md
- **Verification:** Inspeção visual da árvore pós-edição; nenhum outro ponto do README referencia o arquivo removido
- **Committed in:** 37c87bd (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug de documentação)
**Impact on plan:** Correção direta e local, causada pela própria remoção decidida na Task 1. Sem scope creep — nenhum arquivo fora do already-touched foi tocado.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Critério 1 do ROADMAP Phase 2 fechado: zero chrome fixo na cadeia MkDocs/index inteira, templates incluídos (o único template morto foi removido)
- Critérios 3 e 4 deixaram de depender de inspeção manual: `bash tests/fail-closed.sh` é gate repetível e comprovadamente não-mutante
- Padrão de bootstrap de catálogo provado em dois scripts (`generate-index.sh`, `generate-mkdocs.sh`) sem nenhuma variação entre eles — pronto para a Phase 3 herdar ao consumir `pdf_title`, `swagger_title_suffix` e o catálogo `pt-br`
- `tests/fail-closed.sh` ainda não está fiado no fluxo de release (wiring é item explícito da Phase 4, fora de escopo aqui)
- Nenhum bloqueio conhecido para o próximo plano

---
*Phase: 02-cat-logo-de-labels-cadeia-mkdocs-index*
*Completed: 2026-09-29*

## Self-Check: PASSED

- FOUND: scripts/generate-mkdocs.sh
- FOUND: tests/fail-closed.sh
- FOUND: tests/regress.sh
- FOUND: agents/format-mkdocs.md
- FOUND: README.md
- FOUND: README.pt-BR.md
- CONFIRMED REMOVED: templates/index.md
- FOUND: commit 37c87bd (Task 2)
- FOUND: commit 46d1b06 (Task 3)
