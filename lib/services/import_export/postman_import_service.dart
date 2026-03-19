/// Postman 导入服务
///
/// 处理 Postman Collection 和 Environment 的导入。
library;

import 'dart:convert';
import 'dart:io';

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

  /// 冲突时的子集合列表（扁平化存储）
  final List<Collection>? childCollections;

  /// 冲突时的所有请求列表
  final List<HttpRequest>? allRequests;

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
    this.childCollections,
    this.allRequests,
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
    List<Collection>? childCollections,
    List<HttpRequest>? allRequests,
  }) =>
      ImportResult(
        success: false,
        conflictCollection: collection,
        existingId: existingId,
        childCollections: childCollections,
        allRequests: allRequests,
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

  /// 导入 Collection（扁平化存储）
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

      // 转换为扁平化的 Hopp 模型
      final (rootCollection, childCollections, allRequests) =
          PostmanMapper.toHoppCollectionFlat(collection);

      // 检查冲突
      final existing = await _findExistingCollection(rootCollection.name);
      if (existing != null) {
        logInfo('Collection with same name exists: ${rootCollection.name}');
        // 将扁平化数据存储到 ImportResult 以便后续处理
        return ImportResult.conflict(
          collection: rootCollection,
          existingId: existing.id,
          childCollections: childCollections,
          allRequests: allRequests,
        );
      }

      // 保存根集合
      await _storage.saveCollection(rootCollection);

      // 保存所有子集合
      for (final child in childCollections) {
        await _storage.saveCollection(child);
      }

      // 保存所有请求
      for (final request in allRequests) {
        await _storage.saveRequest(request);
      }

      logInfo('Collection imported successfully: ${rootCollection.id}');

      return ImportResult.success(
        collectionId: rootCollection.id,
        importedRequestCount: allRequests.length,
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
    List<Collection>? childCollections,
    List<HttpRequest>? allRequests,
  }) async {
    logInfo('Resolving conflict with strategy: ${resolution.name}');

    switch (resolution) {
      case ConflictResolution.overwrite:
        return _overwriteCollection(
          collection,
          existingId,
          childCollections: childCollections,
          allRequests: allRequests,
        );
      case ConflictResolution.rename:
        return _renameAndImport(
          collection,
          childCollections: childCollections,
          allRequests: allRequests,
        );
      case ConflictResolution.merge:
        return _mergeCollections(
          collection,
          existingId,
          childCollections: childCollections,
          allRequests: allRequests,
        );
      case ConflictResolution.skip:
        return ImportResult.skipped();
    }
  }

  /// 覆盖现有集合（扁平化存储）
  Future<ImportResult> _overwriteCollection(
    Collection collection,
    String? existingId, {
    List<Collection>? childCollections,
    List<HttpRequest>? allRequests,
  }) async {
    logInfo('Overwriting collection: ${collection.name}');

    // 获取所有子集合的 ID 用于级联删除
    final allChildIds = <String>[];
    if (existingId != null) {
      final allCollections = await _storage.getCollections();
      _collectAllChildIds(existingId, allCollections, allChildIds);

      // 删除现有集合及其所有子集合
      await _storage.deleteCollection(existingId);
      for (final childId in allChildIds) {
        await _storage.deleteCollection(childId);
      }
    }

    // 保存新的根集合
    await _storage.saveCollection(collection);

    // 保存所有子集合
    final children = childCollections ?? [];
    for (final child in children) {
      await _storage.saveCollection(child);
    }

    // 保存所有请求
    final requests = allRequests ?? [];
    for (final request in requests) {
      await _storage.saveRequest(request);
    }

    return ImportResult.success(
      collectionId: collection.id,
      importedRequestCount: requests.length,
    );
  }

  /// 收集所有子集合 ID
  void _collectAllChildIds(
    String parentId,
    List<Collection> allCollections,
    List<String> result,
  ) {
    final children =
        allCollections.where((c) => c.parentId == parentId).toList();
    for (final child in children) {
      result.add(child.id);
      _collectAllChildIds(child.id, allCollections, result);
    }
  }

  /// 重命名并导入（扁平化存储）
  Future<ImportResult> _renameAndImport(
    Collection collection, {
    List<Collection>? childCollections,
    List<HttpRequest>? allRequests,
  }) async {
    final newName = await _generateUniqueName(collection.name);

    // 更新根集合名称
    final renamedRoot = collection.copyWith(name: newName);

    // 为子集合更新 parentId（因为根集合 ID 已改变）
    final originalRootId = collection.id;
    final newRootId = renamedRoot.id;

    final renamedChildren = (childCollections ?? []).map((child) {
      if (child.parentId == originalRootId) {
        return child.copyWith(parentId: newRootId);
      }
      return child;
    }).toList();

    // 更新所有请求的 collectionId
    final updatedRequests = (allRequests ?? []).map((request) {
      if (request.parentId == originalRootId) {
        return request.copyWith(parentId: newRootId);
      }
      return request;
    }).toList();

    logInfo('Renaming and importing: $newName');

    // 保存根集合
    await _storage.saveCollection(renamedRoot);

    // 保存所有子集合
    for (final child in renamedChildren) {
      await _storage.saveCollection(child);
    }

    // 保存所有请求
    for (final request in updatedRequests) {
      await _storage.saveRequest(request);
    }

    return ImportResult.success(
      collectionId: renamedRoot.id,
      importedRequestCount: updatedRequests.length,
      renamed: true,
      newName: newName,
    );
  }

  /// 合并集合（扁平化存储）
  Future<ImportResult> _mergeCollections(
    Collection newCollection,
    String? existingId, {
    List<Collection>? childCollections,
    List<HttpRequest>? allRequests,
  }) async {
    if (existingId == null) {
      return ImportResult.error('无法找到现有集合');
    }

    final existing = await _storage.getCollection(existingId);
    if (existing == null) {
      return ImportResult.error('现有集合不存在');
    }

    logInfo('Merging collections: ${existing.name}');

    // 为新请求更新 collectionId
    final requestsToAdd = (allRequests ?? []).map((request) {
      if (request.parentId == newCollection.id) {
        return request.copyWith(parentId: existingId);
      }
      return request;
    }).toList();

    // 为子集合更新 parentId
    final childrenToAdd = (childCollections ?? []).map((child) {
      if (child.parentId == newCollection.id) {
        return child.copyWith(parentId: existingId);
      }
      return child;
    }).toList();

    // 更新现有集合
    final merged = existing.copyWith(
      requests: [...existing.requests, ...requestsToAdd],
    );
    await _storage.saveCollection(merged);

    // 添加所有子集合
    for (final child in childrenToAdd) {
      await _storage.saveCollection(child);
    }

    // 保存所有请求
    for (final request in requestsToAdd) {
      await _storage.saveRequest(request);
    }

    return ImportResult.success(
      collectionId: existingId,
      importedRequestCount: requestsToAdd.length,
      merged: true,
    );
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

}
