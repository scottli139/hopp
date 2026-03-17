/// Postman 与 Hopp 模型映射器
///
/// 处理 Postman Collection/Environment 与 Hopp 模型之间的双向转换。
library;

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../models/collection.dart';
import '../../models/http_method.dart';
import '../../models/http_request.dart';
import '../../models/key_value_pair.dart';
import '../../utils/app_logger.dart';
import 'postman_schema.dart';

/// Postman 模型映射器
class PostmanMapper {
  static const _uuid = Uuid();

  /// 生成唯一 ID
  static String _generateId() => _uuid.v4();

  /// 生成 UUID
  static String _generateUuid() => _uuid.v4();

  // ==================== Postman -> Hopp ====================

  /// Postman Collection -> Hopp Collection
  static Collection toHoppCollection(PostmanCollection postmanCollection) {
    return Collection(
      id: _generateId(),
      name: postmanCollection.info.name,
      description: postmanCollection.info.description,
      children: _extractFolders(postmanCollection.item),
      requests: _extractRootRequests(postmanCollection.item),
    );
  }

  /// 提取文件夹（递归）
  static List<Collection> _extractFolders(List<PostmanItem> items) {
    final folders = <Collection>[];

    for (final item in items) {
      if (item.isFolder) {
        folders.add(
          Collection(
            id: _generateId(),
            name: item.name,
            description: item.description,
            children: _extractFolders(item.item ?? []),
            requests: _extractRequests(item.item ?? []),
          ),
        );
      }
    }

    return folders;
  }

  /// 提取根级请求
  static List<HttpRequest> _extractRootRequests(List<PostmanItem> items) {
    return items.where((i) => i.isRequest).map(_toHoppRequest).toList();
  }

  /// 提取文件夹内的请求
  static List<HttpRequest> _extractRequests(List<PostmanItem> items) {
    return items.where((i) => i.isRequest).map(_toHoppRequest).toList();
  }

  /// Postman Item -> Hopp HttpRequest
  static HttpRequest _toHoppRequest(PostmanItem item) {
    final request = item.request!;
    final headers = _mapHeaders(request.header);

    return HttpRequest(
      id: _generateId(),
      name: item.name,
      method: _mapHttpMethod(request.method),
      url: _extractUrl(request.url),
      params: _mapQueryParams(request.url.query),
      headers: headers,
      body: _extractBody(request.body),
      bodyType: _mapBodyType(request.body?.mode),
      rawContentType: _mapRawContentType(
        request.body?.options?.raw?.language,
        headers,
      ),
    );
  }

  /// 提取 URL
  static String _extractUrl(PostmanUrl url) {
    // 如果 raw 存在，直接使用
    if (url.raw.isNotEmpty) {
      return url.raw;
    }

    // 否则从组件构建
    final buffer = StringBuffer();

    if (url.protocol != null && url.protocol!.isNotEmpty) {
      buffer.write(url.protocol);
      buffer.write('://');
    }

    if (url.host.isNotEmpty) {
      buffer.write(url.host.join('.'));
    }

    if (url.path.isNotEmpty) {
      buffer.write('/');
      buffer.write(url.path.join('/'));
    }

    return buffer.toString();
  }

