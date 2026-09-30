---
phase: 04-g-meos-powershell-prosa-release
plan: "02"
subsystem: quality
tags: [glossary, i18n, anti-calque, bash, wiki]
requires:
  - phase: 04-g-meos-powershell-prosa-release
    provides: "catalog.ps1 loader provado (04-01)"
provides:
  - "Glossário anti-calque em CONTEXT.md (denylist + allowlist + regra VOLP)"
  - "Cópia inline do glossário em agents/format-github-wiki.md e agents/references.md"
  - "tests/no-calques.sh — gate determinístico contra calques (6 gates, 2 controles)"
  - "tests/wiki-links.sh — gate contra o bloco sed quebrado de conversão de link"
  - "Correção do bloco sed de conversão de links (CR-01 + descarte de texto + laço frágil)"
affects: ["04-05"]
actuals:
  tokens: 7162
  tasks: 3
  commits: 3
  plan_head_before: 2698f9b7979e13984889f51289f668320c9f8ae5
  plan_head_after: 3f7300b
tech-stack:
  added: []
  patterns: ["glossário inline em agent (não referenciado) para enforcement sob pressão", "região delimitada por sentinela HTML para conteúdo que citaria a si mesmo e reprovaria o próprio gate"]
key-files:
  created:
    - tests/no-calques.sh
    - tests/wiki-links.sh
  modified:
    - CONTEXT.md
    - agents/format-github-wiki.md
    - agents/references.md
key-decisions:
  - "Denylist v1 contém só formas anglicizadas ausentes do VOLP (D-23) — checar/deletar/resetar/refatorar/acessar/escanear ficam de fora explicitamente na allowlist, provados pelo controle allowlist_is_load_bearing contra 'deletado' em docs/chrome-inventory.md"
  - "Região <!-- no-calques:ignore-start/-end --> em CONTEXT.md e nos dois agents (D-22) — sem ela o próprio glossário, que precisa citar os calques para proibi-los, reprovaria seu próprio gate"
  - "tests/wiki-links.sh extrai as duas expressões sed DO arquivo do agent (não uma cópia) via extração de bloco de código + regex — assim o teste nunca diverge silenciosamente do que está de fato publicado"
requirements-completed: [QUAL-03, CHROME-02]
coverage:
  - id: D1
    description: "CONTEXT.md carrega glossário anti-calque com denylist explícita, allowlist e regra VOLP"
    verification:
      - kind: automated_ui
        ref: "tests/no-calques.sh (denylist_clean_prose, glossary_is_inlined)"
        status: pass
    human_judgment: false
  - id: D2
    description: "agents/format-github-wiki.md carrega glossário INLINE (não só link)"
    verification:
      - kind: integration
        ref: "tests/no-calques.sh (glossary_is_inlined) — grep >=3 formas dentro da região ignorada"
        status: pass
    human_judgment: false
  - id: D3
    description: "tests/no-calques.sh falha quando calque aparece e não passa por vacuidade"
    verification:
      - kind: unit
        ref: "tests/no-calques.sh (gate_is_load_bearing, allowlist_is_load_bearing)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Bloco sed de conversão de link converte, preserva texto e sobrevive a nome de arquivo com espaço"
    verification:
      - kind: unit
        ref: "tests/wiki-links.sh (sed_block_extraction, link_conversion, no_sed_error, spaced_filename_survives)"
        status: pass
    human_judgment: false
duration: 51min
completed: 2026-09-30
status: complete
---

# Phase 04 Plan 02: Glossário anti-calque, cópia inline e correção do bloco sed Summary

**Glossário anti-calque materializado em `CONTEXT.md` (denylist de dez verbos anglicizados sem registro no VOLP, allowlist consagrada, tiques de LLM banidos, regra de desempate D-24), copiado inline nos dois únicos agents que escrevem prosa autoral publicada (`format-github-wiki.md`, `references.md`), com `tests/no-calques.sh` como gate determinístico de seis pernas — duas delas controles que provam que o gate não passa por vacuidade — e o bloco sed de conversão de link do GitHub Wiki corrigido dos três defeitos que o deixavam quebrado (CR-01, descarte de texto, laço frágil), fechado por `tests/wiki-links.sh`.**

## Performance

