/// OpenAPI/Swagger 解析后的轻量模型
///
/// 纯 Dart 类（不使用 freezed / Hive），作为解析层（OpenApiParser）与
/// 映射层（OpenApiMapper）之间的中间表示。Swagger 2.0 文档在解析层内部
/// 先转换为 3.0 形态，因此本模型只描述 3.0 语义。
library;

/// 解析后的 OpenAPI 文档
class OpenApiSpec {
  /// 解析后的 OpenAPI 文档
  const OpenApiSpec({
    required this.title,
    required this.specVersion,
    this.serverUrl,
    this.tagOrder = const [],
    this.operations = const [],
    this.auth,
    this.oauthNotices = const [],
  });

  /// 文档标题（info.title）
  final String title;

  /// 规范版本（如 '3.0.3' 或 '2.0'）
  final String specVersion;

  /// 服务器地址（3.0 取 servers[0].url；2.0 由 schemes/host/basePath 合成；
  /// 无法确定时为 null）
  final String? serverUrl;

  /// tag 在 paths 中首次出现的顺序（用于子集合排序）
  final List<String> tagOrder;

  /// 所有操作（按文档序）
  final List<OpenApiOperation> operations;

  /// 认证方案信息（null = 未配置）
  final AuthSchemeInfo? auth;

  /// 文档中声明但无法自动配置的 OAuth2 / OpenID Connect scheme 名
  final List<String> oauthNotices;
}

/// 单个 API 操作（一个 path + method 组合）
class OpenApiOperation {
  /// 单个 API 操作
  const OpenApiOperation({
    required this.id,
    required this.method,
    required this.path,
    required this.name,
    this.tag,
    this.pathParams = const [],
    this.queryParams = const [],
    this.headerParams = const [],
    this.body,
  });

  /// 操作唯一 ID：`'$method $path'`（method 小写）
  final String id;

  /// HTTP 方法（小写，如 'get'）
  final String method;

  /// 路径（如 '/pets/{petId}'）
  final String path;

  /// 请求名称（summary → operationId → 'GET /path'）
  final String name;

  /// 第一个 tag；null 表示平铺到根集合
  final String? tag;

  /// 路径参数（恒 enabled=true，value='' 留空占位）
  final List<OpenApiParam> pathParams;

  /// 查询参数
  final List<OpenApiParam> queryParams;

  /// 请求头参数
  final List<OpenApiParam> headerParams;

  /// 请求体（null = 无 body）
  final OpenApiBody? body;
}

/// 解析后的参数（value / enabled 由解析层按规则算好）
class OpenApiParam {
  /// 解析后的参数
  const OpenApiParam({
    required this.name,
    this.value = '',
    this.enabled = false,
  });

  /// 参数名
  final String name;

  /// 参数值（example → default → enum[0] → ''）
  final String value;

  /// 是否启用（required 或值非空 → true；path 参数恒 true）
  final bool enabled;
}

/// 解析后的请求体
class OpenApiBody {
  /// 解析后的请求体
  const OpenApiBody({
    required this.content,
    required this.bodyType,
    required this.rawContentType,
    this.isSkeleton = false,
  });

  /// body 文本内容（JSON 为 pretty 字符串；urlencoded 为 'a=b&c=' 形式）
  final String content;

  /// Hopp bodyType：'raw' | 'x-www-form-urlencoded'
  final String bodyType;

  /// Hopp rawContentType：'json' | 'xml' | 'html' | 'javascript' | 'text'
  final String rawContentType;

  /// true = 按 schema 生成的骨架（非 spec 内 example，需用户补全）
  final bool isSkeleton;
}

/// 认证方案信息（仅自动支持 bearer / basic / apiKey）
class AuthSchemeInfo {
  /// 认证方案信息
  const AuthSchemeInfo({
    required this.kind,
    this.apiKeyName,
    this.apiKeyInQuery = false,
  });

  /// 方案类型：'bearer' | 'basic' | 'apiKey'
  final String kind;

  /// apiKey 的参数名（kind == 'apiKey' 时非空）
  final String? apiKeyName;

  /// apiKey 是否放在 query（false = header）
  final bool apiKeyInQuery;
}
