# ADR 0003 — MkDocs chain: root config, copied specs, subshell-free nav

Date: 2026-09-28 · Status: accepted

## Context

Spot-run SR-3 (fixture on a canonical tree) exposed three stacked defects in the MkDocs route: (a) `nav_entries` accumulated inside `find | while read` pipe subshells — the generated nav was empty; (b) nav/index links referenced `.specs/…` outside any `docs_dir`, and `docs/mkdocs.yml` + `cd docs && mkdocs build` resolved the default `docs_dir` to `docs/docs/`; (c) nothing copied the specs into the site, so `index.md` and nav targets pointed at files mkdocs could not see.

## Decision

1. `generate-mkdocs.sh` copies the specs tree to `docs/specs/` and writes `mkdocs.yml` at the project root with explicit `docs_dir: docs` / `site_dir: site`.
2. Nav is built with a `for` loop over globbed dirs and `while … <<< "$files"` — no pipe subshells; files are discovered recursively (features and quick tasks now appear).
3. `generate-index.sh` emits links relative to the docs dir and checks `docs/specs/…` for the architecture section.
4. Build and serve run from the project root (`mkdocs build --strict`, no `cd docs`).

## Consequences

The route's completion criteria (`mkdocs build --strict` exits 0) became achievable. Issues-cache JSON files ride along as static files — harmless. `mkdocs build` itself was not exercised here (mkdocs not installed on the auditing host); config-level verification passed — first real run should confirm end-to-end.