- **Duration:** 51min
- **Started:** 2026-09-30T16:41:11Z
- **Completed:** 2026-09-30T17:32:21Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- `CONTEXT.md` ganhou a seção `## Glossário anti-calque` logo após `## Output language policy`: denylist de dez verbos anglicizados (com forma correta indicada), allowlist de formas consagradas pelo VOLP, termos técnicos mantidos em inglês integral, tiques de LLM banidos, a regra de desempate do VOLP (D-24, datada) e a fronteira de escopo (chrome/prosa de chrome, nunca conteúdo dos specs) — tudo dentro de uma região delimitada por sentinela HTML (D-22) para não reprovar o próprio gate
- `agents/format-github-wiki.md` e `agents/references.md` — os dois únicos sítios onde um agent escreve prosa autoral publicada — carregam a MESMA cópia compacta do glossário inline, com justificativa registrada de por que a duplicação é deliberada (Pitfall 4: referência só consultada sob demanda é ignorada sob pressão de geração)
- `tests/no-calques.sh`: seis gates — `denylist_clean_prose` (varre `CONTEXT.md`, `SKILL.md`, `README.pt-BR.md`, `agents/`, `docs/`, excluindo `tests/` explicitamente), `denylist_clean_ptbr_output` (gera as cinco superfícies pt-br em sandbox e varre as mesmas fatias de chrome de `no-mixed-output.sh`), `denylist_clean_catalog` (varre os VALORES de `pt-br.lang`), e dois controles: `gate_is_load_bearing` (injeta calque+tique e prova que o gate não passaria em silêncio) e `allowlist_is_load_bearing` (prova que `deletado` de `docs/chrome-inventory.md` não é reportado)
- Bloco sed de conversão de link em `agents/format-github-wiki.md` step 4 reescrito com os três defeitos corrigidos de uma vez: CR-01 (parênteses de captura invertidos, que faziam o `sed` abortar antes de converter qualquer link), D-17/Q3 (a segunda expressão descartava o texto visível do link — agora estruturalmente idêntica à primeira, preservando texto e alvo), D-26 (laço `for f in $(find ...)` sem aspas trocado por `find -print0` + `while IFS= read -r -d ''`, sobrevive a nome de arquivo com espaço)
- `tests/wiki-links.sh`: extrai as duas expressões sed DO arquivo do agent (não uma cópia), prova que o bloco converte os três formatos de link relativo preservando o texto, que URLs externas e `mailto:` saem intactas, que a versão corrigida não aborta (gate direto do CR-01), e que um nome de arquivo com espaço sobrevive ao laço sem criar caminho parcial

## Task Commits

1. **Tarefa 1: fatia vertical — glossário no CONTEXT.md, cópia inline no agent e o gate que falha** - `cb07881` (feat)
2. **Tarefa 2: CR-01, o descarte de texto de link e o laço frágil — o bloco sed de conversão de link** - `8a8dfed` (fix)
3. **Tarefa 3: agents/references.md sob o contrato de OUTPUT_LANG e do glossário** - `3f7300b` (feat)

## Files Created/Modified

- `CONTEXT.md` (modificado) - nova seção `## Glossário anti-calque`, região ignorada balanceada
- `agents/format-github-wiki.md` (modificado) - cópia inline do glossário + bloco sed dos três defeitos corrigidos
- `agents/references.md` (modificado) - frase de contrato `OUTPUT_LANG`, título via `label_references`, nota de passthrough (CHROME-04), cópia inline do glossário
- `tests/no-calques.sh` (novo) - gate de QUAL-03, seis gates incluindo dois controles anti-vacuidade
- `tests/wiki-links.sh` (novo) - gate de regressão do bloco sed, extrai as expressões do próprio arquivo do agent

## Decisions Made

- **Denylist v1 restrita a formas ausentes do VOLP (D-23).** `checar`, `deletar`, `resetar`, `refatorar`, `acessar` e `escanear` ficam de fora — a lista de partida do `04-RESEARCH.md` incluía `checar`/`deletar` e teria reprovado prosa legítima. A ocorrência de `deletado` em `docs/chrome-inventory.md` é o caso vivo que o gate `allowlist_is_load_bearing` prova não ser reportado.
- **Região de sentinela HTML (D-22) em três arquivos** (`CONTEXT.md`, os dois agents) — sem ela, o glossário que precisa CITAR os calques para proibi-los reprovaria o próprio gate. `strip_ignored_regions` em `tests/no-calques.sh` trata região não fechada como erro explícito (`FAIL: unbalanced_ignore_region`), nunca como blanqueamento silencioso do resto do arquivo.
- **`tests/wiki-links.sh` extrai as expressões sed DO arquivo do agent**, não de uma cópia mantida no teste — garante que o teste nunca diverge silenciosamente do que está de fato publicado; se o bloco mudar de forma (deixar de ter exatamente duas expressões `-e 's@...@...@g'`), a extração falha explicitamente em vez de testar algo que não existe mais.

