# CONTEXT — md-to-wiki domain reference

The single external home for the vocabulary and conventions every agent of this skill shares. When a variable, convention, or dependency question arises during a run, consult this file rather than improvising. Change a meaning here — the agents reference it, they do not restate it.

## Variables

Set once during onboarding (assignment logic lives in `agents/onboarding.md` — the single mechanism). The orchestrator passes these values inside the dispatch prompt when launching a format agent; nothing relies on environment propagation.

| Variable | Meaning | Values |
|----------|---------|--------|
| `SKILL_DIR` | Absolute path to this skill's folder | any absolute path |
| `OS_TYPE` | Host platform class | `unix` \| `windows` |
| `SCRIPT_EXT` | Companion-script extension for this host | `.sh` \| `.ps1` |
| `SCRIPT_RUNNER` | Prefix that executes a companion script | empty \| `powershell -File` |
| `PROJECT_NAME` | Confirmed project name | free text |
| `SOURCES` | Root directory of the specs tree — one directory | e.g. `.specs/` |
| `AUDIENCE` | Who reads the output | `developer` \| `stakeholder` \| `general` |
| `OUTPUT_LANG` | Output language of published chrome | `en` \| `pt-br` (default `pt-br`; normalize case-insensitively on input — `pt-BR` ≡ `pt-br`) |
| `FORMAT` | Chosen output format | one route name from SKILL.md |

`OS_TYPE`, `SCRIPT_EXT`, and `SCRIPT_RUNNER` are coupled: they are assigned together by the OS detection case, never mixed independently.

## Output language policy

The output language is normalized case-insensitively on input (`pt-br` ≡ `pt-BR`) and projected per consumer: `pt-BR` for MkDocs Material `theme.language`, pandoc `-M lang`, and the HTML `lang` attribute; `pt_BR` for Pyphen hyphenation — the projection happens in one table at the point of use. An unknown value fails closed: stop and list the supported values (`en`, `pt-br`); enforcement in scripts is live in both the `.sh` and the `.ps1` twins. Labels live in `templates/lang/*.lang` files in `KEY=value` format, UTF-8 without BOM; a key missing from the catalog also fails closed, naming the missing key — never a silent fallback, which is how mixed-language output happens. The `.ps1` companions read the same catalog through the shared loader `scripts/lib/catalog.ps1`, and every byte they write is UTF-8 without BOM. Swagger scope is the page title and the `lang` attribute only: the upstream Swagger UI bundle has no official i18n and its chrome stays English — a documented limit. Dates are ISO 8601 in both languages, and the scripts' progress console remains in English (it is not published output).

Authority: `docs/chrome-inventory.md` — the map of chrome keys to their current `en` values and sites lives there; this file does not restate keys.

Note: `MDW_INDEX_OUT` (read by `scripts/generate-index.sh:19`) is a pre-existing output-path environment variable, not a pattern to follow — `OUTPUT_LANG` never reads from the environment; it is assigned during onboarding and passed via dispatch prompt like every other variable.

## Glossário anti-calque

Consequência direta da política acima: quando `OUTPUT_LANG` é `pt-br`, a prosa autoral que os
agents escrevem em runtime (não o chrome vindo do catálogo) segue este glossário. A denylist
executável que DECIDE o gate mora em `tests/no-calques.sh` — esta seção é a fonte da REGRA, o
script é a fonte do PREDICADO; não restate a lista em terceiro lugar.

A denylist e a allowlist abaixo ficam dentro da região delimitada pelos dois comentários que
seguem, porque o próprio gate remove essa região antes de varrer (sem isso, o glossário — que
precisa citar os calques para proibi-los — reprovaria a si mesmo). Qualquer prosa nova sobre
calque entra DENTRO desta região.

<!-- no-calques:ignore-start -->

**Denylist — verbos anglicizados sem registro no VOLP.** Para cada um, a forma a usar:
`deployar` → implantar ou publicar; `printar` → imprimir; `commitar` → registrar ou confirmar;
`pushear` → enviar; `linkar` → ligar ou referenciar; `buildar` → compilar ou construir;
`debugar` → depurar; `startar` → iniciar; `mergear` → integrar ou incorporar; `upar` → enviar ou
subir. O gate cobre as flexões de cada um (infinitivo, primeira e terceira do pretérito,
gerúndio e particípio, singular e plural).

