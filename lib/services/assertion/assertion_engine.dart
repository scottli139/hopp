import 'dart:convert';

import 'package:json_path/json_path.dart';

import '../../models/assertion_rule.dart';
import '../../models/http_response.dart';
import '../variable_resolver.dart';

/// 断言结果
enum AssertionOutcome {
  /// 通过
  passed,

  /// 失败
  failed,

  /// 跳过（规则被禁用，未求值）
  skipped,
}

/// 单条规则的求值结果
class AssertionResult {
  const AssertionResult({
    required this.rule,
    required this.outcome,
    this.actual,
    this.message,
  });

  /// 被求值的规则
  final AssertionRule rule;
  final AssertionOutcome outcome;

  /// 实际值（字符串表示；取不到时为 null）
  final String? actual;

  /// 失败原因等附加说明（skipped / failed 时可能有值）
  final String? message;

  bool get passed => outcome == AssertionOutcome.passed;
}

/// 断言求值引擎（F4.1）
///
/// 纯 Dart 实现，不依赖 Flutter / 存储 / 日志，供 GUI 与 CLI 共用。
/// 期望值与目标参数先经 [VariableResolver] 做 `{{var}}` 插值，再按目标
/// 类型求值；禁用的规则直接记为 [AssertionOutcome.skipped]。
class AssertionEngine {
  AssertionEngine._();

  /// 各目标可用的操作符集合（与 PRD F4.1 矩阵一致）
  static const Map<AssertionTarget, List<AssertionOperator>> operatorsByTarget =
      {
    AssertionTarget.status: [
      AssertionOperator.equals,
      AssertionOperator.notEquals,
      AssertionOperator.lt,
      AssertionOperator.lte,
      AssertionOperator.gt,
      AssertionOperator.gte,
    ],
    AssertionTarget.header: [
      AssertionOperator.equals,
      AssertionOperator.notEquals,
      AssertionOperator.contains,
      AssertionOperator.notContains,
      AssertionOperator.exists,
      AssertionOperator.notExists,
      AssertionOperator.matches,
    ],
    AssertionTarget.body: [
      AssertionOperator.contains,
      AssertionOperator.notContains,
      AssertionOperator.equals,
      AssertionOperator.notEquals,
      AssertionOperator.matches,
    ],
    AssertionTarget.jsonPath: [
      AssertionOperator.exists,
      AssertionOperator.notExists,
      AssertionOperator.equals,
      AssertionOperator.notEquals,
      AssertionOperator.contains,
      AssertionOperator.lt,
      AssertionOperator.lte,
      AssertionOperator.gt,
      AssertionOperator.gte,
    ],
    AssertionTarget.responseTime: [
      AssertionOperator.lt,
      AssertionOperator.lte,
      AssertionOperator.gt,
      AssertionOperator.gte,
    ],
  };

  /// 该目标是否需要目标参数（Header 名 / JSONPath 表达式）
  static bool needsTargetArg(AssertionTarget target) =>
      target == AssertionTarget.header || target == AssertionTarget.jsonPath;

  /// 该操作符是否需要期望值（exists / notExists 不需要）
  static bool needsExpected(AssertionOperator operator) =>
      operator != AssertionOperator.exists &&
      operator != AssertionOperator.notExists;

  /// 求值一组规则，结果与输入顺序一致
  static List<AssertionResult> evaluate({
    required List<AssertionRule> rules,
    required HttpResponse response,
    required VariableResolver resolver,
    required Map<String, String> variables,
  }) {
    return [
      for (final rule in rules)
        _evaluateRule(rule, response, resolver, variables),
    ];
  }

  static AssertionResult _evaluateRule(
    AssertionRule rule,
    HttpResponse response,
    VariableResolver resolver,
    Map<String, String> variables,
  ) {
    if (!rule.enabled) {
      return AssertionResult(rule: rule, outcome: AssertionOutcome.skipped);
    }

    // 操作符与目标不匹配（如绕过 UI 构造的规则）直接判失败
    if (!(operatorsByTarget[rule.target] ?? const []).contains(rule.operator)) {
      return _fail(
        rule,
        null,
        'operator ${rule.operator.name} is not supported for target '
        '${rule.target.name}',
      );
    }

    final expected = resolver.resolve(rule.expected, variables);
    final targetArg = resolver.resolve(rule.targetArg, variables);

    return switch (rule.target) {
      AssertionTarget.status => _evalStatus(rule, response, expected),
      AssertionTarget.header =>
        _evalHeader(rule, response, targetArg, expected),
      AssertionTarget.body => _evalBody(rule, response, expected),
      AssertionTarget.jsonPath =>
        _evalJsonPath(rule, response, targetArg, expected),
      AssertionTarget.responseTime =>
        _evalResponseTime(rule, response, expected),
    };
  }

