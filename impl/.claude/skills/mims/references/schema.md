# schema.md - 数据模型规范文档

> 本文档定义基于 FBS 框架的 `domain-model.yaml` 的完整数据结构、字段约束和验证规则。
>
> **优先级**: 🔴 P0 - 必须创建
> **目标读者**: Claude Agent、开发者
> **用途**: Agent 理解和生成模型的基础

---

## 1. 概述

### 1.1 文档目的

本文档定义 MIMS 项目中 `domain-model.yaml` 文件的完整数据结构规范。该文件是对话式 AI 辅助设计工具的核心输出，采用 **FBS 框架**（Function-Behavior-Structure，Gero 1990）作为建模方法论。

### 1.2 FBS 建模框架

**FBS = Function（功能）+ Behavior（行为）+ Structure（结构）**

| 层 | 含义 | 回答的问题 | 对应 UML |
|----|------|-----------|---------|
| **F 功能层** | 系统的目的，为谁服务 | 谁在用？什么场景？端到端流程如何？ | 用例图 |
| **B 行为层** | 系统如何动态运作 | 有哪些状态？如何变化？操作和规则是什么？ | 状态图 |
| **S 结构层** | 系统由什么构成 | 管理哪些对象？有哪些信息？如何关联？ | 类图 |

**两种顺序**：

```
对话顺序（自顶向下）：F → B → S
  先明确目的（谁用、什么场景、端到端流程）
  再了解行为（操作、状态变化、规则）
  最后落实结构（对象、属性、关系）

YAML 输出顺序（按依赖）：S → B → F
  先定义结构（对象是行为的载体）
  再定义行为（行为依附于结构）
  最后描述功能（功能引用结构和行为）
```

### 1.3 术语定义

| 技术术语 | 用户友好表达 | 层 | 说明 |
|---------|-------------|-----|------|
| Module（功能模块） | 功能模块 | S | 相关对象的集合，模块间单向依赖 |
| Object（业务对象） | 要管理的东西 | S | 系统中需要管理的核心概念 |
| Attribute（属性） | 需要记录的信息 | S | 对象的数据字段 |
| Relationship（关系） | 关联/连接 | S | 对象间的引用或依赖关系 |
| State（状态） | 当前状况/所处阶段 | B | 对象生命周期中的某个状况 |
| Transition（状态转移） | 状态变化 | B | 从一个状态到另一个状态 |
| Operation（操作） | 可以做的操作 | B | 触发状态转移的动作 |
| Rule（业务规则） | 约束条件/规定 | B | 业务逻辑约束，不含格式校验 |
| Response（响应） | 操作后发生什么 | B | 操作执行后的结果和副作用 |
| Actor（参与者） | 用户角色/使用者 | F | 使用系统的角色 |
| Scenario（场景） | 使用场景/工作情境 | F | 单一角色视角的用例（泳道图） |
| Process（业务流程） | 业务流程/办事流程 | F | 跨角色跨对象的端到端流程 |

### 1.4 校验与规则的边界

**validations（技术校验）** → 回答"数据格式是否合法？"

- 适用：required、pattern、range、length、unique 等格式约束
- 定义位置：`attributes[].validations`
- 示例："手机号必须11位"、"金额不能为空"

**rules（业务规则）** → 回答"业务逻辑是否允许？"

- 适用：状态前置条件、跨字段逻辑、增删改约束、操作过程中的业务逻辑
- 定义位置：`objects[].rules`（对象级不变量）或 `operations[].rules`（操作级前置条件）
- 示例："只有已审核供应商才能下单"、"订单金额超过1万需二级审批"

> **注意**：rules 只包含业务逻辑，不重复描述 validations 已涵盖的格式校验。

### 1.5 适用范围

本文档适用于：
- MIMS Skill 的 Agent 理解和生成 `domain-model.yaml`
- 开发者验证和解析 YAML 模型文件
- 子代理（mims-validator）执行模型验证

---

## 2. YAML 顶层结构

### 2.1 顶层概览

```yaml
metadata:            # 元数据（版本、项目信息）
source_materials:    # 资料库（用户提供的参考资料，可选）
domain:              # S层 + B层（结构是行为的载体）
  modules:           # 功能模块（含对象及其内部关系，模块间单向依赖）
  objects:           # 业务对象（含属性、关系、状态、操作、规则）
function:            # F层（引用 domain 中的对象和操作）
  actors:            # 参与者/用户角色
  scenarios:         # 使用场景（泳道图视角）
  processes:         # 端到端业务流程（可选）
```

