---
phase: 04-g-meos-powershell-prosa-release
reviewer: gsd-code-reviewer
depth: standard
status: complete
findings_count:
  critical: 2
  warning: 3
  info: 2
---

# Phase 04 Code Review

## Summary

Reviewed the four catalog-driven `.ps1` twins (`generate-index.ps1`, `generate-mkdocs.ps1`,
`to-pdf.ps1`, `to-dokuwiki.ps1`), the new shared loader `scripts/lib/catalog.ps1`, the three new
test harnesses (`tests/ps1-contract.sh`, `tests/no-calques.sh`, `tests/wiki-links.sh`), the
modified `tests/no-mixed-output.sh`, the glossary/prose additions (`CONTEXT.md`,
`agents/format-github-wiki.md`, `agents/references.md`), `CHANGELOG.md`, and the two `.lang`
catalogs.

All three test suites were executed live against a real `pwsh 7.6.5` (via `/snap/bin/pwsh`,
added to `PATH`) and `pandoc` on this host — `tests/ps1-contract.sh` (21/21 gates green,
including all 9 `pwsh_*` behavioral legs), `tests/no-calques.sh` (6/6 green), and
`tests/wiki-links.sh` (4/4 green). The quote-aware catalog parser in `scripts/lib/catalog.ps1`,
the D-16-class array-slice and absolute-path-leak fixes, the `to-pdf.ps1` `ValueFromRemainingArguments`
param-binding fix, and the `to-dokuwiki.ps1` `GetDirectoryName` colon-safe path fix all hold up
under direct execution, not just static reading.

The adversarial pass found two reproducible correctness defects that no existing gate catches:
both `to-pdf.ps1` and `to-dokuwiki.ps1` ignore the exit code of the `pandoc` invocation they
wrap, so a failing conversion is reported as a success (exit 0, "Converted"/"PDF generated"
message) while the expected output file is never written. Both were reproduced live in this
session with a stub `pandoc` that always fails. This directly contradicts the "fail-closed, never
silent" principle this same phase documents repeatedly in `CONTEXT.md` and `CHANGELOG.md`, and it
is a real regression against the `.sh` twins, which fail closed on the identical failure via
`set -euo pipefail` (also reproduced live, for contrast). Three further warnings and two info
items are listed below.

## Findings

### Critical

#### CR-01: `to-pdf.ps1` reports PDF generation as successful even when `pandoc` fails

**File:** `scripts/to-pdf.ps1:94-122`

**Issue:** The `& $pandoc ...` invocations in both the weasyprint and wkhtmltopdf branches never
check `$LASTEXITCODE` (or `$?`). PowerShell does not throw a terminating exception for a
non-zero exit from a native command, so the surrounding `try {} catch {}` never fires either.
Immediately after the invocation the script unconditionally prints `"PDF generated via
weasyprint: $Output"` and sets `$found = $true`, then exits 0 — regardless of whether `$Output`
was actually created.

Reproduced live in this session with a stub `pandoc` that writes to stderr and exits 1:

```
$ pwsh -File scripts/to-pdf.ps1 out/book.pdf en test.md
pandoc: fatal error
PDF generated via weasyprint: out/book.pdf
EXIT CODE: 0
$ ls out/
specs-book.md        # out/book.pdf was never created
```

