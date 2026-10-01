---
phase: 04-g-meos-powershell-prosa-release
plan: "04"
subsystem: testing
tags: [powershell, regression, golden-fixtures, ps1, bugfix]
requires:
  - phase: 04-g-meos-powershell-prosa-release
    provides: "4 gêmeos .ps1 catalog-driven (04-01, 04-03)"
provides:
  - "Perna .ps1 real em tests/regress.sh (funções run_chain_ps1/run_dokuwiki_ps1)"
  - "tests/fixtures/golden-ps1/ — primeiros golden fixtures .ps1 do projeto"
  - "Manifesto atualizado com pin de versão pwsh 7.6.5, SHA da captura e registro dos bugs achados"
  - "Três bugs pré-existentes corrigidos nos gêmeos .ps1 (to-pdf.ps1, to-dokuwiki.ps1, generate-mkdocs.ps1)"
  - "Dois bugs de robustez corrigidos em tests/ps1-contract.sh (aborto prematuro sob set -e, tolerância D-10)"
affects: ["04-05"]
actuals:
  tokens: 14578
  tasks: 3
  commits: 3
  plan_head_before: bec7abe
  plan_head_after: 32f92fd
tech-stack:
  added: [powershell 7.6.5 via snap]
  patterns:
    - "golden fixture pattern para .ps1 — captura determinística com pin de versão"
    - "helper compartilhado (pdf_status_tolerated) para uma exceção documentada (D-10) usada por múltiplas pernas de teste"
    - "[Parameter(ValueFromRemainingArguments = $true)] como idioma correto para 'arquivos restantes' em param() do PowerShell — [string[]] posicional sozinho NÃO junta argumentos extras"
key-files:
  created:
    - tests/fixtures/golden-ps1/mkdocs/docs/mkdocs.yml
    - tests/fixtures/golden-ps1/mkdocs/docs/index.md
    - tests/fixtures/golden-ps1/pdf/specs-book.md
    - tests/fixtures/golden-ps1/dokuwiki/README.md
    - tests/fixtures/golden-ps1/dokuwiki/data/pages/ (7 páginas convertidas)
  modified:
    - tests/regress.sh (Tarefa 1 — perna .ps1 real, commit prévio cf70afc)
    - tests/fixtures/manifest.md
    - tests/ps1-contract.sh
    - scripts/to-pdf.ps1
    - scripts/to-dokuwiki.ps1
    - scripts/generate-mkdocs.ps1
key-decisions:
  - "pwsh instalado via snap (canonical Microsoft) — checkpoint:human-action da Tarefa 2 cleared pelo usuário; PATH precisa incluir /snap/bin"
  - "Golden fixtures capturados com pwsh 7.6.5 num host sem engine de PDF (nem weasyprint nem wkhtmltopdf) — a superfície pdf ficou sob a exceção D-10 já prevista no manifesto, igual ao lado .sh"
  - "Bugs achados nos gêmeos .ps1 durante a primeira execução real da perna foram corrigidos in-line (Regra 1 de desvio), não deferidos — o próprio plano autoriza isso explicitamente ('se alguma perna falhar, o defeito está nos gêmeos e não no harness — conserte no gêmeo')"
  - "Bugs de robustez achados em tests/ps1-contract.sh (aborto prematuro sob set -e, tolerância D-10 ausente) também corrigidos in-line — bloqueavam diretamente o critério de aceite da própria Tarefa 3 (rodar a suíte inteira e ver FAIL=0)"
  - "Manifesto recebeu o SHA do commit de captura num commit de acompanhamento separado (docs), porque o hash de um commit só existe depois de criado — mesmo padrão já usado nas duas linhas de SHA anteriores do manifesto"
requirements-completed: [QUAL-02]
coverage:
  - id: D1
    description: "Perna .ps1 de tests/regress.sh executa de verdade (não SKIPPED) com pwsh presente"
    verification:
      - kind: integration
        ref: "tests/regress.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "tests/fixtures/golden-ps1/ capturado e byte-idêntico na re-execução (duas rodadas consecutivas, zero FAIL, rc determinístico)"
    verification:
      - kind: integration
        ref: "tests/regress.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Manifesto registra pin de versão pwsh, SHA da captura e os bugs achados/corrigidos"
    verification:
      - kind: unit
        ref: "grep 'pwsh --version' tests/fixtures/manifest.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "Os quatro gêmeos .ps1 produzem saída correta sob tests/ps1-contract.sh (21/21 OK, zero FAIL, zero SKIPPED)"
    verification:
      - kind: integration
        ref: "tests/ps1-contract.sh"
        status: pass
    human_judgment: false
  - id: D5
    description: "Cadeia .ps1 com pt-br roda de ponta a ponta fora do harness (mkdocs.yml com theme.language, index.md em PT-BR, livro PDF em PT-BR, README DokuWiki em PT-BR)"
    verification:
      - kind: manual
        ref: "execução manual em /tmp/ptbr-e2e durante a Tarefa 3"
        status: pass
    human_judgment: true
