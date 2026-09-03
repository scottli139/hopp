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
- [性能考虑](#性能考虑)
- [安全考虑](#安全考虑)
- [UI 测试模式](#ui-测试模式)
- [扩展性设计](#扩展性设计)
- [AI 助手架构（三层）](#ai-助手架构三层)
- [预请求链与变量转换](#预请求链与变量转换)
- [参考资源](#参考资源)

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
│  ┌─────────────────────────┐  ┌─────────────────────────┐   │
│  │        Models           │  │        Services         │   │
│  │       (Freezed)         │  │   (Business Logic)      │   │
│  │                         │  │   直接访问 Hive / 网络   │   │
│  └───────────┬─────────────┘  └────────────┬────────────┘   │
└──────────────┼─────────────────────────────┼────────────────┘
               │                             │
               └─────────────────────────────┘
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
> 注：无独立 Repository 层——Service 直接访问 Hive/Dio，保持简单。

---

## 技术栈

### 核心框架

| 技术 | 版本 | 用途 |
|-----|------|-----|
| Flutter | 3.35.x | UI 框架 |
| Dart | 3.9.x | 编程语言 |
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

### 核心依赖

> 版本以 `pubspec.yaml` 为准（2026-09-03 核对）。

| 包名 | 版本 | 用途 |
|-----|------|------|
| flutter_riverpod | ^2.6.1 | 状态管理 |
| riverpod_annotation | ^2.6.1 | Provider 注解 |
| dio | ^5.8.0+1 | HTTP 客户端 |
| hive / hive_flutter | ^2.2.3 / ^1.1.0 | NoSQL 存储 |
| shared_preferences | ^2.5.2 | 配置存储 |
| path_provider / path | ^2.1.5 / ^1.9.0 | 路径工具 |
| logger | ^2.5.0 | 日志（CLI 闭包共用） |
| intl | ^0.20.2 | 国际化 |
| freezed_annotation | ^2.4.4 | 不可变类注解 |
| json_annotation | ^4.9.0 | JSON 序列化注解 |
| crypto | ^3.0.3 | 证书指纹 + 变量转换摘要（sha1/md5/sha256/hmac） |
| encrypt | ^5.0.3 | AES 加密（M8.2：变量转换 + Hive 落盘加密） |
| yaml | ^3.1.2 | OpenAPI YAML 解析（M8.3） |
| json_path | ^0.7.6 | JSONPath 求值（M8.4 断言引擎，GUI/CLI 共用） |
| args | ^2.7.0 | CLI 参数解析（M8.4） |
| multi_split_view | ^3.6.0 | 可拖拽分割面板 |
| tabbed_view | ^1.22.0 | 标签页容器 |
| data_table_2 | ^2.5.18 | 数据表格 |
| flutter_code_editor | ^0.3.2 | 代码高亮 |
| flutter_svg | ^2.0.17 | SVG 显示 |
| cupertino_icons | ^1.0.8 | 图标 |
| file_picker | ^10.3.10 | 文件选择 |
| package_info_plus | ^9.0.1 | 版本号动态读取（Issue #13） |
| url_launcher | ^6.3.1 | 外部链接跳转（About 页，Issue #8） |
| uuid | ^4.5.3 | UUID 生成 |

### 开发依赖

| 包名 | 版本 | 用途 |
|-----|------|------|
| build_runner | ^2.4.6 | 代码生成 |
| freezed | ^2.4.5 | 不可变类生成 |
| json_serializable | ^6.7.0 | JSON 序列化生成 |
| hive_generator | ^2.0.1 | Hive Adapter 生成 |
| riverpod_generator | ^2.3.0 | Provider 生成 |
| mockito | ^5.4.0 | 测试 Mock |
| flutter_lints | ^5.0.0 | 静态分析规则 |

---

## 项目结构

```
hopp/
├── cli/                                  # hopp run CLI 运行器（M8.4；app 包内目录，非嵌套 pub 包）
│   ├── hopp.dart                         # 入口（fvm dart compile exe cli/hopp.dart 可编译单文件）
│   └── src/                              # app / cli_args / runner / report / export_document
├── lib/
│   ├── main.dart                         # 应用入口
│   ├── theme/                            # 设计系统 token（P1–P5 收口后为视觉规范唯一事实来源）
│   │   ├── app_colors.dart               # 调色板（方法色/状态码色唯一入口）
│   │   ├── app_theme_data.dart           # 语义色 ThemeExtension（亮暗双套）
│   │   ├── app_text_styles.dart          # 7 档字号 + code11/code12 等宽
│   │   ├── app_metrics.dart / app_shadows.dart / app_syntax_colors.dart
│   │   └── app_theme.dart                # ThemeData 组装
│   ├── models/                           # 数据模型 (Freezed + Hive)
│   │   ├── http_request.dart             # 请求模型（Hive typeId 2，field 0-17）
│   │   ├── http_method.dart              # 方法枚举 (typeId 10)
│   │   ├── http_response.dart            # 响应模型（Freezed，不直接入 Hive）
│   │   ├── http_request_info.dart        # 实际发送的请求信息（含 autoHeaderKeys）
│   │   ├── key_value_pair.dart           # 键值对 (typeId 1)
│   │   ├── collection.dart               # Collection (typeId 3)
│   │   ├── app_settings.dart             # 应用设置 (typeId 4)
│   │   ├── request_tab.dart              # 标签页模型
│   │   ├── certificate_info.dart / timing_info.dart
│   │   ├── environment.dart              # 环境变量（M8.1：Environment=11 / Variable=12 / Type=13）
│   │   ├── auth_config.dart              # 认证配置（M8.2：AuthType=14 / AuthConfig=15）
│   │   ├── pre_request_step.dart         # 预请求链（M8.2：Step=16 / ExtractionRule=17 / SourceType=18）
│   │   ├── assertion_rule.dart           # 断言规则（M8.4：Rule=19 / Target=20 / Operator=21）
│   │   ├── adapters/                     # Hive 手写兼容适配器（field 追加兼容存量）
│   │   └── models.dart                   # 导出文件
│   ├── providers/                        # 状态管理 (Riverpod)
│   │   ├── core/                         # 服务装配 + app_info（版本号动态读取）
│   │   ├── request/                      # 请求 Tab / 请求-响应 Notifier
│   │   ├── collection/                   # Collection 树
│   │   ├── settings/
│   │   ├── environment/                  # 环境变量（M8.1）
│   │   ├── import_export/                # 导入导出 + openapi_import_provider（M8.3）
│   │   ├── curl/                         # cURL 导入
│   │   └── providers.dart
│   ├── services/
│   │   ├── http_service.dart             # Dio 封装（纯 Dart 可注入，CLI 共用）
│   │   ├── storage_service.dart          # Hive 初始化 + box 管理（含 AES 落盘）
│   │   ├── database_migration_service.dart
│   │   ├── auth_resolver.dart            # Auth 沿 parentId 链继承解析（M8.2）
│   │   ├── variable_resolver.dart        # {{var}} 解析 + 5 个动态变量（M8.1）
│   │   ├── variable_transforms.dart      # {{var \| fn}} 转换管道（M8.2）
│   │   ├── box_encryption.dart           # HiveAesCipher 落盘加密（M8.2）
│   │   ├── certificate_helper.dart       # 证书解析（去 Flutter 化，CLI 共用）
│   │   ├── shortcut_service.dart / menu_channel.dart
│   │   ├── pre_request/                  # 链执行器 + 响应提取器（M8.2）
│   │   ├── assertion/                    # 断言求值引擎（M8.4，GUI/CLI 共用）
│   │   ├── curl/                         # tokenizer / parser / service
│   │   ├── import_export/                # postman_* + hopp_export_service（M8.4 .hopp.json）
│   │   │   └── openapi/                  # M8.3：parser / mapper / spec / import_service
│   │   └── services.dart
│   ├── widgets/
│   │   ├── common/                       # 设计系统组件：AppButton/AppTextField/AppTabs/AppDialog/
│   │   │   │                             #   AppPopupSelect/AppSegmentedControl/AppSwitch/AppCard/…
│   │   ├── layout/                       # sidebar / request_tabs
│   │   ├── request/                      # request_editor（7 页签）/ response_viewer（含 Tests）
│   │   │   │                             #   auth_config_editor / pre_request_chain_editor /
│   │   │   │                             #   assertion_editor / variable_fx_menu
│   │   ├── import_export/                # import_dialog（Postman/cURL/OpenAPI 三页签，M8.3）
│   │   │   │                             #   export_dialog（FORMAT 双选项，M8.4）
│   │   │   │                             #   conflict_resolution_dialog / curl_import_panel / openapi_import_panel
│   │   ├── environment/                  # environment_manager_dialog / environment_switcher
│   │   ├── collection/                   # collection_settings_dialog（M8.2）
│   │   └── widgets.dart
│   ├── screens/                          # main_screen / about/ / design_gallery/（token 画廊）
│   ├── utils/
│   │   ├── app_logger.dart / url_params_sync.dart / database_consts.dart
│   │   └── testing/                      # ui_test_mode.dart（HTTP 指令服务器）/ test_helpers.dart
│   └── l10n/
└── test/                                 # models / services / providers / widgets / utils
                                          #   cli（M8.4，含 HttpServer 集成）/ fixtures / mocks
```

---

## 数据流

### 单向数据流

```
User Action → Provider → Service → Data Source (Hive / Dio)
                   ↓
              UI Update ← State Change ← AsyncValue
```

> Service 直接访问数据层，无独立 Repository 层。

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
┌─────────────────┬────────────────────────┬─────────────────┐
│   SharedPrefs   │         Hive           │     Memory      │
├─────────────────┼────────────────────────┼─────────────────┤
│ 主题设置        │ Collections（AES 加密）│ HTTP 响应缓存   │
│ 语言设置        │ Requests（AES 加密）   │ 临时计算结果    │
│ 编辑器配置      │ Environments（AES）    │                 │
│ API 配置        │ Settings               │                 │
│ 数据库版本      │                        │                 │
└─────────────────┴────────────────────────┴─────────────────┘
```

> Hive 共 4 个 box（无 History box）：`collections` / `requests` / `environments` 三个 box 自 M8.2 起经 `HiveAesCipher` 落盘 AES 加密（应用级 32 字节 key 以 base64 存数据目录 `.secure_key`，见「安全考虑」）。

### Schema 版本与 typeId 分配

- **数据库版本**：`DatabaseConsts.currentDbVersion = 4`（v4 由 M8.2 引入：追加 Auth/预请求链字段 + 三 box 启用 AES，存量明文 box 自动一次性迁移）。
- **typeId 分配**（全部位于 `lib/models/`，以 `@HiveType` 注解为准）：

| typeId | 模型 | 引入 |
|--------|------|------|
| 1 | KeyValuePair | M1 |
| 2 | HttpRequest（field 0-17） | M1，field 11-13 为 M4，14-16 为 M8.2，17 为 M8.4 |
| 3 | Collection | M1 |
| 4 | AppSettings | M1 |
| 10 | HttpMethod | M1 |
| 11-13 | Environment / EnvironmentVariable / VariableType | M8.1 |
| 14-15 | AuthType / AuthConfig | M8.2 |
| 16-18 | PreRequestStep / ExtractionRule / ExtractionSourceType | M8.2 |
| 19-21 | AssertionRule / AssertionTarget / AssertionOperator | M8.4 |

> HttpResponse / RequestTab / CertificateInfo / TimingInfo / HttpRequestInfo 等为 Freezed 模型，不直接入 Hive box。

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
    @HiveField(14) @Default(AuthConfig()) AuthConfig auth,    // 认证配置（M8.2，沿集合链继承解析）
    @HiveField(15) @Default([]) List<PreRequestStep> preRequestChain,  // 预请求链（M8.2）
    @HiveField(16) @Default(false) bool preRequestRetryOn401, // 401 自动重跑（M8.2）
    @HiveField(17) @Default([]) List<AssertionRule> assertions,  // 断言规则（M8.4）
  }) = _HttpRequest;
}
```

> field 均为追加式扩展，手写兼容适配器对缺 field 的存量数据给默认值，无迁移脚本（见「Schema 版本与 typeId 分配」）。

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
        │       │   └── TabBar (Params/Headers/Body/Auth/Pre-request/Assertions/Settings) ✅
        │       └── ResponseViewer
        │           ├── InfoBar
        │           └── TabBar (Body/Headers/Cookies/Request/Tests [+Timing/Certificate]) ✅
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
   - 落盘加密（M8.2）：collections/requests/environments 三个 Hive box 经 `HiveAesCipher` AES 加密；应用级 32 字节 key 以 base64 存数据目录 `.secure_key`（`box_encryption.dart`），存量明文 box 首次启动自动一次性迁移
   - 环境变量 / 密码 / token 等 secret 类型加密存储、界面脱敏显示
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

> **数据隔离（M8.3）**：`--test-mode` 实例使用独立数据目录 `Documents/hopp_test`（Hive 目录与加密 key 目录均切换），与用户真实数据完全隔离——自动化再也碰不到真实数据，同时也看不到用户数据，需用指令自建 fixture。

```bash
# 1. 以测试模式启动应用
./hopp.app/Contents/MacOS/hopp --test-mode

# 2. 从日志获取端口
grep "测试服务器启动在端口" ~/Library/Containers/.../hopp_*.log

# 3. 执行测试
python3 integration_test/test_client.py --port <PORT> full_test
```

### 可用指令

> 以下为常用指令子集（约 30 条），完整指令（80+ 条，随版本增长）以 `lib/utils/testing/ui_test_mode.dart` 指令分发为准。

| 指令 | 说明 |
|------|------|
| `create_request` / `save_request` / `rename_request` | 创建 / 保存 / 重命名请求 |
| `create_collection` / `trigger_add_folder_dialog` / `create_saved_request` | 创建集合 / 文件夹 / 直接落库的已保存请求（供链引用） |
| `set_url` / `set_method` / `add_header` / `set_body` | 编辑请求 |
| `set_pre_request_chain` | 设置预请求链步骤 + 提取规则 + 401 重跑（M8.2） |
| `set_assertions` | 设置断言规则（request_id/name 定位，M8.4） |
| `send_request` | 发送请求 |
| `switch_request_tab` | 切换请求 Tab (params/headers/body/auth/prerequest/assertions/settings) |
| `switch_response_tab` | 切换响应 Tab (body/headers/cookies/request/tests [+timing/certificate]) |
| `get_response_info` / `get_request_details` / `get_timing_info` / `get_certificate_info` / `get_collection_tree` / `get_active_environment` | 状态回读 |
| `resolve_text` / `get_resolved_request` | 变量解析验证（M8.1） |
| `create_environment` / `set_active_environment` | 环境管理（M8.1） |
| `trigger_import_dialog tab=postman\|curl\|openapi` / `import_openapi` / `trigger_export_dialog` | 导入导出驱动（M8.3/M8.4） |
| `scroll_response target=body\|certificate` / `scroll_at` / `tap_at` / `set_window_size` | 物理交互与窗口（指针注入，M8.0 起） |
| `set_theme_mode` / `open_design_gallery` / `capture_screenshot` / `dismiss_dialog` | 主题 / 画廊 / 截图 / 对话框 |
| `simulate_4xx_response` / `simulate_5xx_response` | 模拟错误响应 |
| `full_test` | 完整测试流程（test_client.py 客户端复合指令） |

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

## AI 助手架构（三层）📋

> 定位：本地 + 私有 AI，数据默认不出机器。

```text
┌─────────────────────────────────────────────────────────┐
│              AI 能力层（可选、显式开启）                  │
│  Tier 2  BYOK 云端（OpenAI/Anthropic/DeepSeek，默认关闭） │
│  Tier 1  本地模型（Ollama/LM Studio，localhost OpenAI 兼容）│
│  Tier 0  无模型（OpenAPI/Swagger 导入、cURL 导入，纯确定性）│
└───────────────────────┬─────────────────────────────────┘
                        │ 产出可保存、可复跑
                        ▼
        Collection / Environment / 断言（本地持久化）
```

**设计原则**:
- 默认本地，永不自动外发；Tier 2 需用户显式配置 key 并开启
- AI 产出落到 collection / 环境 / 断言，而非一次性聊天
- Tier 1 通过 localhost OpenAI 兼容端点接入（Ollama / LM Studio），无需新协议

**统一客户端与安全（借鉴 Voxmit）**:
- 单一 OpenAI 兼容客户端：`baseURL + model + key` 可配，`/chat/completions` 协议；Tier 1 指向 `http://localhost:11434/v1`（Ollama），Tier 2 指向云端
- 密钥走 OS 安全存储（macOS Keychain / Windows Credential Manager / Linux libsecret），日志只落元数据，不落请求体与 key（**尚未实现**：现阶段 secret 变量用应用级 `.secure_key` 文件，见「安全考虑」）
- 优雅降级：AI 有界超时 + 一次重试 + 失败回退；核心「发请求」永不依赖 AI；首次外发前隐私告知门
- 防脑补：生成请求/断言时，字段只允许来自 spec 或用户输入，禁止新增与补全指代

## 预请求链与变量转换 📋

> 替代 Postman 的 pre-request JS 沙箱，用声明式积木降低门槛。

```text
目标请求
  ▲
  │ 注入 {{token}} / {{sign}} 等变量
  │
预请求链（可有多个前置请求）
  │  1. login（密码经变量转换 sha1/aes 加密）
  │  2. 从响应提取 token（JSONPath/正则/Header）
  └── 写入本地作用域变量
```

**变量转换引擎**（纯 Dart，无 JS 沙箱）:
- 解析 `{{value | transform(args)}}` 管道语法
- 内置：sha1 / md5 / sha256 / base64 / aes / hmac
- 动态变量：`{{$timestamp}}`、`{{$timestampMs}}`、`{{$isoTimestamp}}`、`{{$randomUUID}}`、`{{$randomInt}}`

**替换顺序**: 变量解析 → 变量转换 → 变量替换（本地 > 环境 > 全局，本地作用域为预请求链产出，不污染环境）

## 参考资源

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Riverpod Documentation](https://riverpod.dev/)
- [Dio Documentation](https://github.com/cfug/dio)
- [Hive Documentation](https://docs.hivedb.dev/)
