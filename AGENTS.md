# API Tester - AI Agent 项目指南

## 项目概述

**Hopp** 是一款轻量级、跨平台的 API 请求测试工具，类似 Postman，基于 Tauri 构建，注重性能和用户体验。

**当前状态**: 设计/规划阶段（尚未开始编码）  
**技术栈**: Tauri 2.x + React 18 + TypeScript + Rust  
**目标平台**: macOS 10.15+ / Windows 10+ / Linux

---

## 项目文档结构

项目文档位于 `docs/` 目录：

| 文件 | 说明 |
|------|------|
| `docs/PRD.md` | 需求规格说明书，包含完整的功能需求列表 |
| `docs/ARCHITECTURE.md` | 架构设计文档，包含技术栈、模块划分、数据库设计 |
| `docs/DEVELOPMENT_PLAN.md` | 开发计划与里程碑规划 |
| `docs/BACKLOG.md` | 待办功能清单（暂不实现的功能） |

---

## 技术栈

### 前端 (Frontend)

| 技术 | 版本 | 用途 |
|------|------|------|
| React | 18.x | UI 框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 5.x | 构建工具 |
| Tailwind CSS | 3.x | 原子化 CSS |
| Radix UI | 1.x | 无样式 UI 组件库 |
| Zustand | 4.x | 全局状态管理 |
| React Query | 5.x | 服务端状态管理 |
| Monaco Editor | latest | JSON/代码编辑 |

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

## 目录结构规划

### 前端代码目录 (`src/`)

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

### 后端代码目录 (`src-tauri/src/`)

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

## 开发计划 (Milestones)

### Milestone 1: 基础框架 (v0.1.0)
- 初始化 Tauri 项目结构
- 配置前端开发环境
- 实现基础布局组件
- 实现 HTTP 核心请求功能
- 多标签页支持

### Milestone 2: 数据管理 (v0.2.0)
- SQLite 数据库设计与实现
- 请求历史功能（自动保存）
- 收藏请求功能
- 集合/文件夹 CRUD
- Postman 格式导入/导出

### Milestone 3: 环境变量与增强功能 (v0.3.0)
- 环境变量系统
- Cookie 管理
- 文件上传/下载
- cURL 生成与解析
- 深色/浅色主题切换

### Milestone 4: 高级功能 (v0.4.0)
- WebSocket 测试
- 代理设置
- 代码生成器（Python/JS/cURL等）
- API 文档生成

### Milestone 5: 发布准备 (v1.0.0)
- 全面测试与 Bug 修复
- 性能测试与优化
- 编写用户文档
- 应用签名与打包配置

---

## 数据库设计

使用 SQLite 作为本地数据库，主要表结构：

- `collections` - 请求集合表
- `requests` - 请求表
- `history` - 请求历史表
- `environments` - 环境表
- `settings` - 设置表
- `cookies` - Cookie 表

详见 `docs/ARCHITECTURE.md` 中的数据库设计章节。

---

## 构建与运行命令

> ⚠️ **注意**: 项目目前处于设计阶段，以下命令在项目初始化后可用

### 开发环境要求
- Node.js 18+
- Rust 1.75+
- pnpm/npm/yarn

### 常用命令

```bash
# 安装前端依赖
pnpm install

# 开发模式运行（同时启动前端 dev server 和 Tauri）
pnpm tauri dev

# 构建生产版本
pnpm tauri build

# 仅构建前端
pnpm build

# 运行前端开发服务器
pnpm dev
```

---

## 代码规范

### 前端 (TypeScript/React)

- 使用 TypeScript 严格模式
- 组件使用函数式组件 + Hooks
- 使用 Zustand 进行状态管理
- 使用 Tailwind CSS 进行样式编写
- 目录命名使用 kebab-case（如 `my-component`）
- 组件文件使用 PascalCase（如 `MyComponent.tsx`）
- 工具函数使用 camelCase（如 `formatDate.ts`）

### 后端 (Rust)

- 遵循 Rust 官方代码规范
- 使用 `thiserror` 进行错误处理
- 使用 `serde` 进行序列化
- 模块命名使用 snake_case
- 结构体和枚举使用 PascalCase
- 函数和变量使用 snake_case

---

## 测试策略

### 单元测试
- Rust 核心逻辑使用 `cargo test`
- TypeScript 工具函数使用 Vitest

### E2E 测试
- 使用 Playwright 进行端到端测试
- 覆盖核心用户流程（发送请求、保存集合等）

### 目标覆盖率
- 核心模块达到 80% 覆盖率

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

## 性能目标

| 指标 | 目标值 |
|------|--------|
| 启动时间 | < 2 秒 |
| 响应时间 | < 100ms（本地） |
| 内存占用 | < 200MB |

---

## Backlog（暂不实现的功能）

以下功能已在 Backlog 中记录，当前版本暂不实现：

- 响应断言 (F4.1)
- Pre-request/Test Script (F4.2, F4.3)
- 批量运行/Collection Runner (F4.4)
- 云端同步 (F6.2)
- 团队协作 (F6.3)
- gRPC 测试 (F7.2)
- Mock 服务 (F7.4)

详见 `docs/BACKLOG.md`

---

## 参考资源

- [Tauri 官方文档](https://tauri.app/)
- [React 官方文档](https://react.dev/)
- [Rust 官方文档](https://www.rust-lang.org/)
- [Tailwind CSS 文档](https://tailwindcss.com/)
