# Phase 1: Contrato & Golden Fixtures - Research

**Researched:** 2026-09-28
**Domain:** Contrato de skill (variáveis de contexto) + fixtures de regressão byte-idêntica em bash/PowerShell sem engines
**Confidence:** HIGH (cadeia lida por inteiro, comportamentos verificados por execução neste host)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Já travado antes desta discussão (não reabrir):** `OUTPUT_LANG` com valores `en` | `pt-br`, default `pt-br`, token canônico minúsculo, atribuição exclusiva no onboarding, transmissão por dispatch prompt (PARAM-01); normalização `pt-br` ≡ `pt-BR` + tabela de projeção por consumidor (`pt-BR` Material/pandoc/HTML, `pt_BR` Pyphen) + fail-closed listando suportados (PARAM-02); formato/lugar do catálogo (`templates/lang/*.lang`, `KEY=value`, UTF-8 sem BOM — definido no stack do projeto, implementado na Phase 2); datas ISO 8601 nos dois idiomas; escopo Swagger = título + `lang` com limite upstream documentado; console dos scripts permanece em inglês.

- **D-01:** Golden fixtures cobrem as **5 superfícies publicáveis**: `index.md`, `mkdocs.yml` + `docs/` (nav), mirror DokuWiki, livro-PDF **no fallback markdown sem engine** (comportamento atual e determinístico do `to-pdf.sh`/`to-pdf.ps1` sem pandoc), e Swagger UI. Intermediários (`specs-book.md`, `merged-specs/`) ficam **de fora** — só saídas publicáveis.
- **D-02:** Swagger é congelado como **template + instância renderada**: o harness aplica a substituição dos `{{…}}` com valores da fixture via `sed` e diffa contra a instância golden — congela também o contrato de renderização atual que a Phase 3 vai traduzir.
- **D-03:** Instalar `pwsh` no host como dependência **somente de dev** (não runtime; o MET-1 conta custo por execução, não setup único) e capturar os goldens `.ps1` já na Phase 1. Baseline documentado: **PowerShell 7 no Linux** — a verificação PS 5.1 real continua como gap registrado no STATE.md (BOM/CRLF podem diferir entre 5.1 e 7).
- **D-04:** Harness sem `pwsh` no host: a perna `.ps1` é marcada `SKIPPED` com o motivo e o processo termina com **exit code próprio (ex.: 3)** — execução parcial é máquina-detectável, nunca silenciosa; `pwsh` não vira obrigação global para rodar a regressão.
- **D-05:** A tree de entrada é a **réplica da fixture validada `/tmp/mdw-sr3`** (nav 5 seções, links internos 100%) **+ `features/autenticação/`** como diretório acentuado — mesmo nome que a Phase 3 usará no critério de corrupção de bytes.
- **D-06:** A tree vive **commitada como arquivos `.md` reais** em `tests/fixtures/` — imutável, auditável, diff do golden revisável arquivo a arquivo; a fonte da verdade é conteúdo, não código gerador.
- **D-07:** Formato **chave → sítio**: cada linha usa a chave futura do catálogo (`site_name_suffix`, `nav_home`, `section_quick_start`, … — seed do glossário definida no stack do projeto) mapeada ao `arquivo:linha` atual. A Phase 2 extrai as strings `en` **verbatim** conferindo contra o inventário; o rubric audita o par en/pt-br completo contra o mesmo mapa.
- **D-08:** Casa: **`docs/chrome-inventory.md`** para o mapa; o contrato da skill (`CONTEXT.md`) recebe **somente as decisões de escopo** (política fail-closed de chave ausente, localização/formato do catálogo, escopo Swagger, datas ISO 8601) e aponta para o mapa — o contrato é lido por agents em runtime e permanece enxuto.

### Claude's Discretion

- Mecânica da máscara de data: token simétrico aplicado no golden e na saída fresca **antes** do diff, cobrindo os 3 sítios datados da cadeia (`scripts/generate-index.sh:105`, `scripts/generate-index.ps1:84`, `scripts/to-pdf.ps1:21`); token e sítios documentados no harness e no contrato da fase. Nota: `to-pdf.ps1` emite rodapé datado que o `to-pdf.sh` não emite — divergência entre gêmeos que os goldens por geminho capturam como estão (wart atual preservado).
- Layout interno de `tests/` (harness em `tests/regress.sh` — nome que a Phase 4 referencia — + `tests/fixtures/` com a tree e os goldens `.sh`/`.ps1` separados por geminho).
- Invocação canônica dos scripts na captura (args, cwd, ordem de execução por superfície).
- Redação exata da seção de decisões de escopo no contrato da skill e da pergunta `OUTPUT_LANG` no onboarding (seguir o padrão AUDIENCE: tokens canônicos + descrição por valor; default `pt-br` registrado quando o usuário manifesta indiferença).

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PARAM-01 | `OUTPUT_LANG` é o único parâmetro de idioma (`en` \| `pt-br`, default `pt-br`), atribuído no onboarding e transmitido por dispatch prompt — como `AUDIENCE`, nunca env var | Padrão `AUDIENCE` mapeado com âncoras exatas (`agents/onboarding.md:9-12` pergunta, `:47` lista de retorno; `CONTEXT.md:9-18` tabela Variables, `:7` regra de transmissão). Nenhum env var de idioma existe hoje; único env var da cadeia é `MDW_INDEX_OUT` (`generate-index.sh:19`), pré-existente e fora do escopo |
| PARAM-02 | Locale normalizado na entrada (`pt-br` ≡ `pt-BR`) e projetado por consumidor; valor desconhecido interrompe com erro listando os suportados | Decisão já travada; research confirma as formas canônicas por consumidor e o padrão fail-closed existente (`to-dokuwiki.sh:11-12` — erro nomeando o problema + como resolver). Contrato registra; enforcement nas scripts é Phase 2+ |
| QUAL-02 | Golden fixtures `en` congelados por geminho (.sh/.ps1) + harness de diff sem engines; `OUTPUT_LANG=en` reproduz a saída atual byte-idêntica (token de data mascarado e documentado) | Fixture `/tmp/mdw-sr3` existe e foi inventariada (14 arquivos); cadeia executada 2× neste host — byte-idêntica após máscara de data; 3 sítios datados confirmados verbatim; armadilhas de locale/cwd/git-remote/BOM catalogadas com evidência |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Diretivas acionáveis extraídas de `.claude/CLAUDE.md` que o planner deve honrar:

- **Compatibilidade:** saída com `OUTPUT_LANG=en` byte-idêntica à atual — os goldens desta fase SÃO esse critério congelado
- **Metodologia MET-1:** toda mudança pesa custo permanente por execução vs ganho de previsibilidade; sem portar padrões sem necessidade demonstrada
- **Stack:** bash + markdown; **nenhuma dependência nova de runtime** — `pwsh`/`pandoc` nesta fase são dependências **de dev** (D-03), nunca exigidas pelo harness em runtime
- **Idioma:** docs e saída em PT-BR sem calques ("deployar", "printar", "commitar"); termo técnico fica em inglês integral ou usa equivalente consagrado; glossário canônico manda
- **Git:** todo o trabalho no branch `ft/gsd-pattern-align`
- **Rubric:** todo arquivo de skill tocado (`CONTEXT.md`, `agents/onboarding.md`) passa por auditoria delta com `docs/skill-quality-rubric.md`
- **Encoding:** UTF-8 sem BOM nos artefatos bash; nunca capitalizar label via `sed '\u'` em chrome (ver Pitfall 1 — corrompido por execução neste host)
- **GSD Workflow Enforcement:** mudanças via comandos GSD (esta fase entra por `/gsd-execute-phase`)

## Summary

