# Manifest — registro de captura dos golden fixtures

Date: 2026-09-29 · Status: accepted

Este registro torna a captura dos goldens reprodutível por um terceiro e o
diff de regressão confiável. O modo `capture` de `tests/regress.sh` é o
ÚNICO escritor dos goldens — editar golden à mão invalida o critério de
regressão silenciosamente e é proibido.

## Baseline da captura

- `pandoc --version`: pandoc 3.7.0.2 (versão do host WSL2 Ubuntu 24.04)
- `pwsh --version`: **PowerShell 7.6.5** — capturado na Tarefa 3 do plano
  `04-04`, host WSL2 Ubuntu 24.04, `pwsh` instalado via `snap install
  powershell --classic`. O interpretador é invocado com o perfil de
  usuário desabilitado (`pwsh -NoProfile -NonInteractive -File`) em toda
  chamada, para que a captura não dependa de configuração da máquina de
  quem captura. Em hosts Linux/WSL sem `pwsh` o harness termina exit 3
  (regime SKIPPED correto, não um defeito). Este host não tem engine de
  PDF (nem `weasyprint` nem `wkhtmltopdf`): a superfície PDF foi capturada
  sob a exceção D-10 (ver abaixo), como o lado `.sh` já era.
- Commit SHA da captura `.ps1` (golden-ps1/ adicionado, Tarefa 3 do plano
  `04-04`): `7a82332`
- Commit SHA da captura (golden-sh/dokuwiki adicionado): `3c81fe2`
- Commit SHA da captura inicial (goldens engine-less .sh): `f2faeb9`

**Três bugs pré-existentes nos gêmeos `.ps1`, achados pela primeira
execução real desta perna (Tarefa 3, plano `04-04`) e corrigidos nesta
mesma tarefa** — nenhum host anterior tinha `pwsh`, então nenhum destes
jamais tinha sido exercitado de verdade:

- **`to-pdf.ps1` — vazamento de argumentos posicionais.** O bloco `param()`
  declarava `[string[]]$Files` sem `ValueFromRemainingArguments`, e o
  binder posicional do PowerShell NÃO junta os argumentos restantes num
  parâmetro de array da forma que a pesquisa da fase assumiu (a hipótese
  de menor confiança de toda a `04-RESEARCH.md`, e a que se provou
  errada): sem o atributo, `$Files` recebia só o PRIMEIRO arquivo, e todo
  o resto silenciosamente caía em `$args` sem nenhum erro. Toda invocação
  multi-arquivo de `to-pdf.ps1` produzia um livro de UM arquivo só. Fix:
  `[Parameter(ValueFromRemainingArguments = $true)]` no parâmetro `$Files`.
- **`to-dokuwiki.ps1` — `Split-Path -Parent` vazio em page-id com `:`.**
  O separador de page-id do DokuWiki É o `:` (CHROME-04), e `Split-Path`
  interpreta um `:` no último segmento de um caminho RELATIVO como
  qualificador de unidade, devolvendo string vazia como diretório-pai e
  fazendo `New-Item` falhar (silenciosamente tolerado só porque o
  diretório-pai já existia via `$pagesDir`, mas imprimindo erro no
  console). Fix: `[System.IO.Path]::GetDirectoryName()` no lugar de
  `Split-Path -Parent`, que faz split de string puro sem semântica de
  drive — mesmo padrão que `dirname` no lado `.sh`.
- **`generate-mkdocs.ps1` — caminho absoluto do host vazando no nav do
  `mkdocs.yml`.** O mesmo bug de classe D-16 já corrigido em
  `generate-index.ps1` (plano `04-01`) nunca tinha sido replicado aqui: a
  regex `-replace '^.[/\\]', ''` nunca casa contra um caminho absoluto
  Unix (`/tmp/...`), então `$file.FullName` — sempre absoluto — vazava
  inteiro para dentro do nav. Corrigido com a MESMA abordagem de
  `Resolve-Path -Relative` + fallback de remoção de prefixo de `$cwd`.

**Dois bugs de robustez em `tests/ps1-contract.sh`, achados pelo mesmo
motivo** — o harness nunca tinha rodado uma perna comportamental real até
esta tarefa:

- **Aborto prematuro da suíte inteira sob `set -e`.** Nove das pernas
  comportamentais/estruturais terminavam com o idioma
  `[ "$ok" -eq 1 ] && echo "OK: ..."`; quando `ok=0`, essa expressão
  devolve status 1, e por ser a última instrução de uma função chamada
  nua no fim do script, `set -e` encerrava o processo ALI — pulando toda
  perna seguinte sem reportar, o oposto do que o cabeçalho do arquivo
  documenta ("Never silent about a partial run"). Fix: `return 0`
  explícito ao final de cada uma dessas funções.
