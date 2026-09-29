#!/usr/bin/env bash
# to-dokuwiki.sh — Convert markdown files to DokuWiki syntax
set -euo pipefail

OUTPUT_DIR="${1:?Usage: to-dokuwiki.sh <output_dir> <output_lang> <file1.md> [file2.md ...] — output_lang required, supported: en, pt-br}"
OUTPUT_LANG="${2:?Usage: to-dokuwiki.sh <output_dir> <output_lang> <file1.md> [file2.md ...] — output_lang required, supported: en, pt-br}"
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
# catalog before any byte of output is written. This bootstrap runs BEFORE
# the pandoc guard below so a missing key halts naming the key even on a
# host without pandoc (T-03-08).
: "${dokuwiki_readme_heading:?key dokuwiki_readme_heading not found in catalog}"
: "${dokuwiki_readme_steps:?key dokuwiki_readme_steps not found in catalog}"
: "${dokuwiki_readme_footer:?key dokuwiki_readme_footer not found in catalog}"

shift 2

mkdir -p "$OUTPUT_DIR/data/pages"

if ! command -v pandoc &>/dev/null; then
  echo "ERROR: pandoc not found. Install it: sudo apt install pandoc"
  exit 1
fi

for file in "$@"; do
  [ -f "$file" ] || { echo "WARNING: $file not found, skipping"; continue; }

  # Convert path to DokuWiki page ID: .specs/project/PROJECT.md → specs:project:project
  relative="${file#.specs/}"
  relative="${relative%.md}"
  page_id="${relative//\//:}"
  page_path="$OUTPUT_DIR/data/pages/$page_id.txt"

  mkdir -p "$(dirname "$page_path")"
  pandoc "$file" -f markdown -t dokuwiki -o "$page_path"
  echo "Converted $file -> $page_path"
done

steps_block=$(printf '%b' "${dokuwiki_readme_steps}")

cat > "$OUTPUT_DIR/README.md" <<EOF
# ${dokuwiki_readme_heading}

${steps_block}

${dokuwiki_readme_footer}
EOF

echo "Done. Import $OUTPUT_DIR/data/ into your DokuWiki data/ directory."