A fase é executável neste host **como está**, com duas decisões de planejamento pendentes e uma dependência de instalação. A fixture validada `/tmp/mdw-sr3` **existe** (14 arquivos: 6 specs-fonte em `.specs/`, mirror em `docs/specs/`, `docs/index.md` e `mkdocs.yml` de uma captura anterior com `AUDIENCE=developer`) — a réplica para `tests/fixtures/` é direta e deve acrescentar `features/autenticação/spec.md`. A cadeia `.sh` atual é **determinística run-to-run** — verificada por execução dupla neste host com `LC_ALL=C.UTF-8` e máscara de data: diff vazio. Os 3 sítios datados confirmam verbatim as âncoras do CONTEXT.md (`generate-index.sh:105`, `generate-index.ps1:84`, `to-pdf.ps1:17,21`) e **nenhum outro sítio de data existe** (grep em todos os scripts; conteúdo da fixture é 100% ASCII sem datas ISO — a máscara só toca chrome).

Porém, a realidade engine-less do host cria **duas assimetrias que o plano precisa endereçar**: (1) `to-dokuwiki.sh`/`.ps1` fazem `exit 1` sem pandoc — **não existe fallback** para a superfície DokuWiki, logo o golden dessa superfície exige pandoc instalado como dependência de dev (candidato apt: 3.1.3) sob o mesmo regime D-03/D-04 do pwsh (SKIPPED + exit 3 quando ausente); (2) `to-pdf.ps1` **não tem fallback markdown** (`exit 1` sem engines, linha 60-64) — o único artefato engine-less da perna `.ps1` é `specs-book.md`, nominalmente um intermediário que D-01 exclui; a captura desse geminho precisa de uma exceção explícita e documentada (o rodapé datado que o CONTEXT.md quer congelar vive exatamente ali). Os gêmeos `.ps1` divergem substancialmente dos `.sh` (path de saída `docs/mkdocs.yml` vs raiz, nav não-recursivo, links quebrados por `Split-Path -NoQualifier` no Linux, URL `opencode.ai` no rodapé) — divergências que a captura por geminho congela como estão, exatamente como D-01 determina.

A descoberta de maior alcance para o harness: **o locale do host muda bytes da saída atual**. O sed de title-case (`sed 's/-/ /g; s/\b\(.\)/\u\1/g'`, `generate-index.sh:79`, `generate-mkdocs.sh:29,35`) corrompe `autenticação` em `LC_ALL=C` (byte `c3`→`ff` + `O` final maiúsculo — reproduzido) e sai limpo em locale UTF-8. Logo, captura e diff **precisam pinar `LC_ALL=C.UTF-8`** (presente neste host, portável entre GNU/Linux, e também fixa a collation do `sort` que ordena nav e listas). Igualmente crítico: o cwd de captura **precisa estar fora de qualquer repositório git** — este repo tem `origin`, e `generate-mkdocs.sh:18` vazaria a URL SSH para dentro do `mkdocs.yml` golden.

**Primary recommendation:** Estruturar a fase em 4 blocos sequenciais — (1) contrato (`CONTEXT.md` + `onboarding.md` + decisões de escopo D-08), (2) réplica da tree + inventário de chrome com âncoras arquivo:linha, (3) instalação dev-only de pwsh (+pandoc, decisão pendente) e captura dos goldens por geminho com locale/cwd/argv pinados e manifest documentado, (4) harness `tests/regress.sh` com máscara simétrica de data e regime SKIPPED exit 3.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Parametrização `OUTPUT_LANG` (valores, default, atribuição) | Contrato (`CONTEXT.md` §Variables + `agents/onboarding.md`) | Dispatch prompts dos `agents/format-*.md` (mesma transmissão de `AUDIENCE`) | O contrato é a casa única: variáveis vivem no `CONTEXT.md`, o onboarding é o único ponto de atribuição — padrão estabelecido do projeto |
| Normalização de locale + projeção por consumidor | Contrato (decisão declarada) | Cadeia de scripts (enforcement na Phase 2+) | Phase 1 só registra a decisão; nenhum script consumidor existe ainda |
| Captura dos goldens `.sh` | Harness (`tests/regress.sh` modo captura) | Cadeia `.sh` atual não modificada | O golden congela a cadeia como está; o harness é o instrumento |
| Captura dos goldens `.ps1` | Harness + `pwsh` dev-only (D-03) | — | Baseline PS7/Linux documentado; PS 5.1 é gap conhecido |
| Captura do golden DokuWiki | Harness + `pandoc` dev-only (decisão pendente) | — | `to-dokuwiki.*` não tem fallback; sem pandoc a perna não produz bytes |
| Dif de regressão engine-less | Harness (`diff -r`/`cmp` + máscara) | — | Critério 4 do roadmap: roda em host sem mkdocs/pandoc |
| Inventário de chrome | `docs/chrome-inventory.md` (novo artefato de dados) | Contrato aponta para o mapa (D-08) | Contrato fica enxuto; o mapa é referência de implementação da Phase 2 |
| Chrome em prosa de agent (GitHub Wiki, openapi.yml) | Camada 4 (`agents/format-*.md`) | — | Não é capturável por golden (autoria de LLM em runtime); só inventário |

## Standard Stack

Nenhuma biblioteca nova — a fase é bash + coreutils + markdown (constraint de stack). O "stack" aqui é o toolchain do harness e as dependências de dev.

### Core (toolchain do harness)

| Tool | Versão (host) | Papel | Por quê |
|------|---------------|-------|---------|
| GNU bash | 5.2.21 | Runtime do harness e da cadeia `.sh` | Já é o runtime da skill; `tests/regress.sh` roda sob `#!/usr/bin/env bash` — invocar explicitamente com `bash` (ver Pitfall 3: zsh não faz word-split) |
| GNU diff / cmp | 3.10 | Dif byte-exato (`diff -r` para trees, `cmp` para arquivo único) | Ferramenta canônica do critério 4; sem dependência externa |
| GNU sed | 4.9 | Máscara de data + render Swagger (D-02) | Já usado pela cadeia; regex `[0-9]{4}-[0-9]{2}-[0-9]{2}` cobre os 3 sítios ISO 8601 |
| `mktemp -d` | coreutils | Workdir isolado por perna | Única maneira confiável de garantir cwd fora do repo git (Pitfall 2) e tree limpa por execução (Pitfall 5) |
| `locale C.UTF-8` | glibc (presente como `C.utf8`) | Pin de locale para captura e diff | Determinismo do title-case sed e da collation (Pitfall 1) |

### Dev-only (instalação, não runtime — regime D-03)

| Tool | Estado no host | Papel | Instalação |
|------|----------------|-------|------------|
| `pwsh` (PowerShell 7) | **AUSENTE** | Captura dos goldens `.ps1` | [CITED: learn.microsoft.com/powershell/scripting/install/install-ubuntu] Ubuntu 24.04 suportado até 2029-05-31; preferido: repo PMC (`wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb` + `sudo dpkg -i` + `sudo apt-get install -y powershell`); alternativa: `.deb` universal do GitHub releases (7.6.6 LTS na doc de 2026-08-11); tar.gz binário documentado em install-other-linux#binary-archives (não exige sudo). Snap existe mas **não** é método suportado pela Microsoft. **sudo exige senha neste host → passo com o usuário** |
| `pandoc` | **AUSENTE** (candidato apt `3.1.3+ds-2`) | Captura do golden DokuWiki (perna `.sh` e `.ps1`) | `sudo apt install pandoc` — decisão pendente (ver Open Questions Q1) |

### Alternatives Considered

