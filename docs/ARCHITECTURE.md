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

## 技术栈

### 前端 (Frontend)

| 技术 | 版本 | 用途 |
|------|------|------|
| React | 18.x | UI 框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 5.x | 构建工具 |
| Tailwind CSS | 3.x | 原子化 CSS |
| Radix UI | 1.x | 无样式 UI 组件 |
| Zustand | 4.x | 状态管理 |

### 后端 (Backend - Tauri)

| 技术 | 版本 | 用途 |
|------|------|------|
| Tauri | 2.x | 桌面应用框架 |
| Rust | 1.75+ | 系统语言 |
| reqwest | 0.11+ | HTTP 客户端 |
| tokio | 1.x | 异步运行时 |
| rusqlite | 0.30+ | SQLite 数据库 |

## 目录结构

```
src/
├── components/           # UI 组件
├── pages/               # 页面
├── stores/              # Zustand 状态管理
├── hooks/               # 自定义 Hooks
├── services/            # Tauri API 调用封装
├── types/               # TypeScript 类型定义
└── utils/               # 工具函数

src-tauri/src/
├── commands/            # Tauri 命令
├── services/            # 业务服务
├── models/              # 数据模型
└── utils/               # 工具函数
```

## 数据库设计

### SQLite 表结构

```sql
-- 请求集合表
CREATE TABLE collections (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 请求表
CREATE TABLE requests (
    id TEXT PRIMARY KEY,
    collection_id TEXT,
    name TEXT NOT NULL,
    method TEXT NOT NULL,
    url TEXT NOT NULL,
    headers TEXT,
    body TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 请求历史表
CREATE TABLE history (
    id TEXT PRIMARY KEY,
    method TEXT NOT NULL,
    url TEXT NOT NULL,
    response_status INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 环境表
CREATE TABLE environments (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    variables TEXT,
    is_global BOOLEAN DEFAULT FALSE
);
```