  /// 映射 HTTP 方法
  static HttpMethod _mapHttpMethod(String method) {
    final upperMethod = method.toUpperCase();
    switch (upperMethod) {
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

  /// 映射查询参数
  static List<KeyValuePair> _mapQueryParams(List<PostmanQueryParam>? params) {
    if (params == null || params.isEmpty) return [];

    return params
        .map(
          (p) => KeyValuePair(
            id: _generateId(),
            key: p.key,
            value: p.value ?? '',
            enabled: p.enabled,
          ),
        )
        .toList();
  }

  /// 映射请求头
  static List<KeyValuePair> _mapHeaders(List<PostmanHeader>? headers) {
    if (headers == null || headers.isEmpty) return [];

    return headers
        .map(
          (h) => KeyValuePair(
            id: _generateId(),
            key: h.key,
            value: h.value,
            enabled: h.enabled,
          ),
        )
        .toList();
  }

  /// 提取 Body 内容
  static String _extractBody(PostmanBody? body) {
    if (body == null) return '';

    switch (body.mode) {
      case 'raw':
        return body.raw ?? '';
      case 'urlencoded':
        return _encodeUrlEncoded(body.urlencoded);
      case 'formdata':
        return _encodeFormData(body.formdata);
      case 'graphql':
        return _encodeGraphQL(body.graphql);
      case 'binary':
        return '';
      default:
        return '';
    }
  }

  /// 编码 URL 编码数据
  static String _encodeUrlEncoded(List<PostmanUrlEncoded>? data) {
    if (data == null || data.isEmpty) return '';

    final params = data.where((d) => d.enabled).map(
          (d) =>
              '${Uri.encodeComponent(d.key)}=${Uri.encodeComponent(d.value ?? '')}',
        );

    return params.join('&');
  }

  /// 编码 Form Data
  static String _encodeFormData(List<PostmanFormData>? data) {
    if (data == null || data.isEmpty) return '';

    // 对于导入，我们只保留文本类型的值
    final textEntries = data.where((d) => d.enabled && d.type != 'file');

    final params = textEntries.map(
      (d) =>
          '${Uri.encodeComponent(d.key)}=${Uri.encodeComponent(d.value ?? '')}',
    );

    return params.join('&');
  }

  /// 编码 GraphQL
  static String _encodeGraphQL(PostmanGraphQL? graphql) {
    if (graphql == null) return '';

    final map = <String, dynamic>{
      'query': graphql.query,
      if (graphql.variables != null && graphql.variables!.isNotEmpty)
        'variables': jsonDecode(graphql.variables!),
    };

    return jsonEncode(map);
  }

  /// 映射 Body 类型
  static String _mapBodyType(String? mode) {
    switch (mode) {
      case 'raw':
        return 'raw';
      case 'urlencoded':
        return 'x-www-form-urlencoded';
      case 'formdata':
        return 'form-data';
      case 'graphql':
        return 'graphql';
      case 'binary':
        return 'binary';
      default:
        return 'none';
    }
  }

  /// 映射 Raw 内容类型
  ///
  /// 支持从 Postman 的 language 字段或从 Content-Type header 推断
  static String _mapRawContentType(
      String? language, List<KeyValuePair> headers) {
    // 首先尝试从 language 字段映射
    if (language != null && language.isNotEmpty) {
      final normalized = language.toLowerCase().trim();
      AppLogger.info(
        '[PostmanMapper] Mapping raw content type from language: $normalized',
      );

      switch (normalized) {
        case 'json':
          return 'json';
        case 'xml':
          return 'xml';
        case 'html':
          return 'html';
        case 'javascript':
        case 'js':
          return 'javascript';
        case 'text':
          return 'text';
      }
    }

    // 如果 language 为空或无法识别，尝试从 Content-Type header 推断
    final contentTypeHeader = headers
        .where((h) => h.enabled && h.key.toLowerCase() == 'content-type')
        .firstOrNull;

    if (contentTypeHeader != null && contentTypeHeader.value.isNotEmpty) {
      final contentType = contentTypeHeader.value.toLowerCase();
      AppLogger.info(
        '[PostmanMapper] Inferring raw content type from Content-Type header: $contentType',
      );

      if (contentType.contains('application/json') ||
          contentType.contains('text/json')) {
        return 'json';
      } else if (contentType.contains('application/xml') ||
          contentType.contains('text/xml') ||
          contentType.contains('application/soap')) {
        return 'xml';
      } else if (contentType.contains('text/html')) {
        return 'html';
      } else if (contentType.contains('application/javascript') ||
          contentType.contains('text/javascript')) {
        return 'javascript';
      } else if (contentType.contains('text/plain')) {
        return 'text';
      }
    }

    AppLogger.info(
      '[PostmanMapper] Defaulting to text (language: $language, no matching Content-Type header)',
    );
    return 'text';
  }

  // ==================== Hopp -> Postman ====================

  /// Hopp Collection -> Postman Collection
  static PostmanCollection toPostmanCollection(
    Collection collection, {
    PostmanVersion version = PostmanVersion.v2_1,
  }) {
    return PostmanCollection(
      info: PostmanInfo(
        name: collection.name,
        description: collection.description ?? '',
        postmanId: _generateUuid(),
        schema:
            'https://schema.getpostman.com/json/collection/${version.value}/collection.json',
      ),
      item: [
        // 映射子文件夹
        ...collection.children.map(_toPostmanFolder),
        // 映射根级请求
        ...collection.requests.map(_toPostmanRequestItem),
      ],
    );
  }

  /// Hopp Collection -> Postman Folder Item
  static PostmanItem _toPostmanFolder(Collection collection) {
    return PostmanItem(
      name: collection.name,
      description: collection.description,
      item: [
        // 递归映射子文件夹
        ...collection.children.map(_toPostmanFolder),
        // 映射请求
        ...collection.requests.map(_toPostmanRequestItem),
      ],
    );
  }

  /// Hopp HttpRequest -> Postman Request Item
  static PostmanItem _toPostmanRequestItem(HttpRequest request) {
    return PostmanItem(
      name: request.name,
      request: PostmanRequest(
        method: request.method.value.toUpperCase(),
        url: _buildPostmanUrl(request.url, request.params),
        header: request.headers
            .where((h) => h.enabled)
            .map(
              (h) => PostmanHeader(
                key: h.key,
                value: h.value,
                enabled: h.enabled,
              ),
            )
            .toList(),
        body: _buildPostmanBody(request),
      ),
    );
  }

  /// 构建 Postman URL
  static PostmanUrl _buildPostmanUrl(
    String url,
    List<KeyValuePair> params,
  ) {
    final uri = Uri.parse(url);

    return PostmanUrl(
      raw: url,
      protocol: uri.scheme.isNotEmpty ? uri.scheme : 'https',
      host: uri.host.isNotEmpty ? uri.host.split('.') : [],
      path: uri.path.isNotEmpty
          ? (() {
              final parts = uri.path.split('/');
              if (parts.isNotEmpty && parts.first.isEmpty) {
                parts.removeAt(0);
              }
              return parts;
            })()
          : [],
      query: params.isNotEmpty
          ? params
              .where((p) => p.enabled)
              .map(
                (p) => PostmanQueryParam(
                  key: p.key,
                  value: p.value,
                  enabled: p.enabled,
                ),
              )
              .toList()
          : null,
    );
  }

  /// 构建 Postman Body
  static PostmanBody? _buildPostmanBody(HttpRequest request) {
    if (request.bodyType == 'none' || request.body.isEmpty) {
      return null;
    }

    switch (request.bodyType) {
      case 'raw':
        return PostmanBody(
          mode: 'raw',
          raw: request.body,
          options: PostmanBodyOptions(
            raw: PostmanRawOptions(
              language: _mapToRawLanguage(request.rawContentType),
            ),
          ),
        );
      case 'x-www-form-urlencoded':
        return PostmanBody(
          mode: 'urlencoded',
          urlencoded: _parseUrlEncoded(request.body),
        );
      case 'form-data':
        return PostmanBody(
          mode: 'formdata',
          formdata: _parseFormData(request.body),
        );
      case 'graphql':
        return PostmanBody(
          mode: 'graphql',
          graphql: _parseGraphQL(request.body),
        );
      default:
        return null;
    }
  }

  /// 映射到 Raw 语言
  static String _mapToRawLanguage(String contentType) {
    switch (contentType) {
      case 'json':
        return 'json';
      case 'xml':
        return 'xml';
      case 'html':
        return 'html';
      case 'javascript':
        return 'javascript';
      case 'text':
      default:
        return 'text';
    }
  }

  /// 解析 URL 编码数据
  static List<PostmanUrlEncoded> _parseUrlEncoded(String body) {
    if (body.isEmpty) return [];

    final params = body.split('&');
    return params.map((param) {
      final parts = param.split('=');
      return PostmanUrlEncoded(
        key: parts.isNotEmpty ? Uri.decodeComponent(parts[0]) : '',
        value: parts.length > 1 ? Uri.decodeComponent(parts[1]) : '',
        enabled: true,
      );
    }).toList();
  }

  /// 解析 Form Data
  static List<PostmanFormData> _parseFormData(String body) {
    // 简化处理，将文本类型的 form data 作为 key-value
    if (body.isEmpty) return [];

    final params = body.split('&');
    return params.map((param) {
      final parts = param.split('=');
      return PostmanFormData(
        key: parts.isNotEmpty ? Uri.decodeComponent(parts[0]) : '',
        value: parts.length > 1 ? Uri.decodeComponent(parts[1]) : '',
        type: 'text',
        enabled: true,
      );
    }).toList();
  }

  /// 解析 GraphQL
  static PostmanGraphQL? _parseGraphQL(String body) {
    if (body.isEmpty) return null;

    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return PostmanGraphQL(
        query: map['query'] as String? ?? '',
        variables:
            map['variables'] != null ? jsonEncode(map['variables']) : null,
      );
    } catch (_) {
      return PostmanGraphQL(query: body);
    }
  }
}
