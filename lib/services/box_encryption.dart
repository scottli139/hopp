import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';

import '../utils/app_logger.dart';

/// Hive 数据落盘加密（F8.4 敏感变量加密存储）
///
/// 方案：应用级 AES key（32 字节随机）以 base64 存于 Hive 数据目录的
/// `.secure_key` 文件，collections / requests / environments 三个数据
/// box 使用 `HiveAesCipher` 加密。secret 变量的值因此不再明文落盘。
///
/// 诚实边界：key 与数据同机存放，防御目标是「直接翻看 Hive 文件读不到
/// 明文」，不防御能访问整台机器的攻击者（那需要 keychain 级方案）。
///
/// 老数据迁移：见 [migrateToEncrypted]，明文 box 读出 → 删除 → 加密
/// 重建 → 写回，幂等（调用方用 SharedPreferences flag 保证只跑一次）。
class BoxEncryption {
  BoxEncryption._();

  static const String keyFileName = '.secure_key';

  /// 加载或创建加密 key。[hiveDir] 为 Hive 数据目录。
  static Future<List<int>> loadOrCreateKey(Directory hiveDir) async {
    final keyFile = File('${hiveDir.path}/$keyFileName');
    if (await keyFile.exists()) {
      return base64Decode(await keyFile.readAsString());
    }
    final key = Hive.generateSecureKey();
    await keyFile.writeAsString(base64Encode(key), flush: true);
    AppLogger.info('[BoxEncryption] Generated new secure key');
    return key;
  }

  /// 将已存在的明文 box 迁移为加密 box；box 不存在时直接跳过。
  ///
  /// 调用时机必须在 box 打开之前。迁移失败仅记录日志（该 box 后续
  /// 以 cipher 打开会失败，由 StorageService 的恢复流程兜底）。
  static Future<void> migrateToEncrypted({
    required String boxName,
    required List<int> key,
  }) async {
    if (!await Hive.boxExists(boxName)) return;

    try {
      final plain = await Hive.openBox<dynamic>(boxName);
      final entries = Map<dynamic, dynamic>.of(plain.toMap());
      await plain.close();

      await Hive.deleteBoxFromDisk(boxName);

      final secured = await Hive.openBox<dynamic>(
        boxName,
        encryptionCipher: HiveAesCipher(key),
      );
      await secured.putAll(entries);
      await secured.close();
      AppLogger.info(
          '[BoxEncryption] Migrated box "$boxName" to encrypted storage');
    } catch (e, stack) {
      AppLogger.error(
          '[BoxEncryption] Failed to migrate box "$boxName"', e, stack);
    }
  }
}
