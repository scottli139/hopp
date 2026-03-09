# 代码规范与风格指南

> 本规范确保所有代码风格一致、质量统一，所有提交必须通过自动化检查。

---

## 🎯 核心原则

1. **可读性优先** - 代码是写给人看的，机器只是顺便执行
2. **显式优于隐式** - 避免魔法值、隐式转换
3. **DRY (Don't Repeat Yourself)** - 提取重复逻辑
4. **单一职责** - 函数/组件只做一件事
5. **类型安全** - 充分利用 TypeScript 和 Rust 的类型系统

---

## 📁 前端规范 (TypeScript/React)

### 目录与文件命名

```
✅ 正确                    ❌ 错误
─────────────────────────────────────────
src/components/           src/Components/
my-component/             MyComponent/
use-api.ts                useApi.ts
api-service.ts            apiService.ts
types/                    type/
```

| 类型 | 命名规范 | 示例 |
|------|----------|------|
| 组件目录 | kebab-case | `request-editor/` |
| 组件文件 | PascalCase | `RequestEditor.tsx` |
| 工具函数 | camelCase | `formatDate.ts` |
| 自定义 Hook | camelCase (use 前缀) | `useRequest.ts` |
| 类型定义 | PascalCase | `Request.types.ts` |
| 常量 | UPPER_SNAKE_CASE | `API_CONSTANTS.ts` |
| 样式文件 | 同名 + `.css` | `RequestEditor.css` |

### 组件规范

```typescript
// ✅ 正确示例
import { FC, useCallback, useState } from 'react';
import { cn } from '@/utils/cn';

// Props 接口必须显式命名
interface RequestEditorProps {
  /** 请求ID */
  requestId: string;
  /** 是否只读 */
  readOnly?: boolean;
  /** 保存回调 */
  onSave?: (data: RequestData) => void;
}

/**
 * 请求编辑器组件
 * 用于编辑 HTTP 请求的各项参数
 */
export const RequestEditor: FC<RequestEditorProps> = ({
  requestId,
  readOnly = false,
  onSave,
}) => {
  const [isLoading, setIsLoading] = useState(false);

  const handleSave = useCallback(() => {
    if (readOnly) return;
    // 保存逻辑
  }, [readOnly]);

  return (
    <div className="flex flex-col gap-4">
      {/* JSX */}
    </div>
  );
};

// ❌ 错误示例
// 不要使用默认导出
export default function requestEditor(props: any) {
  const [loading, setLoading] = useState(false); // 状态命名不清晰
  // ...
}
```

#### 组件规则

1. **必须显式声明返回类型** - `FC<Props>` 或 `: ReactElement`
2. **Props 接口必须带 JSDoc 注释**
3. **默认使用命名导出** - 禁用 `export default`
4. **hooks 必须放在组件顶部**
5. **事件处理函数使用 useCallback**
6. **复杂逻辑提取到自定义 Hook**

### TypeScript 规范

```typescript
// ✅ 正确使用类型

// 1. 优先使用 interface 定义对象类型
interface User {
  id: string;
  name: string;
  email: string;
}

// 2. 使用 type 定义联合类型、元组
type Status = 'idle' | 'loading' | 'success' | 'error';
type Point = [number, number];

// 3. 泛型命名要有意义
interface ApiResponse<TData> {
  data: TData;
  status: number;
  message: string;
}

// 4. 使用 satisfies 进行类型检查
const config = {
  timeout: 5000,
  retries: 3,
} satisfies RequestConfig;

// 5. 避免使用 any，使用 unknown
function parseData(input: unknown): Data {
  if (typeof input === 'string') {
    return JSON.parse(input);
  }
  throw new Error('Invalid input');
}

// ❌ 错误示例
let data: any; // 禁止使用 any
function process(input: any): any { // 参数和返回值都要明确类型
  // ...
}
```

#### TS 规则

1. **严格模式开启** - `strict: true`
2. **禁止 any** - 特殊情况需注释说明
3. **显式返回类型** - 公共函数必须声明
4. **使用可选链** - `obj?.prop` 替代 `obj && obj.prop`
5. **使用空值合并** - `value ?? default` 替代 `||`

### 状态管理规范 (Zustand)

```typescript
// ✅ 正确的 Store 结构
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { devtools } from 'zustand/middleware';

// 1. 定义状态接口
interface RequestState {
  // State
  requests: Request[];
  activeRequestId: string | null;
  isLoading: boolean;
  
  // Computed (使用 selector)
  getActiveRequest: () => Request | null;
  
  // Actions
  addRequest: (request: Request) => void;
  setActiveRequest: (id: string) => void;
  updateRequest: (id: string, updates: Partial<Request>) => void;
}

// 2. 使用 immer 和 devtools
export const useRequestStore = create<RequestState>()(
  devtools(
    immer((set, get) => ({
      // Initial state
      requests: [],
      activeRequestId: null,
      isLoading: false,
      
      // Computed
      getActiveRequest: () => {
        const { requests, activeRequestId } = get();
        return requests.find(r => r.id === activeRequestId) ?? null;
      },
      
      // Actions
      addRequest: (request) => set((state) => {
        state.requests.push(request);
      }),
      
      setActiveRequest: (id) => set((state) => {
        state.activeRequestId = id;
      }),
      
      updateRequest: (id, updates) => set((state) => {
        const request = state.requests.find(r => r.id === id);
        if (request) {
          Object.assign(request, updates);
        }
      }),
    })),
    { name: 'RequestStore' }
  )
);

// 3. 使用 Selector 优化重渲染
// ✅ 正确
const activeRequest = useRequestStore(state => state.getActiveRequest());

// ❌ 错误 - 会导致不必要的重渲染
const { requests, activeRequestId } = useRequestStore();
```

### 样式规范 (Tailwind CSS)

```tsx
// ✅ 正确使用 Tailwind
import { cn } from '@/utils/cn';

export const Button: FC<ButtonProps> = ({ 
  variant = 'primary', 
  size = 'md',
  className,
  children 
}) => {
  return (
    <button
      className={cn(
        // 基础样式
        'inline-flex items-center justify-center rounded-md font-medium',
        'transition-colors focus-visible:outline-none focus-visible:ring-2',
        'disabled:pointer-events-none disabled:opacity-50',
        
        // 变体样式
        variant === 'primary' && 'bg-blue-600 text-white hover:bg-blue-700',
        variant === 'secondary' && 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        variant === 'danger' && 'bg-red-600 text-white hover:bg-red-700',
        
        // 尺寸样式
        size === 'sm' && 'h-8 px-3 text-sm',
        size === 'md' && 'h-10 px-4 text-sm',
        size === 'lg' && 'h-12 px-6 text-base',
        
        // 外部传入的 className
        className
      )}
    >
      {children}
    </button>
  );
};
```

#### Tailwind 规则

1. **使用 cn() 工具函数** - 合并 className，处理条件
2. **按逻辑分组** - 布局/颜色/交互/尺寸
3. **提取重复模式** - 使用 `@apply` 或组件封装
4. **避免任意值** - 尽量使用预设值
5. **响应式前缀有序** - `sm: md: lg: xl:`

---

## ⚙️ 后端规范 (Rust)

### 目录与文件命名

```
✅ 正确                    ❌ 错误
─────────────────────────────────────────
src/commands/             src/Commands/
http_client.rs            HttpClient.rs
models/                   Models/
```

| 类型 | 命名规范 | 示例 |
|------|----------|------|
| 模块文件 | snake_case | `http_client.rs` |
| 结构体/枚举 | PascalCase | `HttpRequest` |
| trait | PascalCase | `RequestHandler` |
| 函数/变量 | snake_case | `send_request` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 类型别名 | PascalCase | `RequestId` |

### 代码组织

```rust
// ✅ 正确的模块结构
// src/services/http_client.rs

use std::time::Duration;
use reqwest::{Client, Method};
use serde::{Deserialize, Serialize};
use thiserror::Error;

// 1. 错误定义在前
#[derive(Debug, Error)]
pub enum HttpError {
    #[error("Request failed: {0}")]
    RequestFailed(String),
    #[error("Timeout after {0:?}")]
    Timeout(Duration),
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
}

// 2. 类型定义
pub type Result<T> = std::result::Result<T, HttpError>;

// 3. 数据结构
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HttpRequest {
    pub method: Method,
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub body: Option<String>,
    pub timeout: Duration,
}

// 4. 实现块
pub struct HttpClient {
    client: Client,
    default_timeout: Duration,
}

impl HttpClient {
    /// 创建新的 HTTP 客户端
    pub fn new() -> Self {
        Self {
            client: Client::new(),
            default_timeout: Duration::from_secs(30),
        }
    }
    
    /// 发送 HTTP 请求
    ///
    /// # Arguments
    /// * `request` - HTTP 请求配置
    ///
    /// # Returns
    /// 成功返回 HttpResponse，失败返回 HttpError
    pub async fn send(&self, request: HttpRequest) -> Result<HttpResponse> {
        // 实现...
        todo!()
    }
}

// 5. 单元测试在最后
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_send_request() {
        // 测试代码
    }
}
```

### 错误处理

```rust
// ✅ 使用 thiserror 定义错误
#[derive(Debug, Error)]
pub enum AppError {
    #[error("HTTP error: {0}")]
    Http(#[from] reqwest::Error),
    
    #[error("Database error: {0}")]
    Database(#[from] rusqlite::Error),
    
    #[error("Not found: {entity} with id {id}")]
    NotFound { entity: String, id: String },
    
    #[error("Validation error: {0}")]
    Validation(String),
}

// ✅ 函数返回 Result
pub async fn fetch_user(id: &str) -> Result<User, AppError> {
    let user = db::find_user(id)
        .await?
        .ok_or_else(|| AppError::NotFound {
            entity: "User".to_string(),
            id: id.to_string(),
        })?;
    
    Ok(user)
}

// ✅ 转换错误类型
let result = operation.map_err(|e| AppError::Validation(e.to_string()))?;
```

### 异步编程

```rust
// ✅ 正确使用 async/await

// 1. async fn 返回 impl Future
pub async fn process_request(req: Request) -> Result<Response> {
    let client = HttpClient::new();
    let response = client.send(req).await?;
    Ok(response)
}

// 2. 使用 tokio::spawn 并发
let handles: Vec<_> = requests
    .into_iter()
    .map(|req| tokio::spawn(process_request(req)))
    .collect();

let results = futures::future::join_all(handles).await;

// 3. 使用 tokio::select! 处理超时
tokio::select! {
    result = send_request(req) => {
        result?
    }
    _ = tokio::time::sleep(Duration::from_secs(30)) => {
        return Err(HttpError::Timeout(Duration::from_secs(30)));
    }
}
```

### 文档注释

```rust
/// HTTP 客户端封装
///
/// 提供便捷的 HTTP 请求发送功能，支持超时、重试等特性。
///
/// # 示例
/// ```
/// use hopp::services::HttpClient;
///
/// let client = HttpClient::new();
/// let response = client.get("https://api.example.com").await?;
/// ```
pub struct HttpClient {
    // ...
}

impl HttpClient {
    /// 发送 GET 请求
    ///
    /// # 参数
    /// - `url`: 请求 URL
    ///
    /// # 返回
    /// 成功返回 `HttpResponse`，失败返回 `HttpError`
    ///
    /// # 错误
    /// - `HttpError::InvalidUrl`: URL 格式不正确
    /// - `HttpError::Timeout`: 请求超时
    pub async fn get(&self, url: &str) -> Result<HttpResponse> {
        // ...
    }
}
```

---

## 🔒 安全规范

### 敏感数据处理

```typescript
// ✅ 前端 - 不存储敏感信息明文
// 使用 Tauri 的 secure storage API
import { secureStore } from '@tauri-apps/plugin-store';

await secureStore.set('apiKey', encryptedValue);
```

```rust
// ✅ 后端 - 使用 keyring 存储
use keyring::Entry;

let entry = Entry::new("hopp", "api_key")?;
entry.set_password(&api_key)?;
```

### 输入验证

```rust
// ✅ 后端验证所有输入
#[derive(Debug, Validate, Deserialize)]
pub struct CreateRequest {
    #[validate(length(min = 1, max = 100))]
    pub name: String,
    #[validate(url)]
    pub url: String,
}

pub fn create_request(data: CreateRequest) -> Result<()> {
    data.validate()?;
    // ...
}
```

---

## 📝 提交规范

### 提交信息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复 Bug |
| `docs` | 文档更新 |
| `style` | 代码格式调整（不影响功能） |
| `refactor` | 重构（非 feat/fix） |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具链/依赖更新 |
| `ci` | CI/CD 配置 |

#### 示例

```
feat(request): add support for multipart form data

- Add FileUpload component
- Update HTTP client to handle multipart
- Add progress tracking for uploads

Closes #123
```

```
fix(http-client): resolve timeout not working for large files

The timeout was not being applied to the entire request duration,
only to the initial connection. Fixed by wrapping the entire
request future with tokio::time::timeout.

Fixes #456
```

### 分支策略

```
main ............ 生产分支，只接受合并
  ↑
release/v0.1.0 .. 发布分支
  ↑
develop ......... 开发分支，功能合并至此
  ↑
feature/M1-1 .... 功能分支
```

| 分支类型 | 命名规范 | 来源 | 合并目标 |
|----------|----------|------|----------|
| 功能分支 | `feature/M1-x-<desc>` | develop | develop |
| 修复分支 | `fix/issue-<number>` | main | main + develop |
| 发布分支 | `release/vx.x.x` | develop | main |

---

## ✅ 检查清单

### 提交前检查

- [ ] 代码通过 ESLint/Prettier 检查
- [ ] 代码通过 rustfmt/clippy 检查
- [ ] TypeScript 类型检查通过
- [ ] 单元测试通过
- [ ] 提交信息符合规范
- [ ] 没有 console.log/debug 残留
- [ ] 敏感信息未提交

### PR 检查

- [ ] 关联 Issue
- [ ] 代码审查通过
- [ ] CI 检查通过
- [ ] 功能测试通过
- [ ] 文档已更新
- [ ] 必要的日志已添加

---

## 📝 日志规范

### 基本原则

**每个新功能必须添加适当的日志**，以便：
- 排查用户问题
- 自动化测试验证
- 运行时行为追踪

### 前端日志规范

```typescript
// ✅ 正确的日志使用
import logger from '@/utils/logger';

// 1. 用户操作 - 使用 info
const handleSendRequest = async () => {
  logger.info('Sending HTTP request', { 
    method: request.method, 
    url: request.url 
  });
  
  try {
    const response = await sendRequest(request);
    logger.info('Request succeeded', { 
      status: response.status,
      duration: response.duration 
    });
  } catch (error) {
    logger.error('Request failed', error as Error, {
      method: request.method,
      url: request.url
    });
  }
};

// 2. 状态变化 - 使用 debug
useEffect(() => {
  logger.debug('Active request changed', { requestId: activeRequestId });
}, [activeRequestId]);

// 3. 关键配置变更 - 使用 info
const updateSettings = (settings: Settings) => {
  logger.info('Settings updated', { 
    theme: settings.theme,
    language: settings.language 
  });
  saveSettings(settings);
};
```

#### 日志级别使用指南

| 级别 | 使用场景 | 示例 |
|------|----------|------|
| `trace` | 详细执行流程 | 函数进入/退出、循环迭代 |
| `debug` | 开发调试信息 | 状态变化、配置值 |
| `info` | 关键业务事件 | 用户操作、请求发送/完成 |
| `warn` | 警告/预期外情况 | 降级处理、重试 |
| `error` | 错误/异常 | 请求失败、操作失败 |

#### 日志内容规范

```typescript
// ✅ 好 - 包含上下文
logger.info('Collection imported', { 
  name: collection.name,
  requestCount: collection.requests.length,
  source: 'postman'
});

// ❌ 差 - 信息不足
logger.info('Import done');
```

### 后端日志规范

```rust
// ✅ 正确的日志使用
use tracing::{info, debug, error, warn};

// 1. 命令/请求处理 - 使用 info
#[tauri::command]
pub async fn send_http_request(request: HttpRequest) -> Result<HttpResponse, String> {
    info!(method = %request.method, url = %request.url, "Sending HTTP request");
    
    let client = HttpClient::new();
    match client.send(request).await {
        Ok(response) => {
            info!(status = response.status, "Request completed");
            Ok(response)
        }
        Err(e) => {
            error!(error = %e, "Request failed");
            Err(e.to_string())
        }
    }
}

// 2. 内部处理 - 使用 debug
debug!(request_id = %id, "Processing request");

// 3. 警告情况 - 使用 warn
warn!(retry_count = retry, "Request timeout, retrying...");
```

#### Rust 日志属性规范

```rust
// ✅ 使用结构化字段
info!(
    user_id = %user.id,
    action = "create_collection",
    collection_name = %name,
    "User created collection"
);

// ❌ 避免字符串拼接
info!("User {} created collection {}", user.id, name);
```

### 日志检查清单

新增功能时，确保：

- [ ] **关键操作**有 `info` 级别日志（创建、更新、删除、发送）
- [ ] **错误处理**有 `error` 级别日志，包含错误对象和上下文
- [ ] **状态变化**有 `debug` 级别日志
- [ ] **用户交互**有日志记录（按钮点击、表单提交）
- [ ] **外部调用**有开始和结束的日志对（请求/响应）
- [ ] **敏感信息**已脱敏（密码、Token 等不记录）

### 敏感信息处理

```typescript
// ✅ 脱敏处理
logger.info('API key configured', { 
  keyId: apiKey.id,
  // ❌ 不要记录: key: apiKey.value
  maskedValue: maskString(apiKey.value, 4) // 只显示后4位
});
```

```rust
// ✅ 脱敏处理
info!(
    api_key_id = %key_id,
    "API key configured"
    // ❌ 不要记录实际 key 值
);
```
