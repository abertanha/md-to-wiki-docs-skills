# Phase 2: Catálogo de Labels & Cadeia MkDocs/index — Research

**Researched:** 2026-09-29
**Domain:** Extração de chrome hardcoded → catálogo KEY=value em bash; substituição por lookup em heredoc/printf; fail-closed em chave ausente; regressão byte-idêntica
**Confidence:** HIGH (todos os scripts lidos integralmente, golden verificado por execução, valores transcritos verbatim dos fontes vivos)

<user_constraints>
## User Constraints (from CONTEXT.md / PROJECT.md)

### Locked Decisions (não reabrir)

- `OUTPUT_LANG` (`en` | `pt-br`, default `pt-br`), atribuído no onboarding, transmitido por dispatch prompt — nunca env var. Implementado na Phase 1; enforcement nos scripts começa nesta fase.
- Formato do catálogo: `templates/lang/en.lang` e `templates/lang/pt-br.lang`, formato `KEY=value`, UTF-8 sem BOM — decidido antes desta fase (seed do glossário em `.claude/CLAUDE.md`).
- Fail-closed obrigatório: chave ausente interrompe a geração nomeando a chave; fallback silencioso está explicitamente proibido (mecanismo de saída mista).
- Nenhuma dependência nova de runtime — bash + markdown apenas.
- Saída com `OUTPUT_LANG=en` byte-idêntica à saída atual — barreira de commit antes de qualquer pt-br.
- Nenhuma transformação de case em runtime no chrome; `sed '\u'` não pode tocar chrome (corrompido em locale C — reproduzido no host).
- Datas: ISO 8601 nos dois idiomas; console dos scripts permanece em inglês.
- Swagger: escopo = título da página + `lang`; chrome do bundle fica em inglês (limite upstream documentado no CONTEXT.md).
- Catálogo: diretório canônico `templates/lang/`, chaves namespaced por superfície.
- Autoridade do inventário de chrome: `docs/chrome-inventory.md` — auditado commit a commit; os scripts vencem sobre a seed quando divergem.

### Claude's Discretion

- Posição exata do argumento `OUTPUT_LANG` na assinatura dos scripts (constrangida: deve ser último fixo antes dos variadicos).
- Estratégia de fail-closed no carregamento: verificação up-front de todas as chaves requeridas vs lazy (na hora do uso); padrão `${VAR:?message}` ou gate explícito de noop.
- Política de `templates/index.md` (unconsumed) — usar-ou-remover é decisão desta fase.
- Idioma da documentação interna do catálogo (comentários no `.lang`).
- Ordem do agrupamento de chaves no arquivo `.lang` (por superfície ou alfabético).

### Deferred Ideas (OUT OF SCOPE para esta fase)

- Catálogo `pt-br` — Phase 3.
- Chrome 100% PT-BR nas 5 superfícies — Phase 3.
- Gêmeos `.ps1` — Phase 4.
- Prosa dos agents em PT-BR — Phase 4.
- Sites multilíngues, mkdocs-static-i18n, seletor de idioma — v2.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Descrição | Suporte da pesquisa |
|----|-----------|---------------------|
| CHROME-01 | Todo chrome de script/template resolve por chave contra catálogo externo `KEY=value`; strings `en` extraídas verbatim das hardcoded atuais | Inventário completo verificado linha a linha em `docs/chrome-inventory.md` e nos fontes vivos; padrão `set -a; . file; set +a` + `${BASH_SOURCE[0]}` para localizar o catálogo |
| CHROME-03 | Chave ausente no catálogo interrompe a geração com erro nomeando a chave | Padrão `${VAR:?key VAR not found in catalog}` (POSIX, funciona com `set -euo pipefail`); verificação up-front via `: ${KEY:?...}` por chave requerida |
| CHROME-04 | Paths, anchors e filenames gerados jamais traduzidos; labels derivados de nomes de arquivo são passthrough sem transformação de case | Três sítios sed title-case identificados verbatim: `generate-index.sh:79`, `generate-mkdocs.sh:29`, `generate-mkdocs.sh:35` — NENHUM é chave de catálogo |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Diretivas acionáveis que o planner deve honrar:

- **Compatibilidade byte-idêntica:** `OUTPUT_LANG=en` reproduz os goldens da Phase 1 — `diff -r` vazio com máscara de data. Qualquer diff é bloqueador de commit.
- **MET-1:** todo padrão adicionado deve ter custo permanente por execução justificado; sem portar padrões sem necessidade demonstrada.
- **Stack:** bash + markdown; zero dependências novas de runtime. `templates/lang/*.lang` são arquivos de dados, não dependências.
- **Encoding:** UTF-8 sem BOM nos `.lang`; nunca `sed '\u'` no chrome (corrompe acentos em locale C — já reproduzido no host).
- **Rubric:** todo arquivo de skill tocado passa pela auditoria delta com `docs/skill-quality-rubric.md`.
- **Git:** trabalho no branch `ft/gsd-pattern-align`; commits por GSD workflow.
- **Idioma:** docs e saída em PT-BR sem calques; valores `en` nos `.lang` ficam em inglês.

---

## Summary