| Em vez de | Alternativa | Quando faria sentido |
|-----------|-------------|----------------------|
| `diff -r` + `cmp` | sha256sum por arquivo | `cmp`/`diff` dão o arquivo e a linha da divergência de graça; sha256 só diz "diferente" — diff é a ferramenta de debug durante a Phase 2 |
| Máscara `sed` no diff | `faketime` / `libfaketime` para congelar o relógio | Dependência nova + LD_PRELOAD frágil; a máscara simétrica é 1 linha de sed e cobre exatamente os 3 sítios conhecidos |
| Tree commitada como `.md` reais (D-06) | Script gerador da tree | Explicitamente rejeitado pelo D-06 — fonte da verdade é conteúdo |
| `tests/regress.sh` em bash | pytest/bats | Constraint de stack (bash + markdown); bats seria dependência nova sem ganho |

**Installation (dev-only, com o usuário):**
```bash
# pwsh (PowerShell 7) — método preferido (repo Microsoft)
wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get install -y powershell
# pandoc (se Q1 aprovada)
sudo apt install pandoc
```

**Version verification:** bash 5.2.21, sed 4.9, diff/cmp 3.10, git 2.43.0, node v20.19.6, jq 1.x — todos verificados por execução neste host em 2026-09-28. `pwsh` e `pandoc` ausentes; versões candidatas verificadas via `apt-cache policy`.

## Package Legitimacy Audit

**Nenhum pacote de registro (npm/PyPI/crates) é instalado nesta fase** — o projeto não tem `package.json`/`requirements.txt` e a constraint de stack veda dependência nova de runtime. As duas instalações são pacotes de sistema (apt), verificadas por canal oficial:

| Package | Registry/Canal | Idade | Verdict | Disposition |
|---------|----------------|-------|---------|-------------|
| `powershell` (7.6.x) | Microsoft PMC / GitHub releases (PowerShell/PowerShell) | projeto maduro, LTS vigente | OK (doc oficial Microsoft Learn verificada) | Approved — dev-only, passo sudo com o usuário |
| `pandoc` (3.1.3+ds-2) | Ubuntu noble archive (jgm/pandoc upstream) | projeto maduro | OK (candidato do archive oficial Ubuntu) | Approved — dev-only, pendente decisão Q1 |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
                    tests/fixtures/ (commitado, imutável — D-06)
                    ┌─────────────────────────────────────────────┐
                    │ tree/  = réplica de /tmp/mdw-sr3/.specs      │
                    │         + features/autenticação/spec.md      │
                    │ golden-sh/  golden-ps1/  (goldens en)       │
                    │ manifest.md (comando canônico, locale, …)   │
                    └──────────────────┬──────────────────────────┘
                                       │ cp -r
                                       ▼
              tests/regress.sh ──► WORK=$(mktemp -d)   [fora do repo git!]
              (LC_ALL=C.UTF-8)         │
                                       ▼
                    ┌──────────────────────────────────────────┐
                    │ perna .sh (sem engines):                 │
                    │  generate-mkdocs.sh ─► mkdocs.yml        │
                    │  generate-index.sh  ─► docs/index.md     │
                    │  to-pdf.sh (fallback) ─► specs-book.pdf  │
                    │  sed render      ─► swagger-ui/index.html│
                    │  [pandoc?] to-dokuwiki.sh ─► README+pages│
                    │                                          │
                    │ perna .ps1 (pwsh? senão SKIPPED):        │
                    │  idem por geminho — saídas divergentes   │
                    │  são goldens PRÓPRIOS por geminho        │
                    └──────────────────┬───────────────────────┘
                                       │ saída fresca
                                       ▼
                    máscara simétrica: sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}/__DATE__/g'
                    aplicada ao golden E à saída fresca (cópias em tmp)
                                       │
                                       ▼
                    diff -r golden-mascarado vs fresco-mascarado
                                       │
              ┌────────────────────────┼─────────────────────────┐
              ▼                        ▼                         ▼
        exit 0 (tudo verde)     exit 1 (diff falhou)      exit 3 (perna(s) SKIPPED
                                                         com motivo impresso — D-04)
```

O fluxo primário (critério 4 do roadmap) é rastreável da tree commitada até o exit code sem tocar engines: mkdocs nunca roda (golden é config+conteúdo, ADR-0003), pandoc só na perna DokuWiki (regime SKIPPED quando ausente).

### Recommended Project Structure

```text
tests/
├── regress.sh                  # harness: captura (modo --capture) + regressão (default)
└── fixtures/
    ├── tree/                   # réplica .specs de /tmp/mdw-sr3 + features/autenticação/spec.md (D-05/D-06)
    ├── manifest.md             # invocação canônica por superfície, PROJECT_NAME, AUDIENCE,
    │                           #   locale pin, ordem de arquivos, mask token, versões pwsh/pandoc, SHA do commit de captura
    ├── golden-sh/              # 5 superfícies da cadeia .sh
    │   ├── mkdocs/             #   mkdocs.yml + docs/specs/** + docs/index.md
    │   ├── pdf/                #   specs-book.pdf (fallback markdown — cópia byte do book)
    │   ├── dokuwiki/           #   README.md (+ data/pages/** se Q1 aprovada)
    │   └── swagger/            #   index.html renderado (D-02)
    └── golden-ps1/             # mesmas superfícies, geminho .ps1 (capturado sob pwsh 7)
        ├── mkdocs/             #   docs/mkdocs.yml (path divergente do .sh — congela como está)
        ├── pdf/                #   specs-book.md (exceção D-01 — ver Q2)
        ├── dokuwiki/
        └── swagger/            #   render idêntico ao .sh (mesmo template)
docs/
└── chrome-inventory.md         # mapa chave → arquivo:linha (D-07/D-08)
```

### Pattern 1: Captura por geminho, golden por superfície

**What:** cada geminho (`.sh` e `.ps1`) tem seu conjunto próprio de goldens por superfície; nunca um golden "combinado".
**When to use:** sempre — os gêmeos divergem hoje (e divergirão até a Phase 4 convergi-los por construção).

Divergências verificadas por leitura nesta sessão (todas congeladas como estão):

| Aspecto | `.sh` | `.ps1` | Âncora |
|---------|-------|--------|--------|
| Path do mkdocs.yml | raiz do projeto | `docs/mkdocs.yml` | [VERIFIED: scripts/generate-mkdocs.sh:42] `cat > mkdocs.yml <<YAML` vs [VERIFIED: scripts/generate-mkdocs.ps1:61] `"@ | Out-File -FilePath "docs/mkdocs.yml" -Encoding utf8` |
| Descoberta de nav | recursiva (`find … | sort`) | só `*.md` do topo (Features/Quick somem) | [VERIFIED: scripts/generate-mkdocs.sh:30] `files=$(find "$dir" -name '*.md' ! -name '_*' | sort)` vs [VERIFIED: scripts/generate-mkdocs.ps1:25] `$mdFiles = Get-ChildItem $dir -Filter "*.md"` |
| Células da tabela Features | `[Spec](…)`/`[Design](…)`/`[Tasks](…)` ou `—` se ausente | `[$name]($spec)` em todas — label = nome do diretório, sem checagem de existência | [VERIFIED: scripts/generate-index.sh:27-29,80-84] vs [VERIFIED: scripts/generate-index.ps1:58] `$content += "`n| $name | [$name]($spec) | [$name]($design) | [$name]($tasks) |"` |
| URL do rodapé | `https://github.com/abertanha/md-to-wiki-docs-skills` | `https://opencode.ai` | [VERIFIED: scripts/generate-index.sh:105] vs [VERIFIED: scripts/generate-index.ps1:84] `*Generated by [md-to-wiki](https://opencode.ai) — $(Get-Date -Format yyyy-MM-dd)*` |
| Rodapé datado no PDF | não emite | `*Generated on $date*` | [VERIFIED: scripts/to-pdf.ps1:21] `*Generated on $date*` |
| Separadores do livro | `---` por arquivo | `\newpage` por arquivo | [VERIFIED: scripts/to-pdf.sh:22] `echo "---"` vs [VERIFIED: scripts/to-pdf.ps1:30] ``$content += "`n`n\newpage`n`n"`` |
| Headings por arquivo no livro | `## $(basename "$file" .md)` | não emite | [VERIFIED: scripts/to-pdf.sh:18] vs to-pdf.ps1:27-31 |
| Fallback sem engines | `cp "$BOOK" "$OUTPUT"` (markdown book) | `exit 1` — sem fallback | [VERIFIED: scripts/to-pdf.sh:44-47] `else cp "$BOOK" "$OUTPUT"; echo "WARNING: pandoc not found. Outputting markdown book as $OUTPUT"` vs [VERIFIED: scripts/to-pdf.ps1:60-63] `if (-not $found) { … exit 1 }` |
| Invocação | posicional | `to-pdf.ps1` usa params nomeados (`-Output`, `-Files`) | [VERIFIED: scripts/to-pdf.ps1:1-4] `param( [string]$Output, [string[]]$Files )` |

