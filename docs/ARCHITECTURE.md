# Hopp 架构设计文档

> 本文档描述 Hopp 项目的整体架构、技术选型和设计决策。

---

## 📋 目录

- [架构概览](#架构概览)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [数据流](#数据流)
- [状态管理](#状态管理)
- [存储层](#存储层)
- [网络层](#网络层)
- [UI 层](#ui-层)
- [设计决策](#设计决策)

---

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Screens   │  │   Widgets   │  │   UI Components     │  │
│  │  (Pages)    │  │  (Reusable) │  │   (Common)          │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          └────────────────┴────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       State Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Providers  │  │  Notifiers  │  │   State Models      │  │
│  │  (Riverpod) │  │ (StateNtf)  │  │   (AsyncValue)      │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          └────────────────┴────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Models    │  │  Services   │  │   Repositories      │  │
│  │  (Freezed)  │  │  (Business) │  │   (Data Access)     │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          └────────────────┴────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    Hive     │  │ SharedPrefs │  │   Dio (HTTP)        │  │
│  │  (NoSQL)    │  │  (Config)   │  │   (Network)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 技术栈

### 核心框架

| 技术 | 版本 | 用途 |
|-----|------|-----|
| Flutter | 3.27.x | UI 框架 |
| Dart | 3.6.x | 编程语言 |
| Riverpod | 2.6.x | 状态管理 |
| Dio | 5.8.x | HTTP 客户端 |

### 代码生成

| 工具 | 用途 |
|-----|------|
| Freezed | 不可变数据类 |
| json_serializable | JSON 序列化 |
| Hive Generator | Hive Adapter 生成 |
| Riverpod Generator | Provider 生成 |

### 存储

| 存储 | 用途 |
|-----|------|
| Hive | Collection、Request 等复杂数据 |
| SharedPreferences | 设置、主题等简单配置 |

---

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/                      # 数据模型
│   ├── http_method.dart         # HTTP 方法枚举
│   ├── http_request.dart        # HTTP 请求模型
│   ├── http_response.dart       # HTTP 响应模型
│   ├── key_value_pair.dart      # 键值对模型
│   ├── collection.dart          # Collection 模型
│   ├── app_settings.dart        # 应用设置模型
│   ├── request_tab.dart         # 标签页模型
│   └── models.dart              # 导出文件
├── providers/                   # 状态管理
│   ├── core/                    # 核心服务 Provider
│   │   └── providers.dart
│   ├── request/                 # 请求相关 Provider
│   │   ├── request_tab_provider.dart
│   │   └── request_response_provider.dart
│   ├── collection/              # Collection Provider
│   │   └── collection_provider.dart
│   ├── settings/                # 设置 Provider
│   │   └── settings_provider.dart
│   └── providers.dart           # 导出文件
├── services/                    # 业务服务
│   ├── http_service.dart        # HTTP 服务
│   ├── storage_service.dart     # 存储服务
│   └── services.dart            # 导出文件
├── widgets/                     # UI 组件
│   ├── layout/                  # 布局组件
│   │   ├── sidebar.dart
│   │   └── request_tabs.dart
│   ├── request/                 # 请求组件
│   │   ├── request_editor.dart
│   │   └── response_viewer.dart
│   └── widgets.dart             # 导出文件
├── screens/                     # 页面
│   └── main_screen.dart
├── utils/                       # 工具类
│   ├── app_logger.dart          # 日志工具
│   └── utils.dart               # 导出文件
└── l10n/                        # 国际化
    ├── app_en.arb
    ├── app_zh.arb
    └── l10n.dart
```

---

## 数据流

### 单向数据流

```
User Action → Provider → Service → Repository → Data Source
                   ↓
              UI Update ← State Change ← AsyncValue
```

### 请求发送流程

```
1. 用户点击 Send 按钮
2. RequestEditor Widget 调用 Provider 方法
3. RequestResponseNotifier 调用 HttpService
4. HttpService 使用 Dio 发送 HTTP 请求
5. 返回结果包装为 AsyncValue
6. UI 根据 AsyncValue 状态更新
```

---

## 状态管理

### Riverpod 架构

```dart
// 1. 定义 StateNotifier
class UserNotifier extends StateNotifier<AsyncValue<User>> {
  UserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    await loadUser();
  }

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

// 2. 定义 Provider
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User>>((ref) {
  return UserNotifier(ref);
});

// 3. 在 Widget 中使用
class UserProfile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) => _buildUserView(user),
      loading: () => const CircularProgressIndicator(),
      error: (err, _) => ErrorView(err),
    );
  }
}
```

### Provider 分类

| 类型 | 用途 | 示例 |
|-----|------|------|
| Provider | 不可变依赖 | `dioProvider` |
| StateProvider | 简单状态 | `activeTabIdProvider` |
| StateNotifierProvider | 复杂状态 | `collectionProvider` |
| FutureProvider | 异步数据 | `userFutureProvider` |
| StreamProvider | 流数据 | `logsStreamProvider` |

---

## 存储层

### 存储策略

```
┌─────────────────┬─────────────────┬─────────────────┐
│   SharedPrefs   │      Hive       │     Memory      │
├─────────────────┼─────────────────┼─────────────────┤
│ 主题设置        │ Collections     │ HTTP 响应缓存   │
│ 语言设置        │ Requests        │ 临时计算结果    │
│ 编辑器配置      │ History         │                 │
│ API 配置        │ Environments    │                 │
└─────────────────┴─────────────────┴─────────────────┘
```

### Hive 数据模型

```dart
@freezed
@HiveType(typeId: 2)
class HttpRequest with _$HttpRequest {
  const factory HttpRequest({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) @Default(HttpMethod.get) HttpMethod method,
    @HiveField(3) @Default('') String url,
    @HiveField(4) @Default([]) List<KeyValuePair> params,
    @HiveField(5) @Default([]) List<KeyValuePair> headers,
    @HiveField(6) @Default('') String body,
    @HiveField(7) @Default('none') String bodyType,
    @HiveField(8) String? parentId,
    @HiveField(9) @Default(0) int sortOrder,
  }) = _HttpRequest;
}
```

---

## 网络层

### Dio 配置

```dart
class HttpService {
  final Dio _dio;

  HttpService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 600,
    ));
  }

  Future<HttpResponse> sendRequest(HttpRequest request) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await _dio.request(
        request.url,
        options: Options(method: request.method.value),
        data: request.body,
        queryParameters: _buildQueryParams(request.params),
      );

      return HttpResponse(
        body: response.data,
        statusCode: response.statusCode,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on DioException catch (e) {
      return HttpResponse.error(_formatError(e));
    }
  }
}
```

---

## UI 层

### 组件层次

```
App
└── MaterialApp
    └── MainScreen
        ├── MultiSplitView
        │   ├── Sidebar
        │   │   └── CollectionTree
        │   └── RequestArea
        │       ├── RequestTabs
        │       ├── RequestEditor
        │       │   ├── UrlBar
        │       │   └── TabBar (Params/Headers/Body/Auth)
        │       └── ResponseViewer
        │           ├── InfoBar
        │           └── TabBar (Body/Headers/Cookies)
        └── StatusBar
