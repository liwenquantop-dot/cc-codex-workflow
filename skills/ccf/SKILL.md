---
name: ccf
description: >
  Structured codex workflow with Plan → Implement → Review → Commit chain.
  Supports CC mode (plain Claude Code, opt in per-task) and CC-Codex mode (every task auto-runs the chain).
  Short aliases: /cx (Codex implement), /cxr (Codex on-demand review), /cxa (Codex adversarial review), /cxw (full chain).
  Heterogeneous review: Claude reviews Codex's diff in Phase 3 (never Codex itself); Codex re-reviews only Claude-authored direct fixes (Phase 3c) or runs adversarial pass on high-risk code (Phase 3b).
---

# Codex Workflow

## Mode

Active mode is set in `~/.claude/codex-workflow.json` (`"cc"` or `"cc-codex"`; legacy `"manual"`/`"auto"` still accepted) and injected each turn via UserPromptSubmit hook.

- **CC-Codex mode**: Every task runs full chain automatically. Implement via Codex, Review by Claude. Do NOT stop between phases.
- **CC mode** (default): Plain Claude Code behavior. Edit source directly. Opt into the full chain per-task via `/cxw`, or run a single Codex implement step via `/cx`.

## Commands

| Command | Who runs it | When to use |
|---|---|---|
| `/cxw` | Orchestrator (Claude drives, Codex implements, Claude reviews) | Run the full Plan → Implement → Review → Build → Commit chain |
| `/cx` | Codex | Implement step only — delegates code mutation to Codex (`codex:rescue --write`) |
| `/cxr` | Codex | **Manual** Codex code review on demand. NOT used inside the auto chain — Phase 3 review is always Claude. Use this only when the user explicitly asks for a Codex second opinion on already-written code. |
| `/cxa` | Codex | Adversarial Codex review on high-risk code (security/concurrency/migrations). Add AFTER Claude's Phase 3, never instead of it. |
| `/cxt` | Claude | Toggle CC ↔ CC-Codex mode |
| `/cxs` | Claude | Show current status |

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

**Phase 3 (Review) is always done by Claude, never by Codex.** Heterogeneous review means a *different model* checks the code than the one that wrote it. Codex implemented → Claude reviews. Re-invoking `/codex:review` or `/codex:rescue` on Codex's own diff is same-model review and breaks the cross-check.

1. Phase 3 — **Claude** reviews Codex's diff (read `git diff` directly; do NOT call `/cxr`, `/codex:review`, or `/codex:rescue` for the review itself).
2. Phase 3c — if Claude made direct fixes on top of Codex's diff, **Codex** re-reviews those Claude-authored fixes (this is the only place Codex reviews).
3. Phase 3b — high-risk code (security, concurrency, migrations) → adversarial Codex review via `/cxa` AFTER Claude's Phase 3, never replacing it.

Todo lists for the chain should read "Claude reviews diff" (not "Codex review") to prevent misrouting.

## Edit Boundaries

- **Implementation** (Codex/Agent): `src/`, `*.java`, `*.py`, `*.js`, `*.ts`, `*.go`, `*.rs`, config files
- **Main session** (Claude): `.claude/`, `docs/`, markdown, planning, review, git ops

## Direct Edit Allowed When

- Single-line fix (typo, import, constant)
- Pure structural op with zero call sites
- User explicitly requests direct edit

## Critical: `--write` Flag Required for File Mutations

`/codex:rescue` defaults to **read-only** sandbox. Without `--write`, Codex investigates and proposes a patch but **cannot modify files** — you get an empty diff and the working tree stays unchanged.

- `/cx` (alias for `/ccf:implement`) hardcodes `--write`. Safe.
- `/cxw` (full chain) routes implementation through `/cx`. Safe.
- Raw `/codex:rescue <task>` → **read-only diagnosis only**. Files will NOT be edited.
- Raw `/codex:rescue --write <task>` → writes allowed.

**Rule**: If the goal is to modify files, never call `/codex:rescue` without `--write`. Prefer `/cx` or `/cxw` so the flag is automatic. If Codex returns an empty diff and the task was meant to mutate files, the missing `--write` flag is the first thing to check.
