# Step 0.5：资料理解 - 详细流程文档

> 本文档详细描述 Step 0.5 的执行流程，由 SKILL.md 引用
>
> **触发条件**：Step 0 中用户提供资料（文档/URL/文本）
> **目标**：读取资料内容 → 提取关键信息 → 生成摘要 → 用户确认

---

## 1. 流程概览

```
用户提供资料
    ↓
读取资料内容
    ↓
提取13类关键信息
    ↓
生成结构化摘要
    ↓
用户确认
    ↓
写入 source_materials 字段
    ↓
继续 Step 1（Agent将在后续步骤中引用资料信息）
```

---

## 2. 详细步骤

### 2.1 读取资料内容

**支持类型**：

| type | 工具 | 示例 |
|------|------|------|
| document | Read 工具 | PDF, Word, Markdown, TXT |
| image | vision 能力 | PNG, JPG, 界面截图, 流程图 |
| url | mcp__web_reader__webReader | 产品文档 URL |
| text | 直接使用 | 用户粘贴的文本内容 |

**执行**：

1. **判断资料类型**：
   - 用户提供本地文件路径 → type = "document" 或 "image"
   - 用户提供 URL → type = "url"
   - 用户直接粘贴文本 → type = "text"

2. **读取内容**：
   - document: `Read(file_path="用户提供的本地文件路径")`
   - image: 使用 vision 能力分析图片内容
   - url: `mcp__web_reader__webReader(url="用户提供的URL")`
   - text: 直接使用用户输入的文本

3. **创建 source_materials 条目**（初始状态）：
```yaml
source_materials:
  - id: "src_001"
    name: "资料名称"
    chinese_name: "中文名"
    type: "document"  # 或 image/url/text
    source:
      type: "local"   # 或 url/manual
      path: "E:/docs/prd.pdf"  # 用户提供的本地文件路径
      referenced_at: "2026-03-26T10:00:00Z"  # 资料被引用的时间
    processing:
      status: "processing"  # 初始状态
```

---

### 2.2 提取13类关键信息

**13 类信息类别**（见 schema.md §3.6.4）：

| category | 说明 | 提取示例 |
|----------|------|---------|
| business_goal | 业务目标 | "构建订单管理系统" |
| user_role | 用户角色 | "客户 - 购买商品的用户，可以创建订单、支付、确认收货" |
| business_object | 业务对象 | "订单 - 客户购买商品的记录，包含订单号、金额、状态等" |
| attribute | 属性信息 | "订单号 - 唯一标识，格式 ORD-YYYYMMDD-NNNNNN" |
| relationship | 关系描述 | "订单包含多个商品" |
| business_rule | 业务规则 | "订单金额超过1万需要二级审批" |
| operation | 操作描述 | "客户可以创建订单" |
| constraint | 约束条件 | "订单号必须唯一" |
| scenario | 使用场景 | "客户下单支付场景" |
| pain_point | 痛点问题 | "当前手工记录容易出错" |
| requirement | 需求描述 | "系统需要支持批量导出" |
| assumption | 假设条件 | "假设用户已登录" |
| other | 其他信息 | 未分类信息 |

**提取原则**：

1. **准确提取**：忠实于原文，不臆测或过度解读
2. **置信度评估**：对每条提取信息评估置信度（0-1）
   - 0.95-1.0：明确陈述，无歧义
   - 0.85-0.95：有上下文支持，较明确
   - 0.70-0.85：需要推断，但合理
   - <0.70：不确定，建议不提取或标记为低置信度

3. **来源标注**：记录每条信息的原文位置
   - 文档：页码 + 段落（如"第2页，第1-2段"）
   - 网页：章节标题或锚点
   - 图片：区域描述（如"左上角流程图"）

4. **关联对象/操作**：
   - 如果提取的信息与特定对象相关，记录 `related_objects`
   - 如果与特定操作相关，记录 `related_operations`

**执行示例**：

```yaml
key_extractions:
  - id: "ext_001"
    category: "user_role"
    content: "客户 - 购买商品的用户，可以创建订单、支付、确认收货"
    confidence: 0.95
    source_reference: "第2页，第1-2段"
    related_operations: ["create_order", "pay", "confirm_receipt"]

  - id: "ext_002"
    category: "business_object"
    content: "订单 - 客户购买商品的记录，包含订单号、金额、状态等"
    confidence: 0.96
    source_reference: "第3页，第1段"
    related_objects: ["Customer", "Product", "OrderItem"]

  - id: "ext_003"
    category: "business_rule"
    content: "订单金额超过1万需要二级审批"
    confidence: 0.99
    source_reference: "第5页，第4段"
    related_objects: ["Order"]
    related_operations: ["create_order"]
```

---

### 2.3 生成结构化摘要

**摘要格式**（用于向用户展示）：

```markdown
我已经阅读了您提供的《{资料名称}》，提取了以下关键信息：

┌─────────────────────────────────────────┐
 │  📄 资料类型: {document_type}            │
 │  📊 字数统计: {word_count}              │
 │                                         │
 │  🎯 业务目标:                            │
 │  • {goal_1}                             │
 │  • {goal_2}                             │
 │                                         │
 │  👥 目标用户:                            │
 │  • {role_1}: {role_1_desc}             │
 │  • {role_2}: {role_2_desc}             │
 │                                         │
 │  📦 核心对象:                            │
 │  • {object_1}: {object_1_desc}         │
 │  • {object_2}: {object_2_desc}         │
 │                                         │
 │  📋 业务规则:                            │
 │  • {rule_1}                             │
 │  • {rule_2}                             │
 │                                         │
 │  💡 使用场景:                            │
 │  • {scenario_1}                         │
 │  • {scenario_2}                         │
 └─────────────────────────────────────────┘

这些信息准确吗？有没有需要补充或修改的地方？
```

