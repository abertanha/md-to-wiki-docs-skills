#!/usr/bin/env bash
# prompt-tests.sh — Prompt-driven routing + execution tests for md-to-wiki skill
# Usage: bash prompt-tests.sh
# Stays in opencode skills dir only — no external dependencies
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

PASS=0; FAIL=0; SKIP=0

# --- OS detection (mirrors SKILL.md) ---
case "$(uname -s 2>/dev/null)" in
  Linux|Darwin)        SCRIPT_EXT=".sh"; SCRIPT_RUNNER="" ;;
  MINGW*|MSYS*|CYGWIN*) SCRIPT_EXT=".sh"; SCRIPT_RUNNER="" ;;
  *)                   SCRIPT_EXT=".ps1"; SCRIPT_RUNNER="powershell -File" ;;
esac

# --- Route engine (mirrors SKILL.md Phase Router) ---
route_prompt() {
  local prompt="$1"
  local lower
  lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
  # Order matters: check most specific patterns first
  case "$lower" in
    *"not sure"*|*"help me choose"*|*"what format"*|*"recommend"*)  echo "onboarding" ;;
    *"swagger"*|*"openapi"*|*"api doc"*|*"api spec"*|*"endpoint"*)      echo "swagger" ;;
    *"github wiki"*|*"wiki tab"*|*"publish to wiki"*)               echo "github-wiki" ;;
    *"dokuwiki"*|*"doku"*|*"wiki export"*)                          echo "dokuwiki" ;;
    *"html"*|*"site"*|*"mkdocs"*|*"material"*)                      echo "mkdocs" ;;
    *"pdf"*|*"print"*|*"book"*)                                      echo "pdf" ;;
    *"audience"*|*"developer"*|*"stakeholder"*)                      echo "behavioral" ;;
    *"issue"*|*"pull request"*|*"reference"*)                        echo "references" ;;
    *"deploy"*|*"publish"*|*"go live"*)                              echo "deploy" ;;
    *)                                                                echo "unknown" ;;
  esac
}

# --- Test helpers ---
assert() {
  local desc="$1" cmd="$2"
  set +o pipefail
  if eval "$cmd" 2>/dev/null; then
    set -o pipefail; PASS=$((PASS + 1))
  else
    set -o pipefail; FAIL=$((FAIL + 1))
    echo "  FAIL: $desc"; echo "    cmd: $cmd"
  fi
}

skip() { local desc="$1" reason="$2"; SKIP=$((SKIP + 1)); echo "  SKIP: $desc ($reason)"; }

setup_repo() {
  local dest="$1"
  rm -rf "$dest"
  git clone --depth 1 --branch feat/7143-tesseractx-api \
    https://github.com/AGX-Software/tesseractx.git "$dest" 2>/dev/null
  cd "$dest"
}

# ============================================================
#  SUITE 1 — FORMAT SELECTION FIDELITY
# ============================================================
echo ""
echo "=== Suite 1: Format selection fidelity ==="

test_format_routing() {
  local prompt="$1" expected="$2"
  local actual
  actual=$(route_prompt "$prompt")
  assert "'$prompt' -> $expected" "[ '$actual' = '$expected' ]"
}

test_format_routing "Build HTML site from specs"              "mkdocs"
test_format_routing "Generate MkDocs Material site"           "mkdocs"
test_format_routing "Create static site with search"          "mkdocs"
test_format_routing "Generate OpenAPI spec"                   "swagger"
test_format_routing "Create Swagger docs from API contracts"  "swagger"
test_format_routing "Build API documentation"                 "swagger"
test_format_routing "Publish to GitHub Wiki"                  "github-wiki"
test_format_routing "Create GitHub Wiki tab"                  "github-wiki"
test_format_routing "Export to DokuWiki"                      "dokuwiki"
test_format_routing "Convert to DokuWiki format"              "dokuwiki"
test_format_routing "Generate PDF from specs"                 "pdf"
test_format_routing "Create PDF document"                     "pdf"
test_format_routing "Print specs as book"                     "pdf"
test_format_routing "I need documentation, not sure which"    "onboarding"
test_format_routing "Help me choose a format"                 "onboarding"
test_format_routing "What format do you recommend"            "onboarding"
test_format_routing "Fix this bug"                            "unknown"
test_format_routing "Add a new feature"                       "unknown"

# ============================================================
#  SUITE 2 — SCRIPT EXECUTION (uses tesseractx repo)
# ============================================================
echo ""
echo "=== Suite 2: Script execution ==="

setup_repo "$TMPDIR/repo"

# --- 2a. discover-sources ---
DS="$SKILL_DIR/scripts/discover-sources.sh"
assert "discover-sources runs on tesseractx" '"$DS" .specs >/dev/null'
assert "discovers 5 project files"  '"$DS" .specs | grep -q "Project.*5 file"'
assert "discovers 8 codebase files" '"$DS" .specs | grep -q "Codebase.*8 file"'
assert "discovers 30 features"      '"$DS" .specs | grep -q "Features.*30 featur"'
assert "discovers 2 quick tasks"     '"$DS" .specs | grep -q "Quick.*2 task"'
assert "JSON output is valid"       '"$DS" .specs json | python3 -m json.tool >/dev/null'

