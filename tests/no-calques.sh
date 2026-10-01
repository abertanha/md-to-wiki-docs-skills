#!/usr/bin/env bash
# no-calques.sh — QUAL-03 gate: the anti-calque glossary decides completion,
# not a subjective read of the pt-br prose.
# Usage: no-calques.sh (no arguments)
#
# Contract: the denylist (anglicized-verb calques) and the LLM-tic list live
# as arrays in this file — the executable predicate for the rule recorded in
# CONTEXT.md's "Glossário anti-calque" section. Six gates run: two audit the
# static prose and the generated pt-br surfaces, one audits the pt-br
# catalog values, and two are controls that prove the first three cannot
# pass by vacuity (a broken pattern or an over-eager one).
#
# Exit codes: 0 = all six gates green, 1 = at least one FAIL:, 3 = at least
# one leg SKIPPED for a missing dev dependency (pandoc). Never silent.
#
# Scope: NEVER scans docs/specs/** nor the PDF book body — that is user
# content the skill does not translate (Out of Scope, PROJECT.md).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
TEMPLATES="$REPO_ROOT/templates"
TREE="$REPO_ROOT/tests/fixtures/tree/.specs"
CATALOG_PTBR="$TEMPLATES/lang/pt-br.lang"

# Pin the locale so the grep patterns below match accented characters
# correctly (same rationale as the other harnesses in this directory).
export LC_ALL=C.UTF-8

FAIL=0
SKIP=0

# Denylist of anglicized-verb calques absent from the VOLP (D-23/D-24 in
# 04-02-PLAN.md) — one ERE per array element so a failing match can name
# WHICH pattern hit, not just "something matched". Flexions covered:
# infinitive, 1st/3rd preterite, gerund, participle, singular/plural.
CALQUE_DENYLIST=(
	'deploy(ar|ei|ou|aram|ando|ado|ados)'
	'print(ar|ei|ou|aram|ando|ado|ados)'
	'commit(ar|ei|ou|aram|ando|ado|ados)'
	'push(ear|eei|eou|earam|eando|eado|eados)'
	'link(ar|ei|ou|aram|ando|ado|ados)'
	'build(ar|ei|ou|aram|ando|ado|ados)'
	'debug(ar|ei|ou|aram|ando|ado|ados)'
	'start(ar|ei|ou|aram|ando|ado|ados)'
	'merge(ar|ei|ou|aram|ando|ado|ados)'
	'up(ar|ei|ou|aram|ando|ado|ados)'
)

# LLM-tic phrases — separate from anglicism calques, same completion gate.
LLM_TIC_DENYLIST=(
	'é importante notar'
	'em resumo'
	'convém destacar'
	'vale ressaltar'
	'vale notar'
	'em última análise'
)

# Prose surfaces scanned for D3 (denylist_clean_prose). `tests/` is
# EXPLICITLY excluded — this very script carries the denylist literals, so
# scanning itself would always fail. `README.md` is excluded — it is
# English prose. `.planning/` is excluded — process artifact, not prose the
# skill publishes.
SCAN_SURFACES=(CONTEXT.md SKILL.md README.pt-BR.md agents docs)

# --- strip_ignored_regions (D-22) ------------------------------------------
# Prints <file> with the region between the two ignore sentinels removed —
# the region exists so the glossary can cite the calques it forbids without
# failing its own gate. An unbalanced region (start without end, or nested
# start) is an error: it would silently blank the rest of the file and let
# the gate pass by vacuity, so it prints a FAIL line and returns non-zero
# instead.
strip_ignored_regions() { # <file>
	local file="$1"
	awk -v file="$file" '
    /no-calques:ignore-start/ {
      if (in_region == 1) { unbalanced = 1 }
      in_region = 1
      next
    }
    /no-calques:ignore-end/ {
      if (in_region == 0) { unbalanced = 1 }
      in_region = 0
      next
    }
    { if (in_region == 0) print }
    END {
      if (in_region == 1) { unbalanced = 1 }
      if (unbalanced == 1) {
        print "FAIL: unbalanced_ignore_region " file
        exit 1
      }
    }
  ' "$file"
}

