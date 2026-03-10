# Hopp - AI Agent 项目指南

> 本文件记录项目知识积累、任务状态和关键决策，供后续会话参考。

---

## 项目概述

**Hopp** 是一款轻量级、跨平台的 API 请求测试工具，类似 Postman，基于 Flutter 构建，注重性能和用户体验。

**当前状态**: ✅ **Session End - Widget 测试完成，405个测试全部通过**  
**技术栈**: Flutter 3.27.x + Dart + Riverpod  
**目标平台**: macOS 10.15+ / Windows 10+ / Linux  
**下次会话重点**: 主题/国际化完善、快捷键支持、M3 用户体验功能

---

## 🔧 Flutter 开发环境配置

### FVM (Flutter Version Management)

项目使用 FVM 管理 Flutter 版本，确保团队协作时 Flutter 版本一致。

**当前版本**: `3.27.4`

**配置文件**:
- `.fvmrc` - FVM 配置文件
- `.fvm/fvm_config.json` - FVM 内部配置

**常用命令**:
```bash
# 安装 FVM (如果尚未安装)
dart pub global activate fvm

# 使用项目指定的 Flutter 版本
fvm use

# 运行 Flutter 命令
fvm flutter run
fvm flutter build macos

# 安装依赖
fvm flutter pub get
```

### 国内镜像配置

由于网络原因，中国大陆开发者需要配置国内镜像以加速 Flutter 和 Dart 包的下载。

**推荐镜像**: Flutter 中国社区 (CFUG)

**环境变量配置** (添加到 `~/.zshrc` 或 `~/.bashrc`):
```bash
# Flutter 中国社区镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

**其他可用镜像**:

| 镜像提供商 | PUB_HOSTED_URL | FLUTTER_STORAGE_BASE_URL |
|-----------|----------------|-------------------------|
| **CFUG (推荐)** | `https://pub.flutter-io.cn` | `https://storage.flutter-io.cn` |
| 上海交通大学 | `https://mirror.sjtu.edu.cn/dart-pub` | `https://mirror.sjtu.edu.cn` |
| 清华大学 TUNA | `https://mirrors.tuna.tsinghua.edu.cn/dart-pub` | `https://mirrors.tuna.tsinghua.edu.cn/flutter` |

**安装 Flutter SDK (使用国内镜像)**:
```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
fvm install 3.27.4
fvm use 3.27.4
```

**注意**: 如需发布 package 到 pub.dev，需要临时取消 `PUB_HOSTED_URL` 环境变量并配置代理。

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
| **Flutter 架构迁移** | 🔄 | 从 Tauri+React 迁移至 Flutter |

### Flutter 迁移任务清单 📋

| 任务 | 优先级 | 预计工时 | 状态 |
|------|--------|----------|------|
| FVM 环境配置 | 🟢 P0 | 1h | ✅ 完成 |
| Flutter 项目结构 | 🟢 P0 | 2h | ✅ 完成 |
| 核心模型迁移 | 🟢 P0 | 3h | ✅ 完成 |
| Riverpod 状态管理 | 🟢 P0 | 4h | ✅ 完成 |
| Dio HTTP 服务 | 🟢 P0 | 3h | ✅ 完成 |
| 本地存储 (Hive+SP) | 🟡 P1 | 3h | ✅ 完成 |
| 侧边栏组件 | 🟡 P1 | 4h | ✅ 完成 |
| 标签页组件 | 🟡 P1 | 3h | ✅ 完成 |
| 请求编辑器 UI | 🟡 P1 | 4h | ✅ 完成 |
| 响应展示 UI | 🟡 P1 | 4h | ✅ 完成 |
| 国际化 (i18n) | 🟢 P2 | 2h | ✅ 完成 |
| 日志系统 | 🟢 P2 | 2h | ✅ 完成 |
| 代码规范配置 | 🟢 P0 | 2h | ✅ 完成 |
| 文档更新 | 🟡 P1 | 4h | ✅ 完成 |
| CI/CD 更新 (Flutter) | 🟢 P2 | 3h | ✅ 完成 |
| 旧代码清理 | 🟢 P2 | 2h | ✅ 完成 |