### 2.2 对象内部结构（S层 + B层 组合）

```yaml
domain:
  objects:
    - id: "obj_001"
      name: "Order"
      chinese_name: "订单"
      module: "OrderModule"

      # ── S层：静态结构 ──────────────────────────
      attributes:           # 数据属性（含 data_dictionary + validations）
      relationships:        # 对象关系（1:1 / 1:N，可选双向）

      # ── B层：动态行为 ──────────────────────────
      states:               # 状态列表
      transitions:          # 状态转移
      operations:           # 操作（含内联或引用的操作级规则 + 响应）
      rules:                # 对象级业务规则（不变量，可被 operations 引用）
```

### 2.3 完整示例（订单）

```yaml
metadata:
  project_name: "订单管理系统"
  version: "1.0"
  last_updated: "2026-03-26T10:00:00Z"
  modeling_approach: "FBS"
  confidence_level: 0.92

source_materials:
  - id: "src_001"
    name: "Product Requirements Document"
    chinese_name: "产品需求文档"
    type: "document"
    description: "订单管理系统的完整需求文档"
    source:
      type: "local"
      path: "E:/docs/prd.pdf"
      referenced_at: "2026-03-26T10:00:00Z"
    content:
      summary: |
        ## 核心需求
        本系统用于管理电商平台的订单流程...

        ## 目标用户
        1. 客户 - 购买商品的用户
        2. 管理员 - 处理订单的内部人员

        ## 核心功能
        - 订单创建与支付
        - 订单审核与发货
        - 订单跟踪与收货

        ## 业务规则
        - 订单金额超过1万需要二级审批
        - 待支付订单超过24小时自动取消
      word_count: 5230
    key_extractions:
      - id: "ext_001"
        category: "user_role"
        content: "客户 - 购买商品的用户，可以创建订单、支付、确认收货"
        confidence: 0.95
        source_reference: "第2页，第1-2段"
        related_operations: ["create_order", "pay", "confirm_receipt"]
      - id: "ext_002"
        category: "user_role"
        content: "管理员 - 处理订单的内部人员，负责审核订单和发货"
        confidence: 0.93
        source_reference: "第2页，第3段"
        related_operations: ["approve_order", "ship"]
      - id: "ext_003"
        category: "business_object"
        content: "订单 - 客户购买商品的记录，包含订单号、金额、状态等"
        confidence: 0.96
        source_reference: "第3页，第1段"
        related_objects: ["Customer", "Product", "OrderItem"]
      - id: "ext_004"
        category: "attribute"
        content: "订单号 - 唯一标识，格式 ORD-YYYYMMDD-NNNNNN"
        confidence: 0.98
        source_reference: "第3页，第2段"
      - id: "ext_005"
        category: "business_rule"
        content: "订单金额超过1万需要二级审批"
        confidence: 0.99
        source_reference: "第5页，第4段"
        related_objects: ["Order"]
        related_operations: ["create_order"]
    processing:
      status: "completed"
      processed_at: "2026-03-26T10:05:00Z"
      processor_version: "v1.0"
    conversations:
      - step: "Step 0.5"
        timestamp: "2026-03-26T10:05:00Z"
        context: "用户确认资料摘要准确"
        confirmation: true

domain:
  modules:
    - id: "mod_001"
      name: "OrderModule"
      chinese_name: "订单模块"
      depends_on: ["CustomerModule"]   # 单向依赖，禁止循环
      relationships:                   # 仅 N:M 关系放模块级
        - from: "Order"
          to: "Product"
          type: "many_to_many"
          label: "包含"
          join_object: "OrderItem"     # 关联对象承载 N:M

  objects:
    - id: "obj_001"
      name: "Order"
      chinese_name: "订单"
      module: "OrderModule"

      attributes:
        - name: "order_no"
          chinese_name: "订单编号"
          type: "string"
          required: true
          primary_key: true
          data_dictionary:
            format: "ORD-{YYYYMMDD}-{6位流水号}"
            example: "ORD-20260322-000001"
          validations:
            - type: "pattern"
              rule: "^ORD-\\d{8}-\\d{6}$"
              message: "订单编号格式不正确"

        - name: "status"
          chinese_name: "订单状态"
          type: "enum"
          required: true
          data_dictionary:
            values:
              - value: "pending_payment"
                label: "待支付"
              - value: "paid"
                label: "已支付"
              - value: "shipped"
                label: "已发货"
              - value: "completed"
                label: "已完成"
              - value: "cancelled"
                label: "已取消"

      relationships:
        - to: "Customer"
          type: "reference"
          cardinality: "many_to_one"
          label: "属于"
          required: true
          bidirectional: false         # 是否支持双向引用

      states:
        - id: "st_001"
          name: "pending_payment"
          chinese_name: "待支付"
          is_initial: true
        - id: "st_002"
          name: "paid"
          chinese_name: "已支付"
        - id: "st_003"
          name: "shipped"
          chinese_name: "已发货"
        - id: "st_004"
          name: "completed"
          chinese_name: "已完成"
          is_final: true
        - id: "st_005"
          name: "cancelled"
          chinese_name: "已取消"
          is_final: true

      transitions:
        - id: "tr_001"
          from_state: "pending_payment"
          to_state: "paid"
          trigger_operation: "pay"
        - id: "tr_002"
          from_state: "paid"
          to_state: "shipped"
          trigger_operation: "ship"
        - id: "tr_003"
          from_state: "shipped"
          to_state: "completed"
          trigger_operation: "confirm_receipt"
        - id: "tr_004"
          from_state: "pending_payment"
          to_state: "cancelled"
          trigger_operation: "cancel"

      rules:                           # 对象级业务规则（不变量）
        - id: "rule_001"
          constraint: "total_amount > 0"
          description: "订单金额必须大于零"
          severity: "error"
        - id: "rule_002"
          constraint: "total_amount > 10000 → requires_approval == true"
          description: "订单金额超过1万需要二级审批"
          severity: "error"

      operations:
        - id: "op_001"
          name: "pay"
          chinese_name: "支付订单"
          description: "完成订单支付"
          parameters:
            - name: "amount"
              type: "number"
              required: true
              label: "支付金额"
          rules:                       # 操作级规则（前置条件）
            - condition: "status == 'pending_payment'"
              action: "ALLOW"
              error_message: "只有待支付订单可以支付"
            - ref: "rule_002"          # 引用对象级规则
          responses:
            - on: "success"
              actions:
                - "更新订单状态为已支付"
                - "创建支付记录"
              notifications:
                - channel: "email"
                  template: "payment_success"
                  recipient: "customer"
            - on: "failure"
              actions:
                - "记录支付失败日志"
                - "返回错误信息"

function:
  actors:
    - id: "actor_001"
      name: "customer"
      chinese_name: "客户"
      description: "购买商品的用户"
      permissions: ["create_order", "pay", "confirm_receipt", "cancel"]

  scenarios:
    - id: "sc_001"
      name: "customer_places_order"
      chinese_name: "客户下单"
      description: "客户选择商品并完成下单支付的场景"
      actor: "customer"
      preconditions: ["客户已登录", "商品库存充足"]
      postconditions: ["订单已创建", "支付已完成"]
      workflow:
        - step: 1
          action: "选择商品"
          actor: "customer"
        - step: 2
          action: "确认订单信息"
          actor: "customer"
        - step: 3
          action: "完成支付"
          actor: "customer"

  processes:
    - id: "proc_001"
      name: "order_fulfillment"
      chinese_name: "订单履行流程"
      description: "从客户下单到收货的完整业务链"
      actors: ["customer", "admin"]
      start_condition: "客户有购买意向"
      end_condition: "客户确认收货"
      steps:
        - step: 1
          action: "客户创建并支付订单"
          actor: "customer"
        - step: 2
          action: "管理员审核并发货"
          actor: "admin"
        - step: 3
          action: "客户确认收货"
          actor: "customer"
```

