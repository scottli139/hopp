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
├── models/                      # 数据模型 (Freezed + Hive)
│   ├── http_method.dart         # HTTP 方法枚举
│   ├── http_request.dart        # HTTP 请求模型
│   ├── http_response.dart       # HTTP 响应模型 (含 TimingInfo)
│   ├── http_request_info.dart   # 实际发送的请求信息模型 ✅
│   ├── key_value_pair.dart      # 键值对模型 (Header/Param)
│   ├── collection.dart          # Collection 模型
│   ├── app_settings.dart        # 应用设置模型
│   ├── request_tab.dart         # 标签页模型
│   ├── certificate_info.dart    # SSL/TLS 证书信息模型 ✅
│   ├── timing_info.dart         # 请求时间分析模型 ✅
│   ├── adapters/                # Hive 向后兼容适配器 ✅
│   └── models.dart              # 导出文件
├── providers/                   # 状态管理 (Riverpod)
│   ├── core/                    # 核心服务 Provider
│   │   └── providers.dart
│   ├── request/                 # 请求相关 Provider
│   │   ├── request_tab_provider.dart
│   │   └── request_response_provider.dart
│   ├── collection/              # Collection Provider
│   │   └── collection_provider.dart
│   ├── settings/                # 设置 Provider
│   │   └── settings_provider.dart
│   ├── import_export/           # 导入/导出 Provider ✅
│   │   └── import_export_provider.dart
│   ├── curl/                    # cURL 导入 Provider ✅
│   │   └── curl_import_provider.dart
│   └── providers.dart           # 导出文件
├── services/                    # 业务服务
│   ├── http_service.dart        # HTTP 服务 (Dio 封装)
│   ├── storage_service.dart     # 存储服务 (Hive)
│   ├── certificate_helper.dart  # 证书信息解析服务 ✅
│   ├── shortcut_service.dart    # 快捷键服务 ✅
│   ├── menu_channel.dart        # macOS 菜单通信 ✅
│   ├── database_migration_service.dart  # 数据库迁移服务 ✅
│   └── services.dart            # 导出文件
├── services/import_export/      # 导入/导出服务 ✅
│   ├── postman_schema.dart      # Postman JSON Schema 模型
│   ├── postman_mapper.dart      # 字段映射转换器
│   ├── postman_import_service.dart   # 导入服务
│   ├── postman_export_service.dart   # 导出服务
│   └── import_export_exception.dart  # 自定义异常
├── services/curl/               # cURL 导入服务 ✅
│   ├── curl_parser.dart         # cURL 命令解析器
│   ├── curl_tokenizer.dart      # 词法分析器
│   ├── curl_import_result.dart  # 导入结果模型
│   └── curl_import_service.dart # 导入服务
├── widgets/                     # UI 组件
│   ├── layout/                  # 布局组件
│   │   ├── sidebar.dart         # 侧边栏 (Collection 树)
│   │   └── request_tabs.dart    # 请求标签栏 ✅
│   ├── request/                 # 请求组件
│   │   ├── request_editor.dart  # 请求编辑器 (URL/Headers/Body/Settings)
│   │   └── response_viewer.dart # 响应查看器 (Request/Body/Headers/Cookies/Timing/Certificate)
│   ├── import_export/           # 导入/导出组件 ✅
│   │   ├── import_dialog.dart   # 导入对话框
│   │   ├── export_dialog.dart   # 导出对话框
│   │   └── conflict_resolution_dialog.dart  # 冲突处理
│   ├── common/                  # 通用组件 ✅
│   │   ├── code_editor.dart     # JSON 代码编辑器
│   │   ├── optimized_response_viewer.dart # 大响应虚拟化组件 ✅
│   │   └── shortcut_wrapper.dart # 快捷键包装器 ✅
│   └── widgets.dart             # 导出文件
├── screens/                     # 页面
│   ├── main_screen.dart         # 主屏幕
│   └── about/                   # 关于页面 ✅
│       └── about_screen.dart
├── utils/                       # 工具类
│   ├── app_logger.dart          # 日志工具 (LogMixin)
│   ├── constants.dart           # 应用常量
│   ├── url_params_sync.dart     # URL 查询参数同步 ✅
│   ├── testing/                 # 测试工具 ✅
│   │   ├── ui_test_mode.dart    # UI 测试模式 (HTTP 指令服务器)
│   │   └── test_helpers.dart    # 测试辅助函数
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

