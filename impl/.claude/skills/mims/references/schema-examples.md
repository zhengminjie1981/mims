# schema-examples.md - 示例数据集与参考资料

> 本文档是 `schema.md` 的配套参考文件，包含完整示例、版本兼容性说明、附录和方法论映射。
>
> **优先级**: 🟡 P1 - 开发者参考，AI 按需加载
> **目标读者**: 开发者、需要完整示例的 Agent
> **核心 Schema 见**: `schema.md`（§1–5）

---

## 6. 示例数据集

### 6.1 简单系统：任务管理（单模块，单对象）

**特点**：1个模块，1个对象，完整的 S+B+F 三层示例

```yaml
metadata:
  project_name: "个人任务管理系统"
  version: "1.0"
  last_updated: "2026-03-23T10:00:00Z"
  modeling_approach: "FBS"
  confidence_level: 0.92

domain:
  modules:
    - id: "mod_001"
      name: "TaskModule"
      chinese_name: "任务模块"
      description: "管理个人待办任务"

  objects:
    - id: "obj_001"
      name: "Task"
      chinese_name: "任务"
      description: "个人待办任务"
      module: "TaskModule"

      attributes:
        - name: "id"
          chinese_name: "任务ID"
          type: "string"
          required: true
          primary_key: true
          data_dictionary:
            format: "TASK-{YYYYMMDD}-{4位流水号}"
            example: "TASK-20260323-0001"
          validations:
            - type: "required"
              message: "任务ID不能为空"
            - type: "pattern"
              rule: "^TASK-\\d{8}-\\d{4}$"
              message: "任务ID格式不正确"
            - type: "unique"
              message: "任务ID必须唯一"

        - name: "title"
          chinese_name: "标题"
          type: "string"
          required: true
          data_dictionary:
            min_length: 1
            max_length: 100
            example: "完成项目文档"
          validations:
            - type: "required"
              message: "任务标题不能为空"
            - type: "length"
              min: 1
              max: 100
              message: "任务标题长度应在1-100个字符之间"

        - name: "priority"
          chinese_name: "优先级"
          type: "enum"
          required: true
          data_dictionary:
            values:
              - value: "low"
                label: "低"
                color: "#8BC34A"
              - value: "medium"
                label: "中"
                color: "#FFC107"
              - value: "high"
                label: "高"
                color: "#FF9800"
              - value: "urgent"
                label: "紧急"
                color: "#F44336"
          validations:
            - type: "required"
              message: "优先级不能为空"

        - name: "status"
          chinese_name: "状态"
          type: "enum"
          required: true
          data_dictionary:
            values:
              - value: "todo"
                label: "待办"
                color: "#9E9E9E"
              - value: "in_progress"
                label: "进行中"
                color: "#2196F3"
              - value: "completed"
                label: "已完成"
                color: "#4CAF50"
              - value: "cancelled"
                label: "已取消"
                color: "#F44336"
          validations:
            - type: "required"
              message: "任务状态不能为空"

        - name: "due_date"
          chinese_name: "截止日期"
          type: "datetime"
          required: false
          data_dictionary:
            format: "ISO 8601"
            example: "2026-04-01T18:00:00Z"

      states:
        - id: "st_001"
          name: "todo"
          chinese_name: "待办"
          is_initial: true
          description: "任务已创建，尚未开始"
        - id: "st_002"
          name: "in_progress"
          chinese_name: "进行中"
          description: "任务正在进行"
        - id: "st_003"
          name: "completed"
          chinese_name: "已完成"
          is_final: true
          description: "任务已完成"
        - id: "st_004"
          name: "cancelled"
          chinese_name: "已取消"
          is_final: true
          description: "任务已取消"

      transitions:
        - id: "tr_001"
          from_state: "todo"
          to_state: "in_progress"
          trigger_operation: "start"
        - id: "tr_002"
          from_state: "in_progress"
          to_state: "completed"
          trigger_operation: "complete"
        - id: "tr_003"
          from_state: "in_progress"
          to_state: "todo"
          trigger_operation: "pause"
        - id: "tr_004"
          from_state: "todo"
          to_state: "cancelled"
          trigger_operation: "cancel"
        - id: "tr_005"
          from_state: "in_progress"
          to_state: "cancelled"
          trigger_operation: "cancel"

      rules:
        - id: "rule_001"
          constraint: "due_date == null OR due_date > created_at"
          description: "截止日期必须晚于创建时间"
          severity: "error"
          scope: "create"

      operations:
        - id: "op_001"
          name: "start"
          chinese_name: "开始任务"
          rules:
            - condition: "status == 'todo'"
              action: "ALLOW"
              error_message: "只有待办任务可以开始"
            - ref: "rule_001"
          responses:
            - on: "success"
              actions:
                - "更新状态为进行中"
                - "记录开始时间"
            - on: "failure"
              actions:
                - "返回错误信息"

        - id: "op_002"
          name: "complete"
          chinese_name: "完成任务"
          parameters:
            - name: "notes"
              type: "string"
              required: false
              label: "完成备注"
              data_dictionary:
                max_length: 500
          rules:
            - condition: "status == 'in_progress'"
              action: "ALLOW"
              error_message: "只有进行中的任务可以完成"
          responses:
            - on: "success"
              actions:
                - "更新状态为已完成"
                - "记录完成时间"
            - on: "failure"
              actions:
                - "保持当前状态"
                - "返回错误信息"

        - id: "op_003"
          name: "cancel"
          chinese_name: "取消任务"
          rules:
            - condition: "status IN ['todo', 'in_progress']"
              action: "ALLOW"
              error_message: "只有待办或进行中的任务可以取消"
          responses:
            - on: "success"
              actions:
                - "更新状态为已取消"

        - id: "op_004"
          name: "pause"
          chinese_name: "暂停任务"
          rules:
            - condition: "status == 'in_progress'"
              action: "ALLOW"
              error_message: "只有进行中的任务可以暂停"
          responses:
            - on: "success"
              actions:
                - "更新状态为待办"

function:
  actors:
    - id: "actor_001"
      name: "user"
      chinese_name: "用户"
      description: "创建和管理个人任务的用户"
      permissions: ["start", "complete", "cancel", "pause"]

  scenarios:
    - id: "sc_001"
      name: "manage_daily_tasks"
      chinese_name: "日常任务管理"
      description: "用户查看、开始和完成日常任务"
      actor: "user"
      preconditions: ["用户已登录"]
      postconditions: ["任务状态已更新"]
      workflow:
        - step: 1
          action: "查看待办任务列表"
          actor: "user"
          objects: ["Task"]
        - step: 2
          action: "选择一个任务开始执行"
          actor: "user"
          objects: ["Task"]
        - step: 3
          action: "完成任务并填写备注"
          actor: "user"
          objects: ["Task"]
```

