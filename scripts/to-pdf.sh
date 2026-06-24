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

# Generate PDF via pandoc
if command -v pandoc &>/dev/null; then
  if pandoc --help | grep -q pdf-engine; then
    pandoc "$BOOK" -o "$OUTPUT" --pdf-engine=xelatex 2>/dev/null \
      || pandoc "$BOOK" -o "$OUTPUT" --pdf-engine=pdflatex 2>/dev/null \
      || pandoc "$BOOK" -o "$OUTPUT" --pdf-engine=wkhtmltopdf 2>/dev/null \
      || { echo "WARNING: No PDF engine available. Outputting markdown book."; cp "$BOOK" "$OUTPUT"; }
  else
    pandoc "$BOOK" -o "$OUTPUT"
  fi
  echo "Generated $OUTPUT"
else
  cp "$BOOK" "$OUTPUT"
  echo "WARNING: pandoc not found. Outputting markdown book as $OUTPUT"
fi

rm -f "$BOOK"
