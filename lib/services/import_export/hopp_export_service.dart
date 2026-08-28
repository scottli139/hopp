/// Hopp 原生导出服务（F4.4，M8.4）
///
/// 把集合（含全部子孙集合的请求）、全部环境与全局变量导出为单个
/// `.hopp.json` 文件，供 CLI/CI 的 `hopp run` 全保真复跑：
/// 断言、预请求链、Auth 配置与变量转换管道全部保留。
///
/// 纯 Dart 实现：数据全部由调用方注入（不依赖 Flutter / path_provider /
/// StorageService / AppLogger），供 GUI 与 CLI 共用。文件写入只用 dart:io。
library;

import 'dart:convert';
import 'dart:io';

import '../../models/assertion_rule.dart';
import '../../models/auth_config.dart';
import '../../models/collection.dart';
import '../../models/environment.dart';
import '../../models/http_request.dart';
import '../../models/key_value_pair.dart';
import '../../models/pre_request_step.dart';

/// Hopp 原生格式导出服务
class HoppExportService {
  const HoppExportService();

  /// 文件头格式标识
  static const String formatId = 'hopp-cli';

  /// 文件头版本号
  static const int formatVersion = 1;

  /// 构建导出文档（深度 JSON，可直接 jsonEncode）。
  ///
  /// - [root]：要导出的根集合
  /// - [allCollections]：全部集合（扁平存储，用于收集子树）
  /// - [allRequests]：全部请求（导出子树内按 parentId 过滤后平铺）
  /// - [environments]：全部环境（secret 变量值一律置空）
  /// - [globals]：全局变量（secret 同样置空）
  /// - [activeEnvironmentId]：导出时激活的环境 ID（CLI 默认环境标记）
  Map<String, dynamic> buildDocument({
    required Collection root,
    required List<Collection> allCollections,
    required List<HttpRequest> allRequests,
    required List<Environment> environments,
    required List<EnvironmentVariable> globals,
    String? activeEnvironmentId,
    DateTime? exportedAt,
  }) {
    // 收集根集合的子树（含根本身）
    final subtreeIds = <String>{root.id};
    void collectSubtree(String parentId) {
      for (final c in allCollections) {
        if (c.parentId == parentId && subtreeIds.add(c.id)) {
          collectSubtree(c.id);
        }
      }
    }

    collectSubtree(root.id);

    final subtreeCollections =
        allCollections.where((c) => subtreeIds.contains(c.id)).toList();
    final subtreeRequests = allRequests
        .where((r) => r.parentId != null && subtreeIds.contains(r.parentId))
        .toList();

    return <String, dynamic>{
      'format': formatId,
      'version': formatVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      if (activeEnvironmentId != null)
        'activeEnvironmentId': activeEnvironmentId,
      'collection': _collectionNodeToJson(root, subtreeCollections),
      'requests': [
        for (final request in subtreeRequests) requestToJson(request),
      ],
      'environments': [
        for (final env in environments) environmentToJson(env),
      ],
      'globals': [for (final v in globals) variableToJson(v)],
    };
  }

  /// 导出到文件，返回写入路径
  Future<String> exportToFile({
    required Collection root,
    required List<Collection> allCollections,
    required List<HttpRequest> allRequests,
    required List<Environment> environments,
    required List<EnvironmentVariable> globals,
    String? activeEnvironmentId,
    required String savePath,
    bool prettyPrint = true,
  }) async {
    final document = buildDocument(
      root: root,
      allCollections: allCollections,
      allRequests: allRequests,
      environments: environments,
      globals: globals,
      activeEnvironmentId: activeEnvironmentId,
    );

    final String jsonString;
    if (prettyPrint) {
      jsonString = const JsonEncoder.withIndent('  ').convert(document);
    } else {
      jsonString = jsonEncode(document);
    }

    final file = File(savePath);
    await file.writeAsString(jsonString);
    return savePath;
  }

  // ---------- 深度序列化（不依赖 freezed toJson 的嵌套行为） ----------

