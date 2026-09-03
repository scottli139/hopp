import 'dart:convert';

import '../../l10n/l10n.dart';
import '../../models/assertion_rule.dart';
import '../assertion/assertion_engine.dart';
import 'ai_models.dart';

/// AI 输出解析失败（UI 可提示「AI 返回格式异常，请重试」）
class AiParseException implements Exception {
  const AiParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// AI 响应解析与防脑补校验（F9.5 硬约束）
///
/// 断言草稿允许部分合法（非法项丢弃并计数）；请求草稿任一字段非法即整体
/// 抛 [AiParseException]（请求草稿不可部分使用）。缺失即缺失，不补全。
class AiResponseParser {
  AiResponseParser._();

  static String get _parseErrorMessage => L10nBridge.t.ai_parseError;

  static const _allowedMethods = {
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS',
  };

  static const _allowedBodyTypes = {
    'none',
    'form-urlencoded',
    'multipart',
    'raw',
  };

  static const _allowedRawContentTypes = {'json', 'xml', 'text'};

  /// 剥离可能的 ```json 围栏后 jsonDecode；解码失败抛 [AiParseException]
  static dynamic decodeAiJson(String raw) {
    var text = raw.trim();

    if (text.startsWith('```')) {
      final firstLineEnd = text.indexOf('\n');
      if (firstLineEnd != -1) {
        text = text.substring(firstLineEnd + 1);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
    }

    try {
      return jsonDecode(text);
    } on FormatException {
      throw AiParseException(_parseErrorMessage);
    }
  }

  /// 校验断言草稿：target/operator 枚举合法且组合在
  /// [AssertionEngine.operatorsByTarget] 矩阵内、targetArg/expected 类型合法、
  /// matches 要求合法正则。非法项丢弃并计入 discarded。
  static AiAssertionParseResult parseAssertionDrafts(dynamic decoded) {
    if (decoded is! List) {
      throw AiParseException(_parseErrorMessage);
    }

    final items = <AiAssertionDraft>[];
    var discarded = 0;

    for (final entry in decoded) {
      final draft = _validateAssertionDraft(entry);
      if (draft == null) {
        discarded++;
      } else {
        items.add(draft);
      }
    }

    return AiAssertionParseResult(items: items, discarded: discarded);
  }

  static AiAssertionDraft? _validateAssertionDraft(dynamic entry) {
    if (entry is! Map) return null;

    // target / operator：枚举名匹配（大小写敏感，与模型一致）
    final target = _enumByName(AssertionTarget.values, entry['target']);
    if (target == null) return null;
    final operator = _enumByName(AssertionOperator.values, entry['operator']);
    if (operator == null) return null;

    // 组合必须在矩阵内（如 status + matches 非法）
    if (!(AssertionEngine.operatorsByTarget[target] ?? const [])
        .contains(operator)) {
      return null;
    }

    // targetArg：header / jsonPath 必填非空 String，其余目标应为空
    final needsArg = AssertionEngine.needsTargetArg(target);
    final targetArgRaw = entry['targetArg'];
    final targetArg = targetArgRaw is String ? targetArgRaw : '';
    if (needsArg && targetArg.isEmpty) return null;

    // expected：exists / notExists 不需要；其余只允许 String / num
    String expected = '';
    if (AssertionEngine.needsExpected(operator)) {
      final expectedRaw = entry['expected'];
      if (expectedRaw is String) {
        expected = expectedRaw;
      } else if (expectedRaw is num) {
        expected = '$expectedRaw';
      } else {
        return null;
      }
      if (expected.isEmpty) return null;
    }

    // matches 的 expected 必须是合法正则
    if (operator == AssertionOperator.matches) {
      try {
        RegExp(expected);
      } on FormatException {
        return null;
      }
    }

    return AiAssertionDraft(
      target: target,
      targetArg: needsArg ? targetArg : '',
      operator: operator,
      expected: expected,
    );
  }

  /// 校验请求草稿：method 大写归一、url 非空、params/headers 元素合法、
  /// bodyType / rawContentType 枚举合法。任一非法即抛 [AiParseException]。
  static AiRequestDraft parseRequestDraft(dynamic decoded) {
    if (decoded is! Map) {
      throw AiParseException(_parseErrorMessage);
    }

    final nameRaw = decoded['name'];
    final name = nameRaw is String ? nameRaw : '';

    final methodRaw = decoded['method'];
    if (methodRaw is! String) {
      throw AiParseException(_parseErrorMessage);
    }
    final method = methodRaw.toUpperCase();
    if (!_allowedMethods.contains(method)) {
      throw AiParseException(_parseErrorMessage);
    }

    final urlRaw = decoded['url'];
    if (urlRaw is! String || urlRaw.isEmpty) {
      throw AiParseException(_parseErrorMessage);
    }

    final params = _parseKeyValueList(decoded['params']);
    final headers = _parseKeyValueList(decoded['headers']);

    final bodyTypeRaw = decoded['bodyType'];
    final bodyType = bodyTypeRaw is String ? bodyTypeRaw : 'none';
    if (!_allowedBodyTypes.contains(bodyType)) {
      throw AiParseException(_parseErrorMessage);
    }

    String? rawContentType;
    if (bodyType == 'raw') {
      final rawType = decoded['rawContentType'];
      if (rawType is String && _allowedRawContentTypes.contains(rawType)) {
        rawContentType = rawType;
      } else if (rawType != null) {
        // raw 时给了非法或不支持的值，整体不可用
        throw AiParseException(_parseErrorMessage);
      }
    }

    final bodyRaw = decoded['body'];
    if (bodyRaw != null && bodyRaw is! String) {
      throw AiParseException(_parseErrorMessage);
    }

    return AiRequestDraft(
      name: name,
      method: method,
      url: urlRaw,
      params: params,
      headers: headers,
      bodyType: bodyType,
      rawContentType: rawContentType,
      body: bodyRaw as String?,
    );
  }

  /// params / headers 列表：元素必须为 {key(非空), value, enabled}，
  /// 任一元素非法即抛 [AiParseException]
  static List<AiKeyValueDraft> _parseKeyValueList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) throw AiParseException(_parseErrorMessage);

    final result = <AiKeyValueDraft>[];
    for (final entry in raw) {
      if (entry is! Map) throw AiParseException(_parseErrorMessage);

      final key = entry['key'];
      if (key is! String || key.isEmpty) {
        throw AiParseException(_parseErrorMessage);
      }

      final value = entry['value'];
      if (value != null && value is! String) {
        throw AiParseException(_parseErrorMessage);
      }

      final enabled = entry['enabled'];
      if (enabled != null && enabled is! bool) {
        throw AiParseException(_parseErrorMessage);
      }

      result.add(
        AiKeyValueDraft(
          key: key,
          value: value as String? ?? '',
          enabled: enabled as bool? ?? true,
        ),
      );
    }
    return result;
  }

  static T? _enumByName<T extends Enum>(List<T> values, dynamic name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
