/// OpenAPI/Swagger 导入服务
///
/// 编排「解析 → 映射 → 落盘」流程：冲突检测复用
/// [PostmanImportService.resolveConflict]（格式无关），并在导入成功后
/// 将 servers[0].url upsert 为全局变量 baseUrl。
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/l10n.dart';
import '../../../models/collection.dart';
import '../../../models/environment.dart';
import '../../../models/http_request.dart';
import '../../../services/storage_service.dart';
import '../../../utils/app_logger.dart';
import '../import_export_exception.dart';
import '../postman_import_service.dart';
import 'openapi_mapper.dart';
import 'openapi_parser.dart';
import 'openapi_spec.dart';

/// 导入状态
enum OpenApiImportStatus {
  /// 成功
  success,

  /// 存在同名集合，等待用户决策
  conflict,

  /// 用户跳过
  skipped,
}

/// 导入结果
class OpenApiImportOutcome {
  const OpenApiImportOutcome._({
    required this.status,
    this.report,
    this.conflictCollection,
    this.existingId,
    this.childCollections,
    this.allRequests,
  });

  /// 成功
  factory OpenApiImportOutcome.success(OpenApiReport report) =>
      OpenApiImportOutcome._(
        status: OpenApiImportStatus.success,
        report: report,
      );

  /// 冲突
  factory OpenApiImportOutcome.conflict({
    required Collection collection,
    required String existingId,
    required List<Collection> childCollections,
    required List<HttpRequest> allRequests,
    OpenApiReport? report,
  }) =>
      OpenApiImportOutcome._(
        status: OpenApiImportStatus.conflict,
        report: report,
        conflictCollection: collection,
        existingId: existingId,
        childCollections: childCollections,
        allRequests: allRequests,
      );

  /// 跳过
  factory OpenApiImportOutcome.skipped() =>
      const OpenApiImportOutcome._(status: OpenApiImportStatus.skipped);

  /// 状态
  final OpenApiImportStatus status;

  /// 导入报告（success 时必有；conflict 时附带预填数据，
  /// 供用户在解决冲突后回传给 [OpenApiImportService.resolveConflict]）
  final OpenApiReport? report;

  /// 冲突的新集合（未保存）
  final Collection? conflictCollection;

  /// 已存在的同名集合 ID
  final String? existingId;

  /// 冲突时的子集合列表（扁平化存储）
  final List<Collection>? childCollections;

  /// 冲突时的所有请求列表
  final List<HttpRequest>? allRequests;
}

/// 导入报告
class OpenApiReport {
  /// 导入报告
  const OpenApiReport({
    required this.collectionId,
    required this.collectionName,
    required this.requestCount,
    required this.collectionCount,
    this.renamed = false,
    this.newName,
    this.merged = false,
    this.placeholders = const [],
    this.oauthNotices = const [],
    this.baseUrl,
    this.baseUrlExisted = false,
    this.authDescription,
  });

  /// 导入的集合 ID
  final String collectionId;

  /// 集合名称（重命名后为新名称）
  final String collectionName;

  /// 导入的请求数量
  final int requestCount;

  /// 导入的子集合数量
  final int collectionCount;

  /// 是否重命名
  final bool renamed;

  /// 新名称（如果重命名）
  final String? newName;

  /// 是否合并
  final bool merged;

  /// 需用户补全的占位说明
  final List<ImportPlaceholder> placeholders;

  /// 需手动配置的 OAuth2 / OpenID Connect scheme 名
  final List<String> oauthNotices;

  /// 写入全局变量 baseUrl 的值（无 servers 时为 null）
  final String? baseUrl;

  /// baseUrl 全局变量是否已存在（true = 更新既有值）
  final bool baseUrlExisted;

  /// 认证配置描述（无认证为 null）
  final String? authDescription;
}

/// OpenAPI/Swagger 导入服务
class OpenApiImportService with LogMixin {
  final StorageService _storage;
  final OpenApiParser _parser;
  final OpenApiMapper _mapper;

