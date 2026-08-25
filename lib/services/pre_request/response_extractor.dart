import 'dart:convert';

import '../../models/http_response.dart';
import '../../models/pre_request_step.dart';

/// 响应提取器（F8.2）
///
/// 按 [ExtractionRule] 从响应中提取值：
/// - bodyJsonPath：JSONPath 子集 `$.data.tokens[0].value`
///   （支持点路径与 `[n]` 数组下标，不支持过滤器/递归等完整语法）
/// - header：响应头名，大小写不敏感
/// - bodyRegex：正则，取第一个捕获组；无捕获组时取整体匹配
///
/// 提取失败（路径不存在 / 正则不匹配 / 来源为空）返回 null。
class ResponseExtractor {
  ResponseExtractor._();

  /// 应用单条规则
  static String? extract(HttpResponse response, ExtractionRule rule) {
    switch (rule.source) {
      case ExtractionSourceType.header:
        return _fromHeader(response, rule.path.trim());
      case ExtractionSourceType.bodyJsonPath:
        return _fromJsonPath(response.body, rule.path.trim());
      case ExtractionSourceType.bodyRegex:
        return _fromRegex(response.body, rule.path);
    }
  }

  static String? _fromHeader(HttpResponse response, String name) {
    if (name.isEmpty) return null;
    final lower = name.toLowerCase();
    for (final header in response.headers) {
      if (header.key.toLowerCase() == lower) return header.value;
    }
    return null;
  }

  static String? _fromRegex(String? body, String pattern) {
    if (body == null || body.isEmpty || pattern.isEmpty) return null;
    try {
      final match = RegExp(pattern).firstMatch(body);
      if (match == null) return null;
      return match.groupCount >= 1 ? match.group(1) : match.group(0);
    } catch (_) {
      return null; // 非法正则
    }
  }

  /// JSONPath 子集：`$` 开头，后续为 `.key` 或 `[index]` 段
  static String? _fromJsonPath(String? body, String path) {
    if (body == null || body.isEmpty) return null;
    final segments = _parseJsonPathSubset(path);
    if (segments == null) return null;

    final dynamic root;
    try {
      root = jsonDecode(body);
    } catch (_) {
      return null; // 非 JSON body
    }

    dynamic current = root;
    for (final segment in segments) {
      if (segment is String) {
        if (current is! Map || !current.containsKey(segment)) return null;
        current = current[segment];
      } else if (segment is int) {
        if (current is! List || segment < 0 || segment >= current.length) {
          return null;
        }
        current = current[segment];
      }
    }

    if (current == null) return null;
    if (current is String) return current;
    // 标量直接 toString；对象/数组重新编码为 JSON 字符串
    if (current is num || current is bool) return current.toString();
    return jsonEncode(current);
  }

  /// 解析 `$.a.b[0].c` 为段序列（String key 或 int 下标）。
  /// 语法不合法（非子集语法）返回 null。
  static List<Object>? _parseJsonPathSubset(String path) {
    if (!path.startsWith(r'$')) return null;
    final segments = <Object>[];
    var i = 1;
    while (i < path.length) {
      if (path[i] == '.') {
        final start = ++i;
        while (i < path.length && path[i] != '.' && path[i] != '[') {
          i++;
        }
        final key = path.substring(start, i);
        if (key.isEmpty) return null;
        segments.add(key);
      } else if (path[i] == '[') {
        final close = path.indexOf(']', i);
        if (close == -1) return null;
        final index = int.tryParse(path.substring(i + 1, close));
        if (index == null) return null; // 只支持数字下标
        segments.add(index);
        i = close + 1;
      } else {
        return null;
      }
    }
    return segments;
  }
}
