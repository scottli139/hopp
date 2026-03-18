import 'package:hive/hive.dart';

import '../app_settings.dart';

/// 自定义 AppSettings 适配器（向后兼容）
///
/// 处理数据模型变更后的向后兼容问题：
/// - 为缺失字段提供默认值
/// - 支持从旧版本数据平滑迁移
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return AppSettings(
      // 基础字段（早期版本就有）
      themeMode: fields[0] as String? ?? 'system',
      language: fields[1] as String? ?? 'en',
      editorFontSize: fields[2] as double? ?? 14.0,
      editorFontFamily: fields[3] as String? ?? 'monospace',

      // 较新版本添加的字段（可能缺失）
      validateCertificates: fields[4] == null ? true : fields[4] as bool,
      requestTimeoutMs: fields[5] == null ? 30000 : fields[5] as int,
      followRedirects: fields[6] == null ? false : fields[6] as bool,
      maxRedirects: fields[7] == null ? 5 : fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.editorFontSize)
      ..writeByte(3)
      ..write(obj.editorFontFamily)
      ..writeByte(4)
      ..write(obj.validateCertificates)
      ..writeByte(5)
      ..write(obj.requestTimeoutMs)
      ..writeByte(6)
      ..write(obj.followRedirects)
      ..writeByte(7)
      ..write(obj.maxRedirects);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
