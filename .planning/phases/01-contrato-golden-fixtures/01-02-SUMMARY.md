---
phase: 01-contrato-golden-fixtures
plan: 02
subsystem: [contract, documentation]
tags: [output-lang, i18n, onboarding, chrome-inventory, context]

# Dependency graph
requires:
  - phase: 01-01
    provides: golden fixtures and regress harness — not directly consumed here, but validates same branch
provides:
  - OUTPUT_LANG variable in CONTEXT.md §Variables with default pt-br and locale policy
  - Output language policy section in CONTEXT.md (normalization, consumer projection, fail-closed, catalog format, Swagger scope, ISO 8601 dates, authority pointer)
  - docs/chrome-inventory.md — 4-layer × 5-surface chrome map seeding Phase 2 catalog extraction
  - agents/onboarding.md — OUTPUT_LANG interview item (item 4) and return criteria token
affects: [02-catalogo-labels, 03-pt-br-superficies, 04-geminos-release, agents/format-*.md dispatch prompts]

actuals:
  tokens: 4200
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: [contract-as-single-source (OUTPUT_LANG lives in CONTEXT.md, assigned only in onboarding, transmitted via dispatch prompt)]

key-files:
  created: [docs/chrome-inventory.md, .planning/phases/01-contrato-golden-fixtures/01-02-SUMMARY.md]
  modified: [CONTEXT.md, agents/onboarding.md]

key-decisions:
  - "OUTPUT_LANG canonical tokens are lowercase: en | pt-br; case-insensitive normalization on input (pt-BR ≡ pt-br)"
  - "Consumer projection table: pt-BR for MkDocs Material/pandoc/HTML; pt_BR for Pyphen — projection at point of use, not scattered"
  - "Fail-closed for unknown value and missing catalog key — no silent fallback (mixed-language output prevention)"
  - "Swagger scope limited to page title + lang attribute: upstream bundle has no official i18n (documented limit)"
  - "OUTPUT_LANG never reads from environment; assignment is onboarding-only, transmission via dispatch prompt"
  - "templates/index.md marked unconsumed (D-12) — no script reads it currently"

patterns-established:
  - "Single-source contract: variable defined in CONTEXT.md §Variables, assigned in onboarding interview, transmitted via dispatch prompt — no env vars"
  - "OUTPUT_LANG question molded after AUDIENCE: canonical tokens + per-value description + explicit Default line"
  - "Chrome inventory format: chave → valor en verbatim → arquivo:linha, 4 camadas × 5 superfícies"
  - "Aditiva-só-quando-não-default: en omits language key, pt-br adds it — preserving byte-identical regression baseline"

requirements-completed: [PARAM-01, PARAM-02]

coverage:
  - id: D1
    description: "OUTPUT_LANG documented in CONTEXT.md §Variables with default pt-br, normalization rule, and locale policy section"
    requirement: PARAM-01
    verification:
      - kind: manual_procedural
        ref: "grep -c '^| `OUTPUT_LANG` |' CONTEXT.md → 1; grep -c 'Output language policy' CONTEXT.md → 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Locale projection table (pt-BR/pt_BR by consumer) and fail-closed contract documented in CONTEXT.md"
    requirement: PARAM-02
    verification:
      - kind: manual_procedural
        ref: "grep -c 'pt_BR' CONTEXT.md → 1; grep -c 'pt-BR' CONTEXT.md → 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "docs/chrome-inventory.md: 4-layer × 5-surface map with 12+ keys (seed + pdf_generated_on + nav_issues), file:line anchors audited, templates/index.md unconsumed"
    requirement: PARAM-01
    verification:
      - kind: manual_procedural
        ref: "grep -c '^## Camada' docs/chrome-inventory.md → 4; grep -c 'unconsumed' docs/chrome-inventory.md → 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "agents/onboarding.md: OUTPUT_LANG as item 4, FORMAT→5, Deployment→6, OUTPUT_LANG in §Return criteria between AUDIENCE and FORMAT"
    requirement: PARAM-01
    verification:
      - kind: manual_procedural
        ref: "grep -c 'OUTPUT_LANG' agents/onboarding.md → 2; grep -c 'Default: `pt-br`' → 1; grep -c '^4.*OUTPUT_LANG' → 1"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-09-29
status: complete
---

# Phase 01 Plan 02 Summary

**OUTPUT_LANG entra no contrato: variável em CONTEXT.md com política de locale completa, inventário de chrome 4 camadas × 5 superfícies em docs/chrome-inventory.md, e pergunta de onboarding com default pt-br — a casa única do padrão AUDIENCE replicada sem portar padrão novo.**

## Performance

