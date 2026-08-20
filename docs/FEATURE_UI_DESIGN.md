# Hopp 新功能界面与交互设计

> 本文档描述 v0.8.0 战略转型后的新功能界面与交互。高保真界面稿见 [design/hopp-new-features.html](./design/hopp-new-features.html)（浏览器打开）。

---

## 1. 设计原则

- 延续现有设计语言：Indigo 主色 `#6366F1`、11–12px 紧凑字体、Menlo 等宽、32px URL 栏、28px Tab、卡片式设置。
- **声明式优先**：能配置的不写脚本；能看得见每一步的不做黑盒。
- **AI 是增强不是依赖**：任何 AI 调用失败/超时/未配置都回退，不阻断「发请求」主流程。
- **可保存、可复跑**：AI 产出落到 collection / 环境 / 断言，而非一次性聊天。

## 2. 屏幕地图

| 功能 | 屏幕/入口 | 关键交互 |
|------|-----------|----------|
| 环境变量（M6） | 顶部环境切换器 + 环境管理对话框 | 切换即解析；secret 脱敏/👁/复制 |
| 变量转换（F8.3） | Headers/Body 行内值 + 转换选择器 | 点值 → 选算法 → 实时预览 |
| 预请求链（F8.2） | 请求设置里的「前置请求链」面板 | 配置 login + 提取 + 注入 |
| 认证（F8.1） | Auth Tab | 选类型 → 引用变量 |
| AI 助手（F9） | 主区新增「AI」Tab / 侧面板 | 自然语言 → 生成预览 → 应用 |
| 轻量断言（F4） | Response 区断言面板 | 发送后自动跑、行级通过/失败 |
| OpenAPI 导入（F9 Tier 0） | 导入对话框 | 选文件 → 解析预览 → 生成 collection |

## 3. 关键交互流程

### 3.1 环境变量解析（发送前）

```mermaid
sequenceDiagram
    participant U as 用户
    participant E as 请求编辑器
    participant V as 变量引擎
    U->>E: 点 Send
    E->>V: resolve(request)
    V->>V: 扫描 {{var}}（URL/Header/Body）
    V->>V: 全局 > 环境 > 本地 查找
    V->>V: 应用变量转换（sha1/aes/hmac...）
    V-->>E: 替换后的最终请求
    E->>E: 发送
    E-->>U: Request 详情展示替换前后对比
```

### 3.2 预请求链（登录 → token）

```mermaid
sequenceDiagram
    participant U as 用户
    participant P as 请求执行器
    participant L as 前置请求 login
    participant T as 目标请求
    U->>P: Send GET /users
    P->>L: 1. POST /auth/login（密码经 sha1 转换）
    L-->>P: { data: { token: "..." } }
    P->>P: 2. JSONPath $.data.token → {{token}}
    P->>T: 3. GET /users + Authorization: Bearer {{token}}
    T-->>P: 200 OK
    P-->>U: 展示 Response 与 Request 详情
```

### 3.3 变量转换（声明式管道）

```mermaid
flowchart LR
    A["{{password | sha1}}"] --> B[解析变量名 password]
    B --> C[查找变量值]
    C --> D[应用转换 sha1]
    D --> E[输出哈希值]
    E --> F[注入 Header/Body]
```

### 3.4 AI 自然语言建请求

```mermaid
sequenceDiagram
    participant U as 用户
    participant A as AI 面板
    participant M as 本地模型（Ollama/LM Studio）
    participant C as Collection
    U->>A: "GET 用户列表，带 token 认证"
    A->>M: chat/completions（localhost，防脑补约束）
    M-->>A: 结构化请求（字段仅来自输入）
    A->>U: 生成预览（可编辑）
    U->>A: 应用到请求 / 保存
    A->>C: 写入 collection（引用 {{baseUrl}}/{{token}}）
```

### 3.5 OpenAPI / Swagger 导入（Tier 0）

```mermaid
flowchart TD
    A[选择 openapi.json] --> B[解析 paths/operations/schemas]
    B --> C[生成请求预览]
    C --> D{用户确认}
    D -->|生成| E[写入 collection，URL 用 {{baseUrl}}]
    D -->|取消| F[丢弃]
```

### 3.6 轻量断言

```mermaid
flowchart LR
    A[发送请求] --> B[得到响应]
    B --> C[逐条执行断言：状态码/Header/Body/JSONPath]
    C --> D{全部通过?}
    D -->|是| E[绿色汇总]
    D -->|否| F[红色 + 失败明细]
    E --> G[可导出 hopp run collection.json]
    F --> G
```

### 3.7 API 文档地址 → 自动创建请求

```mermaid
flowchart TD
    A[输入 API 文档地址] --> B{地址类型}
    B -->|openapi.json / swagger.yaml| C[Tier 0 确定性解析，无需模型]
    B -->|Swagger UI / Redoc / 文档站| D[Tier 1/2 模型抓取并提取接口]
    C --> E[生成 collection / 请求]
    D --> E
    E --> F[可编辑预览 → 保存]
```

> 隐私：机器可读地址走 Tier 0 零外发；人类可读网页走 Tier 1 本地模型不出机器、Tier 2 云模型则文档内容外发，需隐私告知门。

## 4. 组件清单（新增）

- `EnvironmentManagerDialog`：环境列表 + 变量 KV 编辑器（secret 脱敏）
- `EnvironmentSwitcher`：顶部/侧边栏下拉切换
- `VariableTransformEditor`：行内值编辑 + 转换选择器 + 实时预览
- `PrerequisiteChainPanel`：前置请求步骤列表（请求选择 + 提取规则 + 注入变量）
- `AuthConfigTab`：Bearer/Basic/API Key 配置
- `AIAssistantPanel`：自然语言输入 + 生成预览 + 应用/保存
- `AssertionEditor`：断言行（源 + 操作符 + 期望值）+ 通过/失败状态
- `OpenAPIImportDialog`：文件选择 + 解析预览 + 生成 collection
- `OpenAICompatibleClient`：`baseURL + model + key` 统一客户端（Tier 1/2 共用）

## 5. 优先级（实现顺序）

1. 环境变量（M6）—— 一切变量能力的地基
2. 预请求链 + 变量转换（F8）—— 直击登录/token/加密痛点
3. OpenAPI 导入（Tier 0）—— 无模型、零隐私成本、最强差异化
4. 轻量断言 + CLI（F4 降级）—— CI 与可被编排
5. AI 本地模型（Tier 1）→ BYOK 云端（Tier 2）
