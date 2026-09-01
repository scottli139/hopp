import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// 变量转换管道（F8.3）
///
/// 在 `{{var}}` 引用后追加 `| fn` 段，对解析后的值做声明式转换：
///
/// ```text
/// {{password | sha1}}                 # 无参：md5 / sha1 / sha256 / base64
/// {{body | hmac(sha256, {{secret}})}} # 带参：hmac(algo, key)
/// {{text | aes(cbc, key, iv, hex)}}   # 带参：aes(mode, key, iv[, format])
/// ```
///
/// 设计原则（PRD F8.3）：算法内置纯 Dart 实现（crypto / encrypt 包），
/// 转换显式可见；任何一步失败（未知函数 / 参数个数不符 / key 长度非法）
/// 整体返回 null，由调用方保留 `{{...}}` 原文以便 UI 标记。
class VariableTransforms {
  VariableTransforms._();

  /// 无参函数名清单（供 UI 函数菜单使用）
  static const List<String> noArgFunctions = [
    'md5',
    'sha1',
    'sha256',
    'base64'
  ];

  /// 带参函数签名（供 UI 函数菜单 / 参数表单使用）
  static const List<String> parameterizedSignatures = [
    'aes(mode, key, iv)',
    'hmac(algo, key)',
    'date_add(offset)',
    'date_floor(unit)',
  ];

