#!/usr/bin/env bash
# generate-index.sh — Create landing page from discovered sources
# Usage: generate-index.sh <project_name> <audience> <output_lang> [feature_base_dirs...]
# Emits links only for files that exist (keeps `mkdocs build --strict` clean).
set -euo pipefail

PROJECT_NAME="${1:?Usage: generate-index.sh <project_name> <audience> <output_lang> [feature_base_dirs...]}"
AUDIENCE="${2:-general}"
OUTPUT_LANG="${3:?Usage: generate-index.sh <project_name> <audience> <output_lang> [feature_base_dirs...] — output_lang required, supported: en, pt-br}"
OUTPUT_LANG=$(printf '%s' "$OUTPUT_LANG" | tr 'A-Z' 'a-z')

# Allowlist gate BEFORE any path is built from OUTPUT_LANG — an unknown value
# never reaches the catalog path construction below (T-02-01).
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
# catalog before any byte of output is written (a gate covering only a
# subset would let partial output escape before the error surfaces).
: "${site_name_suffix:?key site_name_suffix not found in catalog}"
: "${index_tagline:?key index_tagline not found in catalog}"
: "${section_quick_start:?key section_quick_start not found in catalog}"
: "${section_overview:?key section_overview not found in catalog}"
: "${section_features:?key section_features not found in catalog}"
: "${section_architecture:?key section_architecture not found in catalog}"
: "${section_getting_started:?key section_getting_started not found in catalog}"
: "${section_development:?key section_development not found in catalog}"
: "${label_project_overview:?key label_project_overview not found in catalog}"
: "${label_architecture:?key label_architecture not found in catalog}"
: "${label_stack:?key label_stack not found in catalog}"
: "${label_conventions:?key label_conventions not found in catalog}"
: "${label_roadmap:?key label_roadmap not found in catalog}"
: "${label_state_decisions:?key label_state_decisions not found in catalog}"
: "${label_setup_guide:?key label_setup_guide not found in catalog}"
: "${label_contributing:?key label_contributing not found in catalog}"
: "${table_section:?key table_section not found in catalog}"
: "${table_description:?key table_description not found in catalog}"
: "${table_feature:?key table_feature not found in catalog}"
: "${table_spec:?key table_spec not found in catalog}"
: "${table_design:?key table_design not found in catalog}"
: "${table_tasks:?key table_tasks not found in catalog}"
: "${desc_project_overview:?key desc_project_overview not found in catalog}"
: "${desc_roadmap:?key desc_roadmap not found in catalog}"
: "${desc_architecture:?key desc_architecture not found in catalog}"
: "${index_architecture_body:?key index_architecture_body not found in catalog}"
: "${index_getting_started_body:?key index_getting_started_body not found in catalog}"
: "${cell_absent:?key cell_absent not found in catalog}"
: "${generated_by:?key generated_by not found in catalog}"