duration: ~45min (Tarefa 3; Tarefas 1-2 em sessão anterior)
completed: 2026-09-30
status: complete
---

# Phase 04 Plan 04: Gêmeos PowerShell — Perna de Regressão .ps1 e Golden Fixtures Summary

Primeira execução real da perna `.ps1` do harness de regressão (`tests/regress.sh`) e do conjunto comportamental de `tests/ps1-contract.sh`, num host com PowerShell 7.6.5 — o que expôs e permitiu corrigir três bugs pré-existentes nos gêmeos `.ps1` (nunca antes exercitados de verdade por falta de `pwsh` em qualquer host anterior do projeto) e dois bugs de robustez no próprio harness de teste.

## O que foi feito

**Tarefa 1** (sessão anterior, commit `cf70afc`): implementou as funções `run_chain_ps1` e `run_dokuwiki_ps1` em `tests/regress.sh`, substituindo o stub permanente, e registrou os pins da invocação canônica `.ps1` no manifesto.

**Tarefa 2** (checkpoint:human-action): o usuário instalou PowerShell 7 via `sudo snap install powershell --classic` — `pwsh 7.6.5` confirmado disponível em `/snap/bin/pwsh`.

**Tarefa 3** (esta sessão, commits `7a82332` e `32f92fd`) — Ramo A (pwsh disponível):

1. Rodou `bash tests/regress.sh capture`. Os goldens `.sh` mudaram por UM byte esperado (a data do rodapé, `2026-09-29` → `2026-09-30`, dia de hoje) — revertido para `HEAD` (não é regressão, é ruído de data de captura; confirmado isolando o diff a essa única linha antes de reverter).
2. Capturou `tests/fixtures/golden-ps1/` (mkdocs, pdf, dokuwiki) — os primeiros golden fixtures `.ps1` da história do projeto.
3. Confirmou os invariantes de bytes: zero BOM em qualquer arquivo capturado, nome do diretório acentuado (`autenticação`) intacto sem mojibake, e `repo_url:` vazio no `mkdocs.yml` (a captura roda fora de qualquer repositório git, T-04-08).
4. Rodou `bash tests/regress.sh` duas vezes consecutivas: `rc=0` nas duas, zero `FAIL:`, determinístico.
5. Rodou `bash tests/ps1-contract.sh`: inicialmente 2 `FAIL:` e aborto prematuro da suíte (investigado e corrigido, ver Deviations); após as correções, 21/21 `OK:`, zero `FAIL:`, zero `SKIPPED:`.
6. Rodou a cadeia `.ps1` com `pt-br` fora do harness, num `mktemp -d`: `mkdocs.yml` com `theme.language: pt-BR`, `index.md` com rótulos PT-BR e diretório acentuado intacto, livro PDF com título PT-BR, README DokuWiki com os quatro passos em PT-BR.
7. Preencheu no manifesto a versão real do `pwsh` (7.6.5) e o SHA do commit de captura (`7a82332`, registrado num commit de acompanhamento porque o hash só existe depois do commit criado).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `to-pdf.ps1` só processava o primeiro arquivo de qualquer invocação multi-arquivo**
- **Found during:** Tarefa 3, ao investigar por que `pwsh_accented_dir_survives` falhava com "authentication feature governs" ausente do livro.
- **Issue:** O bloco `param([string]$Output, [string]$OutputLangRaw, [string[]]$Files)` não usava `ValueFromRemainingArguments`. Testado empiricamente: o binder posicional do PowerShell liga `[string[]]$Files` a UM valor só quando chamado via `pwsh -File script.ps1 a b c d`, e todo argumento além do declarado cai silenciosamente em `$args` sem nenhum erro. Esta era a hipótese de MENOR confiança de toda a `04-RESEARCH.md` ("que o bloco param de to-pdf.ps1 liga o parâmetro de array de forma gulosa aos argumentos restantes") — e se provou ERRADA. Toda invocação de 7 arquivos produzia um livro de 1 arquivo (43 linhas em vez de 205), sem nenhum sinal de erro.
- **Fix:** `[Parameter(ValueFromRemainingArguments = $true)]` no parâmetro `$Files`. Confirmado via teste isolado (`/tmp/testparam5.ps1`) antes e depois do fix, e via re-captura do golden mostrando as 8 seções (`# `) esperadas.
- **Files modified:** `scripts/to-pdf.ps1`
- **Commit:** `7a82332`

