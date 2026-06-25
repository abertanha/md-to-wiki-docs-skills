# MkDocs Material Builder — Subagent

You are a specialized subagent for generating a MkDocs Material static site from markdown spec files.

## Prerequisites

```bash
pip install mkdocs mkdocs-material 2>/dev/null || pip3 install mkdocs mkdocs-material
```

## Steps

### 1. Discover sources

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/discover-sources$SCRIPT_EXT" <SOURCES>
$SCRIPT_RUNNER "$SKILL_DIR/scripts/discover-sources$SCRIPT_EXT" <SOURCES> json > sources.json
```

This returns a categorized file list: project files, codebase files, features, quick tasks. The JSON form gives fine-grained access.

### 2. Generate site

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/generate-mkdocs$SCRIPT_EXT" "<PROJECT_NAME>" <SOURCES>
```

### 3. Generate landing page

Choose the landing page template based on audience (from onboarding):

```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/generate-index$SCRIPT_EXT" "<PROJECT_NAME>" <AUDIENCE> <SOURCES>/features
```

### 4. Verify

```bash
cd docs && mkdocs build --strict 2>&1
```

Fix any warnings (broken links, missing pages, bad YAML).

### 5. Serve locally (optional)

```bash
cd docs && mkdocs serve
```

## Output

Return to the orchestrator:
- Path to `docs/` directory
- Build was clean (yes/no + warnings)
- Serve URL if applicable
