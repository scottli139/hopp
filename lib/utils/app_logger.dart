import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

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
      await _file!.writeAsString('\n[$timestamp] === Hopp Started ===\n',
          mode: FileMode.append);

      // 刷新缓冲区
      for (final line in _buffer) {
        await _file!.writeAsString('$line\n', mode: FileMode.append);
      }
      _buffer.clear();
    } catch (e) {
      print('Failed to initialize log file: $e');
    }
  }

  @override
  void output(OutputEvent event) async {
    final lines = event.lines;

    if (_file == null) {
      // 缓存到缓冲区
      _buffer.addAll(lines);
      return;
    }

    try {
      for (final line in lines) {
        await _file!.writeAsString('$line\n', mode: FileMode.append);
      }
    } catch (e) {
      print('Failed to write log: $e');
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
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    output: _multiOutput,
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
