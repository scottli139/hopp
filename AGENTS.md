# Hopp - AI Agent 项目指南

> 本文件记录项目知识积累、任务状态和关键决策，供后续会话参考。

---

## 项目概述

**Hopp** 是一款轻量级、跨平台的 API 请求测试工具，类似 Postman，基于 Tauri 构建，注重性能和用户体验。

**当前状态**: ✅ **M1.1-M1.4 已完成，M1.8 本地存储待开始**  
**技术栈**: Tauri 2.x + React 18 + TypeScript + Rust  
**目标平台**: macOS 10.15+ / Windows 10+ / Linux

---

## 📊 任务状态

### 已完成 ✅

| 任务 | 状态 | 完成时间 | 说明 |
|------|------|----------|------|
| M1.1 项目初始化 | ✅ | 2026-03-09 | Tauri + React + TypeScript 项目搭建完成 |
| 代码规范配置 | ✅ | 2026-03-09 | ESLint、Prettier、rustfmt、clippy 配置完成 |
| 测试框架配置 | ✅ | 2026-03-09 | Vitest + Playwright + cargo test 配置完成 |
| CI/CD 配置 | ✅ | 2026-03-09 | GitHub Actions 工作流全部通过 |
| 文档完善 | ✅ | 2026-03-09 | PRD、架构、开发计划、代码规范、测试方案文档完成 |
| GitHub Pages | ✅ | 2026-03-09 | 项目主页部署完成 |
| 多语言支持 | ✅ | 2026-03-09 | i18next 集成完成，支持中/英双语 |
| 日志系统 | ✅ | 2026-03-09 | 前端 loglevel + 后端 tracing，支持日志查看/导出/清理 |
| AI 开发标识 | ✅ | 2026-03-09 | README 和 GitHub Pages 添加 Kimi AI 开发标识 |
| GitHub 设置指南 | ✅ | 2026-03-09 | 创建 GitHub 仓库 description 和 topics 推荐文档 |
| **M1.3 基础布局组件** | ✅ | 2026-03-09 | ResizablePanel/Sidebar/Header/StatusBar/MainContent 完成，31个单元测试通过 |
| **M1.4 HTTP 核心请求功能** | ✅ | 2026-03-10 | Rust reqwest 封装，前端 HTTP 服务，54个单元测试通过 |
| **M1.5 请求编辑器 UI** | ✅ | 2026-03-10 | Method/URL/Params/Headers/Body 编辑器 |
| **M1.6 响应展示 UI** | ✅ | 2026-03-10 | 响应体/响应头展示，状态码/时间/大小 |
| **M1.7 前后端集成** | ✅ | 2026-03-10 | Tauri 命令封装，前端调用 |
| **M1.9 多标签页功能** | ✅ | 2026-03-10 | 标签页管理，Zustand store |
| **UI 优化** | 🔄 | 2026-03-10 | 重构 Sidebar/RequestTabs/RequestEditor/ResponseViewer 样式，改进间距和尺寸 |

### 进行中 🔄

| 任务 | 状态 | 说明 |
|------|------|------|
| UI 精细化调整 | - | 尺寸、间距、对齐仍需继续优化 |

### 待办 📋

| 任务 | 优先级 | 预计工时 | 说明 |
|------|--------|----------|------|
| M1.8 基础本地存储 | 🟡 P1 | 8h | Settings 配置持久化 |
| UI 精细化调整 | 🟢 P2 | 4h | 继续优化各组件尺寸、间距、对齐，达到生产级水准 |

---

## 💡 知识积累

### 技术决策记录

#### 1. 为什么选择 Tauri 而不是 Electron?
- **包体积小**: Tauri ~5MB vs Electron ~100MB+
- **内存占用低**: Tauri 使用系统 WebView，内存占用显著降低
- **安全性**: Rust 后端提供更安全的内存管理
- **性能**: 原生 Rust 代码执行效率高

