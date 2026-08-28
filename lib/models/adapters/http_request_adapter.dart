import 'package:hive/hive.dart';

import '../assertion_rule.dart';
import '../auth_config.dart';
import '../http_method.dart';
import '../http_request.dart';
import '../key_value_pair.dart';
import '../pre_request_step.dart';

/// 自定义 HttpRequest 适配器（向后兼容）
///
/// 处理数据模型变更后的向后兼容问题：
/// - 为缺失字段提供默认值
/// - 支持从旧版本数据平滑迁移
///
/// 使用此适配器替代自动生成的适配器，确保：
/// 1. 旧版本应用创建的数据可以在新版本中正常读取
/// 2. 新增字段有合理的默认值
/// 3. 不会因为字段缺失而抛出异常
class HttpRequestAdapter extends TypeAdapter<HttpRequest> {
  @override
  final int typeId = 2;

  @override
  HttpRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return HttpRequest(
      // 基础字段（v1 就有，必须存在）
      id: fields[0] as String,
      name: fields[1] as String,
      method: fields[2] as HttpMethod,
      url: fields[3] as String,
      params: (fields[4] as List?)?.cast<KeyValuePair>() ?? const [],
      headers: (fields[5] as List?)?.cast<KeyValuePair>() ?? const [],
      body: fields[6] as String? ?? '',
      bodyType: fields[7] as String? ?? 'none',
      parentId: fields[8] as String?,
      sortOrder: fields[9] as int? ?? 0,
      rawContentType: fields[10] as String? ?? 'json',

      // Request Settings 字段（v2 新增，可能缺失）
      // 关键：使用 ?? 提供默认值，避免 null 转换异常
      validateCertificates: fields[11] == null ? true : fields[11] as bool,
      followRedirects: fields[12] == null ? true : fields[12] as bool,
      maxRedirects: fields[13] == null ? 10 : fields[13] as int,

      // Auth 配置（v3 新增，可能缺失；缺省为 inherit）
      auth: fields[14] as AuthConfig? ?? const AuthConfig(),

      // 预请求链（v4 新增，可能缺失；缺省为空 = 继承集合链）
      preRequestChain:
          (fields[15] as List?)?.cast<PreRequestStep>() ?? const [],
      preRequestRetryOn401: fields[16] as bool? ?? false,

      // 断言规则（v5 新增，可能缺失；缺省为空）
      assertions: (fields[17] as List?)?.cast<AssertionRule>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, HttpRequest obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.method)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.params)
      ..writeByte(5)
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.body)
      ..writeByte(7)
      ..write(obj.bodyType)
      ..writeByte(8)
      ..write(obj.parentId)
      ..writeByte(9)
      ..write(obj.sortOrder)
      ..writeByte(10)
      ..write(obj.rawContentType)
      ..writeByte(11)
      ..write(obj.validateCertificates)
      ..writeByte(12)
      ..write(obj.followRedirects)
      ..writeByte(13)
      ..write(obj.maxRedirects)
      ..writeByte(14)
      ..write(obj.auth)
      ..writeByte(15)
      ..write(obj.preRequestChain)
      ..writeByte(16)
      ..write(obj.preRequestRetryOn401)
      ..writeByte(17)
      ..write(obj.assertions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HttpRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
