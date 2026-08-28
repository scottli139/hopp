/// OpenAPI/Swagger 解析器
///
/// 将 OpenAPI 3.x（JSON/YAML）与 Swagger 2.0（JSON，内部转换为 3.0 形态）
/// 文档解析为轻量的 [OpenApiSpec] 模型。解析层只负责「读懂」文档，
/// 不依赖 Flutter / Hive，可独立测试。
library;

import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../import_export_exception.dart';
import 'openapi_spec.dart';

/// OpenAPI/Swagger 解析器
class OpenApiParser {
  /// 支持的 HTTP 方法（path item 内的操作 key）
  static const _httpMethods = {
    'get',
    'put',
    'post',
    'delete',
    'options',
    'head',
    'patch',
    'trace',
  };

  /// 骨架生成的最大嵌套深度
  static const _maxSkeletonDepth = 6;

  /// 解析文档内容（JSON 或 YAML）
  ///
  /// 抛出 [ImportException]（unknownFormat）：无法解码、不是 Map、
  /// 缺少 openapi/swagger 版本标识或缺少 paths。
  OpenApiSpec parse(String content) {
    final doc = _decodeDocument(content);

    final openapi = doc['openapi']?.toString();
    final swagger = doc['swagger']?.toString();
    final isV3 = openapi != null && openapi.startsWith('3.');
    final isV2 = swagger == '2.0';
    if (!isV3 && !isV2) {
      throw const ImportException(
        code: ImportErrorCode.unknownFormat,
        message: '无法识别为 OpenAPI/Swagger 文档',
      );
    }

    final normalized = isV2 ? _convertV2(doc) : doc;
    if (normalized['paths'] is! Map<String, dynamic>) {
      throw const ImportException(
        code: ImportErrorCode.unknownFormat,
        message: '无法识别为 OpenAPI/Swagger 文档：缺少 paths',
      );
    }

    return _parseDocument(
      normalized,
      specVersion: isV2 ? '2.0' : (openapi ?? '3.0.0'),
    );
  }

  // ==================== 解码 ====================

  /// 解码 JSON / YAML 文本为 plain Map
  Map<String, dynamic> _decodeDocument(String content) {
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on Exception catch (_) {
      try {
        decoded = loadYaml(content);
      } on Exception catch (_) {
        throw const ImportException(
          code: ImportErrorCode.unknownFormat,
          message: '无法识别为 OpenAPI/Swagger 文档',
        );
      }
    }

    final plain = _toPlain(decoded);
    if (plain is! Map<String, dynamic>) {
      throw const ImportException(
        code: ImportErrorCode.unknownFormat,
        message: '无法识别为 OpenAPI/Swagger 文档',
      );
    }
    return plain;
  }

