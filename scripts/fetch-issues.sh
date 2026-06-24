#!/usr/bin/env bash
# fetch-issues.sh — Fetch GitHub issues/PRs with gh (preferred) or curl (fallback)
set -euo pipefail

OWNER_REPO="${1:?Usage: fetch-issues.sh <owner/repo> <number> [number...]}"
shift

CACHE_DIR=".specs/issues/cache"
mkdir -p "$CACHE_DIR"

OWNER="${OWNER_REPO%/*}"
REPO="${OWNER_REPO#*/}"

fetch_item() {
  local num="$1"
  local cache_file="$CACHE_DIR/$num.json"
  local result=""

  [ -f "$cache_file" ] && { title=$(jq -r '.title' "$cache_file" 2>/dev/null); echo "CACHED|$num|$title"; return; }

  # Try gh (GitHub CLI)
  if command -v gh &>/dev/null; then
    for type in issue pr; do
      data=$(gh "$type" view "$num" --repo "$OWNER_REPO" \
        --json number,title,body,state,url,labels,createdAt,closedAt,mergedAt,comments 2>/dev/null) || continue
      [ -n "$data" ] && [ "$data" != "null" ] || continue
      echo "$data" > "$cache_file"
      title=$(echo "$data" | jq -r '.title')
      echo "GH|$num|$title"
      return
    done
  fi

  # Fallback: curl + GitHub API
  if response=$(curl -sf "https://api.github.com/repos/$OWNER_REPO/issues/$num" 2>/dev/null); then
    echo "$response" > "$cache_file"
    title=$(echo "$response" | jq -r '.title // empty')
    echo "CURL|$num|$title"
    return
  fi

  echo "AUTH_NEEDED|$num|" && return
}

for num in "$@"; do
  fetch_item "$num"
done | grep -v '^$' || true
