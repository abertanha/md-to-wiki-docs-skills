# Phase 4: Gêmeos PowerShell, Prosa & Release - Research

**Researched:** 2026-09-30
**Domain:** PowerShell catalog-driven i18n twins, prose governance (anti-calque), release hardening
**Confidence:** MEDIUM — HIGH on the bash-side contract this phase must mirror (read directly from the executed `.sh` twins and their tests), MEDIUM/LOW on the PowerShell-side parsing design because `pwsh` is absent from this host and every `.ps1` claim below is derived by static reading + manual reasoning, not execution.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QUAL-03 | Glossário anti-calque no `CONTEXT.md` rege a prosa dos agents; denylist de calques verificável por grep como critério de completion | §Calque Denylist, §Agent Prose Audit, §Common Pitfalls (Pitfall 4), §Code Examples |
</phase_requirements>

## Summary

Phase 4 has three independent workstreams that share one root cause: the `.ps1` twins were frozen, untouched, in Phase 1 while Phases 2–3 rebuilt the `.sh` chain around `templates/lang/{en,pt-br}.lang`. Bringing the twins to parity is not a matter of copying the bash logic — PowerShell has no `set -a; . file` equivalent, and the catalog's own value-quoting convention (bash single-quote semantics, including a real escaped-apostrophe idiom in `en.lang:62`) does not parse under `ConvertFrom-StringData` without pre-processing. The second workstream — the anti-calque glossary — is genuinely new (there is currently no glossary section anywhere in `CONTEXT.md`), and it targets a narrow, previously-scoped-out surface: the *free-form* prose agents write at runtime (`Home.md`/`_Sidebar.md` in `format-github-wiki.md`), not the English runbook prose of the agent files themselves. The third workstream is a straightforward but multi-file release checklist (fix CR-01, wire `regress.sh`, update two READMEs, run a rubric-delta self-audit, write a release note about the default flip).

The load-bearing risk in this phase is environmental, not architectural: `pwsh` is not installed anywhere in this project's history (confirmed absent on this dev host, and Phase 1's `01-03` plan explicitly deferred `golden-ps1` capture for the same reason — the directory `tests/fixtures/golden-ps1/` does not exist on disk today). Every `.ps1` claim in this document is therefore reasoned from static source, cross-checked against Phase 1's own `[VERIFIED]`-tagged pitfalls (which *were* captured from reading the live `.ps1` files), never from running PowerShell. The planner should budget a `checkpoint:human-verify` wave gated on installing `pwsh` (via `snap install powershell --classic`, confirmed installable — `snap` is present on this host) before treating any `.ps1` change as done, exactly as Phase 1 did for `pandoc`.

**Primary recommendation:** Treat the four `.ps1` twins as a mechanical port of the already-proven bash pattern (positional `output_lang` insertion, allowlist gate, catalog load, fail-closed per-key check) using a **hand-written key=value parser over a `[hashtable]`** — never `ConvertFrom-StringData` on the raw file — because that cmdlet neither strips the catalog's `'…'` quoting nor safely survives the one bash-specific escaped-apostrophe value in `en.lang`. Treat the glossary as new content inlined directly into `CONTEXT.md` and copy-referenced (not just linked) into `agents/format-github-wiki.md`, because Phase 3's own retrospective (Pitfall analysis, `PITFALLS.md:170`) already predicted that a reference-only glossary gets ignored under prompt pressure.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `.ps1` catalog parsing (KEY=value → hashtable) | Companion script (deterministic layer) | — | Same tier as the `.sh` catalog load — a build-time/generation-time concern, never agent judgment |
| `.ps1` positional `output_lang` + allowlist gate | Companion script | — | Mirrors `.sh`'s fail-closed gate; must run before any path is built from the value (same invariant as T-02-01/T-02-06/T-03-07 in the `.sh` chain) |
| `.ps1` UTF-8 read/write discipline | Companion script | Host OS (PS 5.1 vs PS7 runtime) | Encoding behavior is determined by the PowerShell *host version*, not by script logic alone — this is a real secondary-tier dependency the plan must name explicitly |
| Anti-calque glossary content | Shared reference (`CONTEXT.md`) | Agent prose (`agents/format-*.md`) | `CONTEXT.md` is the single external home (HIE-5 in `docs/skill-quality-rubric.md`); agents inline a copy because a referenced-only doc is "ignored under pressure" (research finding, see Pitfall 4) |
| Denylist grep gate | Test/verification layer (new `tests/*.sh` or agent-embedded check) | — | Deterministic code substituting for prose self-policing (STE-6 in the rubric) |
| Release notes / README updates | Documentation | — | No runtime behavior; pure doc-tier work |

## Standard Stack

### Core

No new runtime dependency is introduced — the project's own constraint (`bash + markdown; nenhuma dependência nova de runtime`, `.claude/CLAUDE.md`) forbids it, and nothing in this phase's scope requires one.

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|---------------|
| Windows PowerShell 5.1 / PowerShell 7+ | host-provided | Executes the `.ps1` twins | Already the project's target (`SCRIPT_RUNNER = "powershell -File"` assigned in `agents/onboarding.md:36`); PS 5.1 is the default on unmodified Windows, PS7/`pwsh` is this project's dev-verification baseline (D-03, `01-RESEARCH.md`) |
| `pwsh` (PowerShell 7, Linux/WSL build) | current | Dev-only verification of `.ps1` logic on this Linux host | [ASSUMED — not installed, not run this session]. Installable via `snap install powershell --classic` (`snap` confirmed present: `/usr/bin/snap`) — mirrors the `pandoc`-as-dev-dep precedent from Phase 1 (`01-03-SUMMARY.md`) |

### Supporting

