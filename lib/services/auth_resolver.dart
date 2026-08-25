import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/auth_config.dart';
import '../models/collection.dart';
import '../models/http_request.dart';
import '../models/key_value_pair.dart';
import 'variable_resolver.dart';

/// 认证解析器（F8.1）
///
/// 职责：
/// 1. 沿集合继承链解析生效的 [AuthConfig]（请求级 > 就近集合级）
/// 2. 发送前将认证配置应用到请求（字段值先经变量解析），
///    生成 `Authorization` header 或 API Key header/query 参数
///
/// 全部为纯函数，便于单元测试。
class AuthResolver {
  AuthResolver._();

  /// 解析生效的认证配置。
  ///
  /// 规则（与 UI 原型一致）：
  /// - 从请求自身的 `auth` 开始，[AuthType.inherit] 时沿 `parentId`
  ///   向上找最近一个非 inherit 的集合配置；
  /// - [AuthType.none] 显式阻断继承（视为无认证，返回 null）；
  /// - 全链 inherit / 无父级时返回 null（无认证）。
  static AuthConfig? resolveEffective(
    HttpRequest request,
    Map<String, Collection> collectionsById,
  ) {
    if (request.auth.type != AuthType.inherit) {
      return request.auth.type == AuthType.none ? null : request.auth;
    }

    var cursor = request.parentId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final collection = collectionsById[cursor];
      if (collection == null) return null;
      final auth = collection.auth;
      if (auth.type != AuthType.inherit) {
        return auth.type == AuthType.none ? null : auth;
      }
      cursor = collection.parentId;
    }
    return null;
  }

  /// 返回生效认证的来源集合（用于 UI 的「继承自 X」提示）。
  ///
  /// 仅当请求自身为 inherit 且命中集合级非 inherit 配置时返回该集合，
  /// 其余情况返回 null。
  static Collection? inheritedFrom(
    HttpRequest request,
    Map<String, Collection> collectionsById,
  ) {
    if (request.auth.type != AuthType.inherit) return null;

    var cursor = request.parentId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final collection = collectionsById[cursor];
      if (collection == null) return null;
      if (collection.auth.type != AuthType.inherit) return collection;
      cursor = collection.parentId;
    }
    return null;
  }

  /// 集合视角的继承来源（用于集合设置的「继承自 X」提示）。
  ///
  /// 从 [collection] 的父级开始沿 parentId 向上，返回最近一个配置了
  /// 非 inherit 认证的祖先集合（不含自身）；未命中返回 null。
  static Collection? inheritedFromCollection(
    Collection collection,
    Map<String, Collection> collectionsById,
  ) {
    var cursor = collection.parentId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final c = collectionsById[cursor];
      if (c == null) return null;
      if (c.auth.type != AuthType.inherit) return c;
      cursor = c.parentId;
    }
    return null;
  }

  /// 将 [auth] 应用到 [request]。
  ///
  /// 认证字段值经 [resolver] 解析（支持 `{{var}}` 与转换管道）后写入：
  /// - bearer / basic → 覆盖同名 `Authorization` header
  /// - apiKey → 按配置覆盖同名 header 或 query 参数
  ///
  /// 调用方应传入 [resolveEffective] 的结果；inherit / none 时原样返回。
  static HttpRequest apply(
    HttpRequest request,
    AuthConfig auth,
    Map<String, String> variables,
    VariableResolver resolver,
  ) {
    switch (auth.type) {
      case AuthType.inherit:
      case AuthType.none:
        return request;
      case AuthType.bearer:
        final token = resolver.resolve(auth.token, variables);
        return _upsertHeader(request, 'Authorization', 'Bearer $token');
      case AuthType.basic:
        final username = resolver.resolve(auth.username, variables);
        final password = resolver.resolve(auth.password, variables);
        final encoded = base64Encode(utf8.encode('$username:$password'));
        return _upsertHeader(request, 'Authorization', 'Basic $encoded');
      case AuthType.apiKey:
        final name = resolver.resolve(auth.apiKeyName, variables).trim();
        final value = resolver.resolve(auth.apiKeyValue, variables);
        if (name.isEmpty) return request;
        if (auth.apiKeyAddTo == AuthConfig.apiKeyAddToQuery) {
          return _upsertParam(request, name, value);
        }
        return _upsertHeader(request, name, value);
    }
  }

  /// 覆盖同名 header（忽略大小写），追加一条启用的新配置
  static HttpRequest _upsertHeader(
    HttpRequest request,
    String key,
    String value,
  ) {
    final headers = request.headers
        .where((h) => h.key.toLowerCase() != key.toLowerCase())
        .toList();
    headers.add(KeyValuePair(id: const Uuid().v4(), key: key, value: value));
    return request.copyWith(headers: headers);
  }

  /// 覆盖同名 query 参数（大小写敏感，与 URL 参数语义一致）
  static HttpRequest _upsertParam(
    HttpRequest request,
    String key,
    String value,
  ) {
    final params = request.params.where((p) => p.key != key).toList();
    params.add(KeyValuePair(id: const Uuid().v4(), key: key, value: value));
    return request.copyWith(params: params);
  }
}
