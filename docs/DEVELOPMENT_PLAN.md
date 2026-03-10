# Hopp 开发计划与里程碑

> 本文档记录 Hopp 项目的开发计划、里程碑和任务进度。

---

## 🎯 项目概述

**Hopp** 是一款轻量级、跨平台的 API 请求测试工具，基于 Flutter 构建，致力于提供高效、优雅的 API 测试体验。

**当前阶段**: Flutter 迁移完成，功能完善中  
**目标版本**: v1.0.0  
**技术栈**: Flutter 3.27.x + Dart 3.6.x + Riverpod

---

## 📅 里程碑规划

### M1: 基础架构 ✅ COMPLETED

| 任务 | 状态 | 完成时间 | 说明 |
|-----|------|---------|------|
| FVM 环境配置 | ✅ | 2026-03-10 | Flutter 3.27.4 + 国内镜像 |
| 项目结构搭建 | ✅ | 2026-03-10 | 目录结构、依赖配置 |
| 代码规范配置 | ✅ | 2026-03-10 | analysis_options.yaml |
| 核心模型定义 | ✅ | 2026-03-10 | Freezed + Hive 模型 |
| 基础服务实现 | ✅ | 2026-03-10 | HTTP、存储服务 |

**技术决策**:
- 使用 FVM 管理 Flutter 版本
- 使用 Riverpod 进行状态管理
- 使用 Dio 作为 HTTP 客户端
- 使用 Hive + SharedPreferences 进行本地存储

---

### M2: 核心功能 ✅ COMPLETED

| 任务 | 状态 | 完成时间 | 说明 |
|-----|------|---------|------|
| 侧边栏组件 | ✅ | 2026-03-10 | Collection 树形结构 |
| 标签页管理 | ✅ | 2026-03-10 | 多标签页支持 |
| 请求编辑器 | ✅ | 2026-03-10 | Method/URL/Params/Headers/Body |
| 响应展示 | ✅ | 2026-03-10 | Body/Headers/Status/Time/Size |
| HTTP 请求发送 | ✅ | 2026-03-10 | Dio 封装，错误处理 |

**UI 设计**:
- Material Design 3 设计语言
- 可拖拽调整面板宽度
- 响应式布局适配

---

### M3: 用户体验 🔄 IN PROGRESS

| 任务 | 状态 | 优先级 | 预计工时 |
|-----|------|--------|---------|
| 主题切换 | 🔄 | P1 | 4h |
| 国际化完善 | 🔄 | P1 | 6h |
| 快捷键支持 | ⏳ | P2 | 8h |
| 请求历史 | ⏳ | P2 | 8h |
| 拖拽排序 | ⏳ | P2 | 6h |

**设计规范**:
- 统一的间距系统 (4/8/12/16/24/32)
- 一致的按钮高度 (28/36/44)
- 标准化圆角 (4/6/8/12)
- 专业的配色方案

---

### M4: 高级功能 📋 PLANNED

| 任务 | 状态 | 优先级 | 预计工时 |
|-----|------|--------|---------|
| 环境变量 | ⏳ | P1 | 12h |
| Pre/Post Script | ⏳ | P2 | 16h |
| 批量请求 | ⏳ | P2 | 12h |
| WebSocket 支持 | ⏳ | P3 | 16h |
| gRPC 支持 | ⏳ | P3 | 20h |

---

### M5: 数据管理 📋 PLANNED

| 任务 | 状态 | 优先级 | 预计工时 |
|-----|------|--------|---------|
| Postman 导入/导出 | ⏳ | P1 | 12h |
| Insomnia 导入 | ⏳ | P2 | 8h |
| 云端同步 | ⏳ | P2 | 20h |
| 团队协作 | ⏳ | P3 | 40h |

---

### M6: 测试与质量 🔄 IN PROGRESS

| 任务 | 状态 | 优先级 | 预计工时 |
|-----|------|--------|---------|
| 单元测试 | ✅ | P0 | 16h | 2026-03-11 |
| Widget 测试 | ✅ | P1 | 12h | 2026-03-11 | 88个测试全部通过 |
| 集成测试 | ⏳ | P1 | 12h | - |
| CI/CD 配置 | ✅ | P0 | 8h | 2026-03-10 |
| 性能优化 | ⏳ | P2 | 16h |

---

## 📊 当前任务状态

### 进行中 🔄

| 任务 | 负责人 | 进度 | 截止时间 |
|-----|-------|------|---------|
| Widget 测试 | ✅ 完成 | 100% | 2026-03-11 |
| UI 细节优化 | - | 30% | 2026-03-14 |

### 待办 📋

| 任务 | 优先级 | 预计工时 |
|-----|-------|---------|
| 主题切换 (Light/Dark) | 🟡 P1 | 4h |
| 国际化完善 | 🟡 P1 | 6h |
| 快捷键支持 | 🟢 P2 | 8h |
| 请求历史记录 | 🟢 P2 | 8h |
| 环境变量 | 🟡 P1 | 12h |
| Postman 导入 | 🟡 P1 | 12h |

### 已完成 ✅

