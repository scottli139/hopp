# Hopp 代码规范与风格指南

> 本文档定义 Flutter/Dart 项目的代码规范，确保代码一致性、可维护性和高质量。

---

## 📋 目录

- [Dart 代码规范](#dart-代码规范)
- [Flutter 代码规范](#flutter-代码规范)
- [项目结构规范](#项目结构规范)
- [命名规范](#命名规范)
- [日志规范](#日志规范)
- [状态管理规范](#状态管理规范)
- [UI/UX 规范](#uiux-规范)
- [文档规范](#文档规范)
- [Git 提交规范](#git-提交规范)

---

## Dart 代码规范

### 1. 基础规范

遵循 [Effective Dart](https://dart.dev/effective-dart) 官方指南：

- **DO** 使用 `dart format` 格式化代码
- **DO** 使用 `dart analyze` 静态分析
- **AVOID** 使用 `dynamic` 类型
- **PREFER** 使用 `final` 而非 `var`
- **PREFER** 使用 `const` 构造函数

### 2. 代码风格

```dart
// ✅ Good
class UserRepository {
  final HttpClient _client;
  
  const UserRepository(this._client);
  
  Future<User> getUser(String id) async {
    final response = await _client.get('/users/$id');
    return User.fromJson(response.data);
  }
}

// ❌ Bad
class user_repository {
  var client;
  
  user_repository(c) {
    client = c;
  }
  
  getUser(id) async {
    var res = await client.get('/users/' + id);
    return User.fromJson(res.data);
  }
}
```

### 3. 导入排序

```dart
// 1. Dart SDK 导入
import 'dart:async';
import 'dart:convert';

// 2. Flutter 包导入
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. 第三方包导入
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// 4. 项目内导入
import '../models/user.dart';
import '../services/api_service.dart';
```

### 4. 空安全规范

```dart
// ✅ Good
String? nullableString;
late String initializedLater;
final String nonNullable = 'value';

// 使用 ?? 提供默认值
final name = user.name ?? 'Anonymous';

// 使用 ?. 进行安全调用
final length = nullableString?.length;

// ❌ Bad
String couldBeNull = null; // 编译错误
```

---

## Flutter 代码规范

### 1. Widget 规范

```dart
// ✅ Good - 使用 const 构造函数
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Hello');
  }
}

// ✅ Good - 状态类使用下划线前缀
class MyStatefulWidget extends ConsumerStatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  ConsumerState<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends ConsumerState<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

### 2. Build 方法规范

```dart
// ✅ Good - 保持 build 方法简洁
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
    bottomNavigationBar: _buildBottomBar(),
  );
}

Widget _buildAppBar() {
  return AppBar(
    title: const Text('Title'),
  );
}

// ❌ Bad - build 方法过于臃肿
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Title'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            // 大量逻辑代码...
          },
        ),
        // 更多代码...
      ],
    ),
    // 更多代码...
  );
}
```

### 3. 状态管理规范

```dart
// ✅ Good - 使用 Riverpod
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User>>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<AsyncValue<User>> {
  UserNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadUser();
  }

  final Ref _ref;

  Future<void> loadUser() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(userServiceProvider);
      final user = await service.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

// ✅ Good - 使用 ConsumerWidget
class UserProfile extends ConsumerWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) => _buildUserView(user),
      loading: () => const CircularProgressIndicator(),
      error: (err, _) => ErrorWidget(err),
    );
  }
}
```

---

## 项目结构规范

### 目录结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用配置
├── models/                      # 数据模型
│   ├── user.dart
│   ├── user.freezed.dart        # 生成的代码
│   └── user.g.dart              # 生成的代码
├── providers/                   # Riverpod Providers
│   ├── core/                    # 核心服务 Provider
│   ├── user/                    # 功能模块 Provider
│   └── providers.dart           # 导出文件
├── services/                    # 业务服务
│   ├── api_service.dart
│   └── storage_service.dart
├── widgets/                     # UI 组件
│   ├── common/                  # 通用组件
│   ├── layout/                  # 布局组件
│   └── features/                # 功能组件
├── screens/                     # 页面
│   ├── home_screen.dart
│   └── settings_screen.dart
├── utils/                       # 工具类
│   ├── extensions/              # 扩展方法
│   ├── constants.dart           # 常量
│   └── logger.dart              # 日志
└── l10n/                        # 国际化
    ├── app_en.arb
    └── app_zh.arb
```