  /// 集合树节点：children 为嵌套子集合（按 sortOrder 排序）
  Map<String, dynamic> _collectionNodeToJson(
    Collection collection,
    List<Collection> allCollections,
  ) {
    final children = allCollections
        .where((c) => c.parentId == collection.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return <String, dynamic>{
      'id': collection.id,
      'name': collection.name,
      if (collection.description != null) 'description': collection.description,
      'parentId': collection.parentId,
      'sortOrder': collection.sortOrder,
      'auth': authToJson(collection.auth),
      'preRequestChain': [
        for (final step in collection.preRequestChain) stepToJson(step),
      ],
      'preRequestRetryOn401': collection.preRequestRetryOn401,
      'children': [
        for (final child in children)
          _collectionNodeToJson(child, allCollections),
      ],
    };
  }

  /// 请求深度 JSON（含 parentId / sortOrder / auth / 预请求链 / 断言）
  static Map<String, dynamic> requestToJson(HttpRequest request) {
    return <String, dynamic>{
      'id': request.id,
      'name': request.name,
      'method': request.method.name,
      'url': request.url,
      'params': [for (final p in request.params) kvToJson(p)],
      'headers': [for (final h in request.headers) kvToJson(h)],
      'body': request.body,
      'bodyType': request.bodyType,
      'parentId': request.parentId,
      'sortOrder': request.sortOrder,
      'rawContentType': request.rawContentType,
      'validateCertificates': request.validateCertificates,
      'followRedirects': request.followRedirects,
      'maxRedirects': request.maxRedirects,
      'auth': authToJson(request.auth),
      'preRequestChain': [
        for (final step in request.preRequestChain) stepToJson(step),
      ],
      'preRequestRetryOn401': request.preRequestRetryOn401,
      'assertions': [
        for (final rule in request.assertions) assertionToJson(rule),
      ],
    };
  }

  /// KV 对深度 JSON
  static Map<String, dynamic> kvToJson(KeyValuePair pair) {
    return <String, dynamic>{
      'id': pair.id,
      'key': pair.key,
      'value': pair.value,
      'enabled': pair.enabled,
    };
  }

  /// Auth 配置深度 JSON
  static Map<String, dynamic> authToJson(AuthConfig auth) {
    return <String, dynamic>{
      'type': auth.type.name,
      'token': auth.token,
      'username': auth.username,
      'password': auth.password,
      'apiKeyName': auth.apiKeyName,
      'apiKeyValue': auth.apiKeyValue,
      'apiKeyAddTo': auth.apiKeyAddTo,
    };
  }

  /// 预请求链步骤深度 JSON
  static Map<String, dynamic> stepToJson(PreRequestStep step) {
    return <String, dynamic>{
      'id': step.id,
      'requestId': step.requestId,
      'enabled': step.enabled,
      'extractions': [
        for (final rule in step.extractions) extractionToJson(rule),
      ],
    };
  }

  /// 提取规则深度 JSON
  static Map<String, dynamic> extractionToJson(ExtractionRule rule) {
    return <String, dynamic>{
      'id': rule.id,
      'source': rule.source.name,
      'path': rule.path,
      'targetVariable': rule.targetVariable,
      'enabled': rule.enabled,
    };
  }

  /// 断言规则深度 JSON
  static Map<String, dynamic> assertionToJson(AssertionRule rule) {
    return <String, dynamic>{
      'id': rule.id,
      'enabled': rule.enabled,
      'target': rule.target.name,
      'targetArg': rule.targetArg,
      'operator': rule.operator.name,
      'expected': rule.expected,
    };
  }

  /// 环境深度 JSON（secret 变量值一律置空字符串）
  static Map<String, dynamic> environmentToJson(Environment env) {
    return <String, dynamic>{
      'id': env.id,
      'name': env.name,
      if (env.description != null) 'description': env.description,
      'sortOrder': env.sortOrder,
      'variables': [for (final v in env.variables) variableToJson(v)],
    };
  }

  /// 变量深度 JSON：secret 值一律置空字符串（CLI 用 --env-var / 进程环境注入）
  static Map<String, dynamic> variableToJson(EnvironmentVariable variable) {
    return <String, dynamic>{
      'id': variable.id,
      'key': variable.key,
      'value': variable.isSecret ? '' : variable.value,
      'type': variable.type.name,
      'enabled': variable.enabled,
    };
  }
}