---

## 3. 完整 Schema 定义

### 3.1 Metadata（元数据）

```yaml
metadata:
  project_name: string       # 必需，项目名称，长度 1-100
  version: string            # 必需，格式 \d+\.\d+，如 "1.0"
  last_updated: string       # 必需，ISO 8601 格式
  modeling_approach: "FBS"   # 必需，固定值
  confidence_level: number   # 可选，0-1 浮点数
```

| 字段 | 类型 | 必需 | 约束 |
|------|------|------|------|
| project_name | string | 是 | 长度 1-100 |
| version | string | 是 | 正则 `^\d+\.\d+$` |
| last_updated | string | 是 | ISO 8601 |
| modeling_approach | string | 是 | 固定值 `"FBS"` |
| confidence_level | number | 否 | 0-1 |

---

### 3.2 Domain — S 结构层

#### 3.2.1 Module（功能模块）

```yaml
domain:
  modules:
    - id: string              # 必需，格式 mod_\d+
      name: string            # 必需，PascalCase，如 "OrderModule"
      chinese_name: string    # 必需，中文名
      description: string     # 可选
      depends_on: [string]    # 可选，依赖的其他模块名；禁止循环依赖
      relationships:          # 可选，仅放 N:M 关系
        - from: string        # 必需，源对象名
          to: string          # 必需，目标对象名
          type: "many_to_many"
          label: string       # 可选，关系标签
          chinese_label: string
          join_object: string # 可选，承载 N:M 的关联对象名
```

