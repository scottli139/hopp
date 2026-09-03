# Hopp 自动化测试方案

> 本文档定义 Flutter 项目的测试策略、工具配置和最佳实践。

---

## 📋 目录

- [测试策略](#测试策略)
- [单元测试](#单元测试)
- [CLI 测试](#cli-测试)
- [Widget 测试](#widget-测试)
- [集成测试](#集成测试)
- [UI 测试模式](#ui-测试模式)
- [测试覆盖率](#测试覆盖率)
- [CI/CD 集成](#cicd-集成)
- [测试工具](#测试工具)

---

## 测试策略

### 测试金字塔

```
    /\
   /  \  E2E 测试 (5%)
  /----\ 
 /      \ 集成测试 (15%)
/--------\
          单元测试 (80%)
```

### 测试目标与当前状态

| 层级 | 目标覆盖率 | 当前状态 | 测试类型 |
|-----|-----------|---------|---------|
| Models | 100% | ✅ 196 个通过 | 单元测试 |
| Services | 90%+ | ✅ 357 个通过 | 单元测试 + Mock |
| Providers | 80%+ | ✅ 114 个通过 | 单元测试 |
| Widgets | 70%+ | ✅ 165 个通过 / 2 跳过 | Widget 测试 |
| Utils | 80%+ | ✅ 41 个通过 | 单元测试 |
| CLI | — | ✅ 18 个通过 | 单元测试 + HttpServer 集成 |
| 根目录（design_guard / app_version） | — | ✅ 2 个通过 | 静态扫描 + 守护 |
| Integration | 60%+ | ✅ Peekaboo + UI 测试模式 | 集成测试 |

### 总体统计

| 统计项 | 数值 |
|--------|------|
| 测试总数 | 893 |
| 通过 | 891 |
| 失败 | 0 |
| 跳过 | 2 |

> **注意**: 891 通过 / 2 跳过，无失败（2026-08-31 `fvm flutter test` 实测，M8.4 落地后）。跳过项在 `test/widgets/sidebar_test.dart`（2 个）。

---

## 单元测试

### 1. 模型测试

```dart
// test/models/http_request_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/key_value_pair.dart';

void main() {
  group('HttpRequest', () {
    test('should create HttpRequest with default values', () {
      final request = HttpRequest.empty();
      
      expect(request.method, HttpMethod.get);
      expect(request.url, 'https://api.example.com');
      expect(request.params, isEmpty);
      expect(request.headers, isEmpty);
      expect(request.body, '');
    });

    test('should copy with new values', () {
      final request = HttpRequest.empty();
      final updated = request.copyWith(
        method: HttpMethod.post,
        url: 'https://api.new.com',
        body: '{"key": "value"}',
      );
      
      expect(updated.method, HttpMethod.post);
      expect(updated.url, 'https://api.new.com');
      expect(updated.body, '{"key": "value"}');
    });

    test('should serialize to JSON', () {
      final request = HttpRequest.empty().copyWith(
        id: 'test-id',
        name: 'Test Request',
      );
      
      final json = request.toJson();
      expect(json['id'], 'test-id');
      expect(json['name'], 'Test Request');
    });
  });
}
```

### 2. Service 测试

```dart
// test/services/http_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:hopp/services/http_service.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/http_method.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
import 'http_service_test.mocks.dart';

void main() {
  late HttpService httpService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    httpService = HttpService(dio: mockDio);
  });

  group('HttpService', () {
    test('should send GET request successfully', () async {
      // Arrange
      final request = HttpRequest.empty().copyWith(
        method: HttpMethod.get,
        url: 'https://api.example.com/users',
      );

      when(mockDio.request<any>(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onSendProgress: anyNamed('onSendProgress'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((_) async => Response(
        data: Uint8List.fromList(utf8.encode('{"id": 1}')),
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      // Act
      final response = await httpService.sendRequest(request);

      // Assert
      expect(response.statusCode, 200);
      expect(response.error, isNull);
    });

    test('should handle network error', () async {
      // Arrange
      final request = HttpRequest.empty();

      when(mockDio.request<any>(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onSendProgress: anyNamed('onSendProgress'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      // Act
      final response = await httpService.sendRequest(request);

      // Assert
      expect(response.error, contains('timeout'));
      expect(response.statusCode, isNull);
    });
  });
}
```

### 3. Provider 测试

```dart
// test/providers/request_tab_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/providers/request/request_tab_provider.dart';
import 'package:hopp/models/http_request.dart';

void main() {
  group('RequestTabNotifier', () {
    late RequestTabNotifier notifier;

    setUp(() {
      notifier = RequestTabNotifier();
    });

    test('should add new tab', () {
      // Arrange
      final request = HttpRequest.empty();

      // Act
      notifier.openTab(request);

      // Assert
      expect(notifier.tabCount, 1);
      expect(notifier.getTab(request.id)?.request.id, request.id);
    });

    test('should close tab', () {
      // Arrange
      final request = HttpRequest.empty();
      notifier.openTab(request);

      // Act
      notifier.closeTab(request.id);

      // Assert
      expect(notifier.tabCount, 0);
    });

    test('should mark tab as dirty when updating request', () {
      // Arrange
      final request = HttpRequest.empty();
      notifier.openTab(request);
      final updatedRequest = request.copyWith(url: 'https://new.com');

      // Act
      notifier.updateRequest(request.id, updatedRequest);

      // Assert
      expect(notifier.getTab(request.id)?.isDirty, true);
    });
  });
}
```

---

## CLI 测试

`cli/` 运行器（M8.4 / v0.12.0）测试位于 `test/cli/hopp_cli_test.dart`（18 个：参数解析 / env 合并 / reporter / HttpServer 集成）：

```bash
# 直接以 Dart 运行
fvm dart run cli/hopp.dart run <file.hopp.json> \
  [--env 名称|外部env文件路径] [--env-var K=V]… \
  [--reporter console|json|junit] [--output path] [--timeout ms]

# 编译单文件二进制（发布形态）
fvm dart compile exe cli/hopp.dart -o hopp
```

- exit code：0 = 全部通过，1 = 有断言失败，2 = 用法/文件错误
- 集成用例：dart:io HttpServer 起本地服务，跑 login 预请求链（密码 sha1 管道）提取 `{{token}}` 再断言——与 GUI 共用同一套求值引擎代码路径
- 密钥纪律：报告输出只含断言 expected/actual/message 与变量名，不落变量值/响应体

---

## Widget 测试

### 1. 基础 Widget 测试

```dart
// test/widgets/common/app_segmented_control_test.dart（节选自真实测试）
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/theme/app_theme.dart';
import 'package:hopp/theme/app_theme_data.dart';
import 'package:hopp/widgets/common/app_segmented_control.dart';

void main() {
  const items = [
    AppSegmentedItem(value: 'system', icon: Icons.brightness_auto_outlined, tooltip: 'System'),
    AppSegmentedItem(value: 'light', icon: Icons.light_mode_outlined, tooltip: 'Light'),
    AppSegmentedItem(value: 'dark', icon: Icons.dark_mode_outlined, tooltip: 'Dark'),
  ];

  Widget wrap(Widget child, {bool dark = false}) {
    return MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('AppSegmentedControl rendering', () {
    testWidgets('renders all items at spec size', (tester) async {
      await tester.pumpWidget(wrap(AppSegmentedControl<String>(
        items: items,
        value: 'system',
        onChanged: (_) {},
      )));

      expect(find.byType(AppSegmentedControl<String>), findsOneWidget);
      // 断言规格：容器高 24、选中段 surface 底等（详见真实测试）
    });

    testWidgets('calls onChanged when segment tapped', (tester) async {
      String? selected;
      await tester.pumpWidget(wrap(AppSegmentedControl<String>(
        items: items,
        value: 'system',
        onChanged: (v) => selected = v,
      )));

      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pump();

      expect(selected, 'dark');
    });
  });
}
```
> 更多真实组件测试：`test/widgets/common/`（app_text_field_test / app_divider_test / app_segmented_control_test / app_components_golden_test）。

### 2. 带 Riverpod 的 Widget 测试

> 以下为示意代码（UserProfile 为虚构示例，项目无此文件）；真实 Riverpod widget 测试见 `test/widgets/`（如断言编辑器 / Tests 页签 / 环境对话框，M8.4）。

```dart
// 示意：test/widgets/user_profile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:hopp/widgets/user_profile.dart';
import 'package:hopp/providers/user_provider.dart';
import 'package:hopp/models/user.dart';

class MockUserNotifier extends Mock implements UserNotifier {}

void main() {
  group('UserProfile', () {
    testWidgets('should show loading state', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => 
              AsyncValue<User>.loading()),
          ],
          child: const MaterialApp(
            home: UserProfile(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show user data', (tester) async {
      // Arrange
      final user = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => 
              AsyncValue<User>.data(user)),
          ],
          child: const MaterialApp(
            home: UserProfile(),
          ),
        ),
      );

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('should show error state', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => 
              AsyncValue<User>.error('Failed to load', StackTrace.empty)),
          ],
          child: const MaterialApp(
            home: UserProfile(),
          ),
        ),
      );

      // Assert
      expect(find.text('Failed to load'), findsOneWidget);
    });
  });
}
```

---

## 集成测试

### 1. 配置集成测试

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### 2. 编写集成测试

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hopp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Test', () {
    testWidgets('should create and send a request', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Create new collection
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter collection name
      await tester.enterText(
        find.byType(TextField).first,
        'Test Collection',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Create new request
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Request'));
      await tester.pumpAndSettle();

      // Enter URL
      await tester.enterText(
        find.byType(TextField).last,
        'https://api.example.com/users',
      );

      // Send request
      await tester.tap(find.text('Send'));
      await tester.pump(const Duration(seconds: 2));

      // Verify response is shown
      expect(find.text('Response'), findsOneWidget);
    });

    testWidgets('should switch between tabs', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Create multiple requests...
      // Switch between tabs...
    });
  });
}
```

### 3. 运行集成测试

```bash
# macOS
fvm flutter test integration_test/app_test.dart -d macos

# Windows
fvm flutter test integration_test/app_test.dart -d windows

# Linux
fvm flutter test integration_test/app_test.dart -d linux
```

---

## UI 测试模式

Hopp 实现了内置的 UI 测试模式，支持通过 HTTP 指令远程控制应用，用于自动化 UI 测试。

### 架构

```
测试客户端 (Python) → HTTP POST → UI Test Server → MethodChannel → Flutter Provider
```

### 使用方式

```bash
# 1. 以测试模式启动应用
./hopp.app/Contents/MacOS/hopp --test-mode

# 2. 从日志获取端口
grep "测试服务器启动在端口" ~/Library/Containers/.../hopp_*.log

# 3. 执行测试
python3 integration_test/test_client.py --port <PORT> full_test
```

> **数据隔离（2026-08-28 起）**：`--test-mode/--ui-test` 启动的实例使用独立数据目录 `~/Library/Containers/com.example.hopp/Data/Documents/hopp_test`（含独立加密 key），与用户真实数据 `Documents/hopp` 完全隔离——Hive 非跨进程安全，并发打开同一目录曾导致数据清零。因此 test-mode 实例看不到用户的集合/环境，自动化需用 `create_collection`/`create_saved_request`/`import_openapi` 等指令自建 fixture。日志目录不变（实例仍可能并发写同日日志，无破坏性）。

### 可用指令

| 指令 | 说明 |
|------|------|
| `create_request` | 创建新请求 |
| `set_url` | 设置 URL |
| `send_request` | 发送请求 |
| `switch_response_tab` | 切换响应 Tab (body/headers/cookies/request/tests，有响应时追加 timing/certificate) |
| `switch_request_tab` | 切换请求 Tab (params/headers/body/auth/prerequest/assertions/settings) |
| `get_response_info` | 获取响应信息 |
| `rename_request` | 重命名请求 |
| `set_body_type` | 设置 Body 类型 (none/raw/form-data/x-www-form-urlencoded/binary/graphql) |
| `set_raw_content_type` | 设置 Raw 子类型 (text/javascript/json/html/xml) |
| `get_timing_info` | 获取时间分析 |
| `get_request_details` | 获取请求详情 |
| `get_certificate_info` | 获取证书信息 |
| `simulate_4xx_response` | 模拟 4XX 错误响应 |
| `simulate_5xx_response` | 模拟 5XX 错误响应 |
| `simulate_large_response` | 模拟大响应 |
| `beautify_code` | 格式化代码 |
| `dismiss_dialog` | 关闭顶层对话框（Navigator.maybePop） |
| `set_theme_mode` | 切换主题模式 (light/dark/system) |
| `set_ui_scale` | 设置界面文字缩放（`scale`: 1.0/1.25/1.5，F5.7；持久化生效，HiDPI 紧凑布局验收用） |
| `close_storage` | 干净关闭所有 Hive box（复制 box 文件前必须调用；SIGTERM 直杀会损坏尾部帧导致 Hive 恢复清空，2026-09-02 事故） |
| `create_environment` | 创建环境（含变量定义，支持 secret/enabled） |
| `delete_environment` | 删除环境 |
| `get_environments` | 获取环境列表 |
| `set_active_environment` | 设置/取消激活环境（按 id 或 name） |
| `get_active_environment` | 获取当前激活环境 |
| `set_global_variables` | 设置全局变量 |
| `get_global_variables` | 获取全局变量 |
| `resolve_text` | 解析文本中的 {{variable}}（验证替换引擎与动态变量） |
| `get_resolved_request` | 获取活动请求应用变量替换后的结果 |
| `create_saved_request` | 创建已保存请求直接入指定 Collection（供预请求链引用，F8.2 测试钩子） |
| `set_pre_request_chain` | 设置请求的预请求链（步骤+提取规则+401 重跑，Tab/已保存请求均可，F8.2 测试钩子） |
| `set_assertions` | 设置请求断言规则（request_id/name 定位 + 规则数组，Tab 与已保存请求双写，F4.1 测试钩子） |
| `scroll_response` | 滚动响应区（`target`: body/certificate，回读滚动结果；已知问题 #4 的自动化验证依赖） |
| `tap_at` / `scroll_at` | 指针注入点击 / 滚动（坐标命中分发，绕过 widget test 局限） |
| `set_window_size` | 真实调整窗口尺寸（macOS 原生通道） |
| `trigger_import_dialog` | 打开导入对话框（可选 `tab`: `postman`/`curl`/`openapi`，缺省 Postman 页签） |
| `trigger_curl_import_dialog` | 已合并为 Import 对话框 cURL 页签；指令保留并重定向为 `trigger_import_dialog(tab=curl)` |
| `import_openapi` | OpenAPI/Swagger 导入全流程（解析→勾选→导入→冲突解决，F9 测试钩子，参数见下文） |
| `trigger_environment_dialog` | 打开环境管理对话框 |
| `open_design_gallery` | 打开 Design Gallery 页（全 token/组件双主题展示） |
| `set_ai_mock` | 设置 AI canned 响应（`response`: String，mock 接缝，F9.5） |
| `clear_ai_mock` | 清除 AI canned 响应 |
| `ai_explain` | AI 解释当前 tab 响应（需先 `send_request` / `simulate_*`，返回 `status`/`result`/`error`） |
| `ai_generate_assertions` | AI 基于当前 tab 响应生成断言草稿（返回 `status`/`assertions`/`discarded`/`error`） |
| `ai_build_request` | AI 自然语言建请求（`description`: String 必填，返回 `status`/`draft`/`error`） |
| `full_test` | 完整测试流程 |

> 本表为常用指令清单；完整指令（97 条，随版本增长）以 `lib/utils/testing/ui_test_mode.dart` 指令分发为准。

#### AI 指令（F9.5）与 mock 接缝

本机无 Ollama / LM Studio 时，AI 全链路自动化走 canned mock：`set_ai_mock` 设置固定响应串后，`llmClientProvider` 返回 `CannedLlmClient`（任何 `chat()` 立即返回该串，不发网络请求）；`clear_ai_mock` 恢复真实客户端。`ai_explain` / `ai_generate_assertions` / `ai_build_request` 内部会自动确保 AI 配置就绪（未启用置 `aiEnabled=true`、模型名为空置 `test-model`），业务失败不抛异常，`errorMessage` 放在返回 Map 的 `error` 键供脚本断言。

| 指令 | 参数 | 返回（`status` 恒为 `idle`/`loading`/`success`/`error`） |
|------|------|------|
| `set_ai_mock` | `response`: String | `{'mocked': true}` |
| `clear_ai_mock` | — | `{'mocked': false}` |
| `ai_explain` | —（取当前 tab 响应） | `{'status', 'result', 'error'}` |
| `ai_generate_assertions` | —（取当前 tab 响应） | `{'status', 'assertions': [{'target','targetArg','operator','expected'}], 'discarded', 'error'}` |
| `ai_build_request` | `description`: String（必填） | `{'status', 'draft': {'name','method','url','params','headers','bodyType','rawContentType','body'}, 'error'}` |

#### `import_openapi` 参数与返回

| 参数 | 类型 | 说明 |
|------|------|------|
| `content` | String | 内联 spec 文本（与 `path` / `url` 三选一） |
| `path` | String | 相对 CWD 的 spec 文件路径 |
| `url` | String | 远程 spec URL |
| `header_name` / `header_value` | String? | 自定义请求头（仅 `url` 来源） |
| `select` | String / Array | `"all"`（默认，保持解析后全选）/ `"none"` / op id 数组（op id 格式 `"get /pets"`） |
| `stop_at` | String | `"preview"` 止于解析预览 / `"complete"`（默认）执行导入 |
| `on_conflict` | String? | `rename` / `overwrite` / `merge` / `skip`；冲突且未给时返回冲突信息不解决 |

返回结构：

- 成功：`{stage, title, specVersion, serverUrl, opCount, tags, selectedCount, report?, conflict?}`；`report` 含 collectionId / collectionName / requestCount / collectionCount / renamed / newName / merged / placeholders（每项 kind/method/path/detail）/ oauthNotices / baseUrl / baseUrlExisted / authDescription；`skip` 解决后 `stage` 为 `idle`
- 解析 / 导入失败：`{success: false, result: {stage: 'error', error}}`（HTTP 200，业务失败透传）

示例：

```bash
# 预览 petstore fixture（不导入）
curl -X POST http://localhost:<PORT>/ \
  -d '{"action":"import_openapi","params":{"path":"test/fixtures/openapi/petstore3.json","stop_at":"preview"}}'

# 只导入指定 op，同名冲突时重命名
curl -X POST http://localhost:<PORT>/ \
  -d '{"action":"import_openapi","params":{"path":"test/fixtures/openapi/petstore3.json","select":["get /pet/findByStatus"],"on_conflict":"rename"}}'

# 打开导入对话框并定位到 OpenAPI 页签
curl -X POST http://localhost:<PORT>/ \
  -d '{"action":"trigger_import_dialog","params":{"tab":"openapi"}}'
```

### UI 测试脚本列表

| 脚本 | 用途 |
|------|------|
| `test_client.py` | Python 测试客户端 |
| `test_body_type_selector.py` | Body 类型选择器测试 |
| `test_certificate.py` | Certificate Tab 测试 |
| `test_code_editor_improved.py` | Code Editor 样式测试 |
| `test_dropdown_style.py` | Dropdown 样式测试 |
| `test_error_response.py` | 4XX/5XX 响应测试 |
| `test_font_update.py` | 字体更新测试 |
| `test_postman_import.py` | Postman 导入测试 |
| `test_rename_request.py` | 请求重命名测试 |
| `test_request_details.py` | 请求详情展示测试 |
| `test_request_editor_ui.py` | Request Editor UI 测试 |
| `test_request_info.py` | 请求信息测试 |
| `test_request_settings_ui.py` | Request Settings UI 测试 |
| `test_response_optimization.py` | 响应优化测试 |
| `test_save_and_rename.py` | 保存和重命名测试 |
| `test_timing_analysis.py` | Timing 分析测试 |
| `test_ui_optimization.py` | UI 优化测试 |
| `test_border_issue.py` | 边框问题回归测试 |
| `test_collection_cascade_delete.py` | Collection 级联删除测试 |
| `test_curl_import.py` | cURL 导入测试 |
| `test_database_migration.py` | 数据库迁移测试 |
| `test_dialog_ui_fix.py` | 对话框 UI 修复测试 |
| `test_issue_6_empty_state.py` | 空状态入口指引测试 |
| `test_raw_content_type_fix.py` | Raw Content Type 修复测试 |
| `test_rename_request_with_screenshot.py` | 请求重命名（含截图）测试 |
| `test_response_body_compare.py` | 响应体对比测试 |
| `test_save_button.py` | 保存按钮测试 |
| `test_save_edge_cases.py` | 保存边界场景测试 |
| `test_url_input_focus.py` | URL 输入框焦点测试 |
| `test_url_params_sync.py` | URL 参数同步测试 |
| `test_environment_variables.py` | 环境变量系统（M8.1）验收测试 |

---

## Peekaboo E2E 测试

基于 macOS 无障碍 API 的系统级 E2E 测试套件，位于 `integration_test/peekaboo/`：

```bash
cd integration_test/peekaboo
make test   # 完整测试
make quick  # 快速测试
make logs   # 查看日志
```

详细使用经验与坑位记录见 [PEEKABOO_CLI_LEARNING.md](./PEEKABOO_CLI_LEARNING.md)（Flutter 应用分工：peekaboo 管系统级「看」，应用内 UI 驱动走 test-mode 指令服务器，见该文 6.4）。

---

## 测试覆盖率

### 生成覆盖率报告

```bash
# 运行测试并收集覆盖率
fvm flutter test --coverage

# 生成 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 打开报告
open coverage/html/index.html
```

### 覆盖率配置

实际 CI 中的覆盖率上传见 `.github/workflows/ci.yml`（codecov/codecov-action@v4）。以下为配置示意：

```yaml
# .github/workflows/<your-workflow>.yml（示意）
- name: Run tests with coverage
  run: |
    fvm flutter test --coverage
    
- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    files: coverage/lcov.info
```

### 忽略文件

```yaml
# analysis_options.yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.mocks.dart"
    - "test/**"
```

---

## CI/CD 集成

实际工作流见 `.github/workflows/`（以下为现状摘要，以 workflow 文件为准）：

| 文件 | 触发 | 内容 |
|------|------|------|
| `ci.yml` | push main / pull_request | `dart format --set-exit-if-changed` → pub get → build_runner 生成文件存在性检查 → `flutter analyze --no-fatal-infos` → `flutter test` + codecov@v4 上传 → 三平台 release 构建（macOS / windows-2022 / linux） |
| `pr-check.yml` | pull_request | 轻量检查（analyze `--no-fatal-infos`，与 ci.yml 一致） |
| 发布 workflow | push `v*` tag | 三平台打包 + `softprops/action-gh-release` 自动上传 zip 附件；macOS 签名 dmg 由维护者本地构建后手动上传 release（见 [GITHUB_SETTINGS](./GITHUB_SETTINGS.md)） |

关键点：

- Flutter 版本经 env `FLUTTER_VERSION: "3.35.4"` 统一锁定（与 `.fvmrc` 同版本）；Windows 固定 `windows-2022`（windows-latest 已升 VS2026，Flutter 3.35 尚不支持）
- analyze 用 `--no-fatal-infos`：info 级存量为基线（3.35.4 下约 1500+），0 error / 0 warning 即过，新增 warning 会挂
- 本地提交前跑 `fvm dart format lib test cli`（pre-push 钩子同样做 format 检查）

---

## 测试工具

### 1. Mock 生成

```bash
# 生成 Mock 类
fvm dart run build_runner build --delete-conflicting-outputs
```

### 2. 黄金测试 (Golden Tests)

组件 golden 基线位于 `test/widgets/common/app_components_golden_test.dart`（12 组双主题 PNG，存于 `test/widgets/common/goldens/`）：

```dart
// test/widgets/common/app_components_golden_test.dart（节选：按组件用例表循环生成双主题基线）
await tester.pumpWidget(wrap(caseWidget, dark: dark));
await expectLater(
  find.byType(caseType),
  matchesGoldenFile('goldens/${name}_${dark ? 'dark' : 'light'}.png'),
);
```

更新基线（更新后必须人工目检 PNG，见 AGENTS.md 设计守门条款）：

```bash
fvm flutter test test/widgets/common/ --update-goldens
```

### 3. 性能测试

```dart
testWidgets('Scrolling performance', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  final list = find.byType(ListView);
  
  await tester.fling(list, const Offset(0, -300), 1000);
  await tester.pumpAndSettle();
  
  // 检查帧率
  expect(tester.binding.hasScheduledFrame, isFalse);
});
```

---

## 最佳实践

### 1. 测试命名规范

```dart
// ✅ Good
group('UserService', () {
  test('should return user when found', () {});
  test('should throw exception when user not found', () {});
  test('should cache user after first fetch', () {});
});

// ❌ Bad
group('UserService', () {
  test('test1', () {});
  test('test2', () {});
});
```

### 2. AAA 模式

```dart
test('should calculate total', () {
  // Arrange
  final calculator = Calculator();
  
  // Act
  final result = calculator.add(2, 3);
  
  // Assert
  expect(result, 5);
});
```

### 3. 测试独立性

```dart
// ✅ Good
group('Counter', () {
  late Counter counter;
  
  setUp(() {
    counter = Counter();
  });
  
  test('increment', () {
    counter.increment();
    expect(counter.value, 1);
  });
  
  test('decrement', () {
    counter.decrement();
    expect(counter.value, -1);
  });
});
```

### 4. 测试环境日志降噪

`lib/utils/app_logger.dart` 的 `_AllLogFilter` 在 `flutter test` 环境（进程环境变量 `FLUTTER_TEST=true`）下只输出 warning 及以上级别，避免 trace/debug/info 刷屏。

> 注意：编译期 `bool.fromEnvironment('FLUTTER_TEST')` 在 Flutter 3.27.4 下为 false，必须用 `Platform.environment` 检测。

---

## 参考资源

- [Flutter Testing](https://docs.flutter.dev/testing)
- [Dart Test](https://pub.dev/packages/test)
- [Mockito](https://pub.dev/packages/mockito)
- [Riverpod Testing](https://riverpod.dev/docs/cookbooks/testing)
