import 'package:hopp/services/ai/ai_response_parser.dart';

import '../../models/assertion_rule.dart';

/// AI 生成的断言草稿（F9.5，F4.2）
///
/// 由 [AiResponseParser] 校验产出，枚举与 [AssertionRule] 完全一致；
/// UI 确认后可转换为 AssertionRule 落库。
class AiAssertionDraft {
  const AiAssertionDraft({
    required this.target,
    required this.targetArg,
    required this.operator,
    required this.expected,
  });

  final AssertionTarget target;

  /// Header 名 / JSONPath 表达式；其余目标为空串
  final String targetArg;
  final AssertionOperator operator;
  final String expected;

  /// 本地编辑态克隆（UI 草稿行修改 target / operator 等字段）
  AiAssertionDraft copyWith({
    AssertionTarget? target,
    String? targetArg,
    AssertionOperator? operator,
    String? expected,
  }) =>
      AiAssertionDraft(
        target: target ?? this.target,
        targetArg: targetArg ?? this.targetArg,
        operator: operator ?? this.operator,
        expected: expected ?? this.expected,
      );

  @override
  bool operator ==(Object other) =>
      other is AiAssertionDraft &&
      other.target == target &&
      other.targetArg == targetArg &&
      other.operator == operator &&
      other.expected == expected;

  @override
  int get hashCode => Object.hash(target, targetArg, operator, expected);

  @override
  String toString() =>
      'AiAssertionDraft(target: ${target.name}, targetArg: $targetArg, '
      'operator: ${operator.name}, expected: $expected)';
}

/// 断言解析结果：合法项 + 被丢弃的非法项数量（防脑补，缺失不补全）
class AiAssertionParseResult {
  const AiAssertionParseResult({required this.items, required this.discarded});

  final List<AiAssertionDraft> items;
  final int discarded;
}

/// AI 生成的请求参数 / Header 条目
class AiKeyValueDraft {
  const AiKeyValueDraft({
    required this.key,
    required this.value,
    required this.enabled,
  });

  final String key;
  final String value;
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is AiKeyValueDraft &&
      other.key == key &&
      other.value == value &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(key, value, enabled);
}

/// AI 生成的请求草稿（F9.5 自然语言建请求）
class AiRequestDraft {
  const AiRequestDraft({
    required this.name,
    required this.method,
    required this.url,
    required this.params,
    required this.headers,
    required this.bodyType,
    required this.rawContentType,
    required this.body,
  });

  final String name;

  /// 大写归一：GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS
  final String method;
  final String url;
  final List<AiKeyValueDraft> params;
  final List<AiKeyValueDraft> headers;

  /// none|form-urlencoded|multipart|raw
  final String bodyType;

  /// json|xml|text，仅 bodyType 为 raw 时有值
  final String? rawContentType;
  final String? body;

  @override
  bool operator ==(Object other) =>
      other is AiRequestDraft &&
      other.name == name &&
      other.method == method &&
      other.url == url &&
      _listEquals(other.params, params) &&
      _listEquals(other.headers, headers) &&
      other.bodyType == bodyType &&
      other.rawContentType == rawContentType &&
      other.body == body;

  @override
  int get hashCode => Object.hash(name, method, url, bodyType, rawContentType,
      body, Object.hashAll(params), Object.hashAll(headers),);

  static bool _listEquals(List<AiKeyValueDraft> a, List<AiKeyValueDraft> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
