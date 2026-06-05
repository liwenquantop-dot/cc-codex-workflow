# cc-codex-workflow

Structured codex workflow plugin for Claude Code. Enforces Plan → Implement → Review → Commit with heterogeneous review (Claude reviews Codex, Codex reviews Claude).

Includes bundled [OpenAI Codex](https://github.com/openai/codex) plugin — single install, zero extra dependencies.

## Install

```bash
# 1. Register marketplace
/plugin marketplace add liwenquantop-dot/cc-codex-workflow

# 2. Install plugin
/plugin install cc-codex-workflow@cc-codex-workflow

# 3. Reload plugins
/reload-plugins

# 4. Setup Codex (first time only)
/codex:setup

# 5. Verify
/cxs
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
| `/codex:rescue` | Direct Codex rescue (bundled) |
| `/codex:review` | Direct Codex review (bundled) |
| `/codex:setup` | Codex setup (bundled) |

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

- [Codex CLI](https://github.com/openai/codex) installed and authenticated
- Claude Code CLI

## Credits

Bundles [OpenAI Codex plugin](https://github.com/openai/codex) v1.0.4 by OpenAI. See `LICENSE.codex` and `NOTICE`.
