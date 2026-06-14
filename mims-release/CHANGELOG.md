# Changelog

MIMS 版本与内容变更记录。每条目按版本（对应 `mims-release/.mims-version`，三段式语义化版本）组织，并标注内容来源提交（`.mims-commit`）。

`mims update` 升级后会展示与本地旧版本之间的变更。

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