### 文件命名

| 类型 | 命名规范 | 示例 |
|-----|---------|------|
| Dart 文件 | snake_case.dart | `user_profile.dart` |
| 模型文件 | snake_case.dart | `http_request.dart` |
| Widget 文件 | snake_case.dart | `custom_button.dart` |
| Provider 文件 | snake_case.dart | `user_provider.dart` |
| 测试文件 | snake_case_test.dart | `user_service_test.dart` |

---

## 命名规范

### 类命名

```dart
// ✅ Good - PascalCase
class HttpRequest { }
class UserRepository { }
class CustomButton extends StatelessWidget { }

// 抽象类
abstract class ApiClient { }

// Mixin
mixin Loggable { }

// 扩展
extension StringExtension on String { }
```

### 变量和函数命名

```dart
// ✅ Good - camelCase
final userName = 'John';
final isLoading = false;
final httpClient = Dio();

Future<User> fetchUser(String id) async { }
void handleSubmit() { }
bool get isValid => true;

// ❌ Bad
final user_name = 'John';
final IsLoading = false;
final HTTPClient = Dio();

Future<User> FetchUser(String ID) async { }
```

### 常量命名

```dart
// ✅ Good - camelCase for constants
const defaultTimeout = Duration(seconds: 30);
const maxRetryCount = 3;
const apiBaseUrl = 'https://api.example.com';

// 枚举
enum HttpMethod {
  get,
  post,
  put,
  delete,
}

// ❌ Bad - 不要使用 SCREAMING_SNAKE_CASE
const DEFAULT_TIMEOUT = Duration(seconds: 30);
```

---

## 日志规范

### 1. 基本原则

**所有代码必须包含适当的日志记录**，以便快速定位和分析问题。日志是生产环境调试的重要手段。

### 2. 日志级别规范

| 级别 | 使用场景 | 示例 |
|-----|---------|------|
| `trace` | 最详细的跟踪信息，进入/退出函数 | 进入某个处理方法 |
| `debug` | 调试信息，开发环境使用 | 变量值、状态变化 |
| `info` | 关键业务流程记录 | 用户操作、请求开始/完成 |
| `warning` | 警告，非致命问题 | 网络重试、缓存失效 |
| `error` | 错误，业务逻辑失败 | 请求失败、保存失败 |
| `fatal` | 致命错误，应用无法继续 | 初始化失败、数据库崩溃 |

### 3. 必须记录日志的场景

```dart
// ✅ 服务初始化
Future<void> initialize() async {
  AppLogger.info('[StorageService] Initializing...');
  // ... 初始化逻辑
  AppLogger.info('[StorageService] Initialized successfully');
}

// ✅ 数据持久化操作
Future<void> saveCollection(Collection collection) async {
  AppLogger.debug('[StorageService] Saving collection: ${collection.id}');
  await _box?.put(collection.id, collection);
  AppLogger.debug('[StorageService] Collection saved: ${collection.id}');
}

// ✅ 用户操作
void openTab(HttpRequest request) {
  AppLogger.info('[RequestTabNotifier] Opening new tab: ${request.name}');
  // ... 逻辑
}

// ✅ 网络请求
Future<HttpResponse> sendRequest(HttpRequest request) async {
  AppLogger.info('[HttpService] Sending ${request.method.value} to ${request.url}');
  try {
    final response = await _dio.request(...);
    AppLogger.info('[HttpService] Request completed: ${response.statusCode}');
    return response;
  } catch (e, stack) {
    AppLogger.error('[HttpService] Request failed', e, stack);
    rethrow;
  }
}

// ✅ 状态变化
Future<void> loadCollections() async {
  AppLogger.debug('[CollectionNotifier] Loading collections...');
  try {
    final collections = await storage.getCollections();
    AppLogger.info('[CollectionNotifier] Loaded ${collections.length} collections');
  } catch (e, stack) {
    AppLogger.error('[CollectionNotifier] Failed to load collections', e, stack);
  }
}
```

### 4. 日志格式规范

