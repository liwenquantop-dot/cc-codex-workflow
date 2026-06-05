# cc-codex-workflow

Structured codex workflow plugin for Claude Code. Enforces Plan → Implement → Review → Commit with heterogeneous review (Claude reviews Codex, Codex reviews Claude).

> **Naming format**: `plugin@marketplace`. Plugin name is `ccf` (from `plugin.json`), marketplace name is `cc-codex-workflow` (repo name). So: `ccf@cc-codex-workflow`.

## Install

```bash
# 1. Install codex plugin (dependency)
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex

# 2. Install cc-codex-workflow
/plugin marketplace add liwenquantop-dot/cc-codex-workflow

# 3. Install explicitly (auto-install does NOT work — must run manually)
/plugin install ccf@cc-codex-workflow

# 4. Reload
/reload-plugins

# 5. Setup Codex (first time only)
/codex:setup

# 6. Verify
/ccf:workflow-status
```

### Verify install

```bash
cat ~/.claude/plugins/installed_plugins.json | grep ccf
# Should show an entry with installedAt timestamp.
```

### Uninstall

```bash
claude plugin uninstall ccf@cc-codex-workflow
```

## Commands

| Command | Description |
|---|---|
| `/ccf:workflow` | Full chain: Plan → Implement → Review → Build → Commit |
| `/ccf:implement` | Implement only (`/codex:rescue --write`) |
| `/ccf:code-review` | Code review (`/codex:review`) |
| `/ccf:adversarial-review` | Adversarial review (`/codex:adversarial-review`) |
| `/ccf:toggle-mode` | Toggle auto/manual mode |
| `/ccf:workflow-status` | Show current status |

### Short Aliases (optional)

Create local commands in `~/.claude/commands/` for shorter names:

```bash
# ~/.claude/commands/cx.md → /ccf:implement
# ~/.claude/commands/cxw.md → /ccf:workflow
# ~/.claude/commands/cxr.md → /ccf:code-review
# ~/.claude/commands/cxa.md → /ccf:adversarial-review
# ~/.claude/commands/cxt.md → /ccf:toggle-mode
# ~/.claude/commands/cxs.md → /ccf:workflow-status
```

## Modes

- **AUTO** (`/ccf:toggle-mode`): Every task automatically runs the full chain
- **MANUAL** (default): Use `/ccf:workflow` to trigger the full chain explicitly

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
