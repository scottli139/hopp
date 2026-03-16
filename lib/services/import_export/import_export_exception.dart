/// 导入/导出异常定义
///
/// 定义导入导出过程中可能发生的错误类型和异常。
library;

/// 导入错误码
enum ImportErrorCode {
  /// 未知格式
  unknownFormat,

  /// 不支持的版本
  unsupportedVersion,

  /// 无效的 JSON
  invalidJson,

  /// 缺少必填字段
  missingRequiredField,

  /// 文件未找到
  fileNotFound,

  /// 权限被拒绝
  permissionDenied,

  /// 集合为空
  emptyCollection,

  /// 其他错误
  unknown,
}

/// 导入异常
class ImportException implements Exception {
  /// 错误码
  final ImportErrorCode code;

  /// 错误信息
  final String message;

  /// 详细信息
  final dynamic details;

  const ImportException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ImportException(${code.name}): $message';
}

/// 导出异常
class ExportException implements Exception {
  /// 错误信息
  final String message;

  /// 详细信息
  final dynamic details;

  const ExportException({
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ExportException: $message';
}

/// 冲突解决策略
enum ConflictResolution {
  /// 覆盖现有集合
  overwrite,

  /// 重命名导入
  rename,

  /// 合并集合
  merge,

  /// 跳过
  skip,
}
