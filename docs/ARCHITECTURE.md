# 架构说明文档

## 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   React UI  │ │  Zustand    │ │  Monaco     │           │
│  │  Components │ │    Store    │ │   Editor    │           │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘           │
└─────────┼───────────────┼───────────────┼───────────────────┘
          │               │               │
          │         ┌─────┴─────┐         │
          │         │   Tauri   │         │
          │         │   Bridge  │         │
          │         │ (IPC/API) │         │
          │         └─────┬─────┘         │
          │               │               │
┌─────────┼───────────────┼───────────────┼───────────────────┐
│         │    Core Service Layer (Rust)  │                   │
│  ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐          │
│  │ HTTP Client │ │   Storage   │ │  WebSocket  │          │
│  │  (reqwest)  │ │  (SQLite)   │ │   Manager   │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
│                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ Environment │ │   Import/   │ │   Code      │           │
│  │   Manager   │ │   Export    │ │  Generator  │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

---

## 技术栈选型

### 前端 (Frontend)

| 技术 | 版本 | 用途 |
|------|------|------|
| React | 18.x | UI 框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 5.x | 构建工具 |
| Tailwind CSS | 3.x | 原子化 CSS |
| Radix UI | 1.x | 无样式 UI 组件库 |
| Zustand | 4.x | 状态管理 |
| React Query | 5.x | 服务端状态管理 |
| Monaco Editor | latest | 代码编辑器 |

### 后端 (Backend - Tauri)

| 技术 | 版本 | 用途 |
|------|------|------|
| Tauri | 2.x | 桌面应用框架 |
| Rust | 1.75+ | 系统编程语言 |
| reqwest | 0.11+ | HTTP 客户端 |
| tokio | 1.x | 异步运行时 |
| rusqlite | 0.30+ | SQLite 数据库 |
| serde | 1.x | 序列化/反序列化 |
| tauri-plugin-store | latest | 本地存储插件 |

---

## 模块划分

### 1. 前端模块 (src/)

```
src/
├── components/           # UI 组件
│   ├── common/          # 通用组件
│   ├── request/         # 请求相关组件
│   ├── response/        # 响应相关组件
│   ├── sidebar/         # 侧边栏组件
│   └── layout/          # 布局组件
├── pages/               # 页面
├── stores/              # Zustand 状态管理
│   ├── requestStore.ts
│   ├── collectionStore.ts
│   ├── environmentStore.ts
│   └── uiStore.ts
├── hooks/               # 自定义 Hooks
├── services/            # Tauri API 调用封装
├── types/               # TypeScript 类型定义
├── utils/               # 工具函数
└── styles/              # 全局样式
```

### 2. 后端模块 (src-tauri/src/)

```
src-tauri/src/
├── main.rs              # 应用入口
├── lib.rs               # 库入口
├── commands/            # Tauri 命令
│   ├── http.rs          # HTTP 请求命令
│   ├── storage.rs       # 数据存储命令
│   ├── environment.rs   # 环境管理命令
│   └── websocket.rs     # WebSocket 命令
├── services/            # 业务服务
│   ├── http_client.rs   # HTTP 客户端封装
│   ├── storage/         # 存储服务
│   │   ├── mod.rs
│   │   ├── sqlite.rs
│   │   └── models.rs
│   ├── environment.rs   # 环境变量服务
│   ├── websocket.rs     # WebSocket 服务
│   └── import_export.rs # 导入导出服务
├── models/              # 数据模型
│   ├── request.rs
│   ├── response.rs
│   ├── collection.rs
│   └── environment.rs
└── utils/               # 工具函数
    ├── curl_parser.rs   # cURL 解析
    └── code_gen.rs      # 代码生成
```

---

## 数据流

### HTTP 请求流程

```
┌─────────┐    ┌─────────────┐    ┌─────────────┐    ┌───────────┐
│  User   │───▶│  React UI   │───▶│ Tauri Invoke│───▶│  Rust     │
│ Action  │    │   (State)   │    │   (IPC)     │    │  Command  │
└─────────┘    └─────────────┘    └─────────────┘    └─────┬─────┘
                                                            │
                              ┌──────────────────────────────┘
                              ▼
┌─────────┐    ┌─────────────┐    ┌─────────────┐    ┌───────────┐
│ Display │◀───│ Update Store│◀───│ Tauri Event │◀───│  reqwest  │
│ Response│    │             │    │   (IPC)     │    │  Request  │
└─────────┘    └─────────────┘    └─────────────┘    └───────────┘
```

