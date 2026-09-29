#!/usr/bin/env bash
# regress.sh — Capture and regression-check the golden fixtures of the .sh chain
# Usage: regress.sh [capture]
#
# Modes:
#   regress (default) — rerun the engine-less chain over the committed fixture
#                       tree and diff the fresh output against the goldens,
#                       masking dates symmetrically on both sides.
#   capture           — rerun the chain and overwrite the goldens with the
#                       fresh output. The capture mode is the ONLY writer of
#                       the golden fixtures; never edit them by hand.
#
# Exit codes: 0 = all legs green, 1 = a diff (or usage error) diverged,
# 3 = one or more legs SKIPPED (reason printed per leg). Partial runs are
# machine-detectable, never silent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
TEMPLATES="$REPO_ROOT/templates"
TREE="$REPO_ROOT/tests/fixtures/tree/.specs"
GOLDEN="$REPO_ROOT/tests/fixtures/golden-sh"

# Pin the locale BEFORE any leg: the title-case sed in the chain corrupts
# accented directory labels under LC_ALL=C, and the sort collation must be
# stable between capture and diff.
export LC_ALL=C.UTF-8

# Date mask token: applied symmetrically (to golden copies AND fresh copies,
# never in place) before any diff, so the capture date never leaks into the
# result. Covers every ISO 8601 date site in the chain chrome.
MASK='s/[0-9]{4}-[0-9]{2}-[0-9]{2}/__DATE__/g'

SKIP=0
FAIL=0

skip() { # <reason> — mark the run as partial (exit 3), keep going
  echo "SKIPPED: $1"
  SKIP=1
}

die() { # <message> — fail closed
  echo "ERROR: $1" >&2
  exit 1
}

[ -d "$TREE" ] || die "fixture tree not found: $TREE (tests/fixtures/tree/.specs must stay committed)"

# Run the .sh chain engine-less over a FRESH workdir (never reuse one: the
# specs mirror accumulates orphans) and collect the publishable surfaces.
# The workdir is a mktemp dir OUTSIDE any git repo, so the origin URL can
# never leak into the golden mkdocs.yml.
run_dokuwiki_sh() { # <dest_dir> — runs to-dokuwiki.sh over the fixture tree (requires pandoc)
  local DEST="$1" WORK
  WORK=$(mktemp -d)
  cp -r "$TREE" "$WORK/.specs"
  (
    cd "$WORK"
    bash "$SCRIPTS/to-dokuwiki.sh" dokuwiki \
      .specs/project/PROJECT.md .specs/project/ROADMAP.md \
      .specs/codebase/ARCHITECTURE.md \
      .specs/features/login/spec.md .specs/features/login/design.md \
      ".specs/features/autenticação/spec.md" \
      .specs/quick/fix-nav/spec.md
  )
  cp -r "$WORK/dokuwiki" "$DEST/dokuwiki"
  rm -rf "$WORK"
}

run_chain() { # <dest_dir>
  local DEST="$1" WORK
  WORK=$(mktemp -d)
  cp -r "$TREE" "$WORK/.specs"
  (
    cd "$WORK"
    bash "$SCRIPTS/generate-mkdocs.sh" TestProject .specs en
    bash "$SCRIPTS/generate-index.sh" TestProject general en docs/specs/features
    # Explicit file arguments, in format-pdf.md policy order — never an
    # unquoted expansion (word splitting differs between shells).
    bash "$SCRIPTS/to-pdf.sh" specs-book.pdf en \
      .specs/project/PROJECT.md .specs/project/ROADMAP.md \
      .specs/codebase/ARCHITECTURE.md \
      .specs/features/login/spec.md .specs/features/login/design.md \
      .specs/features/autenticação/spec.md \
      .specs/quick/fix-nav/spec.md
    # Swagger surface: render the template instance exactly as the agent
    # flow does (placeholder substitution only).
    mkdir -p swagger-ui
    sed -e 's/{{PROJECT_NAME}}/TestProject/g' \
        -e 's|{{OPENAPI_YML}}|openapi.yml|g' \
        "$TEMPLATES/swagger-ui.html" > swagger-ui/index.html
  )
  mkdir -p "$DEST/mkdocs" "$DEST/pdf" "$DEST/swagger"
  cp "$WORK/mkdocs.yml" "$DEST/mkdocs/mkdocs.yml"
  cp -r "$WORK/docs" "$DEST/mkdocs/docs"
  cp "$WORK/specs-book.pdf" "$DEST/pdf/specs-book.pdf"
  cp "$WORK/swagger-ui/index.html" "$DEST/swagger/index.html"
  rm -rf "$WORK"
}

