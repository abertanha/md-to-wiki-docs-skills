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
		bash "$SCRIPTS/to-dokuwiki.sh" dokuwiki en \
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
		# flow does (placeholder substitution only). Resolve the title suffix
		# from the en catalog and leave {{LANG_ATTR}} empty — that empty
		# substitution IS the additive en behavior (no lang attribute emitted).
		mkdir -p swagger-ui
		(
			set -a
			# shellcheck source=/dev/null
			. "$TEMPLATES/lang/en.lang"
			set +a
			: "${swagger_title_suffix:?key swagger_title_suffix not found in catalog}"
			sed -e 's/{{PROJECT_NAME}}/TestProject/g' \
				-e 's|{{OPENAPI_YML}}|openapi.yml|g' \
				-e "s|{{TITLE_SUFFIX}}|${swagger_title_suffix}|g" \
				-e 's|{{LANG_ATTR}}||g' \
				"$TEMPLATES/swagger-ui.html" >swagger-ui/index.html
		)
	)
	mkdir -p "$DEST/mkdocs" "$DEST/pdf" "$DEST/swagger"
	cp "$WORK/mkdocs.yml" "$DEST/mkdocs/mkdocs.yml"
	cp -r "$WORK/docs" "$DEST/mkdocs/docs"
	cp "$WORK/specs-book.pdf" "$DEST/pdf/specs-book.pdf"
	cp "$WORK/swagger-ui/index.html" "$DEST/swagger/index.html"
	rm -rf "$WORK"
}

# Run the .ps1 chain engine-less over a FRESH workdir, mirroring run_chain
# above. Interpreter invoked with profile disabled and non-interactive mode
# on every call (a user profile could change default encoding/
# ErrorActionPreference and make the capture depend on the capturing
# machine). Feature base dir DIVERGES from the .sh pin (docs/specs/features):
# generate-mkdocs.ps1 never copies the specs tree into docs/ (D-19,
# tests/fixtures/manifest.md). generate-mkdocs.ps1 and generate-index.ps1
# both write under docs/ (D-19 — the .ps1 twin writes mkdocs.yml inside
# docs/, unlike the .sh twin's root-level mkdocs.yml), so the whole docs/
# tree is what gets collected here.
run_chain_ps1() { # <dest_dir>
	local DEST="$1" WORK
	WORK=$(mktemp -d)
	cp -r "$TREE" "$WORK/.specs"
	(
		cd "$WORK"
		pwsh -NoProfile -NonInteractive -File "$SCRIPTS/generate-mkdocs.ps1" TestProject .specs en
		pwsh -NoProfile -NonInteractive -File "$SCRIPTS/generate-index.ps1" TestProject general en .specs/features
		# Explicit file arguments, in format-pdf.md policy order — never an
		# unquoted expansion (word splitting differs between shells). This is
		# the ONLY invocation in the chain whose non-zero exit is tolerated: on
		# a host without a PDF engine the twin still writes the markdown book
		# before failing closed, and that book IS the golden for this surface
		# on such a host (D-10). The assertion right after separates that
		# tolerated outcome from a real failure.
		pwsh -NoProfile -NonInteractive -File "$SCRIPTS/to-pdf.ps1" specs-book.pdf en \
			.specs/project/PROJECT.md .specs/project/ROADMAP.md \
			.specs/codebase/ARCHITECTURE.md \
			.specs/features/login/spec.md .specs/features/login/design.md \
			".specs/features/autenticação/spec.md" \
			.specs/quick/fix-nav/spec.md || true
		[ -f specs-book.md ] || die "to-pdf.ps1 did not write specs-book.md even as the tolerated no-engine fallback (D-10)"
	)
	mkdir -p "$DEST/mkdocs" "$DEST/pdf"
	cp -r "$WORK/docs" "$DEST/mkdocs/docs"
	cp "$WORK/specs-book.md" "$DEST/pdf/specs-book.md"
	rm -rf "$WORK"
}

