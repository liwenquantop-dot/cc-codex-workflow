---
description: "CCF: Show workflow status and config (/ccf:workflow-status)"
---

Read ~/.claude/codex-workflow.json and report:

1. Mode: **AUTO** (every task runs full chain) / **MANUAL** (use /ccf:workflow to trigger)
   If file does not exist, report MANUAL (default).
2. Available commands: /ccf:workflow, /ccf:implement, /ccf:code-review, /ccf:adversarial-review, /ccf:toggle-mode, /ccf:workflow-status
