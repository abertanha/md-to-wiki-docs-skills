#!/usr/bin/env bash
# ps1-contract.sh — Repeatable gate for the `.ps1` catalog contract
# (D-15, D-16, D-18, D-20, T-04-01, T-04-02, T-04-03, T-04-06).
# Usage: ps1-contract.sh (no arguments)
#
# Structural gates run on ANY host (no `pwsh` required) — they read source
# text only. Behavioral legs additionally exercise a real `pwsh` process and
# are SKIPPED (never silently) when `pwsh` is absent from the host, exactly
# like the `.ps1` leg of tests/regress.sh.
#
# Exit codes: 0 = every gate green, 1 = at least one gate failed, 3 = one or
# more legs SKIPPED (reason printed per leg) with zero failures. Never
# silent about a partial run.
#
# Every mutating probe copies scripts/, templates/ and the fixture .specs
# tree into its own `mktemp -d` sandbox before touching a catalog or running
# a twin — the real working tree is never mutated. Each sandbox is removed
# at the end of its probe.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
LIB="$SCRIPTS/lib"
TEMPLATES="$REPO_ROOT/templates"
TREE="$REPO_ROOT/tests/fixtures/tree/.specs"
CATALOG_EN="$TEMPLATES/lang/en.lang"
CATALOG_PTBR="$TEMPLATES/lang/pt-br.lang"

# The list of .ps1 twins under contract — a single variable so the plan
# 04-03 expansion (the other three twins) is a one-line change, not a
# rewrite of every gate below.
TWINS=(generate-index.ps1)

# Pin the locale before any gate, same rationale as every other harness in
# this suite: accented fixture names must survive title-casing/sorting.
export LC_ALL=C.UTF-8

FAIL=0
SKIP=0

sandbox_new() { # — mktemp sandbox with scripts/, templates/ and .specs copied in
	local sandbox
	sandbox=$(mktemp -d)
	cp -r "$SCRIPTS" "$sandbox/scripts"
	cp -r "$TEMPLATES" "$sandbox/templates"
	cp -r "$TREE" "$sandbox/.specs"
	printf '%s\n' "$sandbox"
}

# <pattern> <file> — line number of the first match whose line is NOT a
# full comment line (`^[[:space:]]*#`). Empty output when no such match.
first_call_line() {
	local pat="$1" file="$2"
	grep -n -E "$pat" "$file" 2>/dev/null | awk -F: '{
    rest = $0
    sub(/^[0-9]+:/, "", rest)
    if (rest !~ /^[[:space:]]*#/) { print $1; exit }
  }'
}

require_pwsh() { # <gate_name> — prints SKIPPED and returns 1 when pwsh is absent
	if ! command -v pwsh >/dev/null 2>&1; then
		echo "SKIPPED: $1 — pwsh not found on host (see tests/fixtures/manifest.md)"
		SKIP=1
		return 1
	fi
	return 0
}

# =====================================================================
# Structural gates (run on every host, no pwsh required)
# =====================================================================

# --- Gate: lib_single_source ------------------------------------------
# D-18: the parser lives once, in scripts/lib/catalog.ps1, never copied
# into a twin.
lib_single_source() {
	local count in_lib all_defined=1 fn
	count=$(grep -rn '^function Get-Catalog ' "$SCRIPTS" --include='*.ps1' | wc -l)
	in_lib=$(grep -c '^function Get-Catalog ' "$LIB/catalog.ps1" 2>/dev/null || echo 0)
	for fn in Resolve-OutputLang Get-CatalogPath Get-Catalog Assert-CatalogKey Write-Utf8NoBom Expand-CatalogEscapes; do
		grep -qE "^function ${fn} " "$LIB/catalog.ps1" || all_defined=0
	done
	if [ "$count" -eq 1 ] && [ "$in_lib" -eq 1 ] && [ "$all_defined" -eq 1 ]; then
		echo "OK: lib_single_source"
	else
		echo "FAIL: lib_single_source — Get-Catalog def count=${count} in_lib=${in_lib} all_six_defined=${all_defined}"
		FAIL=1
	fi
}

