# srs-template.md — 软件需求规格说明书（SRS）模板

> 由 P6 检查点或 /mims srs 命令加载，基于 domain-model.yaml 生成 srs.md

## 生成原则

偏自然语言，业务视角。补充 domain-model.yaml 中不适合用结构化数据表达的信息：
- 业务叙述和背景
- 决策理由和背景
- 约束和假设

不重复 YAML 中已有的精确结构数据（类型、基数等），用表格摘要引用。

## 模板

# {项目名} — 软件需求规格说明书（SRS）

> 由迷悟师（MIMS）基于对话自动生成
> 生成时间：{datetime}
> 版本：{metadata.version}
> 设计阶段：初步设计

## 1. 项目概述

### 1.1 业务背景
{从 metadata.context 和 P3 对话中提取，自然语言叙述}

### 1.2 总体目标
{从需求收集中提取的核心目标}

### 1.3 成功标准
{从 P3 对话中确认的成功标准}

## 2. 用户角色

{逐个角色的画像式描述}

| 角色 | 描述 | 典型场景 |
|------|------|---------|
| {chinese_name} | {description} | {关联场景名} |

## 3. 业务场景

{逐个场景的故事叙述：背景→触发→操作→结果}

### {场景中文名}

- **参与角色**：{actors}
- **前置条件**：{preconditions}
- **后置条件**：{postconditions}
- **流程**：
{workflow steps as numbered list}

> 参见模型：{chinese_name}（{name}）

## 4. 业务流程

{逐个流程的端到端描述}

### {流程中文名}

- **归属场景**：{parent_scenario 的 chinese_name}
- **参与角色**：{actors}
- **启动条件**：{start_condition}
- **结束条件**：{end_condition}

**流程步骤**：

| 步骤 | 操作 | 执行者 | 涉及模块 | 信息传递 | 业务逻辑 |
|------|------|--------|---------|---------|---------|
| {n} | {action} | {actor} | {module} | {info_passed} | {business_logic} |

## 5. 总体架构

### 5.1 功能模块划分

| 模块 | 类型 | 描述 | 依赖 |
|------|------|------|------|
| {chinese_name} | {传统/AI Agent/混合} | {description} | {depends_on} |

### 5.2 模块间依赖关系
{文字描述模块间调用和数据流向}

### 5.3 外部系统与接口

| 外部系统 | 接口类型 | 方向 | 关联模块 | 说明 |
|---------|---------|------|---------|------|
| {chinese_name} | {function_call/data_exchange/data_sync} | {outbound/inbound/bidirectional} | {connected_module} | {trigger}: {description} |

### 5.4 系统边界
{描述系统的范围，哪些在系统内，哪些在外}

## 6. AI Agent 模块评估

{如有 is_ai_agent=true 的模块，逐个展示评估过程和结论}

### {模块中文名}（AI Agent）

- **AI 类型**：{ai_agent_type}
- **评估依据**：{ai_justification}
- **评估维度**：
  - 输入特征：{结构化/非结构化}
  - 处理逻辑：{规则明确/需要理解判断}
  - 输出特征：{确定性/生成式}
  - 精确度要求：{精确/容忍误差}
  - 最终结论：{AI Agent/传统/混合}

## 7. 约束与假设

{从对话中提取的约束和假设}

## 8. 关键决策记录

| 决策 | 选项 | 最终选择 | 理由 | 时间 |
|------|------|---------|------|------|
| {从对话中提取的关键决策} | | | | |

---

*由 MIMS 自动生成 · {datetime}*
