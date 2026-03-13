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
| **当前状态** | ✅ **URL Focus 边框对齐修复完成** |
| **技术栈** | Flutter 3.27.x + Dart + Riverpod |
| **目标平台** | macOS 10.15+ / Windows 10+ / Linux |
| **测试覆盖** | 418+ 个测试 (Models 152 + Services 73 + Providers 92 + Widgets 88 + UI Test) |
| **下次重点** | 🟡 主题切换 / 🟢 请求历史 |

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
| UI 测试模式 | 2026-03-12 | 内置 HTTP 指令服务器，支持远程控制 |
| UI 自动化测试验证 | 2026-03-12 | HTTPS 请求 + Certificate Tab 切换测试 |
| 请求名称编辑 | 2026-03-12 | 右键菜单重命名 + UI 测试模式支持 |
| UI 自动化测试验证 | 2026-03-12 | HTTPS 请求 + Certificate Tab 切换测试 |
| 响应优化 | 2026-03-12 | 大响应体虚拟化显示优化 |
| UI 自动化测试验证 | 2026-03-12 | 响应优化功能测试脚本 |
| UI 细节优化 | 2026-03-13 | Tab 样式、+按钮、URL输入框、下拉菜单优化 |
| UI 对齐修复 | 2026-03-13 | URL行高度统一36px、Method下拉与URL输入框对齐、Certificate字体缩小 |
| URL Focus 边框对齐修复 | 2026-03-13 | 修复 URL 输入框 focus 状态紫色边框与灰色背景区域高度不一致问题 |

### 进行中 🔄

| 任务 | 说明 |
|------|------|
| 主题切换 | Light/Dark 模式完善 |

### 质量保障

| 类别 | 数量 | 状态 |
|------|------|------|
| Models 测试 | 152 | ✅ 通过 |
| Services 测试 | 73 | ✅ 通过 |
| Providers 测试 | 92 | ✅ 通过 |
| Widget 测试 | 88 | ✅ 通过 |
| 响应优化组件测试 | 新增 | ✅ 通过 |
| UI 优化测试 | 新增 7 个 | ✅ 通过 |
| **总计** | **418** | **全部通过** |

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

**优势**:
- ✅ 精确控制，直接操作 Flutter Provider 状态
- ✅ 稳定可靠，不受窗口位置/分辨率影响
- ✅ 速度快，无需等待动画
- ✅ 易于扩展，添加新指令简单

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
<summary>2026-03-13 - URL Focus 边框对齐修复完成</summary>

**修复内容**:
- ✅ 修复 URL 输入框 focus 状态下紫色边框与灰色背景区域高度不一致问题
- ✅ 让 TextField 完全控制所有边框状态（enabledBorder/focusedBorder）
- ✅ 移除外层 Container 的边框设置，避免边框叠加
- ✅ 调整 contentPadding 确保文字垂直居中

**技术方案**:

1. **问题原因**:
   - 外层 Container 设置了高度 36px 和背景色
   - 内层 TextField 的边框独立于 Container
   - 导致背景色区域和边框区域不一致

2. **解决方案**:
```dart
// TextField 完全控制背景和边框，使用 SizedBox 限制高度
Expanded(
  child: SizedBox(
    height: 36,
    child: TextField(
      decoration: InputDecoration(
        // TextField 控制背景色
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        // TextField 控制边框
        enabledBorder: OutlineInputBorder(...),  // 灰色边框
        focusedBorder: OutlineInputBorder(...),  // 紫色边框
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
        ),
      ),
    ),
  ),
)
```

3. **新增 UI 测试指令**:
- `focus_url_input` - 聚焦 URL 输入框（用于测试 focus 状态）

**验证结果**:

| 检查项 | 状态 | 说明 |
|--------|------|------|
| Focus 边框对齐 | ✅ | 紫色边框与灰色背景区域完全对齐 |
| 高度一致 | ✅ | URL 输入框与 Method 下拉框高度一致（36px） |
| 文字垂直居中 | ✅ | URL 文字在输入框内垂直居中 |
| 非 focus 状态边框 | ✅ | 灰色边框与 focus 状态边框位置一致 |

**截图验证**:
- `url_unfocused.png` - 非 focus 状态（灰色边框）
- `url_focus_state.png` - focus 状态（紫色边框对齐效果，高度 36px）