  static const _uuid = Uuid();

  OpenApiImportService(
    this._storage, {
    OpenApiParser? parser,
    OpenApiMapper? mapper,
  })  : _parser = parser ?? OpenApiParser(),
        _mapper = mapper ?? OpenApiMapper();

  /// 从 URL 拉取并解析文档
  ///
  /// 可选单个自定义 header（如鉴权）。非 2xx / 网络错误抛
  /// [ImportException]（unknown）。
  Future<OpenApiSpec> fetchFromUrl(
    String url, {
    String? headerName,
    String? headerValue,
  }) async {
    logInfo('Fetching OpenAPI spec from URL: $url');

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    try {
      final response = await dio.get<String>(
        url,
        options: headerName != null && headerName.isNotEmpty
            ? Options(headers: {headerName: headerValue ?? ''})
            : null,
      );
      final data = response.data;
      if (data == null || data.trim().isEmpty) {
        throw ImportException(
          code: ImportErrorCode.unknown,
          message: L10nBridge.t.openapi_fetchEmpty,
        );
      }
      return _parser.parse(data);
    } on ImportException {
      rethrow;
    } on DioException catch (e) {
      logError('Failed to fetch OpenAPI spec', e);
      throw ImportException(
        code: ImportErrorCode.unknown,
        message: L10nBridge.t.openapi_fetchFailed('${e.message ?? e}'),
      );
    }
  }

