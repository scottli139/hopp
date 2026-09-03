import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/services/single_instance_lock.dart';

void main() {
  group('SingleInstanceLock', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hopp_lock_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('tryAcquire 创建数据目录并持有锁', () async {
      final dir = Directory('${tempDir.path}/data');
      expect(await dir.exists(), isFalse);

      final lock = SingleInstanceLock();
      expect(await lock.tryAcquire(dir), isTrue);
      expect(lock.isHeld, isTrue);
      expect(
        await File('${dir.path}/${SingleInstanceLock.lockFileName}').exists(),
        isTrue,
      );

      await lock.release();
      expect(lock.isHeld, isFalse);
    });

    test('release 后可重新获取', () async {
      final lock = SingleInstanceLock();
      expect(await lock.tryAcquire(tempDir), isTrue);
      await lock.release();

      final lock2 = SingleInstanceLock();
      expect(await lock2.tryAcquire(tempDir), isTrue);
      await lock2.release();
    });

    test('同进程重复获取仍成功（fcntl per-process 语义，只防跨进程双开）', () async {
      // dart:io lock 在 POSIX 上是 fcntl 语义：同进程对同一文件重复加锁
      // 不冲突（2026-09-03 实测）。因此竞争分支无法进程内测试，跨进程
      // 双开行为需真机验证。此用例固化该语义，防误改成依赖同进程互斥。
      // （Windows 为 per-handle 强制锁，同进程二次加锁会失败——CI 测试仅
      // 跑 ubuntu，本断言按 POSIX 语义书写。）
      final lock1 = SingleInstanceLock();
      final lock2 = SingleInstanceLock();
      expect(await lock1.tryAcquire(tempDir), isTrue);
      expect(await lock2.tryAcquire(tempDir), isTrue);
      await lock1.release();
      await lock2.release();
    });

    test('目录不可创建时 fail-open 放行', () async {
      // 用一个已存在的普通文件当目录 → create(recursive) 必失败
      final bogus = File('${tempDir.path}/not_a_dir');
      await bogus.writeAsString('x');

      final lock = SingleInstanceLock();
      expect(await lock.tryAcquire(Directory(bogus.path)), isTrue);
      expect(lock.isHeld, isFalse);
    });
  });
}
