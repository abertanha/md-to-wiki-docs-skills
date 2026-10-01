---
phase: "04"
slug: "04-g-meos-powershell-prosa-release"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-01"
---

# Phase 04 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller → script | Project name, specs-dir path, output_lang passed as positional args | Strings; sanitized before use |
| Script → file system | `.specs/` tree read; output dirs written | Local files; paths validated via Resolve-Path / realpath |
| Script → external tools | pandoc, weasyprint, wkhtmltopdf, pwsh invoked by path | Controlled args only; no shell string interpolation |
| `.specs/config.json` → script | `repo_url` field consumed by generate-mkdocs | Newlines stripped before YAML interpolation (T-RETRO-02) |
| `templates/lang/*.lang` → script | Catalog KEY=value loaded via bash source / PS parser | Parser is literal-only; Invoke-Expression and ConvertFrom-StringData banned (T-04-02) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-04-01 | Tampering | OUTPUT_LANG allowlist | high | mitigate | `Resolve-OutputLang` runs before any catalog path is built; allowlist `case` block in `.sh` twins; `allowlist_before_path` gate in ps1-contract.sh | closed |
| T-04-02 | Tampering | catalog.ps1 parser | medium | mitigate | Literal-only parser (no `Invoke-Expression`, no `ConvertFrom-StringData`); `banned_cmdlets` gate in ps1-contract.sh | closed |
| T-04-03 | Information Disclosure | generate-index.ps1 path derivation | medium | mitigate | `Resolve-Path -Relative` + cwd-prefix stripping replaces `Split-Path -NoQualifier`; no absolute host path in generated index.md | closed |
| T-04-04 | Tampering | format-github-wiki.md find loop | medium | mitigate | `find -print0 \| while IFS= read -r -d ''` null-delimited; verified by wiki-links.sh | closed |
| T-04-05 | Tampering | to-pdf.ps1 pandoc args | low | accept | `@PandocLangOpts` splat never string-concatenated; array elements passed directly | closed |
| T-04-06 | Denial of Service | catalog.ps1 unclosed quote | low | mitigate | Unclosed-quote value discarded; `Assert-CatalogKey` halts naming the key | closed |
| T-04-07 | Tampering | format-github-wiki.md sed | low | accept | sed expressions are static regex literals; no catalog variable interpolated | closed |
| T-04-08 | Information Disclosure | generate-mkdocs repo_url | low | accept | git remote URL included intentionally; golden capture uses `mktemp -d` outside any repo (fixture shows empty repo_url) | closed |
| T-04-09 | Tampering | golden-sh fixtures | medium | mitigate | `git diff --quiet HEAD -- tests/fixtures/golden-sh/` wired as automated verify step; capture mode is sole writer | closed |
| T-04-10 | Denial of Service | test harness exit codes | medium | mitigate | Harnesses exit 3 (SKIP) when pwsh absent — distinct from 0/1; verified live | closed |
| T-04-11 | Repudiation | SKILL.md positional signature | medium | mitigate | SKILL.md positional-signature table matches Usage: lines of all 4 .ps1/.sh twins | closed |
| T-04-SC | Tampering | pwsh installation (supply-chain) | high | mitigate | `gate="blocking-human"` checkpoint required human to run `sudo snap install powershell --classic`; confirmed in SUMMARY | closed |
| T-RETRO-01 | Denial of Service / Repudiation | to-pdf.ps1, to-dokuwiki.ps1 | high | mitigate | `$LASTEXITCODE -ne 0` checked after every pandoc invocation (weasyprint branch, wkhtmltopdf branch, per-file DokuWiki); `exit 1` before any success message — mirrors `.sh` twins' `set -euo pipefail` | closed |
| T-RETRO-02 | Tampering (YAML injection) | generate-mkdocs.ps1, generate-mkdocs.sh | high | mitigate | `$ProjectName` / `$repoUrl` have CR/LF stripped before YAML heredoc (`-replace '[\r\n]'` in PS; `tr -d '\r\n'` in bash); sanitization confirmed BEFORE the `cat > mkdocs.yml` / `$content = @"..."` interpolation | closed |

*Status: open · closed · open — below block_on threshold (non-blocking)*
*Severity: critical > high > medium > low*
*Disposition: mitigate (implementation verified) · accept (documented risk)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-04-05 | `@PandocLangOpts` splat passes args as PS array elements — never string-concatenated; no injection path | abertanha | 2026-10-01 |
| AR-02 | T-04-07 | sed expressions in format-github-wiki.md are static regex literals hardcoded in the agent file; no user data reaches them | abertanha | 2026-10-01 |
| AR-03 | T-04-08 | `repo_url` in mkdocs.yml is the project's own public remote URL — intentional, single-author, captured outside any repo in the golden fixture | abertanha | 2026-10-01 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-01 | 12 (T-04-01..T-04-SC) | 9 mitigated + 3 accepted | 0 (prior register) | gsd-security-auditor (retroactive-STRIDE) |
| 2026-10-01 | +2 (T-RETRO-01, T-RETRO-02) found during retroactive scan | 0 initially | 2 open (HIGH) | gsd-security-auditor |
| 2026-10-01 | 14 total | 14 closed | 0 | gsd-security-auditor (re-verification after fixes) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-01