  /// 读取本地文件内容
  Future<String> readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ImportException(
        code: ImportErrorCode.fileNotFound,
        message: L10nBridge.t.import_fileNotFound,
      );
    }
    return file.readAsString();
  }

  /// 导入文档（filePath / url / content 三选一）
  ///
  /// 空文档抛 [ImportException]（emptyCollection）；同名集合已存在时返回
  /// conflict outcome，之后调用 [resolveConflict] 完成导入。
  Future<OpenApiImportOutcome> importSpec({
    String? filePath,
    String? url,
    String? headerName,
    String? headerValue,
    String? content,
    Set<String>? selectedOpIds,
  }) async {
    logInfo('Importing OpenAPI spec...');

    final spec = await _loadSpec(
      filePath: filePath,
      url: url,
      headerName: headerName,
      headerValue: headerValue,
      content: content,
    );

    if (spec.operations.isEmpty) {
      throw ImportException(
        code: ImportErrorCode.emptyCollection,
        message: L10nBridge.t.openapi_noOperations,
      );
    }

    final mapResult = _mapper.toHopp(spec, selectedOpIds: selectedOpIds);
    final root = mapResult.rootCollection;

    // 检查冲突
    final existing = await _findExistingCollection(root.name);
    if (existing != null) {
      logInfo('Collection with same name exists: ${root.name}');
      return OpenApiImportOutcome.conflict(
        collection: root,
        existingId: existing.id,
        childCollections: mapResult.childCollections,
        allRequests: mapResult.allRequests,
        report: _buildReport(mapResult),
      );
    }

    // 保存
    await _saveAll(root, mapResult.childCollections, mapResult.allRequests);
    final baseUrlExisted = await _upsertBaseUrl(mapResult.baseUrl);

    logInfo(
      'OpenAPI spec imported: ${root.id} '
      '(${mapResult.allRequests.length} requests, '
      '${mapResult.childCollections.length} collections)',
    );

    return OpenApiImportOutcome.success(
      _buildReport(mapResult, baseUrlExisted: baseUrlExisted),
    );
  }

  /// 解决导入冲突（委托 PostmanImportService，格式无关）
  ///
  /// 成功后同样 upsert 全局变量 baseUrl。
  Future<OpenApiImportOutcome> resolveConflict({
    required ConflictResolution resolution,
    required Collection collection,
    String? existingId,
    List<Collection>? childCollections,
    List<HttpRequest>? allRequests,
    String? baseUrl,
    List<ImportPlaceholder> placeholders = const [],
    List<String> oauthNotices = const [],
    String? authDescription,
  }) async {
    logInfo('Resolving OpenAPI import conflict: ${resolution.name}');

    final result = await PostmanImportService(_storage).resolveConflict(
      collection: collection,
      resolution: resolution,
      existingId: existingId,
      childCollections: childCollections,
      allRequests: allRequests,
    );

    if (result.skipped) {
      return OpenApiImportOutcome.skipped();
    }
    if (!result.success) {
      throw ImportException(
        code: ImportErrorCode.unknown,
        message:
            result.errorMessage ?? L10nBridge.t.openapi_conflictResolveFailed,
      );
    }

    final baseUrlExisted = await _upsertBaseUrl(baseUrl);

    return OpenApiImportOutcome.success(
      OpenApiReport(
        collectionId: result.collectionId ?? collection.id,
        collectionName: result.newName ?? collection.name,
        requestCount: result.importedRequestCount,
        collectionCount: (childCollections ?? []).length,
        renamed: result.renamed,
        newName: result.newName,
        merged: result.merged,
        placeholders: placeholders,
        oauthNotices: oauthNotices,
        baseUrl: baseUrl,
        baseUrlExisted: baseUrlExisted,
        authDescription: authDescription,
      ),
    );
  }

  // ==================== 内部方法 ====================

  /// 取内容并解析（三选一）
  Future<OpenApiSpec> _loadSpec({
    String? filePath,
    String? url,
    String? headerName,
    String? headerValue,
    String? content,
  }) async {
    if (content != null) {
      return _parser.parse(content);
    }
    if (filePath != null) {
      return _parser.parse(await readFile(filePath));
    }
    if (url != null) {
      return fetchFromUrl(url,
          headerName: headerName, headerValue: headerValue);
    }
    throw ImportException(
      code: ImportErrorCode.unknownFormat,
      message: L10nBridge.t.openapi_noSource,
    );
  }

  /// 保存根集合、子集合与所有请求
  Future<void> _saveAll(
    Collection root,
    List<Collection> children,
    List<HttpRequest> requests,
  ) async {
    await _storage.saveCollection(root);
    for (final child in children) {
      await _storage.saveCollection(child);
    }
    for (final request in requests) {
      await _storage.saveRequest(request);
    }
  }

  /// upsert 全局变量 baseUrl；返回是否已存在（更新而非新增）
  Future<bool> _upsertBaseUrl(String? baseUrl) async {
    if (baseUrl == null || baseUrl.isEmpty) {
      return false;
    }
    final globals =
        List<EnvironmentVariable>.of(await _storage.getGlobalVariables());
    final index = globals.indexWhere((v) => v.key == 'baseUrl');
    if (index >= 0) {
      globals[index] = globals[index].copyWith(value: baseUrl);
      await _storage.saveGlobalVariables(globals);
      logInfo('Updated existing global variable: baseUrl');
      return true;
    }
    globals.add(
      EnvironmentVariable(
        id: _uuid.v4(),
        key: 'baseUrl',
        value: baseUrl,
      ),
    );
    await _storage.saveGlobalVariables(globals);
    logInfo('Added global variable: baseUrl');
    return false;
  }

  /// 查找同名集合
  Future<Collection?> _findExistingCollection(String name) async {
    final collections = await _storage.getCollections();
    for (final collection in collections) {
      if (collection.name == name) {
        return collection;
      }
    }
    return null;
  }

  /// 构建导入报告
  OpenApiReport _buildReport(
    OpenApiMapResult mapResult, {
    bool baseUrlExisted = false,
  }) {
    return OpenApiReport(
      collectionId: mapResult.rootCollection.id,
      collectionName: mapResult.rootCollection.name,
      requestCount: mapResult.allRequests.length,
      collectionCount: mapResult.childCollections.length,
      placeholders: mapResult.placeholders,
      oauthNotices: mapResult.oauthNotices,
      baseUrl: mapResult.baseUrl,
      baseUrlExisted: baseUrlExisted,
      authDescription: mapResult.authDescription,
    );
  }
}
