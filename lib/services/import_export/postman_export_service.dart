/// Postman 导出服务
///
/// 处理 Hopp Collection 导出为 Postman 格式。
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../models/collection.dart';
import '../../utils/app_logger.dart';
import 'import_export_exception.dart';
import 'postman_mapper.dart';
import 'postman_schema.dart';

/// 导出选项
class ExportOptions {
  /// 格式版本
  final PostmanVersion version;

  /// 美化输出
  final bool prettyPrint;

  /// 包含环境变量
  final bool includeEnvironment;

  const ExportOptions({
    this.version = PostmanVersion.v2_1,
    this.prettyPrint = true,
    this.includeEnvironment = false,
  });
}

/// Postman 导出服务
class PostmanExportService with LogMixin {
  final StorageService _storage;

  PostmanExportService(this._storage);

  /// 导出 Collection 到文件
  Future<String> exportCollection({
    required String collectionId,
    required String savePath,
    ExportOptions options = const ExportOptions(),
  }) async {
    logInfo('Exporting collection: $collectionId to $savePath');

    try {
      // 获取集合
      final collection = await _storage.getCollection(collectionId);
      if (collection == null) {
        throw ExportException(
          message: 'Collection not found: $collectionId',
        );
      }

      // 转换为 Postman 格式
      final postmanCollection = PostmanMapper.toPostmanCollection(
        collection,
        version: options.version,
      );

      // 序列化 JSON
      final json = postmanCollection.toJson();
      String jsonString;
      if (options.prettyPrint) {
        jsonString = const JsonEncoder.withIndent('  ').convert(json);
      } else {
        jsonString = jsonEncode(json);
      }

      // 写入文件
      final file = File(savePath);
      await file.writeAsString(jsonString);

      logInfo('Collection exported successfully: $savePath');

      return savePath;
    } on ExportException {
      rethrow;
    } catch (e, stack) {
      logError('Export failed', e, stack);
      throw ExportException(
        message: '导出失败: $e',
        details: stack,
      );
    }
  }

  /// 导出集合并自动选择保存路径
  Future<String> exportCollectionToDefaultPath({
    required String collectionId,
    String? basePath,
    ExportOptions options = const ExportOptions(),
  }) async {
    final collection = await _storage.getCollection(collectionId);
    if (collection == null) {
      throw ExportException(
        message: 'Collection not found: $collectionId',
      );
    }

    final fileName = generateFileName(collection.name, options.version);
    final savePath = basePath != null
        ? path.join(basePath, fileName)
        : path.join(_getDefaultExportPath(), fileName);

    return exportCollection(
      collectionId: collectionId,
      savePath: savePath,
      options: options,
    );
  }

  /// 生成文件名
  String generateFileName(String collectionName, PostmanVersion version) {
    // 清理名称，移除非法字符
    final sanitized =
        collectionName.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();

    final versionSuffix = version == PostmanVersion.v2_1 ? 'v2.1' : 'v2.0';
    return '${sanitized}_$versionSuffix.postman_collection.json';
  }

  /// 获取默认导出路径（用户下载目录）
  String _getDefaultExportPath() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return path.join(home, 'Downloads');
  }

  /// 验证导出文件
  Future<bool> validateExport(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 验证基本结构
      if (!json.containsKey('info') || !json.containsKey('item')) {
        return false;
      }

      final info = json['info'] as Map<String, dynamic>;
      if (!info.containsKey('name') || !info.containsKey('schema')) {
        return false;
      }

      return true;
    } catch (e) {
      logError('Export validation failed', e);
      return false;
    }
  }
}