**摘要生成原则**：

1. **按类别组织**：将提取的信息按 category 分组
2. **突出重点**：优先展示高置信度（≥0.90）的信息
3. **简洁明了**：每个类别展示 3-5 条最重要的信息
4. **用户友好**：使用自然语言，避免技术术语

**示例**：

```markdown
我已经阅读了您提供的《产品需求文档》，提取了以下关键信息：

┌─────────────────────────────────────────┐
 │  📄 资料类型: PDF文档                    │
 │  📊 字数统计: 约5230字                  │
 │                                         │
 │  🎯 业务目标:                            │
 │  • 构建订单管理系统，处理电商订单流程    │
 │  • 提高订单处理效率，减少人工错误        │
 │                                         │
 │  👥 目标用户:                            │
 │  • 客户: 购买商品的用户，可以创建订单、支付、确认收货 │
 │  • 管理员: 处理订单的内部人员，负责审核订单和发货 │
 │                                         │
 │  📦 核心对象:                            │
 │  • 订单: 客户购买商品的记录，包含订单号、金额、状态等 │
 │  • 产品: 被购买的商品                   │
 │  • 客户: 购买商品的用户                 │
 │                                         │
 │  📋 业务规则:                            │
 │  • 订单金额超过1万需要二级审批           │
 │  • 待支付订单超过24小时自动取消          │
 │                                         │
 │  💡 使用场景:                            │
 │  • 客户下单支付场景                      │
 │  • 管理员审核发货场景                    │
 └─────────────────────────────────────────┘

这些信息准确吗？有没有需要补充或修改的地方？
```

---

### 2.4 用户确认

**确认流程**：

1. **展示摘要**（如上节所示）
2. **等待用户反馈**：
   - 用户确认："准确"、"对"、"是的" → 继续下一步
   - 用户修改："{内容}不对，应该是..." → 更新提取信息，重新展示摘要
   - 用户补充："还有..." → 添加新信息，重新展示摘要

3. **处理用户修改**：
   - 修改提取内容的 `content` 字段
   - 降低 `confidence`（如果用户纠正了提取错误）
   - 添加 `conversations` 记录

4. **记录确认**：
```yaml
conversations:
  - step: "Step 0.5"
    timestamp: "2026-03-26T10:05:00Z"
    context: "用户确认资料摘要准确"
    confirmation: true
```

---

### 2.5 更新 source_materials

**最终状态**：

```yaml
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
      # ... 更多提取项

    processing:
      status: "completed"
      processed_at: "2026-03-26T10:05:00Z"
      processor_version: "v1.0"

    conversations:
      - step: "Step 0.5"
        timestamp: "2026-03-26T10:05:00Z"
        context: "用户确认资料摘要准确"
        confirmation: true
```

---

## 3. 后续引用

**在 Step 1-6 中引用资料信息**：

- **Step 2（角色场景分析）**：
  - 检查 `key_extractions` 中 `category == "user_role"` 的项
  - 如果有："从您的资料中，我识别出这些角色：{列表}，对吗？"

- **Step 3（业务对象识别）**：
  - 检查 `key_extractions` 中 `category == "business_object"` 的项
  - 如果有："从您的描述和资料中，我识别出这些对象：{列表}"

- **Step 4-5（状态与规则建模）**：
  - 检查 `key_extractions` 中 `category == "business_rule"` 的项
  - 如果有："根据您的资料，{规则内容}，对吗？"

**引用格式**：

```
"根据您提供的《{资料名称}》，我了解到：
{引用内容}

基于此，我的问题是..."
```

---

## 4. 异常处理

### 4.1 资料读取失败

**场景**：文件损坏、URL 无法访问、图片无法识别

**处理**：
1. 告知用户："抱歉，我无法读取这个{资料类型}，原因：{错误信息}"
2. 提供选项：
   - A. 重新提供路径
   - B. 跳过，直接描述
3. 更新 `processing.status = "failed"`

### 4.2 提取信息置信度过低

**场景**：资料内容模糊、不完整，大部分提取项 confidence < 0.70

**处理**：
1. 展示低置信度的提取项
2. 提示用户："这些信息我不太确定，请您确认或补充"
3. 标记 `confidence` 值，供后续参考

### 4.3 资料与用户描述冲突

**场景**：用户口头描述与资料内容不一致

**处理**：
1. 展示冲突："您的资料中提到{资料内容}，但您刚才说{用户描述}，哪个是正确的？"
2. 以用户确认为准
3. 记录冲突在 `conversations` 中

---

## 5. 提示词模板

**资料摘要展示模板**（见 §2.3）

**资料引用模板**（用于 Step 1-6）：

```markdown
"根据您提供的《{资料名称}》（第{页码}页），我了解到：

{引用内容}

基于此，我想确认：{问题}？"
```

**示例**：

```markdown
"根据您提供的《产品需求文档》（第5页），我了解到：

订单金额超过1万需要二级审批

基于此，我想确认：这个审批流程需要哪些角色参与？"
```

---

## 6. 完成条件

Step 0.5 完成需满足：

- ✅ 资料内容已成功读取
- ✅ 关键信息已提取并结构化存储
- ✅ 摘要已展示给用户
- ✅ 用户已确认（或修改后确认）
- ✅ `source_materials` 字段已写入 `domain-model.yaml`
- ✅ `processing.status = "completed"`

完成后，Agent 将在 Step 1-6 中自动引用资料信息辅助建模。

---

*文档版本: 1.0*
*最后更新: 2026-03-26*
