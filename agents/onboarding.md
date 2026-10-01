# Onboarding — Subagent

Interview the user to set every variable in [CONTEXT.md](../CONTEXT.md) (§Variables). Return only when all of them are confirmed.

## Interview

1. **PROJECT_NAME** — what is this project called?
2. **SOURCES** — the single root directory of the specs tree (typically `.specs/`; layout in CONTEXT.md §Source taxonomy). Confirm the directory exists on disk.
3. **AUDIENCE** — `developer` \| `stakeholder` \| `general` (canonical tokens; use one of these exactly):
   - developer — detailed code docs, API references
   - stakeholder — executive summaries, roadmaps, decisions
   - general — feature overviews, tutorials
4. **OUTPUT_LANG** — `en` \| `pt-br` (canonical tokens, lowercase; use one of these exactly):
   - en — English chrome, byte-identical to today's output
   - pt-br — Portuguese (Brazil) chrome
   Default: `pt-br` when the user has no preference.
5. **FORMAT** — which output format? Present the route table from SKILL.md.
6. **Deployment** — hosted or local-only?

## Resolve SKILL_DIR

```bash
SKILL_DIR=$(dirname "$(find ~/.config/opencode/skills/md-to-wiki "$PWD/.opencode/skills/md-to-wiki" "$PWD/.cursor/skills/md-to-wiki" -name SKILL.md 2>/dev/null | head -1)")
```

## Update check

If `$SKILL_DIR/.git` exists, the skill is a git clone — offer to run `scripts/update.sh`.

## Detect OS (assign once)

```bash
kernel="$(uname -s 2>/dev/null || true)"
case "$kernel" in
  MINGW*|MSYS*|CYGWIN*)  OS_TYPE="unix";    SCRIPT_EXT=".sh";  SCRIPT_RUNNER="" ;;                 # Git Bash runs .sh natively
  "")                    OS_TYPE="windows"; SCRIPT_EXT=".ps1"; SCRIPT_RUNNER="powershell -File" ;; # no uname → PowerShell host
  *)                     OS_TYPE="unix";    SCRIPT_EXT=".sh";  SCRIPT_RUNNER="" ;;                 # Linux, Darwin, BSD, …
esac
```

Unix is the default; Windows is the special case.

## Return criteria

Return to the orchestrator only when all of these hold — if one cannot be satisfied, say so and stop:

- Every variable in CONTEXT.md §Variables has a value (`FORMAT` included)
- The `SOURCES` directory exists on disk
- `SKILL_DIR` resolved non-empty

Return the variables by their CONTEXT.md names (`PROJECT_NAME`, `SOURCES`, `AUDIENCE`, `OUTPUT_LANG`, `FORMAT`, `OS_TYPE`, `SCRIPT_EXT`, `SCRIPT_RUNNER`, `SKILL_DIR`).