  // ---------- status ----------

  static AssertionResult _evalStatus(
    AssertionRule rule,
    HttpResponse response,
    String expected,
  ) {
    final code = response.statusCode;
    if (code == null) {
      return _fail(rule, null, 'no response');
    }
    final actual = '$code';

    final expectedNum = num.tryParse(expected);
    if (expectedNum == null) {
      return _fail(rule, actual, 'expected not a number');
    }
    final ok = switch (rule.operator) {
      AssertionOperator.equals => code == expectedNum,
      AssertionOperator.notEquals => code != expectedNum,
      AssertionOperator.lt => code < expectedNum,
      AssertionOperator.lte => code <= expectedNum,
      AssertionOperator.gt => code > expectedNum,
      AssertionOperator.gte => code >= expectedNum,
      _ => false,
    };
    return ok
        ? _pass(rule, actual)
        : _fail(rule, actual, 'expected ${rule.operator.name} $expected');
  }

  // ---------- header ----------

  static AssertionResult _evalHeader(
    AssertionRule rule,
    HttpResponse response,
    String name,
    String expected,
  ) {
    final lowerName = name.toLowerCase();
    String? value;
    for (final h in response.headers) {
      if (h.key.toLowerCase() == lowerName) {
        value = h.value;
        break;
      }
    }

    if (value == null) {
      return switch (rule.operator) {
        AssertionOperator.notExists => _pass(rule, null),
        _ => _fail(rule, null, 'header not found'),
      };
    }

    switch (rule.operator) {
      case AssertionOperator.exists:
        return _pass(rule, value);
      case AssertionOperator.notExists:
        return _fail(rule, value, 'header exists');
      case AssertionOperator.equals:
        return value == expected
            ? _pass(rule, value)
            : _fail(rule, value, 'expected "$expected"');
      case AssertionOperator.notEquals:
        return value != expected
            ? _pass(rule, value)
            : _fail(rule, value, 'expected not "$expected"');
      case AssertionOperator.contains:
        return value.contains(expected)
            ? _pass(rule, value)
            : _fail(rule, value, 'expected to contain "$expected"');
      case AssertionOperator.notContains:
        return !value.contains(expected)
            ? _pass(rule, value)
            : _fail(rule, value, 'expected not to contain "$expected"');
      case AssertionOperator.matches:
        final regex = _tryRegex(expected);
        if (regex == null) {
          return _fail(rule, value, 'invalid regex');
        }
        return regex.hasMatch(value)
            ? _pass(rule, value)
            : _fail(rule, value, 'expected to match /$expected/');
      default:
        return _fail(
          rule,
          value,
          'operator ${rule.operator.name} is not supported for target header',
        );
    }
  }

  // ---------- body ----------

  static AssertionResult _evalBody(
    AssertionRule rule,
    HttpResponse response,
    String expected,
  ) {
    final body = response.body ?? '';
    switch (rule.operator) {
      case AssertionOperator.contains:
        return body.contains(expected)
            ? _pass(rule, null)
            : _fail(rule, null, 'expected body to contain "$expected"');
      case AssertionOperator.notContains:
        return !body.contains(expected)
            ? _pass(rule, null)
            : _fail(rule, null, 'expected body not to contain "$expected"');
      case AssertionOperator.equals:
        return body == expected
            ? _pass(rule, null)
            : _fail(rule, null, 'expected body to equal "$expected"');
      case AssertionOperator.notEquals:
        return body != expected
            ? _pass(rule, null)
            : _fail(rule, null, 'expected body not to equal "$expected"');
      case AssertionOperator.matches:
        final regex = _tryRegex(expected);
        if (regex == null) {
          return _fail(rule, null, 'invalid regex');
        }
        return regex.hasMatch(body)
            ? _pass(rule, null)
            : _fail(rule, null, 'expected body to match /$expected/');
      default:
        return _fail(
          rule,
          null,
          'operator ${rule.operator.name} is not supported for target body',
        );
    }
  }

  // ---------- jsonPath ----------

