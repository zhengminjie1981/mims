# 迷悟师（MIMS）部署说明

> **Make Idea Make Sense** — 通过对话帮助非技术用户完成软件设计的 AI 引导师

---

## 🚀 快速开始

### 前提条件

已安装 [Claude Code CLI](https://claude.ai/code)，版本 ≥ 1.0

### 一键安装

#### GitHub 公开版（外部用户）

**Linux / macOS**：
```bash
cd /your-project
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-github.sh | bash
```

**Windows PowerShell**：
```powershell
cd C:\your-project
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-github.ps1'))
```

#### GitLab 企业版（内部用户）

**Linux / macOS**：
```bash
cd /your-project
curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-gitlab.sh | bash
```

**Windows PowerShell**：
```powershell
cd C:\your-project
iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-gitlab.ps1'))
```

### 手动安装

如果无法使用安装脚本：

```bash
# GitHub
git clone https://github.com/zhengminjie1981/mims.git
cd mims
cp -r impl/. /your-project/

# 或 GitLab（需要内网访问）
git clone https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS.git
cd MIMS
cp -r impl/. /your-project/
```

---

## 📖 使用方法

### 1. 启动 Claude Code

```bash
cd /your-project
claude
```

### 2. 开始对话

输入 `/mims` 启动迷悟师：

```
您：/mims

迷悟师：您好！我是迷悟师，帮您把想法变得清晰、有条理。

我们会分两个阶段完成：
1. 需求建模：通过对话逐步理清您的业务设计
2. 原型生成：基于设计生成可以直接在浏览器打开的原型

请告诉我您想做什么？
```

### 3. 按步骤对话

迷悟师会引导您完成 7 个步骤：

| 步骤 | 内容 | 示例问题 |
|------|------|----------|
| Step 0 | 需求收集 | "您想做什么系统？" |
| Step 1 | 了解背景 | "大概多少人会用？" |
| Step 2 | 角色场景 | "谁会用这个系统？" |
| Step 3 | 业务对象 | "需要管理哪些东西？" |
| Step 4 | 状态变化 | "订单有哪些状态？" |
| Step 5 | 操作规则 | "对订单能做什么操作？" |
| Step 6 | 模型验证 | 展示验证报告 |

### 4. 生成原型

建模完成后，输入：

```
您：/mims prototype
```

迷悟师会生成可交互的 HTML 原型，用浏览器打开即可查看。

---

## 🔄 升级

检查并升级到最新版本：

```bash
./upgrade.sh
```

升级到指定版本：

```bash
./upgrade.sh --version 1.2.0
```

---

## 📂 安装后目录结构

```
your-project/
├── .mims-version                  ← 版本标识（勿删）
├── CLAUDE.md                      ← 迷悟师人设（自动注入）
├── README.md                      ← 本文档
├── USER_GUIDE.md                  ← 完整用户手册
└── .claude/
    ├── agents/
    │   ├── mims-validator.md      ← 模型验证子代理
    │   └── mims-prototyper.md     ← 原型生成子代理
    └── skills/mims/
        ├── SKILL.md               ← 需求建模工作流
        └── references/            ← 知识库（按需加载）
            ├── schema.md                  ← 数据结构规范
            ├── schema-examples.md         ← 示例数据集
            ├── prompt-ref.md              ← 提示词模板
            ├── change-rules.md            ← 变更管理规则
            └── workflow-step0.5.md        ← 资料处理流程
```

---

## 🎯 常用命令

| 命令 | 用途 |
|------|------|
| `/mims` | 查看介绍和命令列表 |
| `/mims design` | 启动设计流程 |
| `/mims model` | 查看当前模型 |
| `/mims validate` | 验证模型质量 |
| `/mims prototype` | 生成原型 |
| `/mims change` | 修改已有设计 |

---

## ❓ 常见问题

### Q: 安装后看不到 `/mims` 命令？

1. 确认 `CLAUDE.md` 在项目根目录
2. 确认 `.claude/skills/mims/SKILL.md` 存在
3. 重启 Claude Code

### Q: 如何查看当前版本？

```bash
cat .mims-version
```

### Q: 如何卸载？

删除以下文件和目录：
- `CLAUDE.md`
- `README.md`
- `USER_GUIDE.md`
- `.mims-version`
- `.claude/` 目录

### Q: 升级会丢失我的自定义配置吗？

升级脚本会自动备份 `.claude/agents/` 和 `.claude/skills/` 中的自定义文件，升级后可手动合并。

---

## 📚 更多文档

- **用户手册**：`USER_GUIDE.md` — 完整的使用指南（822 行）
- **项目主页**：https://github.com/your-username/MIMS

---

## 📄 许可证

MIT License

---

**版本**：1.1.0 | **更新日期**：2026-03-26

```
/mims design
```

迷悟师会通过两个阶段引导你完成设计：需求建模（对话引导）和原型生成（自动生成可交互 HTML）。

### 辅助命令

| 命令 | 功能 |
|------|------|
| `/mims` | 查看迷悟师介绍和可用命令 |
| `/mims design` | 启动或继续设计流程 |
| `/mims model` | 查看当前 `domain-model.yaml` 的可读摘要 |
| `/mims validate` | 手动验证当前模型的完整性 |
| `/mims prototype` | 跳过建模步骤，直接生成 HTML 原型（需已有 yaml） |
| `/mims change` | 主动进入变更管理流程 |

### 生成的文件

| 文件 | 说明 |
|------|------|
| `domain-model.yaml` | FBS 领域模型，对话过程中实时更新（含 source_materials 字段记录资料信息） |
| `conversation.md` | 对话历史和决策记录 |
| `prototype/index.html` | 可交互原型入口（双击即可在浏览器打开） |
| `prototype/*.html` | 每个功能模块的列表页 |
| `prototype/styles.css` | 原型样式 |
| `prototype/app.js` | 原型交互逻辑和模拟数据 |

---

## 常见问题

**Q：迷悟师和 Claude 普通对话有什么区别？**

A：安装 MIMS 后，Claude 会以"迷悟师"身份与你对话。它专注于引导你完成软件设计，使用日常语言（不用技术术语），一次只问一个问题，确保你的想法被准确记录为结构化模型。

**Q：`/mims` 没有反应怎么办？**

A：确认 `CLAUDE.md` 文件在项目根目录，且 `.claude/skills/mims/SKILL.md` 存在。重启 Claude Code 后重试。

**Q：原型可以直接用于生产吗？**

A：不可以。原型使用模拟数据，零后端，仅用于需求验证和演示。生产系统需要根据 `domain-model.yaml` 另行开发。

**Q：设计到一半需要修改之前的内容怎么办？**

A：直接告诉迷悟师"我想修改…"，它会识别变更级别（轻微/局部/中等/重大），告知影响范围后执行修改。也可以输入 `/mims change` 主动进入变更流程。

**Q：`domain-model.yaml` 能手动编辑吗？**

A：可以。文件是标准 YAML，手动编辑后用 `/mims validate` 检查一致性。Schema 规范见 `.claude/skills/mims/references/schema.md`。

**Q：迷悟师支持引用本地参考资料吗？**

A：支持。在 Step 0 时，迷悟师会询问您是否有需求文档、产品说明书等资料。您只需提供资料的**本地路径**（如 `E:\docs\prd.pdf`），迷悟师会读取并提取关键信息。

支持的资料类型包括：
- 文档（PDF、Word、Markdown）
- 图片（界面截图、流程图）
- 网页（产品文档 URL）
- 文本（直接粘贴）

**注意**：迷悟师记录的是资料路径，如果资料文件被移动或删除，迷悟师将无法找到该资料。

**Q：提供的资料会被如何使用？**

A：迷悟师会读取资料内容，提取关键信息（用户角色、业务对象、业务规则等）并生成摘要供您确认。资料路径和提取的信息存储在 `domain-model.yaml` 的 `source_materials` 字段中。原始资料文件仍在您的本地路径，不会被修改。

---

## 适用场景

- 非技术产品经理整理产品需求
- 创业者验证业务模型
- 业务分析师与开发团队对齐需求
- 学生学习软件设计方法

## 不适用场景

- 技术架构设计（微服务、数据库选型等）
- 生产级代码生成
- 已有代码的逆向分析
