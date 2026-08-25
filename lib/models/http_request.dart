import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import 'auth_config.dart';
import 'http_method.dart';
import 'key_value_pair.dart';
import 'pre_request_step.dart';

part 'http_request.freezed.dart';
part 'http_request.g.dart';

/// HTTP 请求模型
///
/// 包含请求的所有配置信息，包括 URL、方法、头部、Body 和请求级别设置。
@freezed
@HiveType(typeId: 2)
class HttpRequest with _$HttpRequest {
  const factory HttpRequest({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) @Default(HttpMethod.get) HttpMethod method,
    @HiveField(3) @Default('') String url,
    @HiveField(4) @Default([]) List<KeyValuePair> params,
    @HiveField(5) @Default([]) List<KeyValuePair> headers,
    @HiveField(6) @Default('') String body,
    @HiveField(7) @Default('none') String bodyType,
    @HiveField(8) String? parentId,
    @HiveField(9) @Default(0) int sortOrder,
    @HiveField(10) @Default('json') String rawContentType,
    // Request Settings (请求级别配置)
    @HiveField(11) @Default(true) bool validateCertificates,
    @HiveField(12) @Default(true) bool followRedirects,
    @HiveField(13) @Default(10) int maxRedirects,
    // Auth 配置（F8.1；默认 type = inherit，沿集合链向上解析）
    @HiveField(14) @Default(AuthConfig()) AuthConfig auth,

    // 预请求链（F8.2；空列表 = 未配置，继承集合默认链）
    @HiveField(15) @Default([]) List<PreRequestStep> preRequestChain,

    // 收到 401 时自动重跑前置链（F8.2；随链一起按层继承）
    @HiveField(16) @Default(false) bool preRequestRetryOn401,
  }) = _HttpRequest;

  factory HttpRequest.fromJson(Map<String, dynamic> json) =>
      _$HttpRequestFromJson(json);

  factory HttpRequest.empty() => HttpRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Request',
        method: HttpMethod.get,
        url: 'https://httpbin.org/get',
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
      );
}
