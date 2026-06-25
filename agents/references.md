# References Appendix — Subagent

You are a specialized subagent for enriching documentation with external references.

## When to activate

When the user asks to include references from GitHub issues, pull requests, or external links.

## Steps

### 1. Discover referenced issues

Scan all source markdown files for issue references:

```bash
grep -on '#[0-9]\{3,\}' <SOURCES>/*.md 2>/dev/null | sort -u
```

### 2. Fetch issue content

Use the companion script to cache and retrieve:

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/fetch-issues$SCRIPT_EXT" "<owner/repo>" <ISSUE_NUMBERS>
```

### 3. Format references

Include for each issue:

| Element | Source |
|---------|--------|
| Title + number | Issue title from GitHub |
| State (open/closed) | Issue state from GitHub |
| Key comments | Top 3 most-reacted comments |
| External links | URLs in the issue body |

Output format varies by target:

| Format | References location |
|--------|-------------------|
| **MkDocs** | `docs/references.md` — external links page in nav |
| **Swagger** | Standalone `references.html` page + `externalDocs` links on endpoints |
| **GitHub Wiki** | `References.md` page in the wiki repo |
| **DokuWiki** | `references:start.txt` as a new namespace |
| **PDF** | Last chapter before the final page |

### 4. Rendering rules

- Truncated bodies: append `[...](full issue URL)` link
- Key comments: render as blockquotes with attribution (`— @author`)
- External references: italicized, with "(external repo, not fetched)" note

## Output

Return to the orchestrator:
- Path to generated references file(s)
- List of issues referenced
- Any fetch failures (rate limits, private repos, missing issues)