**模块设计规则**：
- 模块间依赖必须是单向的（`depends_on` 声明）
- 禁止循环依赖（A 依赖 B，B 不能依赖 A）
- 上层模块中的对象可单向引用下层模块中的对象
- N:M 关系定义在模块级；1:1 / 1:N 关系定义在对象级

#### 3.2.2 Object（业务对象）

```yaml
domain:
  objects:
    - id: string              # 必需，格式 obj_\d+
      name: string            # 必需，PascalCase，如 "Order"
      chinese_name: string    # 必需，中文名
      description: string     # 可选
      module: string          # 可选，所属模块名
      category: string        # 可选，core / supporting
```

#### 3.2.3 Attribute（属性）

```yaml
attributes:
  - name: string              # 必需，snake_case
    chinese_name: string      # 必需，中文名
    type: string              # 必需，见类型系统
    required: boolean         # 可选，默认 false
    primary_key: boolean      # 可选，默认 false
    computed: boolean         # 可选，默认 false（计算属性）
    default_value: any        # 可选
    label: string             # 可选，UI 显示标签

    data_dictionary:          # 可选，定义格式/枚举/示例
      # 枚举类型（type: enum）
      values:
        - value: string
          label: string
          description: string
          icon: string        # 可选
          color: string       # 可选，十六进制色值

      # 文本/数值类型
      format: string          # 格式说明
      pattern: string         # 正则表达式
      min_length: integer
      max_length: integer
      min_value: number
      max_value: number
      scale: integer          # 小数位数
      example: any            # 示例值

    validations:              # 可选，技术格式校验
      - type: string          # required / pattern / range / length / unique / custom
        rule: string          # 校验表达式（非 required 类型时使用）
        min: number           # range / length 类型使用
        max: number
        message: string       # 必需，错误提示
        severity: string      # 可选，error / warning，默认 error
```

**类型系统**：

| 类型 | 说明 | 示例值 |
|------|------|--------|
| string | 文本字符串 | "Hello" |
| number | 数字（整数或小数） | 123, 45.67 |
| boolean | 布尔值 | true, false |
| datetime | 日期时间 | "2026-03-22T10:00:00Z" |
| enum | 枚举值 | "pending"（需配合 data_dictionary.values） |
| reference | 对其他对象的引用 | 存储目标对象的 id |

**validations 类型说明**：

| type | 适用类型 | rule 字段 | 说明 |
|------|---------|----------|------|
| required | 所有 | — | 字段不能为空 |
| pattern | string | 正则表达式 | 格式匹配 |
| range | number, datetime | — | 使用 min/max |
| length | string | — | 使用 min/max |
| unique | 所有 | — | 值在集合内唯一 |
| custom | 所有 | 表达式字符串 | 自定义逻辑 |

#### 3.2.4 Relationship（对象级关系，1:1 / 1:N）

```yaml
relationships:
  - to: string                # 必需，目标对象名
    type: string              # 必需，reference / composition / aggregation
    cardinality: string       # 必需，one_to_one / one_to_many / many_to_one
    label: string             # 可选，关系标签（英文）
    chinese_label: string     # 可选，中文标签
    required: boolean         # 可选，是否必需关系
    cascade_delete: boolean   # 可选，是否级联删除
    bidirectional: boolean    # 可选，默认 false；true 时目标对象可反向引用本对象
```

**关系类型说明**：

| type | 含义 | 示例 | cascade_delete |
|------|------|------|----------------|
| reference | 引用关系，独立存在 | 订单引用客户 | 通常 false |
| composition | 组合，强依赖，整体消失则部分消失 | 订单与订单行 | 通常 true |
| aggregation | 聚合，弱依赖，可独立存在 | 部门与员工 | 通常 false |

---

### 3.3 Domain — B 行为层

