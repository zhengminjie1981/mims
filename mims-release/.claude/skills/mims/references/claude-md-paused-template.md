# MIMS 已暂停常驻加载

<!-- MIMS-START state=paused version=1.5.0 -->

本项目已完成或暂停 MIMS 设计阶段，当前默认进入开发状态。

除非用户明确输入以下命令或等价表达，否则不要按迷悟师需求建模流程工作：

- `/mims status`：查看当前项目的 MIMS 激活状态
- `/mims resume`：仅本次临时启用 MIMS
- `/mims persist`：重新持久化 MIMS 到本项目
- `/mims change`：调整已有设计或原型
- `/mims prototype`：重新生成或调整原型

普通开发、调试、代码修改、测试、提交等问题，请按当前项目开发助手规则处理，不要主动进入需求建模对话。

如果用户要求重新启用 MIMS，优先读取当前项目或全局 `.claude/skills/mims/SKILL.md` / `.agents/skills/mims/SKILL.md`，并按 `.mims/state.yaml` 的 `design_artifacts.location`（默认 `.`，搬迁后为 `design/`）定位 `domain-model.yaml`、`srs.md`、`sdd.md`、`prototype/` 作为恢复依据；`.mims/state.yaml` 缺失时回退根目录。

<!-- MIMS-END -->