A Phase 2 é uma extração mecânica: todas as strings de chrome fixo da cadeia MkDocs/index estão inventariadas com valor verbatim e sítio `arquivo:linha` em `docs/chrome-inventory.md` (auditado e commitado na Phase 1). O trabalho desta fase é (1) criar `templates/lang/en.lang` com esses valores verbatim, (2) refatorar `generate-index.sh` e `generate-mkdocs.sh` para carregar o catálogo e substituir cada hardcoded por variável de catálogo, e (3) provar que a regressão byte-idêntica passa.

O mecanismo de carregamento é `set -a; . "$CATALOG_FILE"; set +a` com o path do catálogo derivado de `${BASH_SOURCE[0]}` (self-contained, sem arg extra). O fail-closed por chave ausente usa `${VAR:?message}` com verificação up-front de todas as chaves no topo do script. A regressão usa `tests/regress.sh` existente com `OUTPUT_LANG=en` passado explicitamente nas invocações dos scripts.

Há dois itens de fronteira que o planner deve decidir antes de criar os planos: (1) a posição do argumento `OUTPUT_LANG` na assinatura dos scripts (deve vir como último fixo antes dos variadicos para não quebrar chamadas existentes nos agents), e (2) a política para `templates/index.md` — o template é "unconsumed" conforme verificado no inventário; a cadeia viva usa heredoc próprio.

**Primary recommendation:** Criar `templates/lang/en.lang` com todas as chaves do inventário. Refatorar `generate-index.sh` e `generate-mkdocs.sh` em paralelo (os dois arquivos são independentes). Atualizar `tests/regress.sh` para passar `OUTPUT_LANG=en` explicitamente. Verificar regressão byte-idêntica antes de qualquer outro commit desta fase.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Catálogo de labels (fonte única) | `templates/lang/` (arquivo de dados) | — | Arquivo lido por scripts em tempo de geração; não é dependência de runtime |
| Carregamento do catálogo + fail-closed | Scripts `.sh` (topo do script, antes de qualquer uso) | — | A verificação deve ser no ponto de carregamento, não dispersa pelo script |
| Passagem de `OUTPUT_LANG` aos scripts | `agents/format-mkdocs.md` (dispatch prompt → arg do script) | `tests/regress.sh` (perna de regressão) | Contrato do projeto: atribuído no onboarding, transmitido por dispatch; o harness espelha isso com valor explícito `en` |
| Regressão byte-idêntica | `tests/regress.sh` (harness existente) | — | Já funcional com goldens da Phase 1; só precisa passar `OUTPUT_LANG=en` |
| Passthrough de labels derivados de filename | `generate-index.sh:79`, `generate-mkdocs.sh:29,35` (sed title-case) | — | Comportamento congelado pelo golden; NÃO é chave de catálogo |
| Política `templates/index.md` (unconsumed) | Planner (decisão de fase) | — | O inventário confirma: nenhum consumidor; a Phase 2 decide usar-ou-remover |

---

## Standard Stack

### Core (sem mudança de stack — bash + coreutils)

| Mecanismo | Versão/Forma | Propósito | Por quê |
|-----------|-------------|-----------|---------|
| `set -a; . file; set +a` | POSIX/bash | Carregar `KEY=value` como variáveis exportadas | Ponto de encontro mínimo entre bash e o formato; sem dependências extras |
| `${BASH_SOURCE[0]}` | bash 3.2+ | Localizar o catálogo a partir do próprio script | Self-contained: nenhum argumento novo de path; funciona em qualquer cwd |
| `${VAR:?message}` | POSIX parameter expansion | Fail-closed em chave ausente com mensagem nomeando a chave | Compatível com `set -euo pipefail`; a mensagem vai para stderr e o processo termina |
| `: ${VAR:?message}` | POSIX null command + expansion | Verificação up-front de todas as chaves no topo do script | Permite falhar na inicialização, não na metade da geração |
| Heredoc sem quoting (`<<EOF`) | bash | Expansão de variáveis de catálogo no bloco de saída | Padrão já usado nos scripts; variáveis expandem por default |
| `printf '%s\n' "${VAR}"` | coreutils | Expansão de variável de catálogo em printf | Já usado nos scripts; substituir literal por `${VAR}` |
| `templates/lang/en.lang` | arquivo de texto | Catálogo `en` com chaves namespaced | Formato `KEY='value'` com aspas simples para valores com espaços/especiais |

**Nenhuma instalação:** zero pacotes novos. Os arquivos `.lang` são criados pela fase.

### Formato do arquivo `.lang`

```bash
# templates/lang/en.lang — catálogo en, UTF-8 sem BOM
# Valores byte-idênticos às strings hardcoded atuais

# cadeia MkDocs + index (generate-mkdocs.sh, generate-index.sh)
site_name_suffix='— Specifications'
site_description='Auto-generated documentation from spec-driven development'
nav_home='Home'
index_tagline='Auto-generated documentation from spec-driven development sessions.'
```

Regras do formato (todas `[ASSUMED]` para o parser bash, mas consistentes com todos os scripts existentes do projeto):
- `KEY=value` sem espaços ao redor do `=`
- Valores com espaços, pontuação ou caracteres UTF-8 entre aspas simples (`'`)
- Aspas simples literais no valor: usar a sequência `'\''` (fechar, inserir aspas, reabrir)
- Sem expansão de variável no valor (aspas simples inibem expansão)
- UTF-8 sem BOM (consistente com todos os scripts existentes)
- Comentários iniciados com `#` (ignorados pelo `source`/`.`)

