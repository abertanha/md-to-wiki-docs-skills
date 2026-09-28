# Phase 1: Contrato & Golden Fixtures - Pattern Map

**Mapped:** 2026-09-28
**Files analyzed:** 8 (2 modificados, 6 novos — bundles de fixture contados como 1 cada)
**Analogs found:** 5 / 8 (3 são fronteira nova sem analog: tree de fixture e 2 diretórios de goldens)

Todos os analogs citados below são fonte git-TRACKED (verificado: `git ls-files -- <path>` = 1 para cada um; nenhum mirror/gitignored). `tests/` não existe hoje — confirmado — é fronteira nova; o bash do harness ancora 100% nos `scripts/*.sh` existentes.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `tests/regress.sh` | test (harness bash) | batch (captura + diff) | `scripts/to-dokuwiki.sh` (skeleton + gate) + `scripts/discover-sources.sh` (dispatch de modo) + `scripts/to-pdf.sh` (cascata de engines/fallback) | role-adjacent (nenhum teste existe; estilo bash exact) |
| `tests/fixtures/tree/.specs/**` (6 .md replicados + `features/autenticação/spec.md`) | test fixture (dados de entrada) | file-I/O | — (fonte: `/tmp/mdw-sr3/.specs`, ainda presente no host; molde de layout: `CONTEXT.md:32-38`) | none (new frontier) |
| `tests/fixtures/manifest.md` | config/doc (registro de captura) | static | `docs/adr/0003-mkdocs-chain-repair.md` (header + formato de registro) | role-match |
| `tests/fixtures/golden-sh/**` | test fixture (golden gerado) | transform (saída congelada) | — (gerado só pelo modo captura; nunca escrito à mão) | none (generated artifact) |
| `tests/fixtures/golden-ps1/**` | test fixture (golden gerado) | transform (saída congelada) | — (idem; baseline pwsh 7 / Linux, sem BOM, LF) | none (generated artifact) |
| `CONTEXT.md` (§Variables nova linha `OUTPUT_LANG` + pointer de escopo D-08) | config (contrato) | static | a própria tabela Variables — molde exato: linha `AUDIENCE` (`CONTEXT.md:17`) | exact |
| `agents/onboarding.md` (§Interview pergunta `OUTPUT_LANG` + §Return criteria) | config (contrato) | request-response (entrevista) | a própria pergunta `AUDIENCE` (`agents/onboarding.md:9-12`) + lista de retorno (`:47`) | exact |
| `docs/chrome-inventory.md` | doc (mapa de referência) | static (tabela chave → sítio) | `.claude/CLAUDE.md:49-77` (seed do glossário — fonte das chaves) + `docs/skill-quality-rubric.md` (doc de referência table-heavy) | role-match |

## Pattern Assignments

### `tests/regress.sh` (test, batch)

**Analogs:** `scripts/to-dokuwiki.sh` (skeleton + gate fail-closed), `scripts/discover-sources.sh` (dispatch de modo), `scripts/to-pdf.sh` (fallback + severidade), `scripts/generate-mkdocs.sh` (loops sem subshell), `scripts/generate-index.sh` (helpers + sítio de data)

**Skeleton bash — copiar de `scripts/to-dokuwiki.sh:1-5`** (todos os 5 `.sh` do repo seguem este shape: shebang env, header `# nome — propósito`, `set -euo pipefail`, guard de uso):

```bash
#!/usr/bin/env bash
# to-dokuwiki.sh — Convert markdown files to DokuWiki syntax
set -euo pipefail

OUTPUT="${1:?Usage: to-dokuwiki.sh <output_dir> <file1.md> [file2.md ...]}"
```

Para o regress.sh: `# regress.sh — <propósito>` + `# Usage: regress.sh [--capture]` como segunda linha de comentário (convenção de `scripts/generate-index.sh:3` e `scripts/discover-sources.sh:3`).

**Dispatch de modo (regress default vs `--capture`) — copiar de `scripts/discover-sources.sh:6-12,20`:**

```bash
DIR="${1:-.specs}"
FORMAT="${2:-summary}"

if [ ! -d "$DIR" ]; then
  echo "ERROR: Directory not found: $DIR"
  exit 1
fi
...
case "$FORMAT" in
```