#### 3.3.1 State（状态）

```yaml
states:
  - id: string                # 必需，格式 st_\d+
    name: string              # 必需，snake_case
    chinese_name: string      # 必需，中文名
    is_initial: boolean       # 可选，每个对象必须有且仅有一个初始状态
    is_final: boolean         # 可选，终止状态，无出边
    description: string       # 可选
    color: string             # 可选，UI 颜色
    icon: string              # 可选，UI 图标
```

#### 3.3.2 Transition（状态转移）

```yaml
transitions:
  - id: string                # 必需，格式 tr_\d+
    from_state: string        # 必需，源状态名（引用 states[].name）
    to_state: string          # 必需，目标状态名
    trigger_operation: string # 必需，触发操作名（引用 operations[].name）
    condition: string         # 可选，附加转移条件（补充操作规则之外的条件）
    automatic: boolean        # 可选，默认 false；true 时系统自动触发无需用户操作
```

#### 3.3.3 Object-level Rule（对象级业务规则）

```yaml
rules:                        # 对象的业务不变量，纯业务逻辑，不含格式校验
  - id: string                # 必需，格式 rule_\d+
    constraint: string        # 必需，约束表达式（业务语言描述）
    description: string       # 必需，规则说明
    severity: string          # 必需，error / warning
    scope: string             # 可选，create / update / delete / all（默认 all）
```

#### 3.3.4 Operation（操作）

```yaml
operations:
  - id: string                # 必需，格式 op_\d+
    name: string              # 必需，snake_case
    chinese_name: string      # 必需，中文名
    description: string       # 可选
    parameters:               # 可选，操作参数
      - name: string          # 必需
        type: string          # 必需，见类型系统
        required: boolean     # 可选，默认 false
        label: string         # 可选
        data_dictionary: {}   # 可选
        validations: []       # 可选

    rules:                    # 操作级规则（前置条件），内联或引用
      - condition: string     # 内联：前置条件表达式
        action: string        # ALLOW / DENY / WARN
        error_message: string # 提示信息
        priority: string      # 可选，high / medium / low
      - ref: string           # 引用：引用 objects[].rules[].id

    responses:
      - on: string            # 必需，success / failure
        actions: [string]     # 响应动作列表（自然语言描述）
        notifications:        # 可选，通知列表
          - channel: string   # email / sms / web / push
            template: string  # 模板名
            recipient: string # 接收方（actor name 或 system）
```

---

### 3.4 Function — F 功能层

#### 3.4.1 Actor（参与者）

```yaml
function:
  actors:
    - id: string              # 必需，格式 actor_\d+
      name: string            # 必需，snake_case
      chinese_name: string    # 必需，中文名
      description: string     # 必需
      permissions: [string]   # 可选，可执行的操作名列表
```

#### 3.4.2 Scenario（使用场景）

```yaml
  scenarios:
    - id: string              # 必需，格式 sc_\d+
      name: string            # 必需，snake_case
      chinese_name: string    # 必需，中文名
      description: string     # 必需
      actor: string           # 必需，单一角色（泳道视角）
      preconditions: [string] # 可选，前置条件列表
      postconditions: [string]# 可选，后置条件列表
      workflow:
        - step: integer       # 必需，步骤序号
          action: string      # 必需，步骤描述
          actor: string       # 可选，默认为场景的 actor
          system: boolean     # 可选，默认 false；true 表示系统自动执行
          objects: [string]   # 可选，本步骤涉及的对象名
```

#### 3.4.3 Process（端到端业务流程）

```yaml
  processes:                  # 可选，简单系统可不定义
    - id: string              # 必需，格式 proc_\d+
      name: string            # 必需，snake_case
      chinese_name: string    # 必需，中文名
      description: string     # 必需
      actors: [string]        # 必需，参与的角色名列表（跨角色）
      start_condition: string # 必需，流程启动条件
      end_condition: string   # 必需，流程结束条件
      steps:
        - step: integer       # 必需，步骤序号
          action: string      # 必需，步骤描述
          actor: string       # 必需，执行角色
          system: boolean     # 可选，默认 false
          related_scenario: string  # 可选，关联的场景 id
```

---

### 3.5 命名规范