**2. [Rule 1 - Bug] `to-dokuwiki.ps1` falhava ao criar diretório-pai com page-id contendo `:`**
- **Found during:** Tarefa 3, primeira execução do modo `capture` (erros `New-Item: Cannot bind argument to parameter 'Path' because it is an empty string` no console, um por arquivo convertido).
- **Issue:** O separador de page-id do DokuWiki É o `:` (CHROME-04). `Split-Path -Parent` interpreta um `:` no último segmento de um caminho RELATIVO como qualificador de unidade (Windows drive letter semantics), devolvendo string vazia como diretório-pai. `New-Item -Path ''` falha. Tolerado silenciosamente nesta fixture só porque o diretório-pai (`dokuwiki/data/pages`) já existia via `New-Item` anterior — mas imprimia erro no console a cada arquivo, e quebraria de verdade para qualquer page-id com nesting real além de `pages/`.
- **Fix:** `[System.IO.Path]::GetDirectoryName()` no lugar de `Split-Path -Parent` — faz split de string puro, sem semântica de drive, mesmo padrão que `dirname` no lado `.sh` (`to-dokuwiki.sh:57`).
- **Files modified:** `scripts/to-dokuwiki.ps1`
- **Commit:** `7a82332`

**3. [Rule 1 - Bug] `generate-mkdocs.ps1` vazava caminho absoluto do host no nav do `mkdocs.yml`**
- **Found during:** Tarefa 3, ao rodar `bash tests/regress.sh` (segunda execução divergiu da primeira: `FAIL: mkdocs .ps1 (docs/) diverged`, mostrando `/tmp/tmp.XXXXX/.specs/...` diferente entre as duas rodadas).
- **Issue:** Mesma classe de bug D-16 já corrigida em `generate-index.ps1` (plano `04-01`), nunca replicada em `generate-mkdocs.ps1`. A regex `-replace '^.[/\\]', ''` nunca casa contra um caminho absoluto Unix (`/tmp/...` não tem um único caractere seguido de `/` no início — o primeiro caractere já É `/`), então `$file.FullName` (sempre absoluto, via `Get-ChildItem`) vazava inteiro para dentro do YAML — informação do sistema de arquivos do host publicada num documento, e não-determinístico entre execuções (o `mktemp -d` muda a cada rodada).
- **Fix:** `Resolve-Path -Relative` com fallback de remoção de prefixo de `$cwd`, mesma abordagem já usada em `generate-index.ps1`.
- **Files modified:** `scripts/generate-mkdocs.ps1`
- **Commit:** `7a82332`

**4. [Rule 3 - Blocking issue] `tests/ps1-contract.sh` abortava a suíte inteira na primeira perna comportamental com falha**
- **Found during:** Tarefa 3, ao investigar por que a suíde parava logo após `FAIL: pwsh_intact_catalog_succeeds` sem rodar as 6 pernas seguintes.
- **Issue:** Nove funções terminavam com o idioma `[ "$ok" -eq 1 ] && echo "OK: ..."`. Quando `ok=0`, essa expressão devolve status 1; por ser a ÚLTIMA instrução de uma função chamada NUA (sem `&&`/`||`) no fim do script, `set -e` encerrava o processo ali mesmo — pulando toda perna seguinte sem relatar nada, o oposto do que o cabeçalho do próprio arquivo documenta ("Never silent about a partial run"). Bloqueava diretamente o critério de aceite da Tarefa 3 (rodar `ps1-contract.sh` até o fim e ver o `FAIL=0` real).
- **Fix:** `return 0` explícito ao final de cada uma das 14 funções que usam esse idioma (9 confirmadas na tail idiom + pesquisa confirmou as demais já eram seguras via `if/else`).
- **Files modified:** `tests/ps1-contract.sh`
- **Commit:** `7a82332`

