# PDF Builder — Subagent

Compile a markdown specs tree into a single PDF book. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

## Prerequisites

```bash
pandoc --version 2>/dev/null || echo "pandoc missing — install per CONTEXT.md §Dependencies"
```

If any variable from CONTEXT.md is unset, ask the orchestrator before running.

## Steps

### 1. Order the input

Build the ordered file list from the discovery output (`discover-sources ... files`), following this policy — spec/overview files before design/task files within each feature group, project docs before codebase docs, features last:

```
project/*.md → codebase/*.md → features/<name>/spec.md,design.md,tasks.md → quick/<name>/*.md
```

Done when every discovered file is on the list.

### 2. Build the PDF (companion script — primary path)

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/to-pdf$SCRIPT_EXT" specs-book.pdf <ordered files...>
```

The script concatenates, warns about missing files instead of skipping silently, and tries the available engines in order. Done when it exits 0 and `specs-book.pdf` exists with non-zero size.

### 3. Manual fallback (script unreachable)

Only when the script path fails, replicate it:

```bash
{
  for f in <ordered files...>; do
    [ -f "$f" ] || echo "WARNING: $f not found"    # warn, keep going
    echo "## $(basename "$f" .md)"; echo; cat "$f"; echo; echo ---; echo
  done
} > specs-book.md
pandoc specs-book.md -o specs-book.pdf --toc --toc-depth=3 --pdf-engine=weasyprint \
  || pandoc specs-book.md -o specs-book.pdf --toc --toc-depth=3 --pdf-engine=wkhtmltopdf
```

Same completion criterion as step 2.

### 4. Intermediates

`specs-book.md` is retained. Deletion follows the CONTEXT.md cleanup policy — ask the orchestrator first.

## Output

Return to the orchestrator:
- Path to `specs-book.pdf`
- Page count from PDF metadata (`pdfinfo` when available; report unknown otherwise)
- Warnings (missing files — echoed, engine fallbacks used)
