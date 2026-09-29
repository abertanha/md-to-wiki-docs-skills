#!/usr/bin/env bash
# to-pdf.sh — Generate PDF from selected markdown files
set -euo pipefail

OUTPUT="${1:?Usage: to-pdf.sh <output.pdf> <output_lang> <file1.md> [file2.md ...] — output_lang required, supported: en, pt-br}"
OUTPUT_LANG="${2:?Usage: to-pdf.sh <output.pdf> <output_lang> <file1.md> [file2.md ...] — output_lang required, supported: en, pt-br}"
OUTPUT_LANG=$(printf '%s' "$OUTPUT_LANG" | tr 'A-Z' 'a-z')

# Allowlist gate BEFORE any path is built from OUTPUT_LANG — an unknown value
# never reaches the catalog path construction below (T-03-07).
case "$OUTPUT_LANG" in
  en|pt-br) ;;
  *)
    echo "ERROR: unsupported output_lang '${OUTPUT_LANG}' — supported: en, pt-br" >&2
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATALOG="${SCRIPT_DIR}/../templates/lang/${OUTPUT_LANG}.lang"
[ -f "$CATALOG" ] || {
  echo "ERROR: catalog not found for output_lang '${OUTPUT_LANG}': ${CATALOG}" >&2
  exit 1
}

set -a
# shellcheck source=/dev/null
. "$CATALOG"
set +a

# Fail-closed up-front: every key this script expands must exist in the
# catalog before any byte of output is written.
: "${pdf_title:?key pdf_title not found in catalog}"

# PANDOC_LANG_OPTS: empty on en (no flags — behavior preserved, D-06); on
# pt-br, project the locale into the pandoc consumer (D-13). pt-BR is the
# projected BCP 47 form for this consumer.
case "$OUTPUT_LANG" in
  pt-br)
    : "${pdf_toc_title:?key pdf_toc_title not found in catalog}"
    PANDOC_LANG_OPTS=(-M lang=pt-BR -M "toc-title=${pdf_toc_title}")
    ;;
  *)
    PANDOC_LANG_OPTS=()
    ;;
esac

shift 2

BUILD_DIR=$(dirname "$OUTPUT")
mkdir -p "$BUILD_DIR"

# Build ordered markdown
BOOK="${BUILD_DIR}/specs-book.md"
{
  printf '# %s\n\n' "${pdf_title}"
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
    pandoc "$BOOK" -o "$OUTPUT" --toc --toc-depth=3 --pdf-engine=weasyprint \
      "${PANDOC_LANG_OPTS[@]+"${PANDOC_LANG_OPTS[@]}"}" 2>/dev/null \
      && echo "engine: weasyprint" \
      || { pandoc "$BOOK" -o "$OUTPUT" --toc --toc-depth=3 --pdf-engine=xelatex \
           "${PANDOC_LANG_OPTS[@]+"${PANDOC_LANG_OPTS[@]}"}" 2>/dev/null \
           && echo "engine: xelatex"; } \
      || { pandoc "$BOOK" -o "$OUTPUT" --toc --toc-depth=3 --pdf-engine=pdflatex \
           "${PANDOC_LANG_OPTS[@]+"${PANDOC_LANG_OPTS[@]}"}" 2>/dev/null \
           && echo "engine: pdflatex"; } \
      || { pandoc "$BOOK" -o "$OUTPUT" --toc --toc-depth=3 --pdf-engine=wkhtmltopdf \
           "${PANDOC_LANG_OPTS[@]+"${PANDOC_LANG_OPTS[@]}"}" 2>/dev/null \
           && echo "engine: wkhtmltopdf"; } \
      || { echo "WARNING: No PDF engine available. Outputting markdown book."; cp "$BOOK" "$OUTPUT"; }
  else
    pandoc "$BOOK" -o "$OUTPUT" "${PANDOC_LANG_OPTS[@]+"${PANDOC_LANG_OPTS[@]}"}"
  fi
  echo "Generated $OUTPUT"
else
  cp "$BOOK" "$OUTPUT"
  echo "WARNING: pandoc not found. Outputting markdown book as $OUTPUT"
fi

# specs-book.md is retained — deletion follows the CONTEXT.md cleanup policy