### Pattern 2: Máscara simétrica antes do diff

**What:** o golden é armazenado **bruto** (com a data da captura); no momento do diff, o mesmo `sed` de máscara roda sobre o golden e sobre a saída fresca, e o diff compara as cópias mascaradas.
**When to use:** todo diff que envolva `docs/index.md` (qualquer geminho) e o livro `.ps1`.
**Why simétrica:** mascarar só a saída fresca tornaria o golden dependente da data de captura; mascarar ambos torna o diff invariante a qualquer dia de execução.

```bash
# Source: padrão derivado desta research (discretion do CONTEXT.md — mecanismo da máscara)
MASK='s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/__DATE__/g'
sed "$MASK" golden/docs/index.md  > "$TMP/g.md"
sed "$MASK" fresh/docs/index.md   > "$TMP/f.md"
cmp -s "$TMP/g.md" "$TMP/f.md" || fail "index.md divergiu"
```

A regex cobre os 3 sítios porque todos emitem ISO 8601: [VERIFIED: scripts/generate-index.sh:105] `"$(date +%Y-%m-%d)"`; [VERIFIED: scripts/generate-index.ps1:84] `$(Get-Date -Format yyyy-MM-dd)`; [VERIFIED: scripts/to-pdf.ps1:17] `$date = Get-Date -Format "yyyy-MM-dd"`. Grep em todos os scripts confirma: **nenhum outro sítio de data**. O conteúdo da fixture não contém datas ISO (verificado por grep em `/tmp/mdw-sr3/.specs/`), logo a máscara só toca chrome — manter a fixture sem datas é um invariante a registrar no manifest.

### Pattern 3: Regime SKIPPED com exit code próprio (D-04)

```bash
# Source: D-04 do CONTEXT.md; exit 3 está livre na cadeia (grep: scripts usam só exit 0/1)
SKIP=0
if command -v pwsh >/dev/null 2>&1; then
  capture_ps1_legs || fail "perna .ps1 falhou"
else
  echo "SKIPPED: pwsh not found on host (dev-only dep; see manifest)"
  SKIP=1
fi
# …diffs…
[ "$SKIP" -eq 1 ] && exit 3
exit 0
```

Exit codes atuais da cadeia (verificados por grep — `exit 0`/`exit 1` apenas, ex.: `to-dokuwiki.sh:12`, `to-pdf.ps1:63`, `discover-sources.sh:11`): **exit 3 está livre** para a convenção SKIPPED, sem colisão com erro de diff (exit 1 do harness) — parcial é distinguível de falha.

### Pattern 4: Invocação canônica pinada por superfície (discretion)

Invocação derivada dos próprios agents (a cadeia roda como o fluxo real manda), validada por execução neste host:

```bash
# Source: agents/format-mkdocs.md:26,34 + agents/format-pdf.md:20,28 + agents/format-swagger.md:69-70
WORK=$(mktemp -d)                     # FORA do repo git (Pitfall 2)
cp -r tests/fixtures/tree/. "$WORK/"
cd "$WORK" && export LC_ALL=C.UTF-8   # Pitfall 1
bash "$SKILL_DIR/scripts/generate-mkdocs.sh" TestProject .specs
bash "$SKILL_DIR/scripts/generate-index.sh"  TestProject general docs/specs/features
bash "$SKILL_DIR/scripts/to-pdf.sh" specs-book.pdf \
  .specs/project/PROJECT.md .specs/project/ROADMAP.md \
  .specs/codebase/ARCHITECTURE.md \
  .specs/features/login/spec.md .specs/features/login/design.md \
  .specs/features/autenticação/spec.md \
  .specs/quick/fix-nav/spec.md        # ordem da política de format-pdf.md:20, args EXPLÍCITOS (Pitfall 3)
mkdir -p swagger-ui
sed -e 's/{{PROJECT_NAME}}/TestProject/g' -e 's|{{OPENAPI_YML}}|openapi.yml|g' \
  "$SKILL_DIR/templates/swagger-ui.html" > swagger-ui/index.html   # D-02
```

Recomendações de pin (todas discretion, todas a registrar no `manifest.md`):
- `PROJECT_NAME=TestProject` — mesmo nome da captura validada de `/tmp/mdw-sr3` (verificado: `site_name: TestProject — Specifications` no `mkdocs.yml` da fixture)
- `AUDIENCE=general` — é o default do script ([VERIFIED: scripts/generate-index.sh:8] `AUDIENCE="${2:-general}"`) e exercita o ramo da tabela `| Section | Description |` (chrome que o ramo `developer` não emite). Nota: a captura original da fixture usou `developer` (verificado pela presença de `## Quick Start`, emitido só pelo ramo developer em `generate-index.sh:45`) — a réplica não herda essa escolha; o manifest decide e documenta
- Lista de arquivos do PDF: args explícitos na ordem de `format-pdf.md:20` (`project/*.md → codebase/*.md → features/<name>/spec.md,design.md,tasks.md → quick/<name>/*.md`) — nunca expansão de variável não citada (Pitfall 3) e nunca saída de `discover-sources.sh` formato `files` sem pós-ordenação (o ramo `files` não ordena dentro de cada feature dir — [VERIFIED: scripts/discover-sources.sh:24-26] `find "$fd" -maxdepth 1 -name "*.md"` sem `| sort`, ao contrário do ramo `json` que ordena na linha 57)

### Anti-Patterns to Avoid

- **Golden "normalizado" à mão:** qualquer edição manual do golden após a captura (tirar espaço, acertar linha final) invalida o contrato — o golden é a cadeia como está, warts incluídos
- **Um golden só para os dois geminhos:** os gêmeos divergem por construção hoje; golden único esconderia exatamente as divergências que a Phase 4 precisa convergir
- **Capturar com cwd dentro do repo:** vaza `repo_url` para o golden (Pitfall 2)
- **Rodar o harness sob zsh:** quebra a expansão da lista de arquivos (Pitfall 3)
- **Máscara aplicada só de um lado:** falso negativo/positivo dependente da data

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Comparação de trees | Loop por arquivo com `read`/comparadores custom | `diff -r` (+ `cmp` por arquivo) | `diff -r` já reporta arquivo+linha da divergência; é o critério 4 literal |
| Isolamento de execução | Cd manual + `rm -rf` de diretórios fixos | `mktemp -d` | Sujo = nunca; fora do repo git = garantido |
| Congelar relógio | Wrappers com `date` fake / `faketime` | Máscara simétrica de 1 linha nos 3 sítios conhecidos | `faketime` = dependência + LD_PRELOAD; os sítios são 3 e conhecidos por grep |
| Tree de teste | Script gerador da fixture | Arquivos `.md` reais commitados (D-06) | Decisão travada; gerador reintroduz o problema que D-06 elimina |
| Detecção de engines no harness | Lógica própria de versão/mínimo | `command -v` binário (o mesmo gate dos scripts: `to-dokuwiki.sh:10`, `to-pdf.ps1:39`) | O harness só decide roda-vs-SKIPPED; a cadeia continua dona dos próprios gates |
| Parse de mkdocs.yml para validar nav | Parser YAML em bash | Dif byte-exato do golden | O golden É a validação estrutural (ADR-0003: gates estruturais no interim) |

