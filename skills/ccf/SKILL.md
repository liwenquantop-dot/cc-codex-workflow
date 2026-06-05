---
name: ccf
description: >
  Structured codex workflow with Plan → Implement → Review → Commit chain.
  Supports auto mode (every task runs full chain) and manual mode (/cxw to trigger).
  Short aliases: /cx (implement), /cxr (review), /cxa (adversarial review), /cxw (full chain).
  Heterogeneous review: Claude reviews Codex, Codex reviews Claude's direct fixes.
---

# Codex Workflow

## Mode

Active mode is set in `~/.claude/codex-workflow.json` (`"auto"` or `"manual"`) and injected each turn via UserPromptSubmit hook.

- **AUTO mode**: Every task runs full chain automatically. Do NOT stop between phases.
- **MANUAL mode**: Default behavior is single-step. Use `/cxw` to trigger full chain explicitly.

## Commands

| Command | Description |
|---|---|
| `/cxw` | Full chain: Plan → Implement → Review → Build → Commit |
| `/cx` | Implement only (codex:rescue --write) |
| `/cxr` | Review only |
| `/cxa` | Adversarial review |
| `/cxt` | Toggle auto/manual mode |
| `/cxs` | Show current status |

## Autonomous Execution (AUTO mode)

Run the full chain without stopping between phases.

**Only stop when genuinely blocked:**
- Build fails with non-obvious fix
- CRITICAL review finding needs design decision
- Irreversible operation required (git push, PR, prod deploy)
- Codex returns empty diff after 2 retries
- Scope ambiguity

**Do NOT stop for:**
- "Should I commit?" — just do it
- Listing review findings with no decision needed
- Confirming obvious next step

## Review Strategy

1. Claude reviews Codex's diff (Phase 3)
2. If Claude makes direct fixes → Codex re-reviews (Phase 3c)
3. High-risk code → adversarial review via `/cxa` (Phase 3b)

This heterogeneous review catches more issues than same-model review.

## Edit Boundaries

- **Implementation** (Codex/Agent): `src/`, `*.java`, `*.py`, `*.js`, `*.ts`, `*.go`, `*.rs`, config files
- **Main session** (Claude): `.claude/`, `docs/`, markdown, planning, review, git ops

## Direct Edit Allowed When

- Single-line fix (typo, import, constant)
- Pure structural op with zero call sites
- User explicitly requests direct edit
