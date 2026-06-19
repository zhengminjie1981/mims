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

- 升级链路：内网 GitLab 私有库走 `/api/v4` + token 鉴权；启动器 `-fsSL` 加固；发布包附 `SHA256SUMS` 完整性校验；升级前自动快照、一键回滚；本地改动保留为 `.local`。
- 项目生命周期：`/mims status|pause|resume|persist|detach`；设计完成后可暂停进入开发状态。
- 工作产品搬迁：暂停时可选把设计产物整体搬到 `design/`，恢复时自动定位。
- 版本管理：`mims update --check` / `--edge`；`.mims-commit` 标识内容来源。

---

## 安装与更新

安装一次，所有项目可用。

如果你已经安装过 MIMS，优先使用本地更新器。更新器会默认读取 `~/.mims/install-state.json` 中记录的上次安装来源（GitHub 或 GitLab），并按该来源更新：

```powershell
& "$HOME\.mims\update.ps1"
```

Linux / macOS：

```bash
bash ~/.mims/update.sh
```

公司内网或 VPN 用户可以指定 GitLab 源：

```powershell
& "$HOME\.mims\update.ps1" -Source gitlab
```

```bash
bash ~/.mims/update.sh gitlab
```

也可以重新运行下面的安装命令来更新。更新会覆盖全局 MIMS Skill 和 Agents，但不会覆盖你项目中的设计成果：

```text
domain-model.yaml
srs.md
sdd.md
prototype/
CLAUDE.md
AGENTS.md
```

### 通过 GitHub 安装/更新

适合可以访问公网 GitHub 的用户。

#### Linux / macOS（下载到临时文件再执行）

```bash
curl -fsSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh -o /tmp/mims-install.sh && bash /tmp/mims-install.sh
```

#### Windows PowerShell

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
```

### 通过 GitLab 安装/更新（API + token）

适合公司内网或 VPN 环境用户。私有库需 token（GitLab `/raw/` 路由不认 token，必须走 `/api/v4`）。

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

设计完成进入开发阶段后，建议使用 `/mims pause` 暂停当前项目的 MIMS 常驻加载。暂停不会卸载 MIMS，也不会删除 `domain-model.yaml`、`srs.md`、`sdd.md` 或 `prototype/`；暂停时还可选择把这些设计产物整体搬到 `design/` 子目录，位置记录在 `.mims/state.yaml`，之后 `/mims resume` 或 `/mims persist` 会自动恢复、不丢进度。以后可用 `/mims resume` 临时启用，或 `/mims persist` 重新常驻启用。

开发仓库中还提供可执行校验脚本，用于发布前或调试时检查模型硬约束：

```bash
python scripts/validate-domain-model.py domain-model.yaml
python scripts/validate-domain-model.py domain-model.yaml --json
```

有 ERROR 时脚本返回退出码 1，表示模型需要修复后才能进入下一阶段。

---

## 适用范围

MIMS 最适合：

- 管理系统
- 审批流、订单流、任务流
- CRM、ERP、内部工具
- 需要先确认需求和原型的软件想法

不适合作为生产代码生成器。生成的 HTML 原型用于沟通和确认需求，不是可直接上线的系统。

---

## 发布包说明

GitHub 仓库中的 `mims-release/` 是可安装的用户产品包源。包内 README 面向下载发布包或本地源码安装的用户，包含本地安装、目录结构和卸载说明。

## License

MIT License
