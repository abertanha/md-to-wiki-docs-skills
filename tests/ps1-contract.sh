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

# The list of .ps1 twins under contract — a single variable so a future
# expansion is a one-line change, not a rewrite of every gate below. Plan
# 04-03 is the expansion that brought the three twins beyond generate-index.ps1
# into this list (D-19/D-25 froze them until this plan).
TWINS=(generate-index.ps1 generate-mkdocs.ps1 to-pdf.ps1 to-dokuwiki.ps1)

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

# <twin> <lang> — canonical positional args for a twin, one per line, so
# callers can `mapfile -t args < <(twin_canonical_args ...)`. Pins mirror
# tests/fixtures/manifest.md's invocation table and format-pdf.md's file
# order; kept as a single source so the four behavioral legs below never
# drift into four different ad hoc argument lists.
twin_canonical_args() {
	local twin="$1" lang="$2"
	case "$twin" in
	generate-index.ps1)
		printf '%s\n' TestProject general "$lang" .specs/features
		;;
	generate-mkdocs.ps1)
		printf '%s\n' TestProject .specs "$lang"
		;;
	to-pdf.ps1)
		printf '%s\n' out/specs-book.pdf "$lang" \
			.specs/project/PROJECT.md .specs/project/ROADMAP.md \
			.specs/codebase/ARCHITECTURE.md \
			.specs/features/login/spec.md .specs/features/login/design.md \
			".specs/features/autenticação/spec.md" \
			.specs/quick/fix-nav/spec.md
		;;
	to-dokuwiki.ps1)
		printf '%s\n' dokuwiki "$lang" \
			.specs/project/PROJECT.md .specs/project/ROADMAP.md \
			.specs/codebase/ARCHITECTURE.md \
			.specs/features/login/spec.md .specs/features/login/design.md \
			".specs/features/autenticação/spec.md" \
			.specs/quick/fix-nav/spec.md
		;;
	esac
}

# <twin> — the catalog key this twin declares unconditionally, used by
# pwsh_missing_key_halts to remove exactly one key per twin.
twin_required_key() {
	case "$1" in
	generate-index.ps1) printf 'section_overview\n' ;;
	generate-mkdocs.ps1) printf 'site_name_suffix\n' ;;
	to-pdf.ps1) printf 'pdf_title\n' ;;
	to-dokuwiki.ps1) printf 'dokuwiki_readme_heading\n' ;;
	esac
}