**Key insight:** o valor desta fase é que o golden substitui qualquer verificação semântica — não se valida YAML, não se valida nav, compara-se bytes. Qualquer lógica de validação custom é custo permanente sem ganho de previsibilidade (reprova no MET-1).

## Common Pitfalls

### Pitfall 1: Locale do host muda bytes da saída (title-case sed corrompe acento)

**What goes wrong:** o sed que deriva labels de nomes de diretório — [VERIFIED: scripts/generate-index.sh:79 / scripts/generate-mkdocs.sh:29,35] `sed 's/-/ /g; s/\b\(.\)/\u\1/g'` — trata bytes individualmente em locale C: o `ç` (bytes `c3 a7`) de `autenticação` vira lixo.
**Why it happens:** em `LC_ALL=C`, `\b` dispara antes do byte `c3` (não-word) e `\u` o transforma; a sílaba final ganha maiúscula espúria.
**How to avoid:** pinar `LC_ALL=C.UTF-8` na captura E no diff (existe neste host como `C.utf8`; portável entre GNU/Linux; também fixa a collation do `sort` que ordena nav e listas de arquivos).
**Warning signs:** golden com bytes `ff a7` ou `O` maiúsculo final em `Autenticação`.
**Evidência (execução neste host, 2026-09-28):**

```text
$ echo "autenticação" | LC_ALL=C      sed 's/-/ /g; s/\b\(.\)/\u\1/g' | xxd
  4175 7465 6e74 6963 61ff a7c3 a34f 0a   ← "Autentica" + ç CORROMPIDO (c3→ff) + "ãO" (O espúrio)
$ echo "autenticação" | LC_ALL=C.UTF-8 sed 's/-/ /g; s/\b\(.\)/\u\1/g' | xxd
  4175 7465 6e74 6963 61c3 a7c3 a36f 0a   ← "Autenticação" limpo (bytes UTF-8 corretos)
```

Contraste no geminho: [VERIFIED: scripts/generate-mkdocs.ps1:23] `-replace '\b\w', { $_.Value.ToUpper() }` — regex .NET trata `ç` como word char Unicode e `ToUpper()` é Unicode-aware, então o `.ps1` **não corrompe** o mesmo label (e tampouco precisa de locale). Congela-se por geminho, como está. Nota do STATE.md confirmada: "Sed em locale C corrompe acentos neste host (reproduzido 2026-09-28)".

### Pitfall 2: `repo_url` vaza do git do cwd para o golden

**What goes wrong:** [VERIFIED: scripts/generate-mkdocs.sh:17-19] `repo_url=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' || echo "")` — o git procura `.git` subindo a árvore de diretórios. Este repo **tem** `origin` (`git@github.com:abertanha/md-to-wiki-docs-skills.git`, verificado): capturar com cwd dentro do worktree grava `repo_url: git@github.com:abertanha/md-to-wiki-docs-skills` no golden, e qualquer execução futura em cwd git-free difere.
**How to avoid:** workdir sempre `mktemp -d` (fora do repo). Evidência de que é o comportamento da fixture validada: `/tmp/mdw-sr3/mkdocs.yml` linha 3 tem `repo_url: ` vazio (capturado em cwd sem git).
**Warning signs:** golden com URL SSH do skill-repo dentro do mkdocs.yml.
**Bônus:** a linha `repo_url: $repo_url` com variável vazia produz **espaço em branco no fim da linha** (`repo_url: `) e o heredoc termina com **linha em branco** (verificado no hexdump da fixture: `... 6d64 0a0a`). Editores que strippam trailing whitespace corrompem o golden silenciosamente — o manifest deve proibir edição manual e o diff é o guardião.

### Pitfall 3: zsh não faz word-split — lista de arquivos vira um argumento só

**What goes wrong:** `$SCRIPT to-pdf.sh out.pdf $FILES` sem aspas sob zsh passa a string multiline inteira como **um** argumento (verificado neste host: o WARNING do to-pdf nomeou um "arquivo" com 7 paths embutidos). Sob bash, o mesmo código separa.
**Why it happens:** `SH_WORD_SPLIT` é off por default no zsh.
**How to avoid:** harness roda sob `#!/usr/bin/env bash`, e a lista de arquivos do PDF é **args explícitos** (Pattern 4) ou array bash (`files=(...); "${files[@]}"`).
**Warning signs:** WARNING de "arquivo não encontrado" nomeando múltiplos paths.

### Pitfall 4: `cp -r` acumula estado entre execuções

**What goes wrong:** `generate-mkdocs.sh` copia `.specs/` para dentro de `docs/specs/` sem limpar ([VERIFIED: scripts/generate-mkdocs.sh:13] `cp -r "$SPECS_DIR"/. "$SITE_DOCS/specs"/`); re-rodar sobre workdir usado deixa arquivos órfãos de runs anteriores e o `diff -r` da tree inteira falha.
**How to avoid:** workdir fresco por execução de perna (`mktemp -d` + `cp -r` da tree commitada). Nunca re-rodar in-place.

### Pitfall 5: BOM e CRLF — a superfície onde os gêmeos mentem

**What goes wrong:** todo `.ps1` grava via `Out-File -Encoding utf8` ([VERIFIED: scripts/generate-index.ps1:87, generate-mkdocs.ps1:61, to-pdf.ps1:33, to-dokuwiki.ps1:45]). Em PS 5.1 isso grava UTF-8 **com BOM** e CRLF; em PS 7 no Linux, UTF-8 **sem BOM** e LF.
**How to avoid:** baseline é PS7/Linux (D-03) — golden `.ps1` capturado sem BOM, LF. A diferença 5.1 é gap registrado no STATE.md, não bloqueio; o manifest declara o baseline.
**Warning signs:** golden `.ps1` começando com `ef bb bf` ou contendo `0d 0a`.
**Estado atual verificado:** nenhum script/template do repo tem BOM ou CRLF hoje (hexdump dos primeiros bytes + grep de `\r`).

### Pitfall 6: DokuWiki não tem fallback — perna engine-dependente

**What goes wrong:** [VERIFIED: scripts/to-dokuwiki.sh:10-13] `if ! command -v pandoc &>/dev/null; then echo "ERROR: pandoc not found. Install it: sudo apt install pandoc"; exit 1; fi` — o gate vem **antes** da escrita do README; sem pandoc a perna produz só um `data/pages/` vazio e `exit 1`. O `.ps1` idem ([VERIFIED: scripts/to-dokuwiki.ps1:13-17]).
**How to avoid:** decisão Q1 — pandoc como dev-dep (regime D-03) para a captura; no harness, `command -v pandoc` → roda ou SKIPPED (exit 3).
**Warning signs:** golden DokuWiki inexistente ou perna sempre SKIPPED.

### Pitfall 7: `to-pdf.ps1` não tem fallback markdown — o golden `.ps1` da superfície PDF vem do intermediário

