import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import 'http_method.dart';
import 'key_value_pair.dart';

part 'http_request.freezed.dart';
part 'http_request.g.dart';

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
