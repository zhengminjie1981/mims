# codex-runtime.md — Codex 运行协议

> 本文件定义 MIMS 在 Codex 或其他不稳定支持 Skill/子代理的宿主中的执行协议。
> 目标不是让 Codex 模拟 Claude Code 的内部机制，而是确保 MIMS 的核心约束可加载、可降级、可验证、可追溯。

---

## 1. 触发入口

Codex 下以下输入均等价于 `/mims design`：

- 请用 MIMS 帮我开始需求建模
- 帮我梳理一个系统设计
- 我想做一个系统，帮我整理需求
- 按迷悟师的方式继续
- 用户直接描述产品想法、业务流程、管理系统需求或原型需求

Lifecycle 类输入按对应命令处理：

| 用户表达 | 等价命令 |
|---|---|
| 查看 MIMS 状态 / 当前是否启用迷悟师 | `/mims status` |
| 暂停 MIMS 常驻 / 进入开发状态 / 不要常驻迷悟师 | `/mims pause` |
| 临时恢复 MIMS / 本次启用迷悟师 | `/mims resume` |
| 重新启用 MIMS / 持久化迷悟师 | `/mims persist` |
| 移除 MIMS 入口 / 完全退出迷悟师常驻 | `/mims detach` |

触发后必须执行完整 MIMS 初始化、规则加载、恢复、验证和落盘流程，不得只按普通对话总结需求。

如果项目入口 managed block 为 `state=paused`，普通产品描述、业务讨论或开发问题不得自动进入 MIMS；任何用户显式 `/mims` 命令（含 `status`/`model`/`update`/`resume`/`persist`/`change`/`prototype`）或明确"按 MIMS/迷悟师继续"都应被响应。`/mims update` 升级全局 Skill，不影响暂停状态。

---

## 2. 规则加载顺序

Codex 触发 MIMS 后，按以下顺序加载：

1. 当前项目或全局 `.agents/skills/mims/SKILL.md`
2. 若 `.agents` 不存在，读取 `.claude/skills/mims/SKILL.md`
3. 检测安装来源：全局路径存在为 `global`，项目路径存在为 `project`，两者都有为 `both`，都没有为 `none`
4. 检测项目激活状态：解析 `CLAUDE.md` / `AGENTS.md` 的 `<!-- MIMS-START ... -->` managed block；无 state 的旧 block 视为 `active`，`state=paused` 时不主动进入设计流程，但响应任何显式 `/mims` 命令（含 `update`）
5. 定位工作产品：读 `.mims/state.yaml` 的 `design_artifacts.location`（默认 `.`），在 `{location}/domain-model.yaml` 查找；缺失则回退根目录。后续 srs/sdd/prototype 均按 `{location}/` 解析
6. `references/schema-contract.md`
7. `references/schema.md`
8. `references/workflow-common.md`
9. 当前阶段对应 workflow：
   - P 阶段：`workflow-preliminary.md`
   - D 阶段：`workflow-detailed.md`
   - R 阶段：`workflow-prototype.md`
10. 需要执行验证、文档、原型或变更时，读取对应 `agents/mims-*.md`

如果无法读取 `schema-contract.md` 或 `schema.md`，不得生成或修改结构化 `domain-model.yaml`。

---

## 3. 子代理 Fallback

Codex 无法委托 `mims-*` 子代理时，主 Agent 必须读取对应 agent 文件并在当前上下文执行同等规则。

| 任务 | 子代理 | Fallback 要求 |
|---|---|---|
| 模型验证 | `mims-validator` | 读取 validator 规则，输出同等验证报告，并写入 `metadata.validation` |
| 文档生成 | `mims-spec-generator` | 读取 spec-generator 和模板，基于已验证模型生成 SRS/SDD |
| 原型生成 | `mims-prototyper` | 读取 prototyper 规则，生成相对路径 `prototype/` 文件 |
| 变更分析 | `mims-change-manager` | 读取 change-manager 规则，输出变更级别、影响范围和验证建议 |

Fallback 不是跳过；若只能执行简化检查，必须告诉用户当前能力边界，且不得让阶段通过 gate。

---

## 4. Validation Gate