---

## Inventário Completo de Chrome — Phase 2 Scope

> Fonte canônica: `docs/chrome-inventory.md` (auditado contra scripts @ commit `11d2b7a`).
> Esta seção é a referência de implementação. Os valores abaixo foram verificados contra os fontes vivos nesta sessão.

### Camada 1 — `generate-index.sh` (chaves de catálogo)

| Chave | Valor `en` verbatim | Linha(s) | Tipo de uso |
|-------|---------------------|----------|-------------|
| `site_name_suffix` | `— Specifications` | :32 | heredoc (`# $PROJECT_NAME — ${site_name_suffix}`) |
| `index_tagline` | `Auto-generated documentation from spec-driven development sessions.` | :34 | heredoc (`> ${index_tagline}`) |
| `label_project_overview` | `Project Overview` | :41, :49, :56 | `link()` e tabela Overview |
| `label_architecture` | `Architecture` | :42, :58 | `link()` e tabela Overview |
| `label_stack` | `Stack` | :43 | `link()` |
| `label_conventions` | `Conventions` | :44 | `link()` |
| `section_quick_start` | `## Quick Start` | :45 | `printf '%s\n'` |
| `label_roadmap` | `Roadmap` | :50, :57 | `link()` e tabela Overview |
| `label_state_decisions` | `State & Decisions` | :51 | `link()` |
| `section_overview` | `## Overview` | :52, :60 | `printf '%s\n'` (dois ramos) |
| `table_section` | `Section` | :60 | cabeçalho de tabela |
| `table_description` | `Description` | :60 | cabeçalho de tabela |
| `desc_project_overview` | `Vision, goals, and scope` | :56 | célula de tabela Overview |
| `desc_roadmap` | `Features and milestones` | :57 | célula de tabela Overview |
| `desc_architecture` | `System architecture` | :58 | célula de tabela Overview |
| `section_features` | `## Features` | :73 | `printf '%s\n'` |
| `table_feature` | `Feature` | :73 | cabeçalho de tabela |
| `table_spec` | `Spec` | :73, :81 | cabeçalho e link text |
| `table_design` | `Design` | :73, :82 | cabeçalho e link text |
| `table_tasks` | `Tasks` | :73, :83 | cabeçalho e link text |
| `section_architecture` | `## Architecture` | :90 | `printf '%s\n'` |
| `index_architecture_body` | `Refer to the [Architecture](specs/codebase/ARCHITECTURE.md) document for system design and component relationships.` | :90 | `printf '%s\n'` |
| `section_getting_started` | `## Getting Started` | :95 | `printf '%s\n'` |
| `index_getting_started_body` | `For installation instructions, see the [Project Overview](specs/project/PROJECT.md).` | :95 | `printf '%s\n'` |
| `label_setup_guide` | `Setup Guide` | :100 | `link()` |
| `label_contributing` | `Contributing` | :101 | `link()` |
| `section_development` | `## Development` | :102 | `printf '%s\n'` |
| `generated_by` | `Generated by [md-to-wiki](https://github.com/abertanha/md-to-wiki-docs-skills) — %s` | :105 | `printf -- "---\n*${generated_by}*\n" "$(date +%Y-%m-%d)"` |

**Nota sobre `generated_by`:** O `%s` no valor é um format specifier de `printf`. A substituição funciona porque o valor expandido via `"${generated_by}"` se torna o format string do printf. `[VERIFIED: scripts/generate-index.sh:105]` — linha exata: `printf -- '---\n*Generated by [md-to-wiki](https://github.com/abertanha/md-to-wiki-docs-skills) — %s*\n' "$(date +%Y-%m-%d)" >> "$OUTPUT"`.

**Nota sobre `desc_*`:** Três chaves de descrição de linha (`desc_project_overview`, `desc_roadmap`, `desc_architecture`) não têm nome na seed do glossário do `CLAUDE.md`, mas são chrome hardcoded coberto pelo CHROME-01. O planner deve criar as chaves ou justificar a exclusão. `[ASSUMED]` — a seed não nomeia explicitamente.

### Camada 1 — `generate-mkdocs.sh` (chaves de catálogo)

| Chave | Valor `en` verbatim | Linha | Tipo de uso |
|-------|---------------------|-------|-------------|
| `site_name_suffix` | `— Specifications` | :43 | heredoc YAML (`site_name: $PROJECT_NAME ${site_name_suffix}`) |
| `site_description` | `Auto-generated documentation from spec-driven development` | :44 | heredoc YAML |
| `nav_home` | `Home` | :59 | heredoc YAML (`- ${nav_home}: index.md`) |

**Nota:** `site_name_suffix` é compartilhada entre os dois scripts — mesma chave, mesmo valor. `[VERIFIED: scripts/generate-index.sh:32, scripts/generate-mkdocs.sh:43]`

### Camada 3 — `templates/swagger-ui.html`

| Chave | Valor `en` verbatim | Linha | Tipo de uso |
|-------|---------------------|-------|-------------|
| `swagger_title_suffix` | `API Docs` | :6 | `<title>{{PROJECT_NAME}} — API Docs</title>` |

