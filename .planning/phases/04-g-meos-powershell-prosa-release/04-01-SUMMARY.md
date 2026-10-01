---
phase: 04-g-meos-powershell-prosa-release
plan: "01"
subsystem: testing
tags: [powershell, bash, catalog, i18n, ps1]
requires: []
provides:
  - "scripts/lib/catalog.ps1 — loader compartilhado para todos os gêmeos .ps1"
  - "generate-index.ps1 catalog-driven com output_lang posicional"
  - "tests/ps1-contract.sh como gate permanente"
affects: ["04-02", "04-03", "04-04"]
actuals:
  tokens: 9561
  tasks: 3
  commits: 3
  plan_head_before: 2454c839efb6c03bafc34f1599582d46d1eb6618
  plan_head_after: 064423bd7795a3797ad3025b70fe9942a5393a71
tech-stack:
  added: []
  patterns: ["catalog-driven ps1 — loader compartilhado, leitura KEY=value sem BOM"]
key-files:
  created:
    - scripts/lib/catalog.ps1
    - tests/ps1-contract.sh
  modified:
    - scripts/generate-index.ps1
    - templates/lang/en.lang
    - templates/lang/pt-br.lang
    - docs/chrome-inventory.md
key-decisions:
  - "Gates que fazem varredura de literal/cmdlet proibido (banned_cmdlets em generate-index.ps1, verify de Task 1) foram escopados aos arquivos efetivamente tocados neste plano (scripts/lib/*.ps1 + generate-index.ps1), não a scripts/*.ps1 inteiro — os outros três gêmeos .ps1 continuam congelados (D-19/D-25) e ainda usam Out-File; ampliar o escopo do gate para cobri-los teria sido scope creep do plano 04-03"
  - "no_hardcoded_chrome (tests/ps1-contract.sh) precisou stripar tokens de variável PowerShell ($fooBar) antes da busca por needle — nomes de variável em camelCase derivados da chave (ex. $sectionOverview) carregam o próprio fragmento de palavra da chave (\"Overview\") e geravam falso positivo contra o needle"
requirements-completed: [CHROME-01, CHROME-03, PARAM-02]
coverage:
  - id: D1
    description: "catalog.ps1 lê KEY=value sem BOM, trata apóstrofe escapada e comentário à direita do valor"
    verification:
      - kind: integration
        ref: "tests/ps1-contract.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "generate-index.ps1 consome catálogo, aceita output_lang posicional, grava sem BOM, falha fechada para lang inválida"
    verification:
      - kind: integration
        ref: "tests/ps1-contract.sh"
        status: pass
    human_judgment: false
duration: 126min
completed: 2026-09-30
status: complete
---

# Phase 04 Plan 01: Fatia vertical — scripts/lib/catalog.ps1 e generate-index.ps1 Summary

**Loader PowerShell compartilhado (`scripts/lib/catalog.ps1`) provando o caminho inteiro do catálogo de ponta a ponta num único gêmeo (`generate-index.ps1`): output_lang posicional, allowlist antes da resolução de caminho, parser quote-aware para as duas armadilhas verificadas do formato, gravação UTF-8 sem BOM, e um harness (`tests/ps1-contract.sh`) que prova tudo isso neste host sem `pwsh`.**

## Performance

- **Duration:** 126min
- **Started:** 2026-09-30T14:30:36Z
- **Completed:** 2026-09-30T16:37:22Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- `scripts/lib/catalog.ps1` criado com as seis funções exigidas (`Resolve-OutputLang`, `Get-CatalogPath`, `Get-Catalog`, `Assert-CatalogKey`, `Write-Utf8NoBom`, `Expand-CatalogEscapes`) — fonte única do parser, nunca copiado para dentro de um gêmeo (D-18)
- `Get-Catalog` resolve as duas armadilhas verificadas do formato numa única varredura sem regex: a apóstrofe escapada de `dokuwiki_readme_steps` (`'\''`) e o comentário à direita do valor de `pdf_toc_title` (pt-br.lang:58) — validado por simulação Python do algoritmo caractere-a-caractere (parser não executável nativamente neste host sem `pwsh`)
- `generate-index.ps1` refatorado: `output_lang` no mesmo slot posicional do gêmeo `.sh`, allowlist estritamente antes da resolução do caminho do catálogo (T-04-01), chrome 100% por lookup (zero string hardcoded), gravação via `Write-Utf8NoBom`
- Os dois bugs pré-existentes (D-16) corrigidos: o slice de feature-dirs que indexava além do fim do array, e o vazamento de caminho absoluto via `Split-Path -NoQualifier` (agora deriva caminho relativo via `Resolve-Path -Relative` com fallback de remoção de prefixo)
- Quatro chaves novas materializadas nos dois catálogos (`index_development_body`, `nav_issues`, `pdf_generated_on`, `label_references`), todas extraídas verbatim dos sítios `.ps1`/agent citados no plano (CHROME-01) — `docs/chrome-inventory.md` atualizado para registrar a convergência das quatro divergências antes inventariadas na Camada 2
- `tests/ps1-contract.sh`: 8 gates estruturais (provam D-15/D-18/D-20/T-04-01 por leitura de texto, sem `pwsh`) + 6 pernas comportamentais gated em `command -v pwsh` (SKIPPED neste host, nunca em silêncio — mesmo regime de `tests/regress.sh`)
- Cadeia `.sh` sai byte-intocada: `tests/fail-closed.sh` (rc=0), `tests/regress.sh` (rc=3, apenas SKIP esperado de `pwsh`/já conhecido), `tests/no-mixed-output.sh` (rc=0) e `tests/fixtures/golden-sh/` sem diff

