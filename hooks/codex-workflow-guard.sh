#!/usr/bin/env bash
# PreToolUse hook — soft reminder for direct Edit/Write/NotebookEdit on source files in CC-Codex mode.
# Never blocks. Emits stderr advice so Claude self-corrects toward /codex:rescue when warranted.
#
# Exit codes per Claude Code hook protocol:
#   0  -> allow (stdout shown to user, transcript-only by default; stderr shown to model)
#   2  -> block (not used here; this hook is advisory only)
#   other -> non-blocking error
#
# To re-enable hard blocking (legacy), set CCF_HARD_BLOCK=1 in the environment.
set -u

CONFIG="$HOME/.claude/codex-workflow.json"
MODE="cc"

# Read mode (default cc if config missing or unreadable).
# Legacy values "auto"/"manual" map to "cc-codex"/"cc".
if [[ -f "$CONFIG" ]]; then
  VAL=$(python3 -c "
import json
try:
  m = json.load(open('$CONFIG')).get('mode','cc')
except Exception:
  m = 'cc'
m = {'auto': 'cc-codex', 'manual': 'cc'}.get(m, m)
print(m)
" 2>/dev/null)
  [[ -n "${VAL:-}" ]] && MODE="$VAL"
fi

# In CC mode this hook does nothing — user opts into the chain per-task via /cxw or /codex:rescue.
if [[ "$MODE" != "cc-codex" ]]; then
  exit 0
fi

# Parse stdin JSON (Claude Code sends the full hook event).
PAYLOAD=$(cat)

# Extract tool_name, file_path, and (for Edit) total line count of the edit.
# EDIT_LINES = max(lines_in_old_string, lines_in_new_string) for Edit; 0 for others.
# Small Edits (<= EDIT_LINE_THRESHOLD) skip the reminder entirely (truly trivial fixes).
read -r TOOL FPATH EDIT_LINES <<<"$(python3 - "$PAYLOAD" <<'PY'
import json, sys
try:
    ev = json.loads(sys.argv[1])
except Exception:
    print("UNKNOWN  0")
    sys.exit(0)
tool = ev.get("tool_name", "")
ti = ev.get("tool_input", {}) or {}
fp = ti.get("file_path") or ti.get("notebook_path") or ""
lines = 0
if tool == "Edit":
    old = ti.get("old_string", "") or ""
    new = ti.get("new_string", "") or ""
    lines = max(old.count("\n") + 1, new.count("\n") + 1)
print(f"{tool} {fp} {lines}")
PY
)"

# Only consider the three file-mutating tools.
case "$TOOL" in
  Edit|Write|NotebookEdit) ;;
  *) exit 0 ;;
esac

# No path → can't decide, let it through silently.
[[ -z "${FPATH:-}" ]] && exit 0

# Small Edit (default <= 10 lines) → truly trivial, no reminder.
# Override threshold via CCF_EDIT_LINE_THRESHOLD env var (0 disables the skip).
# Write/NotebookEdit never qualify -- they replace whole files / cells.
EDIT_LINE_THRESHOLD="${CCF_EDIT_LINE_THRESHOLD:-10}"
if [[ "$TOOL" == "Edit" && "$EDIT_LINE_THRESHOLD" -gt 0 && "${EDIT_LINES:-0}" -le "$EDIT_LINE_THRESHOLD" ]]; then
  exit 0
fi

# Normalize basename and extension.
BASENAME="${FPATH##*/}"
EXT="${BASENAME##*.}"
EXT_LC=$(printf '%s' "$EXT" | tr '[:upper:]' '[:lower:]')

# --- Exemptions: these paths are always silent even in CC-Codex mode ---

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

# --- Source extensions: SOFT REMINDER (advisory only) ---
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
    if [[ "${CCF_HARD_BLOCK:-0}" == "1" ]]; then
      cat >&2 <<EOF
BLOCKED by ccf workflow guard (mode: CC-Codex, CCF_HARD_BLOCK=1).

Tool: $TOOL
Target: $FPATH

Direct edit of source files is disabled. Delegate to Codex:

  /codex:rescue --write <task description citing $FPATH and line numbers>

To disable: unset CCF_HARD_BLOCK or run /ccf:toggle-mode.
EOF
      exit 2
    fi

    cat >&2 <<EOF
[ccf workflow reminder — CC-Codex mode]
Tool: $TOOL  Target: $FPATH$([[ "$TOOL" == "Edit" && "${EDIT_LINES:-0}" -gt 0 ]] && printf '  (~%s lines)' "$EDIT_LINES")

Non-trivial source edit detected. Prefer the Codex chain when this edit
involves design, multiple call sites, or new logic:

  /codex:rescue --write <task description citing $FPATH:line>

Proceeding with the direct edit anyway. To re-enable hard blocking set
CCF_HARD_BLOCK=1. Switch modes: /cxt   Status: /cxs.
EOF
    exit 0
    ;;
esac

# Unknown extension — let it through silently.
exit 0
