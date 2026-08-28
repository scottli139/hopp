/// OpenAPI 与 Hopp 模型映射器
///
/// 将解析后的 [OpenApiSpec] 转换为扁平化存储的三元组
/// （根集合, [子集合], [请求]），层级通过 parentId 串联，
/// 组织方式与 PostmanMapper.toHoppCollectionFlat 一致。
library;

import 'package:uuid/uuid.dart';

import '../../../models/auth_config.dart';
import '../../../models/collection.dart';
import '../../../models/http_method.dart';
import '../../../models/http_request.dart';
import '../../../models/key_value_pair.dart';
import 'openapi_spec.dart';

/// 需要用户补全的占位说明
class ImportPlaceholder {
  /// 需要用户补全的占位说明
  const ImportPlaceholder({
    required this.kind,
    required this.method,
    required this.path,
    required this.detail,
  });

  /// 占位类型：'body'（请求体骨架）| 'pathVars'（路径变量）| 'formData'（表单骨架）
  final String kind;

  /// HTTP 方法（大写）
  final String method;

  /// 原始路径（如 '/pet/{petId}'）
  final String path;

  /// 说明（pathVars 为变量名列表；其余为补全提示）
  final String detail;
}

/// OpenAPI → Hopp 映射结果
class OpenApiMapResult {
  /// OpenAPI → Hopp 映射结果
  const OpenApiMapResult({
    required this.rootCollection,
    required this.childCollections,
    required this.allRequests,
    this.baseUrl,
    this.placeholders = const [],
    this.oauthNotices = const [],
    this.authDescription,
  });

  /// 根集合
  final Collection rootCollection;

  /// tag 对应的子集合（parentId = 根集合 id，sortOrder 按 tagOrder）
  final List<Collection> childCollections;

  /// 所有请求（parentId 指向所属集合）
  final List<HttpRequest> allRequests;

  /// 服务器地址（spec.serverUrl，用于全局变量 baseUrl）
  final String? baseUrl;

  /// 需用户补全的占位说明
  final List<ImportPlaceholder> placeholders;

  /// OAuth2 / OpenID Connect 提示（透传 spec.oauthNotices）
  final List<String> oauthNotices;

  /// 认证配置的人类可读描述（无认证为 null）
  final String? authDescription;
}

/// OpenAPI 模型映射器
class OpenApiMapper {
  static const _uuid = Uuid();

  /// 路径模板变量：{petId} → {{petId}}
  static final _pathVarPattern = RegExp(r'\{([^{}]+)\}');

  /// OpenApiSpec → Hopp 三元组
  ///
  /// [selectedOpIds] 非空时只映射选中的操作（空 tag 子集合随之省略）。
  OpenApiMapResult toHopp(OpenApiSpec spec, {Set<String>? selectedOpIds}) {
    final rootId = _uuid.v4();
    final rootCollection = Collection(
      id: rootId,
      name: spec.title,
      auth: _mapAuth(spec.auth),
    );

    final operations = spec.operations
        .where((op) => selectedOpIds == null || selectedOpIds.contains(op.id))
        .toList();

    // tag → 子集合（按 tagOrder 排序，仅保留有选中请求的 tag）
    final opTags = operations.map((op) => op.tag).whereType<String>().toSet();
    final usedTags = spec.tagOrder.where(opTags.contains).toList();
    for (final tag in opTags) {
      if (!usedTags.contains(tag)) {
        usedTags.add(tag);
      }
    }

    final childCollections = <Collection>[];
    final tagToCollectionId = <String, String>{};
    for (var i = 0; i < usedTags.length; i++) {
      final id = _uuid.v4();
      tagToCollectionId[usedTags[i]] = id;
      childCollections.add(
        Collection(
          id: id,
          name: usedTags[i],
          parentId: rootId,
          sortOrder: i,
        ),
      );
    }

    final allRequests = <HttpRequest>[];
    final placeholders = <ImportPlaceholder>[];
    for (var i = 0; i < operations.length; i++) {
      final op = operations[i];
      final parentId = op.tag != null ? tagToCollectionId[op.tag]! : rootId;
      allRequests.add(_mapRequest(op, spec.serverUrl, parentId, i));

      if (op.pathParams.isNotEmpty) {
        placeholders.add(
          ImportPlaceholder(
            kind: 'pathVars',
            method: op.method.toUpperCase(),
            path: op.path,
            detail: op.pathParams.map((p) => p.name).join(', '),
          ),
        );
      }
      final body = op.body;
      if (body != null && body.isSkeleton) {
        placeholders.add(
          ImportPlaceholder(
            kind:
                body.bodyType == 'x-www-form-urlencoded' ? 'formData' : 'body',
            method: op.method.toUpperCase(),
            path: op.path,
            detail: body.bodyType == 'x-www-form-urlencoded'
                ? 'Form fields generated from schema — review and fill in'
                : 'Body generated from schema skeleton — review and fill in',
          ),
        );
      }
    }

    return OpenApiMapResult(
      rootCollection: rootCollection,
      childCollections: childCollections,
      allRequests: allRequests,
      baseUrl: spec.serverUrl,
      placeholders: placeholders,
      oauthNotices: spec.oauthNotices,
      authDescription: _authDescription(spec.auth),
    );
  }

