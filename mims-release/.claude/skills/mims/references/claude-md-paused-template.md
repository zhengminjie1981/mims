<!-- MIMS-START state=paused version=1.5.4 -->
# MIMS 已暂停常驻加载

本项目已完成或暂停 MIMS 设计阶段，当前默认进入**开发状态**。

## 设计产物（开发前请先阅读）

设计阶段的产出是开发的输入。位于 `.mims/state.yaml` 中 `design_artifacts.location` 指向的目录（默认当前目录；`/mims pause` 搬迁后为 `design/`）。开发前请先阅读：

- `srs.md`（软件需求规格）、`sdd.md`（软件设计规格）—— 开发依据，实现前必读
- `prototype/`（可点击 HTML 原型）—— 界面与交互参考，浏览器直接打开 `index.html`
- `domain-model.yaml`（结构化领域模型）—— 对象 / 属性 / 状态 / 操作 / 规则 / 权限的权威来源，需精确对照时查阅

## 行为规则

除非用户**明确**输入以下命令或等价表达，否则不要按迷悟师需求建模流程工作，按当前项目开发助手规则处理普通开发、调试、代码、测试、提交问题：

- `/mims status`：查看当前 MIMS 激活状态
- `/mims model`：查看当前模型摘要（只读）
- `/mims update`：升级 MIMS（见下，暂停状态下可用）
- `/mims resume`：仅本次临时启用 MIMS
- `/mims persist`：重新持久化 MIMS 到本项目
- `/mims change`：调整已有设计或原型
- `/mims prototype`：重新生成或调整原型

## 升级 MIMS（暂停状态下也可用）

升级更新的是**全局** MIMS Skill/Agents（`~/.claude`、`~/.agents`、`~/.mims`），**不影响本项目的暂停状态**，也不改写本文件。升级方式：

- Linux/macOS：`bash ~/.mims/update.sh`
- Windows：`& "$HOME\.mims\update.ps1"`
- 内网 GitLab：`bash ~/.mims/update.sh --from gitlab`（需 `MIMS_TOKEN`）

升级后本项目仍保持 paused；要恢复 MIMS 工作请用 `/mims resume`（临时）或 `/mims persist`（重新常驻）。

## 恢复 MIMS

如果用户要求重新启用 MIMS，优先读取当前项目或全局 `.claude/skills/mims/SKILL.md` / `.agents/skills/mims/SKILL.md`，并按 `.mims/state.yaml` 的 `design_artifacts.location`（默认 `.`，搬迁后为 `design/`）定位 `domain-model.yaml`、`srs.md`、`sdd.md`、`prototype/` 作为恢复依据；`.mims/state.yaml` 缺失时回退根目录。
<!-- MIMS-END -->
