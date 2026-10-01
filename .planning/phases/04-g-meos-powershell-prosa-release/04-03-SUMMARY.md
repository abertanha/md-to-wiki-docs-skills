---
phase: 04-g-meos-powershell-prosa-release
plan: "03"
subsystem: i18n
tags: [powershell, mkdocs, pdf, dokuwiki, catalog, ps1]
requires:
  - phase: 04-g-meos-powershell-prosa-release
    provides: "catalog.ps1 loader (04-01), nav_issues key (04-02)"
provides:
  - "generate-mkdocs.ps1 catalog-driven, theme.language aditivo"
  - "to-pdf.ps1 catalog-driven, flags pandoc em todas as invocações"
  - "to-dokuwiki.ps1 catalog-driven, valor multi-segmento"
  - "tests/ps1-contract.sh estendido para os 4 gêmeos"
  - "tests/no-mixed-output.sh allowlist atualizada com nav_issues"
affects: ["04-04", "04-05"]
actuals:
  tokens: 8555
  tasks: 3
  commits: 3
  plan_head_before: 3ef1583
  plan_head_after: 9a213e5
tech-stack:
  added: []
  patterns: ["emissão aditiva para theme.language (omitir em en = byte-idêntico)"]
key-files:
  created: []
  modified:
    - scripts/generate-mkdocs.ps1
    - scripts/to-pdf.ps1
    - scripts/to-dokuwiki.ps1
    - tests/ps1-contract.sh
    - tests/no-mixed-output.sh
key-decisions:
  - "no_hardcoded_chrome (tests/ps1-contract.sh) precisou stripar também o token ${var} (forma com chaves), não só $var — generate-mkdocs.ps1 usa `${navHome}`/`${siteDescription}` (chaves necessárias antes de `:`), e sem esse strip o gate confundia o PRÓPRIO nome da variável com chrome hardcoded, repetindo a classe de falso positivo já documentada no plano 04-01"
  - "declared_keys_complete (tests/ps1-contract.sh) generalizado para unir TODO array `@(...)` do arquivo, não só o primeiro `$RequiredKeys` — to-pdf.ps1 declara `pdf_toc_title` via uma chamada `Assert-CatalogKey` SEPARADA, só dentro do ramo pt-br (espelhando `scripts/to-pdf.sh:40`), e o gate original (escopado a um único bloco) não capturaria essa segunda declaração"
  - "pwsh_accented_dir_survives: a perna foi adaptada por gêmeo em vez de repetir a mesma asserção de substring para os quatro — to-dokuwiki.ps1 prova pela EXISTÊNCIA do arquivo convertido no caminho acentuado, to-pdf.ps1 prova por conteúdo único do arquivo lido (o nome do diretório nunca chega ao livro, D-19), e generate-mkdocs.ps1 fica limitado a um exit-code limpo (seu laço de nav é de um nível só, sem `-Recurse`, e nunca alcança o diretório acentuado aninhado — divergência pré-existente fora de escopo, ver tabela de não-objetivos)"
requirements-completed: [CHROME-01, CHROME-03, PARAM-02, QUAL-01]
coverage:
  - id: D1
    description: "Os quatro gêmeos .ps1 resolvem chrome por chave contra o mesmo catálogo, pelo mesmo loader"
    verification:
      - kind: integration
        ref: "tests/ps1-contract.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "theme.language emitido de forma aditiva (presente em pt-br, ausente em en)"
    verification:
      - kind: integration
        ref: "tests/ps1-contract.sh (theme_language_ptbr_only, pwsh_theme_language)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Flags pandoc -M lang e -M toc-title presentes em TODAS as invocações pt-br"
    verification:
      - kind: integration
        ref: "tests/ps1-contract.sh (pandoc_langopts_all_invocations, pwsh_pandoc_langopts)"
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-09-30
status: complete
---

# Phase 04 Plan 03: Gêmeos mkdocs/PDF/DokuWiki .ps1 — catalog-driven Summary

