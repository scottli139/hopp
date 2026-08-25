import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../utils/database_consts.dart';

/// 数据库迁移服务
///
/// 管理数据库版本控制和自动迁移。
///
/// 使用示例：
/// ```dart
/// final migrationService = DatabaseMigrationService(prefs);
/// await migrationService.migrateIfNeeded();
/// ```
class DatabaseMigrationService with LogMixin {
  final SharedPreferences _prefs;

  /// 构造函数
  DatabaseMigrationService(this._prefs);

  /// 检查并执行必要的迁移
  ///
  /// 在应用启动时调用此方法，确保数据库结构是最新的。
  /// 如果当前版本低于目标版本，会依次执行所有需要的迁移。
  Future<void> migrateIfNeeded() async {
    try {
      final currentVersion = _getCurrentVersion();
      final targetVersion = DatabaseConsts.currentDbVersion;

      logInfo(
        'Database version check: current=$currentVersion, target=$targetVersion',
      );

      if (currentVersion < targetVersion) {
        logInfo(
          'Migration required from v$currentVersion to v$targetVersion',
        );
        await _runMigration(currentVersion, targetVersion);
        await _setVersion(targetVersion);
        logInfo('Migration completed successfully');
      } else {
        logDebug('No migration needed');
      }
    } catch (e, stack) {
      logError('Migration failed', e, stack);
      // 迁移失败不阻止应用启动，适配器会处理向后兼容
      // 但会记录错误供后续排查
    }
  }

  /// 获取当前数据库版本
  ///
  /// 如果没有记录过版本号，返回 1（初始版本）
  int _getCurrentVersion() {
    return _prefs.getInt(DatabaseConsts.dbVersionKey) ?? 1;
  }

  /// 设置数据库版本
  Future<void> _setVersion(int version) async {
    await _prefs.setInt(DatabaseConsts.dbVersionKey, version);
    logDebug('Database version updated to $version');
  }

  /// 执行迁移
  ///
  /// 从 [fromVersion] 迁移到 [toVersion]，依次执行每个版本的迁移
  Future<void> _runMigration(int fromVersion, int toVersion) async {
    for (var version = fromVersion; version < toVersion; version++) {
      final nextVersion = version + 1;
      logInfo('Running migration from v$version to v$nextVersion');
      await _migrateToVersion(nextVersion);
      logInfo('Migration to v$nextVersion completed');
    }
  }

  /// 迁移到指定版本
  ///
  /// 每个版本的迁移逻辑都在这里实现。
  /// 注意：实际的字段默认值由自定义适配器处理，这里主要处理结构性变更。
  Future<void> _migrateToVersion(int version) async {
    switch (version) {
      case 2:
        await _migrateToV2();
        break;
      case 3:
        await _migrateToV3();
        break;
      case 4:
        await _migrateToV4();
        break;
      // 未来版本在这里添加 case
      default:
        logWarning('Unknown migration version: $version');
    }
  }

  /// 迁移到 v2
  ///
  /// v2 变更：
  /// - HttpRequest 添加 validateCertificates 字段（字段索引 11）
  /// - AppSettings 添加多个配置字段
  ///
  /// 注意：由于 Hive 是 schema-less 的，旧数据在读取时会由
  /// 自定义适配器自动处理缺失字段，提供默认值。
  /// 这里主要用于记录迁移日志和未来可能的结构性变更。
  Future<void> _migrateToV2() async {
    logInfo('Migrating to v2: Adding validateCertificates field support');

    // v2 的主要变更已经在适配器中通过向后兼容读取处理
    // 这里可以添加额外的迁移逻辑，比如：
    // - 批量更新已有数据
    // - 数据清理
    // - 索引重建

    // 记录迁移时间戳
    await _recordMigration(2);
  }

  /// 迁移到 v3
  ///
  /// v3 变更（F8.1 认证配置）：
  /// - HttpRequest 添加 auth 字段（字段索引 14，null = 继承集合）
  /// - Collection 添加 auth 字段（字段索引 8，null = 未配置）
  ///
  /// 与 v2 相同：字段默认值由自定义适配器在读时补齐，这里只记录日志。
  Future<void> _migrateToV3() async {
    logInfo('Migrating to v3: Adding auth config field support (F8.1)');

    await _recordMigration(3);
  }

  /// 迁移到 v4
  ///
  /// v4 变更（F8.2 预请求链）：
  /// - HttpRequest 添加 preRequestChain / preRequestRetryOn401（索引 15/16）
  /// - Collection 添加 preRequestChain / preRequestRetryOn401（索引 9/10）
  ///
  /// 字段默认值仍由自定义适配器在读时补齐，这里只记录日志。
  Future<void> _migrateToV4() async {
    logInfo('Migrating to v4: Adding pre-request chain field support (F8.2)');

    await _recordMigration(4);
  }

  /// 记录迁移历史
  Future<void> _recordMigration(int version) async {
    final key = '${DatabaseConsts.migrationLogPrefix}$version';
    final timestamp = DateTime.now().toIso8601String();
    await _prefs.setString(key, timestamp);
    logDebug('Migration v$version recorded at $timestamp');
  }

  /// 获取上次迁移时间
  ///
  /// 用于调试和诊断
  String? getLastMigrationTime(int version) {
    final key = '${DatabaseConsts.migrationLogPrefix}$version';
    return _prefs.getString(key);
  }

  /// 重置数据库版本（用于测试）
  ///
  /// 危险操作，仅用于测试环境
  Future<void> resetVersionForTesting() async {
    logWarning('Resetting database version for testing');
    await _prefs.remove(DatabaseConsts.dbVersionKey);
    // 清除所有迁移记录
    final keys = _prefs.getKeys().where(
          (key) => key.startsWith(DatabaseConsts.migrationLogPrefix),
        );
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// 强制设置版本（用于测试）
  ///
  /// 危险操作，仅用于测试环境
  Future<void> setVersionForTesting(int version) async {
    logWarning('Setting database version to $version for testing');
    await _setVersion(version);
  }
}
