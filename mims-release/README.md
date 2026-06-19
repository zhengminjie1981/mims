# MIMS - Make Idea Make Sense

> 迷悟师：通过对话帮助非技术用户完成软件设计、文档生成和可交互原型。

**版本**：1.6.0

---

## 其他语言

- [English](https://github.com/zhengminjie1981/mims/blob/main/README_EN.md)
- [繁體中文](https://github.com/zhengminjie1981/mims/blob/main/README_ZH_TW.md)
- [日本語](https://github.com/zhengminjie1981/mims/blob/main/README_JA.md)
- [한국어](https://github.com/zhengminjie1981/mims/blob/main/README_KO.md)
- [Français](https://github.com/zhengminjie1981/mims/blob/main/README_FR.md)
- [Español](https://github.com/zhengminjie1981/mims/blob/main/README_ES.md)

---

## MIMS 是什么

MIMS 是一个可安装到 Claude Code、Codex、Cursor 等 AI 编程工具中的设计助手。它会通过自然语言对话，引导你把一个模糊的软件想法逐步整理成：

- `domain-model.yaml`：结构化领域模型
- `srs.md`：软件需求规格说明书
- `sdd.md`：软件设计说明书
- `prototype/`：可直接在浏览器打开的 HTML 原型

你不需要会写代码，也不需要懂软件设计术语。

MIMS v1.6.0 带来升级链路加固与项目生命周期管理：

- 升级链路：内网 GitLab 私有库走 `/api/v4` + token 鉴权；启动器 `-fsSL` 加固并校验脚本头；发布包附 `SHA256SUMS` 完整性校验；升级前自动快照、一键回滚；本地改动保留为 `.local` 不静默覆盖。
- 项目生命周期：`/mims status|pause|resume|persist|detach` 控制当前项目是否常驻加载 MIMS；设计完成后可暂停进入开发状态，需要时再恢复。
- 工作产品搬迁：暂停时可选把 `domain-model.yaml`、`srs.md`、`sdd.md`、`prototype/` 整体搬到 `design/`，恢复时自动定位，不丢进度。
- 版本管理：`mims update --check` 检查是否最新、`--edge` 跟随 main；`.mims-commit` 标识内容来源提交。

---

## 发布包结构

`mims-release/` 是 MIMS 的用户产品包源。这个目录可以由安装脚本读取，也可以随 GitHub 发布包一起下载。

```text
mims-release/
├── README.md              # 发布包内部说明
├── README_GITHUB.md       # GitHub 首页 README 源
├── README_*.md            # 多语言用户 README
├── CLAUDE.md              # Claude Code 项目入口模板
├── AGENTS.md              # Codex 项目入口模板
├── .mims-version
└── .claude/
    ├── skills/mims/
    └── agents/
```

`.claude/` 是当前发布包的内部源目录，不表示 MIMS 只支持 Claude Code。安装脚本会自动把同一套 Skill 和 Agent 安装到：

- Claude Code：`~/.claude/`
- Codex：`~/.agents/`

Codex 用户不需要手动处理 `.claude/` 目录。

---

## 安装与更新

安装一次，所有项目可用。

如果你已经安装过 MIMS，优先使用本地更新器。更新器会读取 `~/.mims/install-state.json` 和 `~/.mims/config` 决定来源，并支持版本检查与跟随主线：

```powershell
& "$HOME\.mims\update.ps1"                 # 默认跟最新 release tag
& "$HOME\.mims\update.ps1" -Check          # 只检查是否最新，不下载
& "$HOME\.mims\update.ps1" -Edge           # 直接拉 main HEAD
```

Linux / macOS：

```bash
bash ~/.mims/update.sh                     # 默认跟最新 release tag
bash ~/.mims/update.sh --check             # 只检查
bash ~/.mims/update.sh --edge              # 拉 main HEAD
```

公司内网或 VPN 用户可以指定 GitLab 源（私有库需配置 token，见下文）：

```powershell
& "$HOME\.mims\update.ps1" -SourceKind gitlab
```

```bash
bash ~/.mims/update.sh --from gitlab
```

更新器会先下载安装脚本到临时文件、校验是脚本而非错误页再执行（`-fsSL` 加固）。每次升级前自动快照当前安装到 `~/.mims/snapshots/<时间戳>/`（保留最近 5 份），升级失败或想退回时可回滚：

```powershell
& "$HOME\.mims\rollback.ps1"               # 回滚到最近一次快照
& "$HOME\.mims\rollback.ps1" -Timestamp 20260614080000
```

```bash
bash ~/.mims/rollback.sh                   # 默认最近
bash ~/.mims/rollback.sh 20260614080000    # 指定快照
```

若你修改过 MIMS 自带文件（如某 reference），升级会自动把它保留为 `<文件>.local` 并提示你手动合并，不静默覆盖。

也可以重新运行下面的安装命令来更新。更新前安装脚本会检查 Claude Code 与 Codex 两端的全局安装状态，包括版本是否一致、关键文件是否缺失、是否存在旧版 `mims-*` Agent 或废弃 reference 文件。

如果检查发现残留或不一致，脚本会提示你选择：

1. 继续覆盖更新
2. 清理全局 MIMS 后更新
3. 退出，不修改文件

清理范围仅限 MIMS 管理的全局安装位置：

```text
~/.claude/skills/mims/
~/.claude/skills/mims.old-*、mims.backup-* 等重复 MIMS Skill 目录
~/.claude/agents/mims-*.md
~/.agents/skills/mims/
~/.agents/skills/mims.old-*、mims.backup-* 等重复 MIMS Skill 目录
~/.agents/agents/mims-*.md
~/.agents/AGENTS.md
~/.mims/update.ps1
~/.mims/update.sh
~/.mims/rollback.ps1
~/.mims/rollback.sh
~/.mims/install-state.json
```

项目内文件只会提示，不会自动修改或删除。因此更新不会覆盖你项目中的设计成果：

```text
domain-model.yaml
srs.md
sdd.md
prototype/
CLAUDE.md
AGENTS.md
```

### 内网 GitLab（私有库）token 配置

GitLab 私有库的 `/raw/` web 路由不认 token，必须走 API 端点。MIMS 的安装器/更新器已改用 `/api/v4/projects/...`，token 通过 `~/.mims/config` 或环境变量 `MIMS_TOKEN` 注入，不进命令行参数（避免被 `ps` 看到）。

`~/.mims/config`（权限自动设为 0600）：

```text
source=gitlab
gitlab_token=你的私有库访问 token
```

或临时用环境变量：

```bash
export MIMS_TOKEN=xxxxx
export MIMS_SOURCE=gitlab
```

首次安装内网版时，先设好 token 再执行安装命令（见下），安装器会把 token 写入 `~/.mims/config` 供后续 `mims update` 复用。

### 通过 GitHub 安装/更新

适合可以访问公网 GitHub 的用户。

#### Linux / macOS（下载到临时文件再执行，加固版）

```bash
curl -fsSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh -o /tmp/mims-install.sh && bash /tmp/mims-install.sh
```

#### Windows PowerShell

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
```

### 通过 GitLab 安装/更新（API + token）

适合公司内网或 VPN 环境用户。私有库需 token。

#### Linux / macOS

```bash
export MIMS_TOKEN=xxxxx
curl -fsSL -H "PRIVATE-TOKEN: $MIMS_TOKEN" "https://gitlab.xyitech.com/api/v4/projects/antwork%2FCloudServer%2Fit%2FMIMS/repository/files/install%2Finstall-global.sh/raw?ref=main" -o /tmp/mims-install.sh && bash /tmp/mims-install.sh --from gitlab
```

#### Windows PowerShell

```powershell
$env:MIMS_TOKEN="xxxxx"
iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/api/v4/projects/antwork%2FCloudServer%2Fit%2FMIMS/repository/files/install%2Finstall-global.ps1/raw?ref=main'))
```

### 完整性校验

发布包内附 `SHA256SUMS`，安装前安装器会逐文件校验哈希，任何不匹配立即中止。由于 skill 文件会成为 prompt/指令，这是 prompt 注入攻击面的防护，不只是普通下载校验。

### 本地源码安装/更新

```powershell
.\install\install-global.ps1 -Source .
```

如果你已经进入 `mims-release/` 目录，也可以：

```powershell
..\install\install-global.ps1 -Source .
```

Linux / macOS：

```bash
bash install/install-global.sh --source .
```

如果当前目录是 `mims-release/`：

```bash
bash ../install/install-global.sh --source .
```

### 离线安装包

发布时会生成最小离线安装包 `mims-offline-v<版本>.zip`，内容只包含 `install/` 和 `mims-release/`。离线机器解压后，进入解压出的包根目录执行本地安装命令即可。

Windows PowerShell：

```powershell
.\install\install-global.ps1 -Source .
```

Linux / macOS：

```bash
bash install/install-global.sh --source .
```

离线升级同样使用新版离线包重新执行上述命令；不要依赖默认 `mims update`，它通常需要访问 GitHub 或 GitLab。安装或升级不会覆盖项目中的 `domain-model.yaml`、`srs.md`、`sdd.md`、`prototype/`、`CLAUDE.md` 或 `AGENTS.md`。

---

## 安装了什么

```text
~/.claude/
├── skills/mims/
└── agents/mims-*.md

~/.agents/
├── AGENTS.md
├── skills/mims/
└── agents/mims-*.md
```

Claude Code 使用 `~/.claude`，Codex 使用 `~/.agents`。安装脚本会同时写入两套目录。

---

## 开始使用

进入你的项目目录：

```bash
cd /your-project
```

在 Claude Code 中可以输入：

```text
/mims design
```

在 Codex 或其他不稳定支持 slash command 的工具中，可以直接输入：

```text
请用 MIMS 帮我开始需求建模
```

也可以说：

```text
帮我梳理一个系统设计
按迷悟师的方式继续
```

首次使用时，MIMS 会询问是否写入项目级配置：

- Claude Code：`CLAUDE.md`
- Codex：`AGENTS.md`

建议选择写入，这样后续打开项目时可以继续保持 MIMS 的对话方式。

---

## 常用命令

| 命令 | 用途 |
|------|------|
| `/mims` | 查看介绍和命令 |
| `/mims design` | 启动或继续设计流程 |
| `/mims model` | 查看当前设计摘要 |
| `/mims status` | 查看当前项目的 MIMS 激活状态 |
| `/mims validate` | 检查当前模型 |
| `/mims prototype` | 生成 HTML 原型 |
| `/mims change` | 修改已有设计 |
| `/mims srs` | 生成需求说明书 |
| `/mims sdd` | 生成设计说明书 |
| `/mims pause` | 暂停项目常驻加载，进入开发状态 |
| `/mims resume` | 仅本次临时启用 MIMS |
| `/mims persist` | 重新持久化 MIMS 到项目入口 |
| `/mims detach` | 移除项目级 MIMS 入口 |

开发仓库中还提供可执行校验脚本，用于发布前或调试时检查模型硬约束：

```bash
python scripts/validate-domain-model.py domain-model.yaml
python scripts/validate-domain-model.py domain-model.yaml --json
```

有 ERROR 时脚本返回退出码 1，表示模型需要修复后才能进入下一阶段。

---

## 工作流程

MIMS 会分三个阶段引导你：

1. **初步设计**：理清目标、用户角色、使用场景和业务流程。
2. **详细设计**：明确系统要管理的内容、信息、状态、操作和规则。
3. **原型生成**：生成可点击的 HTML 页面，用来确认想法是否落地。

中断后可以继续。MIMS 会根据项目中的 `domain-model.yaml` 恢复进度，而不是依赖聊天历史。

设计完成进入开发阶段后，建议使用 `/mims pause` 暂停当前项目的 MIMS 常驻加载。暂停只会把 `CLAUDE.md` / `AGENTS.md` 中的 MIMS managed block 替换为短提示，不会卸载全局或项目内的 MIMS，也不会删除 `domain-model.yaml`、`srs.md`、`sdd.md` 或 `prototype/`。暂停时还可以选择把这几个设计产物整体搬到 `design/` 子目录，保持根目录干净；MIMS 会把位置记录在 `.mims/state.yaml`，之后 `/mims resume` 或 `/mims persist` 会自动从该位置恢复，不丢进度。以后需要调整需求或原型时，可以用 `/mims resume` 临时启用，或用 `/mims persist` 重新常驻启用。

---

## 生成文件

| 文件 | 说明 |
|------|------|
| `domain-model.yaml` | 对话过程中持续更新的领域模型 |
| `srs.md` | 初步设计后的需求说明书 |
| `sdd.md` | 详细设计后的设计说明书 |
| `prototype/index.html` | 原型入口 |
| `prototype/workbench.html` | 流程工作台，有跨角色流程时生成 |
| `prototype/*.html` | 各功能模块页面 |

---

## 更新

重新运行安装命令即可覆盖升级。MIMS 不会覆盖你的项目设计文件：

- `domain-model.yaml`
- `srs.md`
- `sdd.md`
- `prototype/`
- 项目中的 `CLAUDE.md` / `AGENTS.md`

---

## 卸载

删除全局安装目录：

```powershell
Remove-Item -Recurse -Force "$HOME\.claude\skills\mims", "$HOME\.claude\agents\mims-*.md"
Remove-Item -Recurse -Force "$HOME\.agents\skills\mims", "$HOME\.agents\agents\mims-*.md"
```

Linux / macOS：

```bash
rm -rf ~/.claude/skills/mims ~/.claude/agents/mims-*.md
rm -rf ~/.agents/skills/mims ~/.agents/agents/mims-*.md
```

项目中的 `CLAUDE.md`、`AGENTS.md` 和设计产物需要你自行删除。

---

## 适用范围

MIMS 最适合：

- 管理系统
- 审批流、订单流、任务流
- CRM、ERP、内部工具
- 需要先确认需求和原型的软件想法

不适合作为生产代码生成器。生成的 HTML 原型用于沟通和确认需求，不是可直接上线的系统。

---

## License

MIT License