run_dokuwiki_ps1() { # <dest_dir> — runs to-dokuwiki.ps1 over the fixture tree (requires pwsh + pandoc)
	local DEST="$1" WORK
	WORK=$(mktemp -d)
	cp -r "$TREE" "$WORK/.specs"
	(
		cd "$WORK"
		pwsh -NoProfile -NonInteractive -File "$SCRIPTS/to-dokuwiki.ps1" dokuwiki en \
			.specs/project/PROJECT.md .specs/project/ROADMAP.md \
			.specs/codebase/ARCHITECTURE.md \
			.specs/features/login/spec.md .specs/features/login/design.md \
			".specs/features/autenticação/spec.md" \
			.specs/quick/fix-nav/spec.md
	)
	cp -r "$WORK/dokuwiki" "$DEST/dokuwiki"
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
	if out=$(diff -r "$g" "$f" 2>&1); then
		echo "OK: $label identical (date-masked)"
	else
		echo "FAIL: $label diverged"
		printf '%s\n' "$out" | sed 's/^/  /'
		FAIL=1
	fi
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
		if out=$(diff -r "$GOLDEN_DW" "$FRESH_DW/dokuwiki" 2>&1); then
			echo "OK: dokuwiki identical"
		else
			echo "FAIL: dokuwiki diverged"
			printf '%s\n' "$out" | sed 's/^/  /'
			FAIL=1
		fi
		rm -rf "$FRESH_DW"
		;;
	esac
else
	skip "pandoc not found on host — DokuWiki surface needs the dev-only dependency (sudo apt install pandoc; see tests/fixtures/manifest.md)"
fi

# .ps1 leg: requires pwsh (dev-only, baseline PS7/Linux, UTF-8 without BOM).
# On Linux/WSL hosts without pwsh this leg is SKIPPED — correct result for
# this host class, not a defect.
GOLDEN_PS1="$REPO_ROOT/tests/fixtures/golden-ps1"
if command -v pwsh >/dev/null 2>&1; then
	case "$MODE" in
	capture)
		FRESH_PS1=$(mktemp -d)
		run_chain_ps1 "$FRESH_PS1"
		rm -rf "$GOLDEN_PS1/mkdocs" "$GOLDEN_PS1/pdf"
		mkdir -p "$GOLDEN_PS1"
		cp -r "$FRESH_PS1/mkdocs" "$GOLDEN_PS1/mkdocs"
		cp -r "$FRESH_PS1/pdf" "$GOLDEN_PS1/pdf"
		rm -rf "$FRESH_PS1"
		echo "Captured .ps1 golden fixtures into tests/fixtures/golden-ps1/"
		;;
	regress)
		if [ -f "$GOLDEN_PS1/mkdocs/docs/mkdocs.yml" ]; then
			FRESH_PS1=$(mktemp -d)
			MASKED_PS1=$(mktemp -d)
			run_chain_ps1 "$FRESH_PS1"
			mask_copy "$GOLDEN_PS1" "$MASKED_PS1/golden"
			mask_copy "$FRESH_PS1" "$MASKED_PS1/fresh"
			compare_surface "mkdocs .ps1 (docs/)" "mkdocs" "$MASKED_PS1/golden" "$MASKED_PS1/fresh"
			compare_surface "pdf .ps1 (specs-book.md)" "pdf" "$MASKED_PS1/golden" "$MASKED_PS1/fresh"
			rm -rf "$FRESH_PS1" "$MASKED_PS1"
		else
			# Not yet captured is NOT a diff failure — a hard die() here would
			# break the gate for every pwsh host that has not captured yet,
			# unlike the .sh legs whose goldens are already committed.
			skip ".ps1 golden not captured yet under tests/fixtures/golden-ps1/ — run 'bash tests/regress.sh capture' on this host to capture it"
		fi
		;;
	esac

	GOLDEN_DW_PS1="$GOLDEN_PS1/dokuwiki"
	if command -v pandoc >/dev/null 2>&1; then
		case "$MODE" in
		capture)
			FRESH_DW_PS1=$(mktemp -d)
			run_dokuwiki_ps1 "$FRESH_DW_PS1"
			rm -rf "$GOLDEN_DW_PS1"
			cp -r "$FRESH_DW_PS1/dokuwiki" "$GOLDEN_DW_PS1"
			rm -rf "$FRESH_DW_PS1"
			echo "Captured .ps1 DokuWiki golden into tests/fixtures/golden-ps1/dokuwiki/"
			;;
		regress)
			if [ -f "$GOLDEN_DW_PS1/README.md" ]; then
				FRESH_DW_PS1=$(mktemp -d)
				run_dokuwiki_ps1 "$FRESH_DW_PS1"
				if out=$(diff -r "$GOLDEN_DW_PS1" "$FRESH_DW_PS1/dokuwiki" 2>&1); then
					echo "OK: dokuwiki .ps1 identical"
				else
					echo "FAIL: dokuwiki .ps1 diverged"
					printf '%s\n' "$out" | sed 's/^/  /'
					FAIL=1
				fi
				rm -rf "$FRESH_DW_PS1"
			else
				skip ".ps1 DokuWiki golden not captured yet under tests/fixtures/golden-ps1/dokuwiki/ — run 'bash tests/regress.sh capture' on this host to capture it"
			fi
			;;
		esac
	else
		skip "pandoc not found on host — .ps1 DokuWiki surface needs the dev-only dependency (sudo apt install pandoc; see tests/fixtures/manifest.md)"
	fi
else
	skip "pwsh not found on host — .ps1 surfaces require a host with PowerShell 7 (see tests/fixtures/manifest.md)"
fi

[ "$FAIL" -eq 1 ] && exit 1
[ "$SKIP" -eq 1 ] && exit 3
exit 0
