# Skill Quality Rubric

The audit instrument for aligning `md-to-wiki` with the skill-quality patterns demonstrated by `gsd-core`.

- **Source of theory:** `writing-great-skills` (mattpocock-skills plugin, v1.2.0) — its `SKILL.md` and `GLOSSARY.md` are the canonical definitions. Where this rubric and that skill disagree, the skill wins.
- **Source of exemplars:** `gsd-core` v1.15.0 (installed at `~/.claude/plugins/cache/gsd-core/gsd-core/1.15.0/`) — used as a *corpus of comparison*, not as authority. A GSD pattern is adopted only when it passes the Predictability gate (MET-1); copying structure for aesthetics is future sediment.

The root virtue is **Predictability** — the agent following the same *process* every run, not producing the same output. Every dimension below is a lever on it, directly or by curing a failure mode.

---

## Scope boundary — context-rot orchestration is a non-goal

GSD's anti-context-rot machinery (phase loops, milestone archives, parallel executor waves, context monitors) solves a problem md-to-wiki does not have: multi-hour, multi-phase development sessions. md-to-wiki already implements the lightweight form of the same principle — thin router, per-format disclosure, deterministic scripts doing the heavy I/O. Therefore:

- No GSD orchestration mechanism is adopted by default. Adoption requires demonstrating an actual rot case in a real md-to-wiki run (e.g. a large repo whose source scan dumps file contents into the main context).
- Where a case is demonstrated, prefer the STE-6 remedy first (move the work into a script); reach for fresh-context subagent dispatch only when the work genuinely requires judgment.

---

## How to audit (protocol)

1. **Unit of audit:** one file at a time — `SKILL.md`, each `agents/*.md`, plus any shared reference the skills point at. Scripts (`scripts/*.sh|ps1`) are audited only as *targets of pointers* (are they reached with well-worded pointers?), not as prose.
2. **Verdicts, not scores.** Each dimension gets exactly one verdict per file:
   - ✅ **Pass** — evidence present
   - ⚠️ **Partial** — present but weak (say which property fails)
   - ❌ **Fail** — failure mode present; cite the evidence
   - **N/A** — dimension cannot apply (e.g. description checks on a user-invoked file)
3. **Evidence is mandatory.** Every ⚠️/❌ carries a `file:line` citation. A finding without evidence is a hypothesis, not a finding.
4. **Model-relative verdicts.** No-op (PRU-2) and pointer-reliability (INV-4) verdicts are about model behavior, not reader opinion. Mark them **PLAUSIBLE** when read-only analysis suggests them, and **CONFIRMED** only after a spot-run of the skill reproduces the issue. Never settle them by debate.
5. **Record format (long-form, findings only):**

   ```
   | File | Dim | Verdict | Evidence (file:line) | Opportunity |
   ```

   Plus a rollup: one line per axis per file (`INV 3✅ 1⚠️ 1❌`).

---

## Axis INV — Invocation (how the skill is reached)

| ID | Question | Failure detected | GSD exemplar |
|----|----------|------------------|--------------|
| INV-1 | Is the invocation choice justified? Model-invoked (description kept) only when the agent — or another skill — must reach it alone; otherwise user-invoked (zero context load). | Mis-paid load: context load for a hand-fired skill, or cognitive load for an autonomous one. | `skills/gsd-fast` keeps a description + `argument-hint` because it must fire from other flows. |
| INV-2 | Does the description (model-invoked only) state what the skill is, then list branches with trigger phrasing — one trigger per branch, front-loaded leading word, no synonym re-listing? | Duplication inside the description; context load spent on identity that belongs in the body. | `skills/gsd-*/SKILL.md` descriptions follow "state + triggers" shape. |
| INV-3 | Router discipline: does the router name each reachable skill and the condition for reaching it — and only hint, never pretend to fire the unreachable? | Cognitive load without index value; router rows that restate what agents already say. | This repo's `SKILL.md` phase router is itself the object under audit; GSD's router layer is `commands/` + `skills/` naming. |
| INV-4 | Context-pointer wording: does every pointer (description, agent links, `@`-includes) encode *when* to reach its target, in words the agent will reliably match? A must-have target behind a weakly worded pointer is a variance bug — fix wording before inlining. | Pointer that fires unreliably → nondeterministic routing. | `gsd-fast`'s `<execution_context>` `@`-include is a one-line pointer with a named target. |
| INV-5 | Harness levers used where they add determinism: `allowed-tools` scoping, `argument-hint`, `disable-model-invocation` — present when they bind behavior, absent when decorative? | Unused lever (missed determinism) or decorative lever (no-op in frontmatter). | `skills/gsd-fast` frontmatter: `allowed-tools` pinned to the five tools it needs. |