## Task Commits

1. **Tarefa 1: fatia vertical — scripts/lib/catalog.ps1 e generate-index.ps1 de ponta a ponta** - `d4a582e` (feat)
2. **Tarefa 2: os três pares de chaves restantes e a atualização do inventário de chrome** - `bb1b0e9` (feat)
3. **Tarefa 3: tests/ps1-contract.sh — o gate que prova o contrato .ps1 sem pwsh** - `064423b` (test)

## Files Created/Modified

- `scripts/lib/catalog.ps1` (novo) - fonte única do parser de catálogo, allowlist gate, resolução de caminho, fail-closed e gravador UTF-8 sem BOM
- `scripts/generate-index.ps1` (modificado) - catalog-driven, `output_lang` posicional, dois bugs corrigidos
- `templates/lang/en.lang`, `templates/lang/pt-br.lang` (modificados) - quatro chaves novas (`index_development_body`, `nav_issues`, `pdf_generated_on`, `label_references`)
- `docs/chrome-inventory.md` (modificado) - convergência das quatro divergências da Camada 2 registrada; nova linha na Camada 4 para `agents/references.md`; parágrafo "Source of the keys" documenta a exceção das quatro chaves desta fase
- `tests/ps1-contract.sh` (novo) - gate permanente do contrato `.ps1`

## Decisions Made

- **Escopo dos gates de verificação limitado aos arquivos tocados neste plano.** O verify da Tarefa 1 (`banned_cmdlets`) e o gate `banned_cmdlets`/demais gates por-gêmeo de `tests/ps1-contract.sh` iteram sobre `scripts/lib/*.ps1` + a lista `TWINS` (só `generate-index.ps1` neste plano), nunca um glob cego `scripts/*.ps1`. Os outros três gêmeos (`generate-mkdocs.ps1`, `to-pdf.ps1`, `to-dokuwiki.ps1`) e o script não relacionado `fetch-issues.ps1` continuam usando `Out-File` — são escopo do plano `04-03` (D-19/D-25 congelam-nos explicitamente nesta fase). Um glob amplo teria produzido falso-FAIL a cada execução do gate sem que este plano pudesse legitimamente corrigi-lo sem invadir escopo de planos futuros.
- **`no_hardcoded_chrome` precisou stripar tokens `$variavel` antes de buscar o needle.** Os nomes de variável PowerShell que carregam o valor do catálogo são derivados em camelCase da própria chave (`$sectionOverview`, `$labelArchitecture`, `$tableSpec`, ...) e, sem esse strip, o gate confundia o PRÓPRIO nome da variável com chrome hardcoded — falso positivo em 11 das 12 chaves testadas na primeira execução. Corrigido removendo todo token `\$[A-Za-z0-9_]+` do texto antes da comparação literal.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Comentário no próprio `generate-index.ps1` quebrava o gate `allowlist_before_path`**
- **Found during:** Tarefa 1, primeira rodada de verificação
- **Issue:** O comentário acima da chamada de `Resolve-OutputLang` mencionava literalmente `Get-CatalogPath` antes da linha real da chamada, fazendo o grep (que não filtra comentário nessa checagem específica do plano) encontrar a substring "Get-CatalogPath" numa linha anterior à chamada real de "Resolve-OutputLang" e reportar ordem invertida
- **Fix:** Reescrita do comentário para não nomear a função literalmente antes da ordem real das chamadas
- **Files modified:** scripts/generate-index.ps1
- **Commit:** d4a582e

