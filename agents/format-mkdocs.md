# MkDocs Material Builder — Subagent

Generate a MkDocs Material static site from a markdown specs tree. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

## Prerequisites

```bash
mkdocs --version 2>/dev/null || pip install mkdocs mkdocs-material
```

If any variable from CONTEXT.md is unset, ask the orchestrator before running.

## Steps

### 1. Discover sources

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/discover-sources$SCRIPT_EXT" "$SOURCES"
```

Done when the summary accounts for every markdown file under `$SOURCES` (each file appears in exactly one category).

### 2. Generate the site skeleton

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/generate-mkdocs$SCRIPT_EXT" "$PROJECT_NAME" "$SOURCES" "$OUTPUT_LANG"
```

The script copies the specs tree into `docs/specs/` and writes `mkdocs.yml` (project root, `docs_dir: docs`) with the full nav. Done when `mkdocs.yml` exists and its nav contains one section per non-empty top-level spec directory.

`OUTPUT_LANG` comes from the dispatch prompt, never from the environment — same mechanism as step 3 below. An unknown or missing value stops the script with the list of supported languages (`en`, `pt-br`); there is no silent fallback.

### 3. Generate the landing page

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/generate-index$SCRIPT_EXT" "$PROJECT_NAME" "$AUDIENCE" "$OUTPUT_LANG" docs/specs/features
```

Done when `docs/index.md` exists and every link target in it resolves to a file under `docs/`.

`OUTPUT_LANG` comes from the dispatch prompt, never from the environment — same mechanism as `AUDIENCE`. An unknown or missing value stops the script with the list of supported languages (`en`, `pt-br`); there is no silent fallback.

### 4. Verify

```bash
mkdocs build --strict
```

Run from the project root. Done when the build exits 0. Fix warnings (broken links, missing pages, bad YAML) and re-run until clean.

### 5. Serve locally (optional)

```bash
mkdocs serve
```

## Output

Return to the orchestrator:
- Path to `docs/` directory
- Build clean (yes/no + remaining warnings)
- Serve URL if applicable
