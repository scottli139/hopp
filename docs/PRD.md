# 需求规格说明书 (PRD)

## 产品概述

**Hopp** 是一款**本地优先、数据不出机器的 API 工作台**：轻量、跨平台，基于 Flutter 构建，把 AI 的便利嫁接在本地工具的隐私上。

**定位**:
- 跟 Postman 比：隐私、轻量、无账号、数据本地
- 跟纯 AI 聊天比：确定性（collection/环境/断言可保存、可复跑）、零数据外泄

**口号**: *Hop to your APIs*（跃向你的 API）

**战略方向（2026-08-20 决策）**: 不追平 Postman 功能集，聚焦两个核心楔子——**F8 预请求链与变量转换**、**F9 本地 + 私有 AI（三层）**。里程碑与排期见 [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md)，未排期候选见 [BACKLOG.md](./BACKLOG.md)。

---

## 功能需求

### 一、核心请求功能

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F1.1 | HTTP 请求发送 | ✅ | 支持 GET/POST/PUT/DELETE/PATCH/HEAD/OPTIONS | 所有方法可正常发送请求并接收响应 |
| F1.2 | 请求参数设置 | ✅ | Query Params、Path 参数编辑 | URL 自动编码，参数可增删改 |
| F1.3 | 请求头管理 | ✅ | Headers 编辑、常用头预设、自动完成 | 支持批量编辑，Header Key 自动建议 |
| F1.4 | 请求体编辑 | ✅ | JSON/Form-data/Form-urlencoded/Raw/Binary/GraphQL | 每种类型有对应的编辑器，JSON 语法高亮 |
| F1.5 | 响应展示 | ✅ | 显示状态码、响应时间、响应大小 | 实时显示在响应区域 |
| F1.6 | 响应格式化 | ✅ | 自动美化 JSON/XML/HTML | 支持语法高亮和折叠 |
| F1.7 | 响应预览 | ✅ | 原始/预览/JSON/图片等多种视图 | 自动识别 Content-Type 切换视图 |
| F1.8 | Cookie 管理 | ⏸️ | 查看/编辑/导入 Cookie | Cookie 列表展示，支持手动添加 |
| F1.9 | 文件上传/下载 | ⏸️ | multipart/form-data、文件下载 | 支持文件选择、进度显示 |
| F1.10 | cURL 生成 | ⏳ | cURL 命令生成与复制 | 一键复制生成的 cURL 命令（后续并入 Tier 0，见 F9） |
| F1.11 | HTTPS 证书查看 | ✅ | 查看 SSL/TLS 证书详细信息 | 证书颁发者、有效期、域名、指纹等 |
| F1.12 | 请求时间分析 | ✅ | 展示请求各环节耗时 | DNS、TCP、SSL、TTFB、下载时间分段展示 |
| F1.13 | 请求详情展示 | ✅ | 显示实际发送的请求信息 | 展示变量替换后的最终 URL、Headers、Body |
| F1.14 | 请求设置 | 🟡 部分实现 | 请求级别的配置选项 | SSL 验证、Follow Redirects、Max Redirects 已实现（3 项），其他配置项待完成 |

#### F1.14 请求设置 (Request Settings) 详细需求

**功能概述**: 提供请求级别的精细配置，允许用户针对单个请求覆盖全局默认行为。

**设置项清单**:

| 设置项 | 控件类型 | 默认值 | 需求描述 | 状态 |
|--------|----------|--------|----------|------|
| HTTP Version | Dropdown | Auto | 选择 HTTP/1.1 或 HTTP/2，Auto 由系统自动选择 | ⏳ |
| Enable SSL certificate verification | Toggle | ON | 开启/关闭 SSL 证书验证，关闭后允许访问自签名证书 | ✅ 已实现 |
| Automatically follow redirects | Toggle | ON | 是否自动跟随 3xx 重定向响应 | ✅ 已实现 |
| Follow original HTTP Method | Toggle | OFF | 重定向时是否保持原始 HTTP 方法（默认转为 GET）| ⏳ |
| Follow Authorization header | Toggle | OFF | 跨域重定向时是否保留 Authorization Header | ⏳ |
| Remove referer header on redirect | Toggle | OFF | 重定向时是否自动移除 Referer Header | ⏳ |
| Enable strict HTTP parser | Toggle | OFF | 是否严格解析 HTTP 响应头，遇到无效 header 时失败 | ⏳ |
| Encode URL automatically | Toggle | ON | 自动对 URL 路径、查询参数进行百分号编码 | ⏳ |
| Disable cookie jar | Toggle | OFF | 禁用此请求的 Cookie 存储和发送，Cookie 完全隔离 | ⏳ |
| Use server cipher suite during handshake | Toggle | OFF | TLS 握手时优先使用服务器提供的加密套件顺序 | ⏳ |
| Maximum number of redirects | Number Input | 10 | 设置最大重定向次数，0 表示不限制 | ✅ 已实现 |
| TLS/SSL protocols disabled | Multi-select | - | 选择禁用的 TLS/SSL 协议版本（如 SSLv3、TLS1.0）| ⏳ |
| Cipher suite selection | Text Input | - | 自定义加密套件列表，留空使用系统默认 | ⏳ |

**交互需求**:
1. 每个设置项显示「默认值: Settings」提示，表示继承全局设置
2. 修改设置后显示「已修改」标记（如点状指示器）
3. 支持「重置为默认」功能
4. 设置与请求数据一起持久化到 Collection

**技术需求**:
1. Dio HTTP 客户端需支持动态 Options 配置
2. SSL/TLS 高级设置需要平台原生支持
3. 设置变更实时生效，无需重启应用

**UI 规范**:
- 设置项采用卡片式布局
- 分组标题使用 11px Tiny 样式（如 SSL/TLS、Coming Soon）
- 设置项标题使用 12px Caption 样式
- 描述文字使用 11px Tiny 样式
- Switch 开关尺寸 24×14px（Material 默认 60% 缩放）
- Switch ON 状态：Indigo 500 轨道
- Switch OFF 状态：outlineVariant 轨道
- 状态文字 ON/OFF 使用 12px Caption 样式

---

### 二、集合与组织功能 ⏳