# <twin> — the generated artifact path (relative to the sandbox) whose
# bytes pwsh_output_has_no_bom inspects for a BOM.
twin_output_path() {
	case "$1" in
	generate-index.ps1) printf 'docs/index.md\n' ;;
	generate-mkdocs.ps1) printf 'docs/mkdocs.yml\n' ;;
	to-pdf.ps1) printf 'out/specs-book.md\n' ;;
	to-dokuwiki.ps1) printf 'dokuwiki/README.md\n' ;;
	esac
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
# the set of keys a twin READS ($Catalog['key']) must equal the UNION of
# every key array it declares to Assert-CatalogKey, so the up-front gate
# never falls out of sync with the body. A twin may declare a key
# conditionally via a SEPARATE Assert-CatalogKey call outside its main
# $RequiredKeys block (e.g. to-pdf.ps1's pt-br-only pdf_toc_title) — the
# scan below unions every `@(...)` key-literal array in the file, not just
# the first one.
declared_keys_complete() {
	local twin ok=1 file declared expanded
	for twin in "${TWINS[@]}"; do
		file="$SCRIPTS/$twin"
		declared=$(awk '
      /@\(/ { flag=1 }
      flag { print }
      /\)/ { if (flag) flag=0 }
    ' "$file" | grep -oE "'[a-z][a-z0-9_]*'" | tr -d "'" | sort -u)
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
		# Comment lines are never chrome. Every PowerShell variable TOKEN is
		# stripped before the search, in BOTH interpolation forms ($fooBar and
		# ${fooBar}): camelCase variable names built from a key (e.g.
		# $sectionOverview, ${navHome}) would otherwise contain the key's own
		# word fragments and false-positive against a needle like "Overview"
		# or "Home".
		stripped=$(grep -vE '^[[:space:]]*#' "$file" | sed -E 's/\$\{[A-Za-z0-9_]+\}//g; s/\$[A-Za-z0-9_]+//g')
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

# --- Gate: theme_language_ptbr_only ----------------------------------------
# QUAL-01/D-12: the `theme.language` projection in generate-mkdocs.ps1 is
# ADDITIVE — the `pt-BR` literal must appear exactly once, inside the
# pt-br branch of the projection switch, and the en branch must assign an
# empty string (never the key).
theme_language_ptbr_only() {
	local file="$SCRIPTS/generate-mkdocs.ps1" count line branch_line en_empty
	count=$(grep -c 'pt-BR' "$file")
	line=$(grep -n 'pt-BR' "$file" | tail -1 | cut -d: -f1)
	branch_line=$(grep -n "'pt-br' {" "$file" | tail -1 | cut -d: -f1)
	en_empty=$(grep -cF "ThemeLanguage = ''" "$file")
	if [ "$count" -eq 1 ] && [ -n "$branch_line" ] && [ -n "$line" ] && [ "$line" -ge "$branch_line" ] && [ "$en_empty" -ge 1 ]; then
		echo "OK: theme_language_ptbr_only"
	else
		echo "FAIL: theme_language_ptbr_only — count=${count} line=${line:-none} branch_line=${branch_line:-none} en_empty=${en_empty}"
		FAIL=1
	fi
}

# --- Gate: pandoc_langopts_all_invocations ---------------------------------
# QUAL-01, the lesson from plan 03-02: covering only the first pandoc
# invocation lets a PDF built by a fallback engine ship without the locale.
# The reference count of $PandocLangOpts must be at least the number of
# pandoc invocations found, and there must be at least one invocation to
# anchor the comparison — a zero/zero pass would be vacuous, not proof.
pandoc_langopts_all_invocations() {
	local file="$SCRIPTS/to-pdf.ps1" inv spl
	# shellcheck disable=SC2016 # literal $pandoc/$ inside the grep pattern, not a shell expansion
	inv=$(grep -cE '(&[[:space:]]*\$pandoc|[^a-zA-Z-]pandoc[[:space:]]+\$)' "$file")
	spl=$(grep -c 'PandocLangOpts' "$file")
	if [ "$inv" -ge 1 ] && [ "$spl" -ge "$inv" ]; then
		echo "OK: pandoc_langopts_all_invocations"
	else
		echo "FAIL: pandoc_langopts_all_invocations — invocations=${inv} langopt_refs=${spl}"
		FAIL=1
	fi
}

# --- Gate: bootstrap_before_pandoc_guard -----------------------------------
# CHROME-03/T-03-08: in to-dokuwiki.ps1, the catalog key bootstrap must run
# BEFORE the pandoc availability guard, so a missing key halts naming the
# key even on a host without pandoc.
bootstrap_before_pandoc_guard() {
	local file="$SCRIPTS/to-dokuwiki.ps1" a p
	a=$(first_call_line 'Assert-CatalogKey' "$file")
	p=$(first_call_line 'Get-Command "?pandoc' "$file")
	if [ -n "$a" ] && [ -n "$p" ] && [ "$a" -lt "$p" ]; then
		echo "OK: bootstrap_before_pandoc_guard"
	else
		echo "FAIL: bootstrap_before_pandoc_guard — assert=${a:-none} pandoc_guard=${p:-none}"
		FAIL=1
	fi
}

# --- Gate: expand_escapes_scoped --------------------------------------------
# Expand-CatalogEscapes must not leak beyond the one value it mirrors from
# the .sh twin (`printf '%b'` applied only to dokuwiki_readme_steps) — at
# most two occurrences total across scripts/ (its own definition in the lib,
# plus the single call site), and that call site must be associated with
# dokuwiki_readme_steps specifically.
expand_escapes_scoped() {
	local file="$SCRIPTS/to-dokuwiki.ps1" total scoped=0
	total=$(grep -c 'Expand-CatalogEscapes' "$LIB"/*.ps1 "$SCRIPTS"/*.ps1 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
	grep -A2 -B2 'Expand-CatalogEscapes' "$file" | grep -qF 'dokuwiki_readme_steps' && scoped=1
	if [ "$total" -le 2 ] && [ "$scoped" -eq 1 ]; then
		echo "OK: expand_escapes_scoped"
	else
		echo "FAIL: expand_escapes_scoped — total=${total} scoped=${scoped}"
		FAIL=1
	fi
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
	local twin ok=1 sandbox out status args
	for twin in "${TWINS[@]}"; do
		sandbox=$(sandbox_new)
		mapfile -t args < <(twin_canonical_args "$twin" klingon)
		out=$(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" "${args[@]}" 2>&1) && status=0 || status=$?
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
	local twin ok=1 sandbox out status args key
	for twin in "${TWINS[@]}"; do
		sandbox=$(sandbox_new)
		key=$(twin_required_key "$twin")
		sed -i "/^${key}=/d" "$sandbox/templates/lang/en.lang"
		mapfile -t args < <(twin_canonical_args "$twin" en)
		out=$(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" "${args[@]}" 2>&1) && status=0 || status=$?
		rm -rf "$sandbox"
		if [ "$status" -ne 0 ] && printf '%s\n' "$out" | grep -q "$key"; then
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
	local twin ok=1 sandbox out status lang args
	for twin in "${TWINS[@]}"; do
		for lang in en pt-br; do
			sandbox=$(sandbox_new)
			mapfile -t args < <(twin_canonical_args "$twin" "$lang")
			out=$(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" "${args[@]}" 2>&1) && status=0 || status=$?
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
	local twin ok=1 sandbox status b args out_path
	for twin in "${TWINS[@]}"; do
		sandbox=$(sandbox_new)
		mapfile -t args < <(twin_canonical_args "$twin" en)
		(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" "${args[@]}" >/dev/null 2>&1)
		status=$?
		out_path="$sandbox/$(twin_output_path "$twin")"
		if [ "$status" -eq 0 ] && [ -f "$out_path" ]; then
			b=$(head -c3 "$out_path" | od -An -tx1 | tr -d ' \n')
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
# generate-index.ps1 and to-dokuwiki.ps1 each receive a file living under
# the fixture's accented directory (.specs/features/autenticação/) and are
# asserted against the site each one actually reaches: generate-index.ps1
# derives a visible link path from the directory, to-dokuwiki.ps1 writes a
# page file AT that path. to-pdf.ps1 has no directory-derived output at all
# (D-19 preserves its lack of per-file headings), so its probe instead
# proves the accented-path FILE was read successfully via content unique to
# it. generate-mkdocs.ps1's own nav traversal is one level deep
# (Get-ChildItem without -Recurse, a pre-existing divergence out of this
# plan's scope per the "Não-objetivos" table) and never reaches a nested
# accented directory at all — its probe is limited to a clean exit.
pwsh_accented_dir_survives() {
	require_pwsh "pwsh_accented_dir_survives" || return 0
	local twin ok=1 sandbox status args generated out_path
	for twin in "${TWINS[@]}"; do
		sandbox=$(sandbox_new)
		mapfile -t args < <(twin_canonical_args "$twin" en)
		(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/${twin}" "${args[@]}" >/dev/null 2>&1)
		status=$?
		case "$twin" in
		to-dokuwiki.ps1)
			out_path="$sandbox/dokuwiki/data/pages/features/autenticação/spec.txt"
			if [ "$status" -ne 0 ] || [ ! -f "$out_path" ]; then
				echo "FAIL: pwsh_accented_dir_survives ${twin} — status=${status}, page not found at accented path"
				FAIL=1
				ok=0
			fi
			;;
		to-pdf.ps1)
			generated=$(cat "$sandbox/out/specs-book.md" 2>/dev/null || true)
			if [ "$status" -ne 0 ] || ! printf '%s\n' "$generated" | grep -qF 'authentication feature governs'; then
				echo "FAIL: pwsh_accented_dir_survives ${twin} — status=${status}"
				FAIL=1
				ok=0
			fi
			;;
		generate-mkdocs.ps1)
			if [ "$status" -ne 0 ]; then
				echo "FAIL: pwsh_accented_dir_survives ${twin} — status=${status}"
				FAIL=1
				ok=0
			fi
			;;
		*)
			generated=$(cat "$sandbox/$(twin_output_path "$twin")" 2>/dev/null || true)
			if [ "$status" -ne 0 ] || ! printf '%s\n' "$generated" | grep -qF 'autenticação'; then
				echo "FAIL: pwsh_accented_dir_survives ${twin} — status=${status}"
				FAIL=1
				ok=0
			fi
			;;
		esac
		rm -rf "$sandbox"
	done
	[ "$ok" -eq 1 ] && echo "OK: pwsh_accented_dir_survives"
}

# --- Leg: pwsh_pandoc_langopts ----------------------------------------------
# Counterpart of tests/fail-closed.sh's pandoc_lang_flags — proves the
# EFFECTIVE pandoc command line to-pdf.ps1 builds, with a stub `pandoc` (and
# a stub `weasyprint` so Get-Command finds an engine) — no real PDF engine
# needed.
pwsh_pandoc_langopts() {
	require_pwsh "pwsh_pandoc_langopts" || return 0
	local lang sandbox out status args_file ok=1
	for lang in pt-br en; do
		sandbox=$(sandbox_new)
		mkdir -p "$sandbox/bin"
		cat >"$sandbox/bin/pandoc" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$(dirname "$0")/../pandoc-args.txt"
exit 0
STUB
		chmod +x "$sandbox/bin/pandoc"
		cat >"$sandbox/bin/weasyprint" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
		chmod +x "$sandbox/bin/weasyprint"
		args_file="$sandbox/pandoc-args.txt"
		out=$(cd "$sandbox" && PATH="$sandbox/bin:$PATH" \
			pwsh -NoProfile -NonInteractive -File "scripts/to-pdf.ps1" out/specs-book.pdf "$lang" .specs/project/PROJECT.md 2>&1) && status=0 || status=$?
		case "$lang" in
		pt-br)
			if [ "$status" -eq 0 ] && grep -qF -- '-M lang=pt-BR' "$args_file" 2>/dev/null &&
				grep -qF -- '-M toc-title=Sumário' "$args_file" 2>/dev/null; then
				:
			else
				echo "FAIL: pwsh_pandoc_langopts pt-br — status=${status}"
				printf '%s\n' "$out"
				cat "$args_file" 2>/dev/null | sed 's/^/  /'
				FAIL=1
				ok=0
			fi
			;;
		en)
			if [ "$status" -eq 0 ] && ! grep -qF -- '-M lang' "$args_file" 2>/dev/null &&
				! grep -qF -- '-M toc-title' "$args_file" 2>/dev/null; then
				:
			else
				echo "FAIL: pwsh_pandoc_langopts en — status=${status}"
				printf '%s\n' "$out"
				cat "$args_file" 2>/dev/null | sed 's/^/  /'
				FAIL=1
				ok=0
			fi
			;;
		esac
		rm -rf "$sandbox"
	done
	[ "$ok" -eq 1 ] && echo "OK: pwsh_pandoc_langopts"
}

# --- Leg: pwsh_theme_language -----------------------------------------------
pwsh_theme_language() {
	require_pwsh "pwsh_theme_language" || return 0
	local sandbox status yaml ok=1

	sandbox=$(sandbox_new)
	(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/generate-mkdocs.ps1" TestProject .specs pt-br >/dev/null 2>&1)
	status=$?
	yaml=$(cat "$sandbox/docs/mkdocs.yml" 2>/dev/null || true)
	rm -rf "$sandbox"
	if [ "$status" -ne 0 ] || ! printf '%s\n' "$yaml" | grep -qE '^[[:space:]]*language: pt-BR'; then
		echo "FAIL: pwsh_theme_language pt-br — status=${status}"
		FAIL=1
		ok=0
	fi

	sandbox=$(sandbox_new)
	(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/generate-mkdocs.ps1" TestProject .specs en >/dev/null 2>&1)
	status=$?
	yaml=$(cat "$sandbox/docs/mkdocs.yml" 2>/dev/null || true)
	rm -rf "$sandbox"
	if [ "$status" -ne 0 ] || printf '%s\n' "$yaml" | grep -qE '^[[:space:]]*language:'; then
		echo "FAIL: pwsh_theme_language en — status=${status}"
		FAIL=1
		ok=0
	fi

	[ "$ok" -eq 1 ] && echo "OK: pwsh_theme_language"
}

# --- Leg: pwsh_dokuwiki_value_shape ------------------------------------------
# Also gated on a real `pandoc` (to-dokuwiki.ps1 itself refuses to run
# without it) — SKIPPED, never silent, when absent.
pwsh_dokuwiki_value_shape() {
	require_pwsh "pwsh_dokuwiki_value_shape" || return 0
	if ! command -v pandoc >/dev/null 2>&1; then
		echo "SKIPPED: pwsh_dokuwiki_value_shape — pandoc not found on host (dev-only dependency, see tests/fixtures/manifest.md)"
		SKIP=1
		return 0
	fi
	local sandbox status readme args first3 ok=1
	sandbox=$(sandbox_new)
	mapfile -t args < <(twin_canonical_args to-dokuwiki.ps1 en)
	(cd "$sandbox" && pwsh -NoProfile -NonInteractive -File "scripts/to-dokuwiki.ps1" "${args[@]}" >/dev/null 2>&1)
	status=$?
	readme=$(cat "$sandbox/dokuwiki/README.md" 2>/dev/null || true)
	first3=$(head -c3 "$sandbox/dokuwiki/README.md" 2>/dev/null | od -An -tx1 | tr -d ' \n')
	rm -rf "$sandbox"

	if [ "$status" -ne 0 ]; then
		echo "FAIL: pwsh_dokuwiki_value_shape — status=${status}"
		FAIL=1
		ok=0
	fi
	if ! printf '%s\n' "$readme" | grep -qF "DokuWiki's" || printf '%s\n' "$readme" | grep -qF "\\'"; then
		echo "FAIL: pwsh_dokuwiki_value_shape — apostrophe not collapsed cleanly"
		FAIL=1
		ok=0
	fi
	if [ "$(printf '%s\n' "$readme" | grep -cE '^[0-9]\. ')" -ne 4 ]; then
		echo "FAIL: pwsh_dokuwiki_value_shape — steps not on four separate lines"
		FAIL=1
		ok=0
	fi
	if [ "$first3" = "efbbbf" ]; then
		echo "FAIL: pwsh_dokuwiki_value_shape — BOM found"
		FAIL=1
		ok=0
	fi
	[ "$ok" -eq 1 ] && echo "OK: pwsh_dokuwiki_value_shape"
}

lib_single_source
twins_dotsource_lib
allowlist_before_path
banned_cmdlets
bomless_writer
declared_keys_complete
no_hardcoded_chrome
catalog_keys_exist
theme_language_ptbr_only
pandoc_langopts_all_invocations
bootstrap_before_pandoc_guard
expand_escapes_scoped

pwsh_catalog_roundtrip
pwsh_bad_language_halts
pwsh_missing_key_halts
pwsh_intact_catalog_succeeds
pwsh_output_has_no_bom
pwsh_accented_dir_survives
pwsh_pandoc_langopts
pwsh_theme_language
pwsh_dokuwiki_value_shape

[ "$FAIL" -eq 1 ] && exit 1
[ "$SKIP" -eq 1 ] && exit 3
exit 0