## Deviations from Plan

None - o plano foi executado como escrito. As três tarefas, os artefatos e os critérios de aceitação batem com o `04-02-PLAN.md`.

## Issues Encountered

Nenhum. Todos os gates (`tests/no-calques.sh`, `tests/wiki-links.sh`, `tests/no-mixed-output.sh`, `tests/fail-closed.sh`, `tests/regress.sh`) rodaram limpos neste host; `tests/regress.sh` encerra com `rc=3` apenas pelo SKIP conhecido da perna `.ps1` (ausência de `pwsh`, gap documentado desde a Phase 1, tratado no plano `04-04`).

## Auditoria delta — `docs/skill-quality-rubric.md`

Self-audit do executor, proporcional ao tamanho da mudança (3 arquivos de skill tocados + 2 harnesses novos).

| File | Dim | Verdict | Evidence | Nota |
|------|-----|---------|----------|------|
| CONTEXT.md | HIE-4 (co-location) | ✅ Pass | `## Glossário anti-calque` logo após `## Output language policy`; denylist, allowlist, regra de desempate e fronteira de escopo sob o mesmo heading | Consequência direta agrupada, não espalhada por seções |
| CONTEXT.md | HIE-5 (external reference) | ✅ Pass | CONTEXT.md continua a casa externa única do vocabulário; os dois agents apontam de volta a ele | |
| CONTEXT.md | PRU-1 (duplicação) | ✅ Pass | linha "esta seção é a fonte da REGRA, [tests/no-calques.sh] é a fonte do PREDICADO" | Sem redefinição da lista em terceiro lugar |
| agents/format-github-wiki.md | PRU-1 (duplicação) | ⚠️ Partial (deliberada) | cópia inline da denylist idêntica à do CONTEXT.md | Duplicação é INTENCIONAL e justificada no próprio arquivo (Pitfall 4) — não é achado a corrigir, é a defesa contra a regressão que Pitfall 4 descreve |
| agents/format-github-wiki.md | STE-6 (determinism substitution) | ✅ Pass | `tests/no-calques.sh` decide o predicado; a prosa só registra a regra | |
| agents/references.md | HIE-2 (rung placement) | ✅ Pass | contrato `OUTPUT_LANG` + glossário inline só aparecem aqui e em `format-github-wiki.md` — os outros 4 `format-*.md` não escrevem prosa autoral e não recebem a cópia | Split correto por branch (só onde o agent de fato precisa) |
| tests/no-calques.sh | STE-6 (determinism substitution) | ✅ Pass | dois controles (`gate_is_load_bearing`, `allowlist_is_load_bearing`) provam que o gate não passa por vacuidade nem é largo demais | |

Nenhum achado ❌. MET-1 (gate de predictabilidade): aplica-se e passa — o ganho é converter "a prosa pt-br é boa" de expectativa subjetiva num gate de grep determinístico e repetível; o custo permanente por execução é baixo (~30 linhas de array + varredura), justificado pelo requisito QUAL-03.

## User Setup Required

None — nenhuma configuração de serviço externo necessária.

## Next Phase Readiness

- `tests/no-calques.sh` e `tests/wiki-links.sh` estão prontos como gates permanentes para qualquer prosa pt-br futura que os agents escrevam
- `agents/onboarding.md`, `agents/format-mkdocs.md`, `agents/format-swagger.md`, `agents/format-pdf.md` e `agents/format-dokuwiki.md` não escrevem prosa autoral e por isso não receberam a cópia inline — confirmado pelo levantamento do `04-RESEARCH.md` §Agent Prose Audit, ainda válido
- Nenhum bloqueio conhecido para `04-03`/`04-04`/`04-05`; `04-04` ainda depende da instalação de `pwsh` (gap documentado, não bloqueador deste plano)

## Self-Check: PASSED

Todos os arquivos declarados (`CONTEXT.md`, `agents/format-github-wiki.md`, `agents/references.md`, `tests/no-calques.sh`, `tests/wiki-links.sh`) e os 3 hashes de commit de tarefa (`cb07881`, `8a8dfed`, `3f7300b`) confirmados presentes.

---
*Phase: 04-g-meos-powershell-prosa-release*
*Completed: 2026-09-30*
