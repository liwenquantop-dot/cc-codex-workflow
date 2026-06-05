#!/usr/bin/env bash
# PreToolUse hook — block direct Edit/Write/NotebookEdit on source files when AUTO mode.
# Forces source edits through /codex:rescue.
#
# Exit codes per Claude Code hook protocol:
#   0  -> allow (stdout shown to user, transcript-only by default)
#   2  -> block (stderr shown to model, tool call cancelled)
#   other -> non-blocking error
set -u

CONFIG="$HOME/.claude/codex-workflow.json"
MODE="manual"

# Read mode (default manual if config missing or unreadable).
if [[ -f "$CONFIG" ]]; then
  VAL=$(python3 -c "import json,sys
try:
  print(json.load(open('$CONFIG')).get('mode','manual'))
except Exception:
  print('manual')" 2>/dev/null)
  [[ -n "${VAL:-}" ]] && MODE="$VAL"
fi

# In manual mode this hook does nothing — user already opts in via /ccf:workflow.
if [[ "$MODE" != "auto" ]]; then
  exit 0
fi

# Parse stdin JSON (Claude Code sends the full hook event).
PAYLOAD=$(cat)

# Extract tool_name and file_path. Use python for safe JSON parsing.
read -r TOOL FPATH <<<"$(python3 - "$PAYLOAD" <<'PY'
import json, sys
try:
    ev = json.loads(sys.argv[1])
except Exception:
    print("UNKNOWN ")
    sys.exit(0)
tool = ev.get("tool_name", "")
ti = ev.get("tool_input", {}) or {}
fp = ti.get("file_path") or ti.get("notebook_path") or ""
print(f"{tool} {fp}")
PY
)"

# Only guard the three file-mutating tools.
case "$TOOL" in
  Edit|Write|NotebookEdit) ;;
  *) exit 0 ;;
esac

# No path → can't decide, let it through.
[[ -z "${FPATH:-}" ]] && exit 0

# Normalize basename and extension.
BASENAME="${FPATH##*/}"
EXT="${BASENAME##*.}"
# Lowercase the extension for the case match.
EXT_LC=$(printf '%s' "$EXT" | tr '[:upper:]' '[:lower:]')

# --- Exemptions: these paths are always allowed even in AUTO mode ---

# Plugin/config/docs directories.
case "$FPATH" in
  */.claude/*|*/.claude-plugin/*|*/.codex/*|*/.github/*) exit 0 ;;
  */docs/*|*/doc/*) exit 0 ;;
  *CLAUDE.md|*AGENTS.md|*README*|*CHANGELOG*|*LICENSE*|*CONTRIBUTING*) exit 0 ;;
esac

# Doc / config / data extensions — never source.
case "$EXT_LC" in
  md|mdx|markdown|txt|rst|adoc) exit 0 ;;
  json|yaml|yml|toml|ini|cfg|conf|env|lock) exit 0 ;;
  csv|tsv|xml|html|htm) exit 0 ;;
  png|jpg|jpeg|gif|svg|ico|pdf) exit 0 ;;
  gitignore|gitattributes|editorconfig|nvmrc|prettierrc|eslintrc) exit 0 ;;
esac

# --- Source extensions: BLOCK ---
case "$EXT_LC" in
  py|js|jsx|ts|tsx|mjs|cjs|\
  go|rs|java|kt|kts|scala|groovy|\
  swift|m|mm|c|h|cc|cpp|cxx|hpp|hh|\
  cs|fs|vb|\
  rb|php|pl|pm|lua|dart|\
  sh|bash|zsh|fish|\
  vue|svelte|astro|\
  sql|graphql|gql|proto|\
  ex|exs|erl|hrl|clj|cljs|hs|ml|mli|nim|zig|\
  ipynb)
    cat >&2 <<EOF
BLOCKED by ccf workflow guard (mode: AUTO).

Tool: $TOOL
Target: $FPATH

Direct edit of source files is disabled in AUTO mode. Delegate to Codex:

  /codex:rescue --write <your task description, citing $FPATH and line numbers>

Exceptions (re-attempt allowed only if true):
  - User explicitly said "direct edit" / "改这一行" / "直接改" in this turn.
  - Truly single-line typo/import/constant fix with zero call-site impact.

To disable guard for this session: /ccf:toggle-mode  (switches to MANUAL).
EOF
    exit 2
    ;;
esac

# Unknown extension — let it through (don't block ad-hoc files like Makefile, Dockerfile, etc.)
exit 0