# --- Gate: twins_dotsource_lib ------------------------------------------
twins_dotsource_lib() {
	local twin ok=1 file line
	for twin in "${TWINS[@]}"; do
		file="$SCRIPTS/$twin"
		line=$(grep -nE '^\s*\.\s*\(' "$file" | grep 'PSScriptRoot' | grep 'lib/catalog\.ps1' | head -1)
		if [ -z "$line" ]; then
			echo "FAIL: twins_dotsource_lib ${twin} — no dot-source of lib/catalog.ps1 via \$PSScriptRoot found"
			FAIL=1
			ok=0
		fi
	done
	[ "$ok" -eq 1 ] && echo "OK: twins_dotsource_lib"
}

# --- Gate: allowlist_before_path -----------------------------------------
# T-04-01 / V5-V12: the allowlist gate must run strictly before the catalog
# path is built from the value — proves ORDER, not just presence.
allowlist_before_path() {
	local twin ok=1 r c file
	for twin in "${TWINS[@]}"; do
		file="$SCRIPTS/$twin"
		r=$(first_call_line 'Resolve-OutputLang' "$file")
		c=$(first_call_line 'Get-CatalogPath' "$file")
		if [ -n "$r" ] && [ -n "$c" ] && [ "$r" -lt "$c" ]; then
			:
		else
			echo "FAIL: allowlist_before_path ${twin} — resolve=${r:-none} catalog=${c:-none}"
			FAIL=1
			ok=0
		fi
	done
	[ "$ok" -eq 1 ] && echo "OK: allowlist_before_path"
}

