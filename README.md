# cc-codex-workflow

Structured codex workflow plugin for Claude Code. Enforces Plan → Implement → Review → Commit with heterogeneous review (Claude reviews Codex, Codex reviews Claude).

## Install

```bash
# 1. Install codex plugin (dependency)
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex

# 2. Install cc-codex-workflow
/plugin marketplace add liwenquantop-dot/cc-codex-workflow
/plugin install cc-codex-workflow@cc-codex-workflow

# 3. Reload
/reload-plugins

# 4. Setup Codex (first time only)
/codex:setup

# 5. Verify
/cc-codex-workflow:cxs
```

## Commands

| Command | Description |
|---|---|
| `/cc-codex-workflow:cxw` | Full chain: Plan → Implement → Review → Build → Commit |
| `/cc-codex-workflow:cx` | Implement only (`/codex:rescue --write`) |
| `/cc-codex-workflow:cxr` | Review only (`/codex:review`) |
| `/cc-codex-workflow:cxa` | Adversarial review (`/codex:adversarial-review`) |
| `/cc-codex-workflow:cxt` | Toggle auto/manual mode |
| `/cc-codex-workflow:cxs` | Show current status |

### Short Aliases (optional)

Create local commands in `~/.claude/commands/` for shorter names:

```bash
# ~/.claude/commands/cx.md
---
description: "Codex implement (→ /cc-codex-workflow:cx)"
---
Forward to /cc-codex-workflow:cx with arguments: $ARGUMENTS
```

Repeat for `cxw.md`, `cxr.md`, `cxa.md`, `cxt.md`, `cxs.md`. Then use `/cx`, `/cxw`, etc.

## Modes

- **AUTO** (`/cxt` to switch): Every task automatically runs the full chain
- **MANUAL** (default): Use `/cxw` to trigger the full chain explicitly

Config stored in `~/.claude/codex-workflow.json`.

## How It Works

1. **Plan**: Read files, decompose task with file paths and line numbers
2. **Implement**: Delegate to Codex via `/codex:rescue --write`
3. **Review**: Claude reviews Codex's diff; trivial fixes applied directly, logic bugs sent back
4. **Phase 3c**: If Claude made direct fixes, Codex re-reviews them (heterogeneous review)
5. **Build**: Run project build command
6. **Commit**: Conventional commit

## Why Heterogeneous Review?

Same model writing and reviewing shares blind spots (confirmation bias). This workflow has Claude review Codex's output AND Codex review Claude's direct fixes — catching more real issues than either alone.

## Requirements

- [codex plugin](https://github.com/openai/codex-plugin-cc) (`/codex:rescue`, `/codex:review`, `/codex:setup`)
- [Codex CLI](https://github.com/openai/codex) installed and authenticated
- Claude Code CLI