| 元素 | 命名规则 | 正确示例 | 错误示例 |
|------|---------|---------|---------|
| Module 名 | PascalCase + "Module" | `OrderModule` | `order_module` |
| Object 名 | PascalCase | `Order`, `OrderItem` | `order`, `order_item` |
| Attribute 名 | snake_case | `order_no`, `created_at` | `orderNo`, `CreatedAt` |
| State 名 | snake_case | `pending_payment`, `paid` | `PendingPayment` |
| Operation 名 | snake_case | `pay`, `confirm_receipt` | `payOrder`, `ConfirmReceipt` |
| Actor 名 | snake_case | `customer`, `admin` | `Customer`, `Admin` |
| ID 格式 | `{prefix}_\d+` | `obj_001`, `op_001` | `object1`, `operation_1` |

**ID 前缀对照**：

| 元素 | 前缀 | 示例 |
|------|------|------|
| Module | `mod_` | `mod_001` |
| Object | `obj_` | `obj_001` |
| State | `st_` | `st_001` |
| Transition | `tr_` | `tr_001` |
| Operation | `op_` | `op_001` |
| Rule | `rule_` | `rule_001` |
| Actor | `actor_` | `actor_001` |
| Scenario | `sc_` | `sc_001` |
| Process | `proc_` | `proc_001` |

---

### 3.6 Source Materials（资料库）

**资料库**存储用户提供的参考资料（需求文档、产品说明书、界面截图等），用于辅助建模。

#### 3.6.1 基本结构

```yaml
source_materials:
  - id: string                    # 必需，格式 src_\d+
    name: string                  # 必需，资料名称
    chinese_name: string          # 必需，中文名
    type: string                  # 必需，document/image/url/text/audio/video
    description: string           # 可选，资料描述
```

| 字段 | 类型 | 必需 | 约束 |
|------|------|------|------|
| id | string | 是 | 格式 `src_\d+` |
| name | string | 是 | 长度 1-100 |
| chinese_name | string | 是 | 中文名 |
| type | string | 是 | 枚举值见下表 |
| description | string | 否 | 长度 0-500 |

**type 枚举值**：

| 值 | 说明 | 示例 |
|-----|------|------|
| document | 文档类型 | PDF, Word, Markdown |
| image | 图片类型 | PNG, JPG, 界面截图 |
| url | 网页链接 | 产品文档 URL |
| text | 纯文本 | 用户直接输入的文本 |
| audio | 音频 | 会议录音 |
| video | 视频 | 产品演示视频 |

#### 3.6.2 来源信息

```yaml
source:
  type: string                # 必需，local/url/reference/manual
  path: string                # 可选，文件路径
  url: string                 # 可选，URL地址
  referenced_at: string       # 可选，ISO 8601
```

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| type | string | 是 | local（本地文件）/ url（网络）/ reference（引用）/ manual（手动输入） |
| path | string | 否 | 本地文件路径 |
| url | string | 否 | 远程 URL 地址 |
| referenced_at | string | 否 | 资料被引用的时间，ISO 8601 格式 |

#### 3.6.3 内容信息

```yaml
content:
  raw_text: string            # 可选，原始文本
  summary: string             # 必需，内容摘要
  word_count: number          # 可选，字数统计
```

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| raw_text | string | 否 | 原始文本内容（可选） |
| summary | string | 是 | AI 生成的内容摘要 |
| word_count | number | 否 | 字数统计 |

#### 3.6.4 关键信息提取

```yaml
key_extractions:
  - id: string                # 必需，格式 ext_\d+
    category: string          # 必需，信息类别
    content: string           # 必需，提取内容
    confidence: number        # 可选，0-1置信度
    source_reference: string  # 可选，原文引用位置
    related_objects: [string] # 可选，关联对象
    related_operations: [string] # 可选，关联操作
```

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| id | string | 是 | 格式 `ext_\d+` |
| category | string | 是 | 信息类别（见下表） |
| content | string | 是 | 提取的具体内容 |
| confidence | number | 否 | 0-1 置信度 |
| source_reference | string | 否 | 原文位置（页码/段落/时间戳） |
| related_objects | [string] | 否 | 关联的对象名列表 |
| related_operations | [string] | 否 | 关联的操作名列表 |

**category 枚举值**（13类）：

