#!/usr/bin/env bash
# generate-mkdocs.sh — Generate mkdocs.yml from .specs tree
set -euo pipefail

PROJECT_NAME="${1:-Project}"
SPECS_DIR="${2:-.specs}"
WITH_REFS=false

mkdir -p docs

# Detect repo URL from git remote (preferred) or .specs config
repo_url=""
if command -v git &>/dev/null; then
  repo_url=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' || echo "")
fi
if [ -z "$repo_url" ] && [ -f ".specs/config.json" ]; then
  repo_url=$(jq -r '.repo_url // ""' .specs/config.json 2>/dev/null || echo "")
fi

# Build nav structure
nav_entries=""
issues_entry=""

# Iterate .specs subdirectories, building nav items
find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d | sort | while read -r dir; do
  name=$(basename "$dir")
  label=$(echo "$name" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')

  # Collect markdown files in this section
  files=$(find "$dir" -maxdepth 1 -name '*.md' ! -name '_*' | sort)
  if [ -z "$files" ]; then
    continue
  fi

  nav_entries="${nav_entries}  - ${label}:"

  echo "$files" | while read -r file; do
    rel_path="${file#./}"
    file_label=$(basename "$file" .md | sed 's/-/ /g; s/\b\(.\)/\u\1/g')
    nav_entries="${nav_entries}"$'\n    - '"${file_label}: ${rel_path}"
  done
  nav_entries="${nav_entries}"$'\n'
done

# Issues entry (optional)
if [ -d ".specs/issues/cache" ] && [ -n "$(ls -A .specs/issues/cache 2>/dev/null)" ]; then
  issues_count=$(ls -1 .specs/issues/cache/*.json 2>/dev/null | wc -l)
  issues_entry="  - Issues: issues/"
fi

# Generate mkdocs.yml
cat > docs/mkdocs.yml <<YAML
site_name: $PROJECT_NAME — Specifications
site_description: Auto-generated documentation from spec-driven development
repo_url: $repo_url
edit_uri: blob/main/

theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate

nav:
  - Home: index.md
${nav_entries}${issues_entry}
YAML

echo "Generated docs/mkdocs.yml"
