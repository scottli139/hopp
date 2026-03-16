/// Postman 导入服务
///
/// 处理 Postman Collection 和 Environment 的导入。
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';
import 'import_export_exception.dart';
import 'postman_mapper.dart';
import 'postman_schema.dart';

/// 导入结果
class ImportResult {
  /// 是否成功
  final bool success;

  /// 导入的集合 ID
  final String? collectionId;

  /// 导入的请求数量
  final int importedRequestCount;

  /// 是否重命名
  final bool renamed;

  /// 新名称（如果重命名）
  final String? newName;

  /// 是否合并
  final bool merged;

  /// 是否跳过
  final bool skipped;

  /// 冲突的集合（如果存在冲突）
  final Collection? conflictCollection;

  /// 现有集合 ID（如果存在冲突）
  final String? existingId;

  /// 错误信息
  final String? errorMessage;

  const ImportResult({
    required this.success,
    this.collectionId,
    this.importedRequestCount = 0,
    this.renamed = false,
    this.newName,
    this.merged = false,
    this.skipped = false,
    this.conflictCollection,
    this.existingId,
    this.errorMessage,
  });

  factory ImportResult.success({
    required String collectionId,
    required int importedRequestCount,
    bool renamed = false,
    String? newName,
    bool merged = false,
  }) =>
      ImportResult(
        success: true,
        collectionId: collectionId,
        importedRequestCount: importedRequestCount,
        renamed: renamed,
        newName: newName,
        merged: merged,
      );

  factory ImportResult.conflict({
    required Collection collection,
    required String existingId,
  }) =>
      ImportResult(
        success: false,
        conflictCollection: collection,
        existingId: existingId,
      );

  factory ImportResult.skipped() =>
      const ImportResult(success: false, skipped: true);

  factory ImportResult.error(String message) =>
      ImportResult(success: false, errorMessage: message);
}

/// Postman 导入服务
class PostmanImportService with LogMixin {
  final StorageService _storage;

  PostmanImportService(this._storage);

