/// URL 查询参数同步工具
///
/// 提供 URL 与 Params 列表之间的双向同步功能。
///
/// 使用示例：
/// ```dart
/// // 从 URL 解析参数
/// final params = parseQueryParamsFromUrl('https://api.com?key=value');
///
/// // 构建查询字符串
/// final queryString = buildQueryString(params);
///
/// // 同步参数到 URL
/// final newUrl = syncParamsToUrl('https://api.com', params);
/// ```
library;

import '../models/key_value_pair.dart';

/// 从 URL 解析查询参数
///
/// 解析 URL 中的查询字符串，返回 KeyValuePair 列表。
/// 支持 URL 编码的参数值，会自动解码。
///
/// 参数:
/// - [url]: 完整的 URL，可能包含查询字符串
///
/// 返回:
/// KeyValuePair 列表，key 和 value 已解码
///
/// 示例:
/// ```dart
/// final params = parseQueryParamsFromUrl('https://api.com?a=1&b=2');
/// // params = [KeyValuePair(key: 'a', value: '1'), KeyValuePair(key: 'b', value: '2')]
/// ```
List<KeyValuePair> parseQueryParamsFromUrl(String url) {
  if (url.isEmpty) {
    return [];
  }

  try {
    final uri = Uri.parse(url);
    final queryParams = uri.queryParametersAll;

    final params = <KeyValuePair>[];
    for (final entry in queryParams.entries) {
      final key = entry.key;
      final values = entry.value;

      for (final value in values) {
        params.add(
          KeyValuePair(
            id: DateTime.now().millisecondsSinceEpoch.toString() +
                '_${params.length}',
            key: Uri.decodeQueryComponent(key),
            value: Uri.decodeQueryComponent(value),
            enabled: true,
          ),
        );
      }
    }

    return params;
  } catch (e) {
    // URL 解析失败，返回空列表
    return [];
  }
}

/// 从 URL 中提取 base URL（不含查询参数）
///
/// 提取 URL 的基础部分，包括协议、主机、端口和路径，
/// 但不包括查询字符串和片段。
///
/// 参数:
/// - [url]: 完整的 URL
///
/// 返回:
/// 不含查询参数的 base URL
///
/// 示例:
/// ```dart
/// final baseUrl = extractBaseUrl('https://api.com/path?a=1');
/// // baseUrl = 'https://api.com/path'
/// ```
String extractBaseUrl(String url) {
  if (url.isEmpty) {
    return '';
  }

  try {
    final uri = Uri.parse(url);

    // 构建基础 URL
    final buffer = StringBuffer();

    // 协议
    if (uri.scheme.isNotEmpty) {
      buffer.write('${uri.scheme}://');
    }

    // 用户信息（如果有）
    if (uri.userInfo.isNotEmpty) {
      buffer.write('${uri.userInfo}@');
    }

    // 主机
    buffer.write(uri.host);

    // 端口（如果不是默认端口）
    if (uri.hasPort && !_isDefaultPort(uri.scheme, uri.port)) {
      buffer.write(':${uri.port}');
    }

    // 路径
    buffer.write(uri.path);

    return buffer.toString();
  } catch (e) {
    // URL 解析失败，返回原 URL
    return url;
  }
}

/// 检查是否为默认端口
bool _isDefaultPort(String scheme, int port) {
  if (scheme == 'http' && port == 80) return true;
  if (scheme == 'https' && port == 443) return true;
  return false;
}

/// 将 Params 列表构建为查询字符串
///
/// 将 KeyValuePair 列表转换为 URL 编码的查询字符串。
/// 只包含 enabled=true 且 key 非空的参数。
///
/// 参数:
/// - [params]: KeyValuePair 列表
///
/// 返回:
/// URL 编码的查询字符串（不含开头的 ?）
///
/// 示例:
/// ```dart
/// final queryString = buildQueryString([
///   KeyValuePair(key: 'a', value: '1', enabled: true),
///   KeyValuePair(key: 'b', value: 'hello world', enabled: true),
/// ]);
/// // queryString = 'a=1&b=hello%20world'
/// ```
String buildQueryString(List<KeyValuePair> params) {
  if (params.isEmpty) {
    return '';
  }

  final enabledParams =
      params.where((p) => p.enabled && p.key.isNotEmpty).toList();

  if (enabledParams.isEmpty) {
    return '';
  }

  final pairs = enabledParams.map((p) {
    final encodedKey = Uri.encodeQueryComponent(p.key);
    final encodedValue = Uri.encodeQueryComponent(p.value);
    return '$encodedKey=$encodedValue';
  }).toList();

  return pairs.join('&');
}

/// 将 Params 同步到 URL
///
/// 将 KeyValuePair 列表同步到 URL，构建完整的 URL。
///
/// 参数:
/// - [baseUrl]: 基础 URL（不含查询参数）
/// - [params]: KeyValuePair 列表
///
/// 返回:
/// 完整的 URL，包含查询字符串（如果有参数）
///
/// 示例:
/// ```dart
/// final newUrl = syncParamsToUrl('https://api.com', [
///   KeyValuePair(key: 'page', value: '1', enabled: true),
///   KeyValuePair(key: 'size', value: '10', enabled: true),
/// ]);
/// // newUrl = 'https://api.com?page=1&size=10'
/// ```
String syncParamsToUrl(String baseUrl, List<KeyValuePair> params) {
  if (baseUrl.isEmpty) {
    return '';
  }

  final queryString = buildQueryString(params);

  if (queryString.isEmpty) {
    return baseUrl;
  }

  return '$baseUrl?$queryString';
}

/// 检查 URL 是否包含查询参数
///
/// 参数:
/// - [url]: 要检查的 URL
///
/// 返回:
/// true 如果 URL 包含查询参数
bool hasQueryParams(String url) {
  if (url.isEmpty) {
    return false;
  }

  try {
    final uri = Uri.parse(url);
    return uri.queryParameters.isNotEmpty;
  } catch (e) {
    return false;
  }
}

/// 合并 URL 中的查询参数到现有参数列表
///
/// 将 URL 中的查询参数与现有参数列表合并，
/// URL 中的参数会覆盖现有参数中 key 相同的参数。
///
/// 参数:
/// - [existingParams]: 现有的参数列表
/// - [url]: 包含新参数的 URL
///
/// 返回:
/// 合并后的参数列表
List<KeyValuePair> mergeQueryParams(
  List<KeyValuePair> existingParams,
  String url,
) {
  final newParams = parseQueryParamsFromUrl(url);

  if (newParams.isEmpty) {
    return existingParams;
  }

  // 创建现有参数的副本
  final merged = List<KeyValuePair>.from(existingParams);

  for (final newParam in newParams) {
    // 查找是否存在相同 key 的参数
    final existingIndex = merged.indexWhere(
      (p) => p.key == newParam.key && p.enabled,
    );

    if (existingIndex >= 0) {
      // 更新现有参数
      merged[existingIndex] = merged[existingIndex].copyWith(
        value: newParam.value,
      );
    } else {
      // 添加新参数
      merged.add(newParam);
    }
  }

  return merged;
}
