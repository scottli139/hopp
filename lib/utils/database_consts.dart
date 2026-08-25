/// 数据库常量定义
///
/// 定义数据库版本控制、迁移相关的常量。
///
/// 使用示例：
/// ```dart
/// import 'package:hopp/utils/database_consts.dart';
///
/// final version = DatabaseConsts.currentDbVersion;
/// ```
library;

/// 数据库版本常量
class DatabaseConsts {
  DatabaseConsts._();

  /// 当前数据库版本号
  ///
  /// 版本历史：
  /// - v1: 初始版本，包含基础模型 (HttpRequest 字段 0-10)
  /// - v2: 添加 validateCertificates 字段到 HttpRequest，添加更多字段到 AppSettings
  /// - v3: HttpRequest 添加 auth 字段（索引 14），Collection 添加 auth 字段（索引 8）—— F8.1 认证配置
  /// - v4: HttpRequest 添加 preRequestChain/preRequestRetryOn401（索引 15/16），
  ///       Collection 添加 preRequestChain/preRequestRetryOn401（索引 9/10）—— F8.2 预请求链
  static const int currentDbVersion = 4;

  /// SharedPreferences 中存储数据库版本的 key
  static const String dbVersionKey = 'hopp_db_version';

  /// 数据库备份文件后缀
  static const String backupSuffix = '.backup';

  /// 迁移日志 key 前缀
  static const String migrationLogPrefix = 'hopp_migration_';
}

/// 数据库迁移错误码
enum MigrationErrorCode {
  /// 未知错误
  unknown,

  /// 数据损坏
  dataCorrupted,

  /// 磁盘空间不足
  insufficientStorage,

  /// 权限错误
  permissionDenied,

  /// 备份失败
  backupFailed,

  /// 迁移被用户取消
  userCancelled,
}

/// 迁移异常
class MigrationException implements Exception {
  /// 错误码
  final MigrationErrorCode code;

  /// 错误信息
  final String message;

  /// 原始异常（如果有）
  final Object? originalError;

  /// 构造函数
  const MigrationException(
    this.code,
    this.message, {
    this.originalError,
  });

  @override
  String toString() => 'MigrationException(${code.name}): $message';
}