**What goes wrong:** sem engines, [VERIFIED: scripts/to-pdf.ps1:60-64] `if (-not $found) { Write-Output "ERROR: Neither weasyprint nor wkhtmltopdf found."; …; exit 1 }` — o `$Output` (o "publicável") **nunca é criado**. O único artefato engine-less é `specs-book.md` (linha 33), que D-01 exclui como intermediário.
**How to avoid:** decisão Q2 — capturar `specs-book.md` como golden da perna `.ps1` da superfície PDF, com a exceção documentada no manifest (é o único lugar onde o rodapé datado que o CONTEXT.md manda congelar existe).
**Warning signs:** golden `.ps1` de PDF com conteúdo idêntico ao do `.sh` (estariam erradamente copiados — os formatos divergem: `\newpage` vs `---`, headings por arquivo só no `.sh`).

### Pitfall 8: `generate-index.ps1` sob pwsh/Linux — args e links quebrados (congelar como está, mas verificar na captura)

**What goes wrong:** (a) [VERIFIED: scripts/generate-index.ps1:4] `$FeatureBaseDirs = $args[2..$args.Count]` — o slice inclui índice fora de range → elemento `$null` → ruído/erro de `Test-Path` sob pwsh 7 (comportamento a verificar empiricamente na captura); (b) [VERIFIED: scripts/generate-index.ps1:55-57] `"specs/$((Split-Path $dir -NoQualifier) -replace '\\', '/')/spec.md"` — em Unix `Split-Path -NoQualifier` devolve o path absoluto inteiro, então os links da tabela Features saem como `specs//tmp/…/spec.md` (quebrados). O golden congela esses warts como estão — a captura é o primeiro exercício real dos gêmeos no Linux e o momento de *registrar* o comportamento, não de consertar (conserto é Phase 4, se couber).
**How to avoid:** ponto de verificação `checkpoint:human-verify` na captura `.ps1` — rodar, inspecionar stderr e saída, registrar no manifest.

### Pitfall 9: `MDW_INDEX_OUT` é env var pré-existente

**What goes wrong:** [VERIFIED: scripts/generate-index.sh:19] `OUTPUT="${MDW_INDEX_OUT:-docs/index.md}"` — um env var de override existe na cadeia hoje. PARAM-01 veda env var *de idioma*; `MDW_INDEX_OUT` não é idioma, mas o harness deve **não setá-lo** (default path) e o contrato da fase deve notar sua existência para que ninguém o trate como padrão a seguir.
**How to avoid:** harness nunca exporta `MDW_INDEX_OUT`; manifest documenta o default `docs/index.md`.

### Pitfall 10: tempo de vida de `/tmp`

**What goes wrong:** `/tmp` é volátil (tmpfs/limpeza de reboot) — a fixture validada `/tmp/mdw-sr3` pode sumir entre esta research e a execução da fase.
**How to avoid:** a réplica para `tests/fixtures/tree/` é o **primeiro task** do plano (é cópia, não regeneração — a estrutura está inventariada abaixo). Se `/tmp/mdw-sr3` já não existir na execução, a tree é reconstruível a partir do inventário desta research (estrutura completa + conteúdo ASCII simples), com checkpoint humano.

## Code Examples

### Inventário da fixture `/tmp/mdw-sr3` (verificado por `find`, 2026-09-28 — 14 arquivos)

```text
/tmp/mdw-sr3/
  .specs/                                  # 6 arquivos-fonte (conteúdo 100% ASCII — verificado)
    codebase/ARCHITECTURE.md
    features/login/design.md
    features/login/spec.md
    project/PROJECT.md
    project/ROADMAP.md
    quick/fix-nav/spec.md
  docs/                                    # saída de captura anterior (AUDIENCE=developer)
    index.md
    specs/{codebase,features,project,quick}/…  # mirror dos 6 acima
  mkdocs.yml                               # repo_url vazio; nav 5 entradas: Home, Codebase,
                                           #   Features, Project, Quick (verificado por leitura)
```

A réplica da tree de teste = `.specs/` acima + `features/autenticação/spec.md` (D-05). Nav segue 5 entradas porque `autenticação` é subdiretório de `features/` — verificado por execução da réplica neste host: `Generated mkdocs.yml (docs in docs/specs/, nav sections: 5)`.

### Saídas exatas por superfície (cadeia `.sh` atual, engine-less — verificado por execução)

| Superfície | Artefato(s) golden | Portador de chrome | Portador de data | Origem |
|------------|--------------------|--------------------|------------------|--------|
| MkDocs index+nav | `mkdocs.yml`, `docs/index.md`, `docs/specs/**` (mirror) | `mkdocs.yml` (site_name/site_description/Home/nav labels), `docs/index.md` (título, tagline, seções, tabelas, rodapé) | `docs/index.md` rodapé (`:105`) | generate-mkdocs.sh + generate-index.sh |
| DokuWiki | `dokuwiki-out/README.md` (+ `data/pages/**` se pandoc) | README inteiro (título, 4 passos, assinatura) | nenhum | to-dokuwiki.sh:29-38 (exige pandoc — Pitfall 6) |
| PDF | `specs-book.pdf` (fallback = cópia byte do `specs-book.md`; verificado: 280 = 280 bytes) | heading `# Specifications` | nenhum no `.sh` | to-pdf.sh:14,44-47 |
| Swagger UI | `swagger-ui/index.html` | `<title>{{PROJECT_NAME}} — API Docs</title>` | nenhum | templates/swagger-ui.html + sed (D-02) |
| GitHub Wiki | — (sem golden — autoria de agent; só inventário) | Home.md/_Sidebar.md/_Footer.md + nomes de seção | — | agents/format-github-wiki.md:47-53 |

Observação: `specs-book.md` fica retido ao lado do `.pdf` ([VERIFIED: scripts/to-pdf.sh:49] comentário `# specs-book.md is retained — deletion follows the CONTEXT.md cleanup policy`) mas fica **fora** do golden `.sh` (D-01 — intermediário; o `.pdf` fallback é cópia byte dele).

### Inventário de chrome — grade 4 camadas × 5 superfícies (âncoras arquivo:linha, todas lidas nesta sessão)

Formato-alvo de `docs/chrome-inventory.md` (D-07: chave → sítio; chaves = seed do glossário do stack do projeto — o inventário não inventa chaves):

**Camada 1 — cadeia `.sh`**

| Chave | Valor `en` atual (verbatim) | Sítio |
|-------|------------------------------|-------|
| `site_name_suffix` | `— Specifications` (em `# $PROJECT_NAME — Specifications` / `site_name: $PROJECT_NAME — Specifications`) | generate-index.sh:32 · generate-mkdocs.sh:43 |
| `site_description` | `Auto-generated documentation from spec-driven development` | generate-mkdocs.sh:44 |
| `nav_home` | `Home` (em `- Home: index.md`) | generate-mkdocs.sh:59 |
| `index_tagline` | `Auto-generated documentation from spec-driven development sessions.` | generate-index.sh:34 |
| `section_quick_start` | `## Quick Start` | generate-index.sh:45 |
| `section_overview` | `## Overview` | generate-index.sh:52 (stakeholder) · :60 (general) |
| `section_features` | `## Features` (+ headers `\| Feature \| Spec \| Design \| Tasks \|`) | generate-index.sh:73 |
| `section_architecture` | `## Architecture` | generate-index.sh:90 |
| `section_getting_started` | `## Getting Started` | generate-index.sh:95 |
| `section_development` | `## Development` | generate-index.sh:102 |
| `label_project_overview` | `Project Overview` | generate-index.sh:41,49,56 |
| `label_stack` | `Stack` | generate-index.sh:43 |
| `label_conventions` | `Conventions` | generate-index.sh:44 |
| `label_roadmap` | `Roadmap` | generate-index.sh:50,57 |
| `label_state_decisions` | `State & Decisions` | generate-index.sh:51 |
| `label_setup_guide` | `Setup Guide` | generate-index.sh:100 |
| `label_contributing` | `Contributing` | generate-index.sh:101 |
| `label_architecture` | `Architecture` | generate-index.sh:42,58 |
| `table_section` / `table_description` | `| Section | Description |` | generate-index.sh:60 |
| `table_feature`…`table_tasks` | `Feature` / `Spec` / `Design` / `Tasks` | generate-index.sh:73 |
| `row descriptions` (3) | `Vision, goals, and scope` · `Features and milestones` · `System architecture` | generate-index.sh:56-58 |
| `index_architecture_body` | `Refer to the [Architecture](specs/codebase/ARCHITECTURE.md) document for system design and component relationships.` | generate-index.sh:90 |
| `index_getting_started_body` | `For installation instructions, see the [Project Overview](specs/project/PROJECT.md).` | generate-index.sh:95 |
| `generated_by` | `Generated by [md-to-wiki](https://github.com/abertanha/md-to-wiki-docs-skills) — %s` | generate-index.sh:105 |
| `pdf_title` | `# Specifications` | to-pdf.sh:14 |
| `dokuwiki_readme` (bloco) | `# DokuWiki Import Instructions` + 4 passos + `Generated by md-to-wiki skill set` | to-dokuwiki.sh:29-38 |

