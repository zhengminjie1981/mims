# schema-contract.md — MIMS 硬约束契约

> 本文件是 `schema.md` 的短版执行契约，用于 Codex、Claude Code 和其他宿主在上下文有限或子代理不可用时执行硬约束校验。
> 生成或修改 `domain-model.yaml` 前必须先读取本文件；完整字段说明仍以 `schema.md` 为准。

---

## 1. 顶层硬约束

`domain-model.yaml` 必须包含：

```yaml
metadata:
domain:
  modules:
  objects:
function:
  actors:
  scenarios:
```

硬性规则：

- `metadata.modeling_approach` 必须固定为 `"FBS"`，不得写成 `"MIMS"` 或其他值。
- `metadata.version` 必须匹配 `^\d+\.\d+$`，例如 `"1.0"`，不得写成 `"0.1-draft"`。
- `metadata.last_updated` 必须为 ISO 8601 时间字符串。
- 所有列表元素的 `id` 在同类内必须唯一。
- 引用一律使用规范字段要求的标识，不得混用中文名、英文名和 id。

---

## 2. ID 与命名硬约束

| 元素 | id 前缀 | 示例 | name 规则 |
|---|---|---|---|
| Module | `mod_` | `mod_001` | PascalCase + `Module` |
| Object | `obj_` | `obj_001` | PascalCase |
| State | `st_` | `st_001` | snake_case |
| Transition | `tr_` | `tr_001` | — |
| Operation | `op_` | `op_001` | snake_case |
| Rule | `rule_` | `rule_001` | — |
| Actor | `actor_` | `actor_001` | snake_case |
| Scenario | `sc_` | `sc_001` | snake_case |
| Process | `proc_` | `proc_001` | snake_case |
| External Interface | `ext_` | `ext_001` | snake_case |
| Report | `rpt_` | `rpt_001` | snake_case |
| Decision | `dec_` | `dec_001` | — |

禁止：

- `act_001`、`scenario_001`、`object_001`、`operation_001` 等非规范前缀。
- 同一类元素出现重复 id。
- 引用处一会儿写中文名、一会儿写英文名。

---

## 3. 类型系统硬约束

新模型属性类型只能使用：

```text
string, integer, decimal, date, datetime, boolean, enum, reference
```

兼容但不推荐：

```text
number
```

禁止在新模型中使用：

```text
text, money, attachment, table, percent, multi_select, file, image, blob
```

映射建议：

| 非规范类型 | 改为 |
|---|---|
| `text` | `string`，长文本用 `data_dictionary.max_length` 表达 |
| `money` | `decimal`，金额小数位用 `data_dictionary.scale: 2` |
| `percent` | `decimal` |
| `multi_select` | `enum`，多选语义写入说明或拆对象 |
| `attachment` / `file` / `image` | 不作为属性类型使用。简单附件用 `string` 存文件路径/URL；复杂附件建独立 Object + relationship |
| `table` | 拆成独立 Object + relationship |

附件类需求标准模式：

- 简单附件：仅需记录一个文件路径、图片地址或合同链接时，用 `type: string`，字段名建议以 `_url`、`_path` 或 `_file_url` 结尾，`data_dictionary.format` 写明“文件路径/URL”。
- 复杂附件：存在多个文件、上传人/上传时间、分类、版本、审核、独立权限或删除/替换记录时，必须建独立对象（如 `OrderAttachment`、`InvoiceFile`、`InspectionPhoto`），再与主业务对象建立 1:N 关系。
- 附件操作必须建模为 `operations[]`，例如上传、预览、下载、删除、替换；格式、大小、数量、必填、权限和状态限制应进入 `rules[]` 或 `validations[]`。

---

## 4. S 层硬约束

### Module

- `id`、`name`、`chinese_name` 必填。
- `depends_on` 必须构成无环有向图。
- 模块级 `relationships` 只放 N:M 关系。
- 模块级关系必须有 `chinese_label`。

### Object

- `id`、`name`、`chinese_name` 必填。
- 每个核心对象必须至少有一个 `primary_key: true` 的属性。
- 每个对象建议至少 2 个属性；不足时应记录为 WARNING。
- `attributes[].name` 必须为 snake_case。
- `attributes[].type` 必须属于类型系统允许集合。
- 对象级 `relationships[].to` 必须引用存在的 `domain.objects[].name`。
- 对象级 `relationships[].chinese_label` 必填。

