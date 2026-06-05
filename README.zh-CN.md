# cc-codex-workflow

[English](README.md) | **中文**

Claude Code + Codex 协作工作流插件。强制执行 **Plan → Implement → Review → Commit** 链路，并采用异构审查（Claude 审 Codex 的 diff，Codex 审 Claude 的直接修改）。

> 命名规则：`插件名@市场名` = `ccf@cc-codex-workflow`。`ccf` 是插件名（来自 `plugin.json`），`cc-codex-workflow` 是市场/仓库名。

---

## Claude Code 和 Codex 的关系

**Claude Code 是"架构师"，Codex 是"程序员"。** 一个想清楚要做什么，一个把代码真正写出来。

| 角色 | 人类对照 | 干什么 | 不干什么 |
|---|---|---|---|
| **Claude Code（主会话）** | 资深工程师 / 技术 Lead | 读需求、读代码、规划、拆任务、审查 diff、跑测试、写 commit、与人对话 | 不直接动源码（单行 trivial 修复除外） |
| **Codex（子代理）** | 高产实习生 / 外包码农 | 按规格猛写代码、改大段实现、做机械重构 | 不规划、不审查自己的输出、不与人对话 |

**为什么必须配合：**

1. **异构审查** — 同模型既写又审会共享盲点（确认偏置）。Claude（Opus）与 Codex（GPT-5.x）架构不同、盲点不同，互审能挑出对方挑不出的问题。
2. **各司其职** — Claude Code 擅长理解、推理、判断；Codex 擅长按规格高保真生成代码。用反了 = 让架构师写 CRUD、让实习生定方案。
3. **经济性** — cpro 模式下 Claude 的 token 价值最高在 reasoning（规划/审查），把"写"外包给 Codex 整体效率最高。

---

## 极速安装 — 只需两个插件

不用手工写 hook 脚本，不用编辑 `~/.claude/settings.json`。两个插件自带 hook 注册，开箱即用。

```bash
# 1. Codex 插件（提供 /codex:rescue、/codex:review、/codex:setup）
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex

# 2. 本插件（工作流编排 + 硬阻断守卫）
/plugin marketplace add liwenquantop-dot/cc-codex-workflow
/plugin install ccf@cc-codex-workflow

# 3. 重载 + 首次 Codex 初始化
/reload-plugins
/codex:setup

# 4. 验证
/ccf:workflow-status
```

完成。新开任意 Claude Code 会话工作流自动生效。

### 验证安装

```bash
cat ~/.claude/plugins/installed_plugins.json | grep -E 'ccf|codex'
# 应能看到两条带 installedAt 时间戳的记录
```

### 卸载

```bash
claude plugin uninstall ccf@cc-codex-workflow
claude plugin uninstall codex@openai-codex
```

---

## 自动启用的能力

| 层 | 机制 | 效果 |
|---|---|---|
| 提醒 | `UserPromptSubmit` hook | 每轮用户输入注入 "CODEX WORKFLOW ACTIVE" + 当前模式（AUTO/MANUAL），让规则在长会话中始终留在 context |
| **硬阻断** | `PreToolUse` hook（AUTO 模式） | 任何直接的 `Edit` / `Write` / `NotebookEdit` 源码操作被 `exit 2` 取消，强制改走 `/codex:rescue --write`。软提醒会漂移，硬阻断不会 |
| 命令 | `/ccf:*` slash 命令 | 各阶段一键触发 |

不需要编辑 `~/.claude/settings.json` — 插件通过 `.claude-plugin/plugin.json` 注册全部 hook。

---

## 命令

| 命令 | 描述 |
|---|---|
| `/ccf:workflow` | 完整链：Plan → Implement → Review → Build → Commit |
| `/ccf:implement` | 仅实施（等价 `/codex:rescue --write`） |
| `/ccf:code-review` | 代码审查（等价 `/codex:review`） |
| `/ccf:adversarial-review` | 对抗式审查（等价 `/codex:adversarial-review`） |
| `/ccf:toggle-mode` | 切换 AUTO ↔ MANUAL |
| `/ccf:workflow-status` | 查看当前模式 + 配置 |

### 短别名（可选）

在 `~/.claude/commands/` 下放薄包装命令，得到更短的名字：

```
~/.claude/commands/cx.md  → /ccf:implement
~/.claude/commands/cxw.md → /ccf:workflow
~/.claude/commands/cxr.md → /ccf:code-review
~/.claude/commands/cxa.md → /ccf:adversarial-review
~/.claude/commands/cxt.md → /ccf:toggle-mode
~/.claude/commands/cxs.md → /ccf:workflow-status
```

---

## 模式

配置：`~/.claude/codex-workflow.json`。用 `/ccf:toggle-mode` 切换。

### AUTO

- 每个任务自动跑完整链。
- `PreToolUse` 守卫**硬阻断**对源码扩展名的直接 `Edit` / `Write` / `NotebookEdit`：
  `.py .js .jsx .ts .tsx .go .rs .java .kt .swift .c .cpp .h .hpp .cs .rb .php .lua .dart .sh .bash .vue .svelte .sql .graphql .proto .ipynb` 等。
- 豁免：`.claude/`、`.claude-plugin/`、`.codex/`、`.github/`、`docs/`、`README*`、`CLAUDE.md`、`*.md`、`*.json`、`*.yaml`、`*.toml`，以及未知扩展名（如 `Makefile`、`Dockerfile`）。
- 被阻断的工具调用返回 stderr 提示，引导模型改用 `/codex:rescue --write`。

### MANUAL（默认）

- 不硬阻断。用 `/ccf:workflow` 显式触发完整链。
- 每轮仍注入提醒。

### 为什么要硬阻断？

`UserPromptSubmit` 提醒是软约束 — 长会话里 Claude 会漂移，会自我说服"这只是单行修复"绕过规则。`PreToolUse` 直接取消工具调用（`exit 2`），AUTO 开启时工作流真正不可绕过。

---

## 工作原理

1. **Plan**（Claude）：读文件，按 file_path:line_number 拆解任务。
2. **Implement**（Codex）：通过 `/codex:rescue --write` 委托。
3. **Review**（Claude）：读 Codex 的 diff。trivial 修复（拼写/import/常量）直接改；逻辑 bug 带具体反馈打回 Codex 重写。
4. **Phase 3c — 异构审查**（Codex）：Claude 若直接改了，Codex 反向再审一遍。
5. **Build**（Claude）：跑项目编译/测试命令。
6. **Commit**（Claude）：Conventional Commits 规范提交。

### 为什么要异构审查？

同一个模型既写又审会共享盲点 — 对自己输出有确认偏置。Claude（Opus）与 Codex（GPT-5.x）架构不同、盲点不同，交叉审查能挑出单模型自审挑不出的问题。

---

## 依赖

- [codex-plugin-cc](https://github.com/openai/codex-plugin-cc) — 提供 `/codex:rescue`、`/codex:review`、`/codex:setup`
- [Codex CLI](https://github.com/openai/codex) — 已安装并完成鉴权（`/codex:setup` 可帮你安装）
- Claude Code CLI
