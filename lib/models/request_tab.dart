import 'package:freezed_annotation/freezed_annotation.dart';

import 'http_request.dart';

part 'request_tab.freezed.dart';
part 'request_tab.g.dart';

@freezed
class RequestTab with _$RequestTab {
  const factory RequestTab({
    required String id,
    required HttpRequest request,
    @Default(false) bool isDirty,
    DateTime? lastAccessed,
  }) = _RequestTab;

  factory RequestTab.fromJson(Map<String, dynamic> json) =>
      _$RequestTabFromJson(json);

  factory RequestTab.fromRequest(HttpRequest request) => RequestTab(
        id: request.id,
        request: request,
        lastAccessed: DateTime.now(),
      );
}
