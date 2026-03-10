import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import 'http_request.dart';

part 'collection.freezed.dart';
part 'collection.g.dart';

@freezed
@HiveType(typeId: 3)
class Collection with _$Collection {
  const Collection._();

  const factory Collection({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) String? description,
    @HiveField(3) String? parentId,
    @HiveField(4) @Default([]) List<Collection> children,
    @HiveField(5) @Default([]) List<HttpRequest> requests,
    @HiveField(6) @Default(0) int sortOrder,
    @HiveField(7) @Default(false) bool isExpanded,
  }) = _Collection;

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);

  factory Collection.empty() => Collection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Collection',
      );

  bool get isFolder => children.isNotEmpty || requests.isEmpty;
}
