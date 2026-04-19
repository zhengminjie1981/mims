# MIMS - Make Idea Make Sense

> 迷悟师 — 通过对话帮助非技术用户完成软件设计的 AI 引导师

**版本**：1.3.1

---

## 前提条件

| 条件 | 说明 |
|------|------|
| AI 编程工具 | Claude Code CLI / Codex App / Cursor / 其他支持 Skill 的工具 |
| 操作系统 | Windows / macOS / Linux |
| 网络连接 | 脚本安装时需要；手动安装不需要 |

---

## 安装（全局）

**安装一次，所有项目可用。** 无需在每个项目中重复安装。

### Linux / macOS

```bash
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash
```

### Windows PowerShell

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
```

### AI 代理非交互安装

```bash
# Linux/macOS
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash -s -- --silent

# Windows PowerShell
iex "& {$(Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1' -UseBasicParsing)} -Silent"
```

### 企业内网

将脚本 URL 中的 `raw.githubusercontent.com/zhengminjie1981/mims/main/` 替换为 `gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/`。

### 从本地源码安装

```bash
git clone https://github.com/zhengminjie1981/mims.git
# Linux/macOS
bash mims/install/install-global.sh --source mims

# Windows PowerShell
.\mims\install\install-global.ps1 -Source mims
```

---

## 安装了什么

```
~/.claude/
├── skills/mims/           ← Skill + 知识库
│   ├── SKILL.md
│   └── references/
└── agents/                ← 子代理
    ├── mims-validator.md
    ├── mims-prototyper.md
    ├── mims-change-manager.md
    └── mims-spec-generator.md

~/.agents/                 ← Codex 兼容（自动创建）
├── skills/mims/
└── agents/
```

**兼容的工具**：Claude Code、Codex App、Cursor、GitHub Copilot、Windsurf、CodeBuddy、Trae、通义灵码、百度 Comate、OpenCode CLI、Augment Code 等。

---

## 使用

安装后，进入任意项目目录：

```bash
cd /your-project
claude                    # 或 codex / cursor
```

输入 `/mims` 查看介绍，或 `/mims design` 直接开始。

**首次使用时**，迷悟师会询问是否在本项目中写入配置文件（CLAUDE.md / AGENTS.md），以便后续会话自动激活。你可以选择：
- **写入（推荐）** — 后续打开项目时迷悟师人设自动加载
- **仅本次** — 不写入文件，仅当前会话使用

---

## 命令列表

| 命令 | 用途 |
|------|------|
| `/mims` | 查看迷悟师介绍和命令列表 |
| `/mims design` | 启动或继续设计流程（需求建模 → 原型生成） |
| `/mims model` | 查看当前 `domain-model.yaml` 的可读摘要 |
| `/mims validate` | 验证当前模型的完整性 |
| `/mims prototype` | 直接生成 HTML 原型（需已有模型文件） |
| `/mims change` | 修改已有设计 |
| `/mims srs` | 生成软件需求规格说明书（初步设计阶段产出） |
| `/mims sdd` | 生成软件设计规格说明书（详细设计阶段产出） |

---

## 生成的文件

使用过程中，迷悟师会在项目目录下生成以下文件：

| 文件 | 说明 |
|------|------|
| `domain-model.yaml` | FBS 领域模型，对话过程中实时更新 |
| `srs.md` | 软件需求规格说明书（初步设计阶段产出） |
| `sdd.md` | 软件设计规格说明书（详细设计阶段产出） |
| `prototype/index.html` | 可交互原型入口（双击浏览器打开） |
| `prototype/workbench.html` | 流程驱动工作台（有跨角色流程时生成） |
| `prototype/*.html` | 每个功能模块的页面 |
| `prototype/feedback.md` | 评审反馈记录（在原型中记录，体验后供迷悟师读取） |

---

## 更新

重新运行安装脚本即可覆盖升级：

```bash
# Linux/macOS
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash

# Windows PowerShell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
```

**安全说明**：以下项目文件不会被安装覆盖：
- `domain-model.yaml` — 你的领域模型
- `srs.md` / `sdd.md` — 设计文档
- `prototype/` — 生成的原型
- `CLAUDE.md` / `AGENTS.md` — 项目人设文件

---

## 卸载

删除全局目录中的 MIMS 文件：

```bash
# Linux/macOS
rm -rf ~/.claude/skills/mims ~/.claude/agents/mims-*.md
rm -rf ~/.agents/skills/mims ~/.agents/agents/mims-*.md

# Windows PowerShell
Remove-Item -Recurse -Force "$HOME\.claude\skills\mims", "$HOME\.claude\agents\mims-*.md"
Remove-Item -Recurse -Force "$HOME\.agents\skills\mims", "$HOME\.agents\agents\mims-*.md"
```

项目中的 `CLAUDE.md`（含 `<!-- MIMS-START -->` 标记的段落）和设计文件需手动删除。

---

## 许可证

MIT License
