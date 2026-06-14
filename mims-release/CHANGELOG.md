# Changelog

MIMS 版本与内容变更记录。每条目按版本（对应 `mims-release/.mims-version`，三段式语义化版本）组织，并标注内容来源提交（`.mims-commit`）。

`mims update` 升级后会展示与本地旧版本之间的变更。

---

## 1.5.1 — 生命周期脚本 + pause/persist 加固 + 发布对称化

**内容提交**：见同目录 `.mims-commit`。

### 生命周期脚本化（B4）
- 新增 `scripts/mims-lifecycle.py`（pause/persist/detach/status/resume）：所有文件改写在脚本内完成（按标记行 splice，不经 Edit/Write），根治多字节 Edit 失配与 read-tracking 问题。内置 block 外残留扫描、old-style 迁移、粒度判定（整文件 vs block-only，保守）、工作产品搬迁、`.mims/state.yaml` 读写、产物体检。安装器将其装到 `~/.mims/`。

### pause/persist 加固
- **managed block 完整性**：active 模板的全部 MIMS 内容（标题、人设、待机指令、Bootstrap）收进 managed block，block-only 替换永远完备，不再在 block 外留与暂停矛盾的残文。
- **设计产物指引（Q2）**：paused stub 增加"设计产物（开发前请先阅读）"段，按 `design_artifacts.location` 指引 `srs.md`/`sdd.md`/`prototype/`/`domain-model.yaml`。
- **暂停下可升级**：任何显式 `/mims` 命令（含 `/mims update`）在暂停下都响应；升级是全局操作，不影响项目暂停状态。
- **resume/persist 同步**：persist 在 detach（无 block）后追加 active block（不破坏用户内容）；`persist --move-root` 可搬回根目录（与 `pause --move-design` 对称）；resume 读取并展示 `design_phase`/`current_step`。

### 发布对称化 + 安装器韧性
- 新增统一发布入口 `scripts/release.sh`：一次调用对称发布 GitLab + GitHub，统一 `RELEASE_COMMIT`、版本一致性检查、非交互模式；`release-to-gitlab.sh` 自带 tag。**修复 v1.5.0 GitLab 端漏跑 stamping 导致的 `.mims-commit`/`SHA256SUMS` 缺失。**
- 安装器（bash + ps1 对等）清理 legacy `~/.mims/backup-*`；artifacts 缺失时给出明确提示（edge/源码包不带 SHA256SUMS/.mims-commit）。

### 版本规则
- 三段式语义化版本（`^\d+\.\d+(\.\d+)?$`）。

### 此前累积成果（v1.5.0 期间）
- 升级链路加固（GitLab API + token、`-fsSL` bootstrap、快照/回滚、本地改动保护）。
- MIMS 项目激活状态机制（active/paused/detached/absent）。
- 工作产品搬迁与恢复定位（`design_artifacts.location`）。
- 原型评审工具、适用性边界、DomainLite 集成准备、D4.5 语义覆盖、附件类需求、Codex 兼容收口等。

> 完整历史见 `docs/progress/PROJECT_PROGRESS.md`。

---

## 1.5.0 — 升级链路加固 + 项目生命周期 + 工作产品搬迁

**内容提交**：见同目录 `.mims-commit`。

### 升级链路（P0+P1）
- **内网 GitLab 私有库可用**：升级与首装支持 GitLab API + token 鉴权（`/api/v4/projects/...`），解决 `/raw/` web 路由在私有库 401/404 的问题。token 经 `~/.mims/config` 或 `MIMS_TOKEN` 注入，不进命令行参数。
- **启动器加固**：`curl|bash` 改为 `-fsSL` + 下载到临时文件 + 校验 `#!` 头，HTTP 错误页不再被当脚本执行；全部 curl 加超时防挂死。
- **版本与内容解耦**：新增 `.mims-commit` 标识内容来源提交；`mims update --check` 比对本地与远端 commit；`mims update --edge` 直接拉 main HEAD，`mims update` 默认跟最新 release tag。
- **完整性校验**：发布包附 `SHA256SUMS`，安装前逐文件校验，失败即中止（skill 文件会变成 prompt/指令，完整性属 prompt 注入攻击面）。
- **备份与回滚**：升级前自动快照到 `~/.mims/snapshots/<ts>/`，保留最近 5 份；`rollback.sh` / `rollback.ps1` 一键回滚。
- **本地改动保护**：与上次安装基线比对，用户改过的文件保留为 `<file>.local`，不静默覆盖。
- **PowerShell 对等**：Windows 与 Linux/macOS 升级能力一致。

### 项目生命周期
- MIMS 项目激活状态机制：`/mims status` / `pause` / `resume` / `persist` / `detach`。区分安装来源与项目激活状态；设计完成后可暂停项目级 MIMS 常驻加载进入开发状态，需要时再恢复。
- 工作产品搬迁：`.mims/state.yaml design_artifacts.location` 作为模型位置外部指针；模型内部路径相对模型目录解析；`/mims pause` 可选把 `domain-model.yaml` / `srs.md` / `sdd.md` / `prototype/` 整体搬到 `design/` 且不改写内部路径，resume/persist 自动定位。

### 版本规则
- MIMS 与 `domain-model.yaml` 的 `metadata.version` 均改为支持三段式语义化版本（`^\d+\.\d+(\.\d+)?$`）。本版本起 MIMS 采用三段式版本号。

### 此前累积成果（v1.4 期间）
- 原型评审工具、适用性边界检测、DomainLite 集成准备。
- D4.5 P→D 语义覆盖扫描、附件类需求建模。
- Codex 兼容收口、文档生成保障、YAML 描述收紧、结构性缺口补齐、原型生成质量保障。

> 完整历史见 `docs/progress/PROJECT_PROGRESS.md`。