P6、D5、R8/R9 检查点必须产生 validation_result：

```yaml
metadata:
  validation:
    preliminary:
      status: passed | failed | warnings
      method: subagent | fallback-manual | script
      checked_at: "2026-05-27T10:00:00Z"
      error_count: 0
      warning_count: 0
      issues: []
```

阶段状态只能由 validation_result 推导：

| validation_result | 阶段状态 |
|---|---|
| 缺失 | `pending` 或 `in_progress` |
| `error_count > 0` 或 `status: failed` | `in_progress` |
| `error_count = 0` 且 `warning_count > 0` | `complete_with_warnings` |
| `error_count = 0` 且 `warning_count = 0` | `complete` |

禁止直接把阶段写成 `complete`。

---

## 5. 可执行校验脚本

开发仓库提供校验脚本：

```bash
python scripts/validate-domain-model.py domain-model.yaml
python scripts/validate-domain-model.py domain-model.yaml --json
```

Codex fallback 中如可访问该脚本，应优先使用 `method: script` 记录结果；否则使用 `fallback-manual`。

脚本有 ERROR 时退出码为 `1`，这是预期行为。调用方应读取报告，而不是把非零退出码当作工具失败。

---

## 6. 文档生成规则

- `srs.md` 只能在 `metadata.validation.preliminary.error_count = 0` 后生成。
- `sdd.md` 只能在 `metadata.validation.detailed.error_count = 0` 后生成。
- 文档必须基于已验证的 `domain-model.yaml`，不得只根据聊天摘要生成。
- 文档中涉及角色、场景、流程、模块、对象、状态、操作、规则时，必须保留模型 id 或 name，方便反查一致性。

---

## 7. 原型路径规则

默认原型目录：

```text
prototype/
```

`output_dir` 相对 `domain-model.yaml` 所在目录解析；`domain-model.yaml` 的位置由 `.mims/state.yaml` 的 `design_artifacts.location` 决定（默认 `.` = 项目根，`/mims pause` 搬迁后为 `design/`）。因此实际原型目录为 `{location}/{output_dir}`。

允许用户项目已有约定目录：

```yaml
metadata:
  prototype_plan:
    output_dir: "doc/proto/"
    path_policy:
      type: "relative"
      override_reason: "user_project_existing_convention"
```

禁止在 `domain-model.yaml` 中保存绝对路径，例如：

- `D:/...`
- `E:\\...`
- `/Users/...`
- `/home/...`

---

## 8. 恢复规则

恢复会话时只读取项目文件，不依赖聊天历史。先按发现顺序定位 `domain-model.yaml`：

1. 读 `.mims/state.yaml` → 取 `design_artifacts.location`（缺失视为 `.`）
2. 检查 `{location}/domain-model.yaml` → 命中则使用该 location
3. 回退：检查根目录 `domain-model.yaml`（兼容旧项目）

定位后，按 `{location}/` 解析以下恢复输入：

1. `{location}/domain-model.yaml`
2. `metadata.design_progress`
3. `metadata.validation`
4. `{location}/srs.md`
5. `{location}/sdd.md`
6. `{location}/{metadata.prototype_plan.output_dir 或 prototype/}`

如果聊天记忆与文件冲突，以文件为准，并向用户说明差异。

---

## 9. 失败处理

| 失败情况 | 处理 |
|---|---|
| 找不到 Skill | 尝试读取 references；仍失败则停止 MIMS 结构化输出 |
| 找不到 schema-contract/schema | 不生成或修改 `domain-model.yaml` |
| 找不到 validator | 执行最小结构检查，但不得让阶段通过 gate |
| 文档生成前无 validation | 先执行对应验证 |
| 原型路径为绝对路径 | 改为相对路径并记录 override 原因，或询问用户 |

---

## 10. Codex 通过标准

一次 Codex 运行可视为有效，必须满足：

1. 自然语言触发进入 MIMS。
2. 生成或修改模型前应用 Schema 契约。
3. 子代理不可用时执行 fallback。
4. P6、D5、R8/R9 有 validation_result。
5. 阶段状态由 validation_result 推导。
6. SRS/SDD 基于无 ERROR 模型生成。
7. 原型路径为相对路径。
