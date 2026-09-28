# ADR 0004 — PDF build: the companion script is the enforcing home

Date: 2026-09-28 · Status: accepted

## Context

The PDF build meaning lived in three enforcing homes that drifted (audit D6): prose engines (weasyprint → wkhtmltopdf), `to-pdf.sh` (xelatex → pdflatex → wkhtmltopdf → markdown copy, no `--toc`, deletes the book), `to-pdf.ps1` (weasyprint → wkhtmltopdf, `--toc`, silently skips missing files). format-pdf.md also re-derived `SKILL_DIR` with weaker logic and dereferenced an undefined `$env:SKILL_DIR` on Windows.

## Decision

1. The script is the primary path, called via the corpus convention (`$SCRIPT_RUNNER "$SKILL_DIR/scripts/to-pdf$SCRIPT_EXT" …`); the manual procedure is the explicit fallback and mirrors script behavior.
2. `to-pdf.sh` harmonized with `.ps1`: weasyprint first, `--toc --toc-depth=3`, retains `specs-book.md` (deletion follows the CONTEXT.md cleanup policy instead of a contradicting unconditional `rm`).
3. `to-pdf.ps1` now warns on missing files instead of skipping silently.
4. Prose keeps what the script lacks: the input ordering policy (project → codebase → features spec/design/tasks → quick).
5. The re-derived `SKILL_DIR` and the `$env:SKILL_DIR` pointer are gone.

## Consequences

One artifact shape per run regardless of platform path taken; engine drift is closed at the single enforcing home.
