#!/usr/bin/env bash
# no-mixed-output.sh — CHROME-02 gate: zero mixed output across the five
# pt-br publishable surfaces (MkDocs index+nav, GitHub Wiki chrome sources,
# DokuWiki, PDF, Swagger UI).
# Usage: no-mixed-output.sh (no arguments)
#
# Contract: generates all five surfaces with OUTPUT_LANG=pt-br in a sandbox
# and proves that no `en` catalog value (outside the glossary allowlist)
# leaks into the pt-br output.
#
# Exit codes: 0 = zero mixed output across every verifiable surface,
# 1 = at least one leak (a `FAIL:` line naming surface + key + value),
# 3 = at least one leg SKIPPED for a missing dev dependency (pandoc). Never
# fails silently.
#
# Scope: NEVER scans docs/specs/** nor the PDF book body — that is user
# content the skill does not translate (Out of Scope, PROJECT.md). Only the
# five chrome slices named in the scan table below are read.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
TEMPLATES="$REPO_ROOT/templates"
TREE="$REPO_ROOT/tests/fixtures/tree/.specs"
CATALOG_EN="$TEMPLATES/lang/en.lang"
CATALOG_PTBR="$TEMPLATES/lang/pt-br.lang"

# Pin the locale so the title-case sed pipeline in the chain scripts operates
# character-wise, not byte-wise (same rationale as tests/regress.sh and
# tests/fail-closed.sh).
export LC_ALL=C.UTF-8

FAIL=0
SKIP=0

# Glossary allowlist (D-05): keys whose pt-br value is INTENTIONALLY
# identical to en (consecrated terms) — declared explicitly here, never a
# silent default. Emptying this array is what tests/no-mixed-output.sh's own
# negative control (allowlist_is_load_bearing) exercises.
GLOSSARY_ALLOWLIST=(label_stack label_roadmap table_design cell_absent)

in_allowlist() { # <key> — true when key is a declared glossary exception
	local key="$1" k
	for k in "${GLOSSARY_ALLOWLIST[@]}"; do
		[[ "$k" == "$key" ]] && return 0
	done
	return 1
}

[[ -d "$TREE" ]] || {
	echo "ERROR: fixture tree not found: $TREE (tests/fixtures/tree/.specs must stay committed)" >&2
	exit 1
}

# Load the en catalog into THIS process's plain (non-exported) shell
# variables — no `set -a`, so nothing here leaks into the child `bash
# scripts/*.sh` processes spawned below. Used only as the source of leak
# needles via indirect expansion (${!key}).
# shellcheck source=/dev/null
. "$CATALOG_EN"

EN_KEYS=()
while IFS= read -r k; do
	EN_KEYS+=("$k")
done < <(grep -oE '^[a-z][a-z0-9_]*=' "$CATALOG_EN" | sed 's/=$//' | sort -u)

# --- Sandbox generation: all five surfaces, OUTPUT_LANG=pt-br -------------
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp -r "$TREE" "$WORK/.specs"

