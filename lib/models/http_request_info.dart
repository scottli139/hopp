import 'package:freezed_annotation/freezed_annotation.dart';

import 'key_value_pair.dart';

part 'http_request_info.freezed.dart';
part 'http_request_info.g.dart';

/// 实际发送的 HTTP 请求信息
///
/// 用于在 Response 区域的 Request Tab 中展示实际发送出去的完整请求内容，
/// 包括用户填写的 headers 以及 Dio 自动添加的 headers（如 User-Agent 等）
@freezed
class HttpRequestInfo with _$HttpRequestInfo {
  const factory HttpRequestInfo({
    /// HTTP 方法
    required String method,

    /// 基础 URL（不包含查询参数）
    required String baseUrl,

    /// 完整 URL（包含查询参数）
    required String fullUrl,

    /// 请求协议（http/https）
    required String scheme,

    /// 请求主机名
    required String host,

    /// 请求端口
    int? port,

    /// 请求路径
    required String path,

    /// 查询参数
    @Default([]) List<KeyValuePair> queryParams,

    /// 实际发送的请求头（包括自动添加的）
    @Default([]) List<KeyValuePair> headers,

    /// 由 HTTP 客户端自动添加的 header keys（小写）
    ///
    /// 在构建请求信息时按来源记录：用户手动填写的 header 不在此列，
    /// 即使 key 与常见自动 header 同名（如自定义 Host）也不会被误标。
    @Default([]) List<String> autoHeaderKeys,

    /// 请求体内容
    String? body,

    /// 请求体类型
    String? bodyType,

    /// 请求体大小（字节）
    int? bodySize,

    /// 请求时间戳
    required DateTime timestamp,
  }) = _HttpRequestInfo;

  factory HttpRequestInfo.fromJson(Map<String, dynamic> json) =>
      _$HttpRequestInfoFromJson(json);

  const HttpRequestInfo._();

  /// 获取特定 header 的值
  String? getHeader(String key) {
    final keyLower = key.toLowerCase();
    for (final header in headers) {
      if (header.key.toLowerCase() == keyLower) {
        return header.value;
      }
    }
    return null;
  }

  /// 是否有请求体
  bool get hasBody => body != null && body!.isNotEmpty;

  /// 获取 User-Agent
  String? get userAgent => getHeader('user-agent');

  /// 获取 Content-Type
  String? get contentType => getHeader('content-type');

  /// 获取 Content-Length
  String? get contentLength => getHeader('content-length');

  /// 获取 Accept header
  String? get accept => getHeader('accept');

  /// 获取 Authorization header
  String? get authorization => getHeader('authorization');
}