# --- scan_text --------------------------------------------------------------
# Receives a label and a text blob; prints one FAIL line per pattern match
# (calque or LLM tic) and returns non-zero when anything matched. Does NOT
# touch the global FAIL/SKIP accumulators — the caller decides, because the
# positive control (gate_is_load_bearing) needs to call this EXPECTING a
# match without poisoning the overall gate result.
scan_text() { # <label> <text>
	local label="$1" text="$2" pattern line status=0
	for pattern in "${CALQUE_DENYLIST[@]}" "${LLM_TIC_DENYLIST[@]}"; do
		while IFS= read -r line; do
			[ -z "$line" ] && continue
			echo "FAIL: calque ${label} — padrão ${pattern} casou: ${line}"
			status=1
		done < <(printf '%s\n' "$text" | grep -noE "$pattern" || true)
	done
	return "$status"
}

# --- collect_prose_files ----------------------------------------------------
# Expands SCAN_SURFACES (files and directories) into a flat list of markdown
# files to scan, recursing into directories.
collect_prose_files() {
	local surface
	for surface in "${SCAN_SURFACES[@]}"; do
		local path="$REPO_ROOT/$surface"
		if [ -d "$path" ]; then
			find "$path" -type f -name '*.md' -print
		elif [ -f "$path" ]; then
			printf '%s\n' "$path"
		fi
	done
}

# --- Gate: denylist_clean_prose ---------------------------------------------
# For every file under SCAN_SURFACES, strip the ignored regions and scan the
# rest. Zero matches is the condition of green.
denylist_clean_prose() {
	local file text clean=1
	while IFS= read -r file; do
		if ! text=$(strip_ignored_regions "$file"); then
			FAIL=1
			clean=0
			continue
		fi
		if ! scan_text "$(basename "$file")" "$text"; then
			FAIL=1
			clean=0
		fi
	done < <(collect_prose_files)
	[ "$clean" -eq 1 ] && echo "OK: denylist_clean_prose"
}

