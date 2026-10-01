# Architecture Research

**Domain:** OUTPUT_LANG integration in a variables-contract + companion-scripts skill (md-to-wiki)
**Researched:** 2026-09-28
**Confidence:** HIGH (repo facts verified by direct file reading; external i18n patterns MEDIUM — see Sources)

## Standard Architecture

md-to-wiki already has a layered architecture (ADR 0001/0002). OUTPUT_LANG is **not** a new layer — it is a new value flowing through the existing layers, plus one new artifact (the label map) at the deterministic edge. Do not re-architect; extend.

### System Overview

```
┌───────────────────────────────────────────────────────────────────────┐
│ DISPATCH LAYER (unchanged)                                            │
│  SKILL.md router → agents/onboarding.md                               │
│  onboarding assigns ALL contract variables — OUTPUT_LANG joins here    │
├───────────────────────────────────────────────────────────────────────┤
│ CONTRACT LAYER (CONTEXT.md — single external reference home, ADR 0001) │
│  §Variables  + OUTPUT_LANG | pt-br | en   ← machine contract (agents)  │
│  §Anti-calque glossary (NEW §)           ← prose rules (agents only)   │
├───────────────────────────────────────────────────────────────────────┤
│ AGENT LAYER (8 agents — judgment prose)                               │
│  receive OUTPUT_LANG in dispatch prompt (same hand-off as AUDIENCE)    │
│  chrome nouns ← label map; explanatory prose ← glossary               │
├───────────────────────────────────────────────────────────────────────┤
│ DETERMINISTIC LAYER (scripts/*.sh|ps1 + templates/)                   │
│  receive OUTPUT_LANG as a trailing positional argument                │
│  resolve every chrome string by KEY against the label map             │
├───────────────────────────────────────────────────────────────────────┤
│ DATA LAYER (NEW artifact — single source of truth for chrome strings) │
│  labels/en.lbl   ← reproduces today's strings byte-exactly             │
│  labels/pt-br.lbl ← new translation                                   │
└───────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `agents/onboarding.md` | Assign `OUTPUT_LANG` (interview step 6: "output language — PT-BR default or English?"); default `pt-br` when the user expresses no preference | one new interview bullet + return-criteria line |
| `CONTEXT.md` §Variables | Register the variable: meaning, values `pt-br \| en`, default; document the canonical lowercase token; add the anti-calque glossary section | table row + new section (decision already fixed in PROJECT.md) |
| `labels/<lang>.lbl` (NEW) | Single source of truth for every chrome string, one file per language, `key=value` lines, UTF-8 no BOM | flat properties-style file; keys namespaced `index.*`, `mkdocs.*`, `wiki.*`, `dokuwiki.*`, `pdf.*`, `swagger.*` |
| `scripts/generate-mkdocs.{sh,ps1}` | Accept OUTPUT_LANG arg; resolve `site_name` pattern, `site_description`, `Home` nav label from map | trailing arg + lookup helper |
| `scripts/generate-index.{sh,ps1}` | Accept OUTPUT_LANG arg; resolve all headings, link labels, table headers, descriptions, footer from map | same |
| `scripts/to-dokuwiki.{sh,ps1}` | Resolve the import-README chrome from map | same |
| `scripts/to-pdf.{sh,ps1}` | Resolve book title `# Specifications` from map; TOC heading via `toc-title` **only after phase verification** (see Open Points) | same |
| `templates/swagger-ui.html` | Title `{{PROJECT_NAME}} — API Docs`: keep the `{{…}}` placeholder, move the suffix into the map; agent substitutes per existing step 4 of format-swagger | key `swagger.title_suffix` |
| Format agents (prose) | Write `Home.md`/`_Sidebar.md`, `openapi.yml` `info.title/description`, references appendix heading in OUTPUT_LANG per glossary; source canonical section nouns from the map | dispatch prompt + CONTEXT.md glossary |
| `tests/` fixture + regress script (NEW) | Byte-identity regression: run deterministic chain with `OUTPUT_LANG=en`, diff against golden files captured **before** any refactor | committed golden tree + `diff -r` harness; no engines needed (file-level diffs) |

## Recommended Project Structure