### UI/UX 优化任务 📋

| 任务 | 优先级 | 预计工时 | 状态 |
|------|--------|----------|------|
| UI/UX 设计规范 | 🟢 P0 | 4h | ✅ 完成 |
| 色彩系统设计 | 🟢 P0 | 2h | ✅ 完成 |
| 字体系统规范 | 🟢 P0 | 2h | ✅ 完成 |
| 间距系统统一 | 🟢 P0 | 2h | ✅ 完成 |
| 组件样式优化 | 🟡 P1 | 6h | ✅ 完成 (Sidebar 已优化) |
| 动画效果添加 | 🟢 P2 | 4h | ⏳ 待开始 |
| 暗黑模式完善 | 🟡 P1 | 4h | ⏳ 待开始 |
| 快捷键支持 | 🟢 P2 | 4h | ⏳ 待开始 |

### 质量保障任务 📋

| 任务 | 优先级 | 预计工时 | 状态 |
|------|--------|----------|------|
| 单元测试 (Models) | 🟢 P0 | 4h | ✅ 完成 (152个测试) |
| 单元测试 (Services) | 🟢 P0 | 4h | ✅ 完成 (73个测试) |
| 单元测试 (Providers) | 🟢 P0 | 4h | ✅ 完成 (92个测试) |
| **Widget 测试** | 🟡 P1 | 6h | ✅ 完成 (88个测试) |
| 集成测试 | 🟢 P2 | 4h | ⏳ 待开始 |
| 代码覆盖率 80%+ | 🟡 P1 | - | ⏳ 待开始 |

### 下次会话计划 (Next Session) 📋

**建议优先级**：

1. **🟢 P0 - 单元测试实现** (8h)
   - Models 测试 (HttpRequest, HttpResponse, Collection 等)
   - Services 测试 (HttpService, StorageService)
   - 使用 Mockito 进行 mock

2. **🟡 P1 - Widget 测试** (6h)
   - Sidebar 组件测试
   - RequestEditor 组件测试
   - ResponseViewer 组件测试

3. **🟢 P2 - 主题/国际化完善** (4h)
   - 主题切换功能
   - 暗黑模式完善
   - 语言切换功能

4. **🟢 P2 - 快捷键支持** (4h)
   - 常用操作快捷键
   - 快捷键配置

---

## 💡 知识积累

### 技术决策记录

#### 1. 架构变更：从 Tauri 迁移到 Flutter

**为什么从 Tauri + React 迁移到 Flutter？**

原项目使用 Tauri 2.x + React 18 + TypeScript + Rust 技术栈，现决定全面迁移至 Flutter 架构。主要考虑因素：

- **统一技术栈**: Flutter 使用 Dart 单一语言，前后端逻辑都在 Dart 中实现，减少语言切换成本
- **更成熟的桌面支持**: Flutter 3.x 对桌面端（macOS/Windows/Linux）的支持日益成熟
- **UI 一致性**: Flutter 自绘引擎确保跨平台 UI 完全一致，不受系统 WebView 差异影响
- **性能**: Dart AOT 编译为原生代码，性能接近原生应用
- **热重载**: Flutter 的热重载在桌面端开发体验优秀
- **未来扩展**: 如果未来需要支持移动端（iOS/Android），Flutter 可以无缝迁移

**技术栈变更对比**:

| 功能 | 原技术栈 (Tauri) | 新技术栈 (Flutter) |
|------|-----------------|-------------------|
| UI 框架 | React 18 | Flutter Widgets |
| 编程语言 | TypeScript + Rust | Dart |
| 状态管理 | Zustand | Riverpod |
| HTTP 客户端 | Axios + reqwest | Dio |
| 本地存储 | localStorage + SQLite | Hive + SharedPreferences |
| 国际化 | i18next | flutter_localizations |
| 构建工具 | Vite | Flutter SDK |

