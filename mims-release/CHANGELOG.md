# Changelog

MIMS 版本与内容变更记录。每条目按版本（对应 `mims-release/.mims-version`，三段式语义化版本）组织，并标注内容来源提交（`.mims-commit`）。

`mims update` 升级后会展示与本地旧版本之间的变更。

**维护纪律**：工作落地时追加到下方 `## Unreleased` 段；发版时 `./scripts/bump-version.sh <ver>` 自动把 `## Unreleased` 改名为版本号。

---

## 1.6.0 — 发布于 2026-06-19

### v1.6.0 计划内容

**用户侧**
- **加载时安装完整性自检（selfcheck）**：每次 `/mims` 加载先跑一次只读自检，覆盖两端（Claude/Codex）核心文件齐全、SKILL.md frontmatter 完整、版本一致、references/agents 对称、重复 Skill 残留（如 `mims2`）、`~/.mims` 工具链（update/rollback/lifecycle）。安装正常时静默通过；发现问题才介入，不再等到某步报错才暴露。
- **本地优先自愈**：检出可本地修复项（重复 Skill 目录、两端互恢复）先征得确认后清理并复检；本地无法解决（核心文件缺失/损坏、版本漂移、半套安装、工具链缺失）再引导联网更新或重装。删除与联网操作一律先中文提示、用户确认，绝不静默执行。
- **SRS 采纳-精炼建模**：当您已有需求文档（SRS 初稿）时，可“采纳”为 SRS 来源（`requirements.srs.source_mode = adopted_refined`），把文档中的需求抽取为候选条目，经确认/精炼后生成 `srs.md`，而不必只从模型生成。采纳模式不会静默覆盖原始文档，且仍受文档生成 Gate 约束（初步验证 `error_count=0` 后才生成/精炼，且基于已验证的 `domain-model.yaml`）；无 `requirements` 的旧模型继续按原方式从模型生成，完全兼容。

**仓库侧**
- `mims-lifecycle.py` 新增 `selfcheck` 子命令（只读/不联网/不写，输出 `[OK]/[ERROR]/[WARN]/[INFO]` + `[needs_reinstall]/[local_fixable]` 标签 + `SUMMARY`，`errors>0` 退出 1）。
- SKILL.md 入口分发后新增「安装完整性自检」节，整合原运行时自检；脚本缺失时内联最小检查兜底。
- 回归测试 `tests/test_lifecycle_selfcheck.py`：静态断言 + `MIMS_HOME` 隔离的功能测试（完整/缺 schema/重复 mims2/版本漂移/单端/frontmatter 损坏）。
- **SRS 采纳-精炼 schema**：新增 `requirements.srs` 可选顶层结构契约（schema-contract §7）：`source_mode`（model/adopted_refined/manual/external）、`adoption_status`、`candidates[]`（`req_` 前缀、`status`、`category`、`confidence`）；`metadata.version` 正式支持三段式。
- `validate-domain-model.py` 新增 SRS 采纳校验（`E_REQ_001..008`、`W_REQ_001..004`：候选字段合法性、来源引用可解析、采纳-精炼状态一致性）。
- `mims-spec-generator` / `mims-change-manager` / `mims-validator` agent 规则与 `schema` / `workflow-common` / `workflow-preliminary` / `srs-template` 配套更新，支持采纳-精炼流程。
- 回归测试 `tests/test_srs_adoption_schema.py` + `test_schema_validation.py` 扩展覆盖采纳场景。

---

## 1.5.4 — 发布于 2026-06-15

### 1.5.4 计划内容

**用户侧**
- **修复内网 GitLab 用户版本解析不准/不稳的问题**：`resolve_latest_tag` 现在按安装来源解析最新 tag。GitLab 来源走 GitLab API，不再误走 GitHub `releases/latest`，避免企业内网用户检查/升级时拿到错误来源的版本信息。
- **修复已安装版本显示不准的问题**：安装状态现在记录发布包内真实 `.mims-version`，不再使用安装器脚本硬编码版本；安装器也会把 `.mims-version` 同步到 Claude/Codex skill 目录，确保 `get_mims_version` 读取到真实安装版本。
- **修复 update 脚本自覆盖 EOF 问题**：生成 `update.sh` 时改为临时文件原子替换，避免脚本升级自身时出现 EOF/截断风险。

**仓库侧**
- Bash/PowerShell 安装器保持对等修复：来源感知 tag 解析、真实版本落盘、`.mims-version` 安装、update 脚本原子写入。

---

## 1.5.3 — 发布于 2026-06-15

### 1.5.3 计划内容

**用户侧**
- **修复 update.sh 的 `[: 缺少 "]"]` 报错**：生成的 `~/.mims/update.sh` 中 `resolve_source()` 一处 `[ ... = "auto"; }` 笔误（分号在 `[ ]` 内导致 `[` 不闭合），自 v1.5.0 起每次 `--check`/升级都打印一行错误。已修正括号顺序。良性（config 解析 source 时短路绕过，不影响功能），现不再刷错误。

**仓库侧**
- 回归测试 `test_no_malformed_bracket_in_update_heredoc`：断言安装脚本不含 `"auto";` 笔误签名，防止再犯。

---

## 1.5.2 — 发布于 2026-06-15

（下一个版本的变更追加在此处。发版时由 `bump-version.sh` 改名为 `## X.Y.Z`。）

### 1.5.2 计划内容

**用户侧**
- **lifecycle 脚本行尾修复（Windows）**：`mims-lifecycle.py` 在 pause/persist/detach 改写 `CLAUDE.md`/`AGENTS.md` 时强制写 LF，不再把行尾改成 CRLF（此前 Python 默认在 Windows 写 CRLF，会造成整文件 diff）。影响 Windows 用户每次 pause/persist。

**仓库/发布侧（开发流程，不进用户包）**
- 单一版本源：release 脚本从 `mims-release/.mims-version` 读版本，不再硬编码。
- `tests/test_version_consistency.py`：以 `.mims-version` 为真相校验所有版本引用一致。
- `scripts/bump-version.sh`：一键同步版本引用 + `## Unreleased` 改名 + 跑一致性测试。
- `scripts/release.sh`：发布前置门（测试/干净树/CHANGELOG/版本一致）+ 后置验证（两端 artifacts）。
- GitHub Release 正文从 CHANGELOG 派生（不再写死过期内容）。
- CHANGELOG `## Unreleased` 维护纪律；Tag 策略（已发布不 force 重打，修复用 patch）。

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