#### 2. 前端状态管理选择 Zustand 的原因
- 轻量级，无需 Provider 包裹
- TypeScript 支持好
- 中间件生态丰富（immer、devtools、persist）
- 学习成本低，API 简洁

#### 3. UI 组件库选择 Radix UI 的原因
- 无样式组件，完全可控样式
- 可访问性（a11y）支持好
- 与 Tailwind CSS 配合良好
- 官方维护，质量可靠

#### 4. 国际化方案选择 i18next 的原因
- 功能成熟，社区活跃
- 支持语言自动检测和本地存储
- React 集成简单（react-i18next）
- TypeScript 支持良好
- 支持命名空间和复数等高级特性

#### 5. 日志系统设计方案
**前端日志**: 使用 `loglevel` 库
- 轻量级，无依赖
- 支持日志级别控制
- 同时输出到控制台和 localStorage
- 支持导出日志文件

**后端日志**: 使用 Rust `tracing` + `tracing-subscriber` + `tracing-appender`
- 结构化日志输出
- 支持日志文件按天滚动
- 自动清理旧日志
- 日志文件存储在应用数据目录

**日志功能**:
- 前端: `src/utils/logger.ts` - 提供 trace/debug/info/warn/error 方法
- 后端: `src-tauri/src/utils/logger.rs` - 初始化和管理日志文件
- 命令: `src-tauri/src/commands/log.rs` - Tauri 命令暴露给前端
- 服务: `src/services/logService.ts` - 前端调用后端命令的封装
- 组件: `src/components/LogViewer.tsx` - 日志查看器 UI

#### 6. HTTP 请求功能架构
**后端 (Rust)**:
- `models/http.rs` - HTTP 请求/响应模型定义
- `services/http_service.rs` - reqwest 客户端封装
- `commands/http.rs` - Tauri 命令暴露给前端

**前端 (React)**:
- `services/httpService.ts` - 调用 Tauri 命令的封装
- `stores/requestStore.ts` - Zustand store 管理请求状态
- `components/request/RequestEditor.tsx` - 请求编辑器
- `components/request/ResponseViewer.tsx` - 响应展示
- `components/request/RequestTabs.tsx` - 多标签页管理

#### 7. ESLint v10 Flat Config 配置
ESLint v10 使用新的 Flat Config 格式，需要在 `eslint.config.mjs` 中配置：
- 使用 `@eslint/js` 提供基础规则
- TypeScript 规则通过 `@typescript-eslint` 插件提供
- React 插件暂时禁用（与 ESLint v10 兼容性 issues）
- 需要在测试设置中初始化 i18n

#### 8. TypeScript React 类型导入最佳实践
在 ESLint 严格模式下，避免 `React` 命名空间导入导致的 `no-undef` 错误：
```typescript
// ❌ 不推荐
import React, { FC } from 'react';
const handleClick = (e: React.MouseEvent) => {};

// ✅ 推荐
import type { FC, MouseEvent } from 'react';
import { useState } from 'react';
const handleClick = (e: MouseEvent) => {};
```

### 遇到的问题与解决方案

#### 问题 1: CI 中 Rust Action 找不到
**现象**: `Unable to resolve action dtolnay/rust-action, repository not found`
**原因**: 网络或 Action 可用性问题
**解决**: 改用 `actions-rust-lang/setup-rust-toolchain@v1`

#### 问题 2: pnpm lockfile 兼容性
**现象**: `Cannot install with "frozen-lockfile" because pnpm-lock.yaml is absent`
**原因**: CI 环境与本地 pnpm 版本差异
**解决**: 使用 `--no-frozen-lockfile` 选项

#### 问题 3: Ubuntu 24.04 包名变更
**现象**: `Unable to locate package libwebkit2gtk-4.0-dev`
**原因**: Ubuntu 24.04 升级了 webkit2gtk 版本
**解决**: 使用 `libwebkit2gtk-4.1-dev`