(
	cd "$WORK"
	bash "$SCRIPTS/generate-mkdocs.sh" TestProject .specs pt-br >/dev/null
	bash "$SCRIPTS/generate-index.sh" TestProject general pt-br docs/specs/features >/dev/null
	# Explicit file arguments, in format-pdf.md policy order (tests/fixtures/manifest.md pin).
	bash "$SCRIPTS/to-pdf.sh" out/specs-book.pdf pt-br \
		.specs/project/PROJECT.md .specs/project/ROADMAP.md \
		.specs/codebase/ARCHITECTURE.md \
		.specs/features/login/spec.md .specs/features/login/design.md \
		.specs/features/autenticação/spec.md \
		.specs/quick/fix-nav/spec.md >/dev/null
	# Swagger surface: replicate agents/format-swagger.md step 4 exactly —
	# catalog lookup, then a single sed over the four placeholders.
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

DOKUWIKI_RAN=0
if command -v pandoc >/dev/null 2>&1; then
	(
		cd "$WORK"
		bash "$SCRIPTS/to-dokuwiki.sh" dw pt-br \
			.specs/project/PROJECT.md .specs/project/ROADMAP.md \
			.specs/codebase/ARCHITECTURE.md \
			.specs/features/login/spec.md .specs/features/login/design.md \
			.specs/features/autenticação/spec.md \
			.specs/quick/fix-nav/spec.md >/dev/null
	)
	DOKUWIKI_RAN=1
else
	echo "SKIPPED: pandoc not found on host — DokuWiki surface needs the dev-only dependency (sudo apt install pandoc; see tests/fixtures/manifest.md)"
	SKIP=1
fi

# --- Scan slices, per the "Escopo e allowlist" table in 03-03-PLAN.md ----
MKDOCS_TEXT=$(grep -E '^site_name:|^site_description:|: index\.md$' "$WORK/mkdocs.yml" || true)
INDEX_TEXT=$(cat "$WORK/docs/index.md")
PDF_TEXT=$(head -1 "$WORK/out/specs-book.md")
SWAGGER_TEXT=$(cat "$WORK/swagger-ui/index.html")
DOKUWIKI_TEXT=""
[[ "$DOKUWIKI_RAN" -eq 1 ]] && DOKUWIKI_TEXT=$(cat "$WORK/dw/README.md")

# --- Gate: mixed_output ---------------------------------------------------
# For every en catalog key not in the allowlist, the en value must not leak
# into the pt-br surface text. `%s` is a data slot (never literal output),
# so only the fragment before it is used as the needle; needles under 3
# chars are skipped (they would produce spurious matches).
scan_surface() { # <surface_label> <text>
	local surface="$1" text="$2" key value needle leaked=0
	for key in "${EN_KEYS[@]}"; do
		in_allowlist "$key" && continue
		value="${!key}"
		needle="${value%%%s*}"
		[[ "${#needle}" -lt 3 ]] && continue
		if grep -Fq -- "$needle" <<<"$text"; then
			echo "FAIL: mixed_output ${surface} — chave ${key} vazou o valor en"
			FAIL=1
			leaked=1
		fi
	done
	[[ "$leaked" -eq 0 ]] && echo "OK: mixed_output ${surface}"
}

scan_surface mkdocs "$MKDOCS_TEXT"
scan_surface index "$INDEX_TEXT"
scan_surface pdf "$PDF_TEXT"
scan_surface swagger "$SWAGGER_TEXT"
[[ "$DOKUWIKI_RAN" -eq 1 ]] && scan_surface dokuwiki "$DOKUWIKI_TEXT"

# --- Gate: positive_control ------------------------------------------------
# So the gate above cannot pass by vacuity (no surface generated): assert a
# known pt-br value is actually present in each surface's scanned text.
check_positive() { # <surface_label> <text> <needle...>
	local surface="$1" text="$2" needle ok=1
	shift 2
	for needle in "$@"; do
		if ! grep -Fq -- "$needle" <<<"$text"; then
			echo "FAIL: positive_control ${surface} — valor pt-br esperado ausente: ${needle}"
			FAIL=1
			ok=0
		fi
	done
	[[ "$ok" -eq 1 ]] && echo "OK: positive_control ${surface}"
}

check_positive mkdocs "$MKDOCS_TEXT" "— Especificações" "Início"
check_positive index "$INDEX_TEXT" "Visão Geral"
check_positive pdf "$PDF_TEXT" "Especificações"
check_positive swagger "$SWAGGER_TEXT" "Documentação da API" 'lang="pt-BR"'
[[ "$DOKUWIKI_RAN" -eq 1 ]] && check_positive dokuwiki "$DOKUWIKI_TEXT" "Instruções de Importação DokuWiki"

[[ "$FAIL" -eq 1 ]] && exit 1
[[ "$SKIP" -eq 1 ]] && exit 3
exit 0