---

### 6.2 中等系统：订单管理（多模块，多对象）

**特点**：3个模块，4个对象，对象间关系，模块间依赖

```yaml
metadata:
  project_name: "订单管理系统"
  version: "1.0"
  last_updated: "2026-03-23T10:00:00Z"
  modeling_approach: "FBS"
  confidence_level: 0.85

domain:
  modules:
    - id: "mod_001"
      name: "CustomerModule"
      chinese_name: "客户模块"

    - id: "mod_002"
      name: "ProductModule"
      chinese_name: "商品模块"

    - id: "mod_003"
      name: "OrderModule"
      chinese_name: "订单模块"
      depends_on: ["CustomerModule", "ProductModule"]
      relationships:
        - from: "Order"
          to: "Product"
          type: "many_to_many"
          label: "包含"
          join_object: "OrderItem"

  objects:
    - id: "obj_001"
      name: "Customer"
      chinese_name: "客户"
      module: "CustomerModule"
      attributes:
        - name: "name"
          chinese_name: "姓名"
          type: "string"
          required: true
          validations:
            - type: "required"
              message: "姓名不能为空"
            - type: "length"
              min: 1
              max: 50
              message: "姓名长度应在1-50个字符之间"
        - name: "phone"
          chinese_name: "手机号"
          type: "string"
          required: true
          data_dictionary:
            pattern: "^1[3-9]\\d{9}$"
            example: "13800138000"
          validations:
            - type: "required"
              message: "手机号不能为空"
            - type: "pattern"
              rule: "^1[3-9]\\d{9}$"
              message: "手机号格式不正确"

    - id: "obj_002"
      name: "Product"
      chinese_name: "商品"
      module: "ProductModule"
      attributes:
        - name: "name"
          chinese_name: "商品名称"
          type: "string"
          required: true
          validations:
            - type: "required"
              message: "商品名称不能为空"
        - name: "price"
          chinese_name: "售价"
          type: "number"
          required: true
          data_dictionary:
            min_value: 0.01
            scale: 2
            example: "299.00"
          validations:
            - type: "required"
              message: "售价不能为空"
            - type: "range"
              min: 0.01
              message: "售价必须大于零"
        - name: "stock"
          chinese_name: "库存数量"
          type: "number"
          required: true
          data_dictionary:
            min_value: 0
            scale: 0
          validations:
            - type: "required"
              message: "库存数量不能为空"
            - type: "range"
              min: 0
              message: "库存数量不能为负"
      rules:
        - id: "rule_p001"
          constraint: "stock >= 0"
          description: "库存数量不能为负"
          severity: "error"
          scope: "all"

    - id: "obj_003"
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
            example: "ORD-20260323-000001"
          validations:
            - type: "required"
              message: "订单编号不能为空"
            - type: "pattern"
              rule: "^ORD-\\d{8}-\\d{6}$"
              message: "订单编号格式不正确"
            - type: "unique"
              message: "订单编号必须唯一"
        - name: "total_amount"
          chinese_name: "订单总金额"
          type: "number"
          required: true
          computed: true
          data_dictionary:
            min_value: 0.01
            scale: 2
          validations:
            - type: "required"
              message: "订单总金额不能为空"
        - name: "status"
          chinese_name: "订单状态"
          type: "enum"
          required: true
          data_dictionary:
            values:
              - value: "pending_payment"
                label: "待支付"
                color: "#FFA500"
              - value: "paid"
                label: "已支付"
                color: "#2196F3"
              - value: "shipped"
                label: "已发货"
                color: "#9C27B0"
              - value: "completed"
                label: "已完成"
                color: "#4CAF50"
              - value: "cancelled"
                label: "已取消"
                color: "#F44336"

      relationships:
        - to: "Customer"
          type: "reference"
          cardinality: "many_to_one"
          label: "placed_by"
          chinese_label: "由客户下单"
          required: true
          bidirectional: true    # Customer 可反向查询其订单

      rules:
        - id: "rule_o001"
          constraint: "total_amount > 0"
          description: "订单总金额必须大于零"
          severity: "error"
          scope: "create"

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

      operations:
        - id: "op_001"
          name: "pay"
          chinese_name: "支付订单"
          parameters:
            - name: "amount"
              type: "number"
              required: true
              label: "支付金额"
              validations:
                - type: "range"
                  min: 0.01
                  message: "支付金额必须大于零"
          rules:
            - condition: "status == 'pending_payment'"
              action: "ALLOW"
              error_message: "只有待支付订单可以支付"
            - condition: "amount >= total_amount"
              action: "ALLOW"
              error_message: "支付金额不足"
            - ref: "rule_o001"
          responses:
            - on: "success"
              actions:
                - "更新订单状态为已支付"
                - "创建支付记录"
              notifications:
                - channel: "sms"
                  template: "payment_success"
                  recipient: "customer"
            - on: "failure"
              actions:
                - "记录支付失败日志"
                - "返回错误信息"

        - id: "op_002"
          name: "ship"
          chinese_name: "发货"
          parameters:
            - name: "tracking_no"
              type: "string"
              required: true
              label: "快递单号"
          rules:
            - condition: "status == 'paid'"
              action: "ALLOW"
              error_message: "只有已支付订单可以发货"
          responses:
            - on: "success"
              actions:
                - "更新订单状态为已发货"
                - "记录发货时间和快递单号"
              notifications:
                - channel: "sms"
                  template: "order_shipped"
                  recipient: "customer"

        - id: "op_003"
          name: "confirm_receipt"
          chinese_name: "确认收货"
          rules:
            - condition: "status == 'shipped'"
              action: "ALLOW"
              error_message: "只有已发货订单可以确认收货"
          responses:
            - on: "success"
              actions:
                - "更新订单状态为已完成"
                - "记录收货时间"

        - id: "op_004"
          name: "cancel"
          chinese_name: "取消订单"
          rules:
            - condition: "status == 'pending_payment'"
              action: "ALLOW"
              error_message: "只有待支付订单可以取消"
          responses:
            - on: "success"
              actions:
                - "更新订单状态为已取消"
              notifications:
                - channel: "sms"
                  template: "order_cancelled"
                  recipient: "customer"

    - id: "obj_004"
      name: "OrderItem"
      chinese_name: "订单行"
      module: "OrderModule"
      attributes:
        - name: "quantity"
          chinese_name: "购买数量"
          type: "number"
          required: true
          data_dictionary:
            min_value: 1
            scale: 0
          validations:
            - type: "required"
              message: "购买数量不能为空"
            - type: "range"
              min: 1
              message: "购买数量至少为1"
        - name: "unit_price"
          chinese_name: "单价"
          type: "number"
          required: true
          computed: true
          data_dictionary:
            min_value: 0.01
            scale: 2
      relationships:
        - to: "Order"
          type: "composition"
          cardinality: "many_to_one"
          label: "belongs_to"
          chinese_label: "属于订单"
          required: true
          cascade_delete: true
        - to: "Product"
          type: "reference"
          cardinality: "many_to_one"
          label: "references"
          chinese_label: "引用商品"
          required: true

function:
  actors:
    - id: "actor_001"
      name: "customer"
      chinese_name: "客户"
      description: "购买商品的用户"
      permissions: ["pay", "confirm_receipt", "cancel"]
    - id: "actor_002"
      name: "admin"
      chinese_name: "管理员"
      description: "处理订单和发货的内部用户"
      permissions: ["ship"]

  scenarios:
    - id: "sc_001"
      name: "customer_places_order"
      chinese_name: "客户下单支付"
      description: "客户选择商品、创建订单并完成支付"
      actor: "customer"
      preconditions: ["客户已登录", "商品库存充足"]
      postconditions: ["订单已创建", "支付已完成"]
      workflow:
        - step: 1
          action: "选择商品和数量"
          actor: "customer"
          objects: ["Product"]
        - step: 2
          action: "确认订单信息和金额"
          actor: "customer"
          objects: ["Order", "OrderItem"]
        - step: 3
          action: "完成支付"
          actor: "customer"
          objects: ["Order"]
    - id: "sc_002"
      name: "admin_ships_order"
      chinese_name: "管理员发货"
      description: "管理员处理已支付订单并完成发货"
      actor: "admin"
      preconditions: ["订单状态为已支付"]
      postconditions: ["订单状态更新为已发货", "客户收到发货通知"]
      workflow:
        - step: 1
          action: "查看待发货订单列表"
          actor: "admin"
          objects: ["Order"]
        - step: 2
          action: "填写快递单号并确认发货"
          actor: "admin"
          objects: ["Order"]

  processes:
    - id: "proc_001"
      name: "order_fulfillment"
      chinese_name: "订单履行流程"
      description: "从客户下单到最终收货的完整业务链"
      actors: ["customer", "admin"]
      start_condition: "客户有购买意向"
      end_condition: "客户确认收货，订单状态为已完成"
      steps:
        - step: 1
          action: "客户创建订单并完成支付"
          actor: "customer"
          related_scenario: "sc_001"
        - step: 2
          action: "管理员审核订单并发货"
          actor: "admin"
          related_scenario: "sc_002"
        - step: 3
          action: "客户确认收货"
          actor: "customer"
```

