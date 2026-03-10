# Hopp 自动化测试方案

> 本文档定义 Flutter 项目的测试策略、工具配置和最佳实践。

---

## 📋 目录

- [测试策略](#测试策略)
- [单元测试](#单元测试)
- [Widget 测试](#widget-测试)
- [集成测试](#集成测试)
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

### 测试目标

| 层级 | 目标覆盖率 | 测试类型 |
|-----|-----------|---------|
| Models | 100% | 单元测试 |
| Services | 90%+ | 单元测试 + Mock |
| Providers | 80%+ | 单元测试 |
| Widgets | 70%+ | Widget 测试 |
| Integration | 60%+ | 集成测试 |

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

---

## 参考资源

- [Flutter Testing](https://docs.flutter.dev/testing)
- [Dart Test](https://pub.dev/packages/test)
- [Mockito](https://pub.dev/packages/mockito)
- [Riverpod Testing](https://riverpod.dev/docs/cookbooks/testing)
