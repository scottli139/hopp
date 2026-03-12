# Hopp - AI Agent 项目指南

> 本文件记录项目知识积累、任务状态和关键决策，供后续会话参考。

---

## 📑 目录

- [项目概述](#项目概述)
- [开发环境配置](#开发环境配置)
- [任务状态](#任务状态)
- [知识积累](#知识积累)
- [会话记录](#会话记录)
- [更新日志](#更新日志)
- [参考资源](#参考资源)
- [附录：Tauri 归档](#附录tauri-归档)

---

## 项目概述

**Hopp** 是一款轻量级、跨平台的 API 请求测试工具，类似 Postman，基于 Flutter 构建，注重性能和用户体验。

| 项目信息 | 详情 |
|----------|------|
| **当前状态** | ✅ **快捷键与 E2E 测试完成** |
| **技术栈** | Flutter 3.27.x + Dart + Riverpod |
| **目标平台** | macOS 10.15+ / Windows 10+ / Linux |
| **测试覆盖** | 405 个测试 (Models 152 + Services 73 + Providers 92 + Widgets 88) |
| **下次重点** | 🟡 主题切换 / 🟡 响应优化 / 🟢 请求历史 |

---

## 开发环境配置

### FVM (Flutter Version Management)

项目使用 FVM 管理 Flutter 版本，确保团队协作时 Flutter 版本一致。

**当前版本**: `3.27.4`

**常用命令**:
```bash
# 安装 FVM (如果尚未安装)
dart pub global activate fvm

# 使用项目指定的 Flutter 版本
fvm use

# 运行 Flutter 命令
fvm flutter run
fvm flutter build macos
fvm flutter pub get
```

### 国内镜像配置

```bash
# 添加到 ~/.zshrc 或 ~/.bashrc
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

---

## 任务状态

### 已完成 ✅

| 任务 | 完成时间 | 说明 |
|------|----------|------|
| Flutter 架构迁移 | 2026-03-10 | 从 Tauri+React 全面迁移至 Flutter |
| M6 单元测试 | 2026-03-11 | 317个测试 (Models 152 + Services 73 + Providers 92) |
| Widget 测试 | 2026-03-11 | 88个测试全部通过 |
| UI/UX 优化 | 2026-03-11 | 修复 P0 BUG、JSON 语法高亮、响应信息栏优化 |
| HTTPS 证书查看 | 2026-03-11 | F1.11 功能实现，15个测试 |
| 品牌化 | 2026-03-11 | 统一 Logo、修复布局溢出 |
| 快捷键支持 | 2026-03-12 | Shortcuts + Actions + macOS 菜单集成 |
| Peekaboo E2E 测试 | 2026-03-12 | 完整自动化测试套件 |

### 进行中 🔄

| 任务 | 说明 |
|------|------|
| 主题切换 | Light/Dark 模式完善 |
| 响应优化 | 大响应体渲染优化 |

### 质量保障

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 152 | ✅ 通过 |
| Services 测试 | 73 | ✅ 通过 |
| Providers 测试 | 92 | ✅ 通过 |
| Widget 测试 | 88 | ✅ 通过 |
| **总计** | **405** | **全部通过** |

---

## 知识积累

### 技术决策记录

#### 1. 架构选择：Flutter vs Tauri

**为什么从 Tauri 迁移到 Flutter？**

| 因素 | Flutter | Tauri |
|------|---------|-------|
| 技术栈 | Dart 单一语言 | TypeScript + Rust |
| 桌面支持 | 成熟稳定 | 较新 |
| UI 一致性 | 自绘引擎，完全一致 | 依赖系统 WebView |
| 性能 | AOT 编译接近原生 | WebView 开销 |
| 热重载 | 优秀 | 较慢 |
| 移动端扩展 | 无缝支持 | 不支持 |

**当前技术栈**:
- UI 框架: Flutter Widgets
- 状态管理: Riverpod
- HTTP 客户端: Dio
- 本地存储: Hive + SharedPreferences
- 国际化: flutter_localizations

#### 2. Riverpod 选择原因

- **编译时安全**: 相比 Provider，编译时就能捕获错误
- **类型安全**: 完全支持泛型
- **可测试性**: 不依赖 BuildContext
- **代码生成**: 支持 `@riverpod` 注解
- **Scoped 状态**: 支持覆盖 provider

#### 3. HTTP 客户端选择 Dio

- 功能丰富（拦截器、取消请求、文件上传）
- 插件生态（retry、cache）
- 内置错误处理
- 类型安全
- 国内 Flutter 社区广泛使用

### 关键问题解决

#### URL 输入框自动全选问题

**问题**: 每输入字符就自动全选

**原因**: 每次 build 都执行 `_urlController.text = activeTab.request.url`

**解决**:
```dart
// 只在切换 tab 时更新
if (_lastTabId != activeTab.id) {
  _lastTabId = activeTab.id;
  _urlController.text = activeTab.request.url;
}
```

#### Provider 状态被覆盖问题

**问题**: 直接设置 state 被异步 `loadCollections()` 覆盖

**解决**:
```dart
// 通过 mock 配置让 loadCollections 返回正确数据
when(mockStorageService.getCollections())
    .thenAnswer((_) async => collections);
```

### UI/UX 设计规范

#### 间距系统

```dart
class AppConstants {
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
}
```

#### 字体规范

| 样式 | 字号 | 用途 |
|------|------|------|
| Display | 24px | 页面标题 |
| Title | 16px | 区块标题 |
| Body | 14px | 正文 |
| Caption | 12px | 按钮文字 |
| Tiny | 11px | 标签、徽章 |

### macOS 菜单与快捷键

**架构**:
```
macOS Menu → AppDelegate → MethodChannel → MenuChannelService → Providers
```

**快捷键列表**:
| 快捷键 | 功能 |
|--------|------|
| Cmd+N | 新建请求 |
| Cmd+Enter | 发送请求 |
| Cmd+S | 保存请求 |
| Cmd+Shift+S | 另存为 |
| Cmd+W | 关闭标签 |
| Cmd+1-9 | 切换标签 |

### Peekaboo E2E 测试

**测试位置**: `integration_test/peekaboo/`

**常用命令**:
```bash
cd integration_test/peekaboo
make test   # 完整测试
make quick  # 快速测试
make logs   # 查看日志
make clean  # 清理环境
```

### 日志最佳实践

```dart
// 使用 LogMixin
class MyService with LogMixin {
  void doSomething() {
    logInfo('Doing something'); // [MyService] Doing something
    logDebug('Debug info');
    logError('Error occurred', error, stack);
  }
}
```

**禁止事项**:
- ❌ 使用 `print()`
- ❌ 记录敏感信息（密码、Token）
- ❌ 在循环中使用 `info` 级别
- ❌ 错误日志缺少堆栈

### 测试最佳实践

#### Widget 测试结构

```dart
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

    testWidgets('should render correctly', (tester) async {
      final container = ProviderContainer(...);
      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Expected'), findsOneWidget);
    });
  });
}
```

#### 测试命令

```bash
# 运行所有测试
fvm flutter test

# 运行特定类别
fvm flutter test test/models/
fvm flutter test test/services/
fvm flutter test test/providers/
fvm flutter test test/widgets/

# 生成覆盖率报告
fvm flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 会话记录

<details>
<summary>2026-03-12 - UI 字体和布局优化</summary>

**完成工作**:
- ✅ 调整 Request/Response Tab 字体从 13px 到 12px
- ✅ 调整侧边栏 Method badge 字体从 10px 到 9px
- ✅ 调整侧边栏请求名字体从 13px 到 11px
- ✅ 限制 SegmentedButton 高度为 32px

**修改文件**:
- `lib/widgets/request/request_editor.dart`
- `lib/widgets/request/response_viewer.dart`
- `lib/widgets/layout/sidebar.dart`

</details>

<details>
<summary>2026-03-11 - UI/UX 优化完成</summary>

**完成工作**:
- ✅ 修复 P0 - Method 显示不一致 BUG（添加 dirtyRequestsProvider + 保存功能）
- ✅ 修复 P1 - 错误信息截断问题（可展开错误条）
- ✅ 实现 P1 - JSON Body 语法高亮（flutter_code_editor）

**修改文件**:
- `lib/widgets/common/code_editor.dart` (新建)
- `lib/providers/collection/collection_provider.dart`
- `lib/widgets/request/request_editor.dart`
- `lib/widgets/request/response_viewer.dart`

</details>

<details>
<summary>2026-03-11 - HTTPS 证书信息查看 (F1.11)</summary>

**完成工作**:
- ✅ 创建 CertificateInfo 模型
- ✅ 修改 HttpResponse 添加 certificateInfo 字段
- ✅ ResponseViewer 添加动态 Certificate Tab
- ✅ 15个单元测试 + 1个 Widget 测试

**修改文件**:
- `lib/models/certificate_info.dart` (新建)
- `lib/services/certificate_helper.dart` (新建)
- `lib/models/http_response.dart`
- `lib/widgets/request/response_viewer.dart`

</details>

<details>
<summary>2026-03-11 - 品牌化与 Logo 统一</summary>

**完成工作**:
- ✅ 统一应用 Logo（Dock/About/Sidebar/StatusBar）
- ✅ 修复 Sidebar header 布局溢出
- ✅ 优化空状态提示

**修改文件**:
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- `lib/widgets/layout/sidebar.dart`
- `lib/screens/about/about_screen.dart`

</details>

<details>
<summary>2026-03-12 - 快捷键与 Peekaboo E2E 测试</summary>

**完成工作**:
- ✅ Flutter 快捷键支持 (Shortcuts + Actions)
- ✅ macOS 系统菜单集成 (MethodChannel)
- ✅ Peekaboo E2E 测试套件

**修改文件**:
- `lib/widgets/common/shortcut_wrapper.dart`
- `lib/services/menu_channel.dart` (新建)
- `macos/Runner/AppDelegate.swift`
- `integration_test/peekaboo/` (新建目录)

**快捷键**:
- Cmd+N: 新建请求
- Cmd+Enter: 发送请求
- Cmd+S: 保存请求
- Cmd+W: 关闭标签

</details>

---

## 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-03-10 | v0.2.0-flutter | Flutter 迁移完成 |
| 2026-03-11 | v0.2.1-unit-tests | 317个单元测试 |
| 2026-03-11 | v0.2.2-widget-tests | 88个 Widget 测试 |
| 2026-03-11 | v0.2.5-ui-ux-fix | 修复 P0 BUG、JSON 语法高亮 |
| 2026-03-11 | v0.2.6-branding | 统一 Logo、修复布局溢出 |
| 2026-03-11 | v0.2.7-test-fix | 修复 16 个 Sidebar 测试 |
| 2026-03-12 | v0.2.8-shortcuts | 快捷键 + macOS 菜单 |
| 2026-03-12 | v0.2.9-peekaboo | Peekaboo E2E 测试套件 |

---

## 参考资源

### Flutter 生态
- [Flutter 官方文档](https://docs.flutter.dev/)
- [Riverpod 文档](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)

### 第三方库
- [Dio Documentation](https://github.com/cfug/dio)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Freezed Documentation](https://pub.dev/packages/freezed)

---

## 附录：Tauri 归档

<details>
<summary>点击查看原 Tauri 技术栈决策记录（历史参考）</summary>

### 原技术栈 (Tauri)

| 功能 | 技术 |
|------|------|
| UI 框架 | React 18 |
| 编程语言 | TypeScript + Rust |
| 状态管理 | Zustand |
| HTTP 客户端 | Axios + reqwest |
| 本地存储 | localStorage + SQLite |
| 国际化 | i18next |
| 构建工具 | Vite |

### 为什么选择 Tauri 而不是 Electron?
- 包体积小: Tauri ~5MB vs Electron ~100MB+
- 内存占用低: 使用系统 WebView
- 安全性: Rust 后端提供内存安全
- 性能: 原生 Rust 代码执行效率高

### 前端状态管理选择 Zustand
- 轻量级，无需 Provider 包裹
- TypeScript 支持好
- 中间件生态丰富
- API 简洁

### 常见问题

#### ESLint v10 Flat Config
```javascript
// eslint.config.mjs
import js from '@eslint/js';
import ts from 'typescript-eslint';

export default [
  js.configs.recommended,
  ...ts.configs.recommended,
];
```

#### TypeScript React 类型导入
```typescript
// ❌ 不推荐
import React, { FC } from 'react';

// ✅ 推荐
import type { FC } from 'react';
import { useState } from 'react';
```

### 命令参考

```bash
# 开发
pnpm tauri dev
pnpm dev

# 测试
pnpm test:unit
pnpm test:e2e

# 构建
pnpm tauri build
```

</details>

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
