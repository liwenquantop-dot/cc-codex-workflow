---
description: "CCF: Toggle workflow mode — CC ↔ CC-Codex (/ccf:toggle-mode)"
---

Toggle the codex workflow mode.

Procedure (run these tools in order):
1. Use the `Read` tool on `~/.claude/codex-workflow.json`.
   - If Read fails because the file does not exist, treat the current mode as "cc" (default) and skip to step 3.
2. Parse the JSON, read the `mode` field. Apply legacy aliases first:
   - "auto" → treat as "cc-codex"
   - "manual" → treat as "cc"
3. Compute the new mode:
   - "cc-codex" → "cc"
   - anything else (including "cc" or missing) → "cc-codex"
4. Use the `Write` tool to overwrite `~/.claude/codex-workflow.json` with exactly:
   `{"mode": "<new-mode>"}\n`
   Claude Code requires the Read in step 1 before this Write — do not skip it even if you "know" the current state.
5. Report the new mode in one short sentence.

Do not change anything else. Do not commit. Do not run other commands.

**Mode meanings:**
- **CC** (default): Plain Claude Code behavior — edit source directly, no enforced codex chain. Opt in per-task via `/cxw` or `/codex:rescue --write`.
- **CC-Codex**: Every task automatically runs the full chain (Plan → Implement → Review → Build → Commit) through Codex.