#### 问题 4: Windows 图标格式错误
**现象**: `icon.ico is not in 3.00 format`
**原因**: 手动创建的 ICO 文件格式不正确
**解决**: 使用 `pnpm tauri icon` 命令重新生成所有平台图标

#### 问题 5: TypeScript globalThis 类型错误
**现象**: `Element implicitly has an 'any' type because type 'typeof globalThis' has no index signature`
**原因**: TypeScript 严格模式下不能直接给 globalThis 添加属性
**解决**: 使用类型断言 `(globalThis as Record<string, unknown>).__TAURI__`

#### 问题 6: ESLint v10 与 React 插件兼容性
**现象**: `TypeError: contextOrFilename.getFilename is not a function`
**原因**: `eslint-plugin-react` 与 ESLint v10 不兼容
**解决**: 暂时禁用 React 插件，仅使用 TypeScript ESLint 规则

#### 问题 7: TypeScript TS6133 未使用变量错误
**现象**: CI 构建失败，`error TS6133: 'React' is declared but its value is never read`
**原因**: TypeScript 严格模式要求导入的变量必须使用
**解决**: 使用 `import type { FC } from 'react'` 分离类型导入和运行时导入

#### 问题 8: Rust CI 中 -D warnings 导致构建失败
**现象**: `error: associated function 'new' is never used`
**原因**: CI 使用 `RUSTFLAGS: -D warnings` 将警告视为错误
**解决**: 对未使用的代码添加 `#[allow(dead_code)]` 属性

### 关键配置要点

#### GitHub Actions 工作流配置
- **前端任务**: 使用 `pnpm/action-setup@v2` + `actions/setup-node@v4`
- **后端任务**: 先安装 Linux 依赖，再安装 Rust
- **构建任务**: 跨平台构建需要不同的系统依赖

#### Tauri 图标生成
```bash
# 准备 1024x1024 的 SVG 或 PNG 图标
pnpm tauri icon /path/to/icon.svg --output src-tauri/icons
```

#### 日志文件位置

**后端日志文件**（Rust tracing 输出）：

| 操作系统 | 日志目录路径 |
|----------|--------------|
| **macOS** | `~/Library/Application Support/hopp/logs/` |
| **Windows** | `%APPDATA%/hopp/logs/` (通常是 `C:/Users/<用户名>/AppData/Roaming/hopp/logs/`) |
| **Linux** | `~/.config/hopp/logs/` 或 `~/.local/share/hopp/logs/` |

**前端日志**：存储在 localStorage（键名：`hopp_logs`），可通过浏览器 DevTools → Application → Local Storage 查看

**快速打开日志目录**：在应用内点击 "Show Logs" → 查看 "Log Directory" 路径

#### 添加新语言支持
```bash
# 1. 在 src/i18n/locales/ 下创建新的翻译文件，如 ja.json
# 2. 在 src/i18n/index.ts 中导入并添加到 resources
# 3. 更新 Language 类型定义
# 4. 在组件中使用 useTranslation hook

# 使用示例
import { useTranslation } from 'react-i18next';

const MyComponent = () => {
  const { t, i18n } = useTranslation();
  return <h1>{t('app.name')}</h1>;
};
```

#### Git 配置
```bash
# 提交模板
git config commit.template .gitmessage

# 代理（如果需要）
git config --global http.proxy http://127.0.0.1:7897
git config --global https.proxy http://127.0.0.1:7897

# 当前项目用户配置已更新为
# user.name: zhongmou
# user.email: zhongmou@beeuc.com
```

---

## 📁 项目文档结构

```
docs/
├── PRD.md                      # 需求规格说明书
├── ARCHITECTURE.md             # 架构设计文档
├── DEVELOPMENT_PLAN.md         # 开发计划与里程碑
├── CODING_STANDARDS.md         # 代码规范与风格指南
├── TESTING.md                  # 自动化测试方案
├── DEVELOPMENT_ENVIRONMENT.md  # 开发环境搭建指南
└── BACKLOG.md                  # 待办功能清单
```