# --- 2b. generate-mkdocs ---
GM="$SKILL_DIR/scripts/generate-mkdocs.sh"
rm -rf docs
assert "mkdocs: exits zero" '"$GM" "TesseractX" .specs >/dev/null'
assert "mkdocs: mkdocs.yml created" '[ -f docs/mkdocs.yml ]'
assert "mkdocs: valid YAML" 'python3 -c "import yaml; yaml.safe_load(open(\"docs/mkdocs.yml\"))"'
assert "mkdocs: site_name matches" \
  'python3 -c "import yaml; d=yaml.safe_load(open(\"docs/mkdocs.yml\")); assert \"TesseractX\" in d[\"site_name\"]"'

# --- 2c. generate-index with different audiences ---
GI="$SKILL_DIR/scripts/generate-index.sh"

for aud in "developer" "stakeholder" "general"; do
  rm -rf docs
  assert "index [$aud]: exits zero" '"$GI" "TesseractX" "$aud" .specs/features >/dev/null'
  assert "index [$aud]: index.md created" '[ -f docs/index.md ]'
  assert "index [$aud]: H1 matches" 'grep -q "^# TesseractX" docs/index.md'
done

rm -rf docs
assert "index [developer]: has Dev section" \
  '"$GI" "TesseractX" "developer" .specs/features >/dev/null; grep -q "## Development" docs/index.md'
rm -rf docs
assert "index [stakeholder]: has Roadmap" \
  '"$GI" "TesseractX" "stakeholder" .specs/features >/dev/null; grep -q "Roadmap" docs/index.md'
rm -rf docs
assert "index [stakeholder]: no Dev section" \
  '"$GI" "TesseractX" "stakeholder" .specs/features >/dev/null; ! grep -q "## Development" docs/index.md'
rm -rf docs
assert "index [general]: has feature table" \
  '"$GI" "TesseractX" "general" .specs/features >/dev/null; grep -q "| Feature |" docs/index.md'

# --- 2d. to-dokuwiki (skip if no pandoc) ---
if command -v pandoc &>/dev/null; then
  DW="$SKILL_DIR/scripts/to-dokuwiki.sh"
  assert "dokuwiki: converts project page" \
    '"$DW" wiki-export .specs/project/PROJECT.md >/dev/null; [ -f wiki-export/data/pages/project/project.txt ]'
  assert "dokuwiki: writes README" '[ -f wiki-export/README.md ]'
else
  skip "dokuwiki conversion" "needs pandoc"
fi

# --- 2e. to-pdf (skip if no pandoc engine) ---
TP="$SKILL_DIR/scripts/to-pdf.sh"
if command -v pandoc &>/dev/null; then
  if pandoc --help 2>/dev/null | grep -q pdf-engine; then
    assert "pdf: generates output" \
      '"$TP" docs/specs-book.pdf .specs/project/PROJECT.md .specs/codebase/ARCHITECTURE.md >/dev/null; [ -s docs/specs-book.pdf ]'
    assert "pdf: valid magic bytes" \
      'python3 -c "b=open(\"docs/specs-book.pdf\",\"rb\").read(5); assert b[:4]==b\"%PDF-\" or b.startswith(b\"#\")"'
  else
    skip "pdf generation" "no PDF engine"
  fi
else
  skip "pdf generation" "needs pandoc"
fi

# --- 2f. fetch-issues ---
FI="$SKILL_DIR/scripts/fetch-issues.sh"
cd "$TMPDIR/repo"
rm -rf .specs/issues
assert "fetch: caches issue JSON" \
  '"$FI" "AGX-Software/tesseractx" 1 2>/dev/null; [ -f .specs/issues/cache/1.json ]'
assert "fetch: cache hit on second call" \
  '"$FI" "AGX-Software/tesseractx" 1 2>/dev/null | grep -q "^CACHED"'
assert "fetch: multi-issue" \
  '"$FI" "AGX-Software/tesseractx" 1 2 3 2>/dev/null; [ -f .specs/issues/cache/2.json ]'

# ============================================================
#  SUITE 3 — EDGE CASES
# ============================================================
echo ""
echo "=== Suite 3: Edge cases ==="

cd "$TMPDIR/repo"

# Missing required arg
assert "mkdocs no args: uses defaults" \
  '"$GM" >/dev/null; [ -f docs/mkdocs.yml ]'

# Missing required arg (index requires project name)
assert "index missing args: exits non-zero" \
  '! "$GI" 2>/dev/null'

# JSON format from discover-sources
assert "discover JSON: features include tesseractx-api-key-management" \
  '"$DS" .specs json | grep -q "tesseractx-api-key-management"'
assert "discover JSON: codebase includes ARCHITECTURE" \
  '"$DS" .specs json | grep -q "ARCHITECTURE.md"'

# Non-existent file
assert "fetch non-existent issue: returns error" \
  '"$FI" "AGX-Software/tesseractx" 99999999 2>/dev/null | grep -qE "NOT_FOUND|AUTH_NEEDED"'

# ============================================================
#  SUMMARY
# ============================================================
echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "============================================"

exit $FAIL