# --- Gate: denylist_clean_ptbr_output ---------------------------------------
# Generates the five publishable surfaces with OUTPUT_LANG=pt-br in a
# sandbox and scans the SAME chrome slices no-mixed-output.sh scans (the
# "Escopo e allowlist" table in 03-03-PLAN.md) — never docs/specs/** nor the
# PDF book body, which is user content this skill never translates.
denylist_clean_ptbr_output() {
	[ -d "$TREE" ] || {
		echo "ERROR: fixture tree not found: $TREE" >&2
		exit 1
	}

	local work
	work=$(mktemp -d)
	cp -r "$TREE" "$work/.specs"

	(
		cd "$work"
		bash "$SCRIPTS/generate-mkdocs.sh" TestProject .specs pt-br >/dev/null
		bash "$SCRIPTS/generate-index.sh" TestProject general pt-br docs/specs/features >/dev/null
		bash "$SCRIPTS/to-pdf.sh" out/specs-book.pdf pt-br \
			.specs/project/PROJECT.md .specs/project/ROADMAP.md \
			.specs/codebase/ARCHITECTURE.md \
			.specs/features/login/spec.md .specs/features/login/design.md \
			.specs/features/autenticação/spec.md \
			.specs/quick/fix-nav/spec.md >/dev/null
		mkdir -p swagger-ui
		(
			set -a
			# shellcheck source=/dev/null
			. "$CATALOG_PTBR"
			set +a
			: "${swagger_title_suffix:?key swagger_title_suffix not found in catalog}"
			sed -e 's/{{PROJECT_NAME}}/TestProject/g' \
				-e 's|{{OPENAPI_YML}}|openapi.yml|g' \
				-e "s|{{TITLE_SUFFIX}}|${swagger_title_suffix}|g" \
				-e 's|{{LANG_ATTR}}| lang="pt-BR"|g' \
				"$TEMPLATES/swagger-ui.html" >swagger-ui/index.html
		)
	)

	local dokuwiki_ran=0
	if command -v pandoc >/dev/null 2>&1; then
		(
			cd "$work"
			bash "$SCRIPTS/to-dokuwiki.sh" dw pt-br \
				.specs/project/PROJECT.md .specs/project/ROADMAP.md \
				.specs/codebase/ARCHITECTURE.md \
				.specs/features/login/spec.md .specs/features/login/design.md \
				.specs/features/autenticação/spec.md \
				.specs/quick/fix-nav/spec.md >/dev/null
		)
		dokuwiki_ran=1
	else
		echo "SKIPPED: pandoc not found on host — DokuWiki leg of denylist_clean_ptbr_output needs the dev-only dependency (sudo apt install pandoc; see tests/fixtures/manifest.md)"
		SKIP=1
	fi

	local mkdocs_text index_text pdf_text swagger_text dokuwiki_text clean=1
	mkdocs_text=$(grep -E '^site_name:|^site_description:|: index\.md$' "$work/mkdocs.yml" || true)
	index_text=$(cat "$work/docs/index.md")
	pdf_text=$(head -1 "$work/out/specs-book.md")
	swagger_text=$(cat "$work/swagger-ui/index.html")
	dokuwiki_text=""
	[ "$dokuwiki_ran" -eq 1 ] && dokuwiki_text=$(cat "$work/dw/README.md")

	scan_text "mkdocs (pt-br)" "$mkdocs_text" || {
		FAIL=1
		clean=0
	}
	scan_text "index (pt-br)" "$index_text" || {
		FAIL=1
		clean=0
	}
	scan_text "pdf (pt-br)" "$pdf_text" || {
		FAIL=1
		clean=0
	}
	scan_text "swagger (pt-br)" "$swagger_text" || {
		FAIL=1
		clean=0
	}
	if [ "$dokuwiki_ran" -eq 1 ]; then
		scan_text "dokuwiki (pt-br)" "$dokuwiki_text" || {
			FAIL=1
			clean=0
		}
	fi

	rm -rf "$work"

	[ "$clean" -eq 1 ] && echo "OK: denylist_clean_ptbr_output"
}

# --- Gate: denylist_clean_catalog -------------------------------------------
# Scans the VALUES of templates/lang/pt-br.lang (not the header comment,
# which is maintenance prose and may cite a technical term freely). Keys are
# extracted the same way tests/fail-closed.sh's catalog_parity does.
denylist_clean_catalog() {
	local keys key value clean=1
	keys=$(grep -oE '^[a-z][a-z0-9_]*=' "$CATALOG_PTBR" | sed 's/=$//' | sort -u)
	while IFS= read -r key; do
		[ -z "$key" ] && continue
		value=$(grep -E "^${key}=" "$CATALOG_PTBR" | head -1 | sed -E "s/^${key}='?//; s/'\$//; s/'[[:space:]]*#.*\$//")
		if ! scan_text "catalog:${key}" "$value"; then
			FAIL=1
			clean=0
		fi
	done <<<"$keys"
	[ "$clean" -eq 1 ] && echo "OK: denylist_clean_catalog"
}

