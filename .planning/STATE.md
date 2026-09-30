---
gsd_state_version: "1.0"
current_phase: 04
current_phase_name: Gêmeos PowerShell, Prosa & Release
current_plan: 5
status: executing
stopped_at: Completed 04-04-PLAN.md
last_updated: "2026-09-30T18:50:19.772Z"
last_activity: 2026-09-30
last_activity_desc: Phase 04 execution started
state_head: 32f92fdd2c3a7f617a83b1b70e02737b11ee4630
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 13
  completed_plans: 12
  percent: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-28)

**Core value:** Qualquer árvore de specs vira documentação publicável com um comando — de forma previsível.
**Current focus:** Phase 04 — Gêmeos PowerShell, Prosa & Release

## Current Position

Current Plan: 5
Total Plans in Phase: 5
Phase: 04 (Gêmeos PowerShell, Prosa & Release) — EXECUTING
Plan: 5 of 5
Status: Ready to execute
Last activity: 2026-09-30 — Phase 04 execution started

Progress: [█████░░░░░] 50%

## Performance Metrics

**Velocity:**

- Total plans completed: 5
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | - | - |
| 02 | 2 | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01 P01 | 14min | 2 tasks | 20 files |
| Phase 03 P01 | 57min | 3 tasks | 4 files |
| Phase 03 P02 | 45min | 3 tasks | 8 files |
| Phase 03 P03 | 25min | 3 tasks | 6 files |
| Phase 04 P01 | 126min | 3 tasks | 6 files |
| Phase 04 P02 | 51min | 3 tasks | 5 files |
| Phase 04 P03 | 20min | 3 tasks | 5 files |
| Phase 04 P04 | 45min | 3 tasks | 9 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Roadmap: fases por fronteira da arquitetura (contrato → catálogo+MkDocs/index → pt-br 5 superfícies → .ps1+agents+release), nunca por idioma — idioma é arquivo de dados
- Roadmap: QUAL-02 (golden fixtures) na Phase 1 — congelar ANTES de qualquer refactor é pré-requisito de todos os gates seguintes
- Roadmap: checkpoint `en` byte-idêntico como critério de barreira da Phase 2 (commit antes de qualquer pt-br)
- Roadmap: gêmeos `.ps1` dobrados na fase final (granularidade coarse) — replicam o padrão provado, não abrem requisito novo
- 03-01: `pt-br.lang` espelha ordem/agrupamento de `en.lang` para diff lado a lado legível entre catálogos
- 03-01: `THEME_LANGUAGE` é variável de script MAIÚSCULA (não chave de catálogo) para não colidir com o filtro `[a-z]` do gate `keyset_equality`
- 03-01: `missing_key_halts` detecta `catalog_basename` opcional pelo sufixo `.lang`, preservando as chamadas antigas sem alteração de assinatura
- [Phase 03]: 03-02: PANDOC_LANG_OPTS inserido em todas as 5 invocações de pandoc de to-pdf.sh, não só na primeira — a cascata de fallback de engines precisa preservar a locale em qualquer engine que rode
- [Phase 03]: 03-02: gate pandoc_lang_flags prova -M lang/-M toc-title com stub executável de pandoc (sem engine real), cobrindo a linha de comando efetiva montada pelo script
- [Phase 03]: 03-02: bootstrap do catálogo em to-dokuwiki.sh roda ANTES da guarda de pandoc, para que CHROME-03 halte nomeando a chave ausente mesmo num host sem pandoc
- [Phase 03]: 03-03: {{LANG_ATTR}} carrega o atributo inteiro (com espaço à esquerda) para resolver o conflito D-09/D-10 vs. byte-identidade do golden en
- [Phase 03]: 03-03: tests/no-mixed-output.sh como harness dedicado (não extensão de fail-closed.sh) — contrato de saída e escopo distintos justificam arquivo próprio (D-14)
- [Phase 04]: 04-01: banned_cmdlets e demais gates de tests/ps1-contract.sh iteram sobre scripts/lib + a lista TWINS (só generate-index.ps1 neste plano), nunca um glob cego scripts/*.ps1 — os outros três gêmeos ficam congelados até 04-03 (D-19/D-25)
- [Phase 04]: 04-01: no_hardcoded_chrome precisou stripar tokens $variavel antes de comparar needle — nomes de variável PowerShell em camelCase derivados da chave carregam o próprio fragmento de palavra e geravam falso positivo
- [Phase 04]: D-22/D-23/D-24: glossário anti-calque em CONTEXT.md com região de sentinela ignorada, denylist v1 restrita a formas ausentes do VOLP, regra de desempate via VOLP
- [Phase 04]: tests/wiki-links.sh extrai as expressões sed DO arquivo do agent (não uma cópia) para nunca divergir silenciosamente do que é publicado
- [Phase 04]: 04-03: no_hardcoded_chrome strip também ${var} (forma com chaves), não só $var — generate-mkdocs.ps1 introduziu a forma com chaves
- [Phase 04]: 04-03: declared_keys_complete generalizado para unir todo array @(...) do arquivo — to-pdf.ps1 declara pdf_toc_title condicionalmente, só no ramo pt-br
- [Phase 04]: 04-03: pwsh_accented_dir_survives adaptada por gêmeo — to-dokuwiki.ps1 prova por existência de arquivo, to-pdf.ps1 por conteúdo, generate-mkdocs.ps1 por exit-code (nav sem -Recurse, defeito pré-existente fora de escopo)
- [Phase 04]: Três bugs pré-existentes nos gêmeos .ps1 (to-pdf.ps1 argumentos posicionais, to-dokuwiki.ps1 Split-Path com ':', generate-mkdocs.ps1 caminho absoluto vazando) corrigidos in-line ao serem expostos pela primeira execução real da perna .ps1 (04-04)
- [Phase 04]: tests/ps1-contract.sh corrigido: set -e abortava a suíte na primeira falha comportamental, e três pernas não toleravam a exceção D-10 (to-pdf.ps1 sem engine de PDF) — helper pdf_status_tolerated compartilhado (04-04)

### Pending Todos

None yet.

### Blockers/Concerns

- Host dev sem mkdocs/pandoc (ADR 0003) — gates estruturais cobrem o interim; execução end-to-end pt-br (Phase 4) exige host com engines
- Verificação PS 5.1 real depende de host Windows — fixture acentuado por geminho é o gate local (gap conhecido, não bloqueador)
- Research flag: `toc-title` no path weasyprint e hifenização Pyphen `pt_BR` merecem `--research-phase` na Phase 3
- Sed em locale C corrompe acentos neste host (reproduzido 2026-09-28) — nenhuma transformação de case em runtime no chrome

## Deferred Items

Items acknowledged and deferred at milestone close, most recent first:

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| *(none)* | | | | |

## Session Continuity

Last session: 2026-09-30T18:50:19.740Z
Stopped at: Completed 04-04-PLAN.md
Resume file: None
