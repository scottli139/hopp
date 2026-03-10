import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = _HttpResponse;

  factory HttpResponse.fromJson(Map<String, dynamic> json) =>
      _$HttpResponseFromJson(json);

  factory HttpResponse.empty() => const HttpResponse();

  factory HttpResponse.error(String message) => HttpResponse(
        error: message,
        timestamp: DateTime.now(),
      );
}
