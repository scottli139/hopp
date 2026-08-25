import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'pre_request_step.freezed.dart';
part 'pre_request_step.g.dart';

/// 提取来源类型（F8.2）
@HiveType(typeId: 18)
enum ExtractionSourceType {
  /// 响应 Body · JSONPath 子集（`$.data.token`，支持点路径与数组下标）
  @HiveField(0)
  bodyJsonPath,

  /// 响应 Header（大小写不敏感）
  @HiveField(1)
  header,

  /// 响应 Body · 正则（取第一个捕获组，无捕获组时取整体匹配）
  @HiveField(2)
  bodyRegex,
}

/// 提取规则：从前置请求的响应中提取值写入变量
@freezed
@HiveType(typeId: 17)
class ExtractionRule with _$ExtractionRule {
  const factory ExtractionRule({
    @HiveField(0) required String id,

    /// 提取来源
    @HiveField(1) @Default(ExtractionSourceType.bodyJsonPath)
    ExtractionSourceType source,

    /// JSONPath 子集 / Header 名 / 正则表达式
    @HiveField(2) @Default('') String path,

    /// 目标变量名（写入本地作用域，如 `token`）
    @HiveField(3) @Default('') String targetVariable,

    @HiveField(4) @Default(true) bool enabled,
  }) = _ExtractionRule;

  factory ExtractionRule.fromJson(Map<String, dynamic> json) =>
      _$ExtractionRuleFromJson(json);
}

/// 预请求链步骤（F8.2）
///
/// 步骤 = 引用集合中一个已保存请求 + 一组提取规则。执行时先解析变量
/// （含 F8.3 转换管道），再发送，最后按规则从响应提取值写入本地作用域。
///
/// 注意：被引用的请求自身的预请求链不会递归执行（深度固定为 1，
/// 防止循环依赖）；其 Auth 配置会正常生效。
@freezed
@HiveType(typeId: 16)
class PreRequestStep with _$PreRequestStep {
  const factory PreRequestStep({
    @HiveField(0) required String id,

    /// 引用的已保存请求 ID（`HttpRequest.id`）
    @HiveField(1) @Default('') String requestId,

    @HiveField(2) @Default(true) bool enabled,

    /// 提取规则列表
    @HiveField(3) @Default([]) List<ExtractionRule> extractions,
  }) = _PreRequestStep;

  factory PreRequestStep.fromJson(Map<String, dynamic> json) =>
      _$PreRequestStepFromJson(json);
}
