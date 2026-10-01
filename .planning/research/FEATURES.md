# Feature Research

**Domain:** Output-language (i18n of generated chrome) added to a spec-tree → multi-destination docs generator
**Researched:** 2026-09-28
**Confidence:** HIGH (pattern level — every load-bearing pattern confirmed across 3+ independent primary sources; see per-claim notes)

**Scope note:** This milestone adds `OUTPUT_LANG` (default `pt-br`, `en` supported) to md-to-wiki, which already generates MkDocs Material sites, GitHub Wikis, DokuWikis, PDF books, and Swagger UI pages. Research covers how output-language features behave when ADDED to existing docs tooling — not the existing features.

**Confidence legend used below:**
- HIGH — pattern confirmed across 3+ independent primary (official docs) sources
- MEDIUM — single primary source, or cross-checked secondary sources
- LOW — unverified / partially blocked this session; flagged for re-verification, never load-bearing below

---

## The Governing Pattern (read this first)

Every surveyed tool implements output language through the same invariant, and it matches this milestone's scope exactly:

> **Translate the chrome (UI labels the tool generates); never the content (what the user wrote).** MkDocs Material translates "template variables and labels" only. Docusaurus translates navbar/footer/sidebar chrome via JSON, content via separate whole-file translation. Sphinx translates generated UI messages (navigation bars) via its own bundled catalogs, content via the gettext `.po` workflow. Hugo translates theme strings from `i18n/<lang>.toml`, content via separate per-language files. (HIGH — four independent official sources agree)

Second invariant: **one canonical language per build**, expressed as a single top-level parameter — `theme.language` (Material), `defaultContentLanguage` (Hugo), `i18n.defaultLocale` (Docusaurus), `language` (Sphinx), `root` locale (VitePress). Multi-language in one site (locale path prefixes, language switchers, hreflang) is a *separate, later* product feature everywhere it exists. (HIGH)

Third invariant: **labels live in per-language catalogs, never inline in code.** Hugo `i18n/` files, Docusaurus JSON, Sphinx `.po`, Material language partials, mdbook-i18n-helpers gettext. No surveyed tool scatters translations as conditionals. (HIGH)

