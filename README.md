# cc-codex-workflow

Structured codex workflow plugin for Claude Code. Enforces Plan → Implement → Review → Commit with heterogeneous review (Claude reviews Codex, Codex reviews Claude).

## Install

```bash
claude install-plugin github:liwenquan/cc-codex-workflow
```

## Commands

| Command | Description |
|---|---|
| `/cxw` | Full chain: Plan → Implement → Review → Build → Commit |
| `/cx` | Implement only (`/codex:rescue --write`) |
| `/cxr` | Review only |
| `/cxa` | Adversarial review |
| `/cxt` | Toggle auto/manual mode |
| `/cxs` | Show current status |

## Modes

- **AUTO** (`/cxt` to switch): Every task automatically runs the full chain
- **MANUAL** (default): Use `/cxw` to trigger the full chain explicitly

Config stored in `~/.claude/cc-codex-workflow.json`.

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

- [codex plugin](https://github.com/openai/codex) (`/codex:rescue`, `/codex:review`)
- Claude Code CLI