```
md-to-wiki/
├── SKILL.md                    # router — unchanged
├── CONTEXT.md                  # + OUTPUT_LANG row, + glossary section
├── labels/                     # NEW — the single chrome-string home
│   ├── en.lbl                  #   extracted verbatim from current scripts
│   └── pt-br.lbl               #   new translation, same key set
├── agents/                     # onboarding +0/+1 step; format agents +prose rule
├── scripts/                    # .sh/.ps1 twins consume the map
├── templates/                  # swagger-ui.html title via map key
└── tests/                      # NEW — golden fixture + regress.sh
    ├── fixtures/specs/         #    minimal sample .specs tree
    ├── golden/en/              #    expected output files (en)
    └── regress.sh              #    runs chain with OUTPUT_LANG=en, diff -r
```

### Structure Rationale

- **labels/ as a sibling of scripts/ and templates/:** it is data consumed by the deterministic layer, not agent documentation. Scripts self-locate it (`$(cd "$(dirname "$0")/.." && pwd)/labels`; PowerShell `$PSScriptRoot\..\labels`) — no new argument, works through the install symlink (traversing the symlinked dir still lands inside the clone). Do **not** use `readlink -f` (absent on BSD/macOS).
- **tests/ golden files in-repo:** PROJECT.md currently cites an ephemeral `/tmp/mdw-sr3` fixture. The byte-identity bar ("diff vazio no fixture") is only auditable if the fixture is committed. File-level diffs of `mkdocs.yml`, `docs/index.md`, the DokuWiki README, `specs-book.md`, and `swagger-ui/index.html` need neither mkdocs nor pandoc — the regression harness runs on this dev host despite missing engines.
- **CONTEXT.md holds the glossary, not the map:** two artifacts, two audiences. CONTEXT.md is prose an agent reads; the map is key=value a script parses. Mixing them forces scripts to parse agent documentation (and agents to read machine data). PROJECT.md's key decision already fixes the glossary in CONTEXT.md.

## Architectural Patterns

### Pattern 1: Message catalog — one catalog per locale, key-based lookup

**What:** All chrome strings live in per-language catalogs (`labels/en.lbl`, `labels/pt-br.lbl`) with identical key sets. Scripts never embed a visible string; they embed a key. This is the gettext/Rails-i18n shape: one dictionary file per locale, msgid/key as the lookup identifier (confidence MEDIUM — gettext docs via PHP manual, Elixir Localize, Rails guide).

**When to use:** any system where the same string set must render in N languages deterministically.

**Trade-offs:** one indirection between code and emitted text (you grep keys, not strings); in exchange, adding a language touches exactly one new file and zero scripts.

**Example:**
```
# labels/en.lbl                      # labels/pt-br.lbl
index.title={project} — Specifications    index.title={project} — Especificações
index.heading.features=Features           index.heading.features=Características
mkdocs.nav.home=Home                      mkdocs.nav.home=Início
```

```bash
# bash lookup — no new runtime dependency
OUTPUT_LANG="${OUTPUT_LANG:-pt-br}"           # contract default, lowercase-normalized
LABELS="$(cd "$(dirname "$0")/.." && pwd)/labels/$OUTPUT_LANG.lbl"
lbl() {                                       # <key>
  local v; v=$(sed -n "s/^$1=//p" "$LABELS" | head -1)
  [ -n "$v" ] || { echo "ERROR: label '$1' missing in $OUTPUT_LANG" >&2; exit 1; }
  printf '%s' "${v/\{project\}/$PROJECT_NAME}"   # whole-string placeholder interpolation
}
```
```powershell
# powershell twin
$map = @{}; Get-Content "$PSScriptRoot\..\labels\$OutputLang.lbl" -Encoding UTF8 |
  ForEach-Object { $i = $_.IndexOf('='); if ($i -gt 0) { $map[$_.Substring(0,$i)] = $_.Substring($i+1) } }
```

### Pattern 2: Whole-string patterns with placeholders, never suffix concatenation

**What:** Store the complete pattern (`{project} — Specifications`), not a composable suffix (`Specifications`) glued on by code. Word order then belongs to the catalog, not the code — PT-BR can become `Especificações do {project}` without touching a script. This is the Rails i18n interpolation rationale: "all grammatical and punctuation decisions are made in the definition itself" (official Rails guide, confidence MEDIUM).

**When to use:** any template string that mixes a runtime value with translated text — here: titles (`{project} — …`), the footer date, the Swagger title.

**Trade-offs:** none at this scale; the lookup helper does one substitution.

### Pattern 3: Normalize at the boundary, fail loudly on missing keys

**What:** BCP 47 tags are case-insensitive by spec but filenames are case-sensitive on Linux (`pt-br.lbl` ≠ `pt-BR.lbl`). The contract therefore fixes ONE canonical token — lowercase `pt-br` (matches HTTP Accept-Language habit, matches the existing `developer|stakeholder|general` lowercase-token style) — and each script lowercases its argument before lookup. A key absent from any catalog is a hard error, not a fallback.