**Escopo Phase 2:** A substituição no template swagger ocorre via `sed` nos agents (não via shell sourcing). A Phase 2 PODE deixar o swagger fora do escopo de script (apenas `generate-index.sh` e `generate-mkdocs.sh` são citados nos requisitos). O planner deve confirmar escopo. `[ASSUMED]`

### Passthrough — NÃO são chaves de catálogo

| Localização | Código verbatim | O que produz |
|-------------|-----------------|--------------|
| `generate-index.sh:79` | `name=$(basename "$dir" \| sed 's/-/ /g; s/\b\(.\)/\u\1/g')` | Label de feature (ex: `Autenticação`, `Login`) |
| `generate-mkdocs.sh:29` | `label=$(basename "$dir" \| sed 's/-/ /g; s/\b\(.\)/\u\1/g')` | Label de seção de nav (ex: `Features`, `Codebase`) |
| `generate-mkdocs.sh:35` | `file_label=$(basename "$file" .md \| sed 's/-/ /g; s/\b\(.\)/\u\1/g')` | Label de arquivo de nav (ex: `ARCHITECTURE`, `PROJECT`) |

`[VERIFIED: scripts/generate-index.sh:79, scripts/generate-mkdocs.sh:29,35]` — lidos integralmente nesta sessão.

Estes sítios usam sed title-case que corrompe acentos em locale C (documentado em `tests/fixtures/manifest.md`). O harness pina `LC_ALL=C.UTF-8` para evitar a corrupção. A Phase 2 NÃO toca esses sítios.

---

## Architecture Patterns

### System Architecture Diagram

```
Dispatch prompt ($OUTPUT_LANG=en)
        │
        ▼
scripts/generate-mkdocs.sh <PROJECT_NAME> <SOURCES> <OUTPUT_LANG>
scripts/generate-index.sh  <PROJECT_NAME> <AUDIENCE> <OUTPUT_LANG> [feature_dirs]
        │
        ▼ (topo do script)
[validate OUTPUT_LANG] → [locate CATALOG via ${BASH_SOURCE[0]}]
        │
        ├─ catalog file missing → ERROR: unsupported language (exit 1)
        │
        ▼
[set -a; . catalog; set +a]
        │
        ▼
[up-front key check: : ${KEY:?msg} per required key]
        │
        ├─ key missing → ERROR: key KEY not found in catalog (exit 1, names the key)
        │
        ▼
[generation: heredocs + printf with ${CATALOG_VAR}]
        │
        ▼
mkdocs.yml / docs/index.md
        │
        ▼
tests/regress.sh (OUTPUT_LANG=en) → diff -r golden/ fresh/ → PASS/FAIL
```

### Recommended Project Structure (adições desta fase)

```
templates/
├── lang/           # novo — catálogo de labels por idioma
│   └── en.lang     # catálogo en, UTF-8 sem BOM, KEY='value'
├── index.md        # unconsumed — decisão de uso-ou-remoção desta fase
└── swagger-ui.html # sem mudança (ou adição de {{SWAGGER_TITLE_SUFFIX}})
scripts/
├── generate-index.sh   # refatorado — carrega catálogo, zero hardcoded
└── generate-mkdocs.sh  # refatorado — carrega catálogo, zero hardcoded
tests/
└── regress.sh      # atualizado — passa OUTPUT_LANG=en explicitamente
```

### Pattern 1: Carregamento do catálogo (topo do script)

```bash
# Catalog bootstrap — must run before any chrome variable is referenced
OUTPUT_LANG="${3:-}"  # position depends on script signature (see Open Questions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATALOG="${SCRIPT_DIR}/../templates/lang/${OUTPUT_LANG}.lang"
[ -f "$CATALOG" ] || {
  echo "ERROR: unsupported language '${OUTPUT_LANG}' — supported: en, pt-br" >&2
  exit 1
}
set -a
. "$CATALOG"
set +a

# Up-front fail-closed check for every key this script uses
: ${site_name_suffix:?key site_name_suffix not found in catalog}
: ${site_description:?key site_description not found in catalog}
: ${nav_home:?key nav_home not found in catalog}
# ... (one line per key this script uses)
```

`[ASSUMED]` — padrão bash padrão, não verificado via ferramenta de documentação externa nesta sessão.

### Pattern 2: Substituição em heredoc

**Antes (hardcoded):**
```bash
cat > "$OUTPUT" <<EOF
# $PROJECT_NAME — Specifications

> Auto-generated documentation from spec-driven development sessions.

EOF
```

**Depois (catálogo):**
```bash
cat > "$OUTPUT" <<EOF
# $PROJECT_NAME ${site_name_suffix}

> ${index_tagline}

EOF
```

A expansão de variável ocorre naturalmente em heredocs sem quoting (`<<EOF`, não `<<'EOF'`). `[ASSUMED]` — comportamento padrão bash.

### Pattern 3: Substituição em printf

**Antes:**
```bash
printf '## Overview\n\n| Section | Description |\n|---------|-------------|\n%s\n' "$rows" >> "$OUTPUT"
```

**Depois:**
```bash
printf '%s\n\n| %s | %s |\n|---------|-------------|\n%s\n' \
  "${section_overview}" "${table_section}" "${table_description}" "$rows" >> "$OUTPUT"
```