## Axis HIE — Information Hierarchy (where content sits)

| ID | Question | Failure detected | GSD exemplar |
|----|----------|------------------|--------------|
| HIE-1 | Are ordered **steps** (when they exist) in-file, and does each end on a completion criterion? | Steps buried behind pointers; or criterion-less steps. | `gsd-fast` `<process>` is one step with its bound stated in `<objective>`. |
| HIE-2 | Rung placement: is material every branch needs inlined, and material only some branches need disclosed behind a pointer? (The branching test.) | Branch-only content inlining → attention tax on all runs; universal content disclosed → must-have behind a weak pointer. | Format-specific detail lives in per-format `agents/format-*.md` (this repo already does this — audit whether the split is complete). |
| HIE-3 | Progressive disclosure mechanics: disclosed files named for what they hold, reached only when the pointer fires? | Files named by convention the agent can't infer content from. | GSD `docs/` filenames are content-named (`TESTING-STANDARDS.md`, `contributor-standards.md`). |
| HIE-4 | Co-location: does a concept's definition, rules, and caveats sit under one heading, not scattered? | Scattering — one meaning fragmented across sites (distinct from duplication: that *repeats* one meaning). | `CONTEXT.md` glossary: one `###` per Module, definition + boundaries together. |
| HIE-5 | External reference: does material needed by *several* skills live in one external home (no description, not invocable, any skill can point at it)? This is where shared vocabulary and decisions belong. | Shared meaning duplicated per-skill instead of externalized; two user-invoked skills trying to share without an external home. | GSD `CONTEXT.md` (vocabulary) + `docs/adr/` (decisions) — the layer this repo lacks. |
| HIE-6 | Sprawl: is SKILL.md simply too long, even if every line is live and unique? Proxy checks: line count, and distance from top to first action the agent takes. | Length itself — wading cost, thinning attention, maintenance. | `gsd-fast` SKILL.md is ~30 lines; heavy content moved to `workflows/` behind `@`-includes. |

## Axis STE — Steering (shaping runtime behavior)

