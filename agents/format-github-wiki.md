# GitHub Wiki Builder — Subagent

You are a specialized subagent for publishing markdown spec files as a GitHub Wiki.

## Prerequisites

```bash
git --version
```

## Steps

### 1. Discover sources

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/discover-sources$SCRIPT_EXT" <SOURCES>
$SCRIPT_RUNNER "$SKILL_DIR/scripts/discover-sources$SCRIPT_EXT" <SOURCES> json > sources.json
```

### 2. Clone wiki repo

```bash
# Replace <owner/repo> from context
gh repo clone <owner/repo> -- wiki 2>/dev/null
if [ ! -d wiki ]; then
  git clone "https://github.com/<owner>/<repo>.wiki.git" wiki 2>/dev/null
fi
```

If no GitHub repo is available, fall back to creating a `wiki/` directory manually.

### 3. Organize content

Structure the wiki directory:

```
wiki/
  Home.md              ← project overview, generated
  _Sidebar.md          ← navigational index, generated
  _Footer.md           ← optional
  Project/
    Overview.md
    Roadmap.md
    State.md
  Architecture/
    Overview.md        ← from ARCHITECTURE.md
    Stack.md           ← from STACK.md
    Conventions.md     ← from CONVENTIONS.md
  Features/
    <feature-name>.md  ← one page per feature (3 sections: spec/design/tasks)
  Quick-Tasks/
    <task-name>.md
  References.md        ← if provided
```

### 4. Convert to Wiki format

Convert Markdown links to MediaWiki-style `[[Page Name]]` links:

```bash
for f in $(find wiki -name '*.md'); do
  # Convert [text](path/file.md) → [[file|text]] for cross-pages
  # Convert [text](https://...) → [text](https://...) unchanged (external)
  sed -i \
    -e 's/\[\([^]]*\)\](\([^)]*\)\.md)/[[\2|\1]]/g' \
    -e 's/\[\([^]]*\)\](\([^)]*\)\/\([^)]*\))/[[\3|\1]]/g' \
    "$f"
done
```

### 5. Commit and push

```bash
cd wiki
git add -A
git commit -m "docs: auto-generate wiki from spec files"
git push origin HEAD 2>/dev/null
```

## Output

Return to the orchestrator:
- Path to `wiki/` directory
- URL to live wiki (if pushed)
- Any warnings (broken links, push failures)