Not applicable — no supporting libraries. `[System.IO.File]`, `Get-Content`, and hashtables are BCL/PowerShell built-ins, not packages.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-written `KEY=value` parser (this recommendation) | `ConvertFrom-StringData` directly on `Get-Content -Raw` | **Rejected** — the cmdlet does not strip the catalog's `'…'` bash-style value quoting (it has no concept of shell quoting), and it runs `[regex]::Unescape()` over the value, which will error or silently corrupt on the one line containing a literal backslash-quote sequence (`en.lang:62`, see Pitfall 1). [CITED: learn.microsoft.com/.../ConvertFrom-StringData — "supports escape character sequences... using the Regex.Unescape Method"] |
| `[System.IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))` for ALL generated output | Keep `Out-File -Encoding utf8` for `en`, only use BOM-less writer for `pt-br` | This project's own prior research (`PITFALLS.md:89`) explicitly floated "en preserva o comportamento atual [com BOM]; pt-br pode usar o mesmo [com BOM]" as an acceptable option, because BOM in generated `.md`/`.yml` is harmless to MkDocs/pandoc consumers — but `.claude/CLAUDE.md`'s locked Stack Patterns table forbids `Out-File -Encoding UTF8`/`>` outright for **all** generated output. These two documents disagree; flagged as an **Open Question** below because it changes what "byte-identical .ps1 golden" even means (see §Open Questions Q1) |
| `snap install powershell` (Linux dev verification) | Wait for a real Windows host | A snap-based `pwsh` on Linux is PowerShell **7**, not PS 5.1 — it can verify parsing/catalog logic and BOM-less-by-default PS7 behavior, but it **cannot** verify the PS 5.1-specific ANSI-fallback/BOM-add behavior this phase's encoding discipline exists to guard against. A genuine PS 5.1 check still requires Windows (documented gap since Phase 1, `STATE.md` Blockers) |

