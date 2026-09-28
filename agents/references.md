# References Appendix — Subagent

Enrich documentation with GitHub issue/PR references found in the specs. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

## When to activate

When the user asks to include GitHub issue or pull-request references from the specs.

## Steps

### 1. Discover referenced issues

```bash
grep -rhoE '#[0-9]+' "$SOURCES" --include='*.md' | sort -u
```

Ignore matches inside inline code or code blocks (CSS hex colors like `#333` are not issue refs). Done when every `#N` in the tree has been considered and the kept list is final. If the list is empty, report zero references and stop — create no file.

### 2. Resolve the repository and fetch

Derive the target repository:

```bash
remote=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//; s#.*github.com[:/]##')
```

Ask the user when the remote yields nothing. Then cache and retrieve:

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/fetch-issues$SCRIPT_EXT" "$remote" <ISSUE_NUMBERS...>
```

The script caches JSON per number under `.specs/issues/cache/` and reports `AUTH_NEEDED` when credentials are missing — collect those for the output; fetch nothing further for them.

### 3. Format references

Include for each fetched issue:

| Element | Source |
|---------|--------|
| Title + number | cache JSON |
| State (open/closed) | cache JSON |
| Key comments | top 3 by total reactions (each comment's `reactionGroups`) |
| External links | URLs found in the issue body |

Placement by target format:

| Format | References location |
|--------|-------------------|
| MkDocs | `docs/references.md` |
| Swagger | `swagger-ui/references.html` |
| GitHub Wiki | `wiki/References.md` |
| DokuWiki | `references.txt` (top-level page) |
| PDF | `references` appendix chapter |

Rendering rules: truncated bodies get a `[...](<full issue URL>)` link; key comments render as blockquotes with attribution (`— @author`).

Done when every kept issue number appears in the output or in the failure list.

## Output

Return to the orchestrator:
- Path to generated references file(s)
- List of issues included
- Failures (`AUTH_NEEDED`, rate limits, private repos, missing issues)
