# Hopp - AI Agent 项目指南

> 本文件记录项目知识积累、任务状态和关键决策，供后续会话参考。

---

## 📝 文档维护原则

**核心原则**: 精简记录，沉淀知识

- **不记录**: 详细的每日会话过程、具体的操作步骤、临时的调试信息
- **要记录**: 
  - 🎯 **重要技术决策**（架构选择、技术选型、设计模式）
  - 🔧 **关键问题解决**（bug 修复、兼容性处理、性能优化）
  - 📋 **新发现的要求**（用户反馈、最佳实践、规范约定）
  - ✅ **任务状态更新**（功能完成、已知问题、测试覆盖）

**更新时机**:
1. 完成重要功能 → 更新【任务状态】
2. 遇到棘手问题并解决 → 更新【关键问题解决】
3. 做出技术决策 → 更新【技术决策记录】
4. 发现新的开发规范 → 更新对应规范章节

---

## 📑 目录

- [项目概述](#项目概述)
- [开发环境配置](#开发环境配置)
- [项目文档说明](#项目文档说明)
- [任务状态](#任务状态)
- [知识积累](#知识积累)
  - [技术决策记录](#技术决策记录)
  - [关键问题解决](#关键问题解决)
- [更新日志](#更新日志)
- [参考资源](#参考资源)

---

## 项目概述

**Hopp** 是一款轻量级、跨平台的 API 请求测试工具，类似 Postman，基于 Flutter 构建，注重性能和用户体验。

| 项目信息 | 详情 |
|----------|------|
| **当前状态** | ✅ **Issue #7 已修复：Import/Export/Delete Collection 对话框 UI/UX 规范** |
| **技术栈** | Flutter 3.27.x + Dart + Riverpod |
| **目标平台** | macOS 10.15+ / Windows 10+ / Linux |
| **测试覆盖** | ✅ **495 个通过 / Issue #7 UI 修复完成** |
| **下次重点** | 🔴 修复 4XX/5XX 响应显示 / 🟡 请求设置实现 / 🟢 国际化完善 |

> **历史参考**: 项目曾使用 Tauri (React + Rust) 技术栈，详见 [ARCHIVED_TAURI.md](./docs/ARCHIVED_TAURI.md)

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

## 项目文档说明

`/docs` 目录包含项目的各类文档，按功能分类如下：

### 📋 产品文档

| 文档 | 功能说明 | 更新时机 |
|------|----------|----------|
| [PRD.md](./docs/PRD.md) | **产品需求规格说明书**，定义产品功能、用户故事、非功能需求 | 新增/修改产品功能时 |
| [BACKLOG.md](./docs/BACKLOG.md) | **待办任务清单**，记录暂不实现但未来可能考虑的功能 | 发现新需求但暂不实现时 |

### 🏗️ 技术文档

| 文档 | 功能说明 | 更新时机 |
|------|----------|----------|
| [ARCHITECTURE.md](./docs/ARCHITECTURE.md) | **架构设计文档**，描述系统架构、技术选型、设计决策 | 架构变更、技术选型调整时 |
| [DEVELOPMENT_PLAN.md](./docs/DEVELOPMENT_PLAN.md) | **开发计划与里程碑**，记录任务进度、发布计划 | 每完成一个里程碑/任务时 |
| [IMPLEMENTATION_NOTES.md](./docs/IMPLEMENTATION_NOTES.md) | **实现说明文档**，详细的技术实现方案、代码示例 | 实现复杂功能时 |
| [SHORTCUTS_IMPLEMENTATION_PLAN.md](./docs/SHORTCUTS_IMPLEMENTATION_PLAN.md) | **快捷键实现计划**，记录快捷键设计方案 | 添加/修改快捷键时 |
| [ARCHIVED_TAURI.md](./docs/ARCHIVED_TAURI.md) | **Tauri 技术栈归档**，记录迁移前的技术决策（历史参考） | 仅作历史参考，不更新 |

### 🎨 设计文档

| 文档 | 功能说明 | 更新时机 |
|------|----------|----------|
| [UI_UX_GUIDELINES.md](./docs/UI_UX_GUIDELINES.md) | **UI/UX 设计规范**，定义视觉设计、交互设计、组件规范 | UI 样式变更、新增组件时 |
| [CODING_STANDARDS.md](./docs/CODING_STANDARDS.md) | **代码规范与风格指南**，定义 Flutter/Dart 编码规范 | 代码规范调整时 |

### 🧪 测试文档

| 文档 | 功能说明 | 更新时机 |
|------|----------|----------|
| [TESTING.md](./docs/TESTING.md) | **自动化测试方案**，测试策略、工具配置、最佳实践 | 测试策略变更、新增测试类型时 |
| [PEEKABOO_CLI_LEARNING.md](./docs/PEEKABOO_CLI_LEARNING.md) | **Peekaboo CLI 学习笔记**，E2E 测试工具使用文档 | 学习/使用 Peekaboo 时 |

### 🔧 工程文档

| 文档 | 功能说明 | 更新时机 |
|------|----------|----------|
| [DEVELOPMENT_ENVIRONMENT.md](./docs/DEVELOPMENT_ENVIRONMENT.md) | **开发环境搭建指南**，Flutter 环境配置说明 | 环境配置变更时 |
| [GITHUB_SETTINGS.md](./docs/GITHUB_SETTINGS.md) | **GitHub 仓库设置指南**，仓库配置、About 信息设置 | GitHub 配置变更时 |

### 文档使用指南

**添加新文档时**：
1. 根据文档内容选择合适的功能分类
2. 如果现有分类不适用，可新增分类
3. 在此表格中添加文档条目，说明功能和使用时机
4. 在文档开头添加清晰的标题和说明

**更新文档时**：
- 同步更新 AGENTS.md 中的相关描述
- 如涉及架构/技术变更，同步更新 ARCHITECTURE.md
- 如涉及功能变更，同步更新 DEVELOPMENT_PLAN.md

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
| UI 测试模式 | 2026-03-12 | 内置 HTTP 指令服务器，支持远程控制 |
| 请求名称编辑 | 2026-03-12 | 右键菜单重命名 + UI 测试模式支持 |
| 响应优化 | 2026-03-12 | 大响应体虚拟化显示优化 |
| UI 细节优化 | 2026-03-13 | Tab 样式、+按钮、URL输入框、下拉菜单优化 |
| UI 对齐修复 | 2026-03-13 | URL行高度统一36px、Method下拉与URL输入框对齐、Certificate字体缩小 |
| URL Focus 边框对齐修复 | 2026-03-13 | 修复 URL 输入框 focus 状态紫色边框与灰色背景区域高度不一致问题 |
| 请求时间分析 | 2026-03-14 | Timing Tab (DNS/TCP/TLS/TTFB/Download) |
| Request Editor UI 优化 | 2026-03-14 | Tab样式、Headers/Params列表、自动完成 |
| 请求设置功能规划 | 2026-03-14 | 参考 Postman 整理 13 项配置 |
| 请求详情展示 | 2026-03-14 | Request Tab (方法/URL/Headers/Body) |
| Request Tab 完善 | 2026-03-14 | 展示实际发送的完整请求信息（含自动添加的 Headers） |
| UI 测试调试规范 | 2026-03-15 | 日志 + 截图联动分析法、实战案例文档 |
| Body 类型选择器测试 | 2026-03-15 | Radio 组 + Raw 子类型 + UI 测试验证 |
| Dropdown 样式改进 | 2026-03-16 | Method/Raw Content Type 下拉菜单样式统一优化 |
| 请求保存功能修复 | 2026-03-16 | 修复新请求无法保存到 Collection 的问题 |
| 保存功能最终修复 | 2026-03-16 | 移除 isDirty 限制，新请求可直接保存 |
| Response Body UI 修复 | 2026-03-16 | 修复重复行号问题，禁用 CodeField 内置 gutter |
| Body 编辑器边框优化 | 2026-03-16 | 隐藏左侧边框线，Request Body 左右靠边 |
| Code Editor 字体优化 | 2026-03-16 | Request/Response Body 使用等宽字体 Menlo，字号 12px，行号 11px |
| Postman 导入/导出 | 2026-03-16 | Collection/Environment 导入导出，支持 v2.0/v2.1 格式 |
| cURL 导入 | 2026-03-18 | F2.6 解析 cURL 命令创建请求，支持常用选项，UX 改进（名称编辑/Collection 选择）|

### 进行中 🔄

| 任务 | 说明 |
|------|------|
| 请求设置 (Request Settings) | 请求级别配置选项 (F1.14)，预计 2026-03-20 开始实现 |
| Request Body 区域优化 | 参考 Postman 改进 Body Tab UI (✅ Radio 选择器/Raw 子类型/UI测试、⏳ Beautify/行号、form-data/x-www-form-urlencoded/binary/GraphQL) |
| 国际化完善 | 框架已搭建，需完善翻译 |

### 已知问题 🐛

| 问题 | 优先级 | 说明 | 状态 |
|------|--------|------|------|
| ~~4XX/5XX 响应不显示服务端返回内容~~ | ~~P0~~ | ~~当服务端返回 4XX 或 5XX 错误时，Response Body 区域不显示服务端返回的数据~~ | ✅ **已修复 (2026-03-17)** - GitHub Issue #1 已关闭 |
| ~~Postman 导入 Raw Content Type 识别错误~~ | ~~P1~~ | ~~导入 Postman Collection 时，body.options.raw.language 为 json 的请求显示为 text~~ | ✅ **已修复 (2026-03-17)** - GitHub Issue #10 已关闭 |
| ~~Certificate 显示假数据~~ | ~~P1~~ | ~~Response 区域的 Certificate Tab 当前显示的是模拟/假数据，非真实证书信息~~ | ✅ **已修复 (2026-03-17)** - GitHub Issue #2 已关闭 |
| ~~自签名证书无法访问~~ | ~~P1~~ | ~~内网自签名证书服务器请求失败，缺少 SSL 验证开关~~ | ✅ **已修复 (2026-03-17)** |
| 删除 Collection 子目录处理问题 | P1 | 删除带子目录的 Collection 时，子 Collection 未被删除而是被保留并提升到第一级 | 需修复删除逻辑 |
| 行号与内容滚动不同步 | P2 | Request/Response Body 编辑器中行号区域与内容区域未对齐，内容滚动时行号不跟随滚动 | 需优化 CodeEditor 组件 |

### 质量保障

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 152 | ✅ 通过 |
| Services 测试 | 73 | ✅ 通过 |
| Providers 测试 | 92 | ✅ 通过 |
| Widget 测试 | 88 | ✅ 通过 |
| 响应优化组件测试 | 新增 | ✅ 通过 |
| UI 优化测试 | 新增 7 个 | ✅ 通过 |
| Timing 分析测试 | 新增 | ✅ 通过 |
| 请求详情展示测试 | 新增 3 个 | ✅ 通过 |
| Body 类型选择器测试 | 新增 12 场景 | ✅ 通过 |
| cURL 解析测试 | 新增 44 个 | ✅ 通过 |
| **总计** | **495** | **✅ 全部通过** |

---

## 知识积累

### 技术决策记录

#### Request Settings 功能规划 (F1.14)

**参考**: Postman 请求级别配置

**功能清单**:

| 设置项 | 类型 | 默认值 | Dio 支持 |
|--------|------|--------|----------|
| HTTP Version | Dropdown | Auto | ✅ via `httpVersion` |
| Enable SSL certificate verification | Toggle | ON | ✅ via `HttpClient` |
| Automatically follow redirects | Toggle | ON | ✅ via `followRedirects` |
| Follow original HTTP Method | Toggle | OFF | ⚠️ 需自定义拦截器 |
| Follow Authorization header | Toggle | OFF | ⚠️ 需自定义拦截器 |
| Remove referer header on redirect | Toggle | OFF | ⚠️ 需自定义拦截器 |
| Enable strict HTTP parser | Toggle | OFF | ❌ 平台特定 |
| Encode URL automatically | Toggle | ON | ✅ 默认行为 |
| Disable cookie jar | Toggle | OFF | ✅ via `CookieManager` |
| Use server cipher suite during handshake | Toggle | OFF | ⚠️ 平台特定 |
| Maximum number of redirects | Number | 10 | ✅ via `maxRedirects` |
| TLS/SSL protocols disabled | Multi-select | - | ⚠️ 平台特定 |
| Cipher suite selection | Text | - | ⚠️ 平台特定 |

**实现架构**:
```
lib/
├── models/
│   └── request_settings.dart          # Freezed 模型
├── providers/
│   └── request/
│       └── request_settings_provider.dart
├── widgets/
│   └── request/
│       ├── request_editor.dart        # 添加 Settings Tab
│       └── request_settings_tab.dart  # 设置面板 UI
└── services/
    └── http/
        └── request_options_builder.dart   # 构建 Dio Options
```

**UI 设计**:
- 设置项采用卡片式布局，每个设置独立卡片
- 显示「Default: Settings」提示继承关系
- 修改后显示紫色圆点指示器
- 支持分组（SSL/TLS、重定向、编码等）

---

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

> **历史参考**: 详见 [ARCHIVED_TAURI.md](./docs/ARCHIVED_TAURI.md)

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

#### Hive 数据库兼容性修复 (Issue #5)

**问题**: 当 `HttpRequest` 模型新增字段（如 `@HiveField(11)`）时，旧版本数据没有该字段，访问不存在的字段会抛出异常，导致应用启动时黑屏。

**解决方案**:
1. **向后兼容适配器**: 使用 `fields[index] == null ? defaultValue : fields[index] as Type` 模式
   ```dart
   validateCertificates: fields[11] == null ? true : fields[11] as bool,
   followRedirects: fields[12] == null ? true : fields[12] as bool,
   maxRedirects: fields[13] == null ? 10 : fields[13] as int,
   ```

2. **数据库迁移服务**: 使用 SharedPreferences 存储数据库版本号，自动检测并执行必要的迁移

#### 4XX/5XX 响应正确处理 (Issue #1)

**问题**: DioException 发生时只返回错误信息，不提取 `e.response` 中的数据，导致 4XX/5XX 响应不显示服务端返回的内容。

**解决**:
```dart
} on DioException catch (e) {
  // 如果服务端返回了响应（4XX/5XX），提取响应数据
  final response = e.response;
  if (response != null) {
    return HttpResponse(
      body: responseBody,
      headers: responseHeaders,
      statusCode: response.statusCode,
      statusText: _getStatusText(response.statusCode),
      error: _formatDioError(e),  // 同时保留错误信息
    );
  }
}
```

#### SSL 证书获取与验证 (Issue #2)

**问题**: `badCertificateCallback` 只在证书验证失败时触发，正常 HTTPS 连接无法触发回调，导致无法获取真实证书信息。

**解决方案**: 使用 `SecureSocket.connect()` 预连接获取真实证书
```dart
Future<CertificateInfo?> fetchCertificateFromHost(
  String host, {
  int port = 443,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final socket = await SecureSocket.connect(
    host,
    port,
    timeout: timeout,
    onBadCertificate: (certificate) => true, // 允许获取自签名证书
  );
  
  final cert = socket.peerCertificate;
  final info = extractCertificateInfoFromX509(cert);
  socket.destroy();
  
  return info;
}
```

**SSL 验证开关实现**:
- 在 `HttpRequest` 中添加 `validateCertificates` 字段（默认 `true`）
- 为每个请求创建独立的 Dio 实例，根据配置设置 `badCertificateCallback`

#### UI 测试调试规范

**问题**: Release 模式下日志被过滤，UI 测试调试困难

**解决方案**:
1. **自定义 LogFilter**: 允许所有日志级别
   ```dart
   class _AllLogFilter extends LogFilter {
     @override
     bool shouldLog(LogEvent event) => true;
   }
   ```

2. **同步文件写入**: 使用 `writeAsStringSync` 避免异步写入导致日志丢失

3. **日志 + 截图联动分析法**:
   | 现象 | 日志表现 | 截图表现 | 诊断结论 |
   |------|----------|----------|----------|
   | 命令未到达 | 无相关日志 | 无变化 | 检查网络/端口 |
   | Provider 未监听 | 命令日志有，但无 listener 日志 | 无变化 | 检查 `ref.listen` 是否在 build 中 |
   | UI 未重建 | Provider 变化日志有，但无 build 日志 | 无变化 | 检查 `ref.watch` vs `ref.read` |

#### Request 保存功能修复

**问题**: 新创建的请求（`Cmd+N`）`isDirty = false`，保存按钮不可点击；且保存逻辑只更新已存在的请求，新请求无法保存到 Collection。

**解决方案**:
1. **移除 isDirty 限制**: 总是允许保存
   ```dart
   void _handleSaveButtonPress(...) {
     // 总是允许保存
     _saveRequest(ref, request);
   }
   ```

2. **自动添加到 Collection**: 新请求自动添加到第一个 Collection
   ```dart
   Future<void> saveRequest(HttpRequest request) async {
     final existingCollectionId = findRequestCollectionId(request.id);
     if (existingCollectionId != null) {
       await updateRequestInCollection(request);
     } else {
       await addRequestToCollection(value.first.id, request);
     }
   }
   ```

#### Code Editor 重复行号问题

**问题**: `flutter_code_editor` 的 `CodeField` 自带行号功能，与自定义行号区域重复显示。

**解决**: 禁用 `CodeField` 内置行号
```dart
CodeField(
  controller: controller,
  gutterStyle: GutterStyle.none,  // 禁用内置行号
  // ...
)
```

#### Postman 导入 Raw Content Type 识别 (Issue #10)

**问题**: `body.options.raw.language` 为 json 时显示为 text，某些 Collection 没有该字段或 Content-Type 只在 header 中指定。

**解决方案**:
1. 首先尝试从 `language` 字段映射（支持大小写不敏感）
2. 如果 language 为空，尝试从 `Content-Type` header 推断
3. 支持 JSON/XML/HTML/JavaScript/Text 类型推断

```dart
static String _mapRawContentType(String? language, List<KeyValuePair> headers) {
  // 1. 尝试从 language 字段映射
  if (language != null && language.isNotEmpty) {
    switch (language.toLowerCase().trim()) {
      case 'json': return 'json';
      case 'xml': return 'xml';
      // ...
    }
  }
  
  // 2. 从 Content-Type header 推断
  final contentTypeHeader = headers
      .where((h) => h.key.toLowerCase() == 'content-type')
      .firstOrNull;
  if (contentTypeHeader != null) {
    if (contentTypeHeader.value.contains('application/json')) {
      return 'json';
    }
  }
  
  return 'text';
}
```

#### Import/Export/Delete Collection 对话框 UI 规范修复 (Issue #7)

**问题**: Import/Export 对话框及 Delete Collection 对话框不符合 UI_UX_GUIDELINES.md 规范

**修复内容**:
1. **语言统一**: 所有对话框文本改为英文
   - Import 对话框: "Import Postman Data" / "Select File" / "Cancel" / "Done"
   - Export 对话框: "Export Postman Collection" / "Select Collection" / "Prettify JSON Output"
   - Delete Collection: "Delete Collection" / "Cancel" / "Delete"

2. **字号规范**: 使用 AppTextStyles 预定义样式
   - 标题: `AppTextStyles.title` (16px, FontWeight.w600)
   - 正文: `AppTextStyles.body` (14px) / `AppTextStyles.bodySmall` (13px)
   - 按钮文字: `AppTextStyles.caption` (12px)

3. **按钮样式规范**: 使用 AppComponentStyles
   - 主要按钮: `AppComponentStyles.primaryButton()` (高度 36px, Indigo 500)
   - 幽灵按钮: `AppComponentStyles.ghostButton()` (Cancel 按钮)
   - 危险按钮: 红色背景 (Delete 按钮), 高度 36px

4. **相关文件**:
   - `lib/widgets/import_export/import_dialog.dart`
   - `lib/widgets/import_export/export_dialog.dart`
   - `lib/widgets/import_export/conflict_resolution_dialog.dart`
   - `lib/widgets/layout/sidebar.dart` (Delete Collection 对话框)

5. **UI 测试**: 
   - 添加 `integration_test/test_dialog_ui_fix.py` 测试脚本
   - 支持截图验证对话框样式

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

### UI 测试模式

**核心实现**: `lib/utils/testing/ui_test_mode.dart`

**客户端**: `integration_test/test_client.py`

**使用方式**:
```bash
# 1. 以测试模式启动应用
./hopp.app/Contents/MacOS/hopp --test-mode

# 2. 从日志获取端口
grep "测试服务器启动在端口" ~/Library/Containers/.../hopp_*.log

# 3. 执行测试
python3 integration_test/test_client.py --port <PORT> full_test
```

**可用指令**:
- `create_request` - 创建新请求
- `set_url` - 设置 URL
- `send_request` - 发送请求
- `switch_response_tab` - 切换响应 Tab (body/headers/cookies/certificate)
- `get_response_info` - 获取响应信息
- `wait` - 等待指定时间
- `rename_request` - 直接重命名请求
- `start_edit_request_name` - 开始编辑请求名称（交互式）
- `set_request_name` - 设置编辑中的名称
- `confirm_edit_request_name` - 确认编辑
- `cancel_edit_request_name` - 取消编辑
- `get_request_info` - 获取请求信息
- `get_response_body_info` - 获取响应体信息（大小、行数等）
- `set_response_display_mode` - 设置响应显示模式（auto/performance/full/raw）
- `simulate_large_response` - 模拟大响应（用于性能测试）
- `full_test` - 完整测试流程
- `focus_url_input` - 聚焦 URL 输入框（用于测试 focus 状态边框对齐）
- `get_timing_info` - 获取请求时间分析信息（DNS/TCP/TLS/TTFB/Download）
- `simulate_response_with_timing` - 模拟带时间分析的响应

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

## 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-03-10 | v0.2.0-flutter | Flutter 迁移完成 |
| 2026-03-11 | v0.2.1-unit-tests | 317个单元测试 |
| 2026-03-11 | v0.2.2-widget-tests | 88个 Widget 测试 |
| 2026-03-11 | v0.2.5-ui-ux-fix | 修复 P0 BUG、JSON 语法高亮 |
| 2026-03-11 | v0.2.6-branding | 统一 Logo、修复布局溢出 |
| 2026-03-12 | v0.2.8-shortcuts | 快捷键 + macOS 菜单 |
| 2026-03-12 | v0.2.9-peekaboo | Peekaboo E2E 测试套件 |
| 2026-03-12 | v0.3.0-ui-test-mode | UI 测试模式，支持 HTTP 指令控制 |
| 2026-03-12 | v0.3.1-rename-request | 请求名称编辑功能 + UI 测试验证 |
| 2026-03-12 | v0.3.2-response-optimization | 大响应体渲染优化 + UI 测试 |
| 2026-03-13 | v0.3.3-ui-polish | UI 细节优化：Tab样式、+按钮、输入框对齐、边框统一、高度优化 |
| 2026-03-13 | v0.3.5-ui-fix | URL Bar 对齐修复：Method下拉、URL输入框、Save/Send按钮统一36px高度 |
| 2026-03-13 | v0.3.6-url-focus-fix | 修复 URL 输入框 focus 状态下紫色边框与灰色背景区域高度不一致问题 |
| 2026-03-14 | v0.3.7-timing-analysis | 请求时间分析功能：DNS/TCP/TLS/TTFB/Download |
| 2026-03-14 | v0.3.8-request-editor-ui | Request Editor UI 优化：Tab样式、Headers/Params列表、自动完成 |
| 2026-03-14 | v0.4.0-rc-plan | 请求设置 (Request Settings) 功能规划完成，参考 Postman 实现 |
| 2026-03-16 | v0.5.0-postman-import | Postman 导入/导出功能：Collection/Environment 支持 v2.0/v2.1 格式 |
| 2026-03-14 | v0.4.0-docs-update | 全面更新项目文档，同步实际功能状态 |
| 2026-03-14 | v0.4.1-request-details | 请求详情展示功能：Request Tab (方法/URL/Headers/Body) + UI测试 |
| 2026-03-14 | v0.4.2-request-info | Request Tab 完善：展示实际发送的完整请求信息（含自动添加的 Headers） |
| 2026-03-14 | v0.4.3-test-fix | 修复 22 个单元测试失败：修复 MissingStubError 问题，所有 418 个测试全部通过 |
| 2026-03-14 | v0.4.4-body-type-selector | Body 类型选择器重构：Radio 组样式 + Raw 子类型下拉菜单 |
| 2026-03-14 | v0.4.5-ui-test-debug-guide | 添加 UI 测试调试规范，修复 Release 模式下日志被过滤问题 |
| 2026-03-15 | v0.4.6-body-type-test | Request Body 类型选择器 UI 测试修复完成，日志系统修复 |
| 2026-03-16 | v0.4.9-save-final | Request 保存功能最终修复：移除 isDirty 限制、新请求可直接保存 |
| 2026-03-16 | v0.4.8-save-fix | Request 保存功能修复：新请求自动添加到 Collection、UI 测试验证 |
| 2026-03-16 | v0.5.0-code-editor-fix | Response/Request Body 编辑器修复：禁用 CodeField 内置行号，解决重复行号问题 |
| 2026-03-16 | v0.5.1-border-polish | Body 编辑器边框优化：隐藏左侧边框，Request Body 左右靠边 |
| 2026-03-16 | v0.5.2-border-final | Body 编辑器边框最终修复：完全禁用所有边框，使用 Theme 覆盖 inputDecorationTheme |
| 2026-03-16 | v0.4.7-dropdown-style | Dropdown 样式改进：垂直间距优化、触发按钮样式统一、UI测试验证 |
| 2026-03-16 | v0.5.3-font-update | Code Editor 字体优化：使用 Menlo 等宽字体，代码 12px/行号 11px，行高 1.5，同步更新 UI_UX_GUIDELINES |
| 2026-03-16 | v0.5.4-known-issues | 记录已知问题：Certificate 假数据、Collection 子目录删除问题、行号滚动同步问题 |
| 2026-03-17 | v0.5.5-certificate-real | 修复 Issue #2: Certificate Tab 显示真实 SSL/TLS 证书（使用 SecureSocket 预连接获取） |
| 2026-03-17 | v0.5.6-error-response-fix | 修复 Issue #1: 4XX/5XX 响应正确显示服务端返回内容 |
| 2026-03-17 | v0.5.7-ssl-verify-switch | 实现 SSL 证书验证开关（Request Settings），支持内网自签名证书，优化证书错误提示 |
| 2026-03-17 | v0.5.9-postman-import-fix | 修复 Postman 导入 Raw Content Type 映射问题 (Issue #10): 支持 language 字段和 Content-Type header 推断 |
| 2026-03-17 | v0.5.8-settings-ui-fix | 修复 Request Settings UI 样式问题 (Issue #9): 字号、Switch 尺寸和颜色规范 |
| 2026-03-18 | v0.6.0-curl-import | cURL 导入功能 (F2.6): 解析 cURL 命令创建请求，支持常用选项 (-X, -H, -d, -F, -u, -k, -L 等)，多行命令，44 个单元测试 |
| 2026-03-18 | v0.6.1-curl-import-ux | cURL 导入 UX 改进: 支持编辑请求名称、选择目标 Collection，参考 Postman 导入流程 |
| 2026-03-18 | v0.6.2-dialog-ui-fix | 修复 Issue #7: Import/Export/Delete Collection 对话框 UI/UX 规范 - 统一英文语言、规范字号和按钮样式 |

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

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