---

## 5. B 层硬约束

### State

- 每个 `states[]` 元素必须有 `id`、`name`、`chinese_name`。
- 有状态的对象必须有且仅有一个 `is_initial: true`。
- `is_final: true` 的状态不能出现在任何 `transitions[].from_state` 中。
- 同一对象内 `states[].name` 必须唯一。

### Transition

- 每个 `transitions[]` 元素必须有 `id`、`from_state`、`to_state`、`trigger_operation`。
- 禁止使用 `operation` 代替 `trigger_operation`。
- `from_state` 和 `to_state` 必须引用同一对象内存在的 `states[].name`。
- `trigger_operation` 必须引用同一对象内存在的 `operations[].name`。

### Operation / Rule

- 每个 `operations[]` 元素必须有 `id`、`name`、`chinese_name`。
- 同一对象内 `operations[].name` 必须唯一。
- `operations[].rules[].ref` 必须引用同一对象内存在的 `rules[].id`。
- 每个关键操作应至少有 `success` 响应；缺失时至少记录 WARNING。

---

## 6. F 层硬约束

### Actor

- 每个 `actors[]` 元素必须有 `id`、`name`、`chinese_name`、`description`。
- `id` 必须使用 `actor_` 前缀。
- `scenarios[].actors[]` 和 `processes[].actors[]` 必须引用 `actors[].name`，不得引用中文名或 actor id。

### Scenario

- 每个 `scenarios[]` 元素必须有 `id`、`name`、`chinese_name`、`description`、`actors`。
- `id` 必须使用 `sc_` 前缀且不能重复。
- `actors[]` 中每个值必须存在于 `function.actors[].name`。
- `workflow[].actor` 如填写，也必须引用 `function.actors[].name`。

### Process

- 每个 `processes[]` 元素必须有 `id`、`name`、`chinese_name`、`parent_scenario`、`description`、`actors`、`start_condition`、`end_condition`、`steps`。
- `parent_scenario` 必须引用存在的 `function.scenarios[].id`。
- `actors[]` 和 `steps[].actor` 必须引用 `function.actors[].name`。
- `steps[].module` 如填写，必须引用 `domain.modules[].name`。
- `steps[].objects[]` 如填写，必须引用 `domain.objects[].name`。

---

## 7. 阶段 Gate 硬约束

阶段完成状态不得手工“乐观写入”。必须由验证结果推导。

### validation_result 必填规则

P6、D5、R8/R9 检查点必须在 `metadata.validation` 下记录结果：

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
    detailed:
      status: passed | failed | warnings
      method: subagent | fallback-manual | script
      checked_at: "2026-05-27T10:00:00Z"
      error_count: 0
      warning_count: 0
      issues: []
    prototype:
      status: passed | failed | warnings
      method: subagent | fallback-manual | script
      checked_at: "2026-05-27T10:00:00Z"
      error_count: 0
      warning_count: 0
      issues: []
  documents:
    srs:
      generated: false
      generated_at: null
      file_path: "srs.md"
    sdd:
      generated: false
      generated_at: null
      file_path: "sdd.md"
    prototype:
      generated: false
      generated_at: null
      output_dir: "prototype/"