# --- Gate: banned_cmdlets ------------------------------------------------
# Neither cmdlet may appear in a non-comment line of the lib or any twin
# under contract: Out-File adds a BOM on Windows PowerShell 5.1 (violates
# D-15); ConvertFrom-StringData cannot round-trip the catalog's quoting
# (Pitfall 1, 04-RESEARCH.md).
banned_cmdlets() {
	local files=("$LIB"/*.ps1) twin bad
	for twin in "${TWINS[@]}"; do files+=("$SCRIPTS/$twin"); done
	bad=$(cat "${files[@]}" | grep -vE '^[[:space:]]*#' | grep -cE 'Out-File|ConvertFrom-StringData' || true)
	if [ "$bad" -eq 0 ]; then
		echo "OK: banned_cmdlets"
	else
		echo "FAIL: banned_cmdlets — ${bad} occurrence(s) under contract"
		FAIL=1
	fi
}

# --- Gate: bomless_writer -------------------------------------------------
# D-15: the UTF8Encoding($false) construction lives once, in the lib; every
# twin under contract writes its output through Write-Utf8NoBom.
bomless_writer() {
	local count ok=1 twin
	# shellcheck disable=SC2016 # literal $false inside the grep pattern, not a shell expansion
	count=$(grep -cE 'UTF8Encoding[^)]*\$false' "$LIB/catalog.ps1")
	if [ "$count" -ne 1 ]; then
		echo "FAIL: bomless_writer — UTF8Encoding \$false construction count=${count} in lib (expected 1)"
		FAIL=1
		ok=0
	fi
	for twin in "${TWINS[@]}"; do
		if ! grep -q 'Write-Utf8NoBom' "$SCRIPTS/$twin"; then
			echo "FAIL: bomless_writer ${twin} — no Write-Utf8NoBom call"
			FAIL=1
			ok=0
		fi
	done
	[ "$ok" -eq 1 ] && echo "OK: bomless_writer"
}

# --- Gate: declared_keys_complete -----------------------------------------
# Permanent guard (same rationale as tests/fail-closed.sh's keyset_equality):
# the set of keys a twin READS ($Catalog['key']) must equal the set it
# DECLARES to Assert-CatalogKey ($RequiredKeys), so the up-front gate never
# falls out of sync with the body.
declared_keys_complete() {
	local twin ok=1 file declared expanded
	for twin in "${TWINS[@]}"; do
		file="$SCRIPTS/$twin"
		declared=$(awk '/\$RequiredKeys = @\(/{flag=1} flag{print} /^\)/{if(flag) exit}' "$file" |
			grep -oE "'[a-z][a-z0-9_]*'" | tr -d "'" | sort -u)
		expanded=$(grep -oE "\\\$Catalog\['[a-z][a-z0-9_]*'\\]" "$file" |
			sed -E "s/^\\\$Catalog\['//; s/'\\]\$//" | sort -u)
		if [ "$declared" = "$expanded" ]; then
			:
		else
			echo "FAIL: declared_keys_complete ${twin} — declared vs expanded diverge"
			diff <(printf '%s\n' "$declared") <(printf '%s\n' "$expanded") | sed 's/^/  /'
			FAIL=1
			ok=0
		fi
	done
	[ "$ok" -eq 1 ] && echo "OK: declared_keys_complete"
}

# --- Gate: no_hardcoded_chrome ---------------------------------------------
# SC1: zero hardcoded chrome string in any twin under contract. Literal
# (grep -F) comparison only — catalog values contain em-dash, parens and
# periods that would misbehave as regex.
no_hardcoded_chrome() {
	local ok=1 key value needle twin file stripped
	for twin in "${TWINS[@]}"; do
		file="$SCRIPTS/$twin"
		# Comment lines are never chrome. Every PowerShell variable TOKEN
		# ($fooBar) is stripped before the search: camelCase variable names
		# built from a key (e.g. $sectionOverview, $labelArchitecture) would
		# otherwise contain the key's own word fragments and false-positive
		# against a needle like "Overview" or "Architecture".
		stripped=$(grep -vE '^[[:space:]]*#' "$file" | sed -E 's/\$[A-Za-z0-9_]+//g')
		while IFS= read -r kv; do
			key="${kv%%=*}"
			value="${kv#*=}"
			value="${value#\'}"
			value="${value%\'}"
			needle="${value%%%s*}"
			[ "${#needle}" -lt 3 ] && continue
			if printf '%s\n' "$stripped" | grep -Fq -- "$needle"; then
				echo "FAIL: no_hardcoded_chrome ${twin} — chave ${key} hardcoded (needle: ${needle})"
				FAIL=1
				ok=0
			fi
		done < <(grep -E '^[a-z][a-z0-9_]*=' "$CATALOG_EN")
	done
	[ "$ok" -eq 1 ] && echo "OK: no_hardcoded_chrome"
}

# --- Gate: catalog_keys_exist ----------------------------------------------
# Catches a typo'd key that declared_keys_complete would miss (it only
# proves self-consistency between the twin's own declared/expanded sets).
catalog_keys_exist() {
	local twin ok=1 file used key catalog_keys
	catalog_keys=$(cat \
		<(grep -oE '^[a-z][a-z0-9_]*=' "$CATALOG_EN" | sed 's/=$//') \
		<(grep -oE '^[a-z][a-z0-9_]*=' "$CATALOG_PTBR" | sed 's/=$//') |
		sort -u)
	for twin in "${TWINS[@]}"; do
		file="$SCRIPTS/$twin"
		used=$(grep -oE "\\\$Catalog\['[a-z][a-z0-9_]*'\\]" "$file" |
			sed -E "s/^\\\$Catalog\['//; s/'\\]\$//" | sort -u)
		while IFS= read -r key; do
			[ -z "$key" ] && continue
			if ! printf '%s\n' "$catalog_keys" | grep -qxF "$key"; then
				echo "FAIL: catalog_keys_exist ${twin} — chave ${key} não existe em nenhum catálogo"
				FAIL=1
				ok=0
			fi
		done <<<"$used"
	done
	[ "$ok" -eq 1 ] && echo "OK: catalog_keys_exist"
}

# =====================================================================
# Behavioral legs (require a real `pwsh` on PATH; SKIPPED otherwise)
# =====================================================================

# --- Leg: pwsh_catalog_roundtrip -------------------------------------------
# Proves the parser's D-20 pitfalls in a live PowerShell process: keyset
# count, quote-boundary stripping, the escaped-apostrophe collapse and the
# trailing-comment discard.
pwsh_catalog_roundtrip() {
	require_pwsh "pwsh_catalog_roundtrip" || return 0
	local out status
	local snippet
	snippet=$(
		cat <<'PWSH'
. "$Env:LIB_PATH"
$en = Get-Catalog -CatalogPath $Env:EN_PATH
$pt = Get-Catalog -CatalogPath $Env:PTBR_PATH
$enVocab = (Get-Content $Env:EN_PATH | Select-String -Pattern '^[a-z][a-z0-9_]*=').Count
$ptVocab = (Get-Content $Env:PTBR_PATH | Select-String -Pattern '^[a-z][a-z0-9_]*=').Count
if ($en.Count -ne $enVocab) { Write-Output "FAIL:en_count $($en.Count) vs $enVocab" } else { Write-Output "OK:en_count" }
if ($pt.Count -ne $ptVocab) { Write-Output "FAIL:pt_count $($pt.Count) vs $ptVocab" } else { Write-Output "OK:pt_count" }
$boundaryBad = $false
foreach ($v in (@($en.Values) + @($pt.Values))) {
  if ($v.StartsWith("'") -or $v.EndsWith("'")) { $boundaryBad = $true }
}
if ($boundaryBad) { Write-Output "FAIL:boundary" } else { Write-Output "OK:boundary" }
$steps = $en['dokuwiki_readme_steps']
if ($steps -like "*DokuWiki's*" -and $steps -notlike "*\'*") { Write-Output "OK:apostrophe" } else { Write-Output "FAIL:apostrophe" }
$toc = $pt['pdf_toc_title']
if ($toc -notlike "*#*" -and $toc -notlike "*exclusiva*") { Write-Output "OK:comment_discard" } else { Write-Output "FAIL:comment_discard" }
PWSH
	)
	out=$(EN_PATH="$CATALOG_EN" PTBR_PATH="$CATALOG_PTBR" LIB_PATH="$LIB/catalog.ps1" \
		pwsh -NoProfile -NonInteractive -Command "$snippet" 2>&1) && status=0 || status=$?
	if [ "$status" -eq 0 ] && ! printf '%s\n' "$out" | grep -q 'FAIL:'; then
		echo "OK: pwsh_catalog_roundtrip"
	else
		echo "FAIL: pwsh_catalog_roundtrip — status=${status}"
		printf '%s\n' "$out" | sed 's/^/  /'
		FAIL=1
	fi
}

# --- Leg: pwsh_bad_language_halts ------------------------------------------
pwsh_bad_language_halts() {
	require_pwsh "pwsh_bad_language_halts" || return 0
	local twin ok=1 sandbox out status
	for twin in "${TWINS[@]}"; do
		sandbox=$(sandbox_new)
		out=$(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" TestProject general klingon 2>&1) && status=0 || status=$?
		rm -rf "$sandbox"
		if [ "$status" -ne 0 ] && printf '%s\n' "$out" | grep -qE 'en, pt-br|pt-br, en'; then
			:
		else
			echo "FAIL: pwsh_bad_language_halts ${twin} — status=${status}"
			printf '%s\n' "$out" | sed 's/^/  /'
			FAIL=1
			ok=0
		fi
	done
	[ "$ok" -eq 1 ] && echo "OK: pwsh_bad_language_halts"
}

# --- Leg: pwsh_missing_key_halts -------------------------------------------
pwsh_missing_key_halts() {
	require_pwsh "pwsh_missing_key_halts" || return 0
	local twin ok=1 sandbox out status
	for twin in "${TWINS[@]}"; do
		sandbox=$(sandbox_new)
		sed -i '/^section_overview=/d' "$sandbox/templates/lang/en.lang"
		out=$(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" TestProject general en .specs/features 2>&1) && status=0 || status=$?
		rm -rf "$sandbox"
		if [ "$status" -ne 0 ] && printf '%s\n' "$out" | grep -q 'section_overview'; then
			:
		else
			echo "FAIL: pwsh_missing_key_halts ${twin} — status=${status}"
			printf '%s\n' "$out" | sed 's/^/  /'
			FAIL=1
			ok=0
		fi
	done
	[ "$ok" -eq 1 ] && echo "OK: pwsh_missing_key_halts"
}

# --- Leg: pwsh_intact_catalog_succeeds --------------------------------------
# Positive control for the two gates above — without it, either could pass
# for a reason unrelated to the mutation under test.
pwsh_intact_catalog_succeeds() {
	require_pwsh "pwsh_intact_catalog_succeeds" || return 0
	local twin ok=1 sandbox out status lang
	for twin in "${TWINS[@]}"; do
		for lang in en pt-br; do
			sandbox=$(sandbox_new)
			out=$(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" TestProject general "$lang" .specs/features 2>&1) && status=0 || status=$?
			rm -rf "$sandbox"
			if [ "$status" -ne 0 ]; then
				echo "FAIL: pwsh_intact_catalog_succeeds ${twin} (${lang}) — status=${status}"
				printf '%s\n' "$out" | sed 's/^/  /'
				FAIL=1
				ok=0
			fi
		done
	done
	[ "$ok" -eq 1 ] && echo "OK: pwsh_intact_catalog_succeeds"
}

# --- Leg: pwsh_output_has_no_bom -------------------------------------------
pwsh_output_has_no_bom() {
	require_pwsh "pwsh_output_has_no_bom" || return 0
	local twin ok=1 sandbox status b
	for twin in "${TWINS[@]}"; do
		sandbox=$(sandbox_new)
		(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" TestProject general en .specs/features >/dev/null 2>&1)
		status=$?
		if [ "$status" -eq 0 ] && [ -f "$sandbox/docs/index.md" ]; then
			b=$(head -c3 "$sandbox/docs/index.md" | od -An -tx1 | tr -d ' \n')
			if [ "$b" = "efbbbf" ]; then
				echo "FAIL: pwsh_output_has_no_bom ${twin} — BOM found"
				FAIL=1
				ok=0
			fi
		else
			echo "FAIL: pwsh_output_has_no_bom ${twin} — generation failed, status=${status}"
			FAIL=1
			ok=0
		fi
		rm -rf "$sandbox"
	done
	[ "$ok" -eq 1 ] && echo "OK: pwsh_output_has_no_bom"
}

# --- Leg: pwsh_accented_dir_survives ----------------------------------------
pwsh_accented_dir_survives() {
	require_pwsh "pwsh_accented_dir_survives" || return 0
	local twin ok=1 sandbox status generated
	for twin in "${TWINS[@]}"; do
		sandbox=$(sandbox_new)
		(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" TestProject general en .specs/features >/dev/null 2>&1)
		status=$?
		generated=$(cat "$sandbox/docs/index.md" 2>/dev/null || true)
		rm -rf "$sandbox"
		if [ "$status" -eq 0 ] && printf '%s\n' "$generated" | grep -qF 'autenticação'; then
			:
		else
			echo "FAIL: pwsh_accented_dir_survives ${twin} — status=${status}"
			FAIL=1
			ok=0
		fi
	done
	[ "$ok" -eq 1 ] && echo "OK: pwsh_accented_dir_survives"
}

lib_single_source
twins_dotsource_lib
allowlist_before_path
banned_cmdlets
bomless_writer
declared_keys_complete
no_hardcoded_chrome
catalog_keys_exist

pwsh_catalog_roundtrip
pwsh_bad_language_halts
pwsh_missing_key_halts
pwsh_intact_catalog_succeeds
pwsh_output_has_no_bom
pwsh_accented_dir_survives

[ "$FAIL" -eq 1 ] && exit 1
[ "$SKIP" -eq 1 ] && exit 3
exit 0
