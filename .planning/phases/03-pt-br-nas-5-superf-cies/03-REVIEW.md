---
phase: 03-pt-br-nas-5-superf-cies
reviewed: 2026-09-30T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - agents/format-dokuwiki.md
  - agents/format-github-wiki.md
  - agents/format-pdf.md
  - agents/format-swagger.md
  - scripts/generate-mkdocs.sh
  - scripts/to-dokuwiki.sh
  - scripts/to-pdf.sh
  - templates/lang/en.lang
  - templates/lang/pt-br.lang
  - templates/swagger-ui.html
  - tests/fail-closed.sh
  - tests/no-mixed-output.sh
  - tests/regress.sh
findings:
  critical: 1
  warning: 6
  info: 0
  total: 7
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-09-30T00:00:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

The core i18n plumbing added in this phase — the `OUTPUT_LANG` allowlist gate, catalog
sourcing, and fail-closed key checks in `scripts/generate-mkdocs.sh`, `scripts/to-pdf.sh`,
and `scripts/to-dokuwiki.sh` — is sound: the allowlist gate runs before any path is built
from the argument, missing keys halt with the key name in the message, and the `en` output
path is provably byte-identical (empty `THEME_LANGUAGE`, no `-M lang`/`-M toc-title`
flags). `templates/lang/en.lang` and `templates/lang/pt-br.lang` have matching keysets
(modulo the declared `pdf_toc_title` allowlist exception), and the two test harnesses
(`tests/fail-closed.sh`, `tests/no-mixed-output.sh`) exercise these paths credibly.

However, one file in scope — `agents/format-github-wiki.md` — contains a link-conversion
`sed` command that is not merely fragile but **actually invalid regex syntax**; I
reproduced the exact failure with GNU sed. Since this is the *only* place that logic is
specified (there is no companion script), and `tests/no-mixed-output.sh`'s own scope
(despite its header comment) never generates or scans a GitHub Wiki surface, this defect
has zero automated coverage and would ship undetected. Beyond that, the Swagger flow
interpolates unescaped, potentially-attacker-or-user-controlled values into `sed`
replacement text, the PDF manual fallback silently diverges from the scripted primary
path, and two catalog files carry stale "no consumer yet" comments for keys this very
phase wires up.

## Critical Issues

### CR-01: `agents/format-github-wiki.md` link-conversion `sed` expressions are invalid regex — GitHub Wiki link rewriting is non-functional

**File:** `agents/format-github-wiki.md:78-83`
**Issue:** Step 4 ("Convert links") specifies:

```bash
for f in $(find wiki -name '*.md'); do
  sed -i -E \
    -e 's@\[\([^]]*\)\]\(([^):]+)\.md\)@[[\1|\2]]@g' \
    -e 's@\[\([^]]*\)\]\(([^):]+)/([^)/:]+)\)@[[\3|\2]]@g' \
    "$f"
done
```

`sed -E` is POSIX ERE, where unescaped `(`/`)` open a capture group and `\(`/`\)` are
literal parentheses (GNU extension). Both expressions here escape the parens meant to be
*capture groups* (`\([^]]*\)`) and correspondingly reference `\1`/`\2`/`\3` in the
replacement — but under `-E` those escaped parens are literal-paren matches, not groups,
so the substitution has fewer real capture groups than referenced backreferences. This is
not a style nit — it is a hard syntax error. Reproduced verbatim:

```
$ sed -E -e 's@\[\([^]]*\)\]\(([^):]+)\.md\)@[[\1|\2]]@g' test.md
sed: -e expression #1, char 43: invalid reference \2 on `s' command's RHS

$ sed -E -e 's@\[\([^]]*\)\]\(([^):]+)/([^)/:]+)\)@[[\3|\2]]@g' test.md
sed: -e expression #1, char 49: invalid reference \3 on `s' command's RHS
```

Since `sed -i` compiles all `-e` expressions before touching any input, the very first
markdown file processed aborts the command entirely — **no links are ever converted**,
for any file, on any run of this step. This is the only place this transform is specified
(there is no `to-github-wiki.sh` companion script), so the GitHub Wiki surface's link
rewriting is currently non-functional as documented, in both `en` and `pt-br` runs (this
predates the i18n work but remains in the file as reviewed, and is squarely in the
"incorrect sed expressions" review criterion).

**Fix:** Use plain, unescaped capture groups (ERE convention) and escape only the literal
markdown-syntax parentheses that don't exist in the actual link syntax being matched —
i.e. drop the spurious literal-paren wrapping around the link text entirely, since
markdown link text is delimited by `[`/`]`, not `(`/`)`:

```bash
sed -i -E \
  -e 's@\[([^]]*)\]\(([^):]+)\.md\)@[[\2|\1]]@g' \
  -e 's@\[([^]]*)\]\(([^):]+)/([^)/:]+)\)@[[\2/\3|\1]]@g' \
  "$f"