This is a pre-existing defect (present since the script's original version, before this phase),
but it survives this phase's full catalog-driven rewrite of the same code path untouched, and it
contradicts the phase's own stated design principle (`CONTEXT.md`: "fail closed... never um
fallback silencioso").

**Fix:** Check the native exit code after each pandoc invocation and only report success / set
`$found` when it is zero and `$Output` actually exists on disk, e.g.:

```powershell
& $pandoc $book -f markdown --pdf-engine=weasyprint `
  -o $Output --metadata "title=$pdfTitle" `
  --toc --toc-depth=3 @PandocLangOpts
if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $Output)) {
  Write-Output "PDF generated via weasyprint: $Output"
  $found = $true
} else {
  Write-Output "WARNING: weasyprint invocation failed (exit $LASTEXITCODE), trying next engine"
}
```

#### CR-02: `to-dokuwiki.ps1` silently continues after a failed per-file `pandoc` conversion

**File:** `scripts/to-dokuwiki.ps1:70-71`

**Issue:** `pandoc "$file" -f markdown -t dokuwiki -o "$pagePath"` is called with no exit-code
check. If conversion fails for a given file, the loop still prints `"Converted $file ->
$pagePath"` and moves on to the next file — the script exits 0 at the end even though one or more
pages were never written.

Reproduced live in this session with a stub `pandoc` that always fails:

```
$ pwsh -File scripts/to-dokuwiki.ps1 dw en test.md
pandoc: fatal error
Converted test.md -> dw/data/pages/test.txt
Done. Import dw/data/ into your DokuWiki data/ directory.
EXIT CODE: 0
$ find dw -type f
dw/README.md        # dw/data/pages/test.txt was never created
```

For contrast, the `.sh` twin (`scripts/to-dokuwiki.sh`) was run against the identical failing
`pandoc` stub and fails closed as designed:

```
$ bash scripts/to-dokuwiki.sh dw en test.md
pandoc: fatal error
EXIT CODE: 1
```

That divergence exists because `to-dokuwiki.sh` runs under `set -euo pipefail` (an unconditional
statement failing aborts the whole script), while PowerShell has no equivalent default and this
plan's rewrite of the function did not add one. This is exactly the kind of twin-parity gap
`tests/ps1-contract.sh` was built to catch in this phase, yet nothing in that harness (or
`tests/no-mixed-output.sh`/`tests/no-calques.sh`) exercises a failing `pandoc`, so it shipped
uncaught.

**Fix:** Check `$LASTEXITCODE` after each conversion and treat a failure as fatal (or at minimum
a surfaced warning plus a non-zero final exit code), mirroring the `.sh` twin's fail-closed
behavior:

```powershell
pandoc "$file" -f markdown -t dokuwiki -o "$pagePath"
if ($LASTEXITCODE -ne 0) {
  Write-Output "ERROR: pandoc failed converting $file (exit $LASTEXITCODE)"
  exit 1
}
Write-Output "Converted $file -> $pagePath"
```

### Warning

#### WR-01: Error paths across `scripts/lib/catalog.ps1` and all four twins write to stdout instead of stderr

**File:** `scripts/lib/catalog.ps1:12, 25, 89` and the `Usage:` lines in each twin
(`scripts/generate-index.ps1:13`, `scripts/generate-mkdocs.ps1:13`, `scripts/to-pdf.ps1:25`,
`scripts/to-dokuwiki.ps1:20`)

**Issue:** Every `ERROR:`/`Usage:` message in the new shared catalog library and in the twins
themselves is emitted via `Write-Output` (stdout), then `exit 1`. The `.sh` twins consistently
write the equivalent message to fd 2 (`>&2`) — e.g. `scripts/generate-mkdocs.sh:22`,
`scripts/to-pdf.sh:14`. `scripts/lib/catalog.ps1` is new code introduced in this phase and is the
single place meant to centralize this contract (D-18) for all four twins going forward, so this
was the opportunity to fix the stream discipline once instead of propagating the old twins'
pre-existing stdout habit into the new shared surface. A caller that separates stdout
(expected generated content / machine-readable status) from stderr (diagnostics), as the `.sh`
twins allow, gets inconsistent behavior depending on which twin it calls.

**Fix:** Route error/usage text through `[Console]::Error.WriteLine(...)` or `Write-Error` in
`catalog.ps1`'s three gate functions, and update each twin's `Usage:` line the same way, so both
language twins agree on which stream carries diagnostics.

#### WR-02: `Expand-CatalogEscapes` only implements `\n`, not the full `printf '%b'` escape set it claims to mirror

**File:** `scripts/lib/catalog.ps1:118-124`

**Issue:** The function's own comment states it is the "Counterpart of the `printf '%b'` the .sh
twin applies to `dokuwiki_readme_steps`". `printf '%b'` expands the full backslash-escape set
(`\n`, `\t`, `\r`, `\\`, `\a`, `\b`, `\f`, `\v`, octal `\0NNN`, etc.), but the implementation here
only replaces literal `\n`. The current catalog values for `dokuwiki_readme_steps` happen to use
only `\n`, so today's test suite (including `pwsh_dokuwiki_value_shape`) cannot distinguish a
correct implementation from this narrower one — the gap is latent, not yet triggered. The first
catalog edit that adds `\t` (or reuses this helper for another `%b`-style value) will silently
diverge from the `.sh` twin's output with no test catching it.

**Fix:** Either implement the full `%b` escape set (at minimum `\t`, `\r`, `\\`) or narrow the
comment to state explicitly that only `\n` is supported and why that is provably sufficient for
every current catalog value — so a future catalog editor is warned instead of silently
regressing.

#### WR-03: Unescaped `$ProjectName`/`$repoUrl` interpolated directly into generated YAML can produce invalid `mkdocs.yml`

**File:** `scripts/generate-mkdocs.ps1:107-108` (and the analogous `generate-mkdocs.sh:92-94`,
out of this review's `.ps1` scope but sharing the same root cause)

**Issue:** `site_name: $ProjectName ${siteNameSuffix}` embeds the caller-supplied project name
with no YAML escaping. A project name containing `: ` (colon-space) — a very plausible real
name, e.g. `"Foo: Bar"` — produces `site_name: Foo: Bar — Specifications`, which most YAML
parsers (including PyYAML, which MkDocs uses) reject as "mapping values are not allowed here",
breaking the entire generated site. This is a pre-existing gap (present before this phase, shared
with the `.sh` twin) that the phase's full rewrite of `generate-mkdocs.ps1` left untouched.

**Fix:** Quote the interpolated value defensively, e.g. emit
`site_name: "$($ProjectName.Replace('"','\"')) ${siteNameSuffix}"` (double-quoted YAML scalar
with the one required escape), or validate/reject project names containing `:` at the onboarding
layer referenced in `CONTEXT.md`.

### Info

#### IN-01: Near-identical comment blocks duplicated across all four `.ps1` twins

**File:** `scripts/generate-index.ps1:17-19`, `scripts/generate-mkdocs.ps1:17-19`,
`scripts/to-pdf.ps1:29-31`, `scripts/to-dokuwiki.ps1:24-26` (the "Order is the security control
(T-04-01)" comment); similarly the "Console stays in English" comment at the end of
`generate-index.ps1` and `generate-mkdocs.ps1`.

**Issue:** The same explanatory comment is copy-pasted verbatim into every twin rather than
stated once (e.g. as a doc comment on `Resolve-OutputLang` itself in `catalog.ps1`, which is
already the single source of the logic it describes). Low-severity, but if the policy or its
rationale ever changes, four call sites need to be updated in lockstep by hand with no mechanism
to catch drift.

**Fix:** Move the rationale into a single doc comment on the relevant `catalog.ps1` function and
leave only a one-line pointer in each twin.

#### IN-02: `nav_issues` catalog key has no `.sh`-twin consumer

**File:** `scripts/generate-mkdocs.ps1:27-33, 98-104` vs. `scripts/generate-mkdocs.sh`

**Issue:** `nav_issues` (one of the four catalog keys added in this phase) is read and used only
by `generate-mkdocs.ps1`'s issues-nav-entry feature; `generate-mkdocs.sh` has no equivalent
"Issues" nav section at all. This is a pre-existing structural divergence between the twins (the
`.ps1` twin has a feature the `.sh` twin lacks), not something this phase introduced, but worth
surfacing since the phase's explicit goal is twin-contract convergence and a reader of
`docs/chrome-inventory.md`/the catalogs alone would not expect an asymmetric consumer for a key
that otherwise reads as shared chrome.

**Fix:** No action required unless/until a future plan wants full feature parity between the two
`generate-mkdocs` twins; if so, note the gap explicitly in `docs/chrome-inventory.md` in the
meantime.

## Disposition

The two Critical findings (CR-01, CR-02) are reproducible, silent-failure defects in files this
phase directly rewrote, and they contradict the phase's own stated fail-closed contract. They
should be fixed (or at minimum explicitly registered as a known limitation in `CHANGELOG.md`'s
"Limitações conhecidas" table, the same way every other known gap in this phase is documented)
before this phase is considered shippable. The Warning items are real robustness/consistency gaps
worth addressing opportunistically but do not block merge on their own. Info items are
maintainability notes only.

---

_Reviewed: 2026-10-01T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
