---
description: "CCF: Implement task via Codex (/ccf:implement)"
argument-hint: "[task description]"
---

Forward to /codex:rescue --write with user arguments.

**Always include `--write`** — without it Codex runs in read-only sandbox and cannot mutate files (empty diff, no edits applied).

If the user passed $ARGUMENTS, call:
/codex:rescue --write $ARGUMENTS

If no arguments, ask what Codex should do.

After Codex returns: if the diff is empty but the task required file changes, verify `--write` was actually forwarded (sandbox should be `workspace-write`, not `read-only`).