→ `MODE="${1:-regress}"` + `case "$MODE" in capture) … ;; *) … ;; esac`.

**Gate fail-closed de dependência — copiar de `scripts/to-dokuwiki.sh:10-13`** (erro nomeia o problema E o fix; nunca fallback silencioso):

```bash
if ! command -v pandoc &>/dev/null; then
  echo "ERROR: pandoc not found. Install it: sudo apt install pandoc"
  exit 1
fi
```

→ Variante SKIPPED (D-04): `command -v pwsh` ausente = `echo "SKIPPED: pwsh not found…"` + acumular `SKIP=1` + **exit 3** no fim. Verificado por grep: a cadeia toda usa só `exit 0`/`exit 1` — **exit 3 está livre**, sem colisão com exit 1 do diff. `pandoc` (perna DokuWiki) segue o mesmo regime SKIPPED/exit 3, não exit 1.

**Severidade WARNING vs ERROR — copiar de `scripts/to-pdf.sh:17`** (WARNING vai para stderr e continua; ERROR nomeia o fix e para):

```bash
[ -f "$file" ] || { echo "WARNING: $file not found, skipping" >&2; continue; }
```

**Iteração de árvore sem subshell — copiar de `scripts/generate-mkdocs.sh:25-38`** (com o comentário-âncora que a linha 25 já carrega; manter o comentário ao replicar):

```bash
# No `... | while read` here — pipe loops run in subshells and lose nav_entries.
for dir in "$SITE_DOCS/specs"/*/; do
  [ -d "$dir" ] || continue
  ...
  while IFS= read -r file; do
    ...
  done <<< "$files"
done
```

**Helpers pequenos com printf — molde de `scripts/generate-index.sh:23-29`** (`link()` / `cell()`): função de 1-3 linhas, comentário de uma linha acima declarando o contrato (`# <o que faz> # <args>`).

**Sítios de data que a máscara cobre (3, todos ISO 8601 — alvo do sed de máscara):**

- `scripts/generate-index.sh:105` — `printf -- '---\n*Generated by [md-to-wiki](https://github.com/abertanha/md-to-wiki-docs-skills) — %s*\n' "$(date +%Y-%m-%d)" >> "$OUTPUT"`
- `scripts/generate-index.ps1:84` — `*Generated by [md-to-wiki](https://opencode.ai) — $(Get-Date -Format yyyy-MM-dd)*`
- `scripts/to-pdf.ps1:17,21` — `$date = Get-Date -Format "yyyy-MM-dd"` / `*Generated on $date*`

Grep confirmou: nenhum outro sítio de data na cadeia. Regex da máscara: `s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/__DATE__/g`, aplicada simetricamente ao golden E à saída fresca (cópias em tmp) antes do diff.

**Por que `LC_ALL=C.UTF-8` é obrigatório (pin no harness):** `scripts/generate-index.sh:79` e `scripts/generate-mkdocs.sh:29,35` usam `sed 's/-/ /g; s/\b\(.\)/\u\1/g'` — em `LC_ALL=C` isto corrompe `autenticação` (reproduzido no host: byte `c3`→`ff`). O pin também fixa a collation do `sort` que ordena nav (`generate-mkdocs.sh:30`) e listas.

**Render Swagger (D-02) — molde do consumo real, `agents/format-swagger.md:67-70`:**

```markdown
From the template at `$SKILL_DIR/templates/swagger-ui.html`, write `swagger-ui/index.html`:

- Replace `{{PROJECT_NAME}}` with `$PROJECT_NAME`
- Replace `{{OPENAPI_YML}}` with `openapi.yml` (same directory)
```

Placeholders no template: `templates/swagger-ui.html:6` (`<title>{{PROJECT_NAME}} — API Docs</title>`) e `:18` (`url: "{{OPENAPI_YML}}"`). O harness replica a substituição via `sed -e 's/{{PROJECT_NAME}}/TestProject/g' -e 's|{{OPENAPI_YML}}|openapi.yml|g'` e diffa contra a instância golden.

