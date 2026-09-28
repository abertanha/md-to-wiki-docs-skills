# Phase 1: Contrato & Golden Fixtures - Context

**Gathered:** 2026-09-28
**Status:** Ready for planning

<domain>
## Phase Boundary

`OUTPUT_LANG` (`en` | `pt-br`, default `pt-br`) entra na camada de contrato da skill (tabela Variables do `CONTEXT.md` + entrevista do `agents/onboarding.md` + transmissão por dispatch prompt), as decisões de escopo do i18n ficam registradas no contrato, e o comportamento `en` atual é congelado em golden fixtures (5 superfícies, por geminho `.sh`/`.ps1`) com harness de diff que roda sem engines — tudo **antes** de qualquer refactor de strings (que começa na Phase 2). Também desta fase: o inventário de chrome (4 camadas × 5 superfícies, chave → arquivo:linha) em `docs/chrome-inventory.md`.

Fora do escopo: extração/consumo do catálogo (Phase 2), qualquer tradução pt-br (Phase 3), gêmeos `.ps1` refatorados + prosa/glossário (Phase 4).

</domain>

<decisions>
## Implementation Decisions

**Já travado antes desta discussão (não reabrir):** `OUTPUT_LANG` com valores `en` | `pt-br`, default `pt-br`, token canônico minúsculo, atribuição exclusiva no onboarding, transmissão por dispatch prompt (PARAM-01); normalização `pt-br` ≡ `pt-BR` + tabela de projeção por consumidor (`pt-BR` Material/pandoc/HTML, `pt_BR` Pyphen) + fail-closed listando suportados (PARAM-02); formato/lugar do catálogo (`templates/lang/*.lang`, `KEY=value`, UTF-8 sem BOM — definido no stack do projeto, implementado na Phase 2); datas ISO 8601 nos dois idiomas; escopo Swagger = título + `lang` com limite upstream documentado; console dos scripts permanece em inglês.

### Escopo dos golden fixtures
- **D-01:** Golden fixtures cobrem as **5 superfícies publicáveis**: `index.md`, `mkdocs.yml` + `docs/` (nav), mirror DokuWiki, livro-PDF **no fallback markdown sem engine** (comportamento atual e determinístico do `to-pdf.sh`/`to-pdf.ps1` sem pandoc), e Swagger UI. Intermediários (`specs-book.md`, `merged-specs/`) ficam **de fora** — só saídas publicáveis.
- **D-02:** Swagger é congelado como **template + instância renderada**: o harness aplica a substituição dos `{{…}}` com valores da fixture via `sed` e diffa contra a instância golden — congela também o contrato de renderização atual que a Phase 3 vai traduzir.

### Gêmeos .ps1 sem pwsh no host
- **D-03:** Instalar `pwsh` no host como dependência **somente de dev** (não runtime; o MET-1 conta custo por execução, não setup único) e capturar os goldens `.ps1` já na Phase 1. Baseline documentado: **PowerShell 7 no Linux** — a verificação PS 5.1 real continua como gap registrado no STATE.md (BOM/CRLF podem diferir entre 5.1 e 7).
- **D-04:** Harness sem `pwsh` no host: a perna `.ps1` é marcada `SKIPPED` com o motivo e o processo termina com **exit code próprio (ex.: 3)** — execução parcial é máquina-detectável, nunca silenciosa; `pwsh` não vira obrigação global para rodar a regressão.

### Árvore de teste
- **D-05:** A tree de entrada é a **réplica da fixture validada `/tmp/mdw-sr3`** (nav 5 seções, links internos 100%) **+ `features/autenticação/`** como diretório acentuado — mesmo nome que a Phase 3 usará no critério de corrupção de bytes.
- **D-06:** A tree vive **commitada como arquivos `.md` reais** em `tests/fixtures/` — imutável, auditável, diff do golden revisável arquivo a arquivo; a fonte da verdade é conteúdo, não código gerador.

### Inventário de chrome
- **D-07:** Formato **chave → sítio**: cada linha usa a chave futura do catálogo (`site_name_suffix`, `nav_home`, `section_quick_start`, … — seed do glossário definida no stack do projeto) mapeada ao `arquivo:linha` atual. A Phase 2 extrai as strings `en` **verbatim** conferindo contra o inventário; o rubric audita o par en/pt-br completo contra o mesmo mapa.
- **D-08:** Casa: **`docs/chrome-inventory.md`** para o mapa; o contrato da skill (`CONTEXT.md`) recebe **somente as decisões de escopo** (política fail-closed de chave ausente, localização/formato do catálogo, escopo Swagger, datas ISO 8601) e aponta para o mapa — o contrato é lido por agents em runtime e permanece enxuto.

### Decisões da sessão de planejamento (pós-pesquisa, Q1–Q4)
- **D-09 (Q1):** `pandoc` entra como dependência **somente de dev** (mesmo regime do pwsh, D-03) — `to-dokuwiki.*` faz `exit 1` sem pandoc, então o golden DokuWiki congela a saída real do pandoc; o harness marca a perna como `SKIPPED`/exit 3 quando pandoc está ausente, igual à perna `.ps1`.
- **D-10 (Q2):** O golden `.ps1` da superfície PDF vem de `specs-book.md` (o que `to-pdf.ps1` produz sem pandoc) — **exceção documentada a D-01** (o geminho `.ps1` não tem fallback markdown); é onde vive o rodapé datado, então a máscara de data continua coberta.
- **D-11 (Q3):** `AUDIENCE=general` fixo na captura dos goldens (determinismo; chrome inventariado não depende do valor); valor registrado no harness.
- **D-12 (Q4):** `templates/index.md` entra no inventário de chrome como **unconsumed** (arquivo:linha incluídos, marcado como tal) — congela o estado real e informa a Phase 2 de que nada o lê.

