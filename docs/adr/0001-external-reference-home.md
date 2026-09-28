# ADR 0001 — CONTEXT.md as the single external reference home

Date: 2026-09-28 · Status: accepted

## Context

The Stage-2 audit (`docs/audit-findings.md` §S2) found 12 shared meanings duplicated across SKILL.md and the eight agents, with four already drifted: `OS_TYPE` vs `OS_DETECTED`, the `dev` audience token rejected by `generate-index.sh`, `SKILL_DIR` re-derived with weaker logic in format-pdf, and the DokuWiki references placement contradicting itself between two files.

## Decision

Create `CONTEXT.md` at the repo root as the single external reference (non-invocable, no description) holding: the variable contract, the script-call convention, the source taxonomy (authority: `discover-sources.sh`), the dependency map, install scopes, and the cleanup policy. Agents reference it by name and stop restating meanings. Mechanisms stay where they run: OS assignment code lives only in `onboarding.md`; per-format check commands stay with their format agents.

## Consequences

- A meaning changes in one place; per-agent files carry only usages (commands, criteria).
- Dispatched agents read `$SKILL_DIR/CONTEXT.md` when a value is unclear — acceptable one-file hop.
- Variable hand-off is by dispatch prompt, never ambient environment.
