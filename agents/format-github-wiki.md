# GitHub Wiki Builder — Subagent

Publish a markdown specs tree as a GitHub Wiki. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

## Prerequisites

```bash
git --version && gh --version
```

If any variable from CONTEXT.md is unset, ask the orchestrator before running.

`OUTPUT_LANG` comes from the dispatch prompt, never from the environment — same mechanism as the
other format agents. An unknown or missing value stops the flow with the list of supported
languages (`en`, `pt-br`); there is no silent fallback.

When `OUTPUT_LANG` is `pt-br`, all authorial prose of `Home.md` and `_Sidebar.md` follows the
glossary below. This copy is inlined DELIBERATELY, not duplication to be pruned — a rule that
lives only behind a link has no force under generation pressure (this project's own prior
research, Pitfall 4). Full rule: [CONTEXT.md, section "Glossário anti-calque"](../CONTEXT.md).

<!-- no-calques:ignore-start -->

Denylist (anglicized verb → correct form): `deployar` → implantar/publicar; `printar` →
imprimir; `commitar` → registrar/confirmar; `pushear` → enviar; `linkar` → ligar/referenciar;
`buildar` → compilar/construir; `debugar` → depurar; `startar` → iniciar; `mergear` →
integrar/incorporar; `upar` → enviar/subir. Technical terms kept in full English, never
Portuguese-ized: `stack`, `roadmap`, `design`, `deploy`, `build`, `commit`, `push`, `branch`,
`merge`, `release`, `wiki`, `spec`, `pull request`. Banned LLM tics: `é importante notar`,
`em resumo`, `convém destacar`, `vale ressaltar`, `vale notar`, `em última análise`.

<!-- no-calques:ignore-end -->

The rest of this agent's own runbook prose stays in English — it is instruction prose for the
model, not published output, and translating it is not this phase's goal.

## Steps

### 1. Discover sources

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/discover-sources$SCRIPT_EXT" "$SOURCES"
```

Done when the summary accounts for every markdown file under `$SOURCES`.

### 2. Resolve the wiki repo

Derive `<owner>/<repo>` from the project remote:

```bash
remote=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//; s#.*github.com[:/]##')
```

If the remote yields nothing, ask the user. Then:

```bash
gh repo clone "$remote" -- wiki 2>/dev/null \
  || git clone "https://github.com/${remote}.wiki.git" wiki 2>/dev/null \
  || mkdir -p wiki   # offline fallback: build locally for later push
```

Done when `wiki/` exists and its origin (when cloned) points at the wiki remote.

### 3. Organize content

Place files from `$SOURCES` into the wiki tree by the CONTEXT.md taxonomy:

```
wiki/
  Home.md              ← project overview, with [[Page]] links to the sections
  _Sidebar.md          ← navigational index
  _Footer.md           ← optional
  Project/             ← from project/*.md
  Architecture/        ← from codebase/*.md
  Features/            ← one page per feature dir (spec/design/tasks sections)
  Quick-Tasks/         ← one page per quick-task dir
```

Write `Home.md` and `_Sidebar.md` yourself — overview text is judgment work; link the sections with `[[Page]]` links. Done when every discovered file from step 1 has a page in the tree.

The authorial chrome of `Home.md` and `_Sidebar.md` — headings and section labels — is written in
the language of `$OUTPUT_LANG`. The canonical section nouns come from the catalog at
`$SKILL_DIR/templates/lang/$OUTPUT_LANG.lang`; use these keys: `label_project_overview`,
`label_architecture`, `section_features`, `section_overview`, `section_getting_started`, and
`label_contributing`.

Page names (`Home.md`, `_Sidebar.md`, `_Footer.md`), directory names (`Project/`,
`Architecture/`, `Features/`, `Quick-Tasks/`), and `[[Page]]` link targets are PATHS and are NEVER
translated, in any language (CHROME-04) — translating them would break the link resolution in
step 5.

### 4. Convert links

Convert relative markdown links to MediaWiki `[[Page|text]]` links — external URLs stay untouched (the patterns require a colon-free relative target, so `http(s)://` never matches). The visible link text the spec author wrote is preserved by both expressions:

```bash
find wiki -name '*.md' -print0 | while IFS= read -r -d '' f; do
  sed -i -E \
    -e 's@\[([^]]*)\]\(([^):]+)\.md\)@[[\1|\2]]@g' \
    -e 's@\[([^]]*)\]\(([^):]+/[^)/:]+)\)@[[\1|\2]]@g' \
    "$f"
done
```

### 5. Verify links

```bash
grep -rhoE '\[\[[^]|]+' wiki --include='*.md' | sed 's/^\[\[//' | sort -u
```

Every `[[target]]` must resolve to a page in the tree (by name or path). Fix the page name or report the broken target. Done when the broken-targets list is empty or fully reported.

### 6. Commit and push

```bash
cd wiki
git add -A
git commit -m "docs: auto-generate wiki from spec files"
git push origin HEAD
```

Done when push exits 0. On failure, capture stderr and report it — a push that failed is reported as failed, never as done.

## Output

Return to the orchestrator:
- Path to `wiki/` directory
- URL to live wiki (when pushed; else "not pushed" + reason)
- Broken links remaining (empty list when clean)
- Push stderr on failure