**When to use:** closed key sets with a regression bar. This is a deliberate, justified deviation from canonical gettext, whose missing-translation behavior is "fall back to the msgid (English) silently" (confidence MEDIUM): that default exists for open-ended translation corpora. Here the key set is small and closed, and a silent en fallback in a `pt-br` run produces mixed-language chrome — precisely the defect class this milestone exists to kill. Rails makes the same call for tests (`raise_on_missing_translations` recommended enabled — official guide).

**Trade-offs:** a typo'd key breaks the build — which is the point: it becomes visible in the regression run instead of in published output.

### Pattern 4: Contract variable hand-off by dispatch prompt, never ambient environment

**What:** OUTPUT_LANG flows exactly as AUDIENCE does today: assigned once in onboarding → carried in the dispatch prompt → passed by the agent as a trailing positional argument at each script call. ADR 0001 already rules "variable hand-off is by dispatch prompt, never ambient environment"; OUTPUT_LANG must not become an exported env var read implicitly by scripts. (The lone `MDW_INDEX_OUT` env knob already in generate-index.sh is an output-path escape hatch, not a contract variable — not a precedent to extend.)

**When to use:** always, in this repo — it is the existing convention; deviating creates a second, invisible propagation channel the audit rubric cannot check.

## Data Flow

### Request Flow — a label resolves deterministically

```
user answer ("em português")
    ↓
onboarding assigns OUTPUT_LANG=pt-br (default when indifferent)
    ↓  dispatch prompt (with all variables)
format agent (e.g. format-mkdocs)
    ↓  script call: $SCRIPT_RUNNER "$SKILL_DIR/scripts/generate-index$SCRIPT_EXT" \
    ↓                "$PROJECT_NAME" "$AUDIENCE" "$OUTPUT_LANG" docs/specs/features
script: normalize lang token → load labels/pt-br.lbl → lbl index.title → {project} substitution → emit
```

### Request Flow — agent prose resolves by rule, not lookup

```
dispatch prompt carries OUTPUT_LANG
    ↓
agent reads CONTEXT.md §glossary (agents already read CONTEXT.md per ADR 0001)
    ↓
writes chrome prose in OUTPUT_LANG following glossary (termo → forma canônica);
canonical section nouns (Features/Características, Architecture/Arquitetura)
come from the SAME map keys so terminology is identical across all 5 surfaces
```

Boundary rule, stated once in CONTEXT.md: **if the string names a generated surface, take it from the map; if it explains, follow the glossary.**

### Key Data Flows

1. **en byte-identity (the regression bar):** the en catalog is *extracted* from the current scripts (grep/sed the literals into the map), never retyped. Golden fixtures are captured from the unmodified chain FIRST; after the refactor, `OUTPUT_LANG=en` re-runs the chain and `diff -r` must be empty. Byte-identity is defined per-artifact against the current `.sh` output (the validated MkDocs chain per PROJECT.md).
2. **pt-br rendering:** identical code path, different catalog — no branching on language inside scripts beyond the one filename.
3. **Content stays untouched:** nav labels derived from filenames (generate-mkdocs) and every spec body remain verbatim in whatever language the author wrote — the skill transforms sources, it does not re-write authorship (PROJECT.md key decision).

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 2 languages, ~40 keys (v1) | two `.lbl` files; nothing else — recommended shape |
| +1 language (es, future) | add `labels/es.lbl` + one glossary section; zero script changes |
| +1 output surface | add keys under a new namespace; map files grow in lockstep (missing key fails loudly) |
| Keys grow past ~100 | consider splitting `labels/<lang>/` per surface — premature now |

### Scaling Priorities

1. **First bottleneck — key-set drift between language files:** prevented by design: hard-fail on missing key + regression diff covers both catalogs once a pt-br golden set is added.
2. **Second bottleneck — .sh/.ps1 re-divergence:** the map removes the string axis of drift (strings live once); the *logic* axis (audience arms, output paths) still exists — the en regression run should exercise both shells once a Windows host is available; until then note it as a known gap.

## Anti-Patterns

### Anti-Pattern 1: Per-script inline `case "$OUTPUT_LANG"` blocks

