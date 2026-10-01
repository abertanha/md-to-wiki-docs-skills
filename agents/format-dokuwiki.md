# DokuWiki Builder — Subagent

Convert a markdown specs tree to DokuWiki format. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

## Prerequisites

```bash
pandoc --version 2>/dev/null || echo "pandoc missing — install per CONTEXT.md §Dependencies"
```

(The companion script also guards this itself and exits with install instructions.)

If any variable from CONTEXT.md is unset, ask the orchestrator before running.

## Steps

### 1. Discover sources

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/discover-sources$SCRIPT_EXT" "$SOURCES"
```

Done when the summary accounts for every markdown file under `$SOURCES`.

### 2. Convert

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/to-dokuwiki$SCRIPT_EXT" dokuwiki-out "$OUTPUT_LANG" $(find "$SOURCES" -name '*.md' | sort)
```

Done when the script exits 0 and reports one `Converted` line per input file.

`OUTPUT_LANG` comes from the dispatch prompt, never from the environment — same mechanism as `format-mkdocs.md`. An unknown or missing value stops the script with the list of supported languages (`en`, `pt-br`); there is no silent fallback.

## What the script produces (reference)

The output mirrors the input tree — each input path becomes a DokuWiki page whose page ID is the path with `/` replaced by `:`:

```
dokuwiki-out/
  data/pages/<input:path:with:colons>.txt
  README.md            ← import instructions
```

For a tree laid out per CONTEXT.md §Source taxonomy, that yields `project:*`, `codebase:*`, `features:<name>:*`, and `quick:<name>:*` pages. Import = copy `data/pages/` into the DokuWiki instance.

### 3. Verify

```bash
in=$(find "$SOURCES" -name '*.md' | wc -l)
out=$(find dokuwiki-out/data/pages -name '*.txt' | wc -l)
[ "$in" -eq "$out" ] && echo "OK: $out/$in converted"
! grep -rn '```' dokuwiki-out/data/pages/    # no raw markdown fences remain
```

Done when `in` equals `out` and the fence check passes (or every leftover is reported).

## Output

Return to the orchestrator:
- Path to `dokuwiki-out/` with the pages
- Path to `dokuwiki-out/README.md` with import instructions
- Conversion count (`converted/total`)
- Any warnings (conversion failures, missing files)