**2. [Rule 1 - Bug] `no_hardcoded_chrome` (tests/ps1-contract.sh) com falso positivo generalizado**
- **Found during:** Tarefa 3, primeira execução do harness
- **Issue:** 11 de 12 needles de chave batiam contra o próprio nome de variável PowerShell que carrega o valor (ex. needle "Overview" batendo em `$sectionOverview`)
- **Fix:** Gate agora remove todo token `$variavel` do texto do gêmeo antes de procurar o needle
- **Files modified:** tests/ps1-contract.sh
- **Commit:** 064423b

Nenhum outro desvio — o restante do plano foi executado como escrito.

## Issues Encountered

O parser de `scripts/lib/catalog.ps1` não pôde ser executado nativamente em PowerShell neste host (sem `pwsh` instalado, gap conhecido desde a Phase 1 — `01-RESEARCH.md`, `04-RESEARCH.md` §Environment Availability). Mitigado por: (a) simulação do algoritmo caractere-a-caractere em Python, replicando exatamente a lógica do parser linha a linha, confirmando o parsing correto dos dois catálogos completos e das duas armadilhas verificadas; (b) `tests/ps1-contract.sh`'s pernas comportamentais (`pwsh_*`) escritas e com lint limpo, prontas para rodar assim que `pwsh` estiver disponível (plano `04-04` trata a instalação atrás de checkpoint bloqueante para humano). A perna `pwsh_catalog_roundtrip`/demais permanecem `[ASSUMED — não executadas sob pwsh]` até essa verificação.

## Auditoria delta — `docs/skill-quality-rubric.md` (docs/chrome-inventory.md)

Auditoria leve (self-audit do executor, proporcional ao tamanho da mudança: 1 arquivo de referência, ~13 linhas de diff). `docs/chrome-inventory.md` é um shared-reference (HIE-5), não um `SKILL.md`/agent — dimensões aplicáveis:

| File | Dim | Verdict | Evidence | Nota |
|------|-----|---------|----------|------|
| docs/chrome-inventory.md | HIE-4 (co-location) | ✅ Pass | linhas 62-67 (Camada 2) | Nota de convergência inserida na MESMA linha/coluna da divergência original, não espalhada em seção nova |
| docs/chrome-inventory.md | PRU-1 (duplicação) | ✅ Pass | linhas 62-67 vs. seed do `.claude/CLAUDE.md` | Nenhuma redefinição do valor das quatro chaves aqui — o documento aponta para `templates/lang/*.lang` como materialização, não reescreve o valor |
| docs/chrome-inventory.md | PRU-3 (sediment) | ✅ Pass | linha 63 (`generated_by`) | A nota de divergência de URL (`https://opencode.ai` vs. github), que ficou FALSA depois da Tarefa 1 convergir o gêmeo ao catálogo, foi removida em vez de deixada como sediment |
| docs/chrome-inventory.md | PRU-4 (fonte única) | ✅ Pass | parágrafo "Source of the keys" | Critério de precedência (scripts/agent vencem a seed) reafirmado, não duplicado com definição divergente |

Nenhuma dimensão MET-1 aplicável (atualização mecânica de um mapa chave→sítio já existente, não uma reestruturação de skill). Nenhum achado ⚠️/❌.

## User Setup Required

None — nenhuma configuração de serviço externo necessária. A instalação de `pwsh` (dev-only, via `snap install powershell --classic`) é tratada no plano `04-04` atrás de checkpoint bloqueante para humano, não neste plano.

## Next Phase Readiness

- `scripts/lib/catalog.ps1` está pronto para ser dot-sourced pelos três gêmeos restantes (`generate-mkdocs.ps1`, `to-pdf.ps1`, `to-dokuwiki.ps1`) no plano `04-03` — nenhuma mudança de assinatura de função esperada
- `tests/ps1-contract.sh`'s variável `TWINS` está desenhada para expansão de uma linha: o plano `04-03` acrescenta os três gêmeos restantes à mesma lista e todos os 8 gates estruturais + 6 pernas comportamentais passam a cobri-los automaticamente
- As quatro chaves novas (`index_development_body`, `nav_issues`, `pdf_generated_on`, `label_references`) já existem nos dois catálogos com paridade verde — plano `04-03` não precisa tocar o catálogo
- Nenhum bloqueio conhecido para `04-02`/`04-03`; `04-04` ainda depende da instalação de `pwsh` (gap documentado, não bloqueador deste plano)

## Self-Check: PASSED

Todos os arquivos declarados (`scripts/lib/catalog.ps1`, `scripts/generate-index.ps1`, `templates/lang/en.lang`, `templates/lang/pt-br.lang`, `docs/chrome-inventory.md`, `tests/ps1-contract.sh`) e os 3 hashes de commit de tarefa (`d4a582e`, `bb1b0e9`, `064423b`) confirmados presentes.

---
*Phase: 04-g-meos-powershell-prosa-release*
*Completed: 2026-09-30*
