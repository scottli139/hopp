# Hopp 实现说明文档

> 本文档记录 Hopp 项目的详细技术实现方案、架构设计和代码示例。

---

## 目录

- [数据库迁移框架](#数据库迁移框架)
- [请求设置 (Request Settings)](#请求设置-request-settings)
- [Postman 导入/导出](#postman-导入导出)
- [cURL 导入](#curl-导入)
- [URL 参数双向联动 (Issue #11)](#url-参数双向联动-issue-11)
- [Collection 扁平化存储重构 (Issue #3)](#collection-扁平化存储重构-issue-3)
- [空状态入口指引 (Issue #6)](#空状态入口指引-issue-6)
- [响应优化 (OptimizedResponseViewer)](#响应优化-optimizedresponseviewer)
- [预请求链与变量转换 (M8.2 / v0.10.0)](#预请求链与变量转换-m82-f8--v0100-2026-08-25)
- [环境变量系统 (M8.1)](#环境变量系统-m81)
- [测试与自动化](#测试与自动化)
- [Mock 服务器](#mock-服务器)

---

## 数据库迁移框架

### 问题背景

当 `HttpRequest` 模型新增字段（如 `validateCertificates`, `followRedirects`, `maxRedirects`）时，旧版本存储的数据缺少这些字段，导致 Hive 读取时抛出异常。

### 解决方案

#### 1. 数据库版本控制 (`database_migration_service.dart`)

- 使用 `SharedPreferences` 存储数据库版本号
- 启动时检测版本，自动执行迁移脚本
- 支持未来版本升级

#### 2. 向后兼容适配器 (`models/adapters/`)

```dart
// 处理缺失字段，提供默认值
validateCertificates: fields[11] == null ? true : fields[11] as bool,
followRedirects: fields[12] == null ? true : fields[12] as bool,
maxRedirects: fields[13] == null ? 10 : fields[13] as int,
```

#### 3. 迁移流程

```
应用启动 → 检查 db_version → 需要升级? → 执行迁移 → 更新版本号 → 正常使用
                     ↓
                  不需要 → 直接使用
```

---

## 请求设置 (Request Settings)

### 技术要点

- 请求设置应与请求数据一起保存到 Collection
- Dio 支持通过 `Options` 配置大部分设置
- SSL 验证通过 `DioHttpClientAdapter` 的 `onHttpClientCreate` 配置
- TLS/SSL 协议禁用需要平台特定的实现
- 设置项需要支持「继承全局默认值」和「请求级别覆盖」两种模式

### 架构设计

请求设置并未拆分为独立文件，而是直接内联在现有组件中：

- `lib/widgets/request/request_editor.dart` 的 `_buildSettingsTab()` 负责 Settings Tab UI
- `lib/models/http_request.dart` 的 `HttpRequest` 模型新增三个字段：
  - `validateCertificates`（SSL 证书验证开关，`@HiveField(11)`）
  - `followRedirects`（自动跟随重定向开关，`@HiveField(12)`）
  - `maxRedirects`（最大重定向次数，`@HiveField(13)`）

> 不存在独立的 `request_settings.dart`、`request_settings_provider.dart`、`request_settings_tab.dart` 或 `request_options_builder.dart`。

### 已实现的设置项

| 功能项 | 类型 | 默认值 | 状态 |
|--------|------|--------|------|
| Enable SSL certificate verification | Toggle | ON | ✅ 已实现 |
| Automatically follow redirects | Toggle | ON | ✅ 已实现 |
| Maximum number of redirects | Number Input | 10 | ✅ 已实现 |

### 完整功能清单（规划）

参考 Postman 请求级别配置，完整清单如下：

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

### UI 设计

- 设置项采用卡片式布局，每个设置独立卡片
- 显示「Default: Settings」提示继承关系
- 修改后显示紫色圆点指示器
- 支持分组（SSL/TLS、重定向、编码等）

---

## Postman 导入/导出

### 架构设计

```
lib/
├── services/
│   └── import_export/
│       ├── postman_import_service.dart      # 导入服务
│       ├── postman_export_service.dart      # 导出服务
│       ├── postman_schema.dart              # Postman JSON Schema 模型
│       ├── postman_mapper.dart              # 字段映射转换器
│       └── import_export_exception.dart     # 自定义异常
├── providers/
│   └── import_export/
│       └── import_export_provider.dart      # 导入/导出状态管理
└── widgets/
    └── import_export/
        ├── import_dialog.dart               # 导入对话框
        ├── export_dialog.dart               # 导出对话框
        └── conflict_resolution_dialog.dart  # 冲突处理对话框
```

### 数据模型设计

#### Collection v2.1 Schema

```dart
@freezed
class PostmanCollection with _$PostmanCollection {
  const factory PostmanCollection({
    required PostmanInfo info,
    required List<PostmanItem> item,
    List<PostmanVariable>? variable,
  }) = _PostmanCollection;
}

@freezed
class PostmanInfo with _$PostmanInfo {
  const factory PostmanInfo({
    required String name,
    String? description,
    String? version,
    @JsonKey(name: '_postman_id') String? postmanId,
    String? schema,
  }) = _PostmanInfo;
}

@freezed
class PostmanItem with _$PostmanItem {
  const factory PostmanItem.request({
    required String name,
    PostmanRequest? request,
    List<PostmanResponse>? response,
    String? description,
  }) = PostmanRequestItem;
  
  const factory PostmanItem.folder({
    required String name,
    required List<PostmanItem> item,
    String? description,
  }) = PostmanFolderItem;
}

@freezed
class PostmanRequest with _$PostmanRequest {
  const factory PostmanRequest({
    required String method,
    required PostmanUrl url,
    List<PostmanHeader>? header,
    PostmanBody? body,
    String? description,
  }) = _PostmanRequest;
}

@freezed
class PostmanBody with _$PostmanBody {
  const factory PostmanBody({
    required String mode,  // raw/urlencoded/formdata/graphql/binary
    String? raw,
    List<PostmanUrlEncoded>? urlencoded,
    List<PostmanFormData>? formdata,
    PostmanGraphQL? graphql,
    PostmanBodyOptions? options,
  }) = _PostmanBody;
}
```

### 核心服务实现

#### PostmanImportService

```dart
class PostmanImportService {
  final CollectionStorageService _collectionStorage;
  final EnvironmentStorageService _environmentStorage;
  
  /// 导入文件，自动检测类型 (Collection/Environment)
  Future<ImportResult> importFile(String filePath) async {
    final content = await File(filePath).readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    
    // 检测类型
    if (_isCollection(json)) {
      return _importCollection(json);
    } else if (_isEnvironment(json)) {
      return _importEnvironment(json);
    } else {
      throw ImportException(
        ImportErrorCode.unknownFormat,
        '无法识别文件格式，请确保是有效的 Postman Collection 或 Environment',
      );
    }
  }
  
  /// 导入 Collection
  Future<ImportResult> _importCollection(Map<String, dynamic> json) async {
    // 版本检测
    final version = _detectVersion(json);
    if (version == PostmanVersion.v1_0) {
      throw ImportException(
        ImportErrorCode.unsupportedVersion,
        '不支持的 Postman v1.0 格式，请升级到 v2.0+',
      );
    }
    
    final collection = PostmanCollection.fromJson(json);
    
    // 转换为 Hopp Collection
    final hoppCollection = PostmanMapper.toHoppCollection(collection);
    
    // 检查冲突
    final existing = await _collectionStorage.getCollectionByName(hoppCollection.name);
    if (existing != null) {
      return ImportResult.conflict(
        collection: hoppCollection,
        existingId: existing.id,
      );
    }
    
    // 保存
    await _collectionStorage.saveCollection(hoppCollection);
    
    return ImportResult.success(
      collectionId: hoppCollection.id,
      importedRequestCount: _countRequests(collection.item),
    );
  }
  
  /// 处理导入冲突
  Future<ImportResult> resolveConflict({
    required Collection collection,
    required ConflictResolution resolution,
    String? existingId,
  }) async {
    switch (resolution) {
      case ConflictResolution.overwrite:
        if (existingId != null) {
          await _collectionStorage.deleteCollection(existingId);
        }
        await _collectionStorage.saveCollection(collection);
        return ImportResult.success(collectionId: collection.id);
        
      case ConflictResolution.rename:
        final newName = await _generateUniqueName(collection.name);
        final renamed = collection.copyWith(name: newName);
        await _collectionStorage.saveCollection(renamed);
        return ImportResult.success(
          collectionId: renamed.id,
          renamed: true,
          newName: newName,
        );
        
      case ConflictResolution.merge:
        // 合并逻辑：保留现有，添加新请求
        final existing = await _collectionStorage.getCollection(existingId!);
        final merged = _mergeCollections(existing!, collection);
        await _collectionStorage.saveCollection(merged);
        return ImportResult.success(
          collectionId: merged.id,
          merged: true,
        );
        
      case ConflictResolution.skip:
        return ImportResult.skipped();
    }
  }
}
```

#### PostmanExportService

```dart
class PostmanExportService {
  final CollectionStorageService _collectionStorage;
  final EnvironmentStorageService _environmentStorage;
  
  /// 导出 Collection
  Future<void> exportCollection({
    required String collectionId,
    required String savePath,
    PostmanVersion version = PostmanVersion.v2_1,
    bool prettyPrint = true,
    bool includeEnvironment = false,
  }) async {
    final collection = await _collectionStorage.getCollection(collectionId);
    if (collection == null) {
      throw ExportException('Collection not found: $collectionId');
    }
    
    // 转换为 Postman 格式
    final postmanCollection = PostmanMapper.toPostmanCollection(
      collection,
      version: version,
    );
    
    // 序列化
    final json = postmanCollection.toJson();
    var jsonString = prettyPrint 
        ? const JsonEncoder.withIndent('  ').convert(json)
        : jsonEncode(json);
    
    // 写入文件
    final file = File(savePath);
    await file.writeAsString(jsonString);
    
    // 可选：导出环境变量
    if (includeEnvironment) {
      await _exportEnvironments(collectionId, savePath);
    }
  }
  
  /// 生成默认文件名
  String generateFileName(String collectionName, PostmanVersion version) {
    final sanitized = collectionName.replaceAll(RegExp(r'[^\w\s-]'), '_');
    final versionSuffix = version == PostmanVersion.v2_1 ? 'v2.1' : 'v2.0';
    return '${sanitized}_$versionSuffix.postman_collection.json';
  }
}
```

#### PostmanMapper

Body 类型映射（Postman → Hopp）：

| Postman mode | Hopp BodyType |
|--------------|---------------|
| raw | raw (支持 json/xml/html/javascript/text 子类型) |
| urlencoded | x-www-form-urlencoded |
| formdata | form-data (文本类型) |
| graphql | graphql |
| binary | binary |

```dart
class PostmanMapper {
  /// Hopp Collection → Postman Collection
  static PostmanCollection toPostmanCollection(
    Collection collection, {
    PostmanVersion version = PostmanVersion.v2_1,
  }) {
    return PostmanCollection(
      info: PostmanInfo(
        name: collection.name,
        description: collection.description ?? '',
        postmanId: _generateUuid(),
        schema: 'https://schema.getpostman.com/json/collection/${version.value}/collection.json',
      ),
      item: [
        // 映射 folders
        ...collection.folders.map(_folderToPostmanItem),
        // 映射顶层 requests
        ...collection.requests.map(_requestToPostmanItem),
      ],
    );
  }
  
  /// Postman Collection → Hopp Collection
  static Collection toHoppCollection(PostmanCollection postmanCollection) {
    return Collection(
      id: _generateId(),
      name: postmanCollection.info.name,
      description: postmanCollection.info.description,
      folders: _extractFolders(postmanCollection.item),
      requests: _extractRootRequests(postmanCollection.item),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Body 类型映射 (Postman → Hopp)
  static BodyType mapPostmanBodyMode(String mode, PostmanBodyOptions? options) {
    switch (mode) {
      case 'raw':
        return BodyType.raw;
      case 'urlencoded':
        return BodyType.formUrlEncoded;
      case 'formdata':
        return BodyType.formData;
      case 'graphql':
        return BodyType.graphql;
      case 'binary':
        return BodyType.binary;
      default:
        return BodyType.none;
    }
  }
  
  /// Raw 子类型映射
  static String? mapRawContentType(String? language) {
    switch (language) {
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
        return 'text/html';
      case 'javascript':
        return 'application/javascript';
      case 'text':
      default:
        return 'text/plain';
    }
  }
}
```

### UI 组件实现

#### ImportDialog

```dart
class ImportDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  bool _isDragging = false;
  ImportState _state = const ImportState.idle();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('导入 Postman 数据'),
      content: SizedBox(
        width: 480,
        height: 320,
        child: _buildContent(),
      ),
      actions: _buildActions(),
    );
  }
  
  Widget _buildContent() {
    return _state.when(
      idle: () => _buildDropZone(),
      loading: () => _buildLoading(),
      conflict: (collection, existingId) => ConflictResolutionDialog(
        collection: collection,
        onResolve: _handleConflictResolution,
      ),
      success: (result) => _buildSuccess(result),
      error: (message) => _buildError(message),
    );
  }
  
  Widget _buildDropZone() {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) => _handleFileDrop(details.files),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey.shade400,
            width: _isDragging ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _isDragging 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05) 
              : Colors.grey.shade50,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('拖放文件到此处或点击选择'),
              SizedBox(height: 8),
              Text(
                '支持 Postman Collection v2.0/v2.1 和 Environment',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleFileDrop(List<XFile> files) async {
    if (files.isEmpty) return;
    
    setState(() => _state = const ImportState.loading());
    
    try {
      final importService = ref.read(postmanImportServiceProvider);
      final result = await importService.importFile(files.first.path);
      
      setState(() => _state = ImportState.success(result));
    } on ImportException catch (e) {
      setState(() => _state = ImportState.error(e.message));
    }
  }
}
```

### 异常处理

```dart
/// 导入错误码
enum ImportErrorCode {
  unknownFormat,
  unsupportedVersion,
  invalidJson,
  missingRequiredField,
  fileNotFound,
  permissionDenied,
}

class ImportException implements Exception {
  final ImportErrorCode code;
  final String message;
  final dynamic details;
  
  ImportException(this.code, this.message, {this.details});
  
  @override
  String toString() => 'ImportException($code): $message';
}

class ExportException implements Exception {
  final String message;
  final dynamic details;
  
  ExportException(this.message, {this.details});
  
  @override
  String toString() => 'ExportException: $message';
}
```

### 依赖库

```yaml
dependencies:
  # 文件选择
  file_picker: ^10.3.10
  # UUID 生成
  uuid: ^4.5.3
```

---

## cURL 导入

### 技术方案

```
lib/
├── services/
│   └── curl/
│       ├── curl_parser.dart            # cURL 命令解析器 (ParsedCurlCommand)
│       ├── curl_tokenizer.dart         # 词法分析器
│       ├── curl_import_result.dart     # 导入结果模型 (CurlImportResult)
│       └── curl_import_service.dart    # 导入服务
└── widgets/
    └── import/
        └── curl_import_dialog.dart     # 导入对话框
```

### 解析器实现

#### 1. Tokenizer - 词法分析

```dart
class CurlTokenizer {
  List<CurlToken> tokenize(String command) {
    // 处理多行、转义字符、引号
    // 支持单引号、双引号、无引号参数
  }
}
```

#### 2. Parser - 语法分析

```dart
class CurlParser {
  ParsedCurlCommand parse(String command) {
    // 识别选项和参数
    // 映射到 HttpRequest 模型
  }
}
```

#### 3. 支持选项映射

| cURL 选项 | Dart 处理 |
|-----------|-----------|
| `-X POST` | `HttpMethod.post` |
| `-H "key:value"` | `KeyValuePair` 列表 |
| `-d "data"` | Body 内容 + 自动识别 Content-Type |
| `-F "key=value"` | `BodyType.formData` |
| `--data-urlencode` | URL 编码处理 |
| `-u user:pass` | Base64 编码 Authorization |
| `-k` | `validateCertificates = false` |
| `-L` | `followRedirects = true` |

### UI 组件

```dart
class CurlImportDialog extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('从 cURL 导入'),
      content: Column(
        children: [
          // 文本输入区
          TextField(
            controller: _curlController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: '粘贴 cURL 命令...',
              suffixIcon: IconButton(
                icon: Icon(Icons.paste),
                onPressed: _pasteFromClipboard,
              ),
            ),
          ),
          // 拖放区域
          DropTarget(
            onDragDone: _handleFileDrop,
            child: Container(...),
          ),
          // 解析结果预览
          if (_parsedResult != null)
            ParsedResultPreview(result: _parsedResult),
        ],
      ),
      actions: [
        TextButton(onPressed: _cancel, child: Text('取消')),
        ElevatedButton(
          onPressed: _parsedResult != null ? _import : null,
          child: Text('导入'),
        ),
        ElevatedButton(
          onPressed: _parsedResult != null ? _importAndSend : null,
          child: Text('导入并发送'),
        ),
      ],
    );
  }
}
```

### 快捷键集成

> 当前尚未实现 cURL 导入快捷键，`ImportCurlIntent` 并不存在。

### 测试示例

```dart
group('CurlParser', () {
  test('should parse simple GET request', () {
    final result = parser.parse('curl https://api.example.com/users');
    expect(result.method, HttpMethod.get);
    expect(result.url, 'https://api.example.com/users');
  });
  
  test('should parse POST with JSON body', () {
    final result = parser.parse(
      'curl -X POST -H "Content-Type: application/json" '
      '-d \'{"name":"test"}\' https://api.example.com/users'
    );
    expect(result.method, HttpMethod.post);
    expect(result.headers['Content-Type'], 'application/json');
    expect(result.body, '{"name":"test"}');
  });
  
  test('should parse multipart form data', () {
    final result = parser.parse(
      'curl -F "file=@/path/to/file.png" '
      '-F "name=avatar" https://api.example.com/upload'
    );
    expect(result.bodyType, BodyType.formData);
    expect(result.formData.length, 2);
  });
  
  test('should handle URL-encoded data', () {
    final result = parser.parse(
      'curl --data-urlencode "name=中文" https://api.example.com/search'
    );
    expect(result.body, 'name=%E4%B8%AD%E6%96%87');
  });
  
  test('should parse multiline command with backslash', () {
    final result = parser.parse(
      'curl -X POST \\\n'
      '  -H "Authorization: Bearer token" \\\n'
      '  https://api.example.com/users'
    );
    expect(result.headers['Authorization'], 'Bearer token');
  });
});
```

---

## URL 参数双向联动 (Issue #11)

**状态**: ✅ 已完成 (2026-03-18，v0.6.3)

**功能概述**:
- URL 输入 `?key=value` → 自动解析到 Params Tab
- Params Tab 修改 → 自动更新 URL
- 使用标志位防止循环更新
- 36 个单元测试覆盖

实现见 `lib/utils/url_params_sync.dart`。

> 技术债：`http_service.dart` / `postman_mapper.dart` / `curl_import_service.dart` 仍各自解析 URL 查询参数，待统一走 `url_params_sync.dart`（见 [BACKLOG](./BACKLOG.md) TD-2）。

---

## Collection 扁平化存储重构 (Issue #3)

**状态**: ✅ 已完成 (2026-03-19，v0.6.5/v0.6.6)

**问题**: 双重存储结构（`children` 嵌套与 `parentId` 并存）导致级联删除和层级显示问题。

**解决方案**: 统一使用扁平化存储结构，只使用 `parentId` 建立层级关系。

**核心改动**:
- `children` 字段保留但标记为废弃（向后兼容）
- `deleteCollection`: 通过 `parentId` 查询递归删除子集合
- `rootCollectionsProvider`: 返回根级集合

> 技术债：子孙递归收集逻辑在 `collection_provider.dart` 与 `postman_import_service.dart` 重复，见 [BACKLOG](./BACKLOG.md) TD-1。

---

## 空状态入口指引 (Issue #6)

**状态**: ✅ 已完成 (2026-03-19，v0.6.7)

**问题**: 初次使用缺少明显的创建 Request/Collection 入口。

**解决方案**:
- Sidebar 空状态添加 "Create Collection" 按钮
- 主区域空状态添加 "Create Request" 按钮
- Sidebar Header 添加可见的 "+" 按钮

> 后续演进：空态已统一为 `AppEmptyState` 组件（v0.8.8 设计系统 P4），替换响应区/侧栏/编辑区全部手写空态。

---

## 响应优化 (OptimizedResponseViewer)

大响应体虚拟化显示组件：`lib/widgets/common/optimized_response_viewer.dart`。

### 显示模式切换策略

| 响应大小 | 默认模式 | 说明 |
|---------|---------|------|
| < 10KB | Full | 完整语法高亮 |
| 10KB - 50KB | Full | 完整语法高亮 |
| > 50KB | Performance | 虚拟化列表，轻量高亮 |

### 要点

- 显示模式：Auto / Performance / Full / Raw
- 虚拟化列表：初始 500 行，支持加载更多
- Performance 模式下使用轻量级 JSON 高亮

---

## 预请求链与变量转换 (M8.2, F8 / v0.10.0, 2026-08-25)

> UI 原型先行：`docs/design/f8_prerequest_chain_preview.html`。需求与验收见 PRD F8。

### 数据模型（Hive typeId 14-18，db v4）

- `AuthConfig`(14) + `AuthType`(15)：挂在 `HttpRequest.auth`(字段 14) 与 `Collection.auth`(字段 8)。**inherit 是显式枚举值而非 null**——规避 freezed copyWith 无法置空可空字段的限制，也让 UI 的 Inherit 项直接映射。
- `PreRequestStep`(16) / `ExtractionRule`(17) / `ExtractionSourceType`(18)：挂在 `HttpRequest.preRequestChain`(15) / `preRequestRetryOn401`(16) 与 `Collection`(9/10)。
- 旧数据兼容走手写 adapter 读时补默认值（HttpRequestAdapter/CollectionAdapter），迁移函数只记日志（惯例同 v2/v3）。

### 发送链路挂载点

全部发送入口汇聚于 `RequestResponseNotifier.sendRequest`，顺序：**预请求链 → 变量解析（含本地作用域）→ Auth 应用 → 发送 →（401 且开启时）重跑链重发一次**。链失败则不发目标请求，错误呈现在响应区。

- 继承解析：请求级非空优先，否则沿 parentId 向上；Auth 的 none 显式阻断继承；链与 401 开关作为整体按层继承。
- 本地作用域：`localVariablesProvider`（StateProvider，会话级不持久化），`resolvedVariablesProvider` 合并顺序 本地 > 环境 > 全局。
- 被引用请求自身的链不递归执行（深度 1 防循环），其 Auth 正常生效。

### 变量转换管道（F8.3）

- `VariableResolver` 的占位符匹配从正则换成手写扫描器 `scanExpressions`，支持参数内嵌套一层 `{{var}}`（`hmac(sha256, {{app_secret}})`）；`extractVariables`/`findUnresolved` 取基础变量名并下钻参数。
- `VariableTransforms`：`splitPipeline` 按顶层 `|` 切分（括号内不切）；无参 md5/sha1/sha256/base64（crypto 包），带参 aes(cbc/ecb, key, iv[, base64|hex]) / hmac(md5|sha1|sha256, key)；AES key 须 UTF-8 后 16/24/32 字节；任何一步失败整体返回 null，原文保留以便 UI 标记。
- UI：URL 栏与 KV 单元格用 `VariableHighlightController` 分段着色（变量 brand / 管道 warning）；值单元格 fx 菜单合并「解析预览 + 函数插入」，带参函数弹参数小表单。

### 敏感数据落盘加密（F8.4）

`BoxEncryption`：应用级 32 字节 AES key（base64 存 Hive 目录 `.secure_key`），collections/requests/environments 三个数据 box 用 `HiveAesCipher`；存量明文 box 启动时一次性迁移（读出→删除→加密重建→写回，SharedPreferences flag 幂等）。防御边界：防直接翻看 Hive 文件，不防整机能被访问的攻击者（keychain 级方案留作后续）。

## 环境变量系统 (M8.1)

> 定位（2026-08-20 决策）：「可复用 + AI 变量注入的基础」，不是 Postman parity。AI 生成的请求引用 `{{baseUrl}}` / `{{token}}`。

### 数据模型
`lib/models/environment.dart`（Hive typeId：Environment=11 / EnvironmentVariable=12 / VariableType=13）：

```dart
@freezed
class Environment with _$Environment {
  const factory Environment({
    required String id,
    required String name,
    required List<EnvironmentVariable> variables,
    String? description,
  }) = _Environment;
}

@freezed
class EnvironmentVariable with _$EnvironmentVariable {
  const factory EnvironmentVariable({
    required String key,
    required String value,
    @Default(VariableType.string) VariableType type,
    @Default(true) bool enabled,
  }) = _EnvironmentVariable;
}

enum VariableType { string, secret }
```

### 变量替换流程

```
1. 用户发送请求前
2. 提取当前激活的 Environment
3. 扫描 URL/Headers/Body 中的 {{variable}} 占位符
4. 按优先级查找变量值 (环境 > 全局，就近原则)
5. 替换占位符为实际值
6. 发送请求 (使用替换后的值)
7. 在 Request Tab 中显示替换前后的对比
```

### 作用域与动态变量

- 优先级：环境变量 > 全局变量（就近原则）
- 动态变量：`$timestamp` / `$timestampMs` / `$isoTimestamp` / `$randomUUID` / `$randomInt`
- 解析器：`lib/services/variable_resolver.dart`

### 实现要点

- 发送前在 `RequestResponseNotifier.sendRequest` 统一应用变量替换
- `lib/utils/url_params_sync.dart` 增加占位符保护，修复 `{{var}}` 被 `Uri.parse` 百分号编码破坏的问题
- test-mode 新增 10 个环境指令（`create_environment` / `set_active_environment` / `resolve_text` / `get_resolved_request` 等）
- 验收：`integration_test/test_environment_variables.py` 9/9 通过

### UI 设计

- 环境管理对话框（`lib/widgets/environment/environment_manager_dialog.dart`）：列表 + 变量表格 + secret 掩码
- Sidebar 顶部环境切换器（`environment_switcher.dart`），持久化激活状态
- 未定义变量：切换器 + URL 栏警告图标（替代悬停预览/快速编辑）
- 后续迭代：变量输入框 `{{` 触发自动建议；已解析变量（蓝色）/ 未定义变量（红色）着色；悬停预览与双击快速编辑

---

## 测试与自动化

### 架构设计

```
lib/
├── services/
│   └── script/
│       ├── script_engine.dart          # JS 引擎封装
│       ├── pre_request_runner.dart     # Pre-request 执行器
│       ├── test_runner.dart            # Test 脚本执行器
│       └── crypto_js_bridge.dart       # CryptoJS 桥接
├── models/
│   └── test_result.dart                # 测试结果模型
└── widgets/
    └── test/
        ├── script_editor.dart          # 脚本编辑器
        ├── assertion_builder.dart      # 可视化断言构建器
        └── batch_runner_dialog.dart    # 批量运行对话框
```

### 依赖库选择

| 库名 | 用途 | 备选 |
|------|------|------|
| flutter_js | JavaScript 引擎 | quickjs_flutter |
| crypto | Dart 加密算法 | pointycastle |

---

## Mock 服务器

### 架构设计

```
lib/
├── services/
│   └── mock/
│       ├── mock_server.dart            # shelf 服务器
│       ├── mock_router.dart            # 路由匹配
│       ├── mock_response_builder.dart  # 响应构建
│       └── mock_rule_manager.dart      # 规则管理
├── models/
│   └── mock_rule.dart                  # Mock 规则模型
└── widgets/
    └── mock/
        ├── mock_config_dialog.dart     # Mock 配置对话框
        └── mock_status_panel.dart      # 运行状态面板
```

### Mock 规则示例

```json
{
  "path": "/api/user/:id",
  "method": "GET",
  "response": {
    "statusCode": 200,
    "headers": {"Content-Type": "application/json"},
    "body": {
      "id": "{{$params.id}}",
      "name": "{{$random.name}}",
      "email": "{{$random.email}}"
    }
  },
  "delay": 500
}
```

---

<p align="center">Built with ❤️ by AI · Powered by Kimi</p>
