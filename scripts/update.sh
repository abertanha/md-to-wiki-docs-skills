#!/usr/bin/env bash
set -euo pipefail

CLONE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/md-to-wiki-repo"

echo "md-to-wiki updater"
echo "=================="

if [ ! -d "$CLONE_DIR/.git" ]; then
  echo "! Not installed via git. Clone dir not found at $CLONE_DIR"
  echo "  Re-run install.sh first."
  exit 1
fi

cd "$CLONE_DIR"

git fetch origin --quiet
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)

if [ "$BEHIND" -eq 0 ]; then
  echo "✓ Already up to date ($(git rev-parse --short HEAD))."
  exit 0
fi

git pull --ff-only origin main
echo "✓ Updated ($(git rev-parse --short HEAD), $BEHIND commit(s) pulled)."