```

### 状态推导规则

- `validation.*.status = failed` 或 `error_count > 0` → 对应阶段不得标记 `complete`。
- `status = passed` 且 `error_count = 0` 且对应文档已生成 → 可标记 `complete`。
- `status = passed` 且 `error_count = 0` 但对应文档未生成 → 标记 `complete_with_warnings`，并在 `issues` 中记录 `{code: "W_DOC_001", message: "验证通过但文档未生成", severity: "warning"}`。
- `status = warnings` 且 `error_count = 0` → 可标记 `complete_with_warnings`，并向用户说明待补充项。
- 没有对应 `validation_result` → 阶段只能是 `pending` 或 `in_progress`。

文档完整性要求：
- `preliminary` 阶段完成需要 `metadata.documents.srs.generated = true`。
- `detailed` 阶段完成需要 `metadata.documents.sdd.generated = true`。
- `prototype` 阶段完成需要 `metadata.documents.prototype.generated = true`。

### 文档生成 Gate

- `srs.md` 只能在 `metadata.validation.preliminary.error_count = 0` 后生成。
- `sdd.md` 只能在 `metadata.validation.detailed.error_count = 0` 后生成。
- 文档生成必须基于已验证的 `domain-model.yaml`，不得只根据聊天摘要生成。
- 文档生成成功后，必须将 `metadata.documents.<type>.generated` 设为 `true`，并写入 `generated_at` 时间戳。

---

## 8. 原型路径硬约束

**工作产品定位规则**：
- `domain-model.yaml` 自身的位置由 `.mims/state.yaml` 的 `design_artifacts.location` 决定（默认 `.` = 项目根；`/mims pause` 搬迁后为 `design/`）。该字段是唯一外部指针，不写进 `domain-model.yaml`。
- `domain-model.yaml` 内部所有路径（`metadata.documents.*.file_path`、`metadata.prototype_plan.output_dir`）均相对 **`domain-model.yaml` 所在目录** 解析，不相对 cwd。
- 因此工作产品（`domain-model.yaml` / `srs.md` / `sdd.md` / `prototype/`）始终作为一组整体存放在 `{location}/` 下；搬迁时整组移动并更新 `location`，无需改写模型内部路径。
- 发现顺序：先读 `.mims/state.yaml` 的 `location` → 查 `{location}/domain-model.yaml` → 回退根目录。

**原型目录约束**：
- 默认原型目录为相对路径 `prototype/`。
- `domain-model.yaml` 中禁止写入绝对路径，例如 `D:/...`、`E:\\...`、`/Users/...`。
- 若用户项目已有约定目录，可使用相对路径 `doc/proto/`，但必须记录原因：

```yaml
metadata:
  prototype_plan:
    output_dir: "doc/proto/"
    path_policy:
      type: "relative"
      override_reason: "user_project_existing_convention"
```

- 原型文件引用统一使用相对路径，例如 `prototype/index.html`。

---

## 9. Codex Fallback 硬约束

当无法委托 `mims-validator`、`mims-spec-generator`、`mims-prototyper` 或 `mims-change-manager` 时：

1. 主 Agent 必须读取对应 agent 规则文件。
2. 主 Agent 必须读取本文件和 `schema.md`。
3. 验证、文档、原型或变更任务必须产生与子代理等价的可追溯结果。
4. 若无法读取规则文件，必须明确告诉用户当前处于简化 fallback，且不得标记阶段 `complete`。

---

## 10. 最小结构性错误清单

以下问题只要出现，必须作为 ERROR：

- `modeling_approach` 不是 `"FBS"`。
- `version` 不符合 `^\d+\.\d+$`。
- 同类 id 重复。
- id 前缀不符合本契约。
- 属性类型不在允许集合内。
- 核心对象没有主键。
- 状态缺少 id。
- 状态转移使用 `operation` 而不是 `trigger_operation`。
- 状态转移引用不存在的状态或操作。
- 角色、场景、流程引用不存在或混用中文名/英文名/id。
- process 缺少 `parent_scenario` 或引用不存在的场景。
- 原型输出路径是绝对路径。
- 阶段标记 `complete` 但缺少对应 validation_result。

---

## 11. Description Length Guidelines

description 字段应有合理的长度。过长描述可能意味着详细叙述应放在 `srs.md` / `sdd.md` 中。

**设计目标长度**（指导性，非强制截断）：

| 字段路径 | 目标上限 |
|---------|---------|
| `function.actors[].description` | 80 字符 |
| `function.scenarios[].description` | 120 字符 |
| `function.processes[].description` | 120 字符 |
| `processes[].steps[].business_logic` | 150 字符 |
| `domain.modules[].description` | 100 字符 |
| `domain.objects[].description` | 100 字符 |
| `domain.objects[].states[].description` | 80 字符 |
| `domain.objects[].operations[].description` | 80 字符 |
| `domain.objects[].rules[].description` | 80 字符 |
| `domain.objects[].rules[].constraint` | 150 字符 |

**执行规则**：
- 新模型：Agent 应遵循目标长度，详细叙述交给 srs.md/sdd.md
- 已有模型：宽容处理，不强制截断（对话过程中 YAML 是唯一持久化载体）
- 验证器对超长描述发出 `W_DESC_001`（WARNING，不阻塞）