### 数据持久化流程

```
┌──────────┐     ┌───────────┐     ┌─────────────┐     ┌──────────┐
│ UI State │────▶│  Tauri    │────▶│ Rust Storage│────▶│ SQLite   │
│ Change   │     │  Invoke   │     │   Service   │     │ Database │
└──────────┘     └───────────┘     └─────────────┘     └──────────┘
```

---

## 数据库设计

### SQLite 表结构

```sql
-- 请求集合表
CREATE TABLE collections (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    parent_id TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES collections(id)
);

-- 请求表
CREATE TABLE requests (
    id TEXT PRIMARY KEY,
    collection_id TEXT,
    name TEXT NOT NULL,
    method TEXT NOT NULL,
    url TEXT NOT NULL,
    headers TEXT, -- JSON
    body_type TEXT, -- none/json/form-data/x-www-form-urlencoded/raw/binary
    body_content TEXT,
    body_raw_type TEXT, -- json/text/xml/html
    params TEXT, -- JSON array
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_id) REFERENCES collections(id)
);

-- 请求历史表
CREATE TABLE history (
    id TEXT PRIMARY KEY,
    request_id TEXT,
    method TEXT NOT NULL,
    url TEXT NOT NULL,
    headers TEXT,
    body TEXT,
    response_status INTEGER,
    response_time_ms INTEGER,
    response_size INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 环境表
CREATE TABLE environments (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    is_global BOOLEAN DEFAULT FALSE,
    variables TEXT, -- JSON array
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 设置表
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cookie 表
CREATE TABLE cookies (
    id TEXT PRIMARY KEY,
    domain TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT,
    path TEXT DEFAULT '/',
    expires TIMESTAMP,
    secure BOOLEAN DEFAULT FALSE,
    http_only BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## IPC 接口设计

### 前端调用 Rust 命令

```typescript
// HTTP 相关
interface HttpCommands {
  sendRequest(request: HttpRequest): Promise<HttpResponse>;
  cancelRequest(requestId: string): Promise<void>;
}

// 集合相关
interface CollectionCommands {
  getCollections(): Promise<Collection[]>;
  createCollection(data: CreateCollectionData): Promise<Collection>;
  updateCollection(id: string, data: UpdateCollectionData): Promise<Collection>;
  deleteCollection(id: string): Promise<void>;
  moveCollection(id: string, parentId: string | null, sortOrder: number): Promise<void>;
}

// 请求相关
interface RequestCommands {
  getRequests(collectionId?: string): Promise<Request[]>;
  getRequest(id: string): Promise<Request>;
  createRequest(data: CreateRequestData): Promise<Request>;
  updateRequest(id: string, data: UpdateRequestData): Promise<Request>;
  deleteRequest(id: string): Promise<void>;
  duplicateRequest(id: string): Promise<Request>;
}

// 历史相关
interface HistoryCommands {
  getHistory(limit?: number, offset?: number): Promise<HistoryItem[]>;
  clearHistory(): Promise<void>;
  deleteHistoryItem(id: string): Promise<void>;
}

// 环境相关
interface EnvironmentCommands {
  getEnvironments(): Promise<Environment[]>;
  getGlobalEnvironment(): Promise<Environment>;
  createEnvironment(data: CreateEnvironmentData): Promise<Environment>;
  updateEnvironment(id: string, data: UpdateEnvironmentData): Promise<Environment>;
  deleteEnvironment(id: string): Promise<void>;
  getActiveEnvironmentId(): Promise<string | null>;
  setActiveEnvironment(id: string | null): Promise<void>;
}

// 导入导出
interface ImportExportCommands {
  importFromPostman(filePath: string): Promise<ImportResult>;
  exportToPostman(collectionId?: string): Promise<string>;
  exportBackup(): Promise<string>;
  importBackup(filePath: string): Promise<void>;
}

// WebSocket
interface WebSocketCommands {
  connect(url: string, headers?: Record<string, string>): Promise<string>;
  disconnect(connectionId: string): Promise<void>;
  send(connectionId: string, data: string): Promise<void>;
  onMessage(callback: (data: { connectionId: string; message: string }) => void): UnlistenFn;
}

// 代码生成
interface CodeGenCommands {
  generateCode(request: HttpRequest, language: string): Promise<string>;
}

// cURL
interface CurlCommands {
  parseCurl(curlCommand: string): Promise<HttpRequest>;
  generateCurl(request: HttpRequest): Promise<string>;
}