</details>

<details>
<summary>2026-03-13 - URL Bar 对齐修复完成</summary>

**修复内容**:
- ✅ URL Bar 高度统一：Method dropdown、URL 输入框、Save/Send 按钮统一为 36px
- ✅ 修复 URL 输入框高度不足问题（使用 Container 设置固定高度）
- ✅ 添加 Focus 效果（紫色边框）
- ✅ 文字垂直居中（调整 contentPadding）

**技术方案**:

1. **URL Bar 布局调整**:
```dart
// 使用 Container 设置固定高度和边框
Container(
  height: 36,
  decoration: BoxDecoration(
    color: theme.colorScheme.surfaceContainerHighest,
    border: Border(...),
  ),
  child: TextField(
    decoration: InputDecoration(
      filled: false,
      border: InputBorder.none,
      focusedBorder: OutlineInputBorder(...),
    ),
  ),
)
```

2. **文字垂直居中**:
```dart
contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
```

3. **新增 UI 测试命令**:
- `scroll_response` - 控制响应区域滚动
- `set_window_size` - 设置窗口大小
- `set_divider_position` - 设置分隔线位置

**验证结果**:

| 检查项 | 状态 | 说明 |
|--------|------|------|
| URL Bar 高度对齐 | ✅ | 36px 统一高度，上下边框对齐 |
| Focus 效果 | ✅ | 紫色边框显示正常 |
| 文字垂直居中 | ✅ | URL 文字在输入框内垂直居中 |

**截图验证**:
- `final_ui_test.png` - URL Bar 对齐效果

</details>

<details>
<summary>2026-03-13 - UI 对齐修复与验证</summary>

**修复内容**:
- ✅ URL 行高度对齐：Method 下拉框与 URL 输入框统一为 32px
- ✅ Method 下拉选项高度：从 48px 缩小到 36px，更紧凑
- ✅ Certificate 字体缩小：标签 10px，值 11px，标题 13px
- ✅ Sidebar Divider：从 8px 缩小到 1px，更精致

**关键修复**:

1. **URL Bar 高度统一**:
```dart
// 统一使用 32px 高度
const urlBarHeight = 32.0;

// Method 下拉框 - 左侧带圆角
Container(
  height: urlBarHeight,
  decoration: BoxDecoration(
    borderRadius: const BorderRadius.horizontal(
      left: Radius.circular(AppConstants.radiusM),
    ),
  ),
)

// URL 输入框 - 右侧 fused
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(AppConstants.radiusM),
      ),
    ),
  ),
)
```

2. **Method 下拉菜单优化**:
```dart
DropdownButton<HttpMethod>(
  itemHeight: 36, // 从 48 缩小到 36
  // 内边距和字体也相应缩小
)
```

3. **Certificate 字体优化**:
```dart
// 状态卡片标题
Text('Certificate is valid', style: TextStyle(fontSize: 13))

// 详情标签
SizedBox(
  width: 120,
  child: Text(label, style: TextStyle(fontSize: 10)),
)

// 详情值
SelectableText(value, style: TextStyle(fontSize: 11))
```

**验证结果** (截图确认):

| 检查项 | 状态 | 说明 |
|--------|------|------|
| URL 行高度 | ✅ | Method 下拉框与 URL 输入框 32px 对齐 |
| Method 下拉选项 | ✅ | 选项高度 36px，视觉上更紧凑 |
| Certificate 字体 | ✅ | 标签 10px、值 11px、标题 13px |
| Sidebar Divider | ✅ | 1px 细线，更精致 |

**截图验证**:
- `ui_test_url_bar.png` - URL 行对齐效果
- `ui_test_cert_top.png` - Certificate 概览
- `ui_test_cert_full.png` - Certificate Chain 详情

**新增 UI 测试命令**:
- `capture_url_bar` - 触发 URL 栏截图
- `expand_method_dropdown` - 展开 Method 下拉菜单（待完善）
- `capture_certificate` - 触发 Certificate 截图
- `switch_request_tab` - 切换 Request Tab

**经验教训**:
- 自动化测试通过 ≠ 视觉正确，必须通过截图人工确认
- Flutter DropdownButton 不支持程序化打开，需要特殊处理
- 高度对齐必须使用统一的尺寸常量，避免硬编码