### Pattern 4: Verificação do fail-closed (teste de CHROME-03)

Para verificar CHROME-03, o planner deve incluir uma task de teste manual:
1. Comentar ou remover uma chave de `en.lang`
2. Executar o script e observar erro nomeando a chave: `generate-index.sh: line N: site_name_suffix: key site_name_suffix not found in catalog`
3. Restaurar a chave e verificar execução bem-sucedida

### Pattern 5: Invocação canônica atualizada (regress.sh)

**Antes (Phase 1):**
```bash
bash "$SCRIPTS/generate-mkdocs.sh" TestProject .specs
bash "$SCRIPTS/generate-index.sh" TestProject general docs/specs/features
```

**Depois (Phase 2):**
```bash
bash "$SCRIPTS/generate-mkdocs.sh" TestProject .specs en
bash "$SCRIPTS/generate-index.sh" TestProject general en docs/specs/features
```

`[ASSUMED]` — posição dos args sujeita à decisão do planner (ver Open Questions).

### Anti-Patterns a Evitar

- **Heredoc com quoting (`<<'EOF'`):** variáveis de catálogo NÃO expandem em heredocs com aspas — o quoting bloqueia toda expansão. Todos os heredocs existentes já usam `<<EOF` sem quotes. Não introduzir `<<'EOF'` para bloco que contenha variáveis de catálogo.
- **Carregamento lazy de catálogo:** não verificar chaves apenas na hora do uso — o script pode falhar na metade, deixando saída parcial. Verificação up-front no topo.
- **`export` individual:** não exportar cada variável individualmente com `export KEY=value` — usar `set -a; . file; set +a` que exporta todas de uma vez.
- **`sed '\u'` no chrome:** não capitalizar nenhuma variável de catálogo via sed (corrompe acentos em locale C). As chaves são pré-capitalizadas no `.lang`.
- **Valores sem quoting no `.lang`:** valores com espaços, em dash (`—`), brackets ou outros caracteres devem estar entre aspas simples. Sem quoting, `set -a; . file` pode interpretar espaços como separadores.
- **`BASH_SOURCE` sem `cd`:** usar `cd "$(dirname "${BASH_SOURCE[0]}")" && pwd` — não apenas `dirname`, que pode retornar path relativo.

---

## Don't Hand-Roll

| Problema | Não construir | Usar em vez | Por quê |
|----------|--------------|-------------|---------|
| Detecção de locale | Lógica de fallback baseada em `$LANG`/`$LC_ALL` | `OUTPUT_LANG` explícito via arg | Imprevisível e rejeitado no questioning; conflita com `OUTPUT_LANG` |
| Compilação de catálogo | Script de pré-processamento dos `.lang` | `set -a; . file; set +a` inline | Zero overhead; bash sourcing é o mecanismo mínimo |
| Interpolação de template | Engine de template (envsubst, Jinja, etc.) | `${VAR}` em heredoc/printf | Sem dependência nova; padrão bash nativo |
| Parser de KEY=value | Lógica custom de parsing | `set -a; . file; set +a` | O shell já faz o parse; qualquer parser custom vai ter bugs |
| Catalog fallback para `en` | Lógica de fallback silencioso | Erro explícito com nome da chave | Fallback silencioso é exatamente o mecanismo de saída mista (proibido) |

---

## Common Pitfalls

### Pitfall 1: Valor com espaços não quotado no `.lang` quebra sourcing

**O que vai errado:** `site_name_suffix=— Specifications` (sem quotes) faz o shell interpretar `Specifications` como um comando separado na expansão. O sourcing falha ou atribui valor incorreto.

**Por que acontece:** `set -a; . file` executa o arquivo como shell commands; valores sem quotes sofrem word-splitting.

**Como evitar:** Sempre aspas simples em valores com espaços ou especiais: `site_name_suffix='— Specifications'`.

**Warning signs:** Erro `command not found: Specifications` durante o sourcing do catálogo.

### Pitfall 2: Regressão quebra por valor diferente da hardcoded

**O que vai errado:** O valor em `en.lang` é redigitado (não copiado verbatim), introduzindo diferença sutil (espaço extra, capitalização diferente, aspas diferentes no markdown).

**Por que acontece:** A distância entre a seed do glossário em `CLAUDE.md` e os scripts reais. O inventário `docs/chrome-inventory.md` diz "scripts vencem".

**Como evitar:** Copiar os valores EXCLUSIVAMENTE dos scripts lidos linha a linha, não da seed. O chrome-inventory é a referência, não a seed.

**Warning signs:** `diff` na regressão aponta divergência em linha que contém label.

### Pitfall 3: `BASH_SOURCE` vazio em contexto não-bash

**O que vai errado:** Se o script for chamado como `sh script.sh` em vez de `bash script.sh`, `BASH_SOURCE` é indefinido e a localização do catálogo falha.

**Por que acontece:** `BASH_SOURCE` é extensão bash, não POSIX.

**Como evitar:** Os scripts já usam `#!/usr/bin/env bash` e `set -euo pipefail`. O harness chama explicitamente `bash "$SCRIPTS/..."`. Não mudar o shebang.

