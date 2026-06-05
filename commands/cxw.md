---
description: "Full codex workflow: Plan → Implement → Review → Commit. /cxw fix the bug"
argument-hint: "[task description]"
---

Run the FULL autonomous codex workflow on this task. Do NOT stop between phases.

## Task
$ARGUMENTS

## Execution (autonomous, no pauses)

1. **Plan**: Read relevant files. Decompose into concrete steps with file paths and line numbers.
2. **Implement**: /cc-codex-workflow:rescue --write with the decomposed task. Verify git diff --stat is non-empty.
3. **Review**: git diff to review all changes. Check correctness, edge cases, imports, secrets, regressions.
   - Trivial issues (typo, import): fix directly.
   - Logic bugs: /cc-codex-workflow:rescue again with specific feedback (max 2 retries).
   - After 2 retries still broken: escalate to user.
4. **Build**: Run project build command (mvn compile or equivalent).
5. **Commit**: Stage and commit with conventional commit message.

Stop only when genuinely blocked (build fails with non-obvious fix, CRITICAL review finding, irreversible op).
Report: one short summary of what shipped.