- **Duration:** ~35 min (execução distribuída em duas sessões)
- **Started:** 2026-09-29T09:00:00Z
- **Completed:** 2026-09-29
- **Tasks:** 3
- **Files modified:** 3 (docs/chrome-inventory.md criado, CONTEXT.md e agents/onboarding.md modificados)

## Accomplishments

- `docs/chrome-inventory.md` criado: grade 4 camadas × 5 superfícies, 12 chaves (seed do glossário + pdf_generated_on e nav_issues marcados como twin-exclusive), âncoras arquivo:linha re-auditadas contra scripts @ 11d2b7a, templates/index.md marcado unconsumed (D-12)
- `CONTEXT.md` atualizado: linha OUTPUT_LANG na tabela §Variables (default pt-br, normalização case-insensitive), seção `## Output language policy` com projeção por consumidor (pt-BR/pt_BR), fail-closed para valor desconhecido e chave ausente, escopo Swagger, ISO 8601, pointer Authority para chrome-inventory.md
- `agents/onboarding.md` atualizado: item 4 OUTPUT_LANG com tokens canônicos minúsculos, descrição por valor, Default pt-br; FORMAT renumerado para 5, Deployment para 6; OUTPUT_LANG adicionado na lista de §Return criteria entre AUDIENCE e FORMAT

## Task Commits

1. **Task 1: docs/chrome-inventory.md — mapa 4 camadas × 5 superfícies** — `d4bca46` (feat(01-02))
2. **Task 2: CONTEXT.md — OUTPUT_LANG na tabela §Variables + seção de política** — `2cd5945` (feat(language)) — _incluído em commit de sessão anterior_
3. **Task 3: agents/onboarding.md — pergunta OUTPUT_LANG + §Return criteria** — `3f4a6df` (feat(01-02))

## Files Created/Modified

- `docs/chrome-inventory.md` — mapa de chrome: chave → valor en verbatim → arquivo:linha nas 4 camadas × 5 superfícies; semeia a extração de `en` da Phase 2
- `CONTEXT.md` — variável OUTPUT_LANG + política de locale de saída (normalização, projeção, fail-closed, catálogo, Swagger, datas, console)
- `agents/onboarding.md` — entrevista com OUTPUT_LANG como item 4 com default explícito; lista de retorno atualizada

## Decisions Made

- Casa única preservada: OUTPUT_LANG segue o mesmo mecanismo de AUDIENCE (contrato → onboarding → dispatch prompt, zero env var)
- Projeção por consumidor em tabela única no ponto de uso (Phase 2+), não espalhada
- Fail-closed sem fallback silencioso — política registrada agora, enforcement em script é Phase 2+
- Swagger documentado com limite upstream (sem i18n oficial no bundle), título + lang attribute como escopo único

## Deviations from Plan

### Execução distribuída em duas sessões

- **Tarefa:** Tasks 1–3 executadas em sessões diferentes (Task 1 e 2 na sessão anterior, Task 3 nesta sessão)
- **Causa:** Contexto encerrado entre sessões; Task 2 foi incluída em commit de sincronização de sessão (`2cd5945`)
- **Impacto:** Nenhum — todos os artefatos estão corretos e verificados; SUMMARY.md ausente era o único estado pendente

### Falso positivo no verify check 4

- **Check:** `! grep 'OUTPUT_LANG' CONTEXT.md | grep -qi 'env'` deveria falhar quando há menção a env var ao lado de OUTPUT_LANG
- **Resultado:** A linha 29 do CONTEXT.md menciona "environment" na nota que PROÍBE o uso de env var ("OUTPUT_LANG never reads from the environment") — falso positivo do heurístico grep
- **Status:** PARAM-01 atendido — a nota é a vedação correta, não uma violação

---

**Total deviations:** 1 de execução (duas sessões, sem impacto nos artefatos) + 1 falso positivo de verify (explain no SUMMARY)
**Impact on plan:** Nenhum impacto nos artefatos entregues — todos os acceptance criteria atendidos.

## Issues Encountered

Nenhum problema com os artefatos. A execução distribuída em sessões foi operacional, não técnica.

## User Setup Required

None — este plano produz apenas documentação e contrato; nenhuma configuração de serviço externo necessária.

## Next Phase Readiness

- **01-03 (Wave 2):** Captura dos goldens .ps1 + DokuWiki — requer instalação de `pwsh` e `pandoc` via sudo (checkpoint humano bloqueante). Comandos exatos estão na Task 1 do plano 01-03.
- **Phase 2:** `docs/chrome-inventory.md` está pronto para a extração verbatim de `en` e criação dos arquivos `templates/lang/en.lang` e `templates/lang/pt-br.lang`

---
*Phase: 01-contrato-golden-fixtures*
*Completed: 2026-09-29*
