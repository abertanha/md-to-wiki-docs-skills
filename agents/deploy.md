# Deployment — Subagent

Deploy generated documentation to its target. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

## When to activate

After generation, when the user wants the docs hosted.

## Options by format

| Format | Deployment |
|--------|-----------|
| MkDocs Material | GitHub Pages via `mkdocs gh-deploy` (or upload `docs/site/` to any static host) |
| Swagger | Surge on `swagger-ui/` (or any static host) |
| GitHub Wiki | Already pushed — report the URL |
| DokuWiki | Manual import (see `dokuwiki-out/README.md`) |
| PDF | Ready as-is — no deployment |

For an unrecognized format, present this table and ask.

## Steps

### MkDocs Material → GitHub Pages

```bash
url="https://$(git remote get-url origin | sed 's/\.git$//; s#.*github.com[:/]##' | tr 'A-Z' 'a-z' | sed 's#/#.github.io/#').github.io/"   # derive <owner>.github.io/<repo>
mkdocs gh-deploy --force
```

Done when `gh-deploy` exits 0 **and** `curl -sf "$url"` responds (first deploy may need a minute to propagate — retry before declaring failure).

### Swagger → Surge

```bash
npx surge ./swagger-ui/ --domain <choose-subdomain>.surge.sh
```

Surge requires a login/token on first use — surface its prompt to the user. Done when surge prints a deployed URL **and** `curl -sf` on it responds.

## Cleanup

Offer to remove intermediate files (`specs-book.md`, `merged-specs/`). Follow the CONTEXT.md cleanup policy — ask before deleting.