| ID | Question | Failure detected | GSD exemplar |
|----|----------|------------------|--------------|
| STE-1 | Completion criteria: is each step's bound **checkable** (agent can tell done from not-done) and, where it matters, **exhaustive** ("every source file accounted for", not "produce a list")? Flat reference needs its own bar ("every rule applied"). | Premature completion; thin legwork. | `docs/contributor-standards.md` phrasing "part of the merge contract, not optional background reading" — a demand bar on reference. |
| STE-2 | Leading words: are compact pretrained concepts anchoring behavior (repeated as tokens, never as sentences)? Are restatements that could collapse into one word left uncollapsed? | Triads spelled out at three sites (duplication paying tokens for what a prior gives free); weak words that fail the no-op test. | GSD repeats *phase*, *milestone*, *fresh context* as anchors throughout. |
| STE-3 | Legwork demand: does the wording demand thorough within-step work, or permit offloading to the user / shallow coverage? | Thin legwork under a missing demand. | GSD executors run with explicit checklists per wave. |
| STE-4 | Branch enumeration: is every distinct way to invoke recognized, with an explicit fallback for the unrecognized? (A literal dispatch table — like this repo's bash router — is the strongest form: deterministic code beats prose routing.) | Silent fallthrough; default branch that swallows cases another branch should own. | `SKILL.md` bash `case` router with explicit `*) ROUTE="onboarding"` fallback — audit its case coverage, not its existence. |
| STE-5 | Negation: are prohibitions paired with (or replaced by) the positive target behavior? Count `don't|never|avoid|do not` per file; each occurrence must be a hard guardrail that can't be phrased positively. | Elephant-naming — the ban half-reads as an instruction. | Audit target, not exemplar: GSD's lint rules are named as prohibitions (`no-swallowed-precondition`) but *code*, where prohibition is exact — prose is where negation bites. |
| STE-6 | Determinism substitution: wherever prose instructs what code could decide (validation, routing, ordering), is code doing it? Prose survives only where judgment is genuinely needed. | Stochastic dispatch where a predicate exists. | GSD pushes checks into `eslint-rules/*.cjs` and `scripts/` — prose states policy, code enforces. |

## Axis PRU — Pruning (keeping lean)

| ID | Question | Failure detected | GSD exemplar |
|----|----------|------------------|--------------|
| PRU-1 | Duplication: does any meaning have more than one home? Check synonym clusters across SKILL.md ↔ agents ↔ scripts headers — same meaning restated, not scattered fragments. | Maintenance hazard (change one, miss the other); inflated prominence. | `docs/contributor-standards.md`: "Do not add synonyms; pick one name and use it everywhere." |
| PRU-2 | No-ops: sentence-by-sentence, does the line change behavior versus the model's default? Weak leading words that don't beat the default count. | Paying load to say nothing. | No exemplar needed — the test is the dimension. Verdicts PLAUSIBLE by reading, CONFIRMED by spot-run only. |
| PRU-3 | Relevance/sediment: does every line still bear on what the skill does? Check for stale mentions (renamed files, removed features like the deleted `prompt-tests.sh`, version drift). | Stale layers settled because adding felt safe. | GSD `CHANGELOG.md` + `docs/INVENTORY.md` keep the corpus auditable against drift. |
| PRU-4 | Single source of truth: does each meaning — including variables like `SKILL_DIR`, `SCRIPT_RUNNER` — have exactly one authoritative definition others reference? | Definition drift between definition sites. | `CONTEXT.md` as maintainer-owned single home for vocabulary. |

## Axis MET — Meta (the gate)

| ID | Question | Failure detected |
|----|----------|------------------|
| MET-1 | **Predictability gate.** For every proposed change from the Stage-2 findings: does it make the agent follow the same *process* more reliably? A change that only adds structure, ceremony, or GSD-look-alike without a predictability gain is rejected — it is future sediment. Applied last, to the opportunity list, not to files. | Cosmetic alignment; structure for aesthetics. |

---

## Audit integrity and economy

The audit must itself pass the standards it enforces.

**Integrity — fresh-context auditors.** Every file audit is performed by a subagent that receives only this rubric and the target file (plus the read-only canonical paths above). Conclusions formed in conversation by the orchestrator are inadmissible as evidence. The orchestrator consolidates verdicts but cannot raise or lower one without citation-level evidence; a contested dimension goes to a second, independent fresh audit. Skill-output spot-runs are evaluated **blind**: the evaluating agent receives the skill's *stated completion criterion* plus the run transcript/output — never the skill's prose or the author's intent — and judges done vs not-done against observable behavior. Residual bias the protocol cannot remove: this rubric itself was authored in conversation; mitigated by the rule that the canonical `writing-great-skills` sources override it on conflict, and that auditors are pointed at those sources directly.

**Economy — price every call.**
- One auditor per file; nobody loads the whole corpus. Consolidation receives verdicts and findings, never file dumps.
- Spot-runs (PRU-2, INV-4 confirmations) are batched and run only where the Stage-3 action they gate is expensive or hard to reverse; a cheap deletion ships on a PLAUSIBLE verdict.
- Every Stage-3 *addition* to SKILL.md or to a description is priced as permanent per-run cost (INV-1/INV-2 applied to ourselves): if it doesn't buy predictability, it doesn't ship.
- Model tiering is optional and secondary: mechanical dimensions (frontmatter presence, negation counts, line counts) may go to a cheaper model; judgment dimensions (STE-1, STE-2, PRU-2) stay on the stronger model. The primary economy is load discipline, not model shopping.

---

## Stage-2 scope (fixed by this rubric)

Files in audit scope, in order — each audited by one fresh-context subagent (rubric + file only):

1. `SKILL.md` (router — all 22 dimensions apply)
2. `agents/onboarding.md` (sets global variables — PRU-4 critical)
3. `agents/format-*.md` ×5 (branch payloads — HIE-2, STE-1 critical)
4. `agents/references.md`, `agents/deploy.md`
5. Shared-reference check: what *should* be external (HIE-5) but is currently per-file

Consolidation order: collect long-form findings → rollup per axis → batch the spot-run list (only verdicts gating expensive Stage-3 actions) → apply MET-1 to the opportunity list.

Dimension count: INV 5 · HIE 6 · STE 6 · PRU 4 · MET 1 = **22**.