### Claude's Discretion
- Mecânica da máscara de data: token simétrico aplicado no golden e na saída fresca **antes** do diff, cobrindo os 3 sítios datados da cadeia (`scripts/generate-index.sh:105`, `scripts/generate-index.ps1:84`, `scripts/to-pdf.ps1:21`); token e sítios documentados no harness e no contrato da fase. Nota: `to-pdf.ps1` emite rodapé datado que o `to-pdf.sh` não emite — divergência entre gêmeos que os goldens por geminho capturam como estão (wart atual preservado).
- Layout interno de `tests/` (harness em `tests/regress.sh` — nome que a Phase 4 referencia — + `tests/fixtures/` com a tree e os goldens `.sh`/`.ps1` separados por geminho).
- Invocação canônica dos scripts na captura (args, cwd, ordem de execução por superfície).
- Redação exata da seção de decisões de escopo no contrato da skill e da pergunta `OUTPUT_LANG` no onboarding (seguir o padrão AUDIENCE: tokens canônicos + descrição por valor; default `pt-br` registrado quando o usuário manifesta indiferença).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Contrato da skill (onde OUTPUT_LANG entra)
- `CONTEXT.md` — tabela §Variables (nova linha `OUTPUT_LANG`), §Script-call convention; princípio de casa única: agents referenciam, não reenunciam
- `agents/onboarding.md` — §Interview (padrão da pergunta `AUDIENCE`: tokens canônicos + descrição), mecanismo único de atribuição, §Return criteria (lista de variáveis a retornar cresce com `OUTPUT_LANG`)

### Requisitos & roadmap do milestone
- `.planning/REQUIREMENTS.md` — PARAM-01, PARAM-02 (critérios 1–2 da fase), QUAL-02 (critérios 3–4); §Out of Scope (fallback silencioso, conditionais inline, deps novas)
- `.planning/ROADMAP.md` §Phase 1 — os 5 success criteria que esta fase entrega

### ADRs & instrumento de qualidade
- `docs/adr/0003-mkdocs-chain-repair.md` — host sem engines; gates estruturais no interim
- `docs/adr/0004-script-primary-pdf.md` — cadeia PDF script-primary; fallback sem pandoc é a base do golden da superfície PDF
- `docs/skill-quality-rubric.md` — todo arquivo de skill tocado passa por auditoria delta com este rubric

### Cadeia atual (fonte dos goldens e do inventário)
- `scripts/generate-index.sh` · `scripts/generate-mkdocs.sh` · `scripts/to-dokuwiki.sh` · `scripts/to-pdf.sh` — cadeia `.sh` (chrome em `generate-index.sh` e `generate-mkdocs.sh:43,59`; data em `generate-index.sh:105`)
- `scripts/generate-index.ps1` · `scripts/generate-mkdocs.ps1` · `scripts/to-dokuwiki.ps1` · `scripts/to-pdf.ps1` — gêmeos (datas em `generate-index.ps1:84`, `to-pdf.ps1:17,21`)
- `templates/swagger-ui.html` — placeholders `{{PROJECT_NAME}}`/`{{OPENAPI_YML}}`, título `:6`; `templates/index.md`
- `agents/format-mkdocs.md` · `agents/format-github-wiki.md` · `agents/format-dokuwiki.md` · `agents/format-pdf.md` · `agents/format-swagger.md` — camada 4 do inventário (headings/prose de chrome dos agents)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Fixture `/tmp/mdw-sr3` (validada: nav 5 seções, links internos 100%) — base da tree de teste; existe só em `/tmp`, precisa ser replicada para `tests/fixtures/` (+ `features/autenticação/`)
- Tabela Variables do `CONTEXT.md` + entrevista do onboarding — padrão `AUDIENCE` é o molde exato da pergunta `OUTPUT_LANG`
- Estrutura por geminho `.sh`/`.ps1` já alinhada função a função — a captura separada por geminho espelha a organização existente

### Established Patterns
- Contrato como casa única: variáveis vivem no `CONTEXT.md`, o onboarding é o único ponto de atribuição, dispatch prompt é o único meio de transmissão
- Fail-closed em valor desconhecido (erro nomeando o problema, nunca fallback silencioso) — estende-se ao exit 3 do harness (D-04) e à política de chave ausente que o contrato registra
- Datas ISO 8601 já vigentes nos 3 sítios datados — máscara é ortogonal ao formato

### Integration Points
- `CONTEXT.md` §Variables ← nova linha `OUTPUT_LANG`; `agents/onboarding.md` §Interview + §Return criteria ← nova pergunta e novo token de retorno; dispatch prompts dos `agents/format-*.md` ← transmissão (mesmo mecanismo de `AUDIENCE`)
- `tests/regress.sh` + `tests/fixtures/` — fronteira nova que a Phase 4 wired no fluxo e a Phase 2 usa como checkpoint duro
- `docs/chrome-inventory.md` — mapa novo que semeia o catálogo da Phase 2

</code_context>

<specifics>
## Specific Ideas

- `features/autenticação/` é o diretório acentuado canônico da tree — mesmo nome do critério de corrupção de bytes da Phase 3 (continuidade entre fases)
- Chaves do inventário = seed do glossário já definida no stack do projeto (`site_name_suffix`, `nav_home`, `section_quick_start`, `section_overview`, …) — o inventário não inventa chaves novas, usa essas
- Baseline pwsh é PS7; qualquer diferença BOM/CRLF vs PS 5.1 fica documentada como gap conhecido (já registrado no STATE.md), não como bloqueio

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Contrato & Golden Fixtures*
*Context gathered: 2026-09-28*