  static AssertionResult _evalJsonPath(
    AssertionRule rule,
    HttpResponse response,
    String pathExpr,
    String expected,
  ) {
    final dynamic json;
    try {
      json = jsonDecode(response.body ?? '');
    } on FormatException {
      return _fail(rule, null, 'response body is not valid JSON');
    }

    final List<Object?> values;
    try {
      values = JsonPath(pathExpr).read(json).map((m) => m.value).toList();
    } on Exception {
      // 表达式语法错误等（petitparser ParserException 未经 json_path 导出，
      // 这里按 Exception 兜底）
      return _fail(rule, null, 'invalid JSONPath expression');
    }

    if (values.isEmpty) {
      return switch (rule.operator) {
        AssertionOperator.notExists => _pass(rule, null),
        _ => _fail(rule, null, 'path not found'),
      };
    }

    // 多匹配时取第一个（确定性；exists/notExists 只看有无）
    final value = values.first;
    final actual = _jsonValueToString(value);

    switch (rule.operator) {
      case AssertionOperator.exists:
        return _pass(rule, actual);
      case AssertionOperator.notExists:
        return _fail(rule, actual, 'path exists');
      case AssertionOperator.equals:
        return _jsonEquals(value, expected)
            ? _pass(rule, actual)
            : _fail(rule, actual, 'expected "$expected"');
      case AssertionOperator.notEquals:
        return !_jsonEquals(value, expected)
            ? _pass(rule, actual)
            : _fail(rule, actual, 'expected not "$expected"');
      case AssertionOperator.contains:
        return actual.contains(expected)
            ? _pass(rule, actual)
            : _fail(rule, actual, 'expected to contain "$expected"');
      case AssertionOperator.lt:
      case AssertionOperator.lte:
      case AssertionOperator.gt:
      case AssertionOperator.gte:
        final actualNum = _asNum(value);
        if (actualNum == null) {
          return _fail(rule, actual, 'value is not a number');
        }
        final expectedNum = num.tryParse(expected);
        if (expectedNum == null) {
          return _fail(rule, actual, 'expected not a number');
        }
        final ok = switch (rule.operator) {
          AssertionOperator.lt => actualNum < expectedNum,
          AssertionOperator.lte => actualNum <= expectedNum,
          AssertionOperator.gt => actualNum > expectedNum,
          _ => actualNum >= expectedNum,
        };
        return ok
            ? _pass(rule, actual)
            : _fail(rule, actual, 'expected ${rule.operator.name} $expected');
      default:
        return _fail(
          rule,
          actual,
          'operator ${rule.operator.name} is not supported for target '
          'jsonPath',
        );
    }
  }

  // ---------- responseTime ----------

  static AssertionResult _evalResponseTime(
    AssertionRule rule,
    HttpResponse response,
    String expected,
  ) {
    final durationMs = response.durationMs;
    if (durationMs == null) {
      return _fail(rule, null, 'no timing info');
    }
    final actual = '$durationMs';

    final expectedNum = num.tryParse(expected);
    if (expectedNum == null) {
      return _fail(rule, actual, 'expected not a number');
    }
    final ok = switch (rule.operator) {
      AssertionOperator.lt => durationMs < expectedNum,
      AssertionOperator.lte => durationMs <= expectedNum,
      AssertionOperator.gt => durationMs > expectedNum,
      _ => durationMs >= expectedNum,
    };
    return ok
        ? _pass(rule, actual)
        : _fail(rule, actual, 'expected ${rule.operator.name} $expected');
  }

  // ---------- 工具 ----------

  static AssertionResult _pass(AssertionRule rule, String? actual) =>
      AssertionResult(
        rule: rule,
        outcome: AssertionOutcome.passed,
        actual: actual,
      );

  static AssertionResult _fail(
    AssertionRule rule,
    String? actual,
    String message,
  ) =>
      AssertionResult(
        rule: rule,
        outcome: AssertionOutcome.failed,
        actual: actual,
        message: message,
      );

  /// 正则构造失败返回 null
  static RegExp? _tryRegex(String pattern) {
    try {
      return RegExp(pattern);
    } on FormatException {
      return null;
    }
  }

  /// JSON 值的字符串表示：字符串原样，数字去尾零，bool → 'true'/'false'，
  /// null → 'null'，复合值按 JSON 编码
  static String _jsonValueToString(Object? value) {
    return switch (value) {
      null => 'null',
      final String s => s,
      final bool b => b ? 'true' : 'false',
      final int i => '$i',
      final double d => d == d.truncateToDouble() ? '${d.toInt()}' : '$d',
      _ => jsonEncode(value),
    };
  }

  /// 归一化比较：num 与字符串形式的数字互认，bool 转 'true'/'false'
  static bool _jsonEquals(Object? value, String expected) {
    if (value is num) {
      final expectedNum = num.tryParse(expected);
      if (expectedNum != null) {
        return value == expectedNum;
      }
    }
    return _jsonValueToString(value) == expected;
  }

  /// 值转 num（数字字符串可转）
  static num? _asNum(Object? value) {
    return switch (value) {
      final num n => n,
      final String s => num.tryParse(s),
      _ => null,
    };
  }
}