  /// OpenApiOperation → HttpRequest
  HttpRequest _mapRequest(
    OpenApiOperation op,
    String? serverUrl,
    String parentId,
    int sortOrder,
  ) {
    final path = op.path.replaceAllMapped(
      _pathVarPattern,
      (match) => '{{${match.group(1)}}}',
    );
    final url = serverUrl != null ? '{{baseUrl}}$path' : path;
    final body = op.body;

    return HttpRequest(
      id: _uuid.v4(),
      name: op.name,
      method: _mapMethod(op.method),
      url: url,
      params: op.queryParams.map(_mapParam).toList(),
      headers: op.headerParams.map(_mapParam).toList(),
      body: body?.content ?? '',
      bodyType: body?.bodyType ?? 'none',
      rawContentType: body?.rawContentType ?? 'json',
      parentId: parentId,
      sortOrder: sortOrder,
    );
  }

  /// OpenApiParam → KeyValuePair
  KeyValuePair _mapParam(OpenApiParam param) {
    return KeyValuePair(
      id: _uuid.v4(),
      key: param.name,
      value: param.value,
      enabled: param.enabled,
    );
  }

  /// HTTP 方法字符串 → HttpMethod 枚举
  ///
  /// 未知方法回退 get，与项目惯例一致
  /// （HttpMethod.fromString / PostmanMapper._mapHttpMethod）。
  HttpMethod _mapMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.get;
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'DELETE':
        return HttpMethod.delete;
      case 'PATCH':
        return HttpMethod.patch;
      case 'HEAD':
        return HttpMethod.head;
      case 'OPTIONS':
        return HttpMethod.options;
      default:
        return HttpMethod.get;
    }
  }

  /// AuthSchemeInfo → AuthConfig（挂在根集合上）
  AuthConfig _mapAuth(AuthSchemeInfo? info) {
    switch (info?.kind) {
      case 'bearer':
        return const AuthConfig(type: AuthType.bearer);
      case 'basic':
        return const AuthConfig(type: AuthType.basic);
      case 'apiKey':
        return AuthConfig(
          type: AuthType.apiKey,
          apiKeyName: info?.apiKeyName ?? '',
          apiKeyAddTo: (info?.apiKeyInQuery ?? false)
              ? AuthConfig.apiKeyAddToQuery
              : AuthConfig.apiKeyAddToHeader,
        );
      default:
        return const AuthConfig();
    }
  }

  /// 认证配置的人类可读描述
  String? _authDescription(AuthSchemeInfo? info) {
    switch (info?.kind) {
      case 'bearer':
        return 'Bearer Token (fill in token)';
      case 'basic':
        return 'Basic Auth (fill in username/password)';
      case 'apiKey':
        final where = (info?.apiKeyInQuery ?? false) ? 'Query' : 'Header';
        return 'API Key ($where: ${info?.apiKeyName ?? ''} — fill in the key)';
      default:
        return null;
    }
  }
}