```

(Verify the replacement group order against the target `[[Page|text]]` convention stated
in the surrounding prose — the original also had `\1`/`\2` reversed relative to that
convention; a page-name-then-text order is `[[<path>|<text>]]`, not `[[<text>|<path>]]`.)
Add a regression test that actually runs this command over a small markdown fixture, since
none currently exists (see WR-02).

## Warnings

### WR-01: GitHub Wiki surface has zero automated i18n leak coverage despite being named in scope

**File:** `tests/no-mixed-output.sh:1-9`
**Issue:** The header comment claims coverage of "the five pt-br publishable surfaces
(MkDocs index+nav, GitHub Wiki chrome sources, DokuWiki, PDF, Swagger UI)". The actual
`scan_surface`/`check_positive` calls only cover `mkdocs`, `index`, `pdf`, `swagger`, and
`dokuwiki` (`mkdocs` and `index` are two scans of the *same* MkDocs destination) — GitHub
Wiki is never generated or scanned anywhere in this file. Combined with CR-01, this means
the GitHub Wiki surface — one of the five canonical destinations per `.claude/CLAUDE.md`'s
own project description — has no automated defense against either mixed-language output
or the sed regression above.
**Fix:** Add a GitHub Wiki leg to `tests/no-mixed-output.sh` that replicates
`agents/format-github-wiki.md`'s catalog usage for `Home.md`/`_Sidebar.md` (the same
pattern already used for the scriptless Swagger surface, lines 83-97), scans the generated
chrome for en-value leaks, and runs the link-conversion `sed` against a small fixture so
CR-01-class regressions are caught mechanically. Alternatively, correct the header comment
to state the actual (narrower) scope if GitHub Wiki coverage is deliberately deferred.

### WR-02: Swagger flow interpolates unescaped values into `sed` replacement text

**File:** `agents/format-swagger.md:75-81`, replicated in `tests/regress.sh:97-101` and
`tests/no-mixed-output.sh:92-96`
**Issue:** Step 4.3 substitutes `{{PROJECT_NAME}}` → `$PROJECT_NAME` and `{{TITLE_SUFFIX}}`
→ the catalog value via a single `sed` pass, e.g. `s/{{PROJECT_NAME}}/$PROJECT_NAME/g`. Any
`/` in `$PROJECT_NAME` breaks the `s///` delimiter (sed syntax error, whole command
aborts); a literal `&` in the value gets expanded by sed as "insert the matched text",
silently corrupting the generated `<title>` to contain the literal string
`{{PROJECT_NAME}}` instead of the project name; a trailing `\` can escape the following
delimiter. `$PROJECT_NAME` is user/CONTEXT.md-supplied and not validated against these
characters anywhere in the reviewed files. All three places this pattern appears
(the doc, and both test doubles) hardcode `"TestProject"`, so this class of bug has never
been exercised.
**Fix:** Either escape sed metacharacters in the substituted values before interpolating
(`printf '%s' "$v" | sed -e 's/[&/\]/\\&/g'`) or switch to a delimiter-safe substitution
mechanism (e.g. `awk` with `-v`, or `perl -pe` with quoted `\Q...\E`, or writing the file
via a heredoc/`printf` template instead of `sed` placeholder replacement, matching how
`scripts/generate-mkdocs.sh` and `scripts/to-pdf.sh` already avoid this class of bug by
using heredocs/`printf '%s'` rather than `sed` for value interpolation).

### WR-03: PDF manual fallback silently diverges from the scripted primary path

**File:** `agents/format-pdf.md:39-54`
**Issue:** Two divergences from `scripts/to-pdf.sh`:
1. The fallback code block (lines 42-47) never emits a document-title line — the primary
   script's `printf '# %s\n\n' "${pdf_title}"` (scripts/to-pdf.sh:56) has no equivalent
   here, so a PDF built via the fallback path is missing its title heading entirely
   (`en`: "Specifications"/`pt-br`: "Especificações").
2. Lines 52-54 hardcode the pt-br projection literally as prose (`-M lang=pt-BR -M
   toc-title=Sumário`) instead of directing the agent to read `pdf_toc_title` from the
   active catalog the way the script does (`scripts/to-pdf.sh:40-41`). If `pdf_toc_title`'s
   value is ever edited in `templates/lang/pt-br.lang`, this doc goes stale silently —
   nothing re-derives it and no test checks the doc text against the catalog.
**Fix:** Add the `# ${pdf_title}` header line to the fallback code block, and change the
locale-projection paragraph to say "read `pdf_toc_title` from the loaded catalog" rather
than hardcoding "Sumário", mirroring how `agents/format-swagger.md` documents catalog
lookups instead of hardcoded strings.

