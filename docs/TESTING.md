# Hopp 自动化测试方案

> 本文档定义 Flutter 项目的测试策略、工具配置和最佳实践。

---

## 📋 目录

- [测试策略](#测试策略)
- [单元测试](#单元测试)
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
| Models | 100% | ✅ 185 个通过 | 单元测试 |
| Services | 90%+ | ✅ 250 个通过 | 单元测试 + Mock |
| Providers | 80%+ | ✅ 114 个通过 | 单元测试 |
| Widgets | 70%+ | ✅ 135 个通过 / 2 跳过 | Widget 测试 |
| Utils | 80%+ | ✅ 41 个通过 | 单元测试 |
| 根目录（design_guard / app_version） | — | ✅ 2 个通过 | 静态扫描 + 守护 |
| Integration | 60%+ | ✅ Peekaboo + UI 测试模式 | 集成测试 |

### 总体统计

| 统计项 | 数值 |
|--------|------|
| 测试总数 | 729 |
| 通过 | 727 |
| 失败 | 0 |
| 跳过 | 2 |

> **注意**: 727 通过 / 2 跳过，无失败（2026-08-25 `fvm flutter test` 实测，M8.2 落地后）。

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

## Widget 测试

### 1. 基础 Widget 测试

```dart
// test/widgets/custom_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/widgets/common/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('should render with text', (tester) async {
      // Arrange
      const buttonText = 'Click Me';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: buttonText,
              onPressed: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(buttonText), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      // Arrange
      var wasPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Press',
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(wasPressed, true);
    });

    testWidgets('should show loading state', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Loading',
              isLoading: true,
              onPressed: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

### 2. 带 Riverpod 的 Widget 测试

```dart
// test/widgets/user_profile_test.dart
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
flutter test integration_test/app_test.dart -d macos

# Windows
flutter test integration_test/app_test.dart -d windows

# Linux
flutter test integration_test/app_test.dart -d linux
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

### 可用指令

| 指令 | 说明 |
|------|------|
| `create_request` | 创建新请求 |
| `set_url` | 设置 URL |
| `send_request` | 发送请求 |
| `switch_response_tab` | 切换响应 Tab (request/body/headers/cookies/timing/certificate) |
| `switch_request_tab` | 切换请求 Tab (params/headers/body/auth/settings) |
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
| `create_environment` | 创建环境（含变量定义，支持 secret/enabled） |
| `delete_environment` | 删除环境 |
| `get_environments` | 获取环境列表 |
| `set_active_environment` | 设置/取消激活环境（按 id 或 name） |
| `get_active_environment` | 获取当前激活环境 |
| `set_global_variables` | 设置全局变量 |
| `get_global_variables` | 获取全局变量 |
| `resolve_text` | 解析文本中的 {{variable}}（验证替换引擎与动态变量） |
| `get_resolved_request` | 获取活动请求应用变量替换后的结果 |
| `trigger_environment_dialog` | 打开环境管理对话框 |
| `open_design_gallery` | 打开 Design Gallery 页（全 token/组件双主题展示） |
| `full_test` | 完整测试流程 |

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

详细使用经验与坑位记录见 [PEEKABOO_CLI_LEARNING.md](./PEEKABOO_CLI_LEARNING.md)。

---

## 测试覆盖率

### 生成覆盖率报告

```bash
# 运行测试并收集覆盖率
flutter test --coverage

# 生成 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 打开报告
open coverage/html/index.html
```

### 覆盖率配置

```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: |
    flutter test --coverage
    
- name: Upload coverage
  uses: codecov/codecov-action@v3
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

### GitHub Actions 配置

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.27.x'
        channel: 'stable'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Generate code
      run: dart run build_runner build --delete-conflicting-outputs
    
    - name: Run analyzer
      run: flutter analyze
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: coverage/lcov.info
        fail_ci_if_error: true

  build-macos:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.27.x'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Build macOS
      run: flutter build macos --release

  build-windows:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.27.x'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Build Windows
      run: flutter build windows --release

  build-linux:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.27.x'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Build Linux
      run: flutter build linux --release
```

---

## 测试工具

### 1. Mock 生成

```bash
# 生成 Mock 类
dart run build_runner build --delete-conflicting-outputs
```

### 2. 黄金测试 (Golden Tests)

```dart
// test/goldens/home_screen_test.dart
testWidgets('HomeScreen golden test', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  
  await expectLater(
    find.byType(HomeScreen),
    matchesGoldenFile('goldens/home_screen.png'),
  );
});
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
