/// `.hopp.json` 导出文件解析（F4.4 CLI）
///
/// 与 `HoppExportService` 的输出一一对应；字段缺失/类型错误抛
/// [FormatException]（上层记 exit 2）。
library;

import 'package:hopp/models/auth_config.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/pre_request_step.dart';

/// 导出文件头部标识
const String kExportFormatId = 'hopp-cli';

// ---------- JSON 工具 ----------

String _reqString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! String) {
    throw FormatException('Missing or invalid "$key"');
  }
  return v;
}

Map<String, dynamic> _asMap(Object? v, String key) {
  if (v is! Map<String, dynamic>) {
    throw FormatException('Invalid "$key" (expected object)');
  }
  return v;
}

List<dynamic> _asList(Object? v, String key) {
  if (v == null) {
    return const [];
  }
  if (v is! List) {
    throw FormatException('Invalid "$key" (expected array)');
  }
  return v;
}

/// 集合树节点（children 嵌套）
class ExportCollectionNode {
  const ExportCollectionNode({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.sortOrder,
    required this.auth,
    required this.preRequestChain,
    required this.preRequestRetryOn401,
    required this.children,
  });

  factory ExportCollectionNode._fromJson(Map<String, dynamic> json) {
    return ExportCollectionNode(
      id: _reqString(json, 'id'),
      name: _reqString(json, 'name'),
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      auth: json['auth'] == null
          ? const AuthConfig()
          : AuthConfig.fromJson(_asMap(json['auth'], 'auth')),
      preRequestChain: [
        for (final e in _asList(json['preRequestChain'], 'preRequestChain'))
          PreRequestStep.fromJson(_asMap(e, 'preRequestChain[]')),
      ],
      preRequestRetryOn401: json['preRequestRetryOn401'] as bool? ?? false,
      children: [
        for (final e in _asList(json['children'], 'children'))
          ExportCollectionNode._fromJson(_asMap(e, 'children[]')),
      ],
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final int sortOrder;
  final AuthConfig auth;
  final List<PreRequestStep> preRequestChain;
  final bool preRequestRetryOn401;
  final List<ExportCollectionNode> children;
}

/// 解析后的导出文档
class HoppExportDocument {
  HoppExportDocument({
    required this.collection,
    required this.requests,
    required this.environments,
    required this.globals,
    this.activeEnvironmentId,
  });

  /// 解析导出文档 JSON
  factory HoppExportDocument.fromJson(Map<String, dynamic> json) {
    final format = json['format'];
    if (format != kExportFormatId) {
      throw FormatException(
        'Not a Hopp CLI file (format: $format, expected "$kExportFormatId")',
      );
    }
    final version = (json['version'] as num?)?.toInt();
    if (version != 1) {
      throw FormatException('Unsupported version: $version (expected 1)');
    }

    final collectionJson = json['collection'];
    if (collectionJson is! Map<String, dynamic>) {
      throw const FormatException('Missing "collection" object');
    }

    return HoppExportDocument(
      collection: ExportCollectionNode._fromJson(collectionJson),
      requests: [
        for (final e in _asList(json['requests'], 'requests'))
          HttpRequest.fromJson(_asMap(e, 'requests[]')),
      ],
      environments: [
        for (final e in _asList(json['environments'], 'environments'))
          Environment.fromJson(_asMap(e, 'environments[]')),
      ],
      globals: [
        for (final e in _asList(json['globals'], 'globals'))
          EnvironmentVariable.fromJson(_asMap(e, 'globals[]')),
      ],
      activeEnvironmentId: json['activeEnvironmentId'] as String?,
    );
  }

  final ExportCollectionNode collection;
  final List<HttpRequest> requests;
  final List<Environment> environments;
  final List<EnvironmentVariable> globals;
  final String? activeEnvironmentId;

  /// 以 Collection 模型重建全部集合节点（Auth / 预请求链继承解析用）
  late final Map<String, Collection> collectionsById = () {
    final map = <String, Collection>{};
    void walk(ExportCollectionNode node) {
      map[node.id] = Collection(
        id: node.id,
        name: node.name,
        description: node.description,
        parentId: node.parentId,
        sortOrder: node.sortOrder,
        auth: node.auth,
        preRequestChain: node.preRequestChain,
        preRequestRetryOn401: node.preRequestRetryOn401,
      );
      node.children.forEach(walk);
    }

    walk(collection);
    return map;
  }();

  /// 按集合树 DFS（sortOrder 排序）顺序返回全部请求：
  /// 每个集合先执行直属请求（sortOrder 升序），再按 sortOrder 递归子集合。
  late final List<HttpRequest> dfsRequests = () {
    final byParent = <String?, List<HttpRequest>>{};
    for (final r in requests) {
      byParent.putIfAbsent(r.parentId, () => []).add(r);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final ordered = <HttpRequest>[];
    void walk(ExportCollectionNode node) {
      ordered.addAll(byParent[node.id] ?? const []);
      [...node.children]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))
        ..forEach(walk);
    }

    walk(collection);
    // parentId 不在导出集合树中的请求（异常情况）按原顺序追加，避免静默丢失
    final known = ordered.map((r) => r.id).toSet();
    for (final r in requests) {
      if (!known.contains(r.id)) {
        ordered.add(r);
      }
    }
    return ordered;
  }();
}
