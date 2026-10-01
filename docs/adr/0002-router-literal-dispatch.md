# ADR 0002 — Router: tightened patterns, executed literally

Date: 2026-09-28 · Status: accepted

## Context

Spot-run SR-1 confirmed a fresh agent applies the bash `case` block literally (it executed it verbatim): `*"pr"*` routed "generate docs for my **project**" to `references`; "build a **wiki**" hit the fallback; 5 of 10 advertised triggers in SKILL.md pointed at a branch that never existed (diagrams).

## Decision

1. Keep routing in the bash `case` block — determinism lives in the patterns, which the agent executes faithfully.
2. Tighten patterns to distinctive phrases (`*"pull request"*` instead of `*"pr"*`); order arms so specific wiki formats precede the generic `*"wiki"*|*"site"*` → mkdocs arm.
3. Instruct execution explicitly ("execute this block with the user's request as `$1`") — the old prose ("analyze… to determine") licensed loose simulation.
4. Align advertised triggers with actual arms; delete the phantom diagram triggers (unimplemented — see README "Hard Rules", still aspirational).

Extracting `scripts/route.sh` was considered and deferred: with patterns fixed and execution instructed, a separate script buys no additional predictability (MET-1).

## Consequences

Route changes are one-block edits in SKILL.md; every trigger phrase in the description must match an arm (INV-2 discipline).