---

## 🛠️ 技术栈详情

### 前端 (Frontend)

| 技术 | 版本 | 用途 |
|------|------|------|
| React | 18.x | UI 框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 5.x | 构建工具 |
| Tailwind CSS | 4.x | 原子化 CSS (v4) |
| Radix UI | 1.x | 无样式 UI 组件库 |
| Zustand | 4.x | 全局状态管理 |
| Immer | 11.x | 不可变数据更新 |
| Monaco Editor | latest | JSON/代码编辑 |
| i18next | 25.x | 国际化框架 |
| react-i18next | 16.x | React i18n 集成 |

### 后端 (Backend - Tauri)

| 技术 | 版本 | 用途 |
|------|------|------|
| Tauri | 2.x | 桌面应用框架 |
| Rust | 1.75+ | 系统编程语言 |
| reqwest | 0.11+ | HTTP 客户端 |
| tokio | 1.x | 异步运行时 |
| rusqlite | 0.30+ | SQLite 数据库 |
| serde | 1.x | 序列化/反序列化 |
| thiserror | 1.x | 错误处理 |
| urlencoding | 2.x | URL 编码 |

---

## 📂 目录结构

```
hopp/
├── .github/workflows/          # CI/CD 配置
│   ├── ci.yml                  # 主 CI 工作流
│   ├── pr-check.yml            # PR 检查
│   └── pages.yml               # GitHub Pages 部署
├── .vscode/                    # VS Code 配置
├── .husky/                     # Git hooks
├── docs/                       # 项目文档
├── e2e/                        # E2E 测试
├── src/                        # 前端源码
│   ├── components/             # UI 组件
│   │   ├── layout/             # 布局组件 (ResizablePanel, Sidebar, Header, StatusBar, MainContent)
│   │   └── request/            # 请求组件 (RequestEditor, ResponseViewer, RequestTabs)
│   ├── hooks/                  # 自定义 Hooks
│   ├── stores/                 # Zustand 状态管理
│   ├── services/               # API 服务
│   ├── types/                  # TypeScript 类型
│   ├── utils/                  # 工具函数
│   ├── i18n/                   # 国际化配置
│   └── test/                   # 测试配置
├── src-tauri/                  # Rust 后端
│   ├── src/
│   │   ├── commands/           # Tauri 命令
│   │   │   ├── log.rs          # 日志相关命令
│   │   │   └── http.rs         # HTTP 请求命令
│   │   ├── services/           # 业务服务
│   │   │   └── http_service.rs # HTTP 服务
│   │   ├── models/             # 数据模型
│   │   │   └── http.rs         # HTTP 模型
│   │   └── utils/              # 工具函数
│   ├── icons/                  # 应用图标
│   ├── Cargo.toml              # Rust 依赖
│   └── tauri.conf.json         # Tauri 配置
├── package.json                # Node.js 依赖
├── vite.config.ts              # Vite 配置
├── vitest.config.ts            # Vitest 配置
├── playwright.config.ts        # Playwright 配置
├── eslint.config.mjs           # ESLint Flat Config (v10)
├── .prettierrc                 # Prettier 配置
├── rustfmt.toml                # Rust 格式化配置
├── .clippy.toml                # Clippy 配置
└── tsconfig.json               # TypeScript 配置
```

---

## 🚀 常用命令

```bash
# 开发
pnpm tauri dev              # 启动开发服务器
pnpm dev                    # 仅启动前端

# 代码检查
pnpm lint                   # ESLint
pnpm lint:fix               # ESLint 自动修复
pnpm format                 # Prettier 格式化
pnpm type-check             # TypeScript 类型检查
pnpm check                  # 运行所有检查

# 测试
pnpm test:unit              # 单元测试
pnpm test:unit:coverage     # 单元测试 + 覆盖率
pnpm test:e2e               # E2E 测试

# Rust
cd src-tauri
cargo build                 # 构建
cargo test                  # 测试
cargo clippy                # 代码检查
cargo fmt                   # 格式化

# 构建
pnpm tauri build            # 构建生产版本
```

