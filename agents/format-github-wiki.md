# GitHub Wiki Builder — Subagent

Publish a markdown specs tree as a GitHub Wiki. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

## Prerequisites

```bash
git --version && gh --version
```

If any variable from CONTEXT.md is unset, ask the orchestrator before running.

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

### 4. Convert links

Convert relative markdown links to MediaWiki `[[Page|text]]` links — external URLs stay untouched (the patterns require a colon-free relative target, so `http(s)://` never matches):

```bash
for f in $(find wiki -name '*.md'); do
  sed -i -E \
    -e 's@\[\([^]]*\)\]\(([^):]+)\.md\)@[[\1|\2]]@g' \
    -e 's@\[\([^]]*\)\]\(([^):]+)/([^)/:]+)\)@[[\3|\2]]@g' \
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