**What people do:** each script embeds both languages in a branch.
**Why it's wrong:** md-to-wiki already proved this failure mode — today's English-only strings are duplicated across .sh/.ps1 twins and have *already* drifted: generate-index.ps1 lacks the developer "Quick Start" arm, emits a different feature table and a different footer URL (opencode.ai vs github.com); generate-mkdocs.ps1 writes mkdocs.yml to a different path with an extra "Issues" nav entry. Inline branches multiply the copies to 2 shells × N languages and re-create exactly the 12-duplicated-meanings problem ADR 0001 was written to close.
**Do this instead:** one shared data file per language; shells differ only in the ~5-line lookup helper.

### Anti-Pattern 2: Silent fallback to English on a missing key

**What people do:** copy gettext's default `missing → msgid` behavior.
**Why it's wrong:** silent fallback yields mixed-language chrome in the default (`pt-br`) path and hides key-set drift from every check.
**Do this instead:** exit non-zero with the key name (Pattern 3).

### Anti-Pattern 3: Passing OUTPUT_LANG by environment variable

**What people do:** `export OUTPUT_LANG` once and let scripts read it.
**Why it's wrong:** bypasses the documented hand-off (dispatch prompt), invisible in agent transcripts, unchecked by the completion criteria — and ambient state is exactly what ADR 0001 removed.
**Do this instead:** trailing positional argument, recorded in CONTEXT.md's script-call convention.

### Anti-Pattern 4: Splitting sentences into composable fragments

**What people do:** store suffixes/prefixes and concatenate in code.
**Why it's wrong:** word order is a property of the target language; PT-BR may invert `{project} — Especificações` to `Especificações do {project}`.
**Do this instead:** whole-string patterns with `{project}` placeholders (Pattern 2).

### Anti-Pattern 5: Authoring the en catalog by re-typing the strings

**What people do:** copy strings by hand into the new map.
**Why it's wrong:** byte-identity dies at extraction time — one changed space or dash variant and the regression diff is forever noisy.
**Do this instead:** extract mechanically from the live scripts; the diff is the proof of extraction.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| pandoc (PDF) | `--toc` unchanged; optional `-V toc-title=<lbl pdf.toc_title>` | `toc-title` support is writer-dependent (historically EPUB/docx; modern templates extend toward LaTeX/HTML) and unverified for weasyprint — MEDIUM confidence, verify live in the PDF phase; if unsupported, record "engine TOC heading stays English" as an accepted limitation (MEDIUM, phase flag) |
| Swagger UI / MkDocs Material | none — they render whatever chrome strings we emit | engine UI chrome (MkDocs search placeholder etc.) is out of scope |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| onboarding ↔ CONTEXT.md | assigns every §Variables row; adds OUTPUT_LANG | default pt-br; canonical token lowercase |
| CONTEXT.md ↔ format agents | agents read, never restate | glossary section is agent-only; map is not in CONTEXT.md |
| format agents ↔ scripts | positional args; OUTPUT_LANG appended LAST to existing signatures | omitted arg → script applies contract default pt-br; explicit `en` → legacy bytes |
| scripts ↔ labels/ | self-located read; key lookup; hard fail on miss | no `readlink -f` (BSD/macOS); `cd+pwd` traverses the install symlink fine |
| agents ↔ labels/ (prose nouns only) | read the same catalogs for canonical section nouns | keeps terminology identical across the 5 surfaces |
| everything ↔ tests/ | golden en fixtures; `diff -r` after chain run | fixtures committed; capture precedes any code change |

## Build Order (dependencies → phase structure)

Each step depends on the one above it being verifiable:

1. **Golden fixture capture** — run the *unmodified* chain over a minimal sample specs tree; commit outputs as `tests/golden/en/`. Must precede any refactor: it is the definition of "current behavior". No engines required.
2. **Label map (en) + key scheme** — mechanically extract ~40 chrome strings from generate-index, generate-mkdocs, to-dokuwiki, to-pdf, swagger-ui.html, templates/index.md; define namespaces. Verifiable: extracting is a diff-able operation.
3. **Contract wiring** — CONTEXT.md variable row + glossary section stub; onboarding interview step + return criterion. Inert until scripts accept the arg, but establishes the canonical token and default before code depends on them.
4. **Script consumption (.sh)** — five .sh scripts + template take the trailing arg and resolve via lookup. Verifiable: `OUTPUT_LANG=en` chain diff vs step-1 fixture is empty → **hard checkpoint, commit here**.
5. **pt-br catalog + glossary content** — translate the key set; author termo→forma-canônica entries. Verifiable: no missing-key errors; pt-br golden set optionally captured as translation review artifact.
6. **Script consumption (.ps1)** — same wiring in the PowerShell twins. Note: en byte-identity is defined against the .sh output; the .ps1 twins currently diverge (footer URL, feature table, mkdocs.yml path) — converging them onto the shared map deliberately normalizes Windows output to the .sh canonical strings. Flag this as an accepted, separately-noted behavior change rather than silently mixing.
7. **Agent-prose convention** — dispatch-prompt line in SKILL.md's Execution Flow (variables list already flows), glossary-following rules + map-sourced nouns in format-github-wiki, format-swagger, format-dokuwiki, format-pdf (fallback block), references (appendix heading). Verifiable per rubric delta audit.
8. **Regression harness + docs** — `tests/regress.sh` wired; README/README.pt-BR + rubric updated; pt-br end-to-end run on a host with engines.