### WR-04: Stale "no consumer" comments for keys this phase wires up

**File:** `templates/lang/en.lang:54,57`; `templates/lang/pt-br.lang:56,60`
**Issue:** Both catalogs still say, for `pdf_title`/`pdf_toc_title` and
`swagger_title_suffix`:
```
# superfície PDF (scripts/to-pdf.sh — sem consumidor nesta fase; consumida na Phase 3)
# superfície Swagger (templates/swagger-ui.html — sem consumidor nesta fase; consumida na Phase 3)
```
This phase (Phase 3, per the phase directory name and `<config>` block) *is* the phase
that wires up `scripts/to-pdf.sh` (now reads `pdf_title`/`pdf_toc_title`) and the Swagger
flow (now reads `swagger_title_suffix` per `agents/format-swagger.md` and
`templates/swagger-ui.html`'s `{{TITLE_SUFFIX}}` placeholder). `templates/lang/pt-br.lang`
is a brand-new file in this same commit series and copied the stale comment forward rather
than updating it. This directly undermines the catalog's own documented
consumer-tracking convention (the DokuWiki section, added in the same phase, correctly
says "consumida neste plano" — see `en.lang:60`, `pt-br.lang:63`), and could mislead a
future maintainer auditing for dead catalog keys.
**Fix:** Update both comments in both files to `— consumida neste plano` (or equivalent),
matching the DokuWiki section's already-correct phrasing.

### WR-05: `printf '%b'` on a catalog-sourced string is fragile against future backslash content

**File:** `scripts/to-dokuwiki.sh:62`
**Issue:** `steps_block=$(printf '%b' "${dokuwiki_readme_steps}")` relies on `%b`
interpreting `\n` sequences embedded in the single-quoted catalog value
(`templates/lang/en.lang:62`, `templates/lang/pt-br.lang:65`). This works today because
the only backslash sequences present are `\n`. `%b` also interprets `\t`, `\a`, `\c`
(stops output at that point), `\0NNN`, etc. Nothing validates or tests that a future
catalog edit (e.g. a translator pasting a Windows path or a code sample containing a
literal backslash) won't be silently mangled or truncated by this expansion. There is no
test exercising a value with a non-`\n` backslash sequence.
**Fix:** Either restrict catalog authors via a comment near the key (not just the file
header) warning that literal backslashes are unsafe, or avoid `%b` by storing the steps as
an already-newline-delimited value and using a different join mechanism (e.g. store `\n`
literally only in a comment-documented sub-format and validate it, or switch the catalog
format for this one multi-line key to something that doesn't require escape
interpretation, e.g. numbered keys `dokuwiki_readme_step_1`..`_4`).

### WR-06: Unquoted `$(find ... | sort)` command substitution in `agents/format-dokuwiki.md`

**File:** `agents/format-dokuwiki.md:28`
**Issue:**
```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/to-dokuwiki$SCRIPT_EXT" dokuwiki-out "$OUTPUT_LANG" $(find "$SOURCES" -name '*.md' | sort)
```
The command substitution is unquoted, so its output undergoes word-splitting and
pathname expansion. A markdown filename containing a space (or a shell glob character)
will be split into multiple, incorrect positional arguments passed to
`scripts/to-dokuwiki.sh`, which will then report "WARNING: <fragment> not found,
skipping" for both halves rather than converting the file. None of the reviewed test
harnesses (`tests/regress.sh`, `tests/no-mixed-output.sh`) exercise a filename with a
space, so this has no coverage. This is the exact "missing quoting" class the review was
asked to check for.
**Fix:** Use a null-delimited pipeline or an array, e.g.:
```bash
mapfile -d '' -t files < <(find "$SOURCES" -name '*.md' -print0 | sort -z)
$SCRIPT_RUNNER "$SKILL_DIR/scripts/to-dokuwiki$SCRIPT_EXT" dokuwiki-out "$OUTPUT_LANG" "${files[@]}"
```

---

_Reviewed: 2026-09-30T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
