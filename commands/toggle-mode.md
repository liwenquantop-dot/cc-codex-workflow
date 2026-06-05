---
description: "CCF: Toggle workflow mode — auto ↔ manual (/ccf:toggle-mode)"
---

Toggle the codex workflow mode.

Read ~/.claude/codex-workflow.json, flip the mode field:
- "auto" → "manual"
- "manual" → "auto"

If the file does not exist, create it with mode "auto".
Write it back and report the new state.

**Mode meanings:**
- auto: Every task automatically runs full chain (Plan → Implement → Review → Build → Commit)
- manual: Only run full chain when explicitly triggered via /ccf:workflow