#### HttpRequest

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
    @HiveField(10) @Default('json') String rawContentType,  // Raw 子类型 ✅
    @HiveField(11) @Default(true) bool validateCertificates,  // SSL 验证开关 ✅
    @HiveField(12) @Default(true) bool followRedirects,       // 跟随重定向 ✅
    @HiveField(13) @Default(10) int maxRedirects,             // 最大重定向次数 ✅
  }) = _HttpRequest;
}
```

#### HttpResponse

```dart
@freezed
class HttpResponse with _$HttpResponse {
  const factory HttpResponse({
    String? body,
    List<KeyValuePair>? headers,
    int? statusCode,
    String? statusText,
    String? error,
    int? durationMs,
    int? sizeBytes,
    DateTime? timestamp,
    TimingInfo? timingInfo,        // 请求时间分析 ✅
    CertificateInfo? certificateInfo,  // SSL/TLS 证书信息 ✅
    HttpRequestInfo? requestInfo,  // 实际发送的请求信息 ✅
  }) = _HttpResponse;
}
```

#### TimingInfo (请求时间分析) ✅

```dart
@freezed
class TimingInfo with _$TimingInfo {
  const factory TimingInfo({
    int? dnsMs,         // DNS 解析时间
    int? tcpMs,         // TCP 连接时间
    int? tlsMs,         // TLS 握手时间
    int? ttfbMs,        // 首字节时间
    int? downloadMs,    // 下载时间
    required int totalMs, // 总耗时
  }) = _TimingInfo;
}
```

#### CertificateInfo (SSL/TLS 证书) ✅

```dart
@freezed
class CertificateInfo with _$CertificateInfo {
  const factory CertificateInfo({
    required String subject,       // 证书主题
    required String issuer,        // 颁发者
    required DateTime validFrom,   // 有效期开始
    required DateTime validTo,     // 有效期结束
    required String signatureAlgorithm, // 签名算法
    required String serialNumber,  // 序列号
    required String sha256Fingerprint,  // SHA-256 指纹
    @Default([]) List<String> subjectAlternativeNames,  // 主题备用名称
    String? publicKeyAlgorithm,    // 公钥算法（nullable）✅
    int? publicKeyLength,          // 公钥长度（nullable）✅
    @Default([]) List<CertificateChainEntry> chain,  // 证书链 ✅
  }) = _CertificateInfo;
}
```

#### HttpRequestInfo (实际发送的请求信息) ✅

```dart
@freezed
class HttpRequestInfo with _$HttpRequestInfo {
  const factory HttpRequestInfo({
    required String method,
    required String baseUrl,
    required String fullUrl,
    required String scheme,
    required String host,
    int? port,
    required String path,
    @Default([]) List<KeyValuePair> queryParams,
    @Default([]) List<KeyValuePair> headers,
    String? body,
    String? bodyType,
    int? bodySize,
    required DateTime timestamp,
  }) = _HttpRequestInfo;
}
```

---

## 网络层

### Dio 配置

```dart
class HttpService {
  Dio? _dio;

  HttpService({Dio? dio}) : _dio = dio;

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
    
    // 为每个请求创建新的 Dio 实例以支持独立的 SSL 配置 ✅
    final dio = _dio ?? _createDioForRequest(request);
    
    try {
      final response = await dio.request(
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
      // 提取 4XX/5XX 响应中的服务端返回内容 ✅
      if (e.response != null) {
        return _extractErrorResponse(e.response!, stopwatch);
      }
      return HttpResponse.error(_formatError(e));
    }
  }
  
  // 根据请求配置创建 Dio 实例 (支持 SSL 验证开关) ✅
  Dio _createDioForRequest(HttpRequest request) {
    final dio = _createDio();
    
    if (!request.validateCertificates) {
      // 禁用 SSL 证书验证
      final adapter = dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.onHttpClientCreate = (client) {
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };
      }
    }
    
    return dio;
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
        │       │   └── TabBar (Params/Headers/Body/Auth/Settings) ✅
        │       └── ResponseViewer
        │           ├── InfoBar
        │           └── TabBar (Request/Body/Headers/Cookies/Timing/Certificate) ✅
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
   - 证书验证可配置 ✅
   - 请求超时设置

3. **代码安全**
   - 静态分析检查
   - 依赖安全扫描

---

## UI 测试模式 ✅

Hopp 实现了内置的 UI 测试模式，支持通过 HTTP 指令远程控制应用。

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
| `get_timing_info` | 获取时间分析 |
| `get_request_details` | 获取请求详情 |
| `get_certificate_info` | 获取证书信息 |
| `simulate_4xx_response` | 模拟 4XX 错误响应 |
| `simulate_5xx_response` | 模拟 5XX 错误响应 |
| `full_test` | 完整测试流程 |

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