**Invocação canônica por superfície (para o modo captura) — derivada dos agents:** `agents/format-mkdocs.md:26,34` (`generate-mkdocs.sh "$PROJECT_NAME" "$SOURCES"`, depois `generate-index.sh "$PROJECT_NAME" "$AUDIENCE" docs/specs/features`), `agents/format-pdf.md:20,28` (ordem `project/*.md → codebase/*.md → features/<name>/spec.md,design.md,tasks.md → quick/<name>/*.md`, args explícitos, nunca expansão não citada). Detalhe crítico do cwd: `generate-mkdocs.sh:17-19` lê `git remote get-url origin` — o workdir de captura DEVE ser `mktemp -d` fora do repo (senão a URL SSH vaza para o golden).

---

### `CONTEXT.md` §Variables (config, static) — MODIFICADO

**Analog:** a própria tabela — molde exato é a linha `AUDIENCE`, `CONTEXT.md:17`:

```markdown
| `AUDIENCE` | Who reads the output | `developer` \| `stakeholder` \| `general` |
```

**Nova linha imediatamente após `:17`** (redação da research, discretion confirmada):

```markdown
| `OUTPUT_LANG` | Output language of published chrome | `en` \| `pt-br` (default `pt-br`; normalize case-insensitively on input — `pt-BR` ≡ `pt-br`) |
```

Regras sintáticas da tabela a honrar: alternância de valores usa pipe escapado `\|` (como `:13` `.sh` \| `.ps1` e `:17`); inglês no contrato (o repo inteiro — scripts, agents, CONTEXT — é EN; PT-BR é a saída, não o contrato).

**Seção de decisões de escopo (D-08) — dois moldes do próprio arquivo:**

1. Pointer de autoridade em uma linha — molde de `CONTEXT.md:30`: `Authority: `scripts/discover-sources.sh`.` → a seção aponta para `docs/chrome-inventory.md` ("the map lives there") sem reenunciar chaves.
2. Política concisa — molde de §Cleanup policy (`CONTEXT.md:62-64`): 2-3 frases declarando a regra (fail-closed de chave ausente, casa/formato do catálogo, escopo Swagger, datas ISO 8601), sem exemplos.

**Regra de casa única a preservar** (`CONTEXT.md:3,7`): variáveis vivem aqui, atribuição só no onboarding, transmissão só por dispatch prompt. `OUTPUT_LANG` entra nesse mecanismo — nunca env var (nota: `MDW_INDEX_OUT` em `generate-index.sh:19` é env var pré-existente e NÃO é molde a seguir).

---

### `agents/onboarding.md` §Interview + §Return criteria (config, request-response) — MODIFICADO

**Analog:** a pergunta `AUDIENCE`, `agents/onboarding.md:9-12` — o molde exato citado pela decisão (tokens canônicos + descrição por valor):

```markdown
3. **AUDIENCE** — `developer` \| `stakeholder` \| `general` (canonical tokens; use one of these exactly):
   - developer — detailed code docs, API references
   - stakeholder — executive summaries, roadmaps, decisions
   - general — feature overviews, tutorials
```

**Nova pergunta como item 4** (renumerar FORMAT→5, Deployment→6), seguindo o molde linha a linha:

```markdown
4. **OUTPUT_LANG** — `en` \| `pt-br` (canonical tokens, lowercase; use one of these exactly):
   - en — English chrome, byte-identical to today's output
   - pt-br — Portuguese (Brazil) chrome
   Default: `pt-br` when the user has no preference.
```

**§Return criteria — linha `:47`** (lista parenthesizada de nomes canônicos; acrescentar `OUTPUT_LANG`):

```markdown
Return the variables by their CONTEXT.md names (`PROJECT_NAME`, `SOURCES`, `AUDIENCE`, `OUTPUT_LANG`, `FORMAT`, `OS_TYPE`, `SCRIPT_EXT`, `SCRIPT_RUNNER`, `SKILL_DIR`).
```

Nota de estilo do arquivo: entrevista é lista numerada, uma linha de contexto por pergunta quando necessário (`:8` mostra o padrão pergunta + esclarecimento), inglês, sem negação solta.

---

### `docs/chrome-inventory.md` (doc, static) — NOVO

**Analogs:** `.claude/CLAUDE.md:49-77` (seed do glossário — fonte canônica das chaves; o inventário NÃO inventa chaves) + `docs/skill-quality-rubric.md` (convenções de doc de referência) + header ADR.

