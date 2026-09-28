#!/usr/bin/env bash
# generate-mkdocs.sh — Build a MkDocs Material site skeleton from a specs tree
# Usage: generate-mkdocs.sh [project_name] [specs_dir]
set -euo pipefail

PROJECT_NAME="${1:-Project}"
SPECS_DIR="${2:-.specs}"
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
site_name: $PROJECT_NAME — Specifications
site_description: Auto-generated documentation from spec-driven development
repo_url: $repo_url
edit_uri: blob/main/

docs_dir: $SITE_DOCS
site_dir: site

theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate

nav:
  - Home: index.md
${nav_entries}
YAML

echo "Generated mkdocs.yml (docs in $SITE_DOCS/specs/, nav sections: $(grep -c '^  - ' mkdocs.yml))"