# Remaining args are feature base dirs; scan each for subdirectories
FEATURE_DIRS=()
shift 3
for base in "$@"; do
  for d in "$base"/*/; do
    [ -d "$d" ] && FEATURE_DIRS+=("$d")
  done
done

OUTPUT="${MDW_INDEX_OUT:-docs/index.md}"
mkdir -p "$(dirname "$OUTPUT")"

# Emit a nav link only when the target exists under docs/
link() { # <label> <relpath-under-docs>
  [ -f "docs/$2" ] && printf -- "- [%s](%s)\n" "$1" "$2"
}
# Emit a table cell link, or the catalog's absent-glyph when the file is absent
cell() { # <relpath-under-docs> <label>
  if [ -f "docs/$1" ]; then printf '[%s](%s)' "$2" "$1"; else printf '%s' "${cell_absent}"; fi
}

cat > "$OUTPUT" <<EOF
# $PROJECT_NAME ${site_name_suffix}

> ${index_tagline}

EOF

case "$AUDIENCE" in
  developer|developers|devs)
    section=$(printf '%s\n' \
      "$(link "${label_project_overview}" 'specs/project/PROJECT.md')" \
      "$(link "${label_architecture}" 'specs/codebase/ARCHITECTURE.md')" \
      "$(link "${label_stack}" 'specs/codebase/STACK.md')" \
      "$(link "${label_conventions}" 'specs/codebase/CONVENTIONS.md')" | sed '/^$/d')
    [ -n "$section" ] && { printf '## %s\n\n%s\n\n' "${section_quick_start}" "$section" >> "$OUTPUT"; }
    ;;
  stakeholder|stakeholders)
    section=$(printf '%s\n' \
      "$(link "${label_project_overview}" 'specs/project/PROJECT.md')" \
      "$(link "${label_roadmap}" 'specs/project/ROADMAP.md')" \
      "$(link "${label_state_decisions}" 'specs/project/STATE.md')" | sed '/^$/d')
    [ -n "$section" ] && { printf '## %s\n\n%s\n\n' "${section_overview}" "$section" >> "$OUTPUT"; }
    ;;
  *)
    rows=""
    [ -f "docs/specs/project/PROJECT.md" ]     && rows+="| [${label_project_overview}](specs/project/PROJECT.md) | ${desc_project_overview} |"$'\n'
    [ -f "docs/specs/project/ROADMAP.md" ]     && rows+="| [${label_roadmap}](specs/project/ROADMAP.md) | ${desc_roadmap} |"$'\n'
    [ -f "docs/specs/codebase/ARCHITECTURE.md" ] && rows+="| [${label_architecture}](specs/codebase/ARCHITECTURE.md) | ${desc_architecture} |"$'\n'
    if [ -n "$rows" ]; then
      printf '## %s\n\n| %s | %s |\n|---------|-------------|\n%s\n' "${section_overview}" "${table_section}" "${table_description}" "$rows" >> "$OUTPUT"
    fi
    ;;
esac

# Feature table
FEATURE_COUNT=0
for dir in "${FEATURE_DIRS[@]}"; do
  [ -d "$dir" ] || continue
  FEATURE_COUNT=$((FEATURE_COUNT + 1))
done

if [ "$FEATURE_COUNT" -gt 0 ]; then
  printf '## %s\n\n| %s | %s | %s | %s |\n|---------|------|--------|-------|\n' \
    "${section_features}" "${table_feature}" "${table_spec}" "${table_design}" "${table_tasks}" >> "$OUTPUT"
  for dir in "${FEATURE_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    # Links must be relative to the site's docs dir, not the project root
    rel_dir="${dir#./}"
    rel_dir="${rel_dir#docs/}"
    name=$(basename "$dir" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')
    printf '| %s | %s | %s | %s |\n' "$name" \
      "$(cell "${rel_dir}spec.md" "${table_spec}")" \
      "$(cell "${rel_dir}design.md" "${table_design}")" \
      "$(cell "${rel_dir}tasks.md" "${table_tasks}")" >> "$OUTPUT"
  done
  printf '\n' >> "$OUTPUT"
fi

# Architecture section
if [ -f "docs/specs/codebase/ARCHITECTURE.md" ]; then
  printf '\n## %s\n\n%s\n\n' "${section_architecture}" "${index_architecture_body}" >> "$OUTPUT"
fi

# Getting started
if [ -f "docs/specs/project/PROJECT.md" ]; then
  printf '## %s\n\n%s\n\n' "${section_getting_started}" "${index_getting_started_body}" >> "$OUTPUT"
fi

if [ "$AUDIENCE" = "developer" ] || [ "$AUDIENCE" = "developers" ] || [ "$AUDIENCE" = "devs" ]; then
  section=$(printf '%s\n' \
    "$(link "${label_setup_guide}" 'specs/project/SETUP.md')" \
    "$(link "${label_contributing}" 'specs/project/CONTRIBUTING.md')" | sed '/^$/d')
  [ -n "$section" ] && { printf '## %s\n\n%s\n\n' "${section_development}" "$section" >> "$OUTPUT"; }
fi

printf -- "---\n*${generated_by}*\n" "$(date +%Y-%m-%d)" >> "$OUTPUT"

echo "Generated $OUTPUT"