**Warning signs:** Erro `BASH_SOURCE: unbound variable` com `set -u`.

### Pitfall 4: Heredoc com catálogo cria diff por espaço trailing no mkdocs.yml

**O que vai errado:** O golden `mkdocs.yml` tem wart documentado: `repo_url: ` (espaço trailing quando cwd é git-free). Se a refatoração do heredoc remover esse espaço, a regressão quebra.

**Por que acontece:** O golden foi capturado com `repo_url` vazia e o heredoc emite o espaço. Editores "clean up" silenciosamente.

**Como evitar:** Não "consertar" o heredoc de `repo_url`. Manter exatamente como está: `repo_url: $repo_url`. Verificar regressão após cada mudança no heredoc.

**Warning signs:** `diff` aponta `< repo_url:` vs `> repo_url: `.

### Pitfall 5: `generated_by` com `%s` e printf — dupla interpretação

**O que vai errado:** `generated_by='Generated by ... — %s'`; se o printf for chamado como `printf -- '%s*\n' "${generated_by}"` (usando `%s` para a variável), o `%s` dentro do valor não é interpretado como format specifier — e a data não aparece.

**Por que acontece:** O `%s` no valor só atua como format specifier quando o valor expandido é o próprio format string do printf.

**Como evitar:** O padrão correto é usar o valor como format string: `printf -- "---\n*${generated_by}*\n" "$(date +%Y-%m-%d)"` — o `%s` no valor expandido é interpretado pelo printf como specifier para a data.

**Warning signs:** Saída mostra `%s` literal no rodapé em vez da data.

### Pitfall 6: Verificação up-front lista apenas subconjunto de chaves

**O que vai errado:** O gate up-front verifica 5 das 10 chaves; uma chave não verificada está ausente no catálogo e o script emite saída parcial ou string vazia antes de falhar.

**Por que acontece:** O up-front gate foi construído manualmente e ficou desatualizado.

**Como evitar:** O gate up-front deve cobrir TODAS as chaves que o script acessa. Uma task de revisão deve confirmar completude por comparação com as substituições no código.

**Warning signs:** Regressão passa, mas saída tem campo vazio (variável expandida para string vazia com `set +u` acidental).

---

## Mecanismo de Regressão — Detalhes Verificados

`[VERIFIED: tests/regress.sh:1-195]` — lido integralmente nesta sessão.

### O que o `regress.sh` compara

```
run_chain() → mkdocs.yml + docs/ + specs-book.pdf + swagger/index.html
    ↓
mask_copy() → aplica MASK='s/[0-9]{4}-[0-9]{2}-[0-9]{2}/__DATE__/g' em cópias tmp (golden E fresh)
    ↓
compare_surface() → diff -r masked_golden/ masked_fresh/ → PASS ou FAIL
```

A máscara é aplicada **simetricamente**: cópias em `/tmp` de ambos os lados são mascaradas antes do diff. O golden é armazenado bruto (data da captura). Sítios datados cobertos: `generate-index.sh:105` (único na cadeia `.sh` para este escopo).

### Invocação atual no harness (Phase 1)

`[VERIFIED: tests/regress.sh:76-77]`
```bash
bash "$SCRIPTS/generate-mkdocs.sh" TestProject .specs
bash "$SCRIPTS/generate-index.sh" TestProject general docs/specs/features
```

### Invocação necessária após Phase 2

A posição de `OUTPUT_LANG` nos args deve ser determinada pelo planner. Exemplo com argumento no final dos fixos (recomendação desta research):

```bash
bash "$SCRIPTS/generate-mkdocs.sh" TestProject .specs en
bash "$SCRIPTS/generate-index.sh" TestProject general en docs/specs/features
```

### Warts preservados nos goldens

`[VERIFIED: tests/fixtures/golden-sh/mkdocs/mkdocs.yml:3]`
- `repo_url: ` — espaço trailing após repo_url vazia quando cwd é git-free. O wart é o comportamento atual congelado; a refatoração NÃO pode removê-lo.
- Linha em branco final do heredoc do `mkdocs.yml` (linha 30 do golden). Idem.

---

## Política `templates/index.md` (Unconsumed)

`[VERIFIED: docs/chrome-inventory.md:72-74]` — trecho verbatim:

> Nota sobre `templates/index.md` (D-12): grep em `agents/`, `scripts/`, `SKILL.md` e `CONTEXT.md` não encontra nenhum consumidor — o `generate-index.sh` usa heredoc próprio (Camada 1). O template é um paralelo morto: a Phase 2 extrai os valores `en` **dos scripts** (fonte viva), nunca daqui. Decidir usar-ou-remover o template é decisão da Phase 2, fora do escopo deste inventário.

**Recomendação desta research:** Remover `templates/index.md`. Manter o template paralelo cria confusão sobre a fonte de verdade. Os scripts usam heredoc próprio e continuarão usando após a refatoração. A remoção simplifica a arquitetura sem risco — o arquivo não tem consumidor.

O planner pode confirmar ou diferir esta decisão. Se diferir, documenta como tech debt.

---

## Arquivos Modificados / Criados nesta Fase