  /// 按顶层 `|` 切分表达式管道（括号内的 `|` 不切分）。
  ///
  /// 返回的段已 trim，至少包含 1 段（基础表达式）。
  static List<String> splitPipeline(String expression) {
    final segments = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < expression.length; i++) {
      final ch = expression[i];
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        if (depth > 0) depth--;
      } else if (ch == '|' && depth == 0) {
        segments.add(expression.substring(start, i).trim());
        start = i + 1;
      }
    }
    segments.add(expression.substring(start).trim());
    return segments;
  }

  /// 取表达式的基础变量名（第一段管道之前的部分）
  static String baseName(String expression) => splitPipeline(expression).first;

  /// 依次应用转换段。任一失败返回 null。
  ///
  /// [resolveArg] 用于解析参数中的 `{{var}}` 引用（由 VariableResolver
  /// 注入，避免循环依赖）。
  static String? applyPipeline(
    String value,
    List<String> segments,
    String Function(String) resolveArg,
  ) {
    var current = value;
    for (final segment in segments) {
      final result = applySingle(current, segment, resolveArg);
      if (result == null) return null;
      current = result;
    }
    return current;
  }

  /// 应用单个转换段（如 `sha1` 或 `hmac(sha256, {{key}})`）
  static String? applySingle(
    String value,
    String segment,
    String Function(String) resolveArg,
  ) {
    final parsed = _parseSegment(segment);
    if (parsed == null) return null;
    final (name, rawArgs) = parsed;

    // 参数先经变量解析（支持 {{var}} 引用）
    final args = [
      for (final arg in rawArgs) resolveArg(arg),
    ];

    try {
      switch (name) {
        case 'md5':
          return args.isEmpty
              ? _hex(md5.convert(utf8.encode(value)).bytes)
              : null;
        case 'sha1':
          return args.isEmpty
              ? _hex(sha1.convert(utf8.encode(value)).bytes)
              : null;
        case 'sha256':
          return args.isEmpty
              ? _hex(sha256.convert(utf8.encode(value)).bytes)
              : null;
        case 'base64':
          return args.isEmpty ? base64Encode(utf8.encode(value)) : null;
        case 'hmac':
          return _hmac(value, args);
        case 'aes':
          return _aes(value, args);
        case 'date_add':
          return _dateAdd(value, args);
        case 'date_floor':
          return _dateFloor(value, args);
        default:
          return null;
      }
    } catch (_) {
      // 加密参数非法（如 key 长度不符）等，视为转换失败
      return null;
    }
  }

  /// 解析段为 (函数名, 原始参数列表)；语法非法返回 null
  static (String, List<String>)? _parseSegment(String segment) {
    final match = RegExp(r'^([A-Za-z][A-Za-z0-9_]*)\s*(?:\((.*)\))?$')
        .firstMatch(segment.trim());
    if (match == null) return null;

    final name = match.group(1)!;
    final argsText = match.group(2);
    if (argsText == null) return (name, const <String>[]);

    // 顶层逗号切分参数（参数内允许 {{var}}，不允许逗号/括号嵌套）
    final args = argsText
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    return (name, args);
  }

  /// hmac(algo, key) → hex
  static String? _hmac(String value, List<String> args) {
    if (args.length != 2) return null;
    final Hash hash;
    switch (args[0]) {
      case 'md5':
        hash = md5;
      case 'sha1':
        hash = sha1;
      case 'sha256':
        hash = sha256;
      default:
        return null;
    }
    final hmac = Hmac(hash, utf8.encode(args[1]));
    return _hex(hmac.convert(utf8.encode(value)).bytes);
  }

  /// aes(mode, key, iv[, format])
  ///
  /// - mode：cbc（需 iv）/ ecb（iv 传占位即可，不参与计算）
  /// - key：UTF-8 后须为 16 / 24 / 32 字节
  /// - format：base64（默认）| hex
  static String? _aes(String value, List<String> args) {
    if (args.length < 3 || args.length > 4) return null;
    final mode = args[0].toLowerCase();
    final keyBytes = utf8.encode(args[1]);
    if (!const [16, 24, 32].contains(keyBytes.length)) return null;

    final enc.AESMode aesMode;
    switch (mode) {
      case 'cbc':
        aesMode = enc.AESMode.cbc;
      case 'ecb':
        aesMode = enc.AESMode.ecb;
      default:
        return null;
    }

    final ivBytes = utf8.encode(args[2]);
    if (aesMode == enc.AESMode.cbc && ivBytes.length != 16) return null;

    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypter = enc.Encrypter(enc.AES(key, mode: aesMode));
    final encrypted = encrypter.encrypt(value, iv: iv);

    final format = args.length == 4 ? args[3].toLowerCase() : 'base64';
    switch (format) {
      case 'base64':
        return encrypted.base64;
      case 'hex':
        return _hex(encrypted.bytes);
      default:
        return null;
    }
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  // ---------------------------------------------------------------
  // 时间函数（F8.5 / M8.6）
  // ---------------------------------------------------------------

  /// epoch 秒/毫秒自适应的整数值解析。
  ///
  /// 输入为整数字符串；绝对值 < 1e11 视为秒（当前秒级 ≈ 1.7e9），
  /// 否则视为毫秒（当前毫秒级 ≈ 1.7e12）。返回 (毫秒值, 是否秒级输入)，
  /// 非整数 / 超出 DateTime 可表示范围返回 null。
  static (int, bool)? _parseEpoch(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return null;
    final isSeconds = parsed.abs() < 100000000000;
    final millis = isSeconds ? parsed * 1000 : parsed;
    if (millis.abs() > 8640000000000000) return null; // DateTime 上限 ~±1e16 ms
    return (millis, isSeconds);
  }

  static String _formatEpoch(int millis, bool asSeconds) =>
      asSeconds ? (millis ~/ 1000).toString() : millis.toString();

  /// date_add(offset)：epoch 相对偏移。
  ///
  /// offset 语法 `[+-]整数+单位`，单位 s/m/h/d/w（秒/分/时/天/周），
  /// 如 `-7d`、`+12h`、`30m`。输入 10 位秒 / 13 位毫秒自适应，输出同单位。
  static String? _dateAdd(String value, List<String> args) {
    if (args.length != 1) return null;
    final match = RegExp(r'^([+-]?\d+)(s|m|h|d|w)$')
        .firstMatch(args[0].trim().toLowerCase());
    if (match == null) return null;
    final amount = int.tryParse(match.group(1)!);
    if (amount == null) return null;
    const unitMs = {
      's': 1000,
      'm': 60000,
      'h': 3600000,
      'd': 86400000,
      'w': 604800000,
    };
    final parsed = _parseEpoch(value);
    if (parsed == null) return null;
    final (millis, isSeconds) = parsed;
    final result = millis + amount * unitMs[match.group(2)!]!;
    if (result.abs() > 8640000000000000) return null;
    return _formatEpoch(result, isSeconds);
  }

  /// date_floor(unit)：本地时间取整。
  ///
  /// unit ∈ hour/day/week/month：hour=本小时零点、day=今天零点、
  /// week=本周一零点、month=本月 1 号零点（均为本地时区）。
  /// 输入输出单位约定同 [_dateAdd]。
  static String? _dateFloor(String value, List<String> args) {
    if (args.length != 1) return null;
    final parsed = _parseEpoch(value);
    if (parsed == null) return null;
    final (millis, isSeconds) = parsed;

    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final DateTime floored;
    switch (args[0].trim().toLowerCase()) {
      case 'hour':
        floored = DateTime(dt.year, dt.month, dt.day, dt.hour);
      case 'day':
        floored = DateTime(dt.year, dt.month, dt.day);
      case 'week':
        final monday = dt.subtract(Duration(days: dt.weekday - 1));
        floored = DateTime(monday.year, monday.month, monday.day);
      case 'month':
        floored = DateTime(dt.year, dt.month, 1);
      default:
        return null;
    }
    return _formatEpoch(floored.millisecondsSinceEpoch, isSeconds);
  }
}
