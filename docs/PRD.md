# 需求规格说明书 (PRD)

## 产品概述

**Hopp** 是一款轻量级、跨平台的 API 请求测试工具，类似 Postman，基于 Flutter 构建，注重性能和用户体验。

**口号**: *Hop to your APIs*（跃向你的 API）

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
| F1.10 | cURL 生成 | ⏳ | cURL 命令生成与复制 | 一键复制生成的 cURL 命令 (v0.6.0) |
| F1.11 | HTTPS 证书查看 | ✅ | 查看 SSL/TLS 证书详细信息 | 证书颁发者、有效期、域名、指纹等 |
| F1.12 | 请求时间分析 | ✅ | 展示请求各环节耗时 | DNS、TCP、SSL、TTFB、下载时间分段展示 |
| F1.13 | 请求详情展示 | ✅ | 显示实际发送的请求信息 | 展示变量替换后的最终 URL、Headers、Body |
| F1.14 | 请求设置 | ⏳ | 请求级别的配置选项 | SSL验证、Follow Redirects、Max Redirects 已实现，其他配置项待完成 |

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
| `--max-redirs` | 最大重定向次数 | maxRedirects |
| `-b, --cookie` | Cookie 数据 | Cookie header |
| `-A, --user-agent` | User-Agent | User-Agent header |
| `-e, --referer` | Referer | Referer header |
| `--compressed` | 接受压缩响应 | Accept-Encoding header |

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
| 剪贴板粘贴 | `Cmd+Shift+V` 或右键菜单 | 从文档/聊天复制后快速导入 |
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
- `Cmd+Shift+V` - 从剪贴板导入 cURL
- `Cmd+Shift+I` - 打开导入对话框（含 Postman/cURL 选项）

**错误处理**:

| 错误类型 | 提示 |
|----------|------|
| 空输入 | "请输入 cURL 命令" |
| 格式无效 | "无法解析 cURL 命令，请检查格式" |
| 不支持的选项 | "警告: 忽略不支持的选项 --xxx" |
| URL 缺失 | "cURL 命令缺少 URL" |

---

### 三、环境变量功能 ⏳

> **状态说明**: 目前仅实现了 Postman Environment 格式的导入导出支持，核心功能（环境管理、变量替换）待实现。

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F3.1 | 环境变量 | ⏳ | 不同环境（开发/测试/生产） | 可创建多个环境配置 |
| F3.2 | 全局变量 | ⏳ | 跨环境共享变量 | 独立于环境的全局变量 |
| F3.3 | 变量替换 | ⏳ | URL/Headers/Body 中使用 `{{var}}` | 发送前自动替换变量 |

### 四、测试与脚本功能 ✅ (v0.7.0 规划)

> 国内接口签名逻辑复杂，脚本灵活度是刚需。将测试功能从 Backlog 提升为核心功能。

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F4.1 | 响应断言 | ⏳ | 可视化断言编辑器，支持状态码、响应字段、响应时间校验 | 无需编写代码，通过 UI 配置断言规则 |
| F4.2 | Pre-request Script | ⏳ | 请求前执行 JS 脚本，动态生成签名、token、时间戳 | 支持 `pm` 对象，可访问环境变量、生成动态值 |
| F4.3 | Test Script | ⏳ | 请求后执行 JS 脚本，校验响应数据 | 支持 `pm.test()`、`pm.expect()` 等断言 API |
| F4.4 | 批量运行 | ⏳ | 集合级别的批量请求执行，生成测试报告 | 支持顺序/并行执行，导出 CSV/HTML 报告 |

#### F4.2 Pre-request Script 详细需求

**国内痛点**: 国内 API 普遍需要动态签名（如阿里系、腾讯系、自研网关），需在请求前计算 sign、timestamp。

**核心 API 设计**:
```javascript
// 访问环境变量
const appKey = pm.environment.get("appKey");
const appSecret = pm.environment.get("appSecret");

// 生成时间戳
const timestamp = new Date().getTime();
pm.environment.set("timestamp", timestamp);

// 计算签名（支持 CryptoJS）
const sign = CryptoJS.MD5(appKey + timestamp + appSecret).toString();
pm.environment.set("sign", sign);

// 动态设置请求头
pm.request.headers.add({key: "X-Sign", value: sign});
```

**内置库支持**:
| 库名 | 版本 | 用途 |
|------|------|------|
| CryptoJS | 4.2.0 | MD5/SHA1/SHA256/HMAC 等签名算法 |
| lodash | 4.17.21 | 数据处理、对象操作 |
| moment | 2.29.4 | 日期时间格式化 |
| uuid | 9.0.0 | UUID 生成 |

**脚本执行环境**:
- 沙箱隔离，限制访问 DOM/文件系统
- 超时限制：5 秒
- 内存限制：128MB

---

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

**Backlog（未来规划）：**

| ID | 功能 | 状态 | 说明 |
|----|------|------|------|
| F6.2 | 云端同步 | Backlog | 用户数据云存储，跨设备同步 |
| F6.3 | 团队协作 | Backlog | 多人实时协作编辑 |

### 七、高级功能

| ID | 功能 | 状态 | 需求描述 | 验收标准 |
|----|------|------|----------|----------|
| F7.1 | WebSocket 测试 | ⏳ | WebSocket 连接测试 | 支持 ws/wss，消息收发 |

#### F7.4 Mock 服务详细需求 (v0.8.0)

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

---
| F7.3 | API 文档生成 | ⏸️ | 从集合生成文档 | 导出 Markdown/HTML |
| F7.5 | 代理设置 | ⏸️ | HTTP/HTTPS 代理 | 支持系统代理和自定义代理 |
| F7.7 | gRPC 测试 | Backlog | Protocol Buffers 接口测试 | 支持 .proto 文件导入和测试 |
| F7.6 | 代码生成 | ⏳ | 生成 Python/JS/cURL 等代码 | 支持 20+ 语言，一键复制 |

#### F7.6 代码生成详细需求

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
| 包含环境变量 | 否 | 是否同时导出关联的环境 |
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
- [x] 导出环境变量（可选）
- [x] 导出成功后显示文件保存路径

**Backlog（未来规划）：**

| ID | 功能 | 状态 | 说明 |
|----|------|------|------|
| F7.2 | gRPC 测试 | Backlog | Protocol Buffers 接口测试 |
| F7.4 | Mock 云端服务 | Backlog | 云端 Mock 服务器（付费功能）|

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
| Tab | 标签页，可同时打开多个请求 |
| Workspace | 工作区（Future：团队协作时使用） |
