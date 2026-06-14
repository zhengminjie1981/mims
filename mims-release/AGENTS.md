# 迷悟师（MIMS）

> 本文件由 MIMS 全局 Skill 管理。首次使用 MIMS 时会自动初始化。

输入 `/mims` 查看迷悟师介绍和可用命令。
输入 `/mims design` 开始需求建模和原型生成。
输入 `/mims status` 查看当前项目的 MIMS 激活状态。
设计完成进入开发阶段后，可输入 `/mims pause` 暂停项目常驻加载；以后可用 `/mims resume` 临时启用，或 `/mims persist` 重新常驻启用。

如果当前 Codex 环境不支持 slash command，也可以直接说：
- 请用 MIMS 帮我开始需求建模
- 帮我梳理一个系统设计
- 按迷悟师的方式继续
- 查看 MIMS 状态
- 暂停 MIMS 常驻 / 进入开发状态
- 临时恢复 MIMS / 重新启用 MIMS
- 更新 MIMS / 升级 MIMS

<!-- MIMS-START state=active version=1.5.1 -->

## Codex Runtime Bootstrap

当用户触发 `/mims`、`/mims design`，或以“需求建模、软件设计、系统设计、业务建模、做一个系统、按迷悟师继续”等自然语言触发 MIMS 时，必须按以下顺序执行：

1. **定位 MIMS 规则文件**：优先读取当前项目或全局 `.agents/skills/mims/SKILL.md`；如不存在，读取 `.claude/skills/mims/SKILL.md`。
2. **检查项目激活状态**：解析 `CLAUDE.md` / `AGENTS.md` 的 MIMS managed block；`state=paused` 时，不要主动进入 MIMS 设计流程，普通问题按开发助手规则处理。任何用户显式输入的 `/mims` 命令（`status`/`model`/`update`/`resume`/`persist`/`change`/`prototype`）都应被响应；pause 只阻止"主动进入设计对话"。`/mims update` 升级全局 Skill，不影响暂停状态。
3. **定位工作产品**：读 `.mims/state.yaml` 的 `design_artifacts.location`（默认 `.`），在 `{location}/domain-model.yaml` 查找；缺失则回退根目录。后续 srs/sdd/prototype 均按 `{location}/` 解析。
4. **加载硬约束**：在生成或修改 `domain-model.yaml` 前，必须读取：
   - `skills/mims/references/schema-contract.md`
   - `skills/mims/references/schema.md`
   - `skills/mims/references/workflow-common.md`
   - 对应阶段的 `workflow-preliminary.md`、`workflow-detailed.md` 或 `workflow-prototype.md`
5. **恢复项目状态**：按 `{location}/` 解析 `domain-model.yaml`、`srs.md`、`sdd.md`、`{output_dir}`；流程进度只以 `domain-model.yaml.metadata.design_progress` 和 `metadata.validation` 为准。
6. **执行子代理 fallback**：如果 Codex 不能委托 `mims-*` 子代理，主 Agent 必须读取 `.agents/agents/mims-*.md` 或 `.claude/agents/mims-*.md` 的规则并在当前上下文执行同等任务。
7. **强制验证 gate**：P6、D5、R8/R9 检查点必须产生 `metadata.validation` 结果；没有 validation_result 或存在 ERROR 时，不得把阶段标记为 `complete`，不得生成下一阶段文档或原型。
8. **Lifecycle 命令边界**：`/mims pause`、`/mims resume`、`/mims persist`、`/mims detach` 只管理当前项目激活状态，不卸载全局或项目内 MIMS，不删除设计产物。`/mims pause` 可选把工作产品整体搬到 `design/` 并更新 `design_artifacts.location`；`/mims persist` 不主动搬回根目录。

## Codex 失败处理

- 如果无法读取完整 Skill，但能读取 references，则进入 fallback 模式，并明确告知用户“当前为 Codex fallback”。
- 如果无法读取 `schema-contract.md` 或 `schema.md`，不得生成或修改 `domain-model.yaml` 的结构化内容，只能向用户说明缺少规则文件。
- 禁止把 `domain-model.yaml` 当作自由文本草稿；必须符合 Schema 契约。
- 禁止在模型中写入原型绝对路径；默认使用相对路径 `prototype/`。

<!-- MIMS-END -->
