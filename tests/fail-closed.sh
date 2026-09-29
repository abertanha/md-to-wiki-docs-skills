#!/usr/bin/env bash
# fail-closed.sh — Repeatable gate for CHROME-03 (fail-closed on missing catalog
# key) and CHROME-04 (title-case passthrough sites stay catalog-free)
# Usage: fail-closed.sh (no arguments)
#
# Exit codes: 0 = every gate green, 1 = at least one gate failed (reason
# printed per gate). No golden fixture is read or written; this harness only
# proves fail-closed behavior of the .sh chain, never regresses output bytes.
#
# Every mutating probe copies scripts/, templates/ and the fixture .specs tree
# into its own `mktemp -d` sandbox before touching a catalog — the real
# working tree is never mutated. Each sandbox is removed at the end of its
# probe.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
TEMPLATES="$REPO_ROOT/templates"
TREE="$REPO_ROOT/tests/fixtures/tree/.specs"
CATALOG_EN="$TEMPLATES/lang/en.lang"

# Pin the locale before any gate: the title-case sed in the chain corrupts
# accented directory labels under LC_ALL=C (same rationale as tests/regress.sh).
export LC_ALL=C.UTF-8

FAIL=0

IDX_ARGS=(TestProject general en docs/specs/features)
MKD_ARGS=(TestProject .specs en)

sandbox_new() { # — mktemp sandbox with scripts/, templates/ and .specs copied in
  local sandbox
  sandbox=$(mktemp -d)
  cp -r "$SCRIPTS" "$sandbox/scripts"
  cp -r "$TEMPLATES" "$sandbox/templates"
  cp -r "$TREE" "$sandbox/.specs"
  printf '%s\n' "$sandbox"
}

# --- Gate: keyset_equality ---------------------------------------------
# Permanent guard against Pitfall 6 (up-front gate falling out of sync with
# the body): the set of keys declared in `: "${key:?…}"` lines must equal
# the set of catalog-namespace keys actually expanded in the script body.
keyset_equality() { # <script_path>
  local script="$1" name declared expanded
  name="$(basename "$script")"
  declared=$(grep -oE '^: "\$\{[a-z_][a-z0-9_]*:\?' "$script" | sed -E 's/^: "\$\{//; s/:\?$//' | sort -u)
  # Expanded set is filtered against the catalog's own key vocabulary so
  # script-internal lowercase vars (dir, label, rel, section, ...) never
  # get mistaken for a catalog reference.
  expanded=$(comm -12 \
    <(grep -oE '\$\{[a-z][a-z0-9_]*\}' "$script" | sed -E 's/^\$\{//; s/\}$//' | sort -u) \
    <(grep -oE '^[a-z][a-z0-9_]*=' "$CATALOG_EN" | sed 's/=$//' | sort -u))
  if [ "$declared" = "$expanded" ]; then
    echo "OK: keyset_equality ${name}"
  else
    echo "FAIL: keyset_equality ${name} — declared vs expanded diverge"
    diff <(printf '%s\n' "$declared") <(printf '%s\n' "$expanded") | sed 's/^/  /'
    FAIL=1
  fi
}

# --- Gate: missing_key_halts ---------------------------------------------
# CHROME-03: removing one key from a SANDBOX COPY of the catalog must halt
# the script with a non-zero status and a message naming the missing key.
missing_key_halts() { # <script_basename> <key> <args...>
  local script="$1" key="$2" sandbox out status
  shift 2
  sandbox=$(sandbox_new)
  sed -i "/^${key}=/d" "$sandbox/templates/lang/en.lang"
  out=$(cd "$sandbox" && bash "scripts/${script}" "$@" 2>&1) && status=0 || status=$?
  rm -rf "$sandbox"
  if [ "$status" -ne 0 ] && printf '%s\n' "$out" | grep -q "$key"; then
    echo "OK: missing_key_halts ${script} (${key})"
  else
    echo "FAIL: missing_key_halts ${script} (${key}) — status=${status}"
    printf '%s\n' "$out" | sed 's/^/  /'
    FAIL=1
  fi
}

