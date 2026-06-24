#!/usr/bin/env bash
# discover-sources.sh — Scan .specs/ (or custom paths) for markdown files
# Usage: discover-sources.sh [--dir <path>] [--format summary|files|json]
set -euo pipefail

DIR="${1:-.specs}"
FORMAT="${2:-summary}"

if [ ! -d "$DIR" ]; then
  echo "ERROR: Directory not found: $DIR"
  exit 1
fi

# Collect files by category
PROJECT_FILES=$(find "$DIR/project" -maxdepth 1 -name "*.md" 2>/dev/null | sort)
CODEBASE_FILES=$(find "$DIR/codebase" -maxdepth 1 -name "*.md" 2>/dev/null | sort)
FEATURE_DIRS=$(find "$DIR/features" -maxdepth 1 -type d 2>/dev/null | sort)
QUICK_DIRS=$(find "$DIR/quick" -maxdepth 1 -type d 2>/dev/null | sort)

case "$FORMAT" in
  files)
    echo "$PROJECT_FILES"
    echo "$CODEBASE_FILES"
    for fd in $FEATURE_DIRS; do
      find "$fd" -maxdepth 1 -name "*.md" 2>/dev/null
    done
    for qd in $QUICK_DIRS; do
      find "$qd" -maxdepth 1 -name "*.md" 2>/dev/null
    done
    ;;
  json)
    echo "{"
    echo "  \"project\": ["
    first=true
    for f in $PROJECT_FILES; do
      $first || echo ","
      first=false
      echo "    \"$f\""
    done
    echo "  ],"
    echo "  \"codebase\": ["
    first=true
    for f in $CODEBASE_FILES; do
      $first || echo ","
      first=false
      echo "    \"$f\""
    done
    echo "  ],"
    echo "  \"features\": ["
    first=true
    for fd in $FEATURE_DIRS; do
      $first || echo ","
      first=false
      name=$(basename "$fd")
      echo "    { \"name\": \"$name\", \"files\": ["
      inner_first=true
      for f in $(find "$fd" -maxdepth 1 -name "*.md" 2>/dev/null | sort); do
        $inner_first || echo ","
        inner_first=false
        echo "      \"$f\""
      done
      echo "    ] }"
    done
    echo "  ],"
    echo "  \"quick\": ["
    first=true
    for qd in $QUICK_DIRS; do
      $first || echo ","
      first=false
      name=$(basename "$qd")
      echo "    { \"name\": \"$name\", \"files\": ["
      inner_first=true
      for f in $(find "$qd" -maxdepth 1 -name "*.md" 2>/dev/null | sort); do
        $inner_first || echo ","
        inner_first=false
        echo "      \"$f\""
      done
      echo "    ] }"
    done
    echo "  ]"
    echo "}"
    ;;
  *)
    # Default: human-readable summary
    project_count=$(echo "$PROJECT_FILES" | wc -l)
    codebase_count=$(echo "$CODEBASE_FILES" | wc -l)
    feature_count=$(echo "$FEATURE_DIRS" | wc -l)
    quick_count=$(echo "$QUICK_DIRS" | wc -l)
    total_files=$(( $(echo "$PROJECT_FILES$CODEBASE_FILES" | wc -l) ))
    for fd in $FEATURE_DIRS; do
      total_files=$(( total_files + $(find "$fd" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l) ))
    done
    for qd in $QUICK_DIRS; do
      total_files=$(( total_files + $(find "$qd" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l) ))
    done

    echo "Discovered in $DIR/"
    echo "  Project  → $project_count file(s)"
    echo "  Codebase → $codebase_count file(s)"
    echo "  Features → $feature_count feature(s)"
    echo "  Quick    → $quick_count task(s)"
    echo "  Total    → $total_files markdown file(s)"
    echo ""
    echo "Feature list:"
    for fd in $FEATURE_DIRS; do
      name=$(basename "$fd")
      count=$(find "$fd" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
      echo "    • $name ($count file(s))"
    done
    ;;
esac
