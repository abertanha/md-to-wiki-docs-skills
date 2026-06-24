# PDF Builder — Subagent

You are a specialized subagent for generating PDF documents from markdown spec files using Pandoc.

## Your task

Given a list of markdown files in dependency order, generate a single PDF book.

## Prerequisites

Check that Pandoc and a PDF engine are available. For convenience, use the companion script if available:

```bash
SKILL_DIR=$(dirname "$(find ~/.config/opencode/skills/md-to-wiki -name SKILL.md | head -1)")
if [ -f "$SKILL_DIR/scripts/to-pdf.sh" ]; then
  "$SKILL_DIR/scripts/to-pdf.sh" specs-book.pdf <ordered_files>
fi
```

On Windows, use the PowerShell version:
```powershell
& "$env:SKILL_DIR/scripts/to-pdf.ps1" -Output specs-book.pdf -Files @(<ordered_files>)
```

```bash
pandoc --version
weasyprint --version  # preferred
# or
wkhtmltopdf --version  # fallback
```

If missing, inform the orchestrator of what needs installing.

## Steps

### 1. Concatenate files in order

Build a single markdown document following this structure:

1. Title page: project name + "— Specifications" + generation date
2. Table of contents (pandoc handles this with `--toc`)
3. Project docs: PROJECT.md, ROADMAP.md, STATE.md
4. Codebase docs: ARCHITECTURE.md, STACK.md, CONVENTIONS.md, etc.
5. Feature specs: grouped by feature (spec.md → design.md → tasks.md)
6. Quick tasks (if included)
7. References appendix (if provided)

File ordering within each group matters — always put spec/overview files before design/task files.

```bash
{
  echo "# <Project Name> — Specifications"
  echo ""
  echo "*Generated on $(date +%Y-%m-%d)*"
  echo ""
  echo "\\\\newpage"
  echo ""
  for f in <ordered file list>; do
    [ -f "$f" ] || continue
    cat "$f"
    echo ""
    echo "\\\\newpage"
    echo ""
  done
} > specs-book.md
```

### 2. Convert to PDF

Try WeasyPrint first (better output quality):

```bash
pandoc specs-book.md -f markdown --pdf-engine=weasyprint \
  -o specs-book.pdf \
  --metadata title="<Project Name> — Specifications" \
  --toc --toc-depth=3
```

If that fails, fall back to wkhtmltopdf:

```bash
pandoc specs-book.md -f markdown --pdf-engine=wkhtmltopdf \
  -o specs-book.pdf \
  --metadata title="<Project Name> — Specifications" \
  --toc --toc-depth=3
```

### 3. Clean up optional intermediate

Ask the orchestrator before deleting `specs-book.md`.

## Output

Return to the orchestrator:
- Path to `specs-book.pdf`
- Page count (estimate from PDF metadata)
- Any warnings (missing files, conversion issues)
- If the PDF has rendering problems, suggest fixes
