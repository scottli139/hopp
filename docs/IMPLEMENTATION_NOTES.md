# Hopp 实现说明文档

> 本文档记录 Hopp 项目的详细技术实现方案、架构设计和代码示例。

---

## 目录

- [数据库迁移框架](#数据库迁移框架)
- [请求设置 (Request Settings)](#请求设置-request-settings)
- [Postman 导入/导出](#postman-导入导出)
- [cURL 导入](#curl-导入)
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

```
lib/
├── models/
│   └── request_settings.dart          # RequestSettings 模型定义
├── providers/
│   └── request/
│       └── request_settings_provider.dart  # 请求设置状态管理
├── widgets/
│   └── request/
│       └── request_settings_tab.dart  # Settings Tab UI
└── services/
    └── http/
        └── request_options_builder.dart   # 根据设置构建 Dio Options
```

### 已实现的设置项

| 功能项 | 类型 | 默认值 | 状态 |
|--------|------|--------|------|
| Enable SSL certificate verification | Toggle | ON | ✅ 已实现 |
| Automatically follow redirects | Toggle | ON | ✅ 已实现 |
| Maximum number of redirects | Number Input | 10 | ✅ 已实现 |

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
├── widgets/
│   └── import_export/
│       ├── import_dialog.dart               # 导入对话框
│       ├── export_dialog.dart               # 导出对话框
│       ├── conflict_resolution_dialog.dart  # 冲突处理对话框
│       └── import_progress_dialog.dart      # 导入进度对话框
└── providers/
    └── import_export/
        ├── import_provider.dart             # 导入状态管理
        └── export_provider.dart             # 导出状态管理
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
  file_picker: ^6.1.1
  # 桌面端拖放支持
  desktop_drop: ^0.4.4
  # UUID 生成
  uuid: ^4.3.3

dev_dependencies:
  # 测试数据生成
  faker: ^2.1.0
```

---

## cURL 导入

### 技术方案

```
lib/
├── services/
│   └── curl/
│       ├── curl_parser.dart            # cURL 命令解析器
│       ├── curl_tokenizer.dart         # 词法分析器
│       └── curl_import_service.dart    # 导入服务
├── models/
│   └── curl_parsed_result.dart         # 解析结果模型
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
  CurlParsedResult parse(List<CurlToken> tokens) {
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

```dart
// lib/widgets/common/shortcut_wrapper.dart
SingleActivator(LogicalKeyboardKey.keyV, meta: true, shift: true): 
    const ImportCurlIntent(),
```

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