md-to-wiki's v1 `OUTPUT_LANG` is therefore the standard "single-locale chrome localization" feature, not the "multilingual site" feature. Everything below follows from that placement.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Missing any of these makes output-language support look broken. Complexity rated for THIS codebase (bash scripts + templates, 5 surfaces).

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **T1. Single top-level `OUTPUT_LANG` parameter with stable, documented default** | Every tool has exactly one language knob (`theme.language`, `defaultContentLanguage`, `defaultLocale`, `language`). Users look for one switch, not per-script flags. | LOW | Contract-layer parameter (PROJECT.md already commits to this). Default `pt-br` per project decision; must be documented where the parameter is documented. HIGH. |
| **T2. Locale normalization (accept `pt-br`, `pt-BR`, `PT-BR`; one canonical internal form)** | BCP 47 tags are case-insensitive; tools vary in what they emit/accept (pandoc and Material use `pt-BR`; Hugo config keys/URLs conventionally lowercase `pt-br`; static-i18n accepts `en_US` underscore form). Case-sensitive string matching is a classic tag-comparison bug. | LOW | Normalize on input (e.g. lowercase internally), emit RFC-recommended casing (`pt-BR`) in generated artifacts (`html lang`, pandoc `lang`, hreflang later). Reject unknown values loudly. MEDIUM (RFC 5646 semantics + observed tool variance). |
| **T3. Externalized label catalog (per-language data files, not inline conditionals)** | No surveyed tool embeds translations in logic; catalogs are the universal substrate (gettext, TOML, JSON, language partials). Inline `if lang == pt-br` in 5 scripts multiplies per added language and per added label. | LOW-MEDIUM | For bash: sourced per-locale label maps (associative arrays or `key=value` files). The en catalog must contain the current strings *verbatim* — that is what makes T7 cheap. HIGH (universal pattern). |
| **T4. Complete chrome coverage — every generated label translated on all 5 surfaces, zero mixed-language output** | Mixed-language chrome is the most visible defect an i18n feature can ship; static-i18n's behavior of leaving unmatched nav titles in the source language reads as "unfinished translation." Users don't give credit for 90% coverage. | MEDIUM | The work is the inventory: `generate-index.sh` (Quick Start, Overview, Features, Architecture, Getting Started, Development), `generate-mkdocs.sh` (`site_name` "— Specifications" suffix, Home), `templates/swagger-ui.html` labels, any PDF front-matter/headings, wiki/DokuWiki index chrome. Known inventory exists in PROJECT.md Context. HIGH. |
| **T5. Explicit fallback policy, fail-closed on missing keys** | Every system defines fallback (Material: en always fallback; VitePress: fall back to root; Docusaurus: default messages render). For a deterministic build tool with a tiny catalog, the correct policy is a **hard error naming the missing key**, not silent en fallback — silent fallback is precisely what produces mixed output (see A4). | LOW | Document the policy in CONTEXT.md; enforce in catalog loader. HIGH (fallback is universal; fail-closed choice is the build-tool-appropriate variant). |
| **T6. `lang` plumbed to platforms that consume it** | Setting the language declaration is a one-line change with real effects everywhere: Material `theme.language: pt-BR` translates ALL Material chrome (search placeholder, footer, prev/next) plus selects a language-specific search stemmer and sets `html lang`; pandoc `lang: pt-BR` (BCP 47) drives hyphenation, translated element names ("Chapter" → "Capítulo") and localized dates in PDF; `<html lang>` on the Swagger page. Skipping this re-translates nothing and leaves platform chrome in English next to translated chrome. | LOW | Note the boundary: Swagger UI's *component* UI (Authorize, Try it out) has **no localization option** in current master configuration docs (verified by direct fetch) — only page chrome we author is translatable. Document that boundary; do not attempt to patch the component. HIGH. |
| **T7. Byte-identical `en` regression (fixture diff empty)** | Project constraint (protects existing English users), and the ecosystem norm that builds are reproducible. Achievable only if en strings are extracted verbatim into the catalog (T3) and the default change doesn't leak into `en` builds. | LOW-MEDIUM | Diff harness against the existing validated fixture (`/tmp/mdw-sr3` pattern). This is the milestone's objective acceptance bar — PROJECT.md commits to it. HIGH (project bar; mechanics standard). |
| **T8. Never translate paths, filenames, anchors, or page IDs — display titles only** | No tool localizes paths; static-i18n is explicit: "we do not need to localize the path or file names," nav entries keep canonical paths with translated titles. Translating them breaks links, GitHub Wiki page slugs, and DokuWiki page IDs. | LOW | Discipline + a link-check regression (the chain already verifies links). HIGH. |
| **T9. Chrome/content boundary stated in the contract** | The chrome-vs-content split is universal; the user-facing equivalent is: `OUTPUT_LANG` changes what the *scripts and agents generate* (labels, nav titles, index chrome, prose they author), never the spec content flowing through. PROJECT.md already places content translation Out of Scope. | LOW | One paragraph in CONTEXT.md; prevents the most likely misexpectation (A1). HIGH. |

### Differentiators (Competitive Advantage)