| Arquivo | Tipo | Operação |
|---------|------|----------|
| `templates/lang/en.lang` | novo | criar — 27+ chaves de catálogo |
| `scripts/generate-index.sh` | existente | refatorar — carregar catálogo, substituir ~27 hardcoded |
| `scripts/generate-mkdocs.sh` | existente | refatorar — carregar catálogo, substituir 3 hardcoded |
| `tests/regress.sh` | existente | atualizar — passar `OUTPUT_LANG=en` nas invocações |
| `agents/format-mkdocs.md` | existente | atualizar — passar `$OUTPUT_LANG` nas chamadas dos scripts |
| `templates/index.md` | existente | remover (se planner confirmar) ou marcar como tech debt |
| `templates/lang/pt-br.lang` | FORA DO ESCOPO | Phase 3 |

**Nota sobre `agents/format-mkdocs.md`:** `[VERIFIED: agents/format-mkdocs.md:26,34]` — chamadas atuais:
```
$SCRIPT_RUNNER "$SKILL_DIR/scripts/generate-mkdocs$SCRIPT_EXT" "$PROJECT_NAME" "$SOURCES"
$SCRIPT_RUNNER "$SKILL_DIR/scripts/generate-index$SCRIPT_EXT" "$PROJECT_NAME" "$AUDIENCE" docs/specs/features
```
Após Phase 2, adicionar `$OUTPUT_LANG` na posição determinada pelo planner.

---

## Assumptions Log

| # | Claim | Section | Risco se errado |
|---|-------|---------|----------------|
| A1 | `set -a; . file; set +a` é o mecanismo de carregamento adequado para `KEY=value` com valores quotados em aspas simples | Standard Stack | Baixo — padrão consagrado; mas valores com aspas simples literais precisam da sequência `'\''` |
| A2 | `${VAR:?message}` funciona corretamente com `set -euo pipefail` para fail-closed nomeando a chave | Standard Stack | Baixo — comportamento POSIX bem documentado |
| A3 | `${BASH_SOURCE[0]}` dá o path correto do script para localizar `templates/lang/` | Architecture Patterns | Médio — verdadeiro quando chamado via `bash path/to/script.sh`; pode falhar com symlinks complexos; o harness usa path absoluto, então ok |
| A4 | Posição de `OUTPUT_LANG` como terceiro arg em `generate-index.sh` e último fixo em `generate-mkdocs.sh` não quebra chamadas existentes dos agents | Architecture Patterns | Médio — `agents/format-mkdocs.md` precisa ser atualizado junto; o planner confirma |
| A5 | Os três `desc_*` (descrições de linha na tabela Overview) são chrome coberto pelo CHROME-01 e precisam de chaves de catálogo | Inventário de Chrome | Médio — o inventário os lista sem chaves nomeadas; o planner decide incluir ou excluir |
| A6 | `templates/index.md` não tem nenhum consumidor e pode ser removido | Política templates/index.md | Baixo — verificado por grep no inventário; remoção é reversível via git |
| A7 | O Swagger (`templates/swagger-ui.html`) está fora do escopo de script desta fase (a substituição ocorre via sed nos agents, não via shell sourcing) | Inventário de Chrome | Médio — CHROME-01 diz "todo chrome"; planner confirma escopo |

---

## Open Questions

1. **Posição de `OUTPUT_LANG` nos argumentos dos scripts**
   - O que sabemos: os scripts têm assinaturas com posicionais fixos mais variadicos; `generate-index.sh` tem `<project_name> <audience> [feature_dirs...]`; `generate-mkdocs.sh` tem `[project_name] [specs_dir]`
   - O que está indefinido: a posição exata de `OUTPUT_LANG` — antes dos variadicos (recomendado), como env var ad-hoc (rejeitado pelo CONTEXT.md), ou como named flag `--lang`
   - Recomendação: adicionar como terceiro fixo antes dos variadicos em `generate-index.sh` (`<project_name> <audience> <output_lang> [feature_dirs...]`) e como terceiro opcional em `generate-mkdocs.sh` (`[project_name] [specs_dir] [output_lang]`). Atualizar `regress.sh` e `agents/format-mkdocs.md` consistentemente.

2. **Escopo do Swagger nesta fase**
   - O que sabemos: `templates/swagger-ui.html` tem chrome (`API Docs` em `swagger_title_suffix`); a substituição atual é via sed nos agents; CHROME-01 diz "todo chrome"; os scripts desta fase são `generate-index.sh` e `generate-mkdocs.sh`
   - O que está indefinido: se o Swagger deve ser incluído no `en.lang` desta fase (mesmo sem mudar o mecanismo de substituição) ou diferido para Phase 3
   - Recomendação: incluir a chave `swagger_title_suffix` no `en.lang` para completar o catálogo `en`; adiar a refatoração do mecanismo de substituição do template para Phase 3

3. **Três chaves `desc_*` (descrições de Overview)**
   - O que sabemos: `Vision, goals, and scope`, `Features and milestones`, `System architecture` são strings hardcoded em `generate-index.sh:56-58`; a seed não as nomeia; o inventário as lista sem chaves
   - O que está indefinido: se o planner as inclui no catálogo (CHROME-01 exige "todo chrome") ou as considera fora do escopo da seed
   - Recomendação: incluir com chaves `desc_project_overview`, `desc_roadmap`, `desc_architecture` para cumprir CHROME-01 integralmente

---

## Environment Availability

