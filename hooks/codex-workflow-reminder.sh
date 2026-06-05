#!/usr/bin/env bash
# UserPromptSubmit hook — codex-workflow reminder with mode toggle.
set -u

# Drain stdin (Claude Code sends JSON event) but don't need to parse it.
cat > /dev/null

CONFIG="$HOME/.claude/codex-workflow.json"
MODE="cc"

# Read mode. Legacy values "auto"/"manual" map to "cc-codex"/"cc".
if [[ -f "$CONFIG" ]]; then
  VAL=$(python3 -c "
import json
try:
  m = json.load(open('$CONFIG')).get('mode', 'cc')
except Exception:
  m = 'cc'
# legacy aliases
m = {'auto': 'cc-codex', 'manual': 'cc'}.get(m, m)
print(m)
" 2>/dev/null)
  [[ -n "$VAL" ]] && MODE="$VAL"
fi

if [[ "$MODE" == "cc-codex" ]]; then
  cat <<'EOF'
CC-CODEX MODE — Every task MUST run full chain: Plan → Implement → Review → Build → Commit. Do NOT stop between phases. Implement = `/codex:rescue --write` (Codex). `--write` is REQUIRED — without it Codex runs read-only and returns an empty diff with no file changes. Review = CLAUDE reads `git diff` directly — do NOT call `/cxr`, `/codex:review`, or `/codex:rescue` for the review step (same-model review defeats the cross-check). Codex only re-reviews if Claude makes direct fixes (Phase 3c) or for `/cxa` adversarial pass on high-risk code. Direct Edit/Write on src/ only if: single-line fix, zero call sites, or user explicitly requested. Self-check before every Edit/Write on .java/.py/.js/.ts/.go/.rs files. Stop only on: build fail, CRITICAL review, irreversible op. Switch: /cxt. Status: /cxs.
EOF
else
  cat <<'EOF'
CC MODE — Default Claude Code behavior: edit source directly, no enforced codex chain. Opt in per-task with `/cxw` (full Plan → Implement → Review → Build → Commit chain) or `/codex:rescue --write <task>` (single Codex implement step). Switch to CC-Codex (auto-chain every task): /cxt. Status: /cxs.
EOF
fi