**Os três gêmeos `.ps1` restantes (`generate-mkdocs.ps1`, `to-pdf.ps1`, `to-dokuwiki.ps1`) migrados para o padrão catalog-driven provado no plano `04-01`, cada um carregando a armadilha própria da sua superfície: `theme.language` aditivo no mkdocs, as flags de idioma do pandoc em TODAS as invocações no PDF (lição do plano `03-02`), e o bootstrap de chaves antes da guarda de pandoc mais o valor multi-segmento com apóstrofe escapada no DokuWiki — com `tests/ps1-contract.sh` estendido para cobrir os quatro gêmeos sob um único gate (doze afirmações estruturais, nove pernas comportamentais) e a allowlist do glossário declarando `nav_issues` explicitamente.**

## Performance

- **Duration:** 20min
- **Started:** 2026-09-30T17:33:47Z
- **Completed:** 2026-09-30T17:53:24Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- `scripts/generate-mkdocs.ps1`: dot-source de `lib/catalog.ps1`, `output_lang` no terceiro posicional (mesmo slot do gêmeo `.sh`), allowlist antes da resolução do caminho do catálogo (T-04-01), chrome (`site_name_suffix`, `site_description`, `nav_home`, `nav_issues`) 100% por lookup, e a projeção de `theme.language` ADITIVA: string vazia no ramo `en` (byte-idêntico preservado), `  language: pt-BR` só no ramo `pt-br` (QUAL-01/D-12) — grava via `Write-Utf8NoBom`
- `scripts/to-pdf.ps1`: bloco `param` reordenado para `<output> <output_lang> <file1.md> [...]`, `pdf_toc_title` declarado SOMENTE dentro do ramo `pt-br` (espelhando `scripts/to-pdf.sh:40`, D-06), e o array `$PandocLangOpts` splatado nas DUAS invocações de pandoc existentes (weasyprint e wkhtmltopdf) — a lição literal do plano `03-02`: cobrir só a primeira invocação produziria PDF sem locale no host que cai no fallback de engine. Título e rodapé datado por lookup (`pdf_title`, `pdf_generated_on`), livro gravado via `Write-Utf8NoBom`
- `scripts/to-dokuwiki.ps1`: assinatura `<output_dir> <output_lang> <file1.md> [...]`, o bug de slice de argumentos indexando além do fim do array corrigido (mesma classe do bug já corrigido em `generate-index.ps1` no plano `04-01`), bootstrap das três chaves do README rodando ANTES da guarda de disponibilidade do pandoc (CHROME-03/T-03-08 — um host sem pandoc halta nomeando a chave, não mascarado pelo erro de pandoc ausente), e `Expand-CatalogEscapes` aplicado SOMENTE a `dokuwiki_readme_steps` — o valor único do catálogo que exercita simultaneamente a apóstrofe escapada e as quebras de linha codificadas
- `tests/ps1-contract.sh`: `TWINS` agora cobre os quatro gêmeos, os oito gates estruturais herdados do plano `04-01` passam a cobri-los de graça (eram laços genéricos), quatro gates estruturais novos (`theme_language_ptbr_only`, `pandoc_langopts_all_invocations`, `bootstrap_before_pandoc_guard`, `expand_escapes_scoped`) e três pernas comportamentais novas gated em `pwsh` (`pwsh_pandoc_langopts`, `pwsh_theme_language`, `pwsh_dokuwiki_value_shape`); as cinco pernas comportamentais herdadas ganharam argumentos canônicos por gêmeo via três helpers novos (`twin_canonical_args`, `twin_required_key`, `twin_output_path`)
- `tests/no-mixed-output.sh`: `nav_issues` declarado na allowlist do glossário (D-21) com justificativa inline — termo técnico consagrado, idêntico em `en`/`pt-br` de propósito
- Cadeia `.sh` sai byte-intocada: `tests/fail-closed.sh` (rc=0), `tests/regress.sh` (rc=3, SKIP esperado de `pwsh`/`.ps1`), `tests/no-mixed-output.sh` (rc=0, DokuWiki incluído — `pandoc` presente neste host), `tests/no-calques.sh` (rc=0), `tests/wiki-links.sh` (rc=0) e `tests/fixtures/golden-sh/` sem diff

## Task Commits