**Installation (dev-only, requires human sudo — same pattern as Phase 1's pandoc install):**
```bash
sudo snap install powershell --classic
pwsh --version
```

**Version verification:** Not applicable to package registries — PowerShell is a runtime/host tool, not an npm/pip/cargo package. No `package-legitimacy` check applies.

## Package Legitimacy Audit

Not applicable — this phase introduces zero external packages in any ecosystem (npm/PyPI/cargo). The only "install" is the host tool `pwsh` via `snap`/apt, which is Microsoft's own official distribution channel, not a registry package subject to typosquatting risk. No audit table produced.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────┐
                    │ templates/lang/{en,pt-br}.lang │   (single source of truth,
                    │  KEY='value' bash-quoted     │    already built, Phase 2/3)
                    └───────────┬─────────────────┘
                                │
                 ┌──────────────┴───────────────┐
                 │                               │
          bash consumer                   PowerShell consumer (THIS PHASE)
     (generate-index.sh, etc.)          (generate-index.ps1, etc.)
                 │                               │
      set -a; . "$CATALOG"; set +a      hand-written parser:
      (shell sources file as code)      Get-Content -Encoding UTF8 |
                 │                       regex split on first '=' |
      : "${key:?msg}" fail-closed        strip outer quotes, un-escape
      per-key check                      the bash \'\'\' idiom |
                 │                       populate [hashtable]$Catalog
      emits chrome via ${key}                    │
                 │                       if (-not $Catalog.ContainsKey($k))
                 ▼                         { fail closed, name $k }
         mkdocs.yml / index.md /                 │
         specs-book.pdf / dokuwiki                ▼
                                          mkdocs.yml / index.md /
                                          specs-book.pdf / dokuwiki
                                          (via -Encoding rule TBD, Q1)
```

Both consumers read the *same* file; they must never disagree on which keys exist (`tests/fail-closed.sh`'s `catalog_parity` gate already enforces this on the bash side and does not need to change — it operates on the `.lang` files themselves, not on either consumer).

### Recommended Project Structure

No new directories. Changes land in-place:
```
scripts/
├── generate-index.ps1      # + output_lang positional, catalog load, fail-closed
├── generate-mkdocs.ps1     # + output_lang positional, catalog load, fail-closed, THEME_LANGUAGE
├── to-pdf.ps1              # + output_lang positional, catalog load, PANDOC_LANG_OPTS equivalent
└── to-dokuwiki.ps1         # + output_lang positional, catalog load, fail-closed

CONTEXT.md                  # + new "## Anti-calque glossary" section

agents/
└── format-github-wiki.md   # + inlined glossary excerpt (not just a CONTEXT.md link)
                             # + CR-01 fix (lines 79-82: \(...\) → (...))

tests/
└── regress.sh              # .ps1 leg: replace the permanent SKIPPED stub (line 198) with
                             # a real capture/regress implementation, gated on `command -v pwsh`
```

### Pattern 1: PowerShell KEY=value catalog parser (hand-written, quote-aware)

**What:** Read the `.lang` file line-by-line, skip comments/blanks, split each `key=value` line on the *first* `=`, then strip exactly one leading and one trailing `'` from the value and collapse the bash escaped-apostrophe idiom (`'\''` → `'`).

**When to use:** Every one of the four `.ps1` twins that needs catalog lookups (`generate-index.ps1`, `generate-mkdocs.ps1`, `to-pdf.ps1`, `to-dokuwiki.ps1`).

**Why not `ConvertFrom-StringData`:** [VERIFIED via live sed probe this session, see Pitfall 1] The catalog's one multi-segment value (`dokuwiki_readme_steps` in `en.lang:62`) uses bash's `'…'\''…'`  idiom to embed a literal apostrophe ("DokuWiki's"). This is bash grammar, not PowerShell or regex grammar — `ConvertFrom-StringData`, which applies [regex]::Unescape() to the value [CITED: learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertfrom-stringdata], has no notion of it and will either mis-parse or throw on the unrecognized `\'` escape.

**Example (untested — no `pwsh` on this host; verify via `checkpoint:human-verify` before shipping):**
```powershell
# Source: hand-derived from templates/lang/en.lang's actual quoting convention
# (verified this session via sed probe, NOT via pwsh execution — see Pitfall 1)
function Get-Catalog {
  param([string]$CatalogPath)
  $catalog = @{}
  foreach ($line in Get-Content -LiteralPath $CatalogPath -Encoding UTF8) {
    if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { continue }
    $key = $line.Substring(0, $eq)
    $raw = $line.Substring($eq + 1)
    if ($raw.Length -ge 2 -and $raw[0] -eq "'" -and $raw[$raw.Length-1] -eq "'") {
      $raw = $raw.Substring(1, $raw.Length - 2)
    }
    # Collapse bash's "close-quote, escaped-quote, reopen-quote" idiom
    # ('\'' — 4 literal chars: quote backslash quote quote) into one literal quote.
    $raw = $raw.Replace("'\''", "'")
    $catalog[$key] = $raw
  }
  return $catalog
}
```

**Fail-closed check per key (mirrors bash's `: "${key:?msg}"`):**
```powershell
function Assert-CatalogKey {
  param([hashtable]$Catalog, [string]$Key)
  if (-not $Catalog.ContainsKey($Key)) {
    Write-Output "ERROR: key $Key not found in catalog"
    exit 1
  }
}
```

**Trade-offs:** This parser is deliberately narrow — it handles exactly the quoting the two committed `.lang` files use (single-quote-wrapped values, one embedded-apostrophe case), not general bash string grammar. That is a feature, not a gap: it never calls `Invoke-Expression` or otherwise executes file content as code, which is actually a **safety improvement** over the bash side's `set -a; . "$CATALOG"; set +a` (previously flagged as a Tampering risk in `02-RESEARCH.md:565`, mitigated only by repo-trust).

### Pattern 2: Positional `output_lang` insertion (mirrors the `.sh` signatures exactly)

**What:** Insert `OutputLang` into each `.ps1`'s existing positional-argument scheme at the same slot the `.sh` twin uses, so `SKILL.md`'s claim ("All are called positionally, identically in `.sh` and `.ps1`") becomes true for the first time — today it is false, and `README.md:48`/`README.pt-BR.md:48` both document the gap explicitly ("that the `.ps1` twins do not yet accept — landing in a later phase").

**Exact signatures to converge on** [VERIFIED: scripts/*.sh, this session]:

| Script | Bash signature (already shipped) | Current `.ps1` signature | Required `.ps1` change |
|--------|-----------------------------------|---------------------------|--------------------------|
| `generate-index` | `<project_name> <audience> <output_lang> [feature_base_dirs...]` | `$args[0]`=project, `$args[1]`=audience, `$args[2..]`=feature dirs [VERIFIED: scripts/generate-index.ps1:2-4] | Insert `$OutputLang = $args[2]`; shift feature dirs to `$args[3..$args.Count]` |
| `generate-mkdocs` | `[project_name] [specs_dir] <output_lang>` | `$args[0]`=project (default `"Project"`), `$args[1]`=specs_dir (default `.specs`) [VERIFIED: scripts/generate-mkdocs.ps1:2-3] | Insert `$OutputLang = $args[2]`, **required** (no default) — mirror bash's mandatory-arg error message |
| `to-pdf` | `<output.pdf> <output_lang> <file1.md> [file2.md ...]` | `param([string]$Output, [string[]]$Files)` — **named param block**, not `$args` [VERIFIED: scripts/to-pdf.ps1:1-4] | Insert a new positional param between them: `param([string]$Output, [string]$OutputLang, [string[]]$Files)` — PowerShell binds array-typed positional params greedily to all remaining args, so this insertion is a clean, non-breaking positional shift |
| `to-dokuwiki` | `<output_dir> <output_lang> <file1.md> [file2.md ...]` | `$args[0]`=output_dir, `$args[1..]`=files [VERIFIED: scripts/to-dokuwiki.ps1:2-3] | Insert `$OutputLang = $args[1]`; shift files to `$args[2..$args.Count]` |

**Allowlist gate (mirrors bash's `case "$OUTPUT_LANG" in en|pt-br) ;; *) …esac`, which must run BEFORE any catalog path is built — T-02-01/T-02-06/T-03-07):**
```powershell
$OutputLang = $OutputLang.ToLowerInvariant()
if ($OutputLang -ne 'en' -and $OutputLang -ne 'pt-br') {
  Write-Output "ERROR: unsupported output_lang '$OutputLang' — supported: en, pt-br"
  exit 1
}
```

### Pattern 3: `$PSScriptRoot`-based catalog path resolution

**What:** `$PSScriptRoot` is PowerShell's built-in automatic variable holding the invoking script's own directory — the direct analog of bash's `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` pattern already used in every `.sh` twin.
```powershell
$Catalog = Join-Path $PSScriptRoot "..\templates\lang\$OutputLang.lang"
if (-not (Test-Path $Catalog)) {
  Write-Output "ERROR: catalog not found for output_lang '$OutputLang': $Catalog"
  exit 1
}
```
**When to use:** All four twins, replacing any ad-hoc path construction. `$PSScriptRoot` has been available since PowerShell 3.0 — safe for both PS 5.1 and PS7 targets.

### Anti-Patterns to Avoid

- **`ConvertFrom-StringData` on the raw catalog file:** see Pattern 1 — mis-parses the quoting convention and risks throwing on the one escaped-apostrophe value.
- **`Out-File -Encoding UTF8` / bare `>` redirection for writing generated output** (current behavior in all 4 `.ps1` twins, [VERIFIED: scripts/generate-index.ps1:87, generate-mkdocs.ps1:61, to-pdf.ps1:33, to-dokuwiki.ps1:45] — see Open Question Q1 for whether this phase changes it) — PS 5.1 always adds a BOM with `-Encoding UTF8`; PS7/Linux does not. This divergence is the crux of Q1.
- **`Invoke-Expression` or any other "treat file content as code" approach to parsing the catalog** — unnecessary and strictly worse than the hashtable parser above; the bash side's `set -a; . file` sourcing is already flagged as an accepted-but-real Tampering risk (`02-RESEARCH.md:565`) — do not import that risk into PowerShell where a safer option exists.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PowerShell "run from own directory" | Manual `[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)` gymnastics | `$PSScriptRoot` | Built-in automatic variable since PS3.0, already the pattern this project's own early research sketch used (`ARCHITECTURE.md:106`) |
| BOM-less UTF-8 write, portable 5.1/7 | Manual byte-array construction | `[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))` | .NET-level API bypasses PowerShell cmdlet encoding-parameter version drift entirely — this is the one part of the encoding story with no cross-version ambiguity (see `about_Character_Encoding`, confirmed via web search this session) |
| Catalog KEY=value parsing | A general bash-grammar parser in PowerShell | The narrow hand-written parser in Pattern 1, scoped to exactly what the two committed `.lang` files contain | The catalog is closed, small (36-37 keys), and committed — general-purpose parsing is unjustified complexity for a fixed, auditable input |

**Key insight:** The catalog format was chosen (per this project's own `STACK.md`) specifically because it is "the minimal meeting point between bash and PowerShell" — but minimal does not mean zero-effort on the PowerShell side. The one place that meeting point actually breaks (embedded-quote value) is exactly the kind of edge case a hand-rolled parser handles correctly and a generic cmdlet does not.

## Common Pitfalls

### Pitfall 1: `ConvertFrom-StringData` cannot round-trip the catalog's one escaped-apostrophe value

**What goes wrong:** `en.lang:62`'s `dokuwiki_readme_steps` value contains the bash idiom `'\''` (close-quote, escaped-quote, reopen-quote) to embed a literal apostrophe in "DokuWiki's". Read naively (feeding the whole line to `ConvertFrom-StringData`, or naively stripping only the first/last character of the *entire remaining line* rather than the correctly-bounded value), the apostrophe-embedding trick is bash-specific grammar that neither `ConvertFrom-StringData` nor a naive quote-strip understands.

**Why it happens:** The catalog format is optimized for bash's `set -a; . file` sourcing, where the shell itself resolves `'\''`. PowerShell has no equivalent sourcing mechanism, so nothing resolves it unless the parser explicitly knows the idiom.

**How to avoid:** Use Pattern 1's parser: strip exactly one leading/trailing quote from the *whole remaining line after `=`* (this works because the value is a single unbroken shell "word" formed entirely of quote-concatenated segments with no unquoted characters escaping the outer boundary — verified against `en.lang:62`'s actual byte content this session), then `.Replace("'\''", "'")` (literal string replace, not regex, to avoid double-escaping headaches) to collapse the idiom.

**Warning signs:** A `.ps1`-generated DokuWiki README that either has a raw `\` in the text, mangles "DokuWiki's" into two separate sentence fragments, or throws a `[regex]::Unescape` exception at catalog-load time.

**Verification status:** [VERIFIED via live `sed` probe this session — confirms the bash-side idiom and its exact 4-character shape] but the *PowerShell-side* fix is [ASSUMED — reasoned, not executed under `pwsh`]. Gate this with `checkpoint:human-verify` once `pwsh` is available.

### Pitfall 2: `Out-File -Encoding UTF8` BOM behavior conflicts between two of this project's own research documents

**What goes wrong:** `.claude/CLAUDE.md`'s locked Stack Patterns table says never use `Out-File -Encoding UTF8`/`>` for generated output (BOM breaks byte-identical diffs) and prescribes `[System.IO.File]::WriteAllText` with `UTF8Encoding($false)` everywhere. But `.planning/research/PITFALLS.md:89` (an earlier research pass in this same project) explicitly proposes the opposite for the `en` path specifically: "Regra: en preserva o comportamento atual [com BOM]; pt-br pode usar o mesmo [BOM em .md gerado é inócuo]." The two documents disagree on what "byte-identical `en`" should mean once the `.ps1` twins are touched for the first time.

**Why it happens:** No `golden-ps1` fixture has ever been captured (confirmed: `tests/fixtures/golden-ps1/` does not exist on disk), so there is no actual regression bar yet to be byte-identical *to* — the "byte-identical" language in the ROADMAP's Success Criterion 2 is aspirational for a baseline that doesn't exist, not a literal diff against a committed golden.

**How to avoid:** This is a real decision point for the user, not something research can resolve unilaterally — see Open Question Q1. Whichever way it resolves, the choice must be recorded in the `golden-ps1` capture's own manifest entry (mirroring `tests/fixtures/manifest.md`'s existing "Proibição de edição manual do golden" section) so future contributors know which byte-shape is intentional.

**Warning signs:** A `.ps1`-generated file starting with `EF BB BF` (BOM) when the plan expected none, or vice versa.

### Pitfall 3: `generate-index.ps1` has two pre-existing, Phase-1-documented Unix-breakage bugs on the exact lines this phase must touch anyway

**What goes wrong:** [VERIFIED: scripts/generate-index.ps1:4] `$FeatureBaseDirs = $args[2..$args.Count]` slices one index past the end of the args array under certain call shapes (documented as producing `$null` noise under pwsh7 in `01-RESEARCH.md:363`). [VERIFIED: scripts/generate-index.ps1:55-57] `Split-Path $dir -NoQualifier` returns the **entire absolute path** on Unix (not a relative fragment as on Windows), producing broken Feature-table links like `specs//tmp/…/spec.md`. Phase 1's own research (`01-RESEARCH.md:361-364`, Pitfall 8) explicitly logged these as "congelar como está... conserto é Phase 4, se couber" (freeze as-is; fixing it is Phase 4's call, if it fits) — deferring the decision to exactly this phase.

**Why it happens:** The `.ps1` twins were written targeting Windows PowerShell's own path semantics and were never exercised on Linux/`pwsh` until Phase 1's abortive fixture-capture attempt (which itself never completed, since `pwsh` was absent then too).

**How to avoid:** Because Phase 4 is inserting a new positional argument at index 2 into `generate-index.ps1` *anyway* (Pattern 2), the `$args[2..$args.Count]` slice bug will be touched by this phase's own required edit regardless — the planner should decide explicitly whether to also fix the `Split-Path -NoQualifier` Unix-breakage in the same task (since the file is already open) or explicitly re-defer it a third time. Silently doing neither risks shipping a `.ps1` catalog refactor on top of index arithmetic that was already known to be off-by-one.

**Warning signs:** Feature-table rows in a `.ps1`-generated `index.md` containing absolute host paths instead of relative `specs/...` links.

### Pitfall 4: A glossary referenced only via `CONTEXT.md` link gets ignored under prompt pressure

**What goes wrong:** [CITED: `.planning/research/PITFALLS.md:170`, this project's own prior research] "O glossário existe no CONTEXT.md, mas o subagent de formato recebe só o dispatch prompt — se a convenção mora só no CONTEXT.md referenciado, o subagent não a aplica consistentemente (referência consultada sob demanda é referência ignorada sob pressão)." This is precisely why ROADMAP Success Criterion 3 requires the glossary to be **inlined** into `agents/format-*.md`, not merely linked.

**Why it happens:** Every `agents/format-*.md` file today opens with "Variables and conventions: [CONTEXT.md](../CONTEXT.md)" — a reference, not inlined content. Under generation pressure (writing free-form `Home.md`/`_Sidebar.md` prose), an agent optimizing for task completion has no forcing function to re-open a linked file for a style rule.

**How to avoid:** Add a short, literal denylist + the "termo técnico integral ou equivalente consagrado" rule directly into the body of `agents/format-github-wiki.md` (the one agent that currently does free-form prose generation — see §Agent Prose Audit), immediately adjacent to the existing `OUTPUT_LANG` paragraph, not just a pointer to `CONTEXT.md`.

**Warning signs:** Generated `Home.md`/`_Sidebar.md` containing any denylisted calque despite a passing `CONTEXT.md` glossary review.

### Pitfall 5: `agents/format-github-wiki.md`'s second link-conversion regex silently discards the original link text — independent of CR-01

**What goes wrong:** [VERIFIED via live sed probe this session] Even after the CR-01 ERE-escaping fix, the second `sed` expression (`agents/format-github-wiki.md:81`) — intended for relative links without a `.md` suffix — replaces `[LinkText](dir/page)` with `[[page|dir]]`, discarding `LinkText` entirely (its own capture group 1 is never referenced in the replacement `[[\3|\2]]`). This reproduces the shape of a pre-existing defect (`docs/audit-findings.md` D3) though not verified to be the identical historical instance (line numbers there predate this file's current structure).

**Why it happens:** The replacement pattern `[[\3|\2]]` was seemingly designed under a MediaWiki-link mental model where the *last path segment* is the target page and the *directory prefix* is the display text — which is backwards from typical usage and orthogonal to the actual anchor text the source markdown author wrote.

**How to avoid:** This bug is **outside CR-01's stated scope** (CR-01 is narrowly the ERE-escaping fix). Flag it to the planner as a scope decision (fix now, while the file is open for CR-01 anyway, vs. defer with an explicit note) rather than silently bundling or silently ignoring it.

**Warning signs:** A GitHub Wiki page with `[[SomePage|SomeDir]]`-shaped links where the visible link text no longer matches what the source spec author wrote.

## Code Examples

### CR-01 fix — exact before/after

**Before** [VERIFIED: agents/format-github-wiki.md:78-83, and reproduced live this session — the unfixed version fails outright with `sed: -e expression #1, char 43: invalid reference \2 on 's' command's RHS`]:
```bash
for f in $(find wiki -name '*.md'); do
  sed -i -E \
    -e 's@\[\([^]]*\)\]\(([^):]+)\.md\)@[[\1|\2]]@g' \
    -e 's@\[\([^]]*\)\]\(([^):]+)/([^)/:]+)\)@[[\3|\2]]@g' \
    "$f"
done
```

**After** [VERIFIED via live sed probe this session — confirmed correct output `[[Login Spec|features/login/spec]]` for `[Login Spec](features/login/spec.md)`]:
```bash
for f in $(find wiki -name '*.md'); do
  sed -i -E \
    -e 's@\[([^]]*)\]\(([^):]+)\.md\)@[[\1|\2]]@g' \
    -e 's@\[([^]]*)\]\(([^):]+)/([^)/:]+)\)@[[\3|\2]]@g' \
    "$f"
done
```
**Change:** In ERE (`sed -E`), `\(`/`\)` match **literal** parentheses; unescaped `(`/`)` create capture groups. The original code had it backwards for the capture group around the link text (`\([^]]*\)` → `([^]]*)`), causing `\1` to be undefined and `\2` to throw. The literal parenthesis pair delimiting the markdown link target itself (`\(` ... `\)`) is unaffected and stays escaped, since those genuinely are literal `(`/`)` characters from `[text](target)` syntax.

### Calque denylist grep — starting set

[CITED: `.claude/CLAUDE.md` Constraints — "deployar", "printar", "commitar" named explicitly; extended with the additional items already named in this project's own prior research, `PITFALLS.md:178`: "deployar|printar|commitar|linkar|salvar save|é importante notar|in summary"]

```bash
# Verified clean against current published-prose surfaces this session
# (agents/, CONTEXT.md, README.pt-BR.md, SKILL.md) — zero matches.
DENYLIST='\b(deploy(ar|ei|ou|aram|ando|ado|ados)'\
'|print(ar|ei|ou|aram|ando|ado)'\
'|commit(ar|ei|ou|aram|ando|ado|ados)'\
'|push(ear|eei|eou|eando|eado)'\
'|debug(ar|ei|ou|ando|ado)'\
'|build(ar|ei|ou|ando|ado)'\
'|delet(ar|ei|ou|ando|ado)'\
'|link(ar|ei|ou|ando|ado)'\
'|check(ar|ei|ou|ando|ado))\b'
grep -rinE "$DENYLIST" agents/ CONTEXT.md README.pt-BR.md
# LLM-tic phrases (separate from anglicism calques, same completion gate):
grep -rinE '(é importante notar|em resumo|convém destacar|vale ressaltar)' agents/ CONTEXT.md README.pt-BR.md
```

**Scope note:** This grep must run against the *generated pt-br output* (Home.md/_Sidebar.md content, and any future free-form prose the agents write) as its primary target per ROADMAP Success Criterion 4 — the scan above against `agents/*.md` themselves only audits the *runbook prose* (currently 100% English, not user-facing pt-br output) and the not-yet-written glossary section. The denylist array itself is [ASSUMED] as a *starting set* — confirm/extend it with the user during `/gsd-discuss-phase`, since exhaustive anglicism coverage is a judgment call this research cannot close unilaterally.

### Agent prosa audit — current state of all 8 `agents/*.md` files

[VERIFIED via `rg` scan this session]

| File | Language today | Free-form prose surface? | Needs inlined glossary? |
|------|-----------------|---------------------------|---------------------------|
| `agents/onboarding.md` | English (runbook) | No — structured interview only | No |
| `agents/format-mkdocs.md` | English (runbook); chrome is catalog-driven | No — all output is catalog lookups | No (already fully catalog-driven, Phase 2) |
| `agents/format-swagger.md` | English (runbook); chrome is catalog-driven | No — title/lang only, catalog-driven (Phase 3) | No |
| `agents/format-pdf.md` | English (runbook); chrome is catalog-driven | No | No |
| `agents/format-dokuwiki.md` | English (runbook); chrome is catalog-driven | No | No |
| `agents/format-github-wiki.md` | English (runbook) | **Yes** — `Home.md`/`_Sidebar.md` are explicitly agent-authored judgment prose (`format-github-wiki.md:60`: "Write Home.md and _Sidebar.md yourself — overview text is judgment work") | **Yes — primary target for this phase's glossary inlining** |
| `agents/references.md` | English (runbook) | Possibly — appendix summaries (not read in depth this session; flagged in `ARCHITECTURE.md:243` as needing "glossary-following rules") | Recommend auditing during planning |
| `agents/deploy.md` | English (runbook) | No — deployment mechanics only | No |

Zero calque hits found scanning all 8 files plus `CONTEXT.md`, `README.pt-BR.md`, and `SKILL.md` this session (grep in Code Examples above) — the audit surface is clean today because no PT-BR free-form prose has been written by any agent yet; this phase's gate protects against future drift, it is not remediating an existing violation.

### Release checklist — concrete diffs required

| Item | Current state [VERIFIED] | Required change |
|------|----------------------------|-------------------|
| `README.md:48` | "with one exception in flight: `generate-index` and `generate-mkdocs` on `.sh` take a required `output_lang` positional... that the `.ps1` twins do not yet accept — landing in a later phase" | Remove the caveat once `.ps1` twins accept `output_lang`; state parity is complete |
| `README.pt-BR.md:48` | Portuguese mirror of the same caveat ("com uma exceção vigente... chega em fase futura") | Same removal, PT-BR wording, free of calques per the new glossary |
| `SKILL.md` (Companion Scripts section) | Already claims "All are called positionally, identically in `.sh` and `.ps1`" — currently **false** per the README's own caveat | No text change needed once parity is real — but note this file already overclaims; verify it becomes true rather than leaving a second stale claim |
| `tests/regress.sh:194-201` | `.ps1` leg is a **permanent SKIP stub**: `if command -v pwsh...; then skip "pwsh present but .ps1 golden capture not yet implemented in this harness"; else skip "pwsh not found..."` — i.e., even WITH `pwsh` present, this leg never actually runs anything | "`tests/regress.sh` wired no fluxo" (ROADMAP Success Criterion 5) requires implementing the actual `.ps1` capture/regress logic here, not just leaving the `pwsh`-present branch as a stub |
| `docs/skill-quality-rubric.md` self-audit | Not yet run for Phase 4's touched files | Add a "rubric delta" table to the plan's own SUMMARY.md, following the exact format already used in `03-02-SUMMARY.md:201-158` and `03-03-SUMMARY.md:146-158` (self-audit by the executor, scoped to files actually touched, not a full 9-file audit) |
| Release note | Does not exist yet | New doc (or `CHANGELOG.md` entry) stating: default is now `pt-br`; `OUTPUT_LANG=en` preserves all prior behavior byte-for-byte on the `.sh` side (proven by `tests/regress.sh`); `.ps1` parity achieved this phase; anti-calque glossary now governs pt-br prose |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `.ps1` twins hardcode all chrome strings, no `output_lang` awareness | `.ps1` twins load the same `.lang` catalog as `.sh`, gated by an `output_lang` positional | This phase | Single source of truth for chrome across both script hosts; eliminates the class of bug where `.sh` and `.ps1` silently drift (already observed once: `generate-index.ps1:84`'s footer URL `https://opencode.ai` vs. the catalog's `https://github.com/abertanha/md-to-wiki-docs-skills` — this divergence will disappear once `.ps1` consumes the catalog, which is a deliberate **convergence**, not a preserved wart; see Open Question Q1 for how this interacts with "byte-identical") |
| No anti-calque enforcement anywhere in the pipeline | Glossary inlined in `CONTEXT.md` + `agents/format-github-wiki.md`, denylist grep as a completion gate | This phase | Converts a subjective prose-quality expectation into a checkable, automatable gate (consistent with `docs/skill-quality-rubric.md`'s STE-6 "determinism substitution" principle) |

**Deprecated/outdated:** The `README.md`/`README.pt-BR.md` "landing in a later phase" caveat about `.ps1` output_lang parity becomes stale the moment this phase ships — it is the clearest, most mechanical "done" signal for the whole phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | The hand-written PowerShell catalog parser (Pattern 1) correctly handles `en.lang:62`'s escaped-apostrophe value and all other catalog values | Architecture Patterns, Pitfall 1 | If wrong, `to-dokuwiki.ps1`'s pt-br/en README output could contain a raw backslash-quote artifact or throw at load time. Mitigated by an explicit `checkpoint:human-verify` recommendation once `pwsh` is available — this is a probe that costs a confirmation checkpoint, not a blocked plan |
| A2 | `snap install powershell --classic` successfully installs a working `pwsh` on this Ubuntu 26.04 host | Standard Stack | If wrong, no `.ps1` verification is possible at all in this environment pre-Windows-host; planner should have a fallback path (static review only, ship behind an explicit human-verify gate on a real Windows/pwsh host) |
| A3 | The calque denylist regex set (Code Examples) is comprehensive enough for the completion gate | Code Examples, Common Pitfalls (Pitfall 4) | If too narrow, calques could slip through a "passing" gate, undermining QUAL-03's intent. Recommend confirming/extending with the user during discuss-phase rather than treating this list as final |
| A4 | Value-boundary quote-stripping (take the *entire* line-remainder after `=`, strip first/last char) is safe for every current catalog value, not just the one tested | Pattern 1 | If some other value (not tested this session) has a different internal quoting shape, the same Substring-based strip could mis-parse it. Mitigated by `tests/fail-closed.sh`'s existing `catalog_parity` gate catching any new key added without a `.ps1`-side equivalent test, but a **value-shape** regression would not be caught by that gate — recommend a `.ps1`-side smoke test enumerating every key, not just a sample |

## Open Questions

1. **Does `en`-path `.ps1` output keep the current BOM-adding `Out-File -Encoding UTF8` behavior, or switch to `[System.IO.File]::WriteAllText` with `UTF8Encoding($false)` for every generated file?**
   - What we know: `.claude/CLAUDE.md`'s locked Stack Patterns table says always use the BOM-less writer. This project's own earlier research (`PITFALLS.md:89`) explicitly proposed keeping `Out-File -Encoding utf8` (with BOM) for `en` specifically, reasoning that no `golden-ps1` fixture exists yet to regress against and BOM in generated `.md`/`.yml` is harmless downstream.
   - What's unclear: Which document is authoritative for this phase. `CLAUDE.md` is the more recently curated, locked project decision; `PITFALLS.md` is exploratory research predating implementation. But `CLAUDE.md`'s guidance was written with `.sh`-side byte-identity already proven — it may not have accounted for the fact that `.ps1`'s "byte-identical" baseline has never actually existed.
   - Recommendation: Surface this explicitly in `/gsd-discuss-phase` as a locked decision to make before planning — it changes what the very first `golden-ps1` capture looks like, and that capture cannot be redone silently later without re-litigating "byte-identical."

2. **Should Phase 4 fix `generate-index.ps1`'s two pre-existing Unix-breakage bugs (Pitfall 3), given Phase 1 explicitly deferred that decision to "Phase 4, se couber"?**
   - What we know: The `$args[2..$args.Count]` off-by-one-adjacent slice and the `Split-Path -NoQualifier` Unix-absolute-path leak are both already documented, both sit on/near the exact line this phase must edit anyway (to insert `output_lang`).
   - What's unclear: Whether fixing them is in QUAL-03's scope or constitutes unrelated scope creep this phase should explicitly decline (with a new deferred-item entry, following the project's own precedent in `deferred-items.md`).
   - Recommendation: Decide explicitly rather than silently bundling or silently re-deferring a third time.

3. **Is `agents/format-github-wiki.md`'s pattern-2 link-text-discarding behavior (Pitfall 5) in CR-01's scope, or a separate defect?**
   - What we know: CR-01 as named in the phase brief is narrowly the ERE-escaping syntax bug. The link-text-discard issue is a different, pre-existing logic bug on the adjacent line.
   - What's unclear: Whether the user considers "fix CR-01" to mean "make the link-conversion sed work correctly" (broader) or "make the sed not error out" (narrower, as literally scoped).
   - Recommendation: Confirm scope explicitly; do not silently expand or silently ignore.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `pwsh` (PowerShell 7, Linux) | Any `.ps1` execution/verification on this dev host | ✗ | — | `sudo snap install powershell --classic` (snap confirmed present); dev-only dependency, same class as Phase 1's `pandoc` |
| Windows host with PowerShell 5.1 | Verifying the PS 5.1-specific BOM/ANSI-fallback encoding behavior this phase's discipline exists to guard against | ✗ (no Windows host in this environment) | — | None available in this session — documented as a standing gap since Phase 1 (`STATE.md` Blockers: "Verificação PS 5.1 real depende de host Windows"). Static-review + `checkpoint:human-verify` on the eventual real host is the only mitigation |
| `pandoc` | `to-dokuwiki.ps1`/`to-pdf.ps1` chrome behavior at runtime (not needed for this phase's own verification, but needed if the `.ps1` golden capture exercises the DokuWiki/PDF legs) | ✓ | 3.7.0.2 (confirmed installed in Phase 1, `tests/fixtures/manifest.md`) | — |
| `git`, `bash`, `sed`, `grep` (coreutils) | CR-01 fix verification, calque denylist grep | ✓ | host-standard | — |

**Missing dependencies with no fallback:**
- Real Windows PowerShell 5.1 host — no fallback exists in this environment; this phase's PS 5.1-specific claims stay `[ASSUMED]` until a human verifies on real Windows hardware/VM, exactly as already logged as a known gap.

**Missing dependencies with fallback:**
- `pwsh` on Linux — installable this session via `snap`, not yet installed; recommend a `checkpoint:human-verify` task early in the phase's execution to install it before any `.ps1` edit is considered verified beyond static review.

## Security Domain

ASVS Level 1 enforcement is active for this project (`security_enforcement: true`, `security_asvs_level: 1` in `.planning/config.json`). This phase is script/prose refactoring with no network, auth, or session surface — most ASVS categories are not applicable. The categories that do apply:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|---------------------|
| V2 Authentication | No | No auth surface in this phase |
| V3 Session Management | No | N/A |
| V4 Access Control | No | N/A |
| V5 Input Validation | Yes | The `output_lang` allowlist gate (Pattern 2) is the input-validation control for this phase — an unrecognized value must fail closed before any path/catalog lookup is built from it, exactly mirroring the already-proven `.sh` pattern |
| V6 Cryptography | No | N/A |
| V12 File and Resources | Yes | Catalog file resolution (`$PSScriptRoot`-relative path, Pattern 3) must not accept an attacker-influenced path; `output_lang` is validated against a fixed allowlist *before* it is interpolated into any file path, preventing path-injection via a crafted `output_lang` value (e.g. `../../etc/passwd`) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|------------------------|
| Path traversal via `output_lang` interpolated into a catalog file path | Tampering | Allowlist gate (`en`/`pt-br` only) runs strictly before the path is constructed — already the pattern in all four `.sh` twins (`T-02-01`/`T-02-06`/`T-03-07`); the `.ps1` twins must replicate the same ordering, not just the same check |
| "Source file as code" injection via catalog loading | Tampering | Already flagged and accepted-as-repo-trusted on the bash side (`set -a; . file`, `02-RESEARCH.md:565`). The PowerShell hand-written parser (Pattern 1) is **strictly safer** here — it never executes catalog content, only parses it as text — and should not regress to an `Invoke-Expression`-based approach that would reintroduce the same class of risk with less justification (PowerShell has no equivalent need to "source" the file the way bash's `set -a` trick does) |
| Prompt-injection-adjacent: a maintainer-authored `.lang` value containing shell metacharacters reaching an unquoted downstream command | Tampering | Out of this phase's scope (no new command construction from catalog values is introduced), but worth noting for the planner: any future catalog value must continue to reach downstream commands only via quoted variable expansion (bash) or quoted string interpolation (PowerShell), never string-built commands |

## Sources

### Primary (HIGH confidence)
- `scripts/generate-index.sh`, `scripts/generate-mkdocs.sh`, `scripts/to-pdf.sh`, `scripts/to-dokuwiki.sh` — read in full this session, the exact contract the `.ps1` twins must converge on
- `scripts/generate-index.ps1`, `scripts/generate-mkdocs.ps1`, `scripts/to-pdf.ps1`, `scripts/to-dokuwiki.ps1` — read in full this session, current unmodified state
- `templates/lang/en.lang`, `templates/lang/pt-br.lang` — read in full this session, exact catalog contents including the escaped-apostrophe edge case
- `tests/regress.sh`, `tests/fail-closed.sh`, `tests/no-mixed-output.sh` — read in full this session
- `agents/format-github-wiki.md` — read in full this session; CR-01 lines confirmed and live-tested via `sed`
- `.planning/phases/01-contrato-golden-fixtures/01-RESEARCH.md` (Pitfalls 5, 7, 8) — this project's own prior `[VERIFIED]`-tagged findings on `.ps1` encoding/path bugs

### Secondary (MEDIUM confidence)
- learn.microsoft.com `ConvertFrom-StringData` docs (via WebSearch this session, not fetched directly) — regex-unescape behavior on values
- learn.microsoft.com `about_Character_Encoding` / PS 5.1 vs PS7 `Out-File`/`Get-Content` UTF8 BOM behavior (via WebSearch this session, not fetched directly)
- `.planning/research/PITFALLS.md`, `.planning/research/STACK.md`, `.planning/research/ARCHITECTURE.md` — this project's own pre-implementation research, some of it (the `.lbl`/`{project}` catalog sketch) now superseded by the actual `.lang` implementation

### Tertiary (LOW confidence)
- The PowerShell code examples in this document (Pattern 1, Pattern 2's allowlist snippet, Assert-CatalogKey) are derived by reasoning against verified bash behavior and verified catalog content, but **not executed under any PowerShell interpreter this session** — treat as a draft implementation to validate via `checkpoint:human-verify`, not as verified code

## Metadata

**Confidence breakdown:**
- Standard stack (bash-side contract): HIGH — read directly from executed, tested source
- Standard stack (PowerShell-side parsing design): MEDIUM/LOW — reasoned, not executed; `pwsh` absent from this host
- Architecture (positional-arg convergence): HIGH — mechanical mapping from verified bash signatures
- Pitfalls: HIGH for bash-side/CR-01 findings (live-tested); MEDIUM for PowerShell-side findings (reasoned from official docs + verified bash behavior, not executed)
- Glossary/calque scope: MEDIUM — grounded in this project's own prior research and locked constraints, but the exact denylist is inherently a judgment call requiring user confirmation

**Research date:** 2026-09-30
**Valid until:** 30 days (stable domain — bash/PowerShell scripting conventions do not shift quickly), but the `pwsh`-absence gap should be closed (or explicitly re-confirmed) before this research is used to plan execution, since several findings are contingent on a environment probe that could not run this session

## RESEARCH COMPLETE
