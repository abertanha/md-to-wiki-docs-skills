#!/usr/bin/env bash
# to-pdf.sh — Generate PDF from selected markdown files
set -euo pipefail

OUTPUT="${1:?Usage: to-pdf.sh <output.pdf> <file1.md> [file2.md ...]}"
shift

BUILD_DIR=$(dirname "$OUTPUT")
mkdir -p "$BUILD_DIR"

# Build ordered markdown
BOOK="${BUILD_DIR}/specs-book.md"
{
  echo "# Specifications"
  echo
  for file in "$@"; do
    [ -f "$file" ] || { echo "WARNING: $file not found, skipping" >&2; continue; }
    echo "## $(basename "$file" .md)"
    echo
    cat "$file"
    echo
    echo "---"
    echo
  done
} > "$BOOK"

# Generate PDF via pandoc — weasyprint first (best output), then latex engines,
# then wkhtmltopdf; fall back to emitting the markdown book
if command -v pandoc &>/dev/null; then
  if pandoc --help | grep -q pdf-engine; then
    pandoc "$BOOK" -o "$OUTPUT" --toc --toc-depth=3 --pdf-engine=weasyprint 2>/dev/null \
      && echo "engine: weasyprint" \
      || { pandoc "$BOOK" -o "$OUTPUT" --toc --toc-depth=3 --pdf-engine=xelatex 2>/dev/null \
           && echo "engine: xelatex"; } \
      || { pandoc "$BOOK" -o "$OUTPUT" --toc --toc-depth=3 --pdf-engine=pdflatex 2>/dev/null \
           && echo "engine: pdflatex"; } \
      || { pandoc "$BOOK" -o "$OUTPUT" --toc --toc-depth=3 --pdf-engine=wkhtmltopdf 2>/dev/null \
           && echo "engine: wkhtmltopdf"; } \
      || { echo "WARNING: No PDF engine available. Outputting markdown book."; cp "$BOOK" "$OUTPUT"; }
  else
    pandoc "$BOOK" -o "$OUTPUT"
  fi
  echo "Generated $OUTPUT"
else
  cp "$BOOK" "$OUTPUT"
  echo "WARNING: pandoc not found. Outputting markdown book as $OUTPUT"
fi

# specs-book.md is retained — deletion follows the CONTEXT.md cleanup policy