1. **Tarefa 1: generate-mkdocs.ps1 catalog-driven com a projeção aditiva de theme.language** - `a5eed05` (feat)
2. **Tarefa 2: to-pdf.ps1 e to-dokuwiki.ps1 — flags de idioma do pandoc e o valor com apóstrofe escapada** - `a652590` (feat)
3. **Tarefa 3: estender tests/ps1-contract.sh aos quatro gêmeos e a allowlist de nav_issues** - `9a213e5` (test)

## Files Created/Modified

- `scripts/generate-mkdocs.ps1` (modificado) - catalog-driven, `theme.language` aditivo, chrome por lookup
- `scripts/to-pdf.ps1` (modificado) - catalog-driven, flags pandoc em todas as invocações, só pt-br
- `scripts/to-dokuwiki.ps1` (modificado) - catalog-driven, bootstrap antes da guarda de pandoc, slice de args corrigido, valor multi-segmento
- `tests/ps1-contract.sh` (modificado) - doze gates estruturais + nove pernas comportamentais, cobrindo os quatro gêmeos
- `tests/no-mixed-output.sh` (modificado) - `nav_issues` na allowlist do glossário

## Decisions Made

- **`no_hardcoded_chrome` precisou stripar também `${var}` (forma com chaves).** `generate-mkdocs.ps1` usa `${navHome}`, `${siteDescription}` etc. (chaves necessárias porque o valor é seguido de `:` no YAML, ambíguo sem elas) — a sed original do plano `04-01` só stripava `$var` sem chaves, então o PRÓPRIO nome da variável (`${navHome}` contém o fragmento "Home" da chave `nav_home`) disparava falso positivo. Corrigido stripando as duas formas de interpolação do PowerShell antes da busca por needle.
- **`declared_keys_complete` generalizado para unir todo array `@(...)` do arquivo.** O gate original (plano `04-01`) escaneava só o bloco `$RequiredKeys = @(...)`, assumindo uma única declaração por script. `to-pdf.ps1` precisa declarar `pdf_toc_title` numa chamada `Assert-CatalogKey` SEPARADA, só dentro do ramo `pt-br` (D-06, mesma forma do gêmeo `.sh`) — o gate foi generalizado para escanear e unir QUALQUER array de chaves entre `@(` e `)`, não só o primeiro, preservando a garantia original (declarado == expandido) sem forçar todo twin a ter exatamente um bloco de chaves.
- **`pwsh_accented_dir_survives` adaptada por gêmeo, não uma asserção única repetida.** O comportamento real de cada gêmeo frente ao diretório acentuado da fixture (`.specs/features/autenticação/`) diverge: `to-dokuwiki.ps1` grava um arquivo NO caminho acentuado (prova por existência de arquivo); `to-pdf.ps1` nunca emite o nome do diretório em lugar nenhum do livro (D-19 — sem heading por arquivo), então a prova é por conteúdo único do arquivo lido; `generate-mkdocs.ps1` usa `Get-ChildItem` sem `-Recurse` (um nível só) e por isso NUNCA alcança o diretório acentuado aninhado dentro de `features/` — pré-existente, fora do escopo deste plano — então sua perna fica limitada a um exit-code limpo. Escrever uma única asserção de substring para os quatro teria produzido uma perna estruturalmente incorreta para três deles.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `no_hardcoded_chrome` com falso positivo em `${var}` (forma com chaves)**
- **Found during:** Tarefa 1, primeira verificação
- **Issue:** A sed do gate (herdada do plano `04-01`) só removia tokens `$var` sem chaves; `generate-mkdocs.ps1` introduziu a primeira ocorrência de `${var}` no repositório (necessária antes de `:` no YAML), e o próprio nome da variável (`${navHome}`, `${siteDescription}`) batia contra o needle da chave que ela carrega
- **Fix:** sed passou a stripar as duas formas de interpolação (`${var}` primeiro, depois `$var`)
- **Files modified:** tests/ps1-contract.sh
- **Commit:** 9a213e5

**2. [Rule 1 - Bug] Segundo literal `pt-BR` num comentário quebrava `theme_language_ptbr_only`**
- **Found during:** Tarefa 1, primeira verificação
- **Issue:** O comentário acima do `switch` de projeção mencionava "pt-BR" duas vezes (uma no texto explicativo, outra no código), fazendo a contagem de literais exceder 1
- **Fix:** Reescrita do comentário para descrever o ramo sem repetir o literal
- **Files modified:** scripts/generate-mkdocs.ps1
- **Commit:** a5eed05

