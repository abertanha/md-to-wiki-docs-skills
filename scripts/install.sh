#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/abertanha/md-to-wiki-docs-skills.git"
SKILL_SUBDIR="md-to-wiki"
CLONE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/md-to-wiki-repo"
SKILL_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/$SKILL_SUBDIR"

echo "md-to-wiki installer"
echo "===================="

if [ -L "$SKILL_DEST" ] && [ -d "$SKILL_DEST" ]; then
  echo "✓ Already installed at $SKILL_DEST"
  echo "  Run update.sh to pull latest, or re-run to reinstall."
  exit 0
fi

echo "Cloning repo into $CLONE_DIR ..."
git clone --depth 1 "$REPO_URL" "$CLONE_DIR"

mkdir -p "$(dirname "$SKILL_DEST")"
ln -sfn "$CLONE_DIR/$SKILL_SUBDIR" "$SKILL_DEST"

echo "✓ Installed at $SKILL_DEST"
echo ""
echo "Scopes available:"
echo "  Global:      $SKILL_DEST"
echo "  Project:     .opencode/skills/$SKILL_SUBDIR/"
echo "  Cursor:      .cursor/skills/$SKILL_SUBDIR/"