---

## 🎯 下一步任务 (M1.8 - 基础本地存储)

### 目标
实现 Settings 配置持久化

### 具体工作
1. 设计 Settings 数据模型
2. 实现本地存储服务
3. 创建设置 UI 页面
4. 集成到应用启动流程

### 已创建/修改的文件汇总

#### M1.3 布局组件
- `src/components/layout/ResizablePanel.tsx` - 可拖拽调整宽度的面板
- `src/components/layout/Sidebar.tsx` - 左侧边栏导航
- `src/components/layout/Header.tsx` - 顶部工具栏
- `src/components/layout/StatusBar.tsx` - 底部状态栏
- `src/components/layout/MainContent.tsx` - 主内容区容器
- `src/components/layout/__tests__/*.test.tsx` - 31个单元测试

#### M1.4 HTTP 核心功能
- `src-tauri/src/models/http.rs` - HTTP 模型定义
- `src-tauri/src/services/http_service.rs` - HTTP 服务
- `src-tauri/src/commands/http.rs` - Tauri 命令
- `src/services/httpService.ts` - 前端 HTTP 服务
- `src/services/__tests__/httpService.test.ts` - 23个单元测试

#### M1.5 请求编辑器 UI
- `src/components/request/RequestEditor.tsx` - 请求编辑器

#### M1.6 响应展示 UI
- `src/components/request/ResponseViewer.tsx` - 响应展示

#### M1.7 前后端集成
- `src/App.tsx` - 集成所有组件

#### M1.9 多标签页功能
- `src/stores/requestStore.ts` - Zustand store
- `src/components/request/RequestTabs.tsx` - 标签页组件

---

## 📝 会话记录

### 2026-03-10 会话 - M1.4 HTTP 核心功能完成

**本次会话完成的工作**:
1. ✅ 完成 M1.4 HTTP 核心请求功能（Rust 后端）
2. ✅ 完成 M1.5 请求编辑器 UI
3. ✅ 完成 M1.6 响应展示 UI
4. ✅ 完成 M1.7 前后端集成
5. ✅ 完成 M1.9 多标签页功能
6. ✅ 添加 23 个 httpService 单元测试
7. ✅ 更新 DEVELOPMENT_PLAN.md 任务状态
8. ✅ 所有 CI 检查通过

**创建/修改的文件**:
- `src-tauri/src/models/http.rs` - HTTP 模型
- `src-tauri/src/services/http_service.rs` - HTTP 服务
- `src-tauri/src/commands/http.rs` - Tauri 命令
- `src/services/httpService.ts` - 前端 HTTP 服务
- `src/stores/requestStore.ts` - Zustand 状态管理
- `src/components/request/RequestEditor.tsx` - 请求编辑器
- `src/components/request/ResponseViewer.tsx` - 响应展示
- `src/components/request/RequestTabs.tsx` - 多标签页
- `src/App.tsx` - 主应用集成

**测试状态**:
- 单元测试: 54 个全部通过
- CI/CD: 全平台构建通过 ✅

**Git 提交记录**:
```
feat(M1.4): implement HTTP core functionality (20 files, +2164/-103)
fix: add http module declaration and format Rust code
style: format http.rs with cargo fmt
fix: remove unused vi import in test file
fix: add #[allow(dead_code)] to suppress Rust warnings in CI
docs: update AGENTS.md with M1.4 completion status
docs: update DEVELOPMENT_PLAN.md with M1 completion status
```

**待开始任务**:
- M1.8 基础本地存储 (Settings 配置持久化)

---

### 2026-03-10 会话 - UI 优化与 Bug 修复

