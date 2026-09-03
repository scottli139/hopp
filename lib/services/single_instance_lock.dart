import 'dart:io';

import '../utils/app_logger.dart';

/// 单实例保护（TD-7）：启动时对数据目录加 OS 级文件锁。
///
/// Hive 非跨进程安全，两个实例并发打开同一数据目录会导致 box 文件被清零
///（2026-08-28、2026-09-02 两次数据事故）。锁随进程退出（含 SIGKILL/SIGTERM）
/// 由 OS 自动释放，无残留锁问题。
///
/// 语义注意：dart:io 的 lock 在 POSIX 上是 fcntl per-process 语义——
/// **同进程**对同一文件重复加锁会成功（已实测验证），因此本类只防
/// 跨进程双开；竞争分支无法做进程内单元测试，需真机双开验证。
class SingleInstanceLock {
  /// 锁文件名（位于数据目录内；test-mode 数据目录独立，互不干扰）
  static const String lockFileName = '.hopp.lock';

  RandomAccessFile? _lockFile;

  /// 当前是否持有锁
  bool get isHeld => _lockFile != null;

  /// 尝试对 [dataDir] 加锁。
  ///
  /// 返回 true = 拿到锁，可继续启动；false = 另一实例已持有锁，应退出。
  ///
  /// 非锁冲突的 IO 异常（目录不可创建、文件打不开等）按 fail-open 处理：
  /// 记日志并放行——这些场景在引入锁之前也能启动（或由后续 Hive 初始化
  /// 自行报错），不应因加锁失败把用户挡在门外。
  Future<bool> tryAcquire(Directory dataDir) async {
    try {
      await dataDir.create(recursive: true);
      final file =
          File('${dataDir.path}${Platform.pathSeparator}$lockFileName');
      final raf = await file.open(mode: FileMode.write);
      try {
        // 非阻塞 exclusive；被另一实例持有时抛 FileSystemException
        await raf.lock();
        _lockFile = raf;
        AppLogger.info('[SingleInstanceLock] acquired: ${file.path}');
        return true;
      } on FileSystemException {
        AppLogger.warning(
            '[SingleInstanceLock] held by another instance: ${file.path}');
        await raf.close();
        return false;
      }
    } catch (e, stack) {
      AppLogger.error(
          '[SingleInstanceLock] unexpected error, fail-open', e, stack);
      return true;
    }
  }

  /// 释放锁（进程退出时 OS 自动释放；此方法供测试与显式清理使用）
  Future<void> release() async {
    final raf = _lockFile;
    _lockFile = null;
    if (raf != null) {
      try {
        await raf.unlock();
      } finally {
        await raf.close();
      }
    }
  }
}
