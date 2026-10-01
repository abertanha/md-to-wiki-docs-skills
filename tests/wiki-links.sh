#!/usr/bin/env bash
# wiki-links.sh — Regression gate for CR-01 and its two sibling defects in
# the link-conversion block of agents/format-github-wiki.md step 4.
# Usage: wiki-links.sh (no arguments)
#
# Contract: extracts the two sed expressions FROM the agent file itself (not
# a copy that could silently diverge), so the test always exercises the
# expressions actually shipped. CR-01 existed for months in a block no test
# touched; this harness closes that door.
#
# Exit codes: 0 = all four gates green, 1 = at least one FAIL:. Never silent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_FILE="$REPO_ROOT/agents/format-github-wiki.md"

export LC_ALL=C.UTF-8

FAIL=0
EXPRS=()

# --- extract_code_block ------------------------------------------------------
# Prints the content of the first fenced ```bash code block whose preceding
# heading line CONTAINS the literal string <heading_needle> (plain substring
# match, not a regex — the heading text itself may contain regex
# metacharacters like the "4." ordinal dot).
extract_code_block() { # <file> <heading_needle>
	local file="$1" needle="$2"
	awk -v needle="$needle" '
    index($0, needle) { found = 1 }
    found && /^```/ {
      if (infence) { exit }
      infence = 1
      next
    }
    infence { print }
  ' "$file"
}

# --- extract_sed_block --------------------------------------------------------
# Pulls the two `-e '...'` sed expressions out of the step 4 code block.
# A block that changed shape (not exactly two expressions) must FAIL the
# test rather than silently running with fewer/more expressions.
extract_sed_block() {
	local block
	block=$(extract_code_block "$AGENT_FILE" '### 4. Convert links')
	mapfile -t EXPRS < <(printf '%s\n' "$block" | grep -oE "'s@.*@g'" | sed "s/^'//; s/'\$//")
	if [ "${#EXPRS[@]}" -eq 2 ]; then
		echo "OK: sed_block_extraction"
	else
		echo "FAIL: sed_block_extraction — expected 2 expressions in the step 4 code block, found ${#EXPRS[@]}"
		FAIL=1
	fi
}

# --- Gate: link_conversion ---------------------------------------------------
# Covers: relative link with .md suffix two folders deep, relative link
# without suffix, relative link with suffix at a folder root, an external
# URL with slashes in its path, a mailto: link, and a single-segment
# relative link with no slash (neither expression matches it — current
# behavior, recorded here on purpose so a future change shows in the diff).
link_conversion() {
	[ "${#EXPRS[@]}" -eq 2 ] || return
	local work cases ok=1
	work=$(mktemp -d)
	cases="$work/cases.md"
	cat >"$cases" <<'FIXTURE'
[Login Spec](features/login/spec.md)
[Design Notes](features/login/design)
[Overview](overview.md)
[External](https://example.com/a/b)
[Mailto](mailto:x@y.z)
[Solo](solo)
FIXTURE
	sed -i -E -e "${EXPRS[0]}" -e "${EXPRS[1]}" "$cases"

	grep -qxF '[[Login Spec|features/login/spec]]' "$cases" || {
		echo "FAIL: link_conversion — relative .md link (two folders deep) not converted correctly"
		ok=0
	}
	grep -qxF '[[Design Notes|features/login/design]]' "$cases" || {
		echo "FAIL: link_conversion — relative link without .md suffix not converted correctly"
		ok=0
	}
	grep -qxF '[[Overview|overview]]' "$cases" || {
		echo "FAIL: link_conversion — relative .md link at folder root not converted correctly"
		ok=0
	}
	grep -qxF '[External](https://example.com/a/b)' "$cases" || {
		echo "FAIL: link_conversion — external URL was touched"
		ok=0
	}
	grep -qxF '[Mailto](mailto:x@y.z)' "$cases" || {
		echo "FAIL: link_conversion — mailto: link was touched"
		ok=0
	}
	grep -qxF '[Solo](solo)' "$cases" || {
		echo "FAIL: link_conversion — single-segment no-slash link was unexpectedly touched"
		ok=0
	}

	rm -rf "$work"
	if [ "$ok" -eq 1 ]; then
		echo "OK: link_conversion"
	else
		FAIL=1
	fi
}

# --- Gate: no_sed_error -------------------------------------------------------
# The CR-01 regression itself: the unfixed expressions abort with "invalid
# reference" before converting a single link. This gate reproves it stays
# fixed — status zero, nothing on stderr.
no_sed_error() {
	[ "${#EXPRS[@]}" -eq 2 ] || return
	local work cases err status
	work=$(mktemp -d)
	cases="$work/t.md"
	printf '%s\n' '[Login Spec](features/login/spec.md)' >"$cases"
	err=$(sed -i -E -e "${EXPRS[0]}" -e "${EXPRS[1]}" "$cases" 2>&1 1>/dev/null) && status=0 || status=$?
	rm -rf "$work"
	if [ "$status" -eq 0 ] && [ -z "$err" ]; then
		echo "OK: no_sed_error"
	else
		echo "FAIL: no_sed_error — status=${status} stderr=${err}"
		FAIL=1
	fi
}

# --- Gate: spaced_filename_survives ------------------------------------------
# D-26: runs the FULL loop extracted from the agent file (find + while read
# -d '') over a directory containing a file whose name has a space, and
# asserts the file was converted in place with no partial-path artifact.
spaced_filename_survives() {
	local block work status
	block=$(extract_code_block "$AGENT_FILE" '### 4. Convert links')
	work=$(mktemp -d)
	mkdir -p "$work/wiki"
	printf '%s\n' '[Login Spec](features/login/spec.md)' >"$work/wiki/Quick Tasks fix nav.md"

	status=0
	(cd "$work" && eval "$block") || status=$?

	local converted=0 stray=0
	if [ -f "$work/wiki/Quick Tasks fix nav.md" ] &&
		grep -qxF '[[Login Spec|features/login/spec]]' "$work/wiki/Quick Tasks fix nav.md"; then
		converted=1
	fi
	# A word-split loop over this filename would spawn `sed -i` on "Quick",
	# "Tasks" and "fix" as separate (nonexistent) targets — none of those
	# partial paths may exist afterward.
	[ -e "$work/wiki/Quick" ] && stray=1
	[ -e "$work/wiki/Tasks" ] && stray=1
	[ -e "$work/wiki/fix" ] && stray=1

	rm -rf "$work"

	if [ "$status" -eq 0 ] && [ "$converted" -eq 1 ] && [ "$stray" -eq 0 ]; then
		echo "OK: spaced_filename_survives"
	else
		echo "FAIL: spaced_filename_survives — status=${status} converted=${converted} stray=${stray}"
		FAIL=1
	fi
}

extract_sed_block
link_conversion
no_sed_error
spaced_filename_survives

[ "$FAIL" -eq 1 ] && exit 1
exit 0
