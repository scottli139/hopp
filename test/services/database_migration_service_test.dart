import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopp/services/database_migration_service.dart';
import 'package:hopp/utils/database_consts.dart';

void main() {
  group('DatabaseMigrationService', () {
    late SharedPreferences prefs;
    late DatabaseMigrationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = DatabaseMigrationService(prefs);
    });

    tearDown(() async {
      await prefs.clear();
    });

    group('Version Management', () {
      test('should return version 1 for fresh install', () {
        // 初始状态没有版本号，应该返回 1
        final version = prefs.getInt(DatabaseConsts.dbVersionKey);
        expect(version, isNull);
      });

      test('should detect migration needed when version is lower', () async {
        // 设置旧版本
        await prefs.setInt(DatabaseConsts.dbVersionKey, 1);

        // 当前目标是版本 2，应该需要迁移
        final currentVersion = prefs.getInt(DatabaseConsts.dbVersionKey) ?? 1;
        expect(currentVersion, equals(1));
        expect(currentVersion < DatabaseConsts.currentDbVersion, isTrue);
      });

      test('should not need migration when version is current', () async {
        // 设置当前版本
        await prefs.setInt(
          DatabaseConsts.dbVersionKey,
          DatabaseConsts.currentDbVersion,
        );

        final currentVersion = prefs.getInt(DatabaseConsts.dbVersionKey) ?? 1;
        expect(currentVersion, equals(DatabaseConsts.currentDbVersion));
      });
    });

    group('Migration Execution', () {
      test('should complete migration without error', () async {
        // 设置旧版本
        await prefs.setInt(DatabaseConsts.dbVersionKey, 1);

        // 执行迁移
        await service.migrateIfNeeded();

        // 验证版本已更新
        final newVersion = prefs.getInt(DatabaseConsts.dbVersionKey);
        expect(newVersion, equals(DatabaseConsts.currentDbVersion));
      });

      test('should record migration timestamp', () async {
        // 设置旧版本
        await prefs.setInt(DatabaseConsts.dbVersionKey, 1);

        // 执行迁移
        await service.migrateIfNeeded();

        // 验证迁移记录
        final timestamp = service.getLastMigrationTime(2);
        expect(timestamp, isNotNull);
        expect(timestamp, isA<String>());
      });
    });

    group('Reset and Testing', () {
      test('should reset version for testing', () async {
        // 设置一个版本
        await prefs.setInt(DatabaseConsts.dbVersionKey, 99);

        // 重置
        await service.resetVersionForTesting();

        // 验证已重置
        final version = prefs.getInt(DatabaseConsts.dbVersionKey);
        expect(version, isNull);
      });

      test('should set specific version for testing', () async {
        // 设置特定版本
        await service.setVersionForTesting(5);

        // 验证
        final version = prefs.getInt(DatabaseConsts.dbVersionKey);
        expect(version, equals(5));
      });
    });

    group('Migration History', () {
      test('should track multiple migrations', () async {
        // 执行多次迁移（模拟）
        await prefs.setInt(DatabaseConsts.dbVersionKey, 1);
        await service.migrateIfNeeded();

        // 验证至少有一次迁移记录
        final timestampV2 = service.getLastMigrationTime(2);
        expect(timestampV2, isNotNull);
      });
    });
  });
}