</details>

<details>
<summary>2026-03-12 - 响应优化功能实现</summary>

**完成工作**:
- ✅ 创建 `OptimizedResponseViewer` 组件，支持大响应虚拟化显示
- ✅ 实现自动/性能/完整/原始四种显示模式
- ✅ 大响应自动切换性能模式（阈值 50KB）
- ✅ 虚拟化列表支持（初始显示 500 行，支持加载更多）
- ✅ 轻量级 JSON 语法高亮（性能模式下）
- ✅ 添加 UI 测试模式支持（3个新指令）
- ✅ 创建响应优化功能测试脚本
- ✅ 所有单元测试通过（418个）

**优化策略**:
| 响应大小 | 默认模式 | 说明 |
|---------|---------|------|
| < 10KB | Full | 完整语法高亮 |
| 10KB - 50KB | Full | 完整语法高亮 |
| > 50KB | Performance | 虚拟化列表，轻量高亮 |

**新增文件**:
- `lib/widgets/common/optimized_response_viewer.dart` - 优化响应显示组件
- `integration_test/test_response_optimization.py` - 自动化测试脚本

**修改文件**:
- `lib/widgets/request/response_viewer.dart` - 集成 OptimizedResponseViewer
- `lib/utils/testing/ui_test_mode.dart` - 添加测试指令
- `lib/providers/request/request_response_provider.dart` - 添加 setMockResponse
- `integration_test/test_client.py` - 添加客户端方法
- `test/widgets/response_viewer_test.dart` - 适配新组件

**测试指令**:
- `get_response_body_info` - 获取响应体信息（大小、行数等）
- `set_response_display_mode` - 设置显示模式（auto/performance/full/raw）
- `simulate_large_response` - 模拟大响应（用于性能测试）

**UI 测试结果** (2026-03-13):
```
总计: 8 个测试
通过: 8 个
失败: 0 个

✅ 测试 1: 基础连接
✅ 测试 2: 大响应模拟 (50.52 KB, 1008 lines)
✅ 测试 3: 获取响应体信息
✅ 测试 4: Tab 切换 (Body/Headers)
✅ 测试 5: 切换到 Performance 模式
✅ 测试 6: 切换到 Full 模式
✅ 测试 7: 切换到 Auto 模式
✅ 测试 8: 超大响应处理 (265.37 KB, 5008 lines)
```

**截图验证**: 
- 大响应正确显示：265.4 KB · 5008 lines
- 性能模式工具栏：Performance / Full 切换按钮（始终显示）
- JSON 语法高亮：key 蓝色、string 绿色、number 蓝色
- 虚拟化加载：Showing 500 of 5008 lines + Load 4508 more / Load all 按钮
- 响应信息栏：200 OK | 150 ms | 265.4 KB

</details>

<details>
<summary>2026-03-12 - 请求名称编辑功能 + UI 测试验证</summary>

**完成工作**:
- ✅ 实现请求名称编辑功能（Sidebar 右键菜单）
- ✅ 支持交互式编辑（TextField + Enter/Esc）
- ✅ 扩展 UI 测试模式（6个新指令）
- ✅ 实际运行 UI 自动化测试并全部通过

**修改文件**:
- `lib/widgets/layout/sidebar.dart` - 添加名称编辑 UI
- `lib/providers/collection/collection_provider.dart` - 添加删除请求方法
- `lib/utils/testing/ui_test_mode.dart` - 添加测试指令
- `integration_test/test_client.py` - 添加客户端方法
- `integration_test/test_rename_request.py` - 新增测试脚本
- `macos/Runner/Release.entitlements` - 添加 network.server 权限

**测试结果**:
```
总计: 4 个测试
通过: 4 个
失败: 0 个

✅ 测试 1: 直接重命名
✅ 测试 2: 交互式编辑
✅ 测试 3: 取消编辑
✅ 测试 4: 重命名已存在请求
```

</details>

<details>
<summary>2026-03-13 - UI 细节优化</summary>