Nenhum outro desvio — o restante das três tarefas foi executado como escrito nos critérios de aceitação automatizados.

## Issues Encountered

`pwsh` segue ausente neste host (gap conhecido desde a Phase 1, tratado no plano `04-04` atrás de checkpoint bloqueante para humano) — as nove pernas comportamentais novas/estendidas (`pwsh_pandoc_langopts`, `pwsh_theme_language`, `pwsh_dokuwiki_value_shape` e as cinco herdadas re-parametrizadas) permanecem `[ASSUMED — não executadas sob pwsh]` até essa instalação. `pandoc` está disponível neste host, então a perna `pwsh_dokuwiki_value_shape` não seria pulada por essa segunda dependência quando `pwsh` chegar.

## Não-objetivos preservados (D-19) — registrados para o plano `04-05`

| Divergência | Estado | Onde isso apareceu neste plano |
|-------------|--------|-------------------------------|
| `generate-mkdocs.ps1` grava em `docs/mkdocs.yml`, o gêmeo `.sh` grava `mkdocs.yml` na raiz com `docs_dir`/`site_dir` explícitos | preservada | Caminho de gravação não alterado na Tarefa 1 |
| `generate-mkdocs.ps1` não copia a árvore de specs para dentro de `docs/specs` | preservada | Não tocado |
| `generate-mkdocs.ps1` itera `Get-ChildItem $SpecsDir -Directory` SEM `-Recurse` — um nível só, nunca alcança um diretório aninhado como `features/autenticação/` | preservada (defeito pré-existente não coberto pelo escopo deste plano) | Limitou a perna `pwsh_accented_dir_survives` para este gêmeo a um exit-code limpo, em vez de uma asserção de conteúdo |
| `to-pdf.ps1` não emite heading por arquivo nem separador entre arquivos | preservada | O nome do diretório acentuado nunca alcança o livro gerado — a perna de sobrevivência acentuada para este gêmeo prova por conteúdo, não pelo nome do diretório |
| `generate-index.ps1` emite linhas de tabela sem checagem de existência/glifo ausente | preservada (já registrada no plano `04-01`) | Não tocado neste plano |

Paridade estrutural de saída entre gêmeos continua fora do critério de sucesso da Phase 4, por decisão já registrada no plano.

## Auditoria delta — `docs/skill-quality-rubric.md`

Nenhum arquivo de skill (`SKILL.md`/agent) foi tocado neste plano — apenas `scripts/*.ps1` (código de geração) e `tests/*.sh` (harness de teste). O rubric de 22 dimensões não se aplica diretamente a esses artefatos (mesmo critério já usado no plano `04-01` para `tests/ps1-contract.sh`). Nenhuma auditoria de rubric necessária.

## User Setup Required

None — nenhuma configuração de serviço externo necessária. A instalação de `pwsh` (dev-only) continua tratada no plano `04-04` atrás de checkpoint bloqueante para humano.

## Next Phase Readiness

- Os quatro gêmeos `.ps1` estão sob o mesmo gate (`tests/ps1-contract.sh`), prontos para a instalação de `pwsh` no plano `04-04` exercitar as nove pernas comportamentais que hoje ficam `SKIPPED`
- `tests/no-mixed-output.sh`'s allowlist já cobre `nav_issues` antes de qualquer superfície `.sh` vir a consumi-la, evitando reprovação em silêncio futura
- A tabela de divergências estruturais preservadas acima está pronta para o plano `04-05` registrar como itens deferidos formais
- Nenhum bloqueio conhecido para `04-04`/`04-05`

## Self-Check: PASSED

Todos os arquivos declarados (`scripts/generate-mkdocs.ps1`, `scripts/to-pdf.ps1`, `scripts/to-dokuwiki.ps1`, `tests/ps1-contract.sh`, `tests/no-mixed-output.sh`) e os 3 hashes de commit de tarefa (`a5eed05`, `a652590`, `9a213e5`) confirmados presentes.

---
*Phase: 04-g-meos-powershell-prosa-release*
*Completed: 2026-09-30*
