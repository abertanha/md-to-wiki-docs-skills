# References Appendix — Subagent

Enrich documentation with GitHub issue/PR references found in the specs. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

`OUTPUT_LANG` comes from the dispatch prompt, never from the environment — same mechanism as the
other format agents. An unknown or missing value stops the flow with the list of supported
languages (`en`, `pt-br`); there is no silent fallback.

This agent writes published prose too: the title of the generated references page, and the
authorial text around issue citations. It is not a `format-*.md` agent, so SC3 does not name it —
but it is the second (and last) site in this skill where an agent produces authorial prose that
ships in the language of `OUTPUT_LANG`. Leaving it out of the glossary would leave the door the
gate exists to close open in one file.

When `OUTPUT_LANG` is `pt-br`, all authorial prose this agent writes follows the glossary below.
This copy is inlined DELIBERATELY, not duplication to be pruned — a rule that lives only behind a
link has no force under generation pressure (this project's own prior research, Pitfall 4). Full
rule: [CONTEXT.md, section "Glossário anti-calque"](../CONTEXT.md).

<!-- no-calques:ignore-start -->

Denylist (anglicized verb → correct form): `deployar` → implantar/publicar; `printar` →
imprimir; `commitar` → registrar/confirmar; `pushear` → enviar; `linkar` → ligar/referenciar;
`buildar` → compilar/construir; `debugar` → depurar; `startar` → iniciar; `mergear` →
integrar/incorporar; `upar` → enviar/subir. Technical terms kept in full English, never
Portuguese-ized: `stack`, `roadmap`, `design`, `deploy`, `build`, `commit`, `push`, `branch`,
`merge`, `release`, `wiki`, `spec`, `pull request`. Banned LLM tics: `é importante notar`,
`em resumo`, `convém destacar`, `vale ressaltar`, `vale notar`, `em última análise`.

<!-- no-calques:ignore-end -->

## When to activate

When the user asks to include GitHub issue or pull-request references from the specs.

## Steps

### 1. Discover referenced issues

```bash
grep -rhoE '#[0-9]+' "$SOURCES" --include='*.md' | sort -u
```

Ignore matches inside inline code or code blocks (CSS hex colors like `#333` are not issue refs). Done when every `#N` in the tree has been considered and the kept list is final. If the list is empty, report zero references and stop — create no file.

### 2. Resolve the repository and fetch

Derive the target repository:

```bash
remote=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//; s#.*github.com[:/]##')
```

Ask the user when the remote yields nothing. Then cache and retrieve:

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/fetch-issues$SCRIPT_EXT" "$remote" <ISSUE_NUMBERS...>
```

The script caches JSON per number under `.specs/issues/cache/` and reports `AUTH_NEEDED` when credentials are missing — collect those for the output; fetch nothing further for them.

### 3. Format references

The TITLE of the generated references page comes from the catalog key `label_references` in
`$SKILL_DIR/templates/lang/$OUTPUT_LANG.lang`, loaded the same way
`agents/format-swagger.md:70` loads its own (`set -a; . "$SKILL_DIR/templates/lang/$OUTPUT_LANG.lang"; set +a`).

What is NOT chrome and therefore never translated: the file names in the placement table below
(`docs/references.md`, `swagger-ui/references.html`, `wiki/References.md`, `references.txt`) are
PATHS and stay identical in any language (CHROME-04); the issue state (`open`/`closed`) and the
comment author attribution are DATA coming from the GitHub API and pass through unchanged — never
translated, never case-transformed.

Include for each fetched issue:

| Element | Source |
|---------|--------|
| Title + number | cache JSON |
| State (open/closed) | cache JSON |
| Key comments | top 3 by total reactions (each comment's `reactionGroups`) |
| External links | URLs found in the issue body |

Placement by target format:

| Format | References location |
|--------|-------------------|
| MkDocs | `docs/references.md` |
| Swagger | `swagger-ui/references.html` |
| GitHub Wiki | `wiki/References.md` |
| DokuWiki | `references.txt` (top-level page) |
| PDF | `references` appendix chapter |

Rendering rules: truncated bodies get a `[...](<full issue URL>)` link; key comments render as blockquotes with attribution (`— @author`).

Done when every kept issue number appears in the output or in the failure list.

## Output

Return to the orchestrator:
- Path to generated references file(s)
- List of issues included
- Failures (`AUTH_NEEDED`, rate limits, private repos, missing issues)