- **`pwsh_intact_catalog_succeeds`, `pwsh_output_has_no_bom` e
  `pwsh_accented_dir_survives` não toleravam a exceção D-10** (status
  não-zero de `to-pdf.ps1` num host sem engine de PDF) — exatamente a
  situação deste host. Fix: helper compartilhado `pdf_status_tolerated`,
  espelhando a MESMA tolerância que `tests/regress.sh` já aplicava.
  `pwsh_accented_dir_survives` também esperava um caminho ANINHADO
  (`features/autenticação/spec.txt`) para `to-dokuwiki.ps1` em vez do
  formato FLAT com `:` que o gêmeo realmente escreve — corrigido para o
  caminho real.

**Perna DokuWiki version-pinned:** a saída do pandoc writer `dokuwiki` pode
variar entre versões. O golden `tests/fixtures/golden-sh/dokuwiki/` está
fixado na versão acima; uma atualização do pandoc pode exigir nova captura.

Exceção D-10 (IMPLEMENTADA nesta fase, não mais antecipada): o golden
`.ps1` da superfície PDF é `specs-book.md` — o que `to-pdf.ps1` produz sem
engine — porque o geminho não tem fallback markdown para o PDF publicável.
Num host sem engine de PDF, a perna `.ps1` de `tests/regress.sh` TOLERA DE
PROPÓSITO o status de saída diferente de zero da invocação de `to-pdf.ps1`
(`|| true` explícito, comentado no harness) e em seguida AFIRMA que
`specs-book.md` existe — se o arquivo não existir, isso É falha de
verdade, distinta da exceção esperada. É também onde vive o rodapé datado
(`*Generated on $date*`) que a máscara cobre.

## Pins da invocação canônica

| Pin | Valor | Por quê |
|-----|-------|---------|
| `PROJECT_NAME` | `TestProject` | Mesmo nome da captura validada na research; estável e sem espaço (atravessa heredoc e `site_name` sem quoting) |
| `AUDIENCE` | `general` | D-11: default do script e o ramo que exercita a tabela `\| Section \| Description \|` (chrome que o ramo `developer` não emite). A fixture original de `/tmp/mdw-sr3` foi capturada com `developer`; a réplica não herda essa escolha |
| `SOURCES` | `.specs` | Raiz da tree de specs, layout da taxonomia de fontes do `CONTEXT.md` |
| Locale | `LC_ALL=C.UTF-8` | Fixado pelo harness ANTES de qualquer perna, na captura E no diff: o sed de title-case da cadeia corrompe acentos em locale C (o `ç` de `autenticação` vira lixo) e a collation do `sort` do nav precisa ser estável entre captura e regressão |
| Cwd da captura | `WORK=$(mktemp -d)` | Fora de qualquer repositório git: `generate-mkdocs.sh` lê `git remote get-url origin`, e cwd dentro do repo vazaria a URL do origin para dentro do golden `mkdocs.yml`. Workdir fresco por execução (o espelho `docs/specs/` acumula órfãos se reusado) |
| Ordem dos arquivos do PDF | 7 argumentos EXPLÍCITOS, nesta ordem: `project/PROJECT.md`, `project/ROADMAP.md`, `codebase/ARCHITECTURE.md`, `features/login/spec.md`, `features/login/design.md`, `features/autenticação/spec.md`, `quick/fix-nav/spec.md` | Ordem da política de `agents/format-pdf.md`; args explícitos, nunca expansão de variável não citada (word splitting difere entre shells) |
| Env de override | nenhum exportado pelo harness | O harness nunca define override de caminho do index; o default `docs/index.md` é o caminho canônico da captura |

## Pins da invocação canônica da cadeia .ps1

A cadeia `.ps1` NÃO é estruturalmente igual à `.sh` (não-objetivos do plano
`04-03`), então os pins abaixo divergem em dois pontos que precisam ficar
registrados — sem isso a captura `.ps1` não é reprodutível por um terceiro.