Not required for a correct v1; valuable beyond it. Ordered by value-to-cost.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **D1. Anti-calque glossary enforced via CONTEXT.md (termo → forma canônica)** | No mainstream generator enforces translation *quality*; they stop at string replacement. A checkable glossary ("deployar"/"printar"/"commitar" banned; technical term stays whole in English or uses consagrado equivalent) is a genuine differentiator for a lusophone-targeted tool, and it makes the agents' prose convention auditable instead of subjective. | LOW-MEDIUM | **Promoted to v1 by PROJECT.md (Active requirement)** — listed here because the ecosystem does not have it, not because it is optional this milestone. Table + audit hook in the delta-rubric flow. |
| **D2. Additional locales beyond en/pt-br (es, fr, …)** | With T3 in place, a new locale is a new data file, not new code — Hugo and Docusaurus scale exactly this way (per-language catalog files; `write-translations --locale xx`). | LOW (after T3) | Value gated on actual demand from a lusophone-first user base; do not pre-translate. MEDIUM. |
| **D3. Translated directory-derived nav/section names (nav_translations-style mapping)** | mkdocs-static-i18n's `nav_translations` (key/value map from default-language title → translated title) is the proven mechanism. md-to-wiki's nav sections derive from user directory names — translating them touches user authorship, which is why it is NOT table stakes: v1 translates fixed chrome only; dir-derived names get an explicit user-provided mapping. | MEDIUM | Requires the mapping table surfaced through the contract layer. Unmatched names must keep original spelling (title-only, per T8). HIGH (mechanism verified in official docs). |
| **D4. Locale-aware PDF typography** | pandoc `lang` gives hyphenation + "Chapter"→"Capítulo" + localized dates via babel/polyglossia for free; WeasyPrint needs `lang` attribute + `hyphens` CSS + pyphen dictionaries. Engine-dependent — a real quality gap between pt-br and en PDF output if skipped. | MEDIUM | Depends on engine matrix (weasyprint-first today, pandoc fallback). T6 is the one-line seed; full typography is polish. MEDIUM-HIGH (pandoc manual + template evidence). |
| **D5. Per-format language overrides (e.g., site pt-br, wiki en)** | Single-target tools cannot express this; a multi-destination generator naturally can. Niche but uniquely available to md-to-wiki's shape. | LOW-MEDIUM | Only after T1; keep precedence rules dead simple (global default, per-format override). No ecosystem precedent surveyed — project-shaped feature. |
| **D6. Locale-aware dates/numbers in generated chrome** | Docusaurus derives calendar format from locale names; pandoc localizes dates in PDF. Matters only if chrome starts embedding dates (e.g., "Generated on …"). | MEDIUM | Defer until chrome contains date/number output worth formatting; number formatting is generally delegated to platforms. MEDIUM. |
| **D7. User-extensible catalog (override/add labels)** | Material (custom language partials) and Hugo (project `i18n/` overriding theme files key-by-key) both allow user overrides — the standard escape hatch when a shipped translation displeases. | MEDIUM | v1.x at earliest; needs stable key names first. HIGH (pattern in two official sources). |
| **D8. hreflang + language switcher across two deployed builds** | The full multilingual-site feature: Material `extra.alternate` (name/link/lang), Docusaurus auto-hreflang, VitePress locale dropdown. Expected only once BOTH an en site and a pt-br site are deployed and linked. | HIGH | Requires multi-build + deploy story; explicitly a different product capability than single-locale OUTPUT_LANG. Defer to a future milestone. HIGH. |
| **D9. RTL support (`dir`)** | Material infers direction from language; Docusaurus/VitePress expose `dir`. Irrelevant until a RTL locale is actually requested. | HIGH | Defer; note in catalog design that locales should carry a `dir` field eventually. HIGH. |

### Anti-Features (Commonly Requested, Often Problematic)