---

### 6.3 带资料的系统：订单管理（有 PRD 文档）

**特点**：包含 source_materials 顶层字段，演示资料引用

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
      depends_on: ["CustomerModule", "ProductModule"]
      relationships:
        - from: "Order"
          to: "Product"
          type: "many_to_many"
          label: "包含"
          join_object: "OrderItem"

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

      rules:
        - id: "rule_001"
          constraint: "total_amount > 0"
          description: "订单金额必须大于零"
          severity: "error"
        - id: "rule_002"
          constraint: "total_amount > 10000 → requires_approval == true"
          description: "订单金额超过1万需要二级审批"
          severity: "error"
          # 注：此规则来源于 source_materials[].key_extractions[ext_005]

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
          rules:
            - condition: "status == 'pending_payment'"
              action: "ALLOW"
              error_message: "只有待支付订单可以支付"
          responses:
            - on: "success"
              actions:
                - "更新订单状态为已支付"
                - "创建支付记录"

function:
  actors:
    - id: "actor_001"
      name: "customer"
      chinese_name: "客户"
      description: "购买商品的用户"
      # 注：此角色来源于 source_materials[].key_extractions[ext_001]
      permissions: ["create_order", "pay", "confirm_receipt", "cancel"]

    - id: "actor_002"
      name: "admin"
      chinese_name: "管理员"
      description: "处理订单的内部人员"
      # 注：此角色来源于 source_materials[].key_extractions[ext_002]
      permissions: ["approve_order", "ship"]

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
          action: "客户创建订单并完成支付"
          actor: "customer"
          related_scenario: "sc_001"
        - step: 2
          action: "管理员审核订单并发货"
          actor: "admin"
        - step: 3
          action: "客户确认收货"
          actor: "customer"