mask_copy() { # <src_tree> <dst_tree> — masked copy, source untouched
  rm -rf "$2"
  mkdir -p "$2"
  cp -r "$1/." "$2/"
  find "$2" -type f -exec sed -i -E "$MASK" {} +
}

compare_surface() { # <label> <relative_dir> <masked_golden_root> <masked_fresh_root>
  local label="$1" rel="$2" g f out
  g="$3/$rel"
  f="$4/$rel"
  out=$(diff -r "$g" "$f" 2>&1) && {
    echo "OK: $label identical (date-masked)"
  } || {
    echo "FAIL: $label diverged"
    printf '%s\n' "$out" | sed 's/^/  /'
    FAIL=1
  }
}

MODE="${1:-regress}"

case "$MODE" in
  capture)
    FRESH=$(mktemp -d)
    trap 'rm -rf "$FRESH"' EXIT
    run_chain "$FRESH"
    rm -rf "$GOLDEN/mkdocs" "$GOLDEN/pdf" "$GOLDEN/swagger"
    mkdir -p "$GOLDEN"
    cp -r "$FRESH/mkdocs" "$GOLDEN/mkdocs"
    cp -r "$FRESH/pdf" "$GOLDEN/pdf"
    cp -r "$FRESH/swagger" "$GOLDEN/swagger"
    echo "Captured golden fixtures into tests/fixtures/golden-sh/"
    ;;
  regress)
    [ -f "$GOLDEN/mkdocs/mkdocs.yml" ] || die "golden not found under $GOLDEN — run 'tests/regress.sh capture' first"
    FRESH=$(mktemp -d)
    MASKED=$(mktemp -d)
    trap 'rm -rf "$FRESH" "$MASKED"' EXIT
    run_chain "$FRESH"
    mask_copy "$GOLDEN" "$MASKED/golden"
    mask_copy "$FRESH" "$MASKED/fresh"
    compare_surface "mkdocs (mkdocs.yml + docs/)" "mkdocs" "$MASKED/golden" "$MASKED/fresh"
    compare_surface "pdf (specs-book.pdf fallback)" "pdf" "$MASKED/golden" "$MASKED/fresh"
    compare_surface "swagger (index.html)" "swagger" "$MASKED/golden" "$MASKED/fresh"
    ;;
  *)
    die "unknown mode: $MODE (Usage: regress.sh [capture])"
    ;;
esac

# DokuWiki leg (.sh geminho): gated on pandoc (dev-only dep, no fallback in the script).
# Missing pandoc is a SKIP, not a diff failure.
GOLDEN_DW="$REPO_ROOT/tests/fixtures/golden-sh/dokuwiki"
if command -v pandoc >/dev/null 2>&1; then
  case "$MODE" in
    capture)
      FRESH_DW=$(mktemp -d)
      run_dokuwiki_sh "$FRESH_DW"
      rm -rf "$GOLDEN_DW"
      cp -r "$FRESH_DW/dokuwiki" "$GOLDEN_DW"
      rm -rf "$FRESH_DW"
      echo "Captured DokuWiki golden into tests/fixtures/golden-sh/dokuwiki/"
      ;;
    regress)
      [ -f "$GOLDEN_DW/README.md" ] || die "DokuWiki golden not found under $GOLDEN_DW — run 'tests/regress.sh capture' first"
      FRESH_DW=$(mktemp -d)
      run_dokuwiki_sh "$FRESH_DW"
      out=$(diff -r "$GOLDEN_DW" "$FRESH_DW/dokuwiki" 2>&1) && {
        echo "OK: dokuwiki identical"
      } || {
        echo "FAIL: dokuwiki diverged"
        printf '%s\n' "$out" | sed 's/^/  /'
        FAIL=1
      }
      rm -rf "$FRESH_DW"
      ;;
  esac
else
  skip "pandoc not found on host — DokuWiki surface needs the dev-only dependency (sudo apt install pandoc; see tests/fixtures/manifest.md)"
fi

# .ps1 leg: requires pwsh (dev-only, baseline PS7/Linux, UTF-8 without BOM).
# On Linux/WSL hosts without pwsh this leg is SKIPPED — correct result for this
# host class, not a defect. The golden-ps1 capture requires a host with pwsh.
if command -v pwsh >/dev/null 2>&1; then
  skip "pwsh present but .ps1 golden capture not yet implemented in this harness"
else
  skip "pwsh not found on host — .ps1 surfaces require a host with PowerShell 7 (see tests/fixtures/manifest.md)"
fi

[ "$FAIL" -eq 1 ] && exit 1
[ "$SKIP" -eq 1 ] && exit 3
exit 0