  /// 递归将 YamlMap/YamlList 转换为 plain Map/List
  dynamic _toPlain(dynamic node) {
    if (node is Map) {
      return node.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), _toPlain(value)),
      );
    }
    if (node is List) {
      return node.map(_toPlain).toList();
    }
    return node;
  }

  // ==================== 3.0 解析 ====================

  /// 解析（或转换后的）3.0 形态文档
  OpenApiSpec _parseDocument(
    Map<String, dynamic> doc, {
    required String specVersion,
  }) {
    final paths = doc['paths'] as Map<String, dynamic>;
    final operations = <OpenApiOperation>[];
    final tagOrder = <String>[];

    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final pathItem = pathEntry.value;
      if (pathItem is! Map<String, dynamic>) {
        continue;
      }
      final sharedParams = _resolveParameters(pathItem['parameters'], doc);

      for (final opEntry in pathItem.entries) {
        final method = opEntry.key.toLowerCase();
        if (!_httpMethods.contains(method)) {
          continue;
        }
        final op = opEntry.value;
        if (op is! Map<String, dynamic>) {
          continue;
        }
        final operation = _parseOperation(path, method, op, sharedParams, doc);
        operations.add(operation);
        final tag = operation.tag;
        if (tag != null && !tagOrder.contains(tag)) {
          tagOrder.add(tag);
        }
      }
    }

    final authResult = _parseAuth(doc);

    return OpenApiSpec(
      title: _parseTitle(doc),
      specVersion: specVersion,
      serverUrl: _parseServerUrl(doc),
      tagOrder: tagOrder,
      operations: operations,
      auth: authResult.auth,
      oauthNotices: authResult.oauthNotices,
    );
  }

  /// 文档标题（info.title，缺失时给默认名）
  String _parseTitle(Map<String, dynamic> doc) {
    final info = doc['info'];
    if (info is Map<String, dynamic>) {
      final title = info['title']?.toString().trim();
      if (title != null && title.isNotEmpty) {
        return title;
      }
    }
    return 'OpenAPI Import';
  }

  /// servers[0].url
  String? _parseServerUrl(Map<String, dynamic> doc) {
    final servers = doc['servers'];
    if (servers is List && servers.isNotEmpty) {
      final first = servers.first;
      if (first is Map<String, dynamic>) {
        final url = first['url']?.toString().trim();
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }
    return null;
  }

  /// 解析单个操作
  OpenApiOperation _parseOperation(
    String path,
    String method,
    Map<String, dynamic> op,
    List<Map<String, dynamic>> sharedParams,
    Map<String, dynamic> doc,
  ) {
    final opParams = _resolveParameters(op['parameters'], doc);
    final merged = _mergeParameters(sharedParams, opParams);

    final pathParams = <OpenApiParam>[];
    final queryParams = <OpenApiParam>[];
    final headerParams = <OpenApiParam>[];

    for (final param in merged) {
      final name = param['name']?.toString() ?? '';
      if (name.isEmpty) {
        continue;
      }
      final required = param['required'] == true;
      final schema = _resolveSchema(param['schema'], doc, <String>{});
      final value = _paramValue(param, schema);

      switch (param['in']?.toString()) {
        case 'path':
          // path 参数恒启用且留空占位
          pathParams.add(OpenApiParam(name: name, enabled: true));
        case 'query':
          queryParams.add(
            OpenApiParam(
              name: name,
              value: value,
              enabled: required || value.isNotEmpty,
            ),
          );
        case 'header':
          headerParams.add(
            OpenApiParam(
              name: name,
              value: value,
              enabled: required || value.isNotEmpty,
            ),
          );
      }
    }

    // tag：取第一个
    String? tag;
    final tags = op['tags'];
    if (tags is List && tags.isNotEmpty) {
      final first = tags.first?.toString().trim();
      if (first != null && first.isNotEmpty) {
        tag = first;
      }
    }

    return OpenApiOperation(
      id: '$method $path',
      method: method,
      path: path,
      name: _operationName(method, path, op),
      tag: tag,
      pathParams: pathParams,
      queryParams: queryParams,
      headerParams: headerParams,
      body: _parseBody(op['requestBody'], doc),
    );
  }

  /// 命名优先级：summary → operationId → 'GET /path'
  String _operationName(String method, String path, Map<String, dynamic> op) {
    final summary = op['summary']?.toString().trim();
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }
    final operationId = op['operationId']?.toString().trim();
    if (operationId != null && operationId.isNotEmpty) {
      return operationId;
    }
    return '${method.toUpperCase()} $path';
  }

  // ==================== 参数 ====================

  /// 解析 parameters 列表（顶层 $ref 逐个解析）
  List<Map<String, dynamic>> _resolveParameters(
    dynamic raw,
    Map<String, dynamic> doc,
  ) {
    final result = <Map<String, dynamic>>[];
    if (raw is! List) {
      return result;
    }
    for (final item in raw) {
      final resolved = _resolveRefChain(item, doc, <String>{});
      if (resolved is Map<String, dynamic>) {
        result.add(resolved);
      }
    }
    return result;
  }

  /// 合并 path 级与 operation 级参数（同名同 in 时 operation 覆盖）
  List<Map<String, dynamic>> _mergeParameters(
    List<Map<String, dynamic>> shared,
    List<Map<String, dynamic>> operation,
  ) {
    final result = List<Map<String, dynamic>>.of(shared);
    for (final param in operation) {
      final index = result.indexWhere(
        (s) => s['name'] == param['name'] && s['in'] == param['in'],
      );
      if (index >= 0) {
        result[index] = param;
      } else {
        result.add(param);
      }
    }
    return result;
  }

  /// 参数取值：example → examples[0].value → schema.example →
  /// schema.default → schema.enum[0] → ''
  String _paramValue(Map<String, dynamic> param, Map<String, dynamic> schema) {
    final value = param['example'] ??
        _firstExampleValue(param['examples']) ??
        schema['example'] ??
        schema['default'] ??
        _firstEnumValue(schema['enum']);
    return _stringify(value);
  }

  /// examples Map 的第一条 value
  dynamic _firstExampleValue(dynamic examples) {
    if (examples is Map && examples.isNotEmpty) {
      final first = examples.values.first;
      if (first is Map) {
        return first['value'];
      }
      return first;
    }
    return null;
  }

  /// enum 列表的第一个值
  dynamic _firstEnumValue(dynamic enumValues) {
    if (enumValues is List && enumValues.isNotEmpty) {
      return enumValues.first;
    }
    return null;
  }

  /// 值转字符串（标量 toString，Map/List jsonEncode）
  String _stringify(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return jsonEncode(value);
  }

  // ==================== $ref ====================

  /// 解析顶层 $ref 链（用于 parameter / requestBody 对象），循环返回空 Map
  dynamic _resolveRefChain(
    dynamic node,
    Map<String, dynamic> doc,
    Set<String> visited,
  ) {
    dynamic current = node;
    while (current is Map && current[r'$ref'] is String) {
      final ref = current[r'$ref'].toString();
      if (visited.contains(ref)) {
        return <String, dynamic>{};
      }
      visited.add(ref);
      current = _lookupRef(doc, ref);
    }
    return current;
  }

  /// 查找本地 $ref（仅支持 #/... 形式），未找到返回 null
  dynamic _lookupRef(Map<String, dynamic> doc, String ref) {
    if (!ref.startsWith('#/')) {
      return null;
    }
    dynamic current = doc;
    for (final segment in ref.substring(2).split('/')) {
      final key = segment.replaceAll('~1', '/').replaceAll('~0', '~');
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  /// 解析 schema 的 $ref（兄弟字段覆盖在解析结果之上），循环返回空 Map
  Map<String, dynamic> _resolveSchema(
    dynamic schema,
    Map<String, dynamic> doc,
    Set<String> visited,
  ) {
    if (schema is! Map) {
      return <String, dynamic>{};
    }
    final map = Map<String, dynamic>.from(
      schema.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    final ref = map[r'$ref'];
    if (ref is String) {
      if (visited.contains(ref)) {
        return <String, dynamic>{};
      }
      visited.add(ref);
      final resolved = _resolveSchema(_lookupRef(doc, ref), doc, visited);
      map.remove(r'$ref');
      return {...resolved, ...map};
    }
    return map;
  }

  // ==================== Body ====================

  /// 解析 requestBody
  OpenApiBody? _parseBody(dynamic requestBodyRaw, Map<String, dynamic> doc) {
    if (requestBodyRaw == null) {
      return null;
    }
    final requestBody = _resolveRefChain(requestBodyRaw, doc, <String>{});
    if (requestBody is! Map<String, dynamic>) {
      return null;
    }
    final content = requestBody['content'];
    if (content is! Map<String, dynamic> || content.isEmpty) {
      return null;
    }

    final contentKey = _selectContentKey(content.keys.toList());
    final media = content[contentKey];
    if (media is! Map<String, dynamic>) {
      return null;
    }

    final example = media['example'] ?? _firstExampleValue(media['examples']);

    if (contentKey == 'application/x-www-form-urlencoded') {
      return _buildUrlEncodedBody(media, example, doc);
    }

    final isJson =
        contentKey == 'application/json' || contentKey.contains('+json');
    final rawContentType = isJson ? 'json' : _inferRawContentType(contentKey);

    if (example != null) {
      return OpenApiBody(
        content: _pretty(example),
        bodyType: 'raw',
        rawContentType: rawContentType,
      );
    }
    final skeleton = _buildSkeleton(media['schema'], doc, <String>{}, 0);
    return OpenApiBody(
      content: _pretty(skeleton),
      bodyType: 'raw',
      rawContentType: rawContentType,
      isSkeleton: true,
    );
  }

  /// content key 优先级：application/json → 含 '+json' →
  /// application/x-www-form-urlencoded → 第一个
  String _selectContentKey(List<String> keys) {
    if (keys.contains('application/json')) {
      return 'application/json';
    }
    for (final key in keys) {
      if (key.contains('+json')) {
        return key;
      }
    }
    if (keys.contains('application/x-www-form-urlencoded')) {
      return 'application/x-www-form-urlencoded';
    }
    return keys.first;
  }

  /// 构建 urlencoded body（'a=b&c=' 形式）
  OpenApiBody _buildUrlEncodedBody(
    Map<String, dynamic> media,
    dynamic example,
    Map<String, dynamic> doc,
  ) {
    final fields = <String, dynamic>{};
    var isSkeleton = false;
    if (example is Map) {
      for (final entry in example.entries) {
        fields[entry.key.toString()] = entry.value;
      }
    } else {
      final skeleton = _buildSkeleton(media['schema'], doc, <String>{}, 0);
      if (skeleton is Map) {
        for (final entry in skeleton.entries) {
          fields[entry.key.toString()] = entry.value;
        }
      }
      isSkeleton = true;
    }

    final body =
        fields.entries.map((e) => '${e.key}=${_stringify(e.value)}').join('&');
    return OpenApiBody(
      content: body,
      bodyType: 'x-www-form-urlencoded',
      rawContentType: 'text',
      isSkeleton: isSkeleton,
    );
  }

  /// 按 content key 推断 rawContentType
  ///
  /// 取值集合与项目惯例一致（见 PostmanMapper._mapRawContentType 与
  /// curl_import_service）：json/xml/html/javascript/text。
  String _inferRawContentType(String contentKey) {
    final ct = contentKey.toLowerCase();
    if (ct.contains('json')) {
      return 'json';
    }
    if (ct.contains('xml') || ct.contains('soap')) {
      return 'xml';
    }
    if (ct.contains('html')) {
      return 'html';
    }
    if (ct.contains('javascript')) {
      return 'javascript';
    }
    return 'text';
  }

  /// 输出 pretty 字符串（String 原样，Map/List pretty JSON，标量 toString）
  String _pretty(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  /// 按 schema 生成骨架
  ///
  /// 每个节点遵循 example → default → enum[0] → 类型占位
  /// （string→""、integer/number→0、boolean→false、array→[]、object→递归）。
  /// 深度超过 [_maxSkeletonDepth] 或 $ref 循环时返回 {}。
  dynamic _buildSkeleton(
    dynamic schemaRaw,
    Map<String, dynamic> doc,
    Set<String> visited,
    int depth,
  ) {
    if (depth > _maxSkeletonDepth) {
      return <String, dynamic>{};
    }
    final schema = _resolveSchema(schemaRaw, doc, visited);
    if (schema.isEmpty) {
      return <String, dynamic>{};
    }

    final example = schema['example'];
    if (example != null) {
      return example;
    }
    final defaultValue = schema['default'];
    if (defaultValue != null) {
      return defaultValue;
    }
    final enumValues = schema['enum'];
    if (enumValues is List && enumValues.isNotEmpty) {
      return enumValues.first;
    }

    final type = schema['type']?.toString();
    if (type == 'object' || (type == null && schema['properties'] is Map)) {
      final properties = schema['properties'];
      if (properties is! Map) {
        return <String, dynamic>{};
      }
      final result = <String, dynamic>{};
      for (final entry in properties.entries) {
        // 每个分支复制 visited：循环保护按路径生效，不误伤兄弟引用
        result[entry.key.toString()] = _buildSkeleton(
          entry.value,
          doc,
          Set<String>.of(visited),
          depth + 1,
        );
      }
      return result;
    }
    if (type == 'array' || (type == null && schema.containsKey('items'))) {
      return <dynamic>[];
    }
    if (type == 'integer' || type == 'number') {
      return 0;
    }
    if (type == 'boolean') {
      return false;
    }
    return '';
  }

  // ==================== Auth ====================

  /// 解析 securitySchemes 与 root security
  ///
  /// 规则：root security 首个条目引用的 scheme 若受支持则采用，否则取
  /// 文档序第一个受支持的；root `security: []` 显式空 → 不配置；未声明
  /// security 字段 → 取文档序第一个受支持的。oauth2/openIdConnect 记入
  /// oauthNotices。
  ({AuthSchemeInfo? auth, List<String> oauthNotices}) _parseAuth(
    Map<String, dynamic> doc,
  ) {
    final components = doc['components'];
    final schemes = components is Map<String, dynamic>
        ? components['securitySchemes']
        : null;
    if (schemes is! Map<String, dynamic> || schemes.isEmpty) {
      return (auth: null, oauthNotices: const <String>[]);
    }

    final oauthNotices = <String>[];
    final supported = <String, AuthSchemeInfo>{};

    for (final entry in schemes.entries) {
      final raw = entry.value;
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final name = entry.key;
      switch (raw['type']?.toString()) {
        case 'http':
          final scheme = raw['scheme']?.toString().toLowerCase();
          if (scheme == 'bearer') {
            supported[name] = const AuthSchemeInfo(kind: 'bearer');
          } else if (scheme == 'basic') {
            supported[name] = const AuthSchemeInfo(kind: 'basic');
          }
        case 'apiKey':
          supported[name] = AuthSchemeInfo(
            kind: 'apiKey',
            apiKeyName: raw['name']?.toString(),
            apiKeyInQuery: raw['in']?.toString() == 'query',
          );
        case 'oauth2':
        case 'openIdConnect':
          oauthNotices.add(name);
      }
    }

    AuthSchemeInfo? auth;
    final security = doc['security'];
    if (security is List) {
      if (security.isNotEmpty) {
        final first = security.first;
        final firstName = first is Map && first.isNotEmpty
            ? first.keys.first.toString()
            : null;
        auth = supported[firstName] ??
            (supported.isNotEmpty ? supported.values.first : null);
      }
      // security: [] 显式空 → 不配置
    } else if (supported.isNotEmpty) {
      auth = supported.values.first;
    }

    return (auth: auth, oauthNotices: oauthNotices);
  }

  // ==================== Swagger 2.0 → 3.0 转换 ====================

  /// 将 Swagger 2.0 文档转换为 3.0 形态（之后走同一套解析）
  Map<String, dynamic> _convertV2(Map<String, dynamic> v2) {
    final result = <String, dynamic>{'openapi': '3.0.0'};

    final info = v2['info'];
    if (info is Map<String, dynamic>) {
      result['info'] = info;
    }

    // servers：schemes[0] + '://' + host + basePath（host 缺失 → 无 servers）
    final host = v2['host']?.toString();
    if (host != null && host.isNotEmpty) {
      final schemes = v2['schemes'];
      final scheme = schemes is List && schemes.isNotEmpty
          ? schemes.first.toString()
          : 'https';
      final basePath = v2['basePath']?.toString() ?? '';
      result['servers'] = [
        {'url': '$scheme://$host$basePath'},
      ];
    }

    // components
    final components = <String, dynamic>{};
    final definitions = v2['definitions'];
    if (definitions is Map<String, dynamic>) {
      components['schemas'] = definitions;
    }
    final parameters = v2['parameters'];
    if (parameters is Map<String, dynamic>) {
      components['parameters'] = parameters;
    }
    final responses = v2['responses'];
    if (responses is Map<String, dynamic>) {
      components['responses'] = responses;
    }
    final securityDefinitions = v2['securityDefinitions'];
    if (securityDefinitions is Map<String, dynamic>) {
      components['securitySchemes'] =
          _convertV2SecurityDefinitions(securityDefinitions);
    }
    if (components.isNotEmpty) {
      result['components'] = components;
    }

    final security = v2['security'];
    if (security is List) {
      result['security'] = security;
    }

    // paths
    final globalConsumes = v2['consumes'];
    final v2paths = v2['paths'];
    final paths = <String, dynamic>{};
    if (v2paths is Map<String, dynamic>) {
      for (final entry in v2paths.entries) {
        final item = entry.value;
        if (item is Map<String, dynamic>) {
          paths[entry.key] = _convertV2PathItem(item, globalConsumes);
        }
      }
    }
    result['paths'] = paths;

    // 重写 $ref 前缀（#/definitions/ → #/components/schemas/ 等）
    final rewritten = _rewriteRefs(result);
    return rewritten as Map<String, dynamic>;
  }

  /// securityDefinitions → securitySchemes
  Map<String, dynamic> _convertV2SecurityDefinitions(
    Map<String, dynamic> definitions,
  ) {
    final schemes = <String, dynamic>{};
    for (final entry in definitions.entries) {
      final raw = entry.value;
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      switch (raw['type']?.toString()) {
        case 'basic':
          schemes[entry.key] = {'type': 'http', 'scheme': 'basic'};
        case 'apiKey':
          schemes[entry.key] = {
            'type': 'apiKey',
            'name': raw['name'],
            'in': raw['in'],
          };
        case 'oauth2':
          schemes[entry.key] = {'type': 'oauth2'};
        default:
          schemes[entry.key] = {'type': raw['type']};
      }
    }
    return schemes;
  }

  /// 转换 path item（含共享 parameters）
  Map<String, dynamic> _convertV2PathItem(
    Map<String, dynamic> item,
    dynamic globalConsumes,
  ) {
    final result = <String, dynamic>{};
    for (final entry in item.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key == 'parameters') {
        // path 级参数：body/formData 无处挂载，仅转换普通参数
        result[key] = _convertV2Parameters(value, globalConsumes).params;
        continue;
      }
      if (_httpMethods.contains(key.toLowerCase()) &&
          value is Map<String, dynamic>) {
        result[key] = _convertV2Operation(value, globalConsumes);
        continue;
      }
      result[key] = value;
    }
    return result;
  }

  /// 转换 operation（consumes 决定 body content key）
  Map<String, dynamic> _convertV2Operation(
    Map<String, dynamic> op,
    dynamic globalConsumes,
  ) {
    final result = <String, dynamic>{};
    for (final entry in op.entries) {
      if (entry.key == 'parameters' || entry.key == 'consumes') {
        continue;
      }
      result[entry.key] = entry.value;
    }

    final converted = _convertV2Parameters(
      op['parameters'],
      op['consumes'] ?? globalConsumes,
    );
    if (converted.params.isNotEmpty) {
      result['parameters'] = converted.params;
    }
    if (converted.requestBody != null) {
      result['requestBody'] = converted.requestBody;
    }
    return result;
  }

  /// 转换 2.0 parameters：body → requestBody；formData → 合成 object
  /// schema 的 urlencoded requestBody；其余包装出 schema 字段
  ({List<Map<String, dynamic>> params, Map<String, dynamic>? requestBody})
      _convertV2Parameters(dynamic raw, dynamic consumes) {
    final params = <Map<String, dynamic>>[];
    Map<String, dynamic>? requestBody;
    if (raw is! List) {
      return (params: params, requestBody: requestBody);
    }

    final formProps = <String, dynamic>{};
    final formRequired = <String>[];

    for (final item in raw) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      // $ref 原样保留（后续统一重写为 components 路径）
      if (item[r'$ref'] is String) {
        params.add(Map<String, dynamic>.from(item));
        continue;
      }

      final inLoc = item['in']?.toString();
      if (inLoc == 'body') {
        final contentKey = _firstConsumes(consumes) ?? 'application/json';
        requestBody = {
          'content': {
            contentKey: {
              'schema': item['schema'] ?? <String, dynamic>{},
            },
          },
        };
        continue;
      }
      if (inLoc == 'formData') {
        final name = item['name']?.toString() ?? '';
        if (name.isEmpty) {
          continue;
        }
        formProps[name] = _v2ParamSchema(item);
        if (item['required'] == true) {
          formRequired.add(name);
        }
        continue;
      }

      params.add({
        'name': item['name'],
        'in': inLoc,
        if (item['required'] == true) 'required': true,
        'schema': _v2ParamSchema(item),
      });
    }

    if (formProps.isNotEmpty) {
      requestBody = {
        'content': {
          'application/x-www-form-urlencoded': {
            'schema': {
              'type': 'object',
              'properties': formProps,
              if (formRequired.isNotEmpty) 'required': formRequired,
            },
          },
        },
      };
    }

    return (params: params, requestBody: requestBody);
  }

  /// 2.0 参数内联类型字段 → 3.0 schema（保留 example/default/enum/type）
  Map<String, dynamic> _v2ParamSchema(Map<String, dynamic> param) {
    return {
      if (param['type'] != null) 'type': param['type'],
      if (param['default'] != null) 'default': param['default'],
      if (param['enum'] != null) 'enum': param['enum'],
      if (param['items'] != null) 'items': param['items'],
      if (param['example'] != null) 'example': param['example'],
      if (param['x-example'] != null) 'example': param['x-example'],
    };
  }

  /// consumes 列表的第一个值
  String? _firstConsumes(dynamic consumes) {
    if (consumes is List && consumes.isNotEmpty) {
      return consumes.first.toString();
    }
    return null;
  }

  /// 深度重写 $ref 前缀
  dynamic _rewriteRefs(dynamic node) {
    if (node is Map) {
      return node.map<String, dynamic>((key, value) {
        final k = key.toString();
        if (k == r'$ref' && value is String) {
          return MapEntry(k, _rewriteRef(value));
        }
        return MapEntry(k, _rewriteRefs(value));
      });
    }
    if (node is List) {
      return node.map(_rewriteRefs).toList();
    }
    return node;
  }

  /// 单个 $ref 前缀重写
  String _rewriteRef(String ref) {
    if (ref.startsWith('#/definitions/')) {
      return ref.replaceFirst('#/definitions/', '#/components/schemas/');
    }
    if (ref.startsWith('#/parameters/')) {
      return ref.replaceFirst('#/parameters/', '#/components/parameters/');
    }
    if (ref.startsWith('#/responses/')) {
      return ref.replaceFirst('#/responses/', '#/components/responses/');
    }
    return ref;
  }
}
