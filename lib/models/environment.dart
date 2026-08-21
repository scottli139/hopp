import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'environment.freezed.dart';
part 'environment.g.dart';

/// 变量类型
///
/// - [string]: 普通字符串变量，明文显示
/// - [secret]: 密文变量，UI 中掩码显示（如 token、密码）
@HiveType(typeId: 13)
enum VariableType {
  @HiveField(0)
  string,
  @HiveField(1)
  secret,
}

/// 环境变量
@freezed
@HiveType(typeId: 12)
class EnvironmentVariable with _$EnvironmentVariable {
  const EnvironmentVariable._();

  const factory EnvironmentVariable({
    @HiveField(0) required String id,
    @HiveField(1) required String key,
    @HiveField(2) required String value,
    @HiveField(3) @Default(VariableType.string) VariableType type,
    @HiveField(4) @Default(true) bool enabled,
  }) = _EnvironmentVariable;

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentVariableFromJson(json);

  factory EnvironmentVariable.empty() => EnvironmentVariable(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        key: '',
        value: '',
      );

  /// 是否为密文变量
  bool get isSecret => type == VariableType.secret;
}

/// Environment 模型 - 环境变量集合
///
/// 每个 Environment 代表一套环境配置（如开发/测试/生产），
/// 包含一组可在请求中通过 {{variable}} 引用的变量。
@freezed
@HiveType(typeId: 11)
class Environment with _$Environment {
  const Environment._();

  const factory Environment({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) String? description,
    @HiveField(3) @Default([]) List<EnvironmentVariable> variables,
    @HiveField(4) @Default(0) int sortOrder,
  }) = _Environment;

  factory Environment.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentFromJson(json);

  factory Environment.empty() => Environment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'New Environment',
      );

  /// 返回启用的变量的 key → value 映射
  Map<String, String> toVariableMap() {
    final result = <String, String>{};
    for (final variable in variables) {
      if (variable.enabled && variable.key.isNotEmpty) {
        result[variable.key] = variable.value;
      }
    }
    return result;
  }
}