```dart
// ✅ Good - 带类名前缀，清晰标识来源
AppLogger.info('[ClassName] Message');

// ✅ Good - 包含关键上下文信息
AppLogger.info('[HttpService] Request completed: 200 in 824ms');
AppLogger.info('[CollectionNotifier] Adding request ${request.name} to collection $collectionId');

// ❌ Bad - 缺少上下文，无法定位问题
AppLogger.info('Success');
AppLogger.info('Done');

// ❌ Bad - 使用 print
print('Debug info'); // 禁止！
```

### 5. 禁止的日志实践

```dart
// ❌ 禁止在生产代码中保留 print
defaultConfig() {
  print('Loading config...'); // 禁止！
}

// ❌ 禁止记录敏感信息
AppLogger.info('User password: ${user.password}'); // 禁止！
AppLogger.info('Token: ${authToken}'); // 禁止！

// ❌ 禁止记录大量数据
AppLogger.debug('Response body: ${largeJson.toString()}'); // 可能超过几MB！

// ❌ 禁止在循环中记录 info 级别日志
for (final item in items) {
  AppLogger.info('Processing item: ${item.id}'); // 如果是1000个items，会产生大量日志
}

// ✅ 应该在循环外记录
AppLogger.info('Processing ${items.length} items');
for (final item in items) {
  // 使用 debug 级别
  AppLogger.debug('Processing item: ${item.id}');
}
```

### 6. 错误日志必须包含堆栈

```dart
// ✅ Good - 错误日志必须包含异常和堆栈
try {
  await riskyOperation();
} catch (e, stack) {
  AppLogger.error('[ClassName] Operation failed', e, stack);
}

// ❌ Bad - 缺少堆栈信息
try {
  await riskyOperation();
} catch (e) {
  AppLogger.error('[ClassName] Operation failed: $e'); // 堆栈丢失！
}
```

### 7. 使用 LogMixin 简化日志

```dart
import '../utils/app_logger.dart';

// ✅ 使用 mixin 自动添加类名前缀
class MyService with LogMixin {
  void doSomething() {
    logInfo('Doing something'); // 自动输出 [MyService] Doing something
    logDebug('Debug info');
    logError('Error occurred', error, stack);
  }
}
```

---

## 状态管理规范

### 1. Provider 组织

```dart
// core/providers.dart - 核心服务
final dioProvider = Provider<Dio>((ref) => Dio());
final storageProvider = Provider<StorageService>((ref) => StorageService());

// features/user/user_provider.dart - 功能模块
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User>>((ref) {
  return UserNotifier(ref);
});

// 导出文件 providers.dart
export 'core/providers.dart';
export 'features/user/user_provider.dart';
```

### 2. StateNotifier 规范

```dart
class UserNotifier extends StateNotifier<AsyncValue<User>> {
  UserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;

  void _init() {
    // 初始化逻辑
  }

  // ✅ Good - 使用 AsyncValue.guard 处理异步
  Future<void> fetchUser(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = _ref.read(userServiceProvider);
      return await service.getUser(id);
    });
  }

  // ✅ Good - 明确的错误处理
  Future<void> updateUser(User user) async {
    try {
      final service = _ref.read(userServiceProvider);
      final updated = await service.updateUser(user);
      state = AsyncValue.data(updated);
    } on NetworkException catch (e) {
      // 处理特定异常
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, stack) {
      // 处理其他异常
      state = AsyncValue.error(e, stack);
    }
  }
}
```

---

## UI/UX 规范

### 1. 设计原则

- **一致性**：使用统一的颜色、字体、间距
- **反馈**：用户操作后提供即时反馈
- **简洁性**：避免视觉混乱，保持界面清晰
- **可访问性**：支持键盘导航、屏幕阅读器

### 2. 颜色和主题

```dart
// ✅ Good - 使用 Theme
class AppTheme {
  static const primaryColor = Color(0xFF6366F1);
  static const secondaryColor = Color(0xFF8B5CF6);
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      // ... 其他配置
    );
  }
}

// 使用
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Title',
    style: Theme.of(context).textTheme.headlineSmall,
  ),
)
```

### 3. 间距规范

