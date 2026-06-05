---
name: ccf
description: >
  Structured codex workflow with Plan → Implement → Review → Commit chain.
  Supports CC mode (plain Claude Code, opt in per-task) and CC-Codex mode (every task auto-runs the chain).
  Short aliases: /cx (implement), /cxr (review), /cxa (adversarial review), /cxw (full chain).
  Heterogeneous review: Claude reviews Codex, Codex reviews Claude's direct fixes.
---

# Codex Workflow

## Mode

Active mode is set in `~/.claude/codex-workflow.json` (`"cc"` or `"cc-codex"`; legacy `"manual"`/`"auto"` still accepted) and injected each turn via UserPromptSubmit hook.

- **CC-Codex mode**: Every task runs full chain automatically through Codex. Do NOT stop between phases.
- **CC mode** (default): Plain Claude Code behavior. Edit source directly. Opt into the chain per-task via `/cxw` or `/codex:rescue`.

## Commands

| Command | Description |
|---|---|
| `/cxw` | Full chain: Plan → Implement → Review → Build → Commit |
| `/cx` | Implement only (codex:rescue --write) |
| `/cxr` | Review only |
| `/cxa` | Adversarial review |
| `/cxt` | Toggle CC ↔ CC-Codex mode |
| `/cxs` | Show current status |

## Autonomous Execution (CC-Codex mode)

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
