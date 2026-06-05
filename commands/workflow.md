---
description: "CCF: Full workflow chain — Plan → Implement → Review → Build → Commit (/ccf:workflow)"
argument-hint: "[task description]"
---

Run the FULL autonomous codex workflow on this task. Do NOT stop between phases.

## Task
$ARGUMENTS

## Execution (autonomous, no pauses)

1. **Plan**: Read relevant files. Decompose into concrete steps with file paths and line numbers.
2. **Implement**: /codex:rescue --write with the decomposed task. Verify git diff --stat is non-empty.
3. **Review (Claude does this — NOT Codex)**: Read the diff yourself via `git diff` and judge it. This is heterogeneous review: a different model than the one that wrote the code. Do NOT call `/codex:review`, `/cxr`, or `/codex:rescue` for the review itself — that defeats the cross-model check.
   - Check: correctness, edge cases, imports, secrets, regressions, scope creep.
   - Trivial issues (typo, import): fix directly with Edit. After such direct fixes, optionally run Phase 3c.
   - Logic bugs in Codex's output: re-dispatch to Codex via `/codex:rescue --write` with specific feedback. Count this as one Phase-2 retry (max 2 total Phase-2 retries per task).
   - After 2 Phase-2 retries still broken: escalate to user.
3b. **Adversarial review (optional, high-risk only)**: For security/concurrency/data-migration code, after Phase 3 also run `/cxa`. Never replaces Phase 3.
3c. **Codex re-review of Claude's direct fixes (optional)**: If Claude made direct Edit fixes on top of Codex's diff, run `/cxr` so Codex audits the Claude-authored lines (this is the one place `/cxr` belongs inside the chain).
4. **Build**: Run project build command (mvn compile or equivalent).
5. **Commit**: Stage and commit with conventional commit message.

Stop only when genuinely blocked (build fails with non-obvious fix, CRITICAL review finding, irreversible op).
Report: one short summary of what shipped.
