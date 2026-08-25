import 'package:uuid/uuid.dart';

import '../models/environment.dart';
import '../models/http_request.dart';
import '../models/key_value_pair.dart';
import 'variable_transforms.dart';

/// 变量替换引擎
///
/// 负责解析请求中的 `{{variable}}` 占位符并替换为实际值：
/// - 支持作用域合并后的变量表（环境变量覆盖全局变量，见 environment_provider）
/// - 支持动态变量 `{{$timestamp}}`、`{{$randomUUID}}` 等
/// - 支持转换管道 `{{var | sha1}}`、`{{body | hmac(sha256, {{key}})}}`（F8.3）
/// - 未定义的变量保留原样，并可通过 [findUnresolved] 查询
class VariableResolver {
  VariableResolver({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// 支持的动态变量（`$` 前缀）
  static const List<String> dynamicVariables = [
    '\$timestamp',
    '\$timestampMs',
    '\$isoTimestamp',
    '\$randomUUID',
    '\$randomInt',
  ];

  /// 一处 `{{...}}` 占位符的扫描结果
  ///
  /// [start] / [end] 为占位符在原文中的起止下标（含 `{{` 与 `}}`），
  /// [expression] 为大括号内的表达式文本（可能含转换管道与参数内
  /// 的嵌套 `{{var}}`）。
  ///
  /// 与正则 `\{\{[^{}]+\}\}` 不同，扫描器支持转换参数内嵌套一层
  /// `{{var}}`（如 `{{body | hmac(sha256, {{app_secret}})}}`）：
  /// 从起始 `{{` 扫描到匹配的 `}}`，途中跳过嵌套的完整 `{{...}}` 对。
  /// 未闭合的 `{{` 原样保留。
  static List<({int start, int end, String expression})> scanExpressions(
    String input,
  ) {
    final matches = <({int start, int end, String expression})>[];
    var i = 0;
    while (i + 1 < input.length) {
      if (input[i] != '{' || input[i + 1] != '{') {
        i++;
        continue;
      }
      final start = i;
      var j = i + 2;
      var end = -1;
      while (j + 1 < input.length) {
        // 嵌套的完整 {{...}} 对：整段跳过
        if (input[j] == '{' && input[j + 1] == '{') {
          final nestedEnd = input.indexOf('}}', j + 2);
          if (nestedEnd == -1) break;
          j = nestedEnd + 2;
          continue;
        }
        if (input[j] == '}' && input[j + 1] == '}') {
          end = j + 2;
          break;
        }
        j++;
      }
      if (end != -1) {
        matches.add((
          start: start,
          end: end,
          expression: input.substring(start + 2, end - 2),
        ));
        i = end;
      } else {
        // 未闭合：跳过起始的 {{，继续向后找
        i = start + 2;
      }
    }
    return matches;
  }

  /// 提取文本中引用的所有变量名（去重）。
  ///
  /// 对管道表达式取基础变量名（`{{a | sha1}}` → `a`），并包含转换
  /// 参数中嵌套引用的变量（`hmac(sha256, {{key}})` → `key`）。
  List<String> extractVariables(String input) {
    final names = <String>[];
    for (final match in scanExpressions(input)) {
      final segments =
          VariableTransforms.splitPipeline(match.expression.trim());
      final base = segments.first;
      if (base.isNotEmpty && !names.contains(base)) {
        names.add(base);
      }
      // 转换参数里嵌套的 {{var}} 引用
      for (final segment in segments.skip(1)) {
        for (final argVar in extractVariables(segment)) {
          if (!names.contains(argVar)) names.add(argVar);
        }
      }
    }
    return names;
  }

  /// 判断变量名是否为动态变量
  bool isDynamicVariable(String name) => dynamicVariables.contains(name);

  /// 生成动态变量的值，不支持的动态变量返回 null
  String? resolveDynamicVariable(String name) {
    final now = DateTime.now();
    switch (name) {
      case '\$timestamp':
        return (now.millisecondsSinceEpoch ~/ 1000).toString();
      case '\$timestampMs':
        return now.millisecondsSinceEpoch.toString();
      case '\$isoTimestamp':
        return now.toUtc().toIso8601String();
      case '\$randomUUID':
        return _uuid.v4();
      case '\$randomInt':
        // 0 ~ 1000000 的随机整数（基于时间戳，避免引入 Random 状态）
        return (now.microsecondsSinceEpoch % 1000001).toString();
      default:
        return null;
    }
  }

  /// 替换文本中的 `{{variable}}` 占位符
  ///
  /// 查找顺序：动态变量（`$` 前缀）→ [variables] 变量表 → 转换管道。
  /// 未定义的变量、或转换失败的表达式，保留 `{{...}}` 原样，便于在 UI 中标记。
  String resolve(String input, Map<String, String> variables) {
    if (!input.contains('{{')) return input;

    final matches = scanExpressions(input);
    if (matches.isEmpty) return input;

    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in matches) {
      buffer.write(input.substring(cursor, match.start));
      final resolved = _resolveExpression(match.expression, variables);
      // 解析失败：保留 {{...}} 原文
      buffer.write(resolved ?? input.substring(match.start, match.end));
      cursor = match.end;
    }
    buffer.write(input.substring(cursor));
    return buffer.toString();
  }

  /// 解析单条表达式（基础变量 + 可选转换管道），失败返回 null
  String? _resolveExpression(
      String rawExpression, Map<String, String> variables) {
    final segments = VariableTransforms.splitPipeline(rawExpression.trim());
    final base = segments.first;
    if (base.isEmpty) return null;

    final String? value;
    if (base.startsWith('\$')) {
      value = resolveDynamicVariable(base);
    } else {
      value = variables[base];
    }
    if (value == null) return null;

    if (segments.length > 1) {
      return VariableTransforms.applyPipeline(
        value,
        segments.sublist(1),
        // 转换参数中嵌套的 {{var}} 走同一解析入口（不支持参数内再套管道）
        (arg) => resolve(arg, variables),
      );
    }
    return value;
  }

  /// 查找文本中未定义的变量（不在变量表中、也不是动态变量）
  List<String> findUnresolved(String input, Map<String, String> variables) {
    final unresolved = <String>[];
    for (final name in extractVariables(input)) {
      if (name.startsWith('\$')) {
        if (resolveDynamicVariable(name) == null &&
            !unresolved.contains(name)) {
          unresolved.add(name);
        }
      } else if (!variables.containsKey(name) && !unresolved.contains(name)) {
        unresolved.add(name);
      }
    }
    return unresolved;
  }

  /// 构建变量表：全局变量 + 环境变量（环境变量覆盖同名的全局变量）
  static Map<String, String> buildScope({
    List<EnvironmentVariable> globals = const [],
    Environment? activeEnvironment,
  }) {
    final result = <String, String>{};
    for (final variable in globals) {
      if (variable.enabled && variable.key.isNotEmpty) {
        result[variable.key] = variable.value;
      }
    }
    if (activeEnvironment != null) {
      result.addAll(activeEnvironment.toVariableMap());
    }
    return result;
  }

  /// 对请求应用变量替换，返回替换后的新请求
  ///
  /// 替换范围：URL、查询参数（key/value）、请求头（key/value）、Body。
  /// 未定义变量保留原样。
  HttpRequest resolveRequest(
      HttpRequest request, Map<String, String> variables) {
    List<KeyValuePair> resolvePairs(List<KeyValuePair> pairs) {
      return pairs
          .map(
            (p) => p.copyWith(
              key: resolve(p.key, variables),
              value: resolve(p.value, variables),
            ),
          )
          .toList();
    }

    return request.copyWith(
      url: resolve(request.url, variables),
      params: resolvePairs(request.params),
      headers: resolvePairs(request.headers),
      body: resolve(request.body, variables),
    );
  }

  /// 查找请求中所有未定义的变量（URL/Params/Headers/Body）
  List<String> findUnresolvedInRequest(
    HttpRequest request,
    Map<String, String> variables,
  ) {
    final buffer = StringBuffer()
      ..write(request.url)
      ..write(' ')
      ..write(request.body);
    for (final pair in [...request.params, ...request.headers]) {
      buffer
        ..write(' ')
        ..write(pair.key)
        ..write(' ')
        ..write(pair.value);
    }
    return findUnresolved(buffer.toString(), variables);
  }
}