| 任务 | 完成时间 | 说明 |
|-----|---------|------|
| Flutter 项目搭建 | 2026-03-10 | FVM + 国内镜像 |
| 核心模型实现 | 2026-03-10 | 7 个模型类 |
| Riverpod 状态管理 | 2026-03-10 | 4 个 Provider 模块 |
| Dio HTTP 服务 | 2026-03-10 | 完整 HTTP 客户端封装 |
| Hive 本地存储 | 2026-03-10 | Collection + Request 存储 |
| 侧边栏 UI | 2026-03-10 | Collection 树形结构 |
| 标签页 UI | 2026-03-10 | 多标签管理 |
| 请求编辑器 UI | 2026-03-10 | 完整请求编辑功能 |
| 响应展示 UI | 2026-03-10 | Body/Headers 展示 |
| 文档更新 | 2026-03-10 | 5 个文档文件 |
| **单元测试** | **2026-03-11** | **317个测试全部通过** |
| **Widget 测试** | **2026-03-11** | **88个测试全部通过** |

---

## 🛠️ 技术栈

### 核心依赖

| 包名 | 版本 | 用途 |
|-----|------|-----|
| flutter_riverpod | ^2.6.1 | 状态管理 |
| dio | ^5.8.0+1 | HTTP 客户端 |
| hive | ^2.2.3 | NoSQL 存储 |
| shared_preferences | ^2.5.2 | 简单配置存储 |
| freezed_annotation | ^2.4.4 | 不可变类生成 |
| multi_split_view | ^3.6.0 | 可拖拽分割面板 |

### 开发依赖

| 包名 | 版本 | 用途 |
|-----|------|-----|
| build_runner | ^2.4.15 | 代码生成 |
| freezed | ^2.5.7 | 代码生成 |
| riverpod_generator | ^2.6.3 | Provider 生成 |
| mockito | ^5.4.5 | 测试 Mock |

---

## 📈 项目统计

### 代码统计

| 指标 | 数值 |
|-----|------|
| Dart 文件数 | 40+ |
| 模型类 | 7 |
| Provider 类 | 6 |
| Widget 组件 | 10+ |
| 测试文件 | 18 |
| 代码行数 | ~5000 |

### 测试覆盖率

| 模块 | 目标 | 当前 | 状态 |
|-----|------|------|------|
| Models | 100% | ~95% | ✅ 已完成 (152个测试) |
| Services | 90% | ~90% | ✅ 已完成 (73个测试) |
| Providers | 80% | ~85% | ✅ 已完成 (92个测试) |
| Widgets | 70% | ~60% | ✅ 已完成 (88个测试) |

---

## 🎨 设计规范

### 颜色系统

```dart
const primaryColor = Color(0xFF6366F1);
const secondaryColor = Color(0xFF8B5CF6);
const successColor = Color(0xFF10B981);
const warningColor = Color(0xFFF59E0B);
const errorColor = Color(0xFFEF4444);
```

### 间距系统

```dart
const kSpaceXS = 4.0;
const kSpaceS = 8.0;
const kSpaceM = 12.0;
const kSpaceL = 16.0;
const kSpaceXL = 24.0;
const kSpaceXXL = 32.0;
```

### 尺寸规范

| 组件 | 小尺寸 | 中尺寸 | 大尺寸 |
|-----|-------|-------|-------|
| 按钮高度 | 28 | 36 | 44 |
| 输入框高度 | 28 | 36 | 44 |
| 圆角 | 4 | 6 | 8/12 |

---

## 🚀 发布计划

### v0.1.0 - Alpha (当前)

- ✅ 基础 HTTP 请求功能
- ✅ Collection 管理
- ✅ 多标签页支持
- ✅ 基础 UI 组件

### v0.2.0 - Beta

- 🔄 主题切换
- 🔄 国际化完善
- ⏳ 快捷键支持
- ⏳ 请求历史

### v0.3.0 - RC

- ⏳ 环境变量
- ⏳ 导入/导出
- ⏳ 测试覆盖 80%+
- ⏳ 性能优化

### v1.0.0 - GA

- ⏳ 完整功能集
- ⏳ 完善的文档
- ⏳ 全平台稳定
- ⏳ 应用商店发布

---

## 📝 更新日志

### 2026-03-10 - Flutter 迁移完成 (Session End)

**已完成工作**:
- ✅ 从 Tauri + React 全面迁移至 Flutter 架构
- ✅ 完成核心功能实现（HTTP 请求、Collection、多标签页）
- ✅ 创建完整的 UI/UX 设计规范文档
- ✅ 配置 Dart 代码规范 (analysis_options.yaml)
- ✅ 更新所有项目文档（README、PRD、架构、开发计划等）
- ✅ 更新 CI/CD 工作流（Flutter 构建）
- ✅ 更新 GitHub Pages 部署配置
- ✅ 创建设计规范常量 (lib/utils/constants.dart)
- ✅ 优化 Sidebar 组件样式

**技术栈变更**:
| 层级 | 旧技术栈 | 新技术栈 |
|------|---------|---------|
| 框架 | Tauri 2.x + React 18 | Flutter 3.27.x |
| 语言 | TypeScript + Rust | Dart 3.6+ |
| 状态管理 | Zustand | Riverpod 2.x |
| HTTP 客户端 | Axios + reqwest | Dio 5.x |
| 存储 | SQLite | Hive + SharedPreferences |

**待办任务** (下次会话):
- ✅ 单元测试实现 (Models, Services, Providers) - 317个测试
- ✅ Widget 测试 - 88个测试
- ⏳ 主题切换功能完善
- ⏳ 快捷键支持
- ⏳ 请求历史功能
- ⏳ Postman 导入/导出

### 2026-03-09 - 项目初始化 (Tauri)

- Tauri + React 项目初始化
- 基础布局组件完成
- CI/CD 配置完成

---

## 🔗 参考链接

- [Flutter 文档](https://docs.flutter.dev/)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [GitHub 项目](https://github.com/scottli139/hopp)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