```dart
// ✅ Good - 使用一致的间距
const kSpaceXS = 4.0;
const kSpaceS = 8.0;
const kSpaceM = 12.0;
const kSpaceL = 16.0;
const kSpaceXL = 24.0;
const kSpaceXXL = 32.0;

// 使用
Padding(
  padding: const EdgeInsets.all(kSpaceM),
  child: Column(
    children: [
      const SizedBox(height: kSpaceS),
      const Text('Title'),
      const SizedBox(height: kSpaceL),
    ],
  ),
)
```

### 4. Widget 尺寸规范

```dart
// 按钮高度
const kButtonHeightS = 28.0;
const kButtonHeightM = 36.0;
const kButtonHeightL = 44.0;

// 输入框高度
const kInputHeightS = 28.0;
const kInputHeightM = 36.0;
const kInputHeightL = 44.0;

// 圆角
const kRadiusS = 4.0;
const kRadiusM = 6.0;
const kRadiusL = 8.0;
const kRadiusXL = 12.0;
```

---

## 文档规范

### 1. 文件头注释

```dart
/// 用户数据模型
/// 
/// 用于表示应用中的用户信息，包含基本资料、联系方式等。
/// 
/// 使用示例：
/// ```dart
/// final user = User(
///   id: '123',
///   name: 'John Doe',
///   email: 'john@example.com',
/// );
/// ```
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
  }) = _User;
}
```

### 2. 函数注释

```dart
/// 获取用户信息
/// 
/// [id] 用户唯一标识
/// 
/// 成功返回 [User] 对象，失败抛出 [UserNotFoundException]
/// 
/// 使用示例：
/// ```dart
/// final user = await getUser('123');
/// print(user.name);
/// ```
Future<User> getUser(String id) async {
  // 实现
}
```

---

## Git 提交规范

### 提交信息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

| 类型 | 说明 |
|-----|------|
| `feat` | 新功能 |
| `fix` | 修复 Bug |
| `docs` | 文档更新 |
| `style` | 代码格式调整（不影响功能） |
| `refactor` | 代码重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具链更新 |

### 示例

```
feat(request): add support for multipart form data

- Implement multipart request builder
- Add file picker integration
- Update UI for file upload

Fixes #123
```

```
fix(http): resolve timeout issue on slow networks

Increase default timeout from 10s to 30s
Add retry logic for timeout errors

Closes #456
```

---

## 工具配置

### 1. analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.mocks.dart"
  
  language:
    strict-casts: true
    strict-raw-types: true

linter:
  rules:
    # 代码风格
    - always_declare_return_types
    - always_put_control_body_on_new_line
    - always_specify_types
    - annotate_overrides
    - avoid_empty_else
    - avoid_init_to_null
    - avoid_returning_null_for_void
    - avoid_unused_constructor_parameters
    - camel_case_types
    - constant_identifier_names
    - empty_constructor_bodies
    - file_names
    - library_names
    - library_prefixes
    - non_constant_identifier_names
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_single_quotes
    - public_member_api_docs
    - sort_constructors_first
    - type_annotate_public_apis
    - unnecessary_this
    - use_super_parameters
```

### 2. VS Code 配置

```json
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "editor.rulers": [80, 120],
  "dart.lineLength": 100,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit",
      "source.organizeImports": "explicit"
    }
  }
}
```

### 3. Git Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit

# 运行 Dart 分析
echo "Running dart analyze..."
dart analyze

if [ $? -ne 0 ]; then
  echo "❌ Dart analysis failed"
  exit 1
fi

# 运行测试
echo "Running tests..."
flutter test

if [ $? -ne 0 ]; then
  echo "❌ Tests failed"
  exit 1
fi

echo "✅ Pre-commit checks passed"
```

---

## 附录

### 推荐工具

| 工具 | 用途 |
|-----|------|
| `dart format` | 代码格式化 |
| `dart analyze` | 静态分析 |
| `flutter_test` | 单元测试 |
| `build_runner` | 代码生成 |
| `freezed` | 不可变类生成 |
| `riverpod_generator` | Provider 生成 |

### 参考资源

- [Effective Dart](https://dart.dev/effective-dart)
- [Flutter Style Guide](https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md)
- [Material Design 3](https://m3.material.io/)
- [Riverpod Documentation](https://riverpod.dev/)