| Pin | Valor | Por quê |
|-----|-------|---------|
| Interpretador | `pwsh -NoProfile -NonInteractive -File` | Perfil de usuário pode alterar default de encoding e de `ErrorActionPreference`; sem `-NoProfile` a captura depende da máquina de quem capturou |
| `PROJECT_NAME` / `AUDIENCE` / `SOURCES` | `TestProject` / `general` / `.specs` | Idênticos aos pins da cadeia `.sh` acima |
| Diretório-base de features do index | `.specs/features` | DIVERGE do pin `.sh` (`docs/specs/features`): `generate-mkdocs.ps1` não copia a árvore de specs para dentro de `docs/`, divergência estrutural preservada pelo D-19 |
| Superfície PDF | o arquivo `specs-book.md` produzido pelo script, e o status de saída diferente de zero do script é TOLERADO | Exceção D-10, implementada na Tarefa 1 do plano `04-04`: o gêmeo não tem fallback markdown para o PDF publicável, então num host sem engine ele grava o livro e encerra com erro. O livro é o golden; o erro é o comportamento correto e esperado nesse host. `tests/regress.sh` tolera o status com um `|| true` explícito e em seguida AFIRMA que o livro existe — se não existir, é falha de verdade |
| Cwd da captura | `mktemp -d` fora de qualquer repositório git | `generate-mkdocs.ps1` lê a URL do remoto `origin`; capturar dentro do repo vazaria essa URL para o golden (T-04-08) |
| Locale | `LC_ALL=C.UTF-8`, fixado pelo harness antes de qualquer perna | Mesmo motivo do lado `.sh`: estabilidade de collation e de tratamento de acento entre captura e diff |
| Máscara de data | a mesma regex ISO 8601 já usada pelo harness, aplicada simetricamente | Cobre o rodapé do index e o rodapé datado do livro do PDF, os dois sítios datados do lado `.ps1` já inventariados abaixo |

## Máscara de data

- Token: `__DATE__`
- Regex: `s/[0-9]{4}-[0-9]{2}-[0-9]{2}/__DATE__/g` (ISO 8601)
- Aplicação SIMÉTRICA: o golden é armazenado BRUTO (com a data da captura);
  no momento do diff, a mesma regex roda sobre cópias em tmp do golden E da
  saída fresca, e o `diff -r` compara as cópias mascaradas. Mascarar só um
  lado tornaria o resultado dependente do dia de execução.
- Sítios datados cobertos (todos os que existem — grep confirmado na
  research, nenhum outro sítio na cadeia):
  - `scripts/generate-index.sh:105` — rodapé `Generated by … — %s` com `$(date +%Y-%m-%d)`
  - `scripts/generate-index.ps1:84` — rodapé com `$(Get-Date -Format yyyy-MM-dd)`
  - `scripts/to-pdf.ps1:17,21` — `$date = Get-Date -Format "yyyy-MM-dd"` e o rodapé `*Generated on $date*`

## Invariantes da tree de fixture (`tests/fixtures/tree/.specs/`)

- Conteúdo 100% ASCII em todos os arquivos — o acento vive SOMENTE no nome
  do diretório `features/autenticação/` (canônico, D-05), que é o ponto da
  fixture e o mesmo nome do critério de corrupção de bytes da Phase 3
- Zero datas ISO no conteúdo — a máscara de data só pode tocar chrome,
  nunca conteúdo (qualquer data no conteúdo criaria falso
  positivo/negativo dependente de máscara)
- Fonte da verdade é conteúdo commitado (D-06) — a tree foi reconstruída a
  partir do inventário do `01-RESEARCH.md` quando a fixture volátil de
  `/tmp/mdw-sr3` não sobreviveu (Pitfall 10); aprovada pelo usuário como
  está na execução do plano 01-01

## Proibição de edição manual do golden

O modo `capture` é o único escritor. Nenhuma normalização à mão é
permitida — os warts de byte são comportamento atual a congelar:

- `repo_url:` com espaço em branco no fim da linha (variável vazia quando
  o cwd é git-free) no golden `mkdocs.yml`
- Linha em branco final do heredoc do `mkdocs.yml`
- Editores que removem espaço em branco à direita corrompem o golden
  silenciosamente; o diff é o guardião
- A proibição vale IGUALMENTE para `tests/fixtures/golden-ps1/`: o modo
  `capture` de `tests/regress.sh` é o único escritor também deste lado,
  nunca uma edição manual
- Decisão de encoding (D-15): toda saída `.ps1` é UTF-8 SEM BOM, nos dois
  idiomas — essa é a forma de bytes intencional do golden `.ps1`. Um golden
  que apareça com BOM é sinal de gravação por caminho errado (ex.
  `Out-File` em vez de `Write-Utf8NoBom`), nunca de normalização legítima

## Regime de execução parcial

O harness nunca falha em silêncio: perna que não pode rodar imprime uma
linha `SKIPPED:` com o motivo e o processo termina com exit code próprio
(3), distinto de falha de diff (1) e de sucesso pleno (0). `pwsh` e
`pandoc` são dependências somente de dev (D-03/D-09) — nunca exigidas em
runtime.
