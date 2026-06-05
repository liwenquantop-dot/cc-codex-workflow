---
description: "CCF: Show workflow status and config (/ccf:workflow-status)"
---

Read ~/.claude/codex-workflow.json and report:

1. Mode (apply legacy aliases first: "auto"→"cc-codex", "manual"→"cc"):
   - **CC-Codex**: every task runs the full chain automatically.
   - **CC** (default): plain Claude Code, opt in per-task via /cxw or /codex:rescue.
   If file does not exist, report CC (default).
2. Available commands: /ccf:workflow, /ccf:implement, /ccf:code-review, /ccf:adversarial-review, /ccf:toggle-mode, /ccf:workflow-status
