import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// 自定义日志过滤器 - 允许所有级别的日志
///
/// 例外：`flutter test` 环境（test runner 注入的进程环境变量
/// FLUTTER_TEST=true）下只输出 warning 及以上级别，避免 trace/debug/info
/// 的 PrettyPrinter 多行框刷屏污染测试输出。
class _AllLogFilter extends LogFilter {
  /// 是否处于 flutter test 环境
  static final bool _isFlutterTest =
      Platform.environment['FLUTTER_TEST'] == 'true';

  @override
  bool shouldLog(LogEvent event) {
    if (_isFlutterTest && event.level.value < Level.warning.value) {
      return false;
    }
    return true;
  }
}

/// 文件日志输出
class _FileOutput extends LogOutput {
  File? _file;
  final List<String> _buffer = [];

  _FileOutput();

  Future<void> init() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final logDir = Directory('${appSupportDir.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      _file = File('${logDir.path}/hopp_$dateStr.log');

      // 写入启动标记
      final timestamp = now.toIso8601String();
      _file!.writeAsStringSync('\n[$timestamp] === Hopp Started ===\n',
          mode: FileMode.append);

      // 刷新缓冲区
      if (_buffer.isNotEmpty) {
        final bufferContent = _buffer.map((l) => '$l\n').join();
        _file!.writeAsStringSync(bufferContent, mode: FileMode.append);
        _buffer.clear();
      }
    } catch (e) {
      // 初始化失败，静默处理
      _buffer.add('Failed to initialize log file: $e');
    }
  }

  @override
  void output(OutputEvent event) {
    final lines = event.lines;

    if (_file == null) {
      // 缓存到缓冲区
      _buffer.addAll(lines);
      return;
    }

    // 同步写入，避免异步丢失日志
    try {
      final content = lines.map((l) => '$l\n').join();
      _file!.writeAsStringSync(content, mode: FileMode.append, flush: true);
    } catch (e) {
      // 静默失败，避免影响应用
      _buffer.addAll(lines);
    }
  }

  /// 获取日志文件路径
  String? get logFilePath => _file?.path;
}

/// 多路输出（控制台 + 文件）
class _MultiOutput extends LogOutput {
  final ConsoleOutput _consoleOutput = ConsoleOutput();
  final _FileOutput _fileOutput = _FileOutput();

  Future<void> init() async {
    await _fileOutput.init();
  }

  @override
  void output(OutputEvent event) {
    _consoleOutput.output(event);
    _fileOutput.output(event);
  }

  String? get logFilePath => _fileOutput.logFilePath;
}

/// 应用日志工具
///
/// 提供统一的日志记录功能，输出到控制台和文件
///
/// 日志文件位置：
/// - macOS: ~/Library/Application Support/hopp/logs/
/// - Windows: %APPDATA%/hopp/logs/
/// - Linux: ~/.local/share/hopp/logs/
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: !kReleaseMode, // Release 模式下禁用颜色
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    output: _multiOutput,
    // 使用自定义 Filter 确保 Release 模式下也能记录所有级别日志
    filter: _AllLogFilter(),
    level: Level.trace, // 启用所有日志级别
  );

  static final _MultiOutput _multiOutput = _MultiOutput();
  static bool _initialized = false;

  /// 初始化日志系统
  static Future<void> initialize() async {
    if (_initialized) return;
    await _multiOutput.init();
    _initialized = true;
    info(
        '[AppLogger] Logger initialized, log file: ${logFilePath ?? "unknown"}');
  }

  /// 获取日志文件路径
  static String? get logFilePath => _multiOutput.logFilePath;

  static void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// 日志 Mixin
///
/// 为类提供便捷的日志方法，自动添加类名前缀
///
/// 使用示例：
/// ```dart
/// class MyService with LogMixin {
///   void doSomething() {
///     logInfo('Doing something'); // 输出: [MyService] Doing something
///   }
/// }
/// ```
mixin LogMixin {
  void logTrace(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.trace('[$runtimeType] $message', error, stackTrace);
  }

  void logDebug(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.debug('[$runtimeType] $message', error, stackTrace);
  }

  void logInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.info('[$runtimeType] $message', error, stackTrace);
  }

  void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.warning('[$runtimeType] $message', error, stackTrace);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.error('[$runtimeType] $message', error, stackTrace);
  }

  void logFatal(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.fatal('[$runtimeType] $message', error, stackTrace);
  }
}