| Dependência | Requerida por | Disponível | Versão | Fallback |
|-------------|--------------|-----------|--------|---------|
| bash | scripts, harness | ✓ | 5.2.21 | — |
| diff (GNU) | regress.sh | ✓ | 3.10 | — |
| sed (GNU) | máscara de data, harness | ✓ | 4.9 | — |
| `templates/lang/` | scripts refatorados | ✗ (criado nesta fase) | — | — |
| pandoc | perna DokuWiki do harness | ✓ | 3.7.0.2 | SKIPPED exit 3 |
| pwsh | perna .ps1 do harness | ✗ | — | SKIPPED exit 3 |

**Dependências ausentes sem fallback:** nenhuma (a única ausente, `templates/lang/`, é criada pela própria fase).

**Estado atual do harness:** `bash tests/regress.sh` passa com exit 3 (mkdocs OK, pdf OK, swagger OK, dokuwiki OK, pwsh SKIPPED) — `[VERIFIED: executado nesta sessão]`.

---

## Security Domain

> `security_enforcement: true` na config. Aplicável ao escopo desta fase.

### Applicable ASVS Categories (ASVS Level 1)

| ASVS Category | Aplica | Controle padrão |
|---------------|--------|----------------|
| V5 Input Validation | sim (limitado) | `OUTPUT_LANG` validado contra allowlist `en`\|`pt-br` antes do uso; erro explícito para valor desconhecido |
| V2 Authentication | não | Geração local de arquivos estáticos |
| V3 Session Management | não | Scripts stateless |
| V4 Access Control | não | Scripts sem usuário |
| V6 Cryptography | não | Nenhuma operação criptográfica |

### Known Threat Patterns

| Pattern | STRIDE | Mitigação padrão |
|---------|--------|-----------------|
| Path traversal via `OUTPUT_LANG` arg | Tampering | `CATALOG` path construído com `${BASH_SOURCE[0]}` e `OUTPUT_LANG` validado contra allowlist antes de construir o path; `[ -f "$CATALOG" ]` como segunda barreira |
| Injeção via valor do `.lang` (code injection) | Tampering | Arquivo `.lang` é commitado e versionado; `set -a; . file` executa o arquivo como shell — arquivo malicioso pode executar código. Mitigação: o arquivo está no repositório controlado; não aceitar `.lang` de input externo |
| Expansão de variável não-tratada | Information Disclosure | Usar `"${VAR}"` (com quotes) em todos os usos; `set -u` captura variáveis não declaradas |

**Nota:** O risco de path traversal é mitigado porque `OUTPUT_LANG` é validado contra `en|pt-br` antes de construir `CATALOG`. A construção `${SCRIPT_DIR}/../templates/lang/${OUTPUT_LANG}.lang` com `OUTPUT_LANG` validated não permite escape do diretório.

---

## Sources

### Primary (HIGH confidence — verificado por leitura direta dos arquivos nesta sessão)

- `docs/chrome-inventory.md` (lido integralmente) — inventário completo de chrome com valores verbatim e sítios `arquivo:linha`
- `scripts/generate-index.sh` (lido integralmente, 108 linhas) — fonte viva dos valores `en` e sítios de substituição
- `scripts/generate-mkdocs.sh` (lido integralmente, 64 linhas) — fonte viva dos valores `en` e sítios de substituição
- `tests/regress.sh` (lido integralmente, 195 linhas) — mecanismo de regressão, máscara de data, invocações canônicas
- `tests/fixtures/golden-sh/mkdocs/mkdocs.yml` (lido) — confirma warts preservados
- `tests/fixtures/golden-sh/mkdocs/docs/index.md` (lido via Bash) — confirma saída atual byte-exata
- `tests/fixtures/manifest.md` (lido integralmente) — documentação de warts, locale pins, invocação canônica
- `CONTEXT.md` (lido integralmente) — política de `OUTPUT_LANG`, script-call convention
- `agents/format-mkdocs.md` (lido até linha 40) — invocações atuais dos scripts pelos agents
- `templates/swagger-ui.html` (lido) — chrome da Camada 3
- `templates/index.md` (lido) — confirma status "unconsumed"
- `tests/regress.sh` executado nesta sessão — saída confirmada: mkdocs OK, pdf OK, swagger OK, dokuwiki OK, exit 3 (pwsh SKIPPED)

### Secondary (MEDIUM confidence — conhecimento de treinamento, padrões bash)

- Padrão `set -a; . file; set +a` — padrão bash/POSIX consagrado `[ASSUMED]`
- `${VAR:?message}` + `set -euo pipefail` — comportamento POSIX `[ASSUMED]`
- `${BASH_SOURCE[0]}` para auto-localização do script — extensão bash `[ASSUMED]`

---

## Metadata

**Confidence breakdown:**
- Chrome inventory: HIGH — valores lidos verbatim dos fontes vivos
- Mecanismo de carregamento: MEDIUM — padrão bash padrão, não verificado via doc externa nesta sessão
- Mecanismo de regressão: HIGH — harness lido e executado
- Posição de args (Open Question 1): MEDIUM — recomendação lógica, planner confirma

**Research date:** 2026-09-29
**Valid until:** 90 dias (bash é estável; os scripts não devem mudar fora desta fase)
