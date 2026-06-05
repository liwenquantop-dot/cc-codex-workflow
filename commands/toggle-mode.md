---
description: "CCF: Toggle workflow mode — auto ↔ manual (/ccf:toggle-mode)"
---

Toggle the codex workflow mode.

Procedure (run these tools in order):
1. Use the `Read` tool on `~/.claude/codex-workflow.json`.
   - If Read fails because the file does not exist, treat the current mode as "manual" (default) and skip to step 3.
2. Parse the JSON, read the `mode` field.
3. Compute the new mode:
   - "auto" → "manual"
   - anything else (including "manual" or missing) → "auto"
4. Use the `Write` tool to overwrite `~/.claude/codex-workflow.json` with exactly:
   `{"mode": "<new-mode>"}\n`
   Claude Code requires the Read in step 1 before this Write — do not skip it even if you "know" the current state.
5. Report the new mode in one short sentence.

Do not change anything else. Do not commit. Do not run other commands.

**Mode meanings:**
- auto: Every task automatically runs full chain (Plan → Implement → Review → Build → Commit)
- manual: Only run full chain when explicitly triggered via /ccf:workflow