**Camada 2 — gêmeos `.ps1`** (mesmas chaves; sítios divergentes; strings divergentes marcadas)

| Chave | Sítio `.ps1` | Divergência vs `.sh` |
|-------|---------------|----------------------|
| `site_name_suffix` | generate-index.ps1:23 · generate-mkdocs.ps1:46 | igual |
| `site_description` | generate-mkdocs.ps1:47 | igual |
| `nav_home` | generate-mkdocs.ps1:17 | igual |
| `index_tagline` | generate-index.ps1:25 | igual |
| `section_overview` + tabela + rows | generate-index.ps1:34-40 | rows emitidas incondicionalmente (sem checagem por arquivo) |
| `section_features` + headers | generate-index.ps1:48-51 | headers iguais; **células divergem** — `[$name]($spec)` com label = nome do diretório (generate-index.ps1:58) |
| `section_architecture` + body | generate-index.ps1:65,67 | body igual |
| `section_getting_started` + body | generate-index.ps1:74,76 | body igual |
| `section_development` + prose | generate-index.ps1:78-80 | **prose divergente** (`See [Setup Guide](…) and [Contributing](…) for developer onboarding.`) |
| `generated_by` | generate-index.ps1:84 | **URL divergente**: `https://opencode.ai` |
| `pdf_title` | to-pdf.ps1:19 | igual |
| `pdf_generated_on` (nova, só `.ps1`) | to-pdf.ps1:21 | `*Generated on $date*` — inexistente no `.sh` |
| `dokuwiki_readme` | to-dokuwiki.ps1:36-45 | igual |
| `nav_issues` (nova, só `.ps1`) | generate-mkdocs.ps1:41 | `Issues: issues/` condicional ao cache |

**Camada 3 — templates**

| Chave | Sítio | Status |
|-------|-------|--------|
| `swagger_title_suffix` | templates/swagger-ui.html:6 — `<title>{{PROJECT_NAME}} — API Docs</title>` (placeholder `{{OPENAPI_YML}}` na linha 18) | consumido por agents/format-swagger.md:67-70 — vivo |
| (espelho das chaves de index) | templates/index.md:1,3,7-25 | **NÃO consumido por nada** — grep em agents/, scripts/, SKILL.md, CONTEXT.md não encontra referência; o generate-index usa heredoc próprio. Inventariar com status "unconsumed"; a Phase 2 extrai `en` **dos scripts** (fonte viva), não daqui |

**Camada 4 — prosa de chrome escrita por agents em runtime**

| Sítio | Chrome | Superfície |
|-------|--------|------------|
| agents/format-github-wiki.md:47-53 | `Home.md`, `_Sidebar.md`, `_Footer.md`, seções `Project/`, `Architecture/`, `Features/`, `Quick-Tasks/` | GitHub Wiki (sem golden — autoria) |
| agents/format-swagger.md:32-34,45 | `{{PROJECT_NAME}} — API Specs`, `Auto-generated from spec-driven development markdowns`, `"Success"` (esqueleto do openapi.yml) | Swagger |
| agents/format-mkdocs.md, format-dokuwiki.md, format-pdf.md | nenhum chrome próprio — orquestram scripts (headings do livro vêm de `basename` — passthrough, CHROME-04) | — |

### Proposta de linha no contrato (exemplo de redação — discretion)

```markdown
# CONTEXT.md §Variables (nova linha após AUDIENCE — linha 17 hoje)
| `OUTPUT_LANG` | Output language of published chrome | `en` \| `pt-br` (default `pt-br`; normalize case-insensitively on input — `pt-BR` ≡ `pt-br`) |

# agents/onboarding.md §Interview (padrão da pergunta AUDIENCE, linhas 9-12)
N+1. **OUTPUT_LANG** — `en` \| `pt-br` (canonical tokens, lowercase; use one of these exactly):
   - en — English chrome, byte-identical to today's output
   - pt-br — Portuguese (Brazil) chrome
   Default: `pt-br` when the user has no preference.

# onboarding.md §Return criteria (linha 47 — acrescentar à lista)
(`PROJECT_NAME`, `SOURCES`, `AUDIENCE`, `OUTPUT_LANG`, `FORMAT`, `OS_TYPE`, `SCRIPT_EXT`, `SCRIPT_RUNNER`, `SKILL_DIR`)
```

## State of the Art

| Abordagem antiga | Abordagem atual | Quando | Impacto |
|------------------|-----------------|--------|---------|
| Verificação de doc gerada por inspeção manual | Golden fixtures byte-exatos + diff mascarado (prática consolidada em CLIs determinísticos) | — | É exatamente QUAL-02; sem framework, só `diff` |
| Validação estrutural de YAML/nav por parse | Dif contra golden congela estrutura e conteúdo juntos | ADR-0003 | Host sem mkdocs verificável desde a config |
| Chrome de LLM agents tratado como "a saída" | Separação explícita chrome-de-script (congelável) vs chrome-de-agent (só inventariável) | esta research | A grade 4×5 delimita o que golden cobre e o que só o inventário mapeia |

**Deprecated/outdated:**
- `templates/index.md` como fonte do index — a cadeia real usa heredoc do `generate-index.sh`; o template é paralelo e não consumido (achado desta research)

## Assumptions Log