**本次会话完成的工作**:
1. ✅ 添加 MIT LICENSE 文件
2. ✅ 修复 Tailwind CSS v4 配置（添加 @tailwindcss/vite 插件）
3. ✅ 重构全局样式系统（colors, shadows, transitions）
4. ✅ 重构 Sidebar 组件（新的 Logo、树形结构、图标优化）
5. ✅ 重构 RequestTabs 组件（现代化标签设计、Method badge）
6. ✅ 重构 RequestEditor 组件（URL 栏、Section Tabs、KeyValue 编辑器）
7. ✅ 重构 ResponseViewer 组件（响应信息栏、空状态、Headers 表格）
8. ✅ 修复 React Hooks 调用顺序问题（useMemo 放在条件返回前）
9. ✅ 所有测试通过 (54/54)

**创建/修改的文件**:
- `LICENSE` - MIT 许可证
- `vite.config.ts` - 添加 @tailwindcss/vite 插件
- `src/styles.css` - 重构全局样式系统
- `src/components/layout/Sidebar.tsx` - 全新设计
- `src/components/request/RequestTabs.tsx` - 现代化标签页
- `src/components/request/RequestEditor.tsx` - 改进布局和间距
- `src/components/request/ResponseViewer.tsx` - 改进布局和修复 Hooks 错误
- `src/App.tsx` - 更新布局结构

**遇到的问题与解决**:
- **问题**: React Hooks 调用顺序错误导致 "Rendered more hooks than during the previous render"
- **原因**: useMemo 被放在了条件返回语句之后
- **解决**: 把所有 Hooks 移到组件顶部，在任何条件判断之前调用

**测试状态**:
- 单元测试: 54 个全部通过
- Lint: 无错误

**待继续任务**:
- UI 精细化调整（尺寸、间距、对齐）

---

## 🔗 重要链接

- **GitHub 仓库**: https://github.com/scottli139/hopp
- **GitHub Actions**: https://github.com/scottli139/hopp/actions
- **GitHub Pages**: https://scottli139.github.io/hopp

---

## 📝 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-03-09 | v0.1.0-init | 项目初始化完成，CI/CD 配置完成，文档完善 |
| 2026-03-09 | v0.1.0-i18n | 多语言支持完成（中/英双语），README 双语版，GitHub Pages 双语切换 |
| 2026-03-09 | v0.1.0-logging | 日志系统完成，新增日志规范到 CODING_STANDARDS.md |
| 2026-03-09 | v0.1.0-ai-badge | README 和 GitHub Pages 添加 AI 开发标识 (Kimi Code CLI + Kimi 2.5 Model) |
| 2026-03-09 | v0.1.0-github-settings | 创建 GitHub 仓库设置指南 (description + topics 推荐) |
| 2026-03-09 | v0.1.0-layout | **M1.3 完成**: 基础布局组件 (ResizablePanel, Sidebar, Header, StatusBar, MainContent)，31个单元测试，CI通过 |
| 2026-03-10 | v0.1.0-http | **M1.4-M1.7 & M1.9 完成**: HTTP 核心功能、请求编辑器、响应展示、多标签页，54个单元测试，CI通过 |
| 2026-03-10 | v0.1.0-ui-refresh | **UI 重构**: Sidebar/RequestTabs/RequestEditor/ResponseViewer 样式优化，修复 Tailwind v4 配置和 React Hooks 顺序问题 |

---

## 参考资源

- [Tauri 官方文档](https://tauri.app/)
- [React 官方文档](https://react.dev/)
- [Rust 官方文档](https://www.rust-lang.org/)
- [Tailwind CSS 文档](https://tailwindcss.com/)
- [Zustand 文档](https://docs.pmnd.rs/zustand)
- [reqwest 文档](https://docs.rs/reqwest/)
- [ESLint Flat Config](https://eslint.org/docs/latest/use/configure/configuration-files)