```

**说明**：
- `source_materials[].key_extractions[]` 记录了从资料中提取的关键信息
- `domain.objects[].rules[].description` 和 `function.actors[].description` 中通过注释标注了信息来源
- `key_extractions[].related_objects` 和 `related_operations` 建立了资料与模型元素的关联
- `conversations[]` 记录了用户对资料摘要的确认过程

---

## 7. 版本兼容性

### 7.1 版本号规则

- 格式：`MAJOR.MINOR`（如 `1.0`, `1.1`, `2.0`）
- MAJOR：结构变更，不向后兼容
- MINOR：新增可选字段，向后兼容

### 7.2 向后兼容性

| 变更类型 | 版本影响 | 兼容性 |
|---------|---------|--------|
| 新增可选字段 | MINOR+1 | ✅ 兼容 |
| 修改字段类型 | MAJOR+1 | ❌ 不兼容 |
| 删除必需字段 | MAJOR+1 | ❌ 不兼容 |
| 新增验证规则 | MINOR+1 | ⚠️ 可能影响现有模型 |

---

## 8. 附录

### 8.1 JSON Schema（待实现）

提供 JSON Schema 版本，用于工具自动验证（待实现）。

### 8.2 验证脚本示例（待实现）

```python
# Python 验证脚本示例（待实现）
def validate_domain_model(yaml_content):
    # 1. YAML 语法验证
    # 2. modeling_approach == "FBS" 检查
    # 3. 必需字段完整性检查
    # 4. 引用完整性验证（状态/操作/角色引用是否存在）
    # 5. 模块循环依赖检查
    # 6. 初始状态唯一性检查
    # 7. 终止状态无出边检查
    pass
