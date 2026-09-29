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

The output language is normalized case-insensitively on input (`pt-br` ≡ `pt-BR`) and projected per consumer: `pt-BR` for MkDocs Material `theme.language`, pandoc `-M lang`, and the HTML `lang` attribute; `pt_BR` for Pyphen hyphenation — the projection happens in one table at the point of use. An unknown value fails closed: stop and list the supported values (`en`, `pt-br`); enforcement in scripts is a later phase, the contract records the decision now. Labels live in `templates/lang/*.lang` files in `KEY=value` format, UTF-8 without BOM (implemented in a later phase); a key missing from the catalog also fails closed, naming the missing key — never a silent fallback, which is how mixed-language output happens. Swagger scope is the page title and the `lang` attribute only: the upstream Swagger UI bundle has no official i18n and its chrome stays English — a documented limit. Dates are ISO 8601 in both languages, and the scripts' progress console remains in English (it is not published output).

Authority: `docs/chrome-inventory.md` — the map of chrome keys to their current `en` values and sites lives there; this file does not restate keys.

Note: `MDW_INDEX_OUT` (read by `scripts/generate-index.sh:19`) is a pre-existing output-path environment variable, not a pattern to follow — `OUTPUT_LANG` never reads from the environment; it is assigned during onboarding and passed via dispatch prompt like every other variable.

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
