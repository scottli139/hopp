import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'assertion_rule.freezed.dart';
part 'assertion_rule.g.dart';

/// 断言目标（F4.1）
@HiveType(typeId: 20)
enum AssertionTarget {
  /// HTTP 状态码
  @HiveField(0)
  status,

  /// 响应 Header（`targetArg` 为 Header 名，大小写不敏感）
  @HiveField(1)
  header,

  /// 响应 Body 文本
  @HiveField(2)
  body,

  /// 响应 Body · JSONPath（`targetArg` 为路径表达式）
  @HiveField(3)
  jsonPath,

  /// 响应耗时（毫秒）
  @HiveField(4)
  responseTime,
}

/// 断言操作符（F4.1）
///
/// 可用集按目标过滤，见 `AssertionEngine.operatorsByTarget`。
@HiveType(typeId: 21)
enum AssertionOperator {
  @HiveField(0)
  equals,
  @HiveField(1)
  notEquals,
  @HiveField(2)
  contains,
  @HiveField(3)
  notContains,
  @HiveField(4)
  exists,
  @HiveField(5)
  notExists,

  /// 正则匹配（`expected` 为正则表达式）
  @HiveField(6)
  matches,
  @HiveField(7)
  lt,
  @HiveField(8)
  lte,
  @HiveField(9)
  gt,
  @HiveField(10)
  gte,
}

/// 断言规则（F4.1）
///
/// 声明式、零代码，挂在请求级（`HttpRequest.assertions`）。每次发送后由
/// `AssertionEngine` 求值；单条可禁用（禁用的规则记为 skipped，不参与判定）。
@freezed
@HiveType(typeId: 19)
class AssertionRule with _$AssertionRule {
  const factory AssertionRule({
    @HiveField(0) required String id,
    @HiveField(1) @Default(true) bool enabled,

    /// 断言目标
    @HiveField(2) @Default(AssertionTarget.status) AssertionTarget target,

    /// 目标参数：Header 名 / JSONPath 表达式；其余目标为空
    @HiveField(3) @Default('') String targetArg,

    /// 断言操作符
    @HiveField(4) @Default(AssertionOperator.equals) AssertionOperator operator,

    /// 期望值（支持 `{{var}}` 插值；exists / notExists 不需要）
    @HiveField(5) @Default('') String expected,
  }) = _AssertionRule;

  factory AssertionRule.fromJson(Map<String, dynamic> json) =>
      _$AssertionRuleFromJson(json);
}
