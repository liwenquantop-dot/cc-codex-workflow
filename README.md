# cc-codex-workflow

**English** | [中文](README.zh-CN.md)

Claude Code + Codex collaboration workflow plugin. Enforces **Plan → Implement → Review → Commit** with heterogeneous review (Claude reviews Codex's diffs, Codex reviews Claude's direct fixes).

> Naming: `plugin@marketplace` = `ccf@cc-codex-workflow`. `ccf` is the plugin name (from `plugin.json`); `cc-codex-workflow` is the marketplace/repo name.

---

## Claude Code vs Codex

**Claude Code is the "architect"; Codex is the "programmer".** One figures out *what* to build, the other actually writes the code.

| Role | Human analog | What it does | What it doesn't do |
|---|---|---|---|
| **Claude Code (main session)** | Senior engineer / tech lead | Read requirements, read code, plan, decompose tasks, review diffs, run tests, write commits, talk to humans | Doesn't touch source directly (except trivial one-liners) |
| **Codex (subagent)** | High-output intern / contractor | Crank out code to spec, write large implementations, mechanical refactors | Doesn't plan, doesn't review its own output, doesn't talk to humans |

**Why pair them:**

1. **Heterogeneous review** — Same model writing and reviewing shares blind spots (confirmation bias on its own output). Claude (Opus) and Codex (GPT-5.x) have different architectures and different blind spots, so each catches what the other misses.
2. **Division of labor** — Claude Code is best at understanding, reasoning, and judgment. Codex is best at high-fidelity code generation to spec. Using them backwards = having the architect write CRUD and the intern make design calls.
3. **Economics** — On a Claude Pro subscription, Claude's tokens are most valuable on reasoning (plan/review). Outsourcing the "writing" to Codex maximizes throughput per dollar.

---

## Quick Install — Just Two Plugins

No manual hook scripts, no editing `~/.claude/settings.json`. Both plugins install their own hooks automatically.

```bash
# 1. Codex plugin (provides /codex:rescue, /codex:review, /codex:setup)
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex

# 2. This plugin (workflow orchestration + hard-block guard)
/plugin marketplace add liwenquantop-dot/cc-codex-workflow
/plugin install ccf@cc-codex-workflow

# 3. Reload + first-time Codex setup
/reload-plugins
/codex:setup

# 4. Verify
/ccf:workflow-status
```

That's it. Open any Claude Code session and the workflow is active.

### Verify install

```bash
cat ~/.claude/plugins/installed_plugins.json | grep -E 'ccf|codex'
# Should show two entries with installedAt timestamps.
```

### Uninstall

```bash
claude plugin uninstall ccf@cc-codex-workflow
claude plugin uninstall codex@openai-codex
```

---

## What You Get (Automatically)

| Layer | Mechanism | Effect |
|---|---|---|
| Reminder | `UserPromptSubmit` hook | Injects "CODEX WORKFLOW ACTIVE" + mode (AUTO/MANUAL) on every user turn so the rule stays in context across long sessions |
| **Hard block** | `PreToolUse` hook (AUTO mode) | Cancels any direct `Edit` / `Write` / `NotebookEdit` on source files with `exit 2`, forcing the edit through `/codex:rescue --write`. Soft reminders alone drift over time — this guard does not |
| Commands | `/ccf:*` slash commands | One-shot triggers for each workflow phase |

No editing of `~/.claude/settings.json` is required — the plugin registers everything through `.claude-plugin/plugin.json`.

---

## Commands

| Command | Description |
|---|---|
| `/ccf:workflow` | Full chain: Plan → Implement → Review → Build → Commit |
| `/ccf:implement` | Implement only (`/codex:rescue --write`) |
| `/ccf:code-review` | Code review (`/codex:review`) |
| `/ccf:adversarial-review` | Adversarial review (`/codex:adversarial-review`) |
| `/ccf:toggle-mode` | Toggle AUTO ↔ MANUAL |
| `/ccf:workflow-status` | Show current mode + config |

### Short aliases (optional)

Put thin wrapper commands in `~/.claude/commands/` for shorter names:

```
~/.claude/commands/cx.md  → /ccf:implement
~/.claude/commands/cxw.md → /ccf:workflow
~/.claude/commands/cxr.md → /ccf:code-review
~/.claude/commands/cxa.md → /ccf:adversarial-review
~/.claude/commands/cxt.md → /ccf:toggle-mode
~/.claude/commands/cxs.md → /ccf:workflow-status
```

---

## Modes

Config: `~/.claude/codex-workflow.json`. Toggle with `/ccf:toggle-mode`.

### AUTO

- Every task automatically runs the full chain.
- `PreToolUse` guard **hard-blocks** direct `Edit` / `Write` / `NotebookEdit` on source extensions:
  `.py .js .jsx .ts .tsx .go .rs .java .kt .swift .c .cpp .h .hpp .cs .rb .php .lua .dart .sh .bash .vue .svelte .sql .graphql .proto .ipynb` and more.
- Exempt: `.claude/`, `.claude-plugin/`, `.codex/`, `.github/`, `docs/`, `README*`, `CLAUDE.md`, `*.md`, `*.json`, `*.yaml`, `*.toml`, and unknown extensions (e.g. `Makefile`, `Dockerfile`).
- Blocked tool call returns a stderr message instructing the model to use `/codex:rescue --write`.

### MANUAL (default)

- No hard block. Use `/ccf:workflow` to trigger the full chain explicitly.
- Reminder still injected each turn.

### Why hard-block?

`UserPromptSubmit` reminders are soft — Claude drifts away from them in long sessions and may rationalize "this is a single-line fix" to bypass the rule. `PreToolUse` cancels the tool call outright (`exit 2`), making the workflow non-bypassable when AUTO is on.

---

## How It Works

1. **Plan** (Claude): Read files, decompose the task with file paths and line numbers.
2. **Implement** (Codex): Delegate via `/codex:rescue --write`.
3. **Review** (Claude): Read Codex's diff. Trivial fixes applied directly (typo / import / constant); logic bugs sent back to Codex with a specific rewrite prompt.
4. **Phase 3c — Heterogeneous review** (Codex): If Claude made direct fixes, Codex re-reviews them.
5. **Build** (Claude): Run the project build/test command.
6. **Commit** (Claude): Conventional Commits.

### Why heterogeneous review?

Same model writing and reviewing shares blind spots — confirmation bias on its own output. Claude (Opus) and Codex (GPT-5.x) have different architectures and different blind spots, so cross-review catches what single-model self-review misses.

---

## Requirements

- [codex-plugin-cc](https://github.com/openai/codex-plugin-cc) — provides `/codex:rescue`, `/codex:review`, `/codex:setup`
- [Codex CLI](https://github.com/openai/codex) — installed and authenticated (`/codex:setup` can install it for you)
- Claude Code CLI