**Allowlist — formas consagradas que NÃO são calque.** Registradas no VOLP e portanto
permitidas: `checar`, `deletar`, `resetar`, `refatorar`, `acessar`, `escanear`. Termos técnicos
mantidos em inglês integral, nunca aportuguesados: `stack`, `roadmap`, `design`, `deploy`
(substantivo), `build` (substantivo), `commit` (substantivo), `push` (substantivo), `branch`,
`merge` (substantivo), `release`, `wiki`, `spec`, `pull request`. A allowlist é declarada
explicitamente — nunca um default silencioso, mesma disciplina da allowlist do glossário em
`tests/no-mixed-output.sh`.

**Tiques de LLM — banidos junto, mesma porta de completion.** `é importante notar`, `em resumo`,
`convém destacar`, `vale ressaltar`, `vale notar`, `em última análise`. São marcadores de prosa
gerada que não acrescentam informação; o alvo é a prosa, não o autor.

<!-- no-calques:ignore-end -->

**Regra de desempate (D-24, 2026-09-30).** Quando aparecer uma forma nova em dúvida: se o VOLP
registra a forma aportuguesada, ela é consagrada e fica permitida; se não registra, o termo fica
em inglês integral e a forma aportuguesada entra na denylist de `tests/no-calques.sh`. A decisão
é registrada aqui, com a data, para que o gate e a prosa nunca discordem.

**Fronteira de escopo.** O glossário rege o CHROME e a PROSA DE CHROME. O conteúdo dos specs do
usuário nunca é reescrito nem traduzido (Out of Scope do `PROJECT.md`), e os caminhos, nomes de
página, âncoras e nomes de arquivo gerados nunca são traduzidos em nenhum idioma (CHROME-04).

## Script-call convention

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/<name>$SCRIPT_EXT" <args>
```

## Source taxonomy

Authority: `scripts/discover-sources.sh`. The specs tree is categorized by **directory**, not by filename:

```
<SOURCES>/
  project/*.md            # PROJECT.md, ROADMAP.md, STATE.md, …
  codebase/*.md           # ARCHITECTURE.md, STACK.md, CONVENTIONS.md, …
  features/<name>/*.md    # spec.md → design.md → tasks.md per feature
  quick/<name>/*.md       # one directory per quick task
```

`discover-sources.sh <SOURCES> [summary|files|json]` scans exactly this layout. Multi-root input is merged into `merged-specs/` before any format agent runs (see SKILL.md, Execution Flow).

## Dependencies by format

| Format | Requires | Install |
|--------|----------|---------|
| MkDocs Material | `mkdocs`, `mkdocs-material` | `pip install mkdocs mkdocs-material` |
| Swagger / OpenAPI | `node` + `npx` (validation via `@redocly/cli`), or just a browser to view | [nodejs.org](https://nodejs.org) |
| GitHub Wiki | `git`, `gh` (clone helper) | system package manager |
| DokuWiki | `pandoc` | `apt install pandoc` / `brew install pandoc` / [pandoc.org](https://pandoc.org) |
| PDF | `pandoc` + engine (`weasyprint` preferred, `xelatex`/`wkhtmltopdf` fallback) | `pip install weasyprint` / `apt install wkhtmltopdf` |

## Install scopes

| Scope | Path |
|-------|------|
| Global (opencode) | `~/.config/opencode/skills/md-to-wiki/` — symlink to the cloned repo (default target of `scripts/install.sh`) |
| Per project | `.opencode/skills/md-to-wiki/` |
| Cursor | `.cursor/skills/md-to-wiki/` |

Because the global scope is a symlink to the clone, `$SKILL_DIR/.git` exists there — the update path is `scripts/update.sh` (or `git pull` inside the clone).

## Cleanup policy

Ask the orchestrator before deleting any intermediate artifact (`specs-book.md`, `merged-specs/`, cached issues). Companion scripts retain their intermediates so this policy can be honored.