| # | Claim | Seção | Risk if Wrong |
|---|-------|-------|---------------|
| A1 | Saída do writer dokuwiki do pandoc pode variar entre versões do pandoc (não verificado — WebSearch rate-limited) | Pitfall 6 / Open Questions Q1 | Golden DokuWiki quebra se o host de re-execução tiver pandoc diferente — mitigado registrando `pandoc --version` no manifest e tratando a perna como version-pinned |
| A2 | PS 7 no Linux grava `Out-File -Encoding utf8` como UTF-8 sem BOM e LF; PS 5.1 grava com BOM | Pitfall 5 | Se invertido, o golden `.ps1` nasceria com BOM — verificação de 1 comando (`head -c 3`) é o primeiro passo da captura; respaldo documental no stack do projeto (`.claude/CLAUDE.md`, que cita about_Character_Encoding) |
| A3 | `generate-index.ps1:4` (`$args[2..$args.Count]`) gera elemento `$null` → ruído/erro de `Test-Path` sob pwsh 7 | Pitfall 8 | Ruído em stderr ou perna falha na captura — checkpoint humano na captura resolve; não afeta o `.sh` |
| A4 | Método tar.gz do pwsh funciona sem sudo (página install-other-linux#binary-archives referenciada mas não aberta nesta sessão) | Standard Stack | Se a rota sem sudo for necessária e não funcionar, instalação exige o usuário de qualquer forma (sudo tem senha) |
| A5 | A URL `https://opencode.ai` no rodapé do `.ps1` é wart a preservar (não decisão de corrigir agora) | Pattern 1 | Se o planner decidir corrigi-la nesta fase, quebra o espírito "cadeia atual não modificada" — correção pertence à Phase 4 via catálogo |

## Open Questions

1. **Superfície DokuWiki sem pandoc (Q1 — bloqueadora de escopo, não de início)**
   - O que se sabe: `to-dokuwiki.sh`/`.ps1` fazem `exit 1` sem pandoc antes de escrever qualquer byte publicável (Pitfall 6); D-01 inclui "mirror DokuWiki" nas 5 superfícies; o critério 4 manda o harness rodar sem engines
   - O que está claro: sem pandoc, não há golden DokuWiki — não existe fallback
   - Recomendação: **pandoc como dev-dep** (mesmo regime D-03 do pwsh: `sudo apt install pandoc`, candidato 3.1.3), captura na Phase 1, e a perna entra no regime SKIPPED/exit 3 quando pandoc ausente. Alternativa (deferir o golden DokuWiki) deixa D-01 parcialmente entregue — pior
2. **Golden `.ps1` da superfície PDF (Q2)**
   - O que se sabe: `to-pdf.ps1` não tem fallback; o `$Output` nunca nasce sem engines (Pitfall 7); o rodapé datado que o CONTEXT.md manda congelar vive em `specs-book.md`
   - Recomendação: capturar `specs-book.md` como golden dessa perna com a exceção a D-01 **documentada no manifest** (é o único artefato engine-less e é byte-diferente do `.sh`: `\newpage`, sem headings por arquivo)
3. **AUDIENCE da captura (Q3 — discretion, decidir no plano)**
   - Recomendação: `general` (default do script; exercita a tabela `| Section | Description |`). A fixture validada usou `developer` — o manifest registra a escolha e o porquê
4. **`templates/index.md` unconsumed (Q4 — para a seção de decisões do contrato)**
   - Recomendação: inventariar com status "unconsumed"; decidir usar-ou-remover fica para a Phase 2 (fora do escopo agora); o inventário marca a fonte viva como sendo os scripts

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | harness + cadeia `.sh` | ✓ | 5.2.21 | — |
| GNU diff/cmp | dif de regressão | ✓ | 3.10 | — |
| GNU sed | máscara + render Swagger | ✓ | 4.9 | — |
| git | repo (branch `ft/gsd-pattern-align`) | ✓ | 2.43.0 | — |
| `C.UTF-8` locale | pin de captura/diff | ✓ (`C.utf8` em `locale -a`) | glibc | `pt_BR.utf8` existe mas não é portável |
| mkdocs/mkdocs-material | nada nesta fase (golden é config-level, ADR-0003) | ✗ (esperado) | — | — |
| pandoc | golden DokuWiki (Q1) | ✗ | candidato apt `3.1.3+ds-2` | perna SKIPPED exit 3 |
| weasyprint/xelatex/wkhtmltopdf | nada (fallback do to-pdf é o golden) | ✗ (esperado) | — | — |
| pwsh | goldens `.ps1` (D-03) | ✗ | 7.6.x via PMC/GitHub (doc oficial) | perna SKIPPED exit 3 |
| node/npx | validação Swagger (opcional) | ✓ | v20.19.6 | — |
| jq | repo_url fallback (`.specs/config.json`) | ✓ | apt | fixture não tem config.json — irrelevante |
| sudo (com senha) | instalação pwsh/pandoc | ✓ exige senha | — | tar.gz do pwsh sem sudo (A4); pandoc sem alternativa sem sudo |

**Missing dependencies with no fallback:** nenhum bloqueador de início — pwsh e pandoc são necessários só no bloco de captura (com o usuário), e o regime SKIPPED mantém o harness funcional sem eles.

**Missing dependencies with fallback:** pwsh (SKIPPED exit 3 — D-04), pandoc (idem, se Q1 aprovada a captura exige instalação; o harness segue sem).

## Security Domain

`security_enforcement: true`, ASVS level 1. Fase de documentação/fixtures/contrato — sem auth, sessão, criptografia ou dados de usuário em runtime.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (skill local sem autenticação) |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | sim (padrão, não superfície de ataque) | Fail-closed por contrato: valor desconhecido de `OUTPUT_LANG` interrompe listando suportados (PARAM-02) — espelha o padrão vigente em `to-dokuwiki.sh:11-12` (erro nomeando o problema + instrução de resolução, nunca fallback silencioso) |
| V6 Cryptography | no | — |

### Known Threat Patterns for {bash + fixtures commitadas}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Nomes de arquivo da fixture chegando a `sed`/comandos como argumento | Tampering | Fixture é conteúdo commitado do repo (confiança de repo); harness usa quoting/arrays (Pitfall 3); nenhum `eval` |
| Golden editado manualmente (corrupção do critério de regressão) | Repudiation | Golden gerado só pelo modo captura; diff é o guardião; manifest registra origem/SHA |
| Workdir compartilhado entre pernas (resíduo influencia saída) | Tampering | `mktemp -d` fresco por perna (Pitfall 4) |
| Rede | — | Nenhum script da fase acessa rede (a cadeia engine-less é local; swagger render é sed sobre arquivo) |

## Sources

### Primary (HIGH confidence)
- Leitura completa, nesta sessão, de: `scripts/generate-index.sh`, `generate-mkdocs.sh`, `to-dokuwiki.sh`, `to-pdf.sh`, `generate-index.ps1`, `generate-mkdocs.ps1`, `to-dokuwiki.ps1`, `to-pdf.ps1`, `discover-sources.sh`, `templates/index.md`, `templates/swagger-ui.html`, `agents/onboarding.md`, `format-mkdocs.md`, `format-swagger.md`, `format-github-wiki.md`, `format-dokuwiki.md`, `format-pdf.md`, `references.md`, `deploy.md`, `CONTEXT.md`, `SKILL.md`, `.planning/{REQUIREMENTS,ROADMAP,STATE}.md`, `docs/adr/0003`, `docs/adr/0004`
- Execuções neste host (2026-09-28): dupla execução da cadeia sobre réplica da fixture + diff mascarado (determinismo); xxd do sed title-case em 3 locales; hexdump BOM/CRLF; `apt-cache policy`; `locale -a`; greps de datas/exit-codes/env-vars
- `/tmp/mdw-sr3` inventariado por `find` + leitura de `mkdocs.yml` e `docs/index.md`

### Secondary (MEDIUM confidence)
- [CITED: learn.microsoft.com/powershell/scripting/install/install-ubuntu] — métodos de instalação do pwsh no Ubuntu 24.04, suporte até 2029-05-31, PMC preferido, snap não-suportado (página verificada via WebFetch em 2026-09-28; ms.date 2026-08-11)

### Tertiary (LOW confidence)
- Estabilidade cross-versão do writer dokuwiki do pandoc — não verificada (WebSearch rate-limited); mitigada pelo manifest de versões (A1)

## Metadata

**Confidence breakdown:**
- Standard stack (toolchain do harness): HIGH — tudo verificado por execução no host
- Architecture (harness/goldens/contrato): HIGH — padrões derivados de leitura completa da cadeia + execução empírica; as 2 decisões pendentes (Q1/Q2) estão delimitadas com recomendação
- Pitfalls: HIGH — Pitfalls 1-4 e 6-7 têm evidência empírica ou âncora verbatim; 5 (BOM PS 5.1) e 8 (args ps1) são [CITED]/[ASSUMED] com checkpoint de captura

**Research date:** 2026-09-28
**Valid until:** 2026-10-28 (a cadeia é estável; o item mais volátil é `/tmp/mdw-sr3` — replicar o quanto antes, Pitfall 10)