**完成工作**:
- ✅ Request Tab 样式优化：高度 32px、选中状态增强、+按钮修复
- ✅ URL 输入框垂直居中对齐，统一边框样式（选中/未选中一致）
- ✅ URL 行整体高度优化：36px → 32px，按钮统一 32px
- ✅ Response Tab 优化：字体 10px、高度 28px、添加图标
- ✅ Request Editor Tabs 优化：高度 36px → 28px
- ✅ Content Type SegmentedButton 优化：高度 32px → 28px，更紧凑样式
- ✅ Method 下拉菜单间距优化
- ✅ Sidebar 弹出菜单样式统一
- ✅ 整体垂直空间优化：降低各组件高度，减少间距浪费
- ✅ 添加 UI 测试指令：`click_new_tab_button`、`get_ui_info`
- ✅ 创建 UI 优化测试脚本

**修改文件**:
- `lib/widgets/layout/request_tabs.dart` - Tab 样式和 +按钮功能
- `lib/widgets/request/request_editor.dart` - URL 输入框和 Method 下拉菜单
- `lib/widgets/request/response_viewer.dart` - Response Tab 样式
- `lib/widgets/layout/sidebar.dart` - 弹出菜单样式
- `lib/utils/testing/ui_test_mode.dart` - 添加测试指令
- `integration_test/test_client.py` - 添加客户端方法
- `integration_test/test_ui_optimization.py` - 新增测试脚本

**UI 测试结果**:
```
总计: 7 个测试
通过: 7 个
失败: 0 个

✅ 测试 1: 基础连接
✅ 测试 2: + 按钮创建新请求
✅ 测试 3: Request Tab 视觉样式
✅ 测试 4: Response Tab 样式
✅ 测试 5: URL 输入框对齐
✅ 测试 6: Method 下拉菜单
✅ 测试 7: UI 信息一致性

📸 截图验证:
- ui_test_new_tab_created.png
- ui_test_request_tabs_multiple.png
- ui_test_response_tabs_body.png
- ui_test_response_tabs_headers.png
- ui_test_url_input_alignment.png
- ui_test_method_dropdown.png
```

</details>

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

<details>
<summary>2026-03-12 - UI 测试模式实现 (Kimi 辅助测试)</summary>

**完成工作**:
- ✅ 实现 UI 测试模式 (`--test-mode` 启动参数)
- ✅ 内置 HTTP 指令服务器 (`UITestModeManager`)
- ✅ 创建 Python 测试客户端 (`test_client.py`)
- ✅ 实现 12 个测试指令 (create_request, send_request, switch_response_tab 等)
- ✅ 成功执行 HTTPS 请求 + Certificate Tab 切换测试
- ✅ 清理冗余测试方案 (Python+OpenCV, XCTest, Peekaboo 高级脚本)
- ✅ 更新测试文档

**技术方案**:
- 应用以 `--test-mode` 启动时，自动启动 HTTP 服务器
- 测试客户端通过 HTTP POST 发送指令
- 应用执行指令并操作 Flutter Provider 状态
- UI 自动响应状态变化

**核心文件**:
- `lib/utils/testing/ui_test_mode.dart` (新建)
- `integration_test/test_client.py` (新建)
- `lib/widgets/request/response_viewer.dart` (修改，支持 Tab 切换)
- `lib/main.dart` (修改，支持测试模式参数)

**使用方式**:
```bash
# 启动应用（测试模式）
./hopp.app/Contents/MacOS/hopp --test-mode

# 执行测试
python3 integration_test/test_client.py --port <PORT> full_test
```

**优势**:
- 精确控制，直接操作状态，不受坐标/分辨率影响
- 稳定可靠，速度快
- 易于扩展新指令

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
| 2026-03-12 | v0.3.0-ui-test-mode | UI 测试模式，支持 HTTP 指令控制 |
| 2026-03-12 | v0.3.1-rename-request | 请求名称编辑功能 + UI 测试验证 |
| 2026-03-12 | v0.3.2-response-optimization | 大响应体渲染优化 + UI 测试 |
| 2026-03-13 | v0.3.3-ui-polish | UI 细节优化：Tab样式、+按钮、输入框对齐、边框统一、高度优化 |
| 2026-03-13 | v0.3.5-ui-fix | URL Bar 对齐修复：Method下拉、URL输入框、Save/Send按钮统一36px高度 |
| 2026-03-13 | v0.3.6-url-focus-fix | 修复 URL 输入框 focus 状态下紫色边框与灰色背景区域高度不一致问题 |

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