#### 2. Flutter 状态管理选择 Riverpod 的原因
- **编译时安全**: 相比 Provider，Riverpod 在编译时就能捕获错误
- **类型安全**: 完全支持泛型，无需手动指定类型
- **可测试性**: 不依赖 BuildContext，易于单元测试
- **代码生成**: 支持 `@riverpod` 注解生成代码，减少样板代码
- ** Scoped 状态**: 支持覆盖（override）provider，便于测试和复用
- **生态成熟**: 与 Flutter 社区紧密结合，文档丰富

#### 3. HTTP 客户端选择 Dio 的原因
- **功能丰富**: 支持拦截器、取消请求、文件上传下载、FormData 等
- **插件生态**: 有 retry、cache、smart_retry 等丰富的插件
- **错误处理**: 内置完善的错误处理机制
- **类型安全**: 支持泛型，响应数据可以轻松类型化
- **社区活跃**: 是国内 Flutter 社区最广泛使用的 HTTP 客户端

#### 4. 本地存储选择 SharedPreferences + Hive 的原因
- **SharedPreferences**: 适合存储简单的键值对配置（如主题、语言设置）
- **Hive**: 高性能 NoSQL 数据库，适合存储复杂数据结构（如请求历史、Collection）
- **纯 Dart 实现**: 无需原生代码，跨平台一致性更好
- **性能优异**: Hive 使用二进制存储，读写速度快
- **类型安全**: 支持 Dart 对象直接存储，通过 TypeAdapter 实现

#### (已归档) 原技术栈决策

<details>
<summary>点击查看原 Tauri 技术栈决策记录</summary>

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

</details>
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

### 2026-03-11 会话 - M6 单元测试完成

**本次会话完成的工作**:
1. ✅ 完成 M6 单元测试实现 (P0)
2. ✅ Models 单元测试 - 152个测试 (7个模型类)
3. ✅ Services 单元测试 - 73个测试 (HttpService + StorageService)
4. ✅ Providers 单元测试 - 92个测试 (所有 StateNotifier 和 Provider)
5. ✅ 创建 mock 类和 fixtures 辅助工具
6. ✅ 使用 mockito 生成 Dio、Hive、SharedPreferences 的 mock
7. ✅ 所有 317 个测试全部通过

**创建的测试文件**:

| 类别 | 文件 | 测试数 |
|------|------|--------|
| Models | test/models/http_method_test.dart | 12 |
| Models | test/models/key_value_pair_test.dart | 18 |
| Models | test/models/http_request_test.dart | 26 |
| Models | test/models/http_response_test.dart | 24 |
| Models | test/models/collection_test.dart | 28 |
| Models | test/models/request_tab_test.dart | 22 |
| Models | test/models/app_settings_test.dart | 32 |
| Services | test/services/http_service_test.dart | 28 |
| Services | test/services/storage_service_test.dart | 45 |
| Providers | test/providers/core_providers_test.dart | 6 |
| Providers | test/providers/request_tab_provider_test.dart | 27 |
| Providers | test/providers/request_response_provider_test.dart | 15 |
| Providers | test/providers/collection_provider_test.dart | 19 |
| Providers | test/providers/settings_provider_test.dart | 25 |

**Mock 和 Fixtures**:
- test/mocks/dio.mocks.dart - Dio mock 配置
- test/mocks/hive.mocks.dart - Hive mock 配置
- test/mocks/service_mocks.dart - Service mock 配置
- test/fixtures/request_fixtures.dart - 请求测试数据
- test/fixtures/response_fixtures.dart - 响应测试数据

**测试覆盖范围**:
- **Models**: 创建、copyWith、JSON 序列化、相等性、边界条件、自定义 getter
- **HttpService**: configure、sendRequest 成功/错误场景、query params、headers、body 处理、cancel token
- **StorageService**: Settings/Collections/Requests CRUD、SharedPreferences、clear/close
- **Providers**: 所有 StateNotifier 方法、状态转换、错误处理、衍生 Provider

