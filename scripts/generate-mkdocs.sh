#!/usr/bin/env bash
# generate-mkdocs.sh — Build a MkDocs Material site skeleton from a specs tree
# Usage: generate-mkdocs.sh [project_name] [specs_dir] <output_lang>
set -euo pipefail

# Pin a UTF-8 locale so the title-case sed pipeline below operates
# character-wise, not byte-wise — under LC_ALL=C, accented basenames
# (e.g. autenticação) are corrupted into mojibake. Preserve any locale
# the caller already set explicitly.
export LC_ALL="${LC_ALL:-C.UTF-8}"

PROJECT_NAME="${1:-Project}"
# Strip newlines: a CR/LF in PROJECT_NAME would inject a second YAML key (T-RETRO-02).
PROJECT_NAME="$(printf '%s' "$PROJECT_NAME" | tr -d '\r\n')"
SPECS_DIR="${2:-.specs}"
OUTPUT_LANG="${3:?Usage: generate-mkdocs.sh [project_name] [specs_dir] <output_lang> — output_lang required, supported: en, pt-br}"
OUTPUT_LANG=$(printf '%s' "$OUTPUT_LANG" | tr 'A-Z' 'a-z')

# Allowlist gate BEFORE any path is built from OUTPUT_LANG — an unknown value
# never reaches the catalog path construction below (T-02-06).
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

# theme.language projection (D-12): consumer configuration, not a chrome
# label, so it is NOT a catalog key — UPPERCASE on purpose keeps it out of
# reach of the [a-z] catalog-reference filter in tests/fail-closed.sh's
# keyset_equality gate. Empty for en (Material's own default is already en,
# so omitting the key keeps the golden byte-identical); pt-BR region-cased
# per BCP 47 for pt-br.
case "$OUTPUT_LANG" in
  en) THEME_LANGUAGE='' ;;
  pt-br) THEME_LANGUAGE=$'  language: pt-BR\n' ;;
esac

set -a
# shellcheck source=/dev/null
. "$CATALOG"
set +a

# Fail-closed up-front: every key this script expands must exist in the
# catalog before any byte of output is written (a gate covering only a
# subset would let partial output escape before the error surfaces).
: "${site_name_suffix:?key site_name_suffix not found in catalog}"
: "${site_description:?key site_description not found in catalog}"
: "${nav_home:?key nav_home not found in catalog}"

SITE_DOCS="docs"

mkdir -p "$SITE_DOCS/specs"

# Copy the specs tree into the site so nav links resolve inside docs_dir
cp -r "$SPECS_DIR"/. "$SITE_DOCS/specs"/

# Detect repo URL from git remote (preferred) or .specs config
repo_url=""
if command -v git &>/dev/null; then
  repo_url=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' || echo "")
fi
if [ -z "$repo_url" ] && [ -f ".specs/config.json" ]; then
  repo_url=$(jq -r '.repo_url // ""' .specs/config.json 2>/dev/null || echo "")
fi
# Strip newlines from repo_url — same YAML injection vector as PROJECT_NAME (T-RETRO-02).
repo_url="$(printf '%s' "$repo_url" | tr -d '\r\n')"

# Build nav: one section per top-level spec dir, files discovered recursively.
# No `... | while read` here — pipe loops run in subshells and lose nav_entries.
nav_entries=""
for dir in "$SITE_DOCS/specs"/*/; do
  [ -d "$dir" ] || continue
  label=$(basename "$dir" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')
  files=$(find "$dir" -name '*.md' ! -name '_*' | sort)
  [ -z "$files" ] && continue
  nav_entries="${nav_entries}  - ${label}:"$'\n'
  while IFS= read -r file; do
    rel="${file#"$SITE_DOCS"/}"
    file_label=$(basename "$file" .md | sed 's/-/ /g; s/\b\(.\)/\u\1/g')
    nav_entries="${nav_entries}    - ${file_label}: ${rel}"$'\n'
  done <<< "$files"
done

# Generate mkdocs.yml at the project root (docs_dir/site_dir explicit, so the
# build works from the root regardless of the caller's cwd)
cat > mkdocs.yml <<YAML
site_name: $PROJECT_NAME ${site_name_suffix}
site_description: ${site_description}
repo_url: $repo_url
edit_uri: blob/main/

docs_dir: $SITE_DOCS
site_dir: site

theme:
  name: material
${THEME_LANGUAGE}  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate

nav:
  - ${nav_home}: index.md
${nav_entries}
YAML

echo "Generated mkdocs.yml (docs in $SITE_DOCS/specs/, nav sections: $(grep -c '^  - ' mkdocs.yml))"
