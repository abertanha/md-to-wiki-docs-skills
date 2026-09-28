---
name: md-to-wiki
description: Turn a markdown spec tree into published documentation — MkDocs Material site, OpenAPI spec with Swagger UI, GitHub Wiki, DokuWiki, or PDF book, with optional GitHub issue/PR references and deployment. Use when the user wants to build a docs site, generate documentation, make a wiki, create an OpenAPI/Swagger spec, publish to a GitHub wiki, convert to DokuWiki, compile a PDF book, add issue references, or deploy the docs.
---

# md-to-wiki — Thin Router

Turn markdown specification files into documentation sites.

Shared vocabulary, script conventions, source taxonomy, and per-format dependencies live in [CONTEXT.md](./CONTEXT.md). Consult it before improvising any value or path.

## Phase Router

Execute this block with the user's request as `$1`, then launch the agent the resulting `ROUTE` names:

```bash
lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
case "$lower" in
  *"not sure"*|*"help"*|*"recommend"*)   ROUTE="onboarding" ;;
  *"github wiki"*|*"wiki tab"*)          ROUTE="github-wiki" ;;
  *"dokuwiki"*|*"doku"*)                 ROUTE="dokuwiki" ;;
  *"swagger"*|*"openapi"*|*"api spec"*|*"api doc"*|*"api reference"*)  ROUTE="swagger" ;;
  *"mkdocs"*|*"material"*|*"docs site"*|*"documentation site"*|*"wiki"*|*"site"*|*"html"*)  ROUTE="mkdocs" ;;
  *"pdf"*|*"print"*|*"book"*)            ROUTE="pdf" ;;
  *"issue"*|*"pull request"*|*"pull-request"*|*"reference"*)  ROUTE="references" ;;
  *"deploy"*|*"publish"*|*"go live"*)    ROUTE="deploy" ;;
  *)                                     ROUTE="onboarding" ;;
esac
```

Arm order matters: the specific wiki formats (`github-wiki`, `dokuwiki`) precede the generic `*"wiki"*`/`*"site"*` arm so "github wiki" lands on the right route. The `references` arm matches distinctive phrases only — bare words like "project" or "process" no longer mis-route.

| Route | Agent | Description |
|-------|-------|-------------|
| `onboarding` | [agents/onboarding.md](./agents/onboarding.md) | Interview user, resolve variables, set up run |
| `mkdocs` | [agents/format-mkdocs.md](./agents/format-mkdocs.md) | Generate MkDocs Material site |
| `swagger` | [agents/format-swagger.md](./agents/format-swagger.md) | Generate OpenAPI 3.0 + Swagger UI |
| `github-wiki` | [agents/format-github-wiki.md](./agents/format-github-wiki.md) | Publish to GitHub Wiki |
| `dokuwiki` | [agents/format-dokuwiki.md](./agents/format-dokuwiki.md) | Convert to DokuWiki format |
| `pdf` | [agents/format-pdf.md](./agents/format-pdf.md) | Generate PDF via Pandoc |
| `references` | [agents/references.md](./agents/references.md) | Enrich docs with GitHub issue/PR references |
| `deploy` | [agents/deploy.md](./agents/deploy.md) | Deploy generated docs to hosting |

## Execution Flow

1. **Onboard** — launch [onboarding.md](./agents/onboarding.md). Done when every variable in [CONTEXT.md](./CONTEXT.md) has a confirmed value. If the user names multiple source roots, merge them first: `mkdir -p merged-specs && cp -r <root1>/* <root2>/* merged-specs/` — then `merged-specs/` is `SOURCES`.
2. **Dispatch the format agent** — pass all variables in the dispatch prompt. Done when the agent satisfies its return contract.
3. **References (optional)** — when issue/PR references were requested, launch [references.md](./agents/references.md).
4. **Deploy (optional)** — launch [deploy.md](./agents/deploy.md) to offer hosting.

## Companion Scripts

All are called positionally, identically in `.sh` and `.ps1` (see [CONTEXT.md](./CONTEXT.md) for the call convention):

| Script | Purpose |
|--------|---------|
| `discover-sources` | Scan the specs tree; `summary` (default), `files`, or `json` output |
| `generate-mkdocs` | Build the MkDocs site skeleton (copies specs in, writes `mkdocs.yml` + nav) |
| `generate-index` | Build the audience-appropriate landing page |
| `to-dokuwiki` | Convert markdown → DokuWiki syntax, mirroring the input tree |
| `to-pdf` | Concatenate + convert to PDF via pandoc |
| `fetch-issues` | Cache GitHub issue/PR metadata via `gh` (fallback `curl`) |