| category | 说明 | 示例 |
|----------|------|------|
| business_goal | 业务目标 | "构建订单管理系统" |
| user_role | 用户角色 | "客户 - 购买商品的用户" |
| business_object | 业务对象 | "订单 - 客户购买商品的记录" |
| attribute | 属性信息 | "订单号 - 唯一标识，格式 ORD-..." |
| relationship | 关系描述 | "订单包含多个商品" |
| business_rule | 业务规则 | "订单金额超过1万需审批" |
| operation | 操作描述 | "客户可以创建订单" |
| constraint | 约束条件 | "订单号必须唯一" |
| scenario | 使用场景 | "客户下单支付场景" |
| pain_point | 痛点问题 | "当前手工记录容易出错" |
| requirement | 需求描述 | "系统需要支持批量导出" |
| assumption | 假设条件 | "假设用户已登录" |
| other | 其他信息 | 未分类信息 |

#### 3.6.5 处理状态

```yaml
processing:
  status: string              # 必需，pending/processing/completed/failed
  processed_at: string        # 可选，处理完成时间
  processor_version: string   # 可选，处理版本
```

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| status | string | 是 | pending（待处理）/ processing（处理中）/ completed（已完成）/ failed（失败） |
| processed_at | string | 否 | 处理完成时间，ISO 8601 格式 |
| processor_version | string | 否 | 处理器版本号 |

#### 3.6.6 对话引用

```yaml
conversations:
  - step: string              # 必需，步骤标识
    timestamp: string         # 必需，引用时间
    context: string           # 可选，引用上下文
    confirmation: boolean     # 可选，用户是否确认
```

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| step | string | 是 | 步骤标识（如 "Step 0.5", "Step 2"） |
| timestamp | string | 是 | 引用时间，ISO 8601 格式 |
| context | string | 否 | 引用上下文描述 |
| confirmation | boolean | 否 | 用户是否确认该资料信息 |

---

## 4. FBS 建模规范

### 4.1 S 层：结构设计原则

**模块划分原则**：

```yaml
# ✅ 好的模块划分（高内聚，低耦合）
modules:
  - name: "OrderModule"
    objects: ["Order", "OrderItem"]
    depends_on: ["CustomerModule", "ProductModule"]

# ❌ 不好的模块划分（跨领域混合）
modules:
  - name: "MainModule"
    objects: ["Order", "Customer", "Product", "Inventory"]  # 所有对象混在一起
```

**对象属性设计原则**：

```yaml
# ✅ 属性名语义清晰，类型明确
attributes:
  - name: "total_amount"
    chinese_name: "订单总金额"
    type: "number"
    data_dictionary:
      min_value: 0.01
      scale: 2
      example: "299.50"

# ❌ 属性语义模糊，类型不明
attributes:
  - name: "data"         # 太模糊
    type: "string"       # 应该是 number
```

**关系设计原则**：

```yaml
# 1:N 关系 → 定义在对象上（"多"方引用"一"方）
objects:
  - name: "OrderItem"
    relationships:
      - to: "Order"
        type: "composition"
        cardinality: "many_to_one"

# N:M 关系 → 定义在模块上，通常需要关联对象
modules:
  - name: "OrderModule"
    relationships:
      - from: "Order"
        to: "Product"
        type: "many_to_many"
        join_object: "OrderItem"
```

### 4.2 B 层：行为设计原则

**状态设计原则**：

```yaml
# ✅ 状态互斥、有业务意义、粒度适中
states:
  - name: "pending_payment"   # 清晰的业务阶段
  - name: "paid"
  - name: "shipped"
  - name: "completed"

# ❌ 避免以下问题
states:
  - name: "active"            # 粒度太粗，无业务含义
  - name: "updated"           # 技术语言而非业务语言
  - name: "paid_and_shipped"  # 混合状态
```

**操作与规则设计原则**：

```yaml
# ✅ 操作级规则：前置条件，决定操作是否可执行
operations:
  - name: "pay"
    rules:
      - condition: "status == 'pending_payment'"
        action: "ALLOW"
        error_message: "只有待支付订单可以执行支付"

# ✅ 对象级规则：不变量，任何操作后都必须满足
rules:
  - constraint: "total_amount > 0"
    description: "订单金额必须大于零"
    severity: "error"

# ✅ 引用对象级规则（避免重复定义）
operations:
  - name: "create"
    rules:
      - ref: "rule_001"       # 引用对象级规则
```

**响应设计原则**：

```yaml
# ✅ 响应完整，success 和 failure 都定义
responses:
  - on: "success"
    actions:
      - "更新订单状态为已支付"
      - "扣减库存"
      - "发送支付成功通知"
  - on: "failure"
    actions:
      - "记录失败日志"
      - "返回错误信息给用户"
```

### 4.3 F 层：功能设计原则

**Scenario vs Process**：

