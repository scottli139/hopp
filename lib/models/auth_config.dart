import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'auth_config.freezed.dart';
part 'auth_config.g.dart';

/// 认证类型（F8.1）
///
/// [inherit] 沿 parentId 链向上找最近的认证配置：请求 → 所属集合 →
/// 父集合 → …；根集合的 inherit 等同于无认证。
@HiveType(typeId: 15)
enum AuthType {
  /// 继承（默认）：向上查找最近的非 inherit 配置
  @HiveField(0)
  inherit,

  /// 无认证（显式阻断继承）
  @HiveField(1)
  none,

  /// Bearer Token：`Authorization: Bearer <token>`
  @HiveField(2)
  bearer,

  /// Basic Auth：`Authorization: Basic base64(user:pass)`
  @HiveField(3)
  basic,

  /// API Key：注入 Header 或 Query
  @HiveField(4)
  apiKey,
}

/// 认证配置（F8.1）
///
/// 挂载点：`HttpRequest.auth` 与 `Collection.auth`，默认 `AuthConfig()`
/// （type = inherit）。所有值字段均支持 `{{var}}` 变量与转换管道，
/// 在发送前解析；secret 语义的字段（token/password/apiKeyValue）在
/// UI 层脱敏显示。
@freezed
@HiveType(typeId: 14)
class AuthConfig with _$AuthConfig {
  const factory AuthConfig({
    @HiveField(0) @Default(AuthType.inherit) AuthType type,

    /// Bearer Token
    @HiveField(1) @Default('') String token,

    /// Basic Auth 用户名
    @HiveField(2) @Default('') String username,

    /// Basic Auth 密码
    @HiveField(3) @Default('') String password,

    /// API Key 键名（如 `X-API-Key`）
    @HiveField(4) @Default('') String apiKeyName,

    /// API Key 值
    @HiveField(5) @Default('') String apiKeyValue,

    /// API Key 注入位置：[apiKeyAddToHeader] 或 [apiKeyAddToQuery]
    @HiveField(6) @Default(AuthConfig.apiKeyAddToHeader) String apiKeyAddTo,
  }) = _AuthConfig;

  factory AuthConfig.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigFromJson(json);

  const AuthConfig._();

  /// API Key 注入位置：Header
  static const String apiKeyAddToHeader = 'header';

  /// API Key 注入位置：Query Params
  static const String apiKeyAddToQuery = 'query';
}