**Molde de tabela — seed do glossário, `.claude/CLAUDE.md:53`** (primeira linha da seed):

```markdown
| Chave | `en` (byte-idêntico ao atual) | `pt-br` (proposta) |
|-------|-------------------------------|--------------------|
| `site_name_suffix` | `— Specifications` | `— Especificações` |
```

→ O inventário inverte a última coluna para sítios (D-07: chave → `arquivo:linha`):

```markdown
| Chave | Valor `en` atual (verbatim) | Sítio(s) |
|-------|------------------------------|----------|
| `site_name_suffix` | `— Specifications` | scripts/generate-index.sh:32 · scripts/generate-mkdocs.sh:43 |
```

**Convenções de doc de referência — copiar de `docs/skill-quality-rubric.md:1-8`:** título H1 com nome do artefato, um parágrafo de abertura declarando o que o doc É, e as linhas `**Source of …:**` apontando a autoridade (aqui: a seed do glossário em `.claude/CLAUDE.md` e a regra "chave órfã cai no en por fallback; o par completo é o que o rubric audita"). Onde o rubric diz "Where this rubric and that skill disagree, the skill wins", o inventário declara o equivalente para a seed.

**Header de data/status — molde ADR, `docs/adr/0003-mkdocs-chain-repair.md:1-3`:**

```markdown
# ADR 0003 — MkDocs chain: root config, copied specs, subshell-free nav

Date: 2026-09-28 · Status: accepted
```

→ `docs/chrome-inventory.md` abre com `Date: … · Source: audited against scripts@ <commit>` (a grade de 4 camadas × 5 superfícies com âncoras arquivo:linha já está verificada verbatim no `01-RESEARCH.md` §"Inventário de chrome" — o doc novo é a transcrição commitada dessa grade, incluindo as divergências marcadas: URL `opencode.ai` em `generate-index.ps1:84`, `pdf_generated_on` só em `to-pdf.ps1:21`, `templates/index.md` com status "unconsumed").

**Idioma:** doc novo em `docs/` segue o idioma dos pares — `docs/adr/*` e `docs/skill-quality-rubric.md` são EN; a seed do glossário em `.claude/CLAUDE.md` é PT-BR. Decisão de idioma do inventário cabe ao planner (valores `en` verbatim ficam em inglês de qualquer forma).

---

### `tests/fixtures/manifest.md` (config/doc, static) — NOVO

**Analog:** `docs/adr/0003-mkdocs-chain-repair.md` — header `Date · Status` (`:3`), seções curtas nomeadas, uma lista numerada de decisões/committments (`:11-14`). O manifest é um registro de captura: header com data + baseline (`pwsh --version`, `pandoc --version`, commit SHA da captura), depois os pins que a research definiu (PROJECT_NAME=TestProject, AUDIENCE=general + porquê, `LC_ALL=C.UTF-8`, token `__DATE__` + os 3 sítios, ordem de arquivos do PDF, cwd `mktemp -d`, exceção `specs-book.md` da perna `.ps1`/Q2, proibição de edição manual do golden). Molde de "política em 2-3 frases": `CONTEXT.md:62-64`.

---

## Shared Patterns

### Skeleton bash (todos os scripts)
**Source:** `scripts/to-dokuwiki.sh:1-5` (idêntico em `to-pdf.sh:1-5`, `generate-index.sh:1-5`, `generate-mkdocs.sh:1-4`, `discover-sources.sh:1-7`)
**Apply to:** `tests/regress.sh`
```bash
#!/usr/bin/env bash
# <name>.sh — <purpose>
# Usage: <name>.sh <args>
set -euo pipefail
```

### Fail-closed com fix nomeado
**Source:** `scripts/to-dokuwiki.sh:10-13`; variante diretório inexistente em `scripts/discover-sources.sh:9-12`
**Apply to:** `tests/regress.sh` (gates `pwsh`/`pandoc`), e é o padrão que PARAM-02 registra para `OUTPUT_LANG` inválido na Phase 2+
```bash
if ! command -v pandoc &>/dev/null; then
  echo "ERROR: pandoc not found. Install it: sudo apt install pandoc"
  exit 1
fi
```
Harness estende: dependência dev-only ausente = `SKIPPED` + exit 3 (parcial ≠ falha); dependência que quebra o diff = exit 1.