# --- Gate: intact_catalog_succeeds ---------------------------------------
# Positive control for missing_key_halts: without it, a halt could pass the
# gate above for a reason unrelated to the removed key (e.g. a script broken
# by something else entirely).
intact_catalog_succeeds() { # <script_basename> <args...>
  local script="$1" sandbox out status
  shift
  sandbox=$(sandbox_new)
  out=$(cd "$sandbox" && bash "scripts/${script}" "$@" 2>&1) && status=0 || status=$?
  rm -rf "$sandbox"
  if [ "$status" -eq 0 ]; then
    echo "OK: intact_catalog_succeeds ${script}"
  else
    echo "FAIL: intact_catalog_succeeds ${script} — status=${status}"
    printf '%s\n' "$out" | sed 's/^/  /'
    FAIL=1
  fi
}

# --- Gate: bad_language_halts --------------------------------------------
# PARAM-02: a value outside the en|pt-br allowlist must halt before any path
# is built from it, and the message must list the supported languages.
bad_language_halts() { # <script_basename> <args...>
  local script="$1" sandbox out status
  shift
  sandbox=$(sandbox_new)
  out=$(cd "$sandbox" && bash "scripts/${script}" "$@" 2>&1) && status=0 || status=$?
  rm -rf "$sandbox"
  if [ "$status" -ne 0 ] && printf '%s\n' "$out" | grep -qE 'en, pt-br|pt-br, en'; then
    echo "OK: bad_language_halts ${script}"
  else
    echo "FAIL: bad_language_halts ${script} — status=${status}"
    printf '%s\n' "$out" | sed 's/^/  /'
    FAIL=1
  fi
}

# --- Gate: passthrough_intact --------------------------------------------
# CHROME-04 as a permanent gate: the title-case pipeline must appear exactly
# once in generate-index.sh and twice in generate-mkdocs.sh, and no line
# carrying that pipeline may also carry a catalog-namespace expansion.
passthrough_intact() {
  local idx_n mk_n leaked
  idx_n=$(grep -cF 's/\b\(.\)/\u\1/g' "$SCRIPTS/generate-index.sh")
  mk_n=$(grep -cF 's/\b\(.\)/\u\1/g' "$SCRIPTS/generate-mkdocs.sh")
  leaked=$(grep -F 's/\b\(.\)/\u\1/g' "$SCRIPTS/generate-index.sh" "$SCRIPTS/generate-mkdocs.sh" \
    | grep -cE '\$\{(site_|nav_|index_|section_|label_|table_|desc_|cell_|generated_by)' || true)
  if [ "$idx_n" -eq 1 ] && [ "$mk_n" -eq 2 ] && [ "$leaked" -eq 0 ]; then
    echo "OK: passthrough_intact (generate-index.sh=1, generate-mkdocs.sh=2, catalog-free)"
  else
    echo "FAIL: passthrough_intact — generate-index.sh=${idx_n} generate-mkdocs.sh=${mk_n} catalog_leak=${leaked}"
    FAIL=1
  fi
}

keyset_equality "$SCRIPTS/generate-index.sh"
keyset_equality "$SCRIPTS/generate-mkdocs.sh"

missing_key_halts generate-index.sh section_quick_start "${IDX_ARGS[@]}"
missing_key_halts generate-mkdocs.sh nav_home "${MKD_ARGS[@]}"
missing_key_halts generate-mkdocs.sh site_name_suffix "${MKD_ARGS[@]}"

intact_catalog_succeeds generate-index.sh "${IDX_ARGS[@]}"
intact_catalog_succeeds generate-mkdocs.sh "${MKD_ARGS[@]}"

bad_language_halts generate-mkdocs.sh TestProject .specs klingon

passthrough_intact

[ "$FAIL" -eq 1 ] && exit 1
exit 0