**5. [Rule 3 - Blocking issue] Três pernas de `tests/ps1-contract.sh` não toleravam a exceção D-10 (status non-zero esperado de `to-pdf.ps1` sem engine de PDF)**
- **Found during:** Tarefa 3, mesma investigação do item 4 — `pwsh_intact_catalog_succeeds`, `pwsh_output_has_no_bom` e `pwsh_accented_dir_survives` tratavam QUALQUER status non-zero de `to-pdf.ps1` como falha, sem saber que este host não tem `weasyprint` nem `wkhtmltopdf` (a MESMA tolerância que `tests/regress.sh` já aplicava desde a Tarefa 1).
- **Fix:** helper compartilhado `pdf_status_tolerated(status, md_path)`, usado pelas três pernas — status 0 OU (status non-zero E o fallback markdown existe) conta como sucesso. Além disso, `pwsh_accented_dir_survives` esperava um caminho ANINHADO (`features/autenticação/spec.txt`) para `to-dokuwiki.ps1` em vez do formato FLAT com `:` que o gêmeo realmente escreve (mesma convenção CHROME-04 do item 2) — corrigido para o caminho real.
- **Files modified:** `tests/ps1-contract.sh`
- **Commit:** `7a82332`

Nenhum desvio exigiu decisão do usuário (Regra 4) — todos os cinco itens acima são correções de bug ou de bloqueio direto do critério de aceite da própria tarefa, dentro do que o plano já autoriza explicitamente ("se alguma perna falhar, o defeito está nos gêmeos e não no harness — conserte no gêmeo").

## Verification

- `bash tests/regress.sh` (duas execuções consecutivas): `rc=0` nas duas, zero `FAIL:`, determinístico, `tests/fixtures/golden-sh/` byte-intocado contra `HEAD`.
- `bash tests/ps1-contract.sh`: 21/21 `OK:`, zero `FAIL:`, zero `SKIPPED:`, `rc=0`.
- `bash tests/fail-closed.sh`, `bash tests/no-mixed-output.sh`, `bash tests/no-calques.sh`, `bash tests/wiki-links.sh`: zero `FAIL:` em todos.
- `shellcheck tests/regress.sh tests/ps1-contract.sh`: limpo.
- `shfmt -d tests/regress.sh tests/ps1-contract.sh`: sem diff.
- Execução manual `pt-br` fora do harness: `mkdocs.yml` com `theme.language: pt-BR`, `index.md` com rótulos PT-BR e diretório acentuado intacto, livro PDF com título PT-BR (`# Especificações`, `*Gerado em 2026-09-30*`), README DokuWiki com 4 passos em PT-BR.
- Invariantes de bytes no `golden-ps1/`: zero BOM (verificado byte a byte em todos os 11 arquivos), acento intacto em `autenticação` (nome de diretório E de arquivo), `repo_url:` vazio no `mkdocs.yml` capturado (sem vazamento de URL de remoto, T-04-08).

## Known Stubs

Nenhum.

## Threat Flags

Nenhuma superfície nova introduzida fora do `<threat_model>` do plano — as correções desta tarefa (T-04-08-class no `generate-mkdocs.ps1`, ver Deviation 3) são FECHAMENTO de uma ameaça já catalogada (T-04-08), não abertura de superfície nova.

## Self-Check: PASSED

Arquivos confirmados no disco:
- FOUND: tests/fixtures/golden-ps1/mkdocs/docs/mkdocs.yml
- FOUND: tests/fixtures/golden-ps1/mkdocs/docs/index.md
- FOUND: tests/fixtures/golden-ps1/pdf/specs-book.md
- FOUND: tests/fixtures/golden-ps1/dokuwiki/README.md
- FOUND: scripts/to-pdf.ps1 (com ValueFromRemainingArguments)
- FOUND: scripts/to-dokuwiki.ps1 (com GetDirectoryName)
- FOUND: scripts/generate-mkdocs.ps1 (com Resolve-Path -Relative)
- FOUND: tests/ps1-contract.sh (com pdf_status_tolerated e return 0)
- FOUND: tests/fixtures/manifest.md (com pwsh 7.6.5 e SHA 7a82332)

Commits confirmados no log:
- FOUND: cf70afc (Tarefa 1, sessão anterior)
- FOUND: 7a82332 (Tarefa 3 — captura + correções)
- FOUND: 32f92fd (Tarefa 3 — SHA no manifesto)
