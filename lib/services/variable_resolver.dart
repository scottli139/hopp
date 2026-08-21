import 'package:uuid/uuid.dart';

import '../models/environment.dart';
import '../models/http_request.dart';
import '../models/key_value_pair.dart';

/// 变量替换引擎
///
/// 负责解析请求中的 `{{variable}}` 占位符并替换为实际值：
/// - 支持作用域合并后的变量表（环境变量覆盖全局变量，见 environment_provider）
/// - 支持动态变量 `{{$timestamp}}`、`{{$randomUUID}}` 等
/// - 未定义的变量保留原样，并可通过 [findUnresolved] 查询
class VariableResolver {
  VariableResolver({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// 匹配 {{variable}} 占位符（允许空白，不允许嵌套大括号）
  static final RegExp _pattern = RegExp(r'\{\{\s*([^{}]+?)\s*\}\}');

  /// 支持的动态变量（`$` 前缀）
  static const List<String> dynamicVariables = [
    '\$timestamp',
    '\$timestampMs',
    '\$isoTimestamp',
    '\$randomUUID',
    '\$randomInt',
  ];

  /// 提取文本中引用的所有变量名（去重、去空白）
  List<String> extractVariables(String input) {
    final names = <String>[];
    for (final match in _pattern.allMatches(input)) {
      final name = match.group(1)!.trim();
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
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
  /// 查找顺序：动态变量（`$` 前缀）→ [variables] 变量表。
  /// 未定义的变量保留 `{{...}}` 原样，便于在 UI 中标记。
  String resolve(String input, Map<String, String> variables) {
    if (!input.contains('{{')) return input;

    return input.replaceAllMapped(_pattern, (match) {
      final name = match.group(1)!.trim();

      if (name.startsWith('\$')) {
        final dynamicValue = resolveDynamicVariable(name);
        if (dynamicValue != null) return dynamicValue;
        return match.group(0)!;
      }

      final value = variables[name];
      return value ?? match.group(0)!;
    });
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
      ..write('\u0000')
      ..write(request.body);
    for (final pair in [...request.params, ...request.headers]) {
      buffer
        ..write('\u0000')
        ..write(pair.key)
        ..write('\u0000')
        ..write(pair.value);
    }
    return findUnresolved(buffer.toString(), variables);
  }
}