**Ordering rationale:** the safety net (1) must exist before any string moves; the map (2) must exist before any consumer; the en checkpoint (4) isolates "did extraction change bytes?" from "is the translation good?" — two failure modes that must not be debugged together; .ps1 (6) and prose (7) are independent of each other but both depend on 2–5; pandoc `toc-title` (PDF) is isolated verification work inside step 4/7, gated by a live engine host.

## Phase-Specific Warnings

| Phase topic | Likely pitfall | Mitigation |
|-------------|---------------|------------|
| Fixture capture | golden files generated *after* the refactor "pass" trivially | capture on a clean checkout of the pre-milestone commit; tag the fixture commit |
| en extraction | em-dash `—` vs `-`, trailing spaces, `— %s` date spacing | extract mechanically; never hand-edit; diff must be byte-level (`diff -r`, not git diff word-mode) |
| pt-br catalog | calques ("deployar", "printar") and LLM tics sneaking into labels | glossary review is a named checklist item; glossary manda over prose instinct (PROJECT.md constraint) |
| .ps1 wiring | PowerShell 5 `Out-File -Encoding utf8` emits BOM; PT-BR diacritics | label files saved UTF-8 no BOM; ps1 reads with `-Encoding UTF8`; verify emitted `docs/index.md` bytes |
| Date in footer | `date +%Y-%m-%d` is locale-sensitive chrome (PT-BR convention dd/mm/yyyy) | recommended: keep ISO 8601 for all languages (international standard, en-identical, zero mechanism); alternative per-language format needs per-shell date tokens (strftime vs Get-Date) — decide once in roadmap, do not improvise per script |
| PDF TOC | `toc-title` writer-dependence | verify on live engine; if unsupported, record accepted limitation (ADR-worthy note) |

## Sources

- **Repo (HIGH — direct file evidence, read 2026-09-28):** `/home/shenmue/md-to-wiki-docs-skills/` — SKILL.md, CONTEXT.md, agents/{onboarding,format-mkdocs,format-pdf,format-github-wiki,format-swagger,references,format-dokuwiki}.md, scripts/{generate-index,generate-mkdocs,to-pdf,to-dokuwiki}.{sh,ps1}, templates/{swagger-ui.html,index.md}, docs/adr/0001-external-reference-home.md; observed .sh/.ps1 divergence in generate-index and generate-mkdocs twins.
- **gettext fallback-to-msgid (MEDIUM, cross-checked):** [PHP Manual — gettext](https://www.php.net/manual/en/function.gettext.php); Elixir Localize changelog explicitly matching gettext fallback behavior ([hex.pm](https://hex.pm)); Lingohub on Rails locale fallback chains ([lingohub.com](https://lingohub.com)).
- **Rails i18n — per-locale files, `%{}` interpolation, raise-on-missing in tests (MEDIUM, official primary source):** [Rails Guides — Rails Internationalization](https://guides.rubyonrails.org/i18n.html).
- **BCP 47 case-insensitivity + pt-BR casing convention (MEDIUM, cross-checked):** OpenID Connect spec text ("BCP47 language tag values are case insensitive"); Java `Locale` docs (region field case-insensitive, canonicalized uppercase) ([docs.oracle.com](https://docs.oracle.com)); Apertium wiki on code confusion ([wiki.apertium.wiki](https://wiki.apertium.wiki)).
- **pandoc `toc-title` writer-dependence (MEDIUM):** Pandoc User's Guide ([pandoc.org](https://pandoc.org/MANUAL.html)); older guide listing it as EPUB/docx-only ([public.dalibo.com](https://public.dalibo.com)); pandoc template docs ([git mirror](https://git.pashev.ru)).

---
*Architecture research for: OUTPUT_LANG integration in md-to-wiki*
*Researched: 2026-09-28*