```

### 响应式布局

```dart
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiSplitView(
      axis: Axis.horizontal,
      builder: (context, area) {
        switch (area.index) {
          case 0:
            return const Sidebar(flex: 0.22);
          case 1:
            return const RequestArea(flex: 0.78);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
```

---

## 设计决策

### 1. 为什么选择 Flutter？

| 因素 | 考虑 |
|-----|------|
| 跨平台 | 一套代码支持 macOS/Windows/Linux |
| 性能 | AOT 编译，接近原生性能 |
| UI 一致性 | 自绘引擎，不受系统差异影响 |
| 生态 | 丰富的包生态，活跃的社区 |
| 未来扩展 | 可无缝扩展到移动端 |

### 2. 为什么选择 Riverpod？

| 因素 | 考虑 |
|-----|------|
| 编译时安全 | 相比 Provider 更安全的依赖注入 |
| 类型安全 | 完全支持泛型 |
| 可测试性 | 不依赖 BuildContext |
| 代码生成 | 支持 @riverpod 注解 |
| Scoped | 支持覆盖 Provider |

### 3. 为什么选择 Hive？

| 因素 | 考虑 |
|-----|------|
| 性能 | 二进制存储，读写速度快 |
| 纯 Dart | 无需原生代码 |
| 类型安全 | 支持 Dart 对象直接存储 |
| 轻量级 | 包体积小 |

### 4. 为什么选择 Dio？

| 因素 | 考虑 |
|-----|------|
| 功能丰富 | 拦截器、取消请求、文件上传等 |
| 插件生态 | retry、cache 等丰富插件 |
| 错误处理 | 完善的错误处理机制 |
| 社区活跃 | 国内 Flutter 社区最广泛使用 |

---

## 性能考虑

### 优化策略

1. **Widget 优化**
   - 使用 `const` 构造函数
   - 使用 `Consumer` 局部刷新
   - 避免不必要的 rebuild

2. **列表优化**
   - 使用 `ListView.builder`
   - 实现 `RepaintBoundary`

3. **图片优化**
   - 使用 `cached_network_image`
   - 适当压缩图片资源

4. **内存优化**
   - 及时释放资源
   - 使用 `WeakReference`

---

## 安全考虑

1. **数据安全**
   - 敏感数据加密存储
   - HTTPS 强制使用

2. **网络安全**
   - 证书验证可配置
   - 请求超时设置

3. **代码安全**
   - 静态分析检查
   - 依赖安全扫描

---

## 扩展性设计

### 插件系统 (未来)

```dart
abstract class HoppPlugin {
  String get name;
  String get version;
  
  void initialize(PluginContext context);
  void registerWidgets(WidgetRegistry registry);
  void registerProviders(ProviderRegistry registry);
}
```

### 主题系统

```dart
abstract class ThemeExtension {
  Color get primaryColor;
  TextTheme get textTheme;
  // ...
}
```

---

## 参考资源

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Riverpod Documentation](https://riverpod.dev/)
- [Dio Documentation](https://github.com/cfug/dio)
- [Hive Documentation](https://docs.hivedb.dev/)

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
