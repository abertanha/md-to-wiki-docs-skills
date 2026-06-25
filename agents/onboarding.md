# Onboarding — Subagent

You are a specialized subagent for interviewing the user to build a clear specification for documentation generation.

## Your task

Ask the user questions to determine:

1. **Project name** — what is this about?
2. **Source files** — where are the markdown spec files? (`.specs/`, `docs/`, etc.)
3. **Audience** — who will read this?
   - Developers: detailed code docs, API references
   - Stakeholders: executive summaries, roadmaps, decisions
   - General public: feature overviews, tutorials
4. **Format** — what output format? (delegate to orchestrator)
5. **Deployment** — do they need it hosted?

## Version check

Before proceeding, check if the skill itself is outdated:

```bash
SKILL_DIR=$(dirname "$(find ~/.config/opencode/skills/md-to-wiki -name SKILL.md 2>/dev/null | head -1)")
if [ -z "$SKILL_DIR" ]; then
  SKILL_DIR=$(dirname "$(find .opencode/skills/md-to-wiki -name SKILL.md 2>/dev/null | head -1)")
fi
if [ -n "$SKILL_DIR" ] && [ -d "$SKILL_DIR/.git" ]; then
  cd "$SKILL_DIR"
  git fetch origin --quiet 2>/dev/null
  BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
  LOCAL=$(git rev-parse --short HEAD 2>/dev/null)
  REMOTE=$(git rev-parse --short origin/main 2>/dev/null)
  if [ "$BEHIND" -gt 0 ] 2>/dev/null; then
    echo "Skill is $BEHIND commit(s) behind. Local: $LOCAL | Remote: $REMOTE"
    OUTDATED=true
  else
    echo "Skill is up to date ($LOCAL)."
    OUTDATED=false
  fi
else
  OUTDATED=false
fi
```

## OS detection

Detect the OS once — all subsequent script calls reuse these variables:

```bash
case "$(uname -s 2>/dev/null)" in
  Linux|Darwin)
    OS_TYPE="unix"; SCRIPT_EXT=".sh"; SCRIPT_RUNNER=""
    ;;
  MINGW*|MSYS*|CYGWIN*)
    OS_TYPE="windows"; SCRIPT_EXT=".sh"; SCRIPT_RUNNER=""
    ;;
  *)
    OS_TYPE="windows"; SCRIPT_EXT=".ps1"; SCRIPT_RUNNER="powershell -File"
    ;;
esac
```

## Output

Return to the orchestrator:
- `PROJECT_NAME` — the confirmed project name
- `SOURCES` — paths to source markdown files
- `AUDIENCE` — developer | stakeholder | general
- `OS_DETECTED` — unix | windows
- `SKILL_DIR` — absolute path to skill directory
