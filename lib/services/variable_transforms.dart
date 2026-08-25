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
  static const List<String> noArgFunctions = ['md5', 'sha1', 'sha256', 'base64'];

  /// 带参函数签名（供 UI 函数菜单 / 参数表单使用）
  static const List<String> parameterizedSignatures = [
    'aes(mode, key, iv)',
    'hmac(algo, key)',
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
          return args.isEmpty ? _hex(md5.convert(utf8.encode(value)).bytes) : null;
        case 'sha1':
          return args.isEmpty ? _hex(sha1.convert(utf8.encode(value)).bytes) : null;
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
    final match = RegExp(r'^([A-Za-z][A-Za-z0-9]*)\s*(?:\((.*)\))?$')
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
}
