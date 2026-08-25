import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hopp/services/box_encryption.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hopp_box_encryption_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('loadOrCreateKey', () {
    test('首次生成 32 字节 key 并落盘，二次加载复用', () async {
      final key1 = await BoxEncryption.loadOrCreateKey(tempDir);
      expect(key1, hasLength(32));
      expect(
        await File('${tempDir.path}/${BoxEncryption.keyFileName}').exists(),
        isTrue,
      );

      final key2 = await BoxEncryption.loadOrCreateKey(tempDir);
      expect(key2, equals(key1));
    });
  });

  group('migrateToEncrypted', () {
    test('明文数据迁移后可用 cipher 读回，且磁盘上无明文', () async {
      const boxName = 'test_migrate';
      const secretValue = 'my-super-secret-token-value';

      // 1. 明文写入
      final plain = await Hive.openBox<String>(boxName);
      await plain.put('password', secretValue);
      await plain.close();

      // 2. 迁移
      final key = await BoxEncryption.loadOrCreateKey(tempDir);
      await BoxEncryption.migrateToEncrypted(boxName: boxName, key: key);

      // 3. 加密 box 用 cipher 打开，数据完好
      final secured = await Hive.openBox<String>(
        boxName,
        encryptionCipher: HiveAesCipher(key),
      );
      expect(secured.get('password'), equals(secretValue));
      await secured.close();

      // 4. 磁盘字节中搜不到原始明文
      final boxFile = File('${tempDir.path}/$boxName.hive');
      final bytes = await boxFile.readAsBytes();
      final body = String.fromCharCodes(bytes);
      expect(body.contains(secretValue), isFalse);
    });

    test('box 不存在时安全跳过', () async {
      final key = await BoxEncryption.loadOrCreateKey(tempDir);
      await BoxEncryption.migrateToEncrypted(
          boxName: 'never_existed', key: key);
      expect(await Hive.boxExists('never_existed'), isFalse);
    });

    test('迁移后不带 cipher 打开读不到数据（Hive 触发自愈恢复）', () async {
      const boxName = 'test_no_cipher';
      final plain = await Hive.openBox<String>(boxName);
      await plain.put('k', 'v');
      await plain.close();

      final key = await BoxEncryption.loadOrCreateKey(tempDir);
      await BoxEncryption.migrateToEncrypted(boxName: boxName, key: key);

      // 明文方式打开加密 box：Hive 视其为损坏并恢复，原数据不可读
      final recovered = await Hive.openBox<String>(boxName);
      expect(recovered.get('k'), isNull);
      await recovered.close();
    });
  });
}