```

### 8.3 错误代码完整清单（待实现）

完整的 E001–E999 错误代码详细说明（待实现）。

---

## 9. 与经典方法论的映射

### 9.1 与 UML 的对应

| FBS 层 | UML 图类型 | 对应元素 |
|--------|-----------|---------|
| F 功能层 | 用例图（Use Case Diagram） | Actor → Actor, Scenario → Use Case, Process → System Boundary |
| B 行为层 | 状态图（State Machine Diagram） | State → State, Transition → Transition, Operation → Event/Trigger |
| S 结构层 | 类图（Class Diagram） | Object → Class, Attribute → Attribute, Relationship → Association/Composition/Aggregation |

### 9.2 与 DDD 的对应

| DDD 概念 | FBS 对应 | 说明 |
|---------|---------|------|
| Entity | Object | 业务对象 |
| Value Object | Attribute（reference 类型） | 无独立标识的值 |
| Aggregate | Module + root_object | 模块即聚合边界，主对象即聚合根 |
| Domain Event | Operation Response | 操作成功后触发的事件 |
| Repository | 不在模型中 | 实现细节，不建模 |
| Domain Service | Process 中的 system 步骤 | 跨对象的业务逻辑 |

---

## 版本历史

| 版本 | 日期 | 说明 | 作者 |
|------|------|------|------|
| 1.0 | 2026-03-23 | 从 schema.md §6-9 拆分而来 | Claude |