> **状态说明**: 基础 Collection/Folder/Request 管理已完成，但请求历史、收藏、拖拽排序待实现。

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F2.1 | 请求历史 | ⏳ | 自动保存最近请求记录 | 保留最近 100 条，支持搜索 |
| F2.2 | 收藏请求 | ⏳ | 手动收藏常用请求 | 收藏列表独立展示 |
| F2.3 | 文件夹/集合 | ✅ | 按项目/模块组织请求 | 支持嵌套文件夹 |
| F2.4 | [导入/导出](#f24-导入导出-postman-格式) | ✅ | Postman 集合导入/导出 | 支持 v2.1 格式，数据不丢失 |
| F2.5 | 请求重命名 | ✅ | 修改请求名称 | 在编辑器和侧边栏支持修改请求名称 |
| F2.6 | cURL 导入 | ✅ | 解析 cURL 命令创建请求 | 支持从剪贴板/文件导入，快速复现接口 (v0.6.0) |
| F2.7 | 拖拽排序 | ⏳ | Collection/Folder/Request 拖拽排序 | 支持拖拽调整顺序和层级 |

#### F2.6 cURL 导入详细需求

**国内痛点**: 后端文档提供 cURL 示例、浏览器开发者工具复制、日志抓取重放，需要快速转换为可视化请求。

**功能概述**:
- 解析标准 cURL 命令，自动填充 Method、URL、Headers、Body
- 支持从剪贴板粘贴、文件导入、直接输入三种方式
- 解析结果可导入当前请求或创建新标签页

**支持的 cURL 选项**:

| 选项 | 说明 | 映射目标 |
|------|------|----------|
| `-X, --request` | HTTP 方法 | request.method |
| `-H, --header` | 请求头 | request.headers |
| `-d, --data` | POST 数据 (application/x-www-form-urlencoded) | request.body |
| `--data-raw` | 原始 POST 数据 | request.body |
| `--data-binary` | 二进制数据 | request.body |
| `--data-urlencode` | URL 编码数据 | request.body + 编码处理 |
| `-F, --form` | multipart/form-data | request.bodyType = formData |
| `-u, --user` | 用户认证 (Basic Auth) | Authorization header |
| `-k, --insecure` | 跳过 SSL 验证 | validateCertificates = false |
| `-L, --location` | 跟随重定向 | followRedirects = true |
| `--max-redirs` | 最大重定向次数（未实现） | — |
| `-b, --cookie` | Cookie 数据（未实现） | — |
| `-A, --user-agent` | User-Agent（未实现） | — |
| `-e, --referer` | Referer（未实现） | — |
| `--compressed` | 接受压缩响应（未实现） | — |

**复杂场景支持**:

1. **多行 cURL 命令**:
   ```bash
   curl -X POST 'https://api.example.com/user' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer token' \
     -d '{"name":"test"}'
   ```

2. **文件上传**:
   ```bash
   curl -F "file=@/path/to/image.png" \
        -F "name=avatar" \
        https://api.example.com/upload
   ```

3. **URL 编码数据**:
   ```bash
   curl --data-urlencode "name=中文内容" \
        --data-urlencode "page=1" \
        https://api.example.com/search
   ```

**导入方式**:

| 方式 | 交互 | 场景 |
|------|------|------|
| 剪贴板粘贴 | 右键菜单（`Cmd+Shift+V` 未实现） | 从文档/聊天复制后快速导入 |
| 文件导入 | 选择 `.sh` 或 `.txt` 文件 | 批量导入多个 cURL |
| 输入框 | 对话框文本框 | 手动输入或调整 |

**UI 设计**:
```
┌─────────────────────────────────────────┐
│  从 cURL 导入                            │
├─────────────────────────────────────────┤
│                                         │
│  粘贴 cURL 命令:                         │
│  ┌─────────────────────────────────┐    │
│  │ curl -X POST \\\                │    │
│  │   -H "Content-Type: json" \\\   │    │
│  │   -d '{"key":"value"}' \\\      │    │
│  │   https://api.com/endpoint      │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [粘贴] [从文件...]  [清除]              │
│                                         │
│  ───────────── 或 ─────────────         │
│                                         │
│  [拖放 .sh/.txt 文件到此处]              │
│                                         │
├─────────────────────────────────────────┤
│  [取消]                    [导入并发送]  │
└─────────────────────────────────────────┘
```

**解析结果预览**:
```
┌─────────────────────────────────────────┐
│  解析结果                                │
├─────────────────────────────────────────┤
│  方法: POST                             │
│  URL: https://api.example.com/user      │
│  Headers: 3 个                           │
│    - Content-Type: application/json     │
│    - Authorization: Bearer xxx          │
│    - User-Agent: curl/7.64.1            │
│  Body: JSON (45 bytes)                  │
│  SSL验证: 启用                           │
│  跟随重定向: 否                          │
├─────────────────────────────────────────┤
│  [重新编辑]  [仅导入]  [导入并发送]      │
└─────────────────────────────────────────┘
```

**快捷键**:
- `Cmd+Shift+V` - 从剪贴板导入 cURL（未实现）
- `Cmd+Shift+I` - 打开导入对话框（含 Postman/cURL 选项）（未实现）

**错误处理**:

| 错误类型 | 提示 |
|----------|------|
| 空输入 | "请输入 cURL 命令" |
| 格式无效 | "无法解析 cURL 命令，请检查格式" |
| 不支持的选项 | "警告: 忽略不支持的选项 --xxx" |
| URL 缺失 | "cURL 命令缺少 URL" |

#### F2.4 导入/导出 (Postman 格式) 详细需求

**功能概述**: 支持与 Postman 格式的双向数据交换，方便用户从 Postman 迁移到 Hopp，或与使用 Postman 的团队成员协作。

**支持格式**:
- **Collection v2.1**: Postman 集合标准格式（主要支持）
- **Collection v2.0**: 向后兼容（导入支持）
- **Environment**: Postman 环境变量格式

##### 2.4.1 导入功能

**入口位置**:
1. 侧边栏 Collection 区域的「导入」按钮
2. 主菜单 File → Import
3. 拖放文件到应用窗口（可选）

**支持导入内容**:

| 数据类型 | 来源 | 映射目标 | 支持状态 |
|----------|------|----------|----------|
| Collection | `.json` 文件 | Hopp Collection | ✅ 完整支持 |
| Folder | Collection 内 folder | Hopp Folder | ✅ 完整支持 |
| Request | Collection 内 item | Hopp Request | ✅ 完整支持 |
| Environment | `.json` 文件 | Hopp Environment | ✅ 完整支持 |
| Global Variables | Postman globals | Hopp Global Variables | ⏳ 后续支持 |

**请求字段映射**:

| Postman 字段 | Hopp 字段 | 说明 |
|--------------|-----------|------|
| `name` | `name` | 请求/集合名称 |
| `request.method` | `method` | HTTP 方法 |
| `request.url.raw` | `url` | 完整 URL |
| `request.url.query` | `queryParams` | 查询参数列表 |
| `request.header` | `headers` | 请求头列表 |
| `request.body.mode` | `bodyType` | body 类型映射 |
| `request.body.raw` | `body` | raw 模式内容 |
| `request.body.urlencoded` | `body` + `bodyType` | form-urlencoded 内容 |
| `request.body.formdata` | `body` + `bodyType` | form-data 内容 |
| `request.description` | `description` | 请求描述 |

**Body 类型映射表**:

| Postman mode | Hopp BodyType | 处理方式 |
|--------------|---------------|----------|
| `raw` + `raw.raw` | `BodyType.raw` | 直接映射，根据语言设置子类型 |
| `raw` + `raw.options.language=json` | `BodyType.raw` + `rawContentType=json` | JSON 子类型 |
| `urlencoded` | `BodyType.formUrlEncoded` | key-value 转换 |
| `formdata` | `BodyType.formData` | 支持 text/file 类型 |
| `graphql` | `BodyType.graphql` | query + variables |
| `binary` | `BodyType.binary` | 文件路径引用 |

**导入流程**:
```
1. 用户选择文件 → 显示文件选择器
2. 解析文件 → 检测格式版本 (v2.0/v2.1)
3. 验证数据 → 检查必填字段完整性
4. 冲突处理 → 同名 Collection 提示覆盖/重命名/跳过
5. 数据转换 → 映射到 Hopp 模型
6. 保存数据 → 写入 Hive 存储
7. 刷新 UI → 更新侧边栏和通知用户
```

**冲突处理策略**:

| 场景 | 处理方式 |
|------|----------|
| 同名 Collection 已存在 | 弹窗选择：覆盖 / 重命名导入 / 合并 / 取消 |
| 环境变量同名 | 自动重命名（添加数字后缀） |
| 不支持的 body 类型 | 跳过该请求，记录警告日志 |
| 无效的 URL 格式 | 保留原值，添加标记提示用户 |

##### 2.4.2 导出功能

**入口位置**:
1. 侧边栏 Collection 右键菜单 →「导出」
2. 侧边栏 Collection 操作按钮 → 导出图标
3. 主菜单 File → Export → Collection

**导出选项**:

| 选项 | 默认值 | 说明 |
|------|--------|------|
| 格式版本 | v2.1 | v2.1 或 v2.0 |
| 包含环境变量 | 否 | 是否同时导出关联的环境（**未实现**：`ExportOptions.includeEnvironment` 存在但未接线，见 F3.7） |
| 美化输出 | 是 | JSON 是否格式化缩进 |
| 文件名 | `{collection_name}.postman_collection.json` | 默认文件名 |

**导出字段映射** (Hopp → Postman):

| Hopp 字段 | Postman 字段 | 默认值/处理 |
|-----------|--------------|-------------|
| `name` | `info.name` | - |
| `id` | `info._postman_id` | 生成 UUID |
| `description` | `info.description` | 空字符串 |
| `folders` | `item` (type: folder) | 递归处理 |
| `requests` | `item` (type: request) | 递归处理 |
| `method.value` | `request.method` | 大写 |
| `url` | `request.url.raw` | 完整 URL |
| `queryParams` | `request.url.query` | 过滤 enabled |
| `headers` | `request.header` | 过滤 enabled |
| `bodyType` | `request.body.mode` | 反向映射 |
| `body` | `request.body.*` | 根据类型填充 |

**导出流程**:
```
1. 用户选择 Collection → 弹出导出选项对话框
2. 配置选项 → 格式版本、美化、包含环境等
3. 构建数据结构 → 从 Hopp 模型转换为 Postman Schema
4. 序列化 JSON → 生成符合格式的 JSON 字符串
5. 选择保存路径 → 显示系统文件保存对话框
6. 写入文件 → 保存到用户指定位置
7. 完成通知 → 显示成功提示和文件路径
```

##### 2.4.3 Environment 导入/导出

**环境变量映射**:

| Postman 字段 | Hopp 字段 | 说明 |
|--------------|-----------|------|
| `name` | `name` | 环境名称 |
| `values` | `variables` | 变量列表 |
| `values[].key` | `key` | 变量名 |
| `values[].value` | `value` | 变量值 |
| `values[].enabled` | `enabled` | 是否启用 |
| `values[].type` | `type` | 类型 (default/secret) |

**类型映射**:
- Postman `default` → Hopp `VariableType.string`
- Postman `secret` → Hopp `VariableType.secret`（敏感信息）

##### 2.4.4 错误处理与日志

**导入错误类型**:

| 错误码 | 描述 | 用户提示 |
|--------|------|----------|
| `INVALID_JSON` | JSON 解析失败 | "文件格式无效，请检查 JSON 格式" |
| `UNSUPPORTED_VERSION` | 版本不支持 (v1.0) | "不支持的 Postman 版本，请使用 v2.0+" |
| `MISSING_REQUIRED_FIELD` | 缺少必填字段 | "数据不完整，缺少必要字段: {field}" |
| `INVALID_URL` | URL 格式无效 | "部分请求 URL 格式无效，已保留原值" |
| `EMPTY_COLLECTION` | 集合为空 | "导入的集合不包含任何请求" |

**日志记录**:
- 导入/导出操作的详细日志（info 级别）
- 跳过的请求和原因（warning 级别）
- 解析错误详情（error 级别）

##### 2.4.5 UI/UX 设计

**导入对话框**:
```
┌─────────────────────────────────────────┐
│  导入 Postman 数据                        │
├─────────────────────────────────────────┤
│                                         │
│  [拖放文件到此处或点击选择]                │
│                                         │
│  支持的格式:                             │
│  • Postman Collection v2.0/v2.1 (.json)  │
│  • Postman Environment (.json)           │
│                                         │
├─────────────────────────────────────────┤
│  [取消]              [选择文件...]        │
└─────────────────────────────────────────┘
```

**冲突处理对话框**:
```
┌─────────────────────────────────────────┐
│  发现同名 Collection                     │
├─────────────────────────────────────────┤
│                                         │
│  "My API" 已存在，请选择处理方式:          │
│                                         │
│  (•) 覆盖现有 Collection                 │
│  ( ) 重命名为 "My API (1)"               │
│  ( ) 合并（保留现有，添加新请求）           │
│  ( ) 跳过此 Collection                   │
│                                         │
│  [ ] 对所有冲突应用相同选择                │
│                                         │
├─────────────────────────────────────────┤
│  [取消]                    [确认导入]     │
└─────────────────────────────────────────┘
```

**导出对话框**:
```
┌─────────────────────────────────────────┐
│  导出 Collection                         │
├─────────────────────────────────────────┤
│                                         │
│  集合名称: My API                        │
│                                         │
│  格式版本: [v2.1 ▼]                     │
│                                         │
│  [√] 美化 JSON 输出                      │
│  [ ] 包含关联的环境变量                   │
│                                         │
│  文件名: My API.postman_collection.json  │
│                                         │
├─────────────────────────────────────────┤
│  [取消]                    [导出]        │
└─────────────────────────────────────────┘
```

##### 2.4.6 验收标准

**导入功能**:
- [x] 支持导入 Postman Collection v2.1 格式
- [x] 支持导入 Postman Collection v2.0 格式
- [x] 支持导入 Postman Environment 格式
- [x] 正确映射所有 HTTP 方法
- [x] 正确映射所有 Body 类型 (raw/form-data/urlencoded/graphql/binary)
- [x] 正确处理查询参数和请求头
- [x] 同名 Collection 冲突处理机制
- [x] 导入失败时显示清晰的错误信息
- [x] 导入成功后刷新侧边栏显示

**导出功能**:
- [x] 支持导出为 Postman Collection v2.1 格式
- [x] 导出文件可在 Postman 中正常打开
- [x] 支持选择格式版本 (v2.1/v2.0)
- [x] 支持美化/压缩 JSON 输出
- [x] 导出包含完整的请求信息
- [ ] 导出环境变量（可选）——**未实现**：`ExportOptions.includeEnvironment` 存在但未接线，导出入口也无该选项；待实现后转 ✅（与 F3.7 联动）
- [x] 导出成功后显示文件保存路径

---

### 三、环境变量功能 ✅ 核心已完成（2026-08-21，M8.1）

> **决策（2026-08-20）**: 做。但定位为「可复用 + AI 变量注入的基础」，不是「追平 Postman 的 checklist 项」。AI 生成的请求引用 `{{baseUrl}}` / `{{token}}`，而非硬编码。
>
> **现状（2026-08-21）**: F3.1-F3.5 已由 M8.1 落地（多环境 + 全局变量 + `{{var}}` 替换引擎 + 动态变量 + secret 掩码 + 未定义变量警告），详细设计见 [IMPLEMENTATION_NOTES.md](./IMPLEMENTATION_NOTES.md#环境变量系统-m81)。

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F3.1 | 环境变量 | ✅ | 不同环境（开发/测试/生产） | 可创建多个环境配置 |
| F3.2 | 全局变量 | ✅ | 跨环境共享变量 | 独立于环境的全局变量 |
| F3.3 | 变量替换 | ✅ | URL/Headers/Body 中使用 `{{var}}` | 发送前自动替换变量 |
| F3.4 | 变量作用域 | ✅ | 环境 > 全局 优先级（就近原则） | 正确解析同名变量 |
| F3.5 | 动态变量 | ✅ | `{{$timestamp}}` / `{{$randomUUID}}` 等 5 个 | 发送时实时生成 |
| F3.6 | 变量转换 | ✅ | 内置哈希/加密/签名函数 | 已由 F8.3 落地（`{{var \| fn}}` 管道全量算法，M8.2 / v0.10.0，2026-08-25） |
| F3.7 | 环境导出 | ⏳ | 导出为 Postman Environment 格式 | 导出文件可被 Postman 正常导入（导入已支持，见 F2.4） |
| F3.8 | 变量悬停预览/快速编辑 | ⏳ | 悬停显示变量值，双击快速编辑 | 编辑器内可直接查看解析结果 |

---

### 四、测试与断言功能 🔄 部分完成（F4.1/F4.4 ✅ v0.12.0；F4.2 ⏳ M8.5）

> **决策（2026-08-20）**: 不做 Postman 兼容的完整 JS 沙箱 + pre-request/test script。AI 时代「写断言脚本」正是 LLM 的强项。
>
> - 预请求的「动态签名 / 加密 / 拿 token」能力，改由 **F8 预请求链 + 变量转换** 承担（声明式，零门槛）。
> - 测试能力降级为：轻量断言子集 + AI 生成断言 + 导出给 CLI/CI 跑。
> - F4.1 / F4.4 已由 M8.4 交付（v0.12.0，2026-08-28）；F4.2 随最小 AI 客户端排期 M8.5（2026-08-28 调整）；F4.3 批量运行在其后视需求排期。

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F4.1 | 响应断言（轻量） | ✅ | 状态码 / Header / Body / JSONPath / 响应时间断言 | 无需写代码，UI 配置断言规则（M8.4 / v0.12.0，2026-08-28） |
| F4.2 | 断言生成（AI） | ⏳ → M8.5 🔄 | 由 AI 根据响应样本生成断言 | 一键生成、可编辑、可保存 |
| F4.3 | 批量运行 | ⏳ | 集合级别批量执行 + 断言 | 顺序/并行，导出 CSV/HTML 报告 |
| F4.4 | CLI / CI 导出 | ✅ | 将集合 + 断言导出为可运行脚本 | 在 CI 中 `hopp run collection.hopp.json`（M8.4 / v0.12.0，2026-08-28） |

> 原 F4.2 Pre-request Script / F4.3 Test Script（JS 沙箱）已 **取消**，能力并入 F8。

#### F4 详案：M8.4 轻量断言 + CLI/CI（2026-08-28 澄清确认）

**范围**

| 项 | 决策 |
|----|------|
| 本期 | F4.1 轻量断言（规则模型 + 求值引擎 + 结果 UI）+ F4.4 CLI/CI 导出与运行器 |
| 挪出 | F4.2 AI 生成断言 → M8.5（依赖 F9.3 单一 OpenAI 兼容客户端，与本地模型能力一起落地，避免 M8.4 提前背负设置页/密钥存储/隐私门基础设施） |
| 不在本期 | F4.3 应用内批量运行与 CSV/HTML 报告；Postman `pm.test` 脚本导入/导出；Newman 兼容导出（违背无 JS 决策，且断言/预请求链无法表达）；集合级默认断言 |

**F4.1 断言规则模型**（声明式，零代码；每条规则四要素 + 启用开关）

| 要素 | 取值 |
|------|------|
| 目标 | Status code / Header（指定名）/ Body 文本 / JSONPath / Response time |
| 操作符 | equals · not equals · contains · not contains · exists · not exists · regex · `>` `<` `>=` `<=`（按目标类型过滤可用集） |
| 期望值 | 字符串，支持 `{{var}}` 插值（复用变量解析器） |
| 启用开关 | 单条可禁用而不删除 |

- 存储：**请求级**（`HttpRequest` 新增字段，Hive 追加 field，存量数据兼容）；JSONPath 用成熟纯 Dart 包（`json_path`），不自写
- 结果 UI：响应区新增 **Tests** 页签——逐条 pass/fail + 实际值 vs 期望值，失败高亮；响应摘要栏 `n/m passed` 徽标；每次 Send 后自动求值，不阻断请求流程

**F4.4 CLI/CI**

| 项 | 决策 |
|----|------|
| 形态 | repo 内 `cli/` 目录（app 包内，非独立 pub 包），import `lib/` 纯 Dart 部分（HTTP/变量/预请求链/断言求值），不依赖 Flutter；`fvm dart compile exe cli/hopp.dart` 可编译单文件二进制 |
| 导出格式 | 原生 `.hopp.json`（全保真：断言、预请求链、Auth、变量转换），在现有 Export 对话框加 FORMAT 选项（Postman v2.1 / Hopp CLI），不单列菜单入口；Postman 导出保持原样不掺断言 |
| 运行 | `hopp run <file> [--env 环境名\|外部 env 文件路径] [--env-var K=V]… [--timeout <ms>]`：DFS 顺序执行请求，跑预请求链 + `{{var}}` 管道 + 断言；exit 0=全过 / 1=有失败 / 2=用法错误 |
| 报告 | `--reporter console（默认）\|json\|junit` + `--output path` 输出文件（JUnit XML 可直接接入 GitHub Actions / GitLab CI） |
| 密钥 | `isSecret` 变量导出时置空；CLI 侧用 `--env-var KEY=VALUE` 或进程环境变量注入 |
| 分发 | 已交付：`fvm dart run cli/hopp.dart run <file>` 本地跑、`dart compile exe` 编译分发；「release 页附三平台 CLI 二进制（CI 加 `dart compile exe`）」**未落地**（CI 暂无 CLI 构建步骤，见 [GITHUB_SETTINGS](./GITHUB_SETTINGS.md)） |

**实施顺序**：F4.1（模型 + 求值引擎 + UI）→ F4.4（导出 + CLI，复用求值引擎）；每步独立可发布。

**验收标准**

- [x] 五类目标 + 操作符按表可配，期望值 `{{var}}` 生效，单条启停生效
- [x] Tests 页签逐条展示 pass/fail 与实际值，摘要徽标准确，求值不阻断发送
- [x] 断言随请求持久化，重启不丢；存量数据无迁移问题（Hive 追加 field 17，手写 adapter 兼容）
- [x] Export for CLI 导出全保真 JSON（含断言/预请求链/Auth，secret 置空）
- [x] `hopp run` 顺序执行并通过 exit code 反映断言结果；`--reporter junit` 产出可被 CI 识别的 XML
- [x] 求值引擎为纯 Dart，GUI 与 CLI 共用同一套结果

### 五、UI/UX 功能

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F5.1 | 多标签页 | ✅ | 同时打开多个请求 | 标签可切换、关闭 |
| F5.2 | 深色/浅色主题 | ✅ | 主题切换 | 跟随系统或手动切换 |
| F5.3 | 快捷键支持 | ✅ | 常用操作快捷键 | Cmd+N, Cmd+Enter, Cmd+S, Cmd+W |
| F5.4 | 响应体搜索 | ⏸️ | 在响应内容中搜索 | 支持正则，高亮匹配 |
| F5.5 | 分屏视图 | ✅ | 请求/响应上下布局 | 可拖拽调整分割比例 |
| F5.6 | 字体缩放 | ⏸️ | 编辑器字体大小调整 | Ctrl+滚轮或设置调整 |

### 六、数据与同步功能

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F6.1 | 本地存储 | ✅ | Hive/SharedPreferences 存储数据 | 数据持久化，应用重启不丢失 |
| F6.4 | 数据备份 | ⏳ | 自动/手动备份 | 可导出完整数据备份 |
| F6.2 | 云端同步 | Backlog | 用户数据云存储，跨设备同步 | 与本地优先定位冲突，谨慎评估 |
| F6.3 | 团队协作 | Backlog | 多人实时协作编辑 | 依赖云端同步，远期 |

### 七、高级功能（⏸️ 整体暂缓）

> **决策（2026-08-20）**: 以下均为非差异化能力，整体暂缓；待核心楔子（F8 / F9）落地后视需求重启。已完成的详细需求保留存档，重启时直接可用。

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F7.1 | WebSocket 测试 | ⏸️ 暂缓 | WebSocket 连接测试 | 支持 ws/wss，消息收发 |
| F7.3 | API 文档生成 | ⏸️ 暂缓 | 从集合生成文档 | 导出 Markdown/HTML |
| F7.4 | Mock 服务 | ⏸️ 暂缓 | 本地 Mock 服务器 | 详细需求见下方存档 |
| F7.5 | 代理设置 | ⏸️ 暂缓 | HTTP/HTTPS 代理 | 支持系统代理和自定义代理 |
| F7.6 | 代码生成 | ⏸️ 暂缓 | 生成 Python/JS/cURL 等代码 | 多语言生成暂缓；cURL 生成（F1.10）保留，后续并入 Tier 0 |
| F7.7 | gRPC 测试 | Backlog | Protocol Buffers 接口测试 | 支持 .proto 文件导入和测试 |

#### F7.4 Mock 服务详细需求（⏸️ 已搁置，存档保留）

**国内痛点**: 前后端分离、敏捷迭代，Mock 是"并行开发"的关键。免费版提供**本地 Mock 服务器**，无需云端依赖。

**功能概述**:
- 基于本地 HTTP 服务器的 Mock 服务（非云端）
- 从 Collection 自动生成 Mock 规则
- 支持动态响应模板、延迟模拟、状态码模拟

**Mock 规则配置**:

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| 匹配路径 | String | /api/example | 支持路径参数 `:id` |
| HTTP 方法 | Enum | GET | GET/POST/PUT/DELETE 等 |
| 响应状态码 | Number | 200 | 可模拟 400/500 错误场景 |
| 响应头 | Object | {} | Content-Type 等 |
| 响应体 | Text/JSON | {} | 支持模板变量 |
| 延迟 | Number | 0 | 模拟网络延迟 (ms) |

**模板变量支持**:

| 变量 | 示例 | 说明 |
|------|------|------|
| `{{$params.name}}` | `{{$params.id}}` | URL 路径参数 |
| `{{$query.name}}` | `{{$query.page}}` | Query 参数 |
| `{{$body.path}}` | `{{$body.user.name}}` | 请求体字段 |
| `{{$random.uuid}}` | `550e8400-e29b-41d4-a716-446655440000` | 随机 UUID |
| `{{$random.name}}` | `John Doe` | 随机姓名 |
| `{{$random.email}}` | `john@example.com` | 随机邮箱 |
| `{{$timestamp}}` | `1710825600` | 当前时间戳 |

**动态响应示例**:
```json
{
  "code": 200,
  "data": {
    "id": "{{$params.id}}",
    "name": "{{$random.name}}",
    "email": "{{$random.email}}",
    "createdAt": "{{$timestamp}}",
    "orders": [
      {"id": "{{$random.uuid}}", "amount": 99.99}
    ]
  }
}
```

**Mock 服务器管理**:
- 启动/停止按钮
- 端口配置（默认 3000）
- CORS 自动启用（支持前端跨域访问）
- 请求日志实时查看

**从集合生成 Mock**:
```
1. 选择 Collection → 右键 "生成 Mock 规则"
2. 为每个请求配置响应模板
3. 一键启动 Mock 服务器
4. 前端切换 baseURL 到 localhost:3000
```

#### F7.6 代码生成详细需求（⏸️ 已搁置，存档保留）

**国内痛点**: 减少重复编码、降低对接成本，新人快速上手。

**支持语言列表**:

| 语言/工具 | 状态 | 说明 |
|-----------|------|------|
| cURL | ✅ | 基础命令行 |
| JavaScript (fetch) | ⏳ | 原生 fetch API |
| JavaScript (axios) | ⏳ | 流行的 HTTP 库 |
| Python (requests) | ⏳ | Python 标准库 |
| Python (httpx) | ⏳ | 异步 HTTP 库 |
| Java (OkHttp) | ⏳ | Android/Java 常用 |
| Java (HttpClient) | ⏳ | Java 11+ 标准库 |
| Go | ⏳ | net/http 包 |
| PHP | ⏳ | cURL 扩展 |
| Ruby | ⏳ | net/http |
| C# (HttpClient) | ⏳ | .NET 标准库 |
| Swift | ⏳ | URLSession |
| Kotlin | ⏳ | OkHttp |
| Rust (reqwest) | ⏳ | 流行的 Rust HTTP 库 |

**代码模板引擎**:
- 使用 Mustache 模板引擎
- 支持自定义模板（高级功能）
- 自动处理：URL 编码、JSON 转义、特殊字符处理

**UI 设计**:
```
┌─────────────────────────────────────────┐
│  生成代码                                │
├─────────────────────────────────────────┤
│  语言: [Python ▼] [复制] [下载]          │
├─────────────────────────────────────────┤
│                                         │
│  ```python                              │
│  import requests                        │
│                                         │
│  url = "https://api.example.com/user"   │
│  headers = {"Authorization": "Bearer"}  │
│  response = requests.get(url, ...)      │
│  ```                                    │
│                                         │
└─────────────────────────────────────────┘
```

---

### 八、预请求链与变量转换 ✅ 已实现（核心楔子，v0.10.0）

> **国内痛点**: 测试某些系统需先登录拿 token；登录密码常需 sha1/aes 等加密后发送。Postman 靠 pre-request 脚本解决，门槛高。
>
> **Hopp 方案**: 用声明式积木替代脚本 —— 认证配置 + 预请求链 + 变量转换。
>
> **实现（2026-08-25）**: UI 原型 `docs/design/f8_prerequest_chain_preview.html`；模型 `AuthConfig`/`PreRequestStep`/`ExtractionRule`；发送链路挂载于 `request_response_provider.dart`；服务层 `auth_resolver.dart` / `variable_transforms.dart` / `pre_request/`。

#### F8.1 认证（Auth）配置

请求 Auth tab + 集合设置对话框配置，请求级优先、集合级沿 parentId 链继承（Inherit/No Auth 显式阻断）。

| 类型 | 说明 | 状态 |
|------|------|------|
| No Auth | 无认证（阻断继承） | ✅ |
| Inherit | 继承就近集合配置 | ✅ |
| Bearer Token | `Authorization: Bearer {{token}}` | ✅ |
| Basic Auth | `Authorization: Basic base64(user:pass)` | ✅ |
| API Key | Header / Query 中的自定义 key | ✅ |

#### F8.2 预请求链（登录 → token）

为某个请求（或集合）配置前置请求：

```text
1. 发送 login 请求（用户名 + 密码，密码经变量转换加密）
2. 从响应中提取 token：JSONPath 子集（如 $.data.token）/ 正则 / Header
3. 写入变量：{{token}}（本地作用域）
4. 目标请求的 Header 自动带上 Authorization: Bearer {{token}}
```

- 支持链式：login → 拿 token → 再调一个接口拿 refresh_token → 目标请求 ✅
- token 过期策略：手动重发 / 按响应码 401 自动重跑前置链（策略条开关）✅
- 变量作用域：前置链产出的变量写入「本地」（会话级 `localVariablesProvider`），不污染环境 ✅
- 试运行：就地执行链查看产出变量，不发目标请求 ✅
- 被引用请求自身的链不递归执行（深度 1，防循环）；其 Auth 配置正常生效
- 集合级默认链：集合设置 → Pre-request，请求级非空时覆盖

#### F8.3 变量转换（哈希 / 加密 / 签名）

在 URL/Header/Body 中引用变量时，支持声明式转换管道（替换 JS 脚本）：

```text
{{password | sha1}}                     # SHA-1，登录密码加密
{{password | md5}}                      # MD5
{{password | sha256}}                   # SHA-256
{{text | aes(cbc, key, iv, hex)}}       # AES 加密（cbc/ecb，默认 base64，可选 hex）
{{text | base64}}                       # Base64 编码
{{$timestampMs | md5}}                  # 动态签名
{{body | hmac(sha256, {{app_secret}})}} # HMAC 签名（参数支持变量引用）
```

内置动态变量：`{{$timestamp}}`、`{{$timestampMs}}`、`{{$isoTimestamp}}`、`{{$randomUUID}}`、`{{$randomInt}}`。

**设计原则**:
- 不引入 JS 沙箱；算法内置（crypto / encrypt 包，底层纯 Dart pointycastle）
- 转换是显式声明的：URL 栏与 KV 单元格分段着色（变量名 brand 色、管道函数 warning 色），fx 菜单可逐步预览解析结果
- 复杂签名若超出内置函数，再考虑 Tier 1 本地 AI 生成 + 轻量表达式
- AES key 须为 UTF-8 后 16/24/32 字节；JSONPath 为子集语法（点路径 + `[n]` 下标）

#### F8.4 验收标准

- [x] 配置 login 前置请求后，目标请求自动携带 token
- [x] 密码可经 sha1 / aes 加密后发送
- [x] 从 JSON / Header 响应中提取变量
- [x] 转换管道清晰可见、可编辑、可保存（分段着色 + fx 预览/插入，配置随请求/集合持久化）
- [x] 敏感变量（password/secret）加密存储（Hive 数据 box AES 加密，应用级 key）、界面脱敏显示

---

### 九、AI 助手（三层）📋 计划（核心楔子）

> 定位：本地 + 私有 AI。数据默认不出机器；AI 是可选、显式开启的能力。

| 层 | 模型 | 能力 | 隐私 |
|----|------|------|------|
| Tier 0 | 无模型 | OpenAPI/Swagger **文件或 URL** 导入生成请求/collection（F9.4 ✅）；cURL **导入**（F2.6 ✅）；cURL/代码**生成**见 F1.10/F7.6（未实现） | 零，纯确定性 |
| Tier 1 | 本地模型（Ollama / LM Studio，localhost OpenAI 兼容） | 解释响应 / 错误（M8.5 🔄）；生成断言（F4.2，M8.5 🔄）；自然语言建请求（M8.5 🔄）；**读取 API 文档网页生成请求**（挪后）；历史语义搜索（挪后） | 零，数据不出机器 |
| Tier 2 | BYOK 云端（OpenAI / Anthropic / DeepSeek 等） | 同上但更强，用户自填 key | 显式选择后才外发 |

> **API 文档地址 → 自动创建请求**（两种模式）：
> - 机器可读地址（`openapi.json` / `swagger.yaml`）→ Tier 0 确定性解析，无需模型、零隐私成本
> - 人类可读网页（Swagger UI / Redoc / 文档站 / Markdown）→ Tier 1/2 模型抓取并提取接口；私有文档 + Tier 2 时内容会外发，需隐私告知门

#### F9.1 设计原则

- **默认本地，永不自动外发**：无账号、无遥测、无云端；Tier 2 必须用户显式配置 key 并开启
- **首次外发隐私门**：Tier 2 第一次实际调用前弹一次隐私说明，确认后才外发
- **优雅降级，永不阻断核心流程**：AI 调用失败 / 超时 / 未配置时自动回退，「发请求」核心功能不受影响
- **可保存、可复跑**：AI 产出落到 collection / 环境 / 断言，不是一次性聊天
- **可解释**：AI 生成的请求/断言展示来源与可编辑的中间产物

#### F9.2 优先级

1. Tier 0：OpenAPI 导入生成请求（无需模型，最强差异化，最先做）
2. Tier 1：解释响应 / 生成断言 / 自然语言建请求
3. Tier 2：可选增强

#### F9.3 实现要点

- **单一 OpenAI 兼容客户端**：`baseURL + model + key` 可配，Tier 1 指向 `http://localhost:11434/v1`（Ollama），Tier 2 指向云端；一套代码覆盖两层
- **密钥走 OS 安全存储**：macOS Keychain / Windows Credential Manager / Linux libsecret，不落 Hive/UserDefaults 明文
- **元数据-only 日志**：只记端点/模型/耗时/字数，不落请求体、key、响应文本本体
- **防脑补硬约束**：生成请求/断言时，字段、参数、取值只允许来自 spec 或用户输入，缺失即缺失，禁止脑补

#### F9.4 Tier 0：OpenAPI/Swagger 导入（M8.3 / v0.11.0，2026-08-28 澄清确认）

**范围**

| 项 | 决策 |
|----|------|
| 规格版本 | OpenAPI 3.0.x / 3.1 + Swagger 2.0（解析层内部统一转 3.0 模型，映射只写一套） |
| 格式 | JSON + YAML（`yaml` 包 + 自写轻量 3.0 子集模型，不引重型解析框架） |
| 来源 | 本地文件（对话框选择，`.json/.yaml/.yml`；拖放为既有残桩，见 BACKLOG 已知问题）+ URL 拉取（可配一组自定义请求头，覆盖私有 spec 常见的 token/basic；不做重定向链/Cookie） |
| 不在本期 | cURL 生成（F1.10）拆独立任务；spec 变更同步（重导入 = 新建或走冲突策略，不保持联动） |

**映射规则**（防脑补：所有取值必须来自 spec，无来源即留空）

| spec 元素 | Hopp 生成物 |
|-----------|-------------|
| `info.title` | Collection 名 |
| `tags` | 子集合（扁平化 parentId）；无 tag 的接口平铺根集合 |
| 请求名 | `summary` → `operationId` → `METHOD /path` |
| `servers[0].url` | upsert 全局变量 `{{baseUrl}}`（尚无集合变量层，作用域 local>环境>全局；重复导入更新同名变量），请求 URL 写 `{{baseUrl}}/path` |
| path 参数 `{id}` | `{{id}}`，并在集合变量留空占位 |
| query/header 参数取值 | `example` → `default` → `enum[0]` → 留空 |
| requestBody | 优先 `example`/`examples`；否则按 schema 类型生成骨架，导入报告标注「类型占位」 |
| `securitySchemes` | bearer / basic / apiKey → 集合级 Auth（F8.1），secret 留空由用户填；OAuth2 不自动配置，导入报告提示 |

**交互流程**

1. 导入入口：现有 Import 对话框扩展格式页签（Postman / cURL / OpenAPI；侧栏菜单单入口「Import…」）
2. 解析后预览：按 tag 分组的接口清单，支持全选 / 按 tag 勾选 / 搜索过滤，确认后落库
3. 冲突处理：复用 Postman 导入四策略（overwrite / rename / merge / skip）
4. 导入报告：成功数、类型占位标注、OAuth2 等未自动配置项提示

**验收标准**

- [x] OpenAPI 3.0/3.1（JSON+YAML）与 Swagger 2.0 均可导入生成 collection
- [x] 文件与 URL 两种来源可用，URL 支持自定义请求头
- [x] servers / tags / 参数 / body / Auth 按映射表生成，无 spec 来源的值留空不脑补
- [x] 预览页可勾选与过滤，冲突四策略生效
- [x] 导入报告列出类型占位与未自动配置项
- [x] Petstore 等真实 spec fixture 单元测试 + test-mode 导入指令可自动化验证（`import_openapi`）

#### F9.5 Tier 1：本地模型（M8.5，2026-08-31 澄清确认）

**范围**

| 项 | 决策 |
|----|------|
| 本期做 | 解释响应/错误；AI 生成断言（F4.2）；自然语言建请求；OpenAI 兼容客户端 + 连接配置 |
| 本期不做 | 读取 API 文档网页生成请求、历史语义搜索（挪 M8.6/BACKLOG）；Tier 2 BYOK（M8.6）；通用 AI 聊天面板；流式输出（BACKLOG）；`/v1/models` 模型列表拉取（模型名手填） |

**底座**（F9.3 本期落地）

- 单一 OpenAI 兼容客户端：Dio 手写 chat completions，`baseURL + model + key` 可配；预设 Ollama `http://localhost:11434/v1`、LM Studio `http://localhost:1234/v1`
- 配置存 `AppSettings` 新字段（settings box 不加密；baseURL/model 非敏感，API key 输入框为 Tier 2 铺路，keychain 级存储随 M8.6）
- 非流式（v1）；连接超时 5s / 生成超时 60s；温度 0；日志只记端点/模型/耗时/token 数，不落请求体/响应文本/key

**交互**

| 能力 | 入口 | 形态 |
|------|------|------|
| 解释响应 | Response info bar ✨ 按钮 | 对话框展示；上下文 = 状态码 + body（截断 ≤8KB） |
| AI 生成断言 | Assertions 页首「AI 生成」按钮 | 生成规则列表可勾选/编辑 → 确认 append；无响应样本时禁用并提示先发送 |
| 自然语言建请求 | URL 栏 ✨ 按钮 | 描述 → 草稿填回当前 tab；当前 tab 有实质内容时先确认覆盖 |

**硬约束**

- 防脑补：AI 产出一律过客户端 schema 校验（枚举合法性、类型匹配、缺失即缺失不补全），非法项丢弃并提示，可重试
- 优雅降级：未检测到服务时提示「未检测到 Ollama（localhost:11434）」；任何失败 toast 提示，不影响发请求主流程
- 可保存可复跑：断言规则落请求模型；生成的请求草稿可编辑、不保存即丢弃

**验收标准**

- [x] Ollama / LM Studio 预设可配置，连接与调用链路经 mock 验证（真模型冒烟已补：2026-08-31 Ollama 0.33 + qwen2.5:3b，端点级 + UI 试用通过）
- [x] 三个能力在无模型环境下经 test-mode 指令（mock 响应）自动化验证
- [x] schema 校验单测覆盖防脑补用例（非法枚举 / 类型不匹配 / 缺失字段）
- [x] 连接失败 / 超时 / 服务未启动均有友好提示，发请求主流程不受影响（单测覆盖错误分层）
- [x] UI 过设计守卫（token + 通用组件），亮/暗双主题正常（token 自适应，无分支代码）

---

## 非功能需求

| 类别 | 需求 | 说明 |
|------|------|------|
| 性能 | 启动时间 | 应用启动 < 2s |
| 性能 | 响应时间 | 请求发送到响应展示 < 100ms（本地） |
| 性能 | 内存占用 | 正常使用 < 200MB |
| 兼容 | 跨平台 | 支持 macOS 10.15+ / Windows 10+ / Linux |
| 安全 | 数据存储 | 敏感信息（Token）加密存储 |
| 可维护 | 代码规范 | 遵循 Flutter + Dart 最佳实践 |

---

## 技术栈

| 层级 | 技术 | 用途 |
|------|------|------|
| 跨平台框架 | Flutter 3.27.x | UI 开发和跨平台支持 |
| 编程语言 | Dart 3.6+ | 业务逻辑实现 |
| UI 设计 | Material Design 3 | 设计系统和组件 |
| 状态管理 | Riverpod 2.x | 全局状态管理 |
| HTTP 客户端 | Dio 5.x | HTTP 请求处理 |
| 数据存储 | Hive + SharedPreferences | 本地数据持久化 |
| 代码生成 | Freezed + json_serializable | 模型类生成 |

---

## 术语表

| 术语 | 说明 |
|------|------|
| Collection | 请求集合，用于组织 API 请求 |
| Environment | 环境配置，包含一组变量 |
| Variable | 变量，使用 `{{name}}` 语法引用 |
| 预请求链 | 发送目标请求前，先执行一个或多个前置请求（如 login）并传递变量 |
| 变量转换 | 对变量值做声明式哈希/加密/签名（如 sha1/aes） |
| Tier 0/1/2 | AI 三层：无模型 / 本地模型 / BYOK 云端 |
| Tab | 标签页，可同时打开多个请求 |
| Workspace | 工作区（Future：团队协作时使用） |