// 设置
interface SettingsCommands {
  getSettings(): Promise<Settings>;
  updateSettings(settings: Partial<Settings>): Promise<void>;
  getProxySettings(): Promise<ProxySettings>;
  updateProxySettings(settings: ProxySettings): Promise<void>;
}
```

---

## 状态管理设计

### Zustand Store 结构

```typescript
// 请求状态
interface RequestState {
  // 当前标签页
  tabs: Tab[];
  activeTabId: string | null;
  
  // 当前请求
  currentRequest: Request;
  requestLoading: boolean;
  response: Response | null;
  
  // Actions
  addTab: (request?: Request) => void;
  closeTab: (tabId: string) => void;
  setActiveTab: (tabId: string) => void;
  updateCurrentRequest: (updates: Partial<Request>) => void;
  sendRequest: () => Promise<void>;
  cancelRequest: () => void;
}

// 集合状态
interface CollectionState {
  collections: Collection[];
  expandedIds: Set<string>;
  selectedRequestId: string | null;
  
  // Actions
  loadCollections: () => Promise<void>;
  createCollection: (data: CreateCollectionData) => Promise<void>;
  updateCollection: (id: string, data: UpdateCollectionData) => Promise<void>;
  deleteCollection: (id: string) => Promise<void>;
  toggleExpanded: (id: string) => void;
  selectRequest: (id: string) => void;
}

// 环境状态
interface EnvironmentState {
  environments: Environment[];
  activeEnvironmentId: string | null;
  globalVariables: Variable[];
  
  // Actions
  loadEnvironments: () => Promise<void>;
  setActiveEnvironment: (id: string | null) => void;
  updateVariable: (envId: string, key: string, value: string) => void;
  resolveVariables: (text: string) => string;
}

// UI 状态
interface UIState {
  theme: 'light' | 'dark' | 'system';
  sidebarVisible: boolean;
  sidebarWidth: number;
  responseViewMode: 'pretty' | 'raw' | 'preview';
  layoutDirection: 'horizontal' | 'vertical';
  fontSize: number;
  
  // Actions
  setTheme: (theme: UIState['theme']) => void;
  toggleSidebar: () => void;
  setSidebarWidth: (width: number) => void;
  setResponseViewMode: (mode: UIState['responseViewMode']) => void;
  setLayoutDirection: (direction: UIState['layoutDirection']) => void;
  setFontSize: (size: number) => void;
}
```

---

## 错误处理策略

### 前端错误处理

```typescript
// 错误类型
enum ErrorType {
  NETWORK_ERROR = 'NETWORK_ERROR',
  TIMEOUT_ERROR = 'TIMEOUT_ERROR',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  NOT_FOUND_ERROR = 'NOT_FOUND_ERROR',
  SERVER_ERROR = 'SERVER_ERROR',
  UNKNOWN_ERROR = 'UNKNOWN_ERROR',
}

// 错误处理流程
1. Rust 命令返回 Result<T, Error>
2. 前端封装统一错误处理 Hook
3. 根据错误类型显示 Toast/Modal
4. 网络错误支持重试
```

### Rust 错误处理

```rust
// 统一错误类型
#[derive(Debug, thiserror::Error, Serialize)]
enum AppError {
    #[error("Network error: {0}")]
    Network(String),
    #[error("Timeout")]
    Timeout,
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
    #[error("Database error: {0}")]
    Database(String),
    #[error("Not found: {0}")]
    NotFound(String),
}

// 自动转换到前端错误
impl serde::Serialize for AppError {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::ser::Serializer,
    {
        serializer.serialize_str(self.to_string().as_ref())
    }
}
```

---

## 安全考虑

| 方面 | 措施 |
|------|------|
| 敏感数据 | Token/密码使用 keyring 存储 |
| HTTPS | 默认验证 SSL 证书，可配置忽略 |
| 文件访问 | 使用 Tauri 的 Scoped FS API |
| 代码执行 | 禁止执行任意用户代码 |
| 更新机制 | 使用 Tauri 官方更新方案 |

---

## 性能优化

| 优化点 | 方案 |
|--------|------|
| 大数据响应 | 虚拟滚动 + 流式显示 |
| 历史记录 | 分页加载 + 本地缓存 |
| 启动速度 | 延迟加载非核心模块 |
| 内存管理 | 大响应体不存储在状态 |
| 数据库查询 | 索引优化 + 连接池 |