**运行命令**:
```bash
# 运行所有测试
fvm flutter test

# 运行特定类别测试
fvm flutter test test/models/
fvm flutter test test/services/
fvm flutter test test/providers/

# 生成覆盖率报告
fvm flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**下次会话重点**:
- Widget 测试 (Sidebar, RequestEditor, ResponseViewer)
- 主题切换功能完善
- 快捷键支持

---

### 2026-03-11 会话 - Widget 测试完成

**本次会话完成的工作**:
1. ✅ 完成 P1 Widget 测试实现
2. ✅ Sidebar Widget 测试 - 25个测试
   - 渲染测试：header、search、loading、error、empty state、collection tree
   - 交互测试：toggle expand、open tab、context menu、dialogs
   - 嵌套集合和 HTTP 方法 badge 测试
3. ✅ RequestEditor Widget 测试 - 32个测试
   - 渲染测试：empty state、URL bar、method dropdown、all tabs
   - Params/Headers/Body/Auth tab 内容测试
   - 复杂场景：多个 params/headers、JSON body
4. ✅ ResponseViewer Widget 测试 - 25个测试
   - 渲染测试：tabs、empty state、info bar
   - Body/Headers/Cookies tab 内容测试
   - 状态码颜色、action buttons 状态测试
5. ✅ RequestTabs Widget 测试 - 28个测试
   - 渲染测试：single/multiple tabs、method badges、dirty indicator
   - 交互测试：activate tab、close tab、new tab button
   - Tab constraints 和长名称处理测试
6. ✅ 所有 88 个 Widget 测试全部通过

**创建的测试文件**:

| 类别 | 文件 | 测试数 |
|------|------|--------|
| Widgets | test/widgets/sidebar_test.dart | 25 |
| Widgets | test/widgets/request_editor_test.dart | 32 |
| Widgets | test/widgets/response_viewer_test.dart | 25 |
| Widgets | test/widgets/request_tabs_test.dart | 28 |

**Widget 测试覆盖范围**:
- **Sidebar**: 集合树渲染、展开/折叠、请求项点击、新建/删除对话框、HTTP 方法 badge
- **RequestEditor**: URL 栏、Method 选择器、Params/Headers/Body/Auth Tabs、KeyValue 编辑器
- **ResponseViewer**: 响应信息栏、Body/ Headers/Cookies Tabs、状态码颜色、复制/保存按钮
- **RequestTabs**: 标签页渲染、激活/关闭标签、新建标签、脏标记、滚动行为

**测试技术要点**:
- 使用 `ProviderContainer` + `UncontrolledProviderScope` 覆盖 provider 依赖
- 使用 mockito 生成的 mock 类模拟 StorageService
- 使用 `tester.pumpAndSettle()` 等待动画完成
- 使用 `find.textContaining()` 处理模糊文本匹配

**运行命令**:
```bash
# 运行所有 Widget 测试
fvm flutter test test/widgets/

# 运行特定 Widget 测试
fvm flutter test test/widgets/sidebar_test.dart
fvm flutter test test/widgets/request_editor_test.dart
fvm flutter test test/widgets/response_viewer_test.dart
fvm flutter test test/widgets/request_tabs_test.dart
```

**测试总计**: 317 (单元测试) + 88 (Widget 测试) = **405 个测试全部通过** ✅

**下次会话重点**:
- 主题切换功能完善
- 暗黑模式完善
- 快捷键支持

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
| 2026-03-10 | v0.2.0-flutter | **Flutter 迁移完成**: 全面迁移至 Flutter 架构，更新所有文档，配置 Dart 代码规范，设置 Flutter CI/CD |
| 2026-03-11 | v0.2.1-unit-tests | **M6 单元测试完成**: 317个测试全部通过，Models 152个 + Services 73个 + Providers 92个 |
| 2026-03-11 | v0.2.2-widget-tests | **Widget 测试完成**: 88个测试全部通过，Sidebar/RequestEditor/ResponseViewer/RequestTabs |
| 2026-03-11 | v0.2.3-logging-std | **日志规范完成**: 新增日志规范到 CODING_STANDARDS.md，所有关键模块添加日志，macOS 网络权限修复 |

---

## 参考资源

### 当前技术栈 (Flutter)
- [Flutter 官方文档](https://docs.flutter.dev/)
- [Dart 官方文档](https://dart.dev/guides)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [Flutter 中国社区](https://flutter.cn/)

### 已归档 (Tauri - 历史参考)
- [Tauri 官方文档](https://tauri.app/)
- [React 官方文档](https://react.dev/)
- [Rust 官方文档](https://www.rust-lang.org/)

---

## Flutter 开发知识积累

### 1. 代码规范与 lint 配置

项目使用 `analysis_options.yaml` 配置 Dart 代码规范：

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  language:
    strict-casts: true
    strict-raw-types: true

linter:
  rules:
    - prefer_single_quotes: true
    - prefer_final_locals: true
    - prefer_const_constructors: true
    - avoid_print: true
```