```yaml
# Scenario：单一角色视角（泳道图的一条泳道）
scenarios:
  - name: "customer_pays_order"
    actor: "customer"         # 只有一个主角
    workflow:
      - step: 1
        action: "查看待支付订单"
        actor: "customer"

# Process：跨角色端到端流程（多条泳道合并）
processes:
  - name: "order_fulfillment"
    actors: ["customer", "admin"]   # 多个角色参与
    steps:
      - step: 1
        action: "客户完成支付"
        actor: "customer"
      - step: 2
        action: "管理员审核发货"
        actor: "admin"
```

---

## 5. 验证规则

### 5.1 结构验证（自动检查）

```yaml
validation_structure:
  # Metadata
  - check: "modeling_approach 必须为 FBS"
    rule: "metadata.modeling_approach == 'FBS'"
    error_code: "E_FBS_001"

  # Module
  - check: "模块间不能有循环依赖"
    rule: "modules[].depends_on 构成的图无环"
    error_code: "E_FBS_010"

  # Object
  - check: "对象名在全局唯一"
    rule: "objects[].name 唯一"
    error_code: "E_FBS_020"

  # State
  - check: "有状态的对象必须有且仅有一个初始状态"
    rule: "如果 states 非空，exists states[] where is_initial==true，且 count==1"
    error_code: "E_FBS_030"

  - check: "状态名在对象内唯一"
    rule: "objects[].states[].name 在同一对象内唯一"
    error_code: "E_FBS_031"

  # Transition
  - check: "转移引用的状态必须存在"
    rule: "transitions[].from_state IN states[].name AND to_state IN states[].name"
    error_code: "E_FBS_040"

  - check: "转移引用的操作必须存在"
    rule: "transitions[].trigger_operation IN operations[].name"
    error_code: "E_FBS_041"

  - check: "终止状态不能有出边"
    rule: "is_final==true 的状态不能出现在 transitions[].from_state"
    error_code: "E_FBS_042"

  # Operation
  - check: "操作名在对象内唯一"
    rule: "objects[].operations[].name 在同一对象内唯一"
    error_code: "E_FBS_050"

  - check: "操作规则的 ref 必须指向存在的 rule id"
    rule: "operations[].rules[].ref IN objects[].rules[].id（同一对象内）"
    error_code: "E_FBS_051"

  # Relationship
  - check: "关系引用的对象必须存在"
    rule: "relationships[].to IN objects[].name"
    error_code: "E_FBS_060"

  # Function
  - check: "场景引用的 actor 必须存在"
    rule: "scenarios[].actor IN actors[].name"
    error_code: "E_FBS_070"

  - check: "流程引用的 actor 必须存在"
    rule: "processes[].actors[] IN actors[].name"
    error_code: "E_FBS_071"
```

### 5.2 语义验证（LLM 检查）

```yaml
validation_semantic:
  - check: "状态的业务合理性"
    description: "状态名和描述是否准确反映业务场景，是否互斥"
    confidence_threshold: 0.7

  - check: "操作规则的完整性"
    description: "规则是否覆盖主要边界情况，是否存在规则冲突"
    confidence_threshold: 0.8

  - check: "模块依赖的合理性"
    description: "模块划分是否合理，依赖方向是否符合业务逻辑"
    confidence_threshold: 0.7

  - check: "场景与流程的一致性"
    description: "场景是否覆盖了流程中的主要步骤"
    confidence_threshold: 0.7
```

### 5.3 错误代码体系

| 代码范围 | 类别 | 示例 |
|---------|------|------|
| E001–E009 | YAML 语法 | E001: 无效 YAML 格式 |
| E_FBS_001–009 | Metadata | E_FBS_001: modeling_approach 非 FBS |
| E_FBS_010–019 | Module | E_FBS_010: 循环依赖 |
| E_FBS_020–029 | Object | E_FBS_020: 对象名重复 |
| E_FBS_030–039 | State | E_FBS_030: 缺少初始状态 |
| E_FBS_040–049 | Transition | E_FBS_040: 引用不存在的状态 |
| E_FBS_050–059 | Operation | E_FBS_050: 操作名重复 |
| E_FBS_060–069 | Relationship | E_FBS_060: 引用不存在的对象 |
| E_FBS_070–079 | Function | E_FBS_070: 引用不存在的角色 |

---

> **示例数据集、版本兼容性、附录及方法论映射**请参考 [`schema-examples.md`](./schema-examples.md)。