# --- Gate: gate_is_load_bearing ----------------------------------------------
# Positive control: without this, a broken pattern would let the three gates
# above pass in silence — exactly the failure mode this gate exists to
# prevent. Copies a real surface, injects one calque line and one LLM-tic
# line, and asserts scan_text reports both as non-clean.
gate_is_load_bearing() {
	local work src injected ok=1
	work=$(mktemp -d)
	src="$REPO_ROOT/CONTEXT.md"
	injected="$work/probe.md"
	cp "$src" "$injected"
	{
		echo ""
		echo "Nós vamos deployando essa mudança amanhã."
		echo "É importante notar que isso é só um teste."
	} >>"$injected"

	local text
	text=$(cat "$injected")
	if scan_text "probe" "$text" >/dev/null; then
		# scan_text returned 0 (clean) — the injected calque/tic was NOT caught.
		ok=0
	fi
	rm -rf "$work"

	if [ "$ok" -eq 1 ]; then
		echo "OK: gate_is_load_bearing"
	else
		echo "FAIL: gate_is_load_bearing — injected calque/tic was not detected by scan_text"
		FAIL=1
	fi
}

# --- Gate: allowlist_is_load_bearing ----------------------------------------
# Second control: asserts the word "deletado" (present in
# docs/chrome-inventory.md, a VOLP-registered form per D-23) is NOT reported
# by denylist_clean_prose — proof the denylist does not reprove legitimate
# pt-br prose.
allowlist_is_load_bearing() {
	local file="$REPO_ROOT/docs/chrome-inventory.md" text
	if ! grep -qF 'deletado' "$file"; then
		echo "FAIL: allowlist_is_load_bearing — docs/chrome-inventory.md no longer contains 'deletado'; update the probe"
		FAIL=1
		return
	fi
	text=$(strip_ignored_regions "$file") || {
		echo "FAIL: allowlist_is_load_bearing — unbalanced ignore region in ${file}"
		FAIL=1
		return
	}
	if scan_text "chrome-inventory-probe" "$text" >/dev/null; then
		echo "OK: allowlist_is_load_bearing"
	else
		echo "FAIL: allowlist_is_load_bearing — 'deletado' was reported by scan_text (denylist too broad, see D-23)"
		FAIL=1
	fi
}

# --- Gate: glossary_is_inlined ----------------------------------------------
# Asserts CONTEXT.md carries the glossary heading and a balanced sentinel
# pair, and that agents/format-github-wiki.md carries the INLINE copy (not
# just the link) — the regression Pitfall 4 describes: someone "cleans up
# duplication" and moves the glossary back behind a link.
glossary_is_inlined() {
	local ctx="$REPO_ROOT/CONTEXT.md" agent="$REPO_ROOT/agents/format-github-wiki.md"
	local ctx_start ctx_end agent_start agent_end inlined_forms ok=1

	grep -qF '## Glossário anti-calque' "$ctx" || ok=0
	ctx_start=$(grep -c 'no-calques:ignore-start' "$ctx")
	ctx_end=$(grep -c 'no-calques:ignore-end' "$ctx")
	[ "$ctx_start" -eq "$ctx_end" ] && [ "$ctx_start" -ge 1 ] || ok=0

	agent_start=$(grep -c 'no-calques:ignore-start' "$agent")
	agent_end=$(grep -c 'no-calques:ignore-end' "$agent")
	[ "$agent_start" -eq "$agent_end" ] && [ "$agent_start" -ge 1 ] || ok=0

	inlined_forms=$(awk '/no-calques:ignore-start/{f=1;next} /no-calques:ignore-end/{f=0} f' "$agent" |
		grep -coE 'deployar|printar|commitar|pushear|linkar|buildar|debugar|startar|mergear|upar')
	[ "$inlined_forms" -ge 3 ] || ok=0

	if [ "$ok" -eq 1 ]; then
		echo "OK: glossary_is_inlined"
	else
		echo "FAIL: glossary_is_inlined — ctx_start=${ctx_start} ctx_end=${ctx_end} agent_start=${agent_start} agent_end=${agent_end} inlined_forms=${inlined_forms}"
		FAIL=1
	fi
}

denylist_clean_prose
denylist_clean_ptbr_output
denylist_clean_catalog
gate_is_load_bearing
allowlist_is_load_bearing
glossary_is_inlined

[ "$FAIL" -eq 1 ] && exit 1
[ "$SKIP" -eq 1 ] && exit 3
exit 0