**VS Code 配置**:

```json
{
  "editor.formatOnSave": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit",
      "source.organizeImports": "explicit"
    }
  }
}
```

### 2. UI/UX 设计规范

#### 色彩系统

```dart
class AppColors {
  static const primary = Color(0xFF6366F1);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}
```

#### 间距系统

```dart
const kSpaceXS = 4.0;
const kSpaceS = 8.0;
const kSpaceM = 12.0;
const kSpaceL = 16.0;
const kSpaceXL = 24.0;
```

#### 字体规范

| 样式 | 字号 | 字重 | 用途 |
|-----|------|------|------|
| Display | 24px | 600 | 页面标题 |
| Headline | 18px | 600 | 区块标题 |
| Title | 16px | 600 | 卡片标题 |
| Body | 14px | 400 | 正文 |
| Caption | 12px | 500 | 标签 |

### 3. 状态管理最佳实践

```dart
// ✅ Good - 使用 AsyncValue 处理异步状态
class UserNotifier extends StateNotifier<AsyncValue<User>> {
  UserNotifier() : super(const AsyncValue.loading());

  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await api.getUser();
    });
  }
}

// Widget 中使用
userAsync.when(
  data: (user) => UserView(user: user),
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => ErrorView(error: err),
);
```

### 4. 代码生成命令

```bash
# 生成 Freezed 模型
dart run build_runner build --delete-conflicting-outputs

# 监听模式（开发时使用）
dart run build_runner watch --delete-conflicting-outputs

# 格式化代码
dart format lib/ test/

# 运行静态分析
dart analyze
```

### 5. 测试最佳实践

#### 5.1 测试结构

```dart
// test/models/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/user.dart';

void main() {
  group('User', () {
    group('creation', () {
      test('should create user with required fields', () {
        // Arrange
        const id = '123';
        const name = 'John';
        
        // Act
        final user = User(id: id, name: name);
        
        // Assert
        expect(user.id, equals(id));
        expect(user.name, equals(name));
      });
    });
    
    group('serialization', () {
      test('should serialize to JSON', () {
        // ...
      });
    });
  });
}
```

#### 5.2 使用 Mockito 进行 Mock

```dart
// 1. 添加注解
@GenerateMocks([Dio])
import 'http_service_test.mocks.dart';

// 2. 在测试中使用
void main() {
  late MockDio mockDio;
  late HttpService httpService;

  setUp(() {
    mockDio = MockDio();
    httpService = HttpService(dio: mockDio);
  });

  test('should make HTTP request', () async {
    // Arrange
    when(mockDio.get(any())).thenAnswer(
      (_) async => Response(
        data: {'id': '1'},
        statusCode: 200,
        requestOptions: RequestOptions(),
      ),
    );

    // Act
    final result = await httpService.fetchUser('1');

    // Assert
    verify(mockDio.get('/users/1')).called(1);
    expect(result.id, equals('1'));
  });
}
```

#### 5.3 Riverpod Provider 测试

