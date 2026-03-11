import 'package:freezed_annotation/freezed_annotation.dart';

import 'certificate_info.dart';
import 'key_value_pair.dart';

part 'http_response.freezed.dart';
part 'http_response.g.dart';

@freezed
class HttpResponse with _$HttpResponse {
  const factory HttpResponse({
    String? body,
    @Default([]) List<KeyValuePair> headers,
    int? statusCode,
    String? statusText,
    int? durationMs,
    int? sizeBytes,
    String? error,
    DateTime? timestamp,
    /// HTTPS 证书信息（仅当请求为 HTTPS 且成功获取证书时存在）
    CertificateInfo? certificateInfo,
  }) = _HttpResponse;

  factory HttpResponse.fromJson(Map<String, dynamic> json) =>
      _$HttpResponseFromJson(json);

  factory HttpResponse.empty() => const HttpResponse();

  factory HttpResponse.error(String message) => HttpResponse(
        error: message,
        timestamp: DateTime.now(),
      );
}
