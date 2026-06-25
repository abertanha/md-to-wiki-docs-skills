# md-to-wiki — Thin Router (Phase 2)

Turn markdown specification files into documentation sites.

**Triggers:** "build wiki", "generate docs", "publish specs", "make a site", "wiki from markdown", "draw diagram", "flow chart", "architecture diagram", "state diagram", "sequence diagram"

## Phase Router

Analyze the user's request to determine which path to take:

```bash
lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
case "$lower" in
  *"not sure"*|*"help"*|*"recommend"*)     ROUTE="onboarding" ;;
  *"html"*|*"site"*|*"mkdocs"*|*"material"*)  ROUTE="mkdocs" ;;
  *"swagger"*|*"openapi"*|*"api"*)          ROUTE="swagger" ;;
  *"github wiki"*|*"wiki tab"*)             ROUTE="github-wiki" ;;
  *"dokuwiki"*|*"doku"*)                    ROUTE="dokuwiki" ;;
  *"pdf"*|*"print"*|*"book"*)               ROUTE="pdf" ;;
  *"reference"*|*"issue"*|*"pr"*|*"pull"*)  ROUTE="references" ;;
  *"deploy"*|*"publish"*|*"go live"*)       ROUTE="deploy" ;;
  *)                                          ROUTE="onboarding" ;;
esac
```

Then launch the appropriate agent:

| Route | Agent | Description |
|-------|-------|-------------|
| `onboarding` | [agents/onboarding.md](./agents/onboarding.md) | Interview user, detect OS, set up SKILL_DIR |
| `mkdocs` | [agents/format-mkdocs.md](./agents/format-mkdocs.md) | Generate MkDocs Material site |
| `swagger` | [agents/format-swagger.md](./agents/format-swagger.md) | Generate OpenAPI 3.0 + Swagger UI |
| `github-wiki` | [agents/format-github-wiki.md](./agents/format-github-wiki.md) | Publish to GitHub Wiki |
| `dokuwiki` | [agents/format-dokuwiki.md](./agents/format-dokuwiki.md) | Convert to DokuWiki format |
| `pdf` | [agents/format-pdf.md](./agents/format-pdf.md) | Generate PDF via Pandoc |
| `references` | [agents/references.md](./agents/references.md) | Enrich docs with GitHub issue/PR references |
| `deploy` | [agents/deploy.md](./agents/deploy.md) | Deploy generated docs to hosting |

## Execution Flow

1. **Onboarding** → Ask questions: project name, source dirs, audience (dev/stakeholder/general), desired format. Detect OS once, store `SKILL_DIR`, `SCRIPT_EXT`, `SCRIPT_RUNNER`.
2. **Format generation** → Load the appropriate format agent. Use companion scripts from `scripts/` with `$SCRIPT_RUNNER`.
3. **References** → If user wants issue/PR references, load [references.md](./agents/references.md).
4. **Deployment** → After generation, load [deploy.md](./agents/deploy.md) to offer hosting.

## Global Variables (set once during onboarding)

- `SKILL_DIR` — resolved path to this skill folder
- `SCRIPT_EXT` — `.sh` or `.ps1`
- `SCRIPT_RUNNER` — `""` or `"powershell -File"`
- `OS_TYPE` — `unix` or `windows`
- `PROJECT_NAME` — from user
- `SOURCES` — paths to spec files
- `AUDIENCE` — `developer`, `stakeholder`, or `general`

## Companion Scripts

All accept positional args identically in `.sh` and `.ps1`:

| Script | Purpose |
|--------|---------|
| `discover-sources` | Scans directories for spec/project/codebase/quick files |
| `generate-mkdocs` | Creates full mkdocs.yml + page structure |
| `generate-index` | Builds audience-appropriate landing page |
| `to-dokuwiki` | Converts markdown → DokuWiki syntax |
| `to-pdf` | Concatenates + converts to PDF via pandoc |
| `fetch-issues` | Caches GitHub issue/PR metadata |

## Multi-Directory Input

Merge multiple source dirs into `merged-specs/` before running:

```bash
mkdir -p merged-specs && cp -r .specs/* docs/* merged-specs/
```

## Sharing

Copy `md-to-wiki/` into colleague's `.config/opencode/skills/` or `.opencode/skills/`. Dependencies vary by format.
