# Hopp - AI Agent 项目指南

> 本文件是 Agent 的快速入口：项目定位、常用命令、文档索引和当前状态。详细设计、规范与实现说明见 `/docs`。

---

## 文档维护原则

- **精简**：本文件只放定位、命令、索引和状态，不铺陈细节
- **沉淀**：技术决策、问题解决、规范细节都写到 `/docs` 对应文档
- **不记录**：每日会话过程、具体操作步骤、临时调试信息
- **更新时机**：完成功能 / 修 bug / 做决策后，同步更新对应 docs 文档与下方「当前状态」

---

## 项目概述

**Hopp** 是一款轻量级、跨平台的 API 请求测试工具（类 Postman），基于 Flutter 构建。

| 项目信息 | 详情 |
|----------|------|
| **技术栈** | Flutter 3.27.x + Dart + Riverpod + Dio + Hive |
| **目标平台** | macOS 10.15+ / Windows 10+ / Linux |
| **当前版本** | `0.7.0` |

> 历史参考：项目曾使用 Tauri (React + Rust)，详见 [ARCHIVED_TAURI.md](./docs/ARCHIVED_TAURI.md)。

---

## 常用命令

### 环境准备

```bash
# 安装 FVM（如未安装）
dart pub global activate fvm

# 使用项目指定的 Flutter 版本并安装依赖
fvm use
fvm flutter pub get
```

### 代码生成

```bash
# Freezed / Riverpod / Hive / JSON 生成
fvm dart run build_runner build --delete-conflicting-outputs
```

### 测试

```bash
fvm flutter test                      # 全部单元 / Widget 测试
fvm flutter test test/models/          # 按目录运行
fvm flutter test --coverage            # 生成覆盖率报告
```

### 构建与运行

```bash
fvm flutter run
fvm flutter build macos
```

### 国内镜像

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

---

## 文档索引

`/docs` 按功能分类存放详细文档：

| 分类 | 文档 |
|------|------|
| 产品 | [PRD](./docs/PRD.md) · [BACKLOG](./docs/BACKLOG.md) |
| 技术 | [ARCHITECTURE](./docs/ARCHITECTURE.md) · [DEVELOPMENT_PLAN](./docs/DEVELOPMENT_PLAN.md) · [IMPLEMENTATION_NOTES](./docs/IMPLEMENTATION_NOTES.md) · [SHORTCUTS](./docs/SHORTCUTS_IMPLEMENTATION_PLAN.md) · [ARCHIVED_TAURI](./docs/ARCHIVED_TAURI.md) |
| 设计 | [UI_UX_GUIDELINES](./docs/UI_UX_GUIDELINES.md) · [CODING_STANDARDS](./docs/CODING_STANDARDS.md) |
| 测试 | [TESTING](./docs/TESTING.md) · [PEEKABOO_CLI_LEARNING](./docs/PEEKABOO_CLI_LEARNING.md) |
| 工程 | [DEVELOPMENT_ENVIRONMENT](./docs/DEVELOPMENT_ENVIRONMENT.md) · [GITHUB_SETTINGS](./docs/GITHUB_SETTINGS.md) · [CHANGELOG](./docs/CHANGELOG.md) |

**维护规则**：

- 新增文档时，选择合适分类并加入上表
- 架构 / 技术决策 → `ARCHITECTURE.md`；功能进度 → `DEVELOPMENT_PLAN.md`；复杂实现 → `IMPLEMENTATION_NOTES.md`
- 版本变更 → 更新 `CHANGELOG.md` 和本文件「当前状态」

---

## 当前状态

### 下次重点 🎯

- 🟡 请求设置 (Request Settings) 完善 —— 见 [IMPLEMENTATION_NOTES](./docs/IMPLEMENTATION_NOTES.md)
- 🟡 Request Body 区域优化（form-data / x-www-form-urlencoded / binary / GraphQL）
- 🟢 国际化完善
- ⏳ 行号与内容滚动同步（P2）

### 已知问题 🐛

| 问题 | 优先级 | 状态 |
|------|--------|------|
| 行号与内容滚动不同步 | P2 | 需优化 CodeEditor 组件 |

---

## 参考资源

- [Flutter](https://docs.flutter.dev/) · [Riverpod](https://riverpod.dev/) · [Material Design 3](https://m3.material.io/)
- [Dio](https://github.com/cfug/dio) · [Hive](https://docs.hivedb.dev/) · [Freezed](https://pub.dev/packages/freezed)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
