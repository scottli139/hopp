import 'package:hive/hive.dart';

import '../auth_config.dart';
import '../collection.dart';
import '../http_request.dart';
import '../pre_request_step.dart';

/// 自定义 Collection 适配器（向后兼容）
///
/// 处理扁平化存储重构后新增字段（sortOrder / isExpanded）以及可选字段
/// （children / requests / parentId / description）的默认值，避免旧数据
/// 因缺失字段在读取时抛出类型转换异常。
class CollectionAdapter extends TypeAdapter<Collection> {
  @override
  final int typeId = 3;

  @override
  Collection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Collection(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      parentId: fields[3] as String?,
      children: (fields[4] as List?)?.cast<Collection>() ?? const [],
      requests: (fields[5] as List?)?.cast<HttpRequest>() ?? const [],
      sortOrder: fields[6] as int? ?? 0,
      isExpanded: fields[7] as bool? ?? false,

      // Auth 配置（v3 新增，可能缺失；缺省为 inherit）
      auth: fields[8] as AuthConfig? ?? const AuthConfig(),

      // 预请求链（v4 新增，可能缺失；缺省为空）
      preRequestChain: (fields[9] as List?)?.cast<PreRequestStep>() ?? const [],
      preRequestRetryOn401: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Collection obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.parentId)
      ..writeByte(4)
      ..write(obj.children)
      ..writeByte(5)
      ..write(obj.requests)
      ..writeByte(6)
      ..write(obj.sortOrder)
      ..writeByte(7)
      ..write(obj.isExpanded)
      ..writeByte(8)
      ..write(obj.auth)
      ..writeByte(9)
      ..write(obj.preRequestChain)
      ..writeByte(10)
      ..write(obj.preRequestRetryOn401);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