  /// 导入文件，自动检测类型
  Future<ImportResult> importFile(String filePath) async {
    logInfo('Importing file: $filePath');

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const ImportException(
          code: ImportErrorCode.fileNotFound,
          message: '文件不存在',
        );
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 检测类型
      if (_isCollection(json)) {
        return importCollection(content);
      } else if (_isEnvironment(json)) {
        return importEnvironment(content);
      } else {
        throw const ImportException(
          code: ImportErrorCode.unknownFormat,
          message: '无法识别文件格式，请确保是有效的 Postman Collection 或 Environment',
        );
      }
    } on ImportException {
      rethrow;
    } catch (e, stack) {
      logError('Import failed', e, stack);
      throw ImportException(
        code: ImportErrorCode.unknown,
        message: '导入失败: $e',
        details: stack,
      );
    }
  }

  /// 导入 Collection
  Future<ImportResult> importCollection(String json) async {
    logInfo('Importing collection...');

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;

      // 版本检测
      final version = _detectVersion(map);
      if (version == PostmanVersion.v2_0) {
        logWarning('Importing v2.0 collection, converting to v2.1 format');
      }

      // 解析集合
      final collection = PostmanCollection.fromJson(map);

      // 检查是否为空
      if (collection.item.isEmpty) {
        throw const ImportException(
          code: ImportErrorCode.emptyCollection,
          message: '导入的集合不包含任何请求',
        );
      }

      // 转换为 Hopp 模型
      final hoppCollection = PostmanMapper.toHoppCollection(collection);

      // 检查冲突
      final existing = await _findExistingCollection(hoppCollection.name);
      if (existing != null) {
        logInfo('Collection with same name exists: ${hoppCollection.name}');
        return ImportResult.conflict(
          collection: hoppCollection,
          existingId: existing.id,
        );
      }

      // 保存集合
      await _storage.saveCollection(hoppCollection);

      // 保存所有请求
      await _saveRequestsRecursively(hoppCollection);

      logInfo('Collection imported successfully: ${hoppCollection.id}');

      return ImportResult.success(
        collectionId: hoppCollection.id,
        importedRequestCount: _countRequests(collection.item),
      );
    } on ImportException {
      rethrow;
    } catch (e, stack) {
      logError('Failed to import collection', e, stack);
      throw ImportException(
        code: ImportErrorCode.invalidJson,
        message: '无法解析 JSON 文件: $e',
      );
    }
  }

  /// 导入 Environment
  Future<ImportResult> importEnvironment(String json) async {
    logInfo('Importing environment...');

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final environment = PostmanEnvironment.fromJson(map);

      // 注意：目前 Hopp 还没有 Environment 模型，这里仅做解析演示
      // 后续需要实现 Environment 的存储
      logInfo('Environment parsed: ${environment.name}');
      logWarning('Environment import not fully implemented yet');

      return ImportResult.success(
        collectionId: '',
        importedRequestCount: environment.values?.length ?? 0,
      );
    } catch (e, stack) {
      logError('Failed to import environment', e, stack);
      throw ImportException(
        code: ImportErrorCode.invalidJson,
        message: '无法解析 Environment 文件: $e',
      );
    }
  }

  /// 解决导入冲突
  Future<ImportResult> resolveConflict({
    required Collection collection,
    required ConflictResolution resolution,
    String? existingId,
  }) async {
    logInfo('Resolving conflict with strategy: ${resolution.name}');

    switch (resolution) {
      case ConflictResolution.overwrite:
        return _overwriteCollection(collection, existingId);
      case ConflictResolution.rename:
        return _renameAndImport(collection);
      case ConflictResolution.merge:
        return _mergeCollections(collection, existingId);
      case ConflictResolution.skip:
        return ImportResult.skipped();
    }
  }

  /// 覆盖现有集合
  Future<ImportResult> _overwriteCollection(
    Collection collection,
    String? existingId,
  ) async {
    logInfo('Overwriting collection: ${collection.name}');

    if (existingId != null) {
      await _storage.deleteCollection(existingId);
    }

    await _storage.saveCollection(collection);
    await _saveRequestsRecursively(collection);

    return ImportResult.success(
      collectionId: collection.id,
      importedRequestCount: _countHoppRequests(collection),
    );
  }

  /// 重命名并导入
  Future<ImportResult> _renameAndImport(Collection collection) async {
    final newName = await _generateUniqueName(collection.name);
    final renamed = collection.copyWith(name: newName);

    logInfo('Renaming and importing: $newName');

    await _storage.saveCollection(renamed);
    await _saveRequestsRecursively(renamed);

    return ImportResult.success(
      collectionId: renamed.id,
      importedRequestCount: _countHoppRequests(renamed),
      renamed: true,
      newName: newName,
    );
  }

  /// 合并集合
  Future<ImportResult> _mergeCollections(
    Collection newCollection,
    String? existingId,
  ) async {
    if (existingId == null) {
      return ImportResult.error('无法找到现有集合');
    }

    final existing = await _storage.getCollection(existingId);
    if (existing == null) {
      return ImportResult.error('现有集合不存在');
    }

    logInfo('Merging collections: ${existing.name}');

    // 合并请求：保留现有，添加新的
    final merged = existing.copyWith(
      requests: [...existing.requests, ...newCollection.requests],
      children: [...existing.children, ...newCollection.children],
    );

    await _storage.saveCollection(merged);
    await _saveRequestsRecursively(merged);

    return ImportResult.success(
      collectionId: merged.id,
      importedRequestCount: _countHoppRequests(newCollection),
      merged: true,
    );
  }

  /// 递归保存所有请求（子集合只作为嵌套对象，不单独保存）
  Future<void> _saveRequestsRecursively(Collection collection,
      {bool isTopLevel = true}) async {
    // 只有顶层集合才保存到 storage
    if (isTopLevel) {
      await _storage.saveCollection(collection);
    }

    // 保存当前集合的请求
    for (final request in collection.requests) {
      await _storage.saveRequest(request);
    }

    // 递归处理子集合（不单独保存）
    for (final child in collection.children) {
      await _saveRequestsRecursively(child, isTopLevel: false);
    }
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

  /// 生成唯一名称
  Future<String> _generateUniqueName(String baseName) async {
    final collections = await _storage.getCollections();
    final names = collections.map((c) => c.name).toSet();

    if (!names.contains(baseName)) {
      return baseName;
    }

    var counter = 1;
    while (true) {
      final newName = '$baseName ($counter)';
      if (!names.contains(newName)) {
        return newName;
      }
      counter++;
    }
  }

  /// 检测是否为 Collection
  bool _isCollection(Map<String, dynamic> json) {
    return json.containsKey('info') &&
        json['info'] is Map &&
        json.containsKey('item') &&
        json['item'] is List;
  }

  /// 检测是否为 Environment
  bool _isEnvironment(Map<String, dynamic> json) {
    return json.containsKey('values') &&
        json['values'] is List &&
        json.containsKey('_postman_variable_scope');
  }

  /// 检测版本
  PostmanVersion _detectVersion(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>?;
    if (info == null) return PostmanVersion.v2_1;

    final schema = info['schema'] as String? ?? '';
    if (schema.contains('v2.0')) {
      return PostmanVersion.v2_0;
    }
    if (schema.contains('v1.0') || schema.contains('/v1/')) {
      throw const ImportException(
        code: ImportErrorCode.unsupportedVersion,
        message: '不支持的 Postman Collection 版本: v1.0。请升级到 v2.0 或 v2.1 格式',
      );
    }
    return PostmanVersion.v2_1;
  }

  /// 计算 Postman 请求数量
  int _countRequests(List<PostmanItem> items) {
    var count = 0;
    for (final item in items) {
      if (item.isRequest) {
        count++;
      } else if (item.isFolder) {
        count += _countRequests(item.item ?? []);
      }
    }
    return count;
  }

  /// 计算 Hopp 请求数量
  int _countHoppRequests(Collection collection) {
    var count = collection.requests.length;
    for (final child in collection.children) {
      count += _countHoppRequests(child);
    }
    return count;
  }
}