Things to deliberately NOT build. Each has a documented failure mode in the ecosystem.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **A1. Machine-translating spec content inside the pipeline** | "Make my whole wiki PT-BR with one command." | Violates the universal chrome/content split: content translation is a human/TMS workflow everywhere (Sphinx → Transifex/Weblate; Docusaurus leaves translation files for humans to fill). Rewrites user authorship, produces unauditable output, and is already Out of Scope in PROJECT.md. | Translate chrome only (T9 boundary). Users translate content upstream; the skill transforms, never rewrites. |
| **A2. Auto-detecting the source language** | "The skill should just know." | Detection is an inference, not a fact — i18n guidance is unanimous that explicit user choice must override detection (SimpleLocalize's technical guide). Fragile on small samples (short specs), non-deterministic, and already rejected during milestone questioning. | Explicit `OUTPUT_LANG` with documented default (T1). |
| **A3. Per-user / per-run language memory (or Accept-Language-driven output)** | "Remember I prefer PT-BR." | Docs builds are artifacts, not sessions. Remembering state breaks same-inputs-same-outputs determinism and makes builds unreproducible across machines. | Explicit parameter on each invocation; stable default. |
| **A4. Silent fallback to English for missing labels** | "Just ship it, fall back gracefully." | Silent fallback is the mechanism behind the #1 visible i18n defect — mixed-language pages. static-i18n's unmatched nav titles staying in the source language is the canonical cautionary example. | Fail closed (T5): hard error naming missing keys. With a ~dozen-key catalog, completeness is cheap; hiding gaps is not graceful. |
| **A5. Translating paths/anchors/filenames/page IDs** | "The wiki should have Portuguese URLs." | Breaks every internal link, GitHub Wiki page slugs, DokuWiki page IDs, and cross-format link conversion — the chain's core value. No tool does it (static-i18n explicitly keeps canonical paths). | Titles only (T8); paths remain stable identifiers. |
| **A6. Locale-suffixed source structures (`page.pt-br.md`) in v1** | "Do it like mkdocs-static-i18n." | That structure exists to serve *many languages from one tree in one build* — a different feature. For one locale per invocation it doubles discovery complexity and contract surface for zero user value. | Catalog-driven chrome (T3). Revisit only if multi-locale same-tree output is ever demanded. |
| **A7. Inline per-language conditionals scattered across the 5 scripts** | Fastest first implementation. | No tool scatters translations in code — catalogs are universal because inline pairs of (language × label × script) multiply combinatorially and are untestable. Also poisons T7: en strings must be data, not the `else` branch. | Single shared catalog mechanism (T3), sourced by all scripts. |

---

## Feature Dependencies

```
[T1 OUTPUT_LANG param + T2 normalization]
        │
        ▼
[T3 label catalog] ──────────────────────────────┐
        │                                         │
        ├──requires──> [T4 chrome coverage, 5 surfaces]
        │                      │
        │                      ▼
        │              [T7 byte-identical en regression]
        │              (en strings extracted verbatim INTO T3)
        │
        ├──requires──> [T5 fail-closed fallback policy]
        │
        └──requires──> [T6 lang plumbing: theme.language / pandoc lang / html lang]
                       │
                       └──enhances──> [D4 locale-aware PDF typography]

[T8 titles-not-paths] ──governs──> [T4] and [D3]

[D3 translated dir-derived nav names] ──requires──> [T3] + user mapping table
                                              ──conflicts with──> [A5] if misimplemented via renames

[D2 more locales]      ──requires──> [T3] + [T5] (completeness gate per locale)
[D5 per-format override] ──requires──> [T1]; keep simple precedence
[D7 user-extensible catalog] ──requires──> [T3] with stable key names
[D8 hreflang + switcher] ──requires──> multi-build + deploy of BOTH locales
                        ──conflicts with──> single-locale-per-build v1 scope
[D9 RTL]               ──requires──> a RTL locale actually requested
[D1 glossary]          ──independent──> (CONTEXT.md data + audit hook; shares nothing with T-items technically)
```

### Dependency Notes

- **T7 requires T3 done as *extraction*, not *rewriting*:** the en catalog must be populated with the current hardcoded strings byte-for-byte, then scripts read from the catalog. Rewriting strings while extracting breaks the regression bar. This ordering is the single most important implementation sequencing.
- **T4 requires a chrome inventory first:** enumerate every label the scripts/templates emit today (PROJECT.md Context holds the known list). The inventory is simultaneously the catalog key list and the T7 checklist.
- **D3 (nav section names) is deliberately behind v1's line:** section names derive from user directories (authorship), unlike fixed chrome. It needs an explicit user mapping — the nav_translations pattern — rather than translation-by-default.
- **D8 conflicts with the v1 shape:** hreflang/switchers presuppose multiple locales coexisting at URLs. v1 builds one locale per invocation; building the switcher infrastructure now would be speculative.
- **T6 partially blocked by platform reality:** Swagger UI component chrome is not localizable via documented config (verified against master). Scope T6 there to the page we generate (title, headings, `lang` attribute) and document the boundary — attempting component translation would be fighting the platform.

## MVP Definition

### Launch With (v1 — this milestone)

- [ ] **T1** `OUTPUT_LANG` in the contract layer, default `pt-br`, `en` supported — the single knob users will look for
- [ ] **T2** locale normalization (`pt-br`/`pt-BR` accepted; canonical `pt-BR` emitted; unknown → loud error)
- [ ] **T3** shared label catalog, en strings extracted verbatim — the enabler of everything else
- [ ] **T4** complete chrome translation across all 5 surfaces (MkDocs index+nav, GitHub Wiki, DokuWiki, PDF, Swagger page)
- [ ] **T5** fail-closed missing-key policy
- [ ] **T6** `lang` plumbed: `theme.language` in mkdocs.yml, `lang` in pandoc metadata, `lang` attribute in Swagger template
- [ ] **T7** `OUTPUT_LANG=en` fixture diff byte-identical — the objective regression bar
- [ ] **T8** titles-not-paths rule held (link verification stays green)
- [ ] **T9** chrome/content boundary documented in CONTEXT.md
- [ ] **D1** anti-calque glossary in CONTEXT.md (promoted into v1 by PROJECT.md Active requirements)

### Add After Validation (v1.x)

- [ ] **D2** additional locales — trigger: a user actually requests one; cost is one data file
- [ ] **D3** translated dir-derived nav names via user mapping — trigger: users ask for Portuguese section names without renaming dirs
- [ ] **D5** per-format overrides — trigger: real mixed-language deployment need
- [ ] **D4** full locale-aware PDF typography — trigger: pt-br PDF quality complaints (hyphenation, "Capítulo")

### Future Consideration (v2+)

- [ ] **D7** user-extensible catalog overrides — defer until key names are stable across releases
- [ ] **D8** hreflang + language switcher — defer until multi-locale coexistence is a real requirement (deploy story needed)
- [ ] **D9** RTL — defer until a RTL locale is requested; keep a `dir` field in catalog design so it is not foreclosed
- [ ] **D6** locale-aware dates/numbers — defer until chrome emits dates worth formatting

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| T1 OUTPUT_LANG param | HIGH | LOW | P1 |
| T3 catalog (verbatim en) | HIGH | LOW-MEDIUM | P1 |
| T4 chrome coverage 5 surfaces | HIGH | MEDIUM | P1 |
| T7 byte-identical en regression | HIGH | LOW-MEDIUM | P1 |
| T5 fail-closed fallback | HIGH | LOW | P1 |
| T2 locale normalization | MEDIUM | LOW | P1 |
| T6 lang plumbing | MEDIUM | LOW | P1 |
| T8 titles-not-paths | HIGH (breakage prevention) | LOW | P1 |
| T9 boundary documented | MEDIUM | LOW | P1 |
| D1 glossary | HIGH (project-specific) | LOW-MEDIUM | P1 (per PROJECT.md) |
| D3 translated nav names | MEDIUM | MEDIUM | P2 |
| D2 more locales | LOW today | LOW after T3 | P2 |
| D4 PDF typography | MEDIUM | MEDIUM | P2 |
| D5 per-format override | LOW | LOW-MEDIUM | P3 |
| D6 dates/numbers | LOW | MEDIUM | P3 |
| D7 user catalog overrides | LOW | MEDIUM | P3 |
| D8 hreflang/switcher | LOW (v1) | HIGH | P3 |
| D9 RTL | VERY LOW (no locale) | HIGH | P3 |

## Competitor Feature Analysis

How established tools deliver the same feature. "Our approach" = the recommendation above.

| Dimension | MkDocs Material | mkdocs-static-i18n | Docusaurus | Sphinx | Hugo | Our Approach |
|-----------|-----------------|--------------------|------------|-------|------|--------------|
| Language knob | `theme.language` (default `en`) | `languages[]` with one `default: true` built at `/` | `i18n.defaultLocale` + `locales` | `language` in conf.py | `defaultContentLanguage` | Single `OUTPUT_LANG`, default `pt-br` (T1) |
| Chrome translation mechanism | Bundled theme translations; overrides via custom language partial | `nav_translations` map (default-language title → translation) | JSON files (`navbar.json`, `code.json`) scaffolded by `write-translations` | Sphinx-bundled UI message translations | `i18n/<lang>.toml` catalogs | Shared bash-sourced label catalog (T3) |
| Content translation | None (explicitly labels-only) | Suffix/folder per-locale page files | Whole-file markdown translation | gettext `.po` per document | Filename suffix / content dirs | **Never** — chrome only (T9/A1) |
| Missing translation behavior | `en` always fallback | Unmatched titles stay in source language (mixed) | Default messages render as-is | Warning on cross-ref mismatch | Improved default-lang fallback in recent versions | **Hard error naming key** (T5) |
| Locale codes | ISO 639-1 + regional (`pt-BR`) | 2-letter or `en_US` territory | `pt-BR` folder names | `language` code | lowercase keys (`pt-br`) in URLs | Normalize input, emit `pt-BR` (T2) |
| `lang`/SEO plumbing | `html lang` via `language`; hreflang via `extra.alternate` | Switcher `link`s | Auto `html lang` + hreflang; `localeConfigs.htmlLang` | Theme-dependent | Per-locale `lang` | Emit `lang` in mkdocs.yml/pandoc/html now; hreflang deferred (T6/D8) |
| Single-locale-only build supported? | Yes (the default) | Yes (minimal example) | Yes (`start --locale fr`) | Yes | Yes | Yes — the v1 shape (one locale per invocation) |
| Search localization | Language-specific stemmer | Per-locale search indexes | Per-locale | n/a | n/a | Comes free via `theme.language` (T6) |

**Target-platform notes (the other side of each surface):**
- **Swagger UI (embedded target):** no `lang`/`translation`/`i18n` option exists in current master configuration docs (verified by direct fetch, twice — negative claim checked against the authoritative file). Chrome we can translate = the page we generate only. Historical 2.x `lang/` translation files did not survive as documented config.
- **GitHub Wiki (target):** no native multi-language support; community conventions are language-suffixed/prefixed pages or a hub page. Output-language applies only to page content we author (headings, generated index chrome).
- **DokuWiki (target):** interface language (`lang` config, default `en`) is a server setting outside the generator's control; its translation plugin organizes translated *pages* in per-language namespaces — a content-translation pattern, out of our scope. LOW confidence on config details (dokuwiki.org blocked this session, HTTP 402) — re-verify before depending on specifics; direction (interface language ≠ ours to set) is safe.
- **PDF (pandoc path):** `lang: pt-BR` metadata → babel/polyglossia → hyphenation, "Chapter"→"Capítulo", localized dates. WeasyPrint path: `lang` + `hyphens` CSS + pyphen.

## Method Notes and Gaps

- The 5 docs questions routed to context7; ctx7 CLI is absent in this environment, so primary sources were fetched directly from official documentation URLs (documented deviation per the documentation-lookup fallback rules).
- The web-search MCP quota exhausted mid-research; affected items (Hugo/mdBook details, BCP 47 casing, DokuWiki config, locale-aware features) were completed via the pre-quota searches plus direct fetches. Per-claim confidences above reflect this honestly.
- mkdocs-static-i18n is **frozen as-is** (maintainer announcement; MkDocs upstream uncertainty). It is evidence for feature *patterns* (nav_translations, fallback, single-locale builds) — not a dependency candidate. Dependency questions belong to STACK.md.
- Not researched (out of Features scope): catalog file format choice for bash, gettext-vs-map tradeoffs, PowerShell portability — covered by the Stack researcher.

## Sources

Primary (official docs, fetched this session):
- MkDocs Material — Changing the language: https://squidfunk.github.io/mkdocs-material/setup/changing-the-language/ (MEDIUM — single primary source; corroborated by static-i18n integration docs)
- mkdocs-static-i18n — Setting up languages: https://ultrabug.github.io/mkdocs-static-i18n/setup/setting-up-languages/ and Localizing navigation: https://ultrabug.github.io/mkdocs-static-i18n/setup/localizing-navigation/ and repo README (frozen status): https://github.com/ultrabug/mkdocs-static-i18n (HIGH — cross-checked across three official pages)
- Docusaurus — i18n introduction: https://docusaurus.io/docs/i18n/introduction and tutorial: https://docusaurus.io/docs/i18n/tutorial (MEDIUM-HIGH)
- Sphinx — Internationalization: https://www.sphinx-doc.org/en/master/usage/advanced/intl.html (MEDIUM)
- VitePress — i18n guide: https://vitepress.dev/guide/i18n (MEDIUM)
- Swagger UI — configuration.md @ master: https://raw.githubusercontent.com/swagger-api/swagger-ui/master/docs/usage/configuration.md (HIGH for the negative claim — verified twice by direct fetch)

Secondary (search-mediated, cross-checked where marked):
- pandoc `lang`/babel/polyglossia behavior — pandoc User's Guide https://pandoc.org/MANUAL.html + Eisvogel template + Quarto docs (MEDIUM, consistent across three)
- Hugo multilingual / `i18n/` catalogs — gohugo.io content-management/multilingual + theme docs snippets (LOW-MEDIUM — search-mediated; official page not directly fetched)
- mdbook-i18n-helpers (gettext ecosystem precedent) — https://github.com/google/mdbook-i18n-helpers via docs.rs/lib.rs references (MEDIUM)
- GitHub Wiki lacks native i18n — GitHub docs https://docs.github.com/ + webapps.stackexchange.com + 2025 community discussion (MEDIUM, cross-checked)
- DokuWiki `lang` config / translation plugin — dokuwiki.org (fetch blocked HTTP 402; search + background only) (LOW — flagged)
- BCP 47 / RFC 5646 case conventions — spec knowledge consistent with pandoc/Material/Docusaurus doc examples (MEDIUM for the invariant "case-insensitive, canonical `pt-BR`"; tool-specific casing variance observed in primary sources)
- i18n anti-patterns — W3C "Internationalization Best Practices for Spec Developers" (concatenation anti-pattern) + SimpleLocalize technical guide (detection is inference; explicit override) (MEDIUM, cross-checked)

---
*Feature research for: output-language support in docs-generation tooling (md-to-wiki OUTPUT_LANG milestone)*
*Researched: 2026-09-28*