```dart
void main() {
  test('should update state', () async {
    // 使用 ProviderContainer 覆盖依赖
    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(MockStorageService()),
      ],
    );

    // 读取 provider
    final notifier = container.read(userProvider.notifier);
    
    // 执行操作
    await notifier.loadUser();

    // 验证状态
    expect(
      container.read(userProvider),
      isA<AsyncData<User>>(),
    );
  });
}
```

#### 5.4 Fixtures 测试数据

```dart
// test/fixtures/user_fixtures.dart
class UserFixtures {
  static User get defaultUser => User(
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
  );

  static List<User> get userList => [
    defaultUser,
    User(id: '2', name: 'Jane', email: 'jane@example.com'),
  ];
}
```

#### 5.5 测试命令

```bash
# 运行所有测试
flutter test

# 运行特定类别测试
flutter test test/models/
flutter test test/services/
flutter test test/providers/
flutter test test/widgets/

# 运行特定测试文件
flutter test test/models/user_test.dart
flutter test test/widgets/sidebar_test.dart

# 运行特定组测试
flutter test --name "User creation"

# 运行测试并生成覆盖率报告
flutter test --coverage

# 生成 HTML 覆盖率报告
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

#### 5.6 测试检查清单

- [x] 模型测试: 创建、copyWith、JSON 序列化、相等性 (152个测试)
- [x] Service 测试: 成功场景、错误处理、边界条件 (73个测试)
- [x] Provider 测试: 状态转换、异步操作、错误状态 (92个测试)
- [x] Widget 测试: 渲染、交互、状态变化 (88个测试)

#### 5.7 Widget 测试最佳实践

```dart
// Widget 测试基本结构
void main() {
  group('MyWidget', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
    });

    Widget buildTestWidget({required ProviderContainer container}) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: MyWidget()),
        ),
      );
    }

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );
    }

    testWidgets('should render correctly', (tester) async {
      final container = createContainer();
      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Expected Text'), findsOneWidget);
    });
  });
}
```

### 6. 日志最佳实践

#### 6.1 日志级别选择

```dart
// trace - 最详细的跟踪，用于开发调试
AppLogger.trace('[ClassName] Entering method foo()');

// debug - 调试信息
AppLogger.debug('[ClassName] Variable value: $value');

// info - 关键业务流程
AppLogger.info('[ClassName] User logged in: ${user.id}');

// warning - 非致命问题
AppLogger.warning('[ClassName] Cache miss for key: $key');

// error - 业务逻辑失败，必须包含异常和堆栈
AppLogger.error('[ClassName] Request failed', error, stackTrace);

// fatal - 致命错误
AppLogger.fatal('[ClassName] Database connection lost', error, stackTrace);
```

#### 6.2 使用 LogMixin

```dart
import '../utils/app_logger.dart';

class MyService with LogMixin {
  void doSomething() {
    logInfo('Doing something'); // 输出: [MyService] Doing something
    logDebug('Debug info');
    logError('Error occurred', error, stack);
  }
}
```

#### 6.3 必须记录的场景

1. **服务初始化** - 记录启动状态和关键配置
2. **数据操作** - 记录保存、删除、更新的关键信息
3. **用户操作** - 记录按钮点击、页面跳转等
4. **网络请求** - 记录请求开始、完成、失败
5. **状态变化** - 记录重要的状态转换

#### 6.4 禁止事项

- ❌ 使用 `print()` - 统一使用 `AppLogger`
- ❌ 记录敏感信息（密码、Token、个人隐私）
- ❌ 在循环中使用 `info` 级别（使用 `debug` 或批量记录）
- ❌ 错误日志缺少堆栈信息

### 7. 构建命令

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

---

## 参考资源

### Flutter 生态
- [Flutter 官方文档](https://docs.flutter.dev/)
- [Dart 官方文档](https://dart.dev/guides)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [Flutter 中国社区](https://flutter.cn/)

### 第三方库
- [Dio Documentation](https://github.com/cfug/dio)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Freezed Documentation](https://pub.dev/packages/freezed)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