### Contrato como casa única (variável → onboarding → dispatch)
**Source:** `CONTEXT.md:3,7,9-18` (tabela + regra de transmissão) + `agents/onboarding.md:9-12,47` (pergunta com tokens canônicos + lista de retorno)
**Apply to:** linha `OUTPUT_LANG` em `CONTEXT.md`, pergunta + retorno em `agents/onboarding.md`; transmissão futura nos dispatch prompts dos `agents/format-*.md` (mesmo mecanismo de `AUDIENCE` — fora do escopo desta fase).

### Header Date · Status em docs/
**Source:** `docs/adr/0003-mkdocs-chain-repair.md:3` (`Date: 2026-09-28 · Status: accepted`)
**Apply to:** `docs/chrome-inventory.md`, `tests/fixtures/manifest.md`

### Tabelas markdown com pipe escapado e verbatim em code span
**Source:** `CONTEXT.md:13,17` (`\|` em alternância de valores) + `.claude/CLAUDE.md:53` (valores de label em backticks)
**Apply to:** linha `OUTPUT_LANG` do contrato, grade do `docs/chrome-inventory.md`

### Locale: pin `LC_ALL=C.UTF-8` em tudo que roda a cadeia
**Source:** o sed title-case `scripts/generate-index.sh:79` / `generate-mkdocs.sh:29,35` (`sed 's/-/ /g; s/\b\(.\)/\u\1/g'`) corrompe acentos em locale C (reproduzido no host)
**Apply to:** `tests/regress.sh` (export no topo, antes de qualquer perna)

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `tests/fixtures/tree/.specs/**` | test fixture | file-I/O | Nenhum fixture commitado existe no repo. Fonte da verdade: `/tmp/mdw-sr3/.specs` (VERIFICADO ainda presente no host em 2026-09-28: 6 arquivos `project/PROJECT.md`, `project/ROADMAP.md`, `codebase/ARCHITECTURE.md`, `features/login/{spec,design}.md`, `quick/fix-nav/spec.md`) + `features/autenticação/spec.md` novo. Molde de layout: `CONTEXT.md:32-38` §Source taxonomy. Invariantes: conteúdo 100% ASCII, zero datas ISO (a máscara só toca chrome). |
| `tests/fixtures/golden-sh/**` | test fixture (golden) | transform | Artefato gerado pelo modo `--capture` do harness — por definição não tem analog escrito à mão. Warts de byte a preservar (documentados, nunca "corrigidos"): `repo_url: ` com espaço trailing quando o cwd é git-free (`generate-mkdocs.sh:45` com variável vazia) e linha em branco final do heredoc. |
| `tests/fixtures/golden-ps1/**` | test fixture (golden) | transform | Idem, baseline pwsh 7/Linux (UTF-8 sem BOM, LF — verificar `head -c 3` no primeiro passo da captura). Divergências entre gêmeos são o ponto: golden próprio por geminho, nunca combinado. |

Para os 3 acima, o planner usa `01-RESEARCH.md` (§Code Examples tem a estrutura completa da tree e a grade de chrome com âncoras) — não padrões de código.

## Metadata

**Analog search scope:** `scripts/` (12 arquivos), `agents/` (8), `docs/` (adr + rubric), `templates/` (2), raiz (`CONTEXT.md`, `SKILL.md`), `.claude/CLAUDE.md` (seed do glossário, linhas 49-77). Projeto não tem `tests/`, nem framework de teste, nem fixture commitado — confirmado por `ls` + `git ls-files`.
**Files scanned:** 28 tracked (15 lidos por inteiro nesta sessão; os demais cobertos pela leitura completa da research)
**Tracked-source gate:** todos os 15 analogs citados verificados com `git ls-files -- <path>` = 1 (tracked); nenhum caminho de mirror emitido.
**Verificações de suporte:** exit codes da cadeia = só 0/1 (exit 3 livre para SKIPPED); `/tmp/mdw-sr3` ainda existe; seed do glossário em `.claude/CLAUDE.md:49-77`; `tests/` inexistente.
**Pattern extraction date:** 2026-09-28
