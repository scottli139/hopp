import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
@HiveType(typeId: 4)
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @HiveField(0) @Default('system') String themeMode,
    @HiveField(1) @Default('en') String language,
    @HiveField(2) @Default(14) double editorFontSize,
    @HiveField(3) @Default('monospace') String editorFontFamily,
    @HiveField(4) @Default(true) bool validateCertificates,
    @HiveField(5) @Default(30000) int requestTimeoutMs,
    @HiveField(6) @Default(false) bool followRedirects,
    @HiveField(7) @Default(5) int maxRedirects,

    /// AI 助手总开关（F9.5，Tier 1 本地模型；默认关闭）
    @HiveField(8) @Default(false) bool aiEnabled,

    /// AI 服务预设标识（'ollama' / 'lmstudio' / 'custom'）
    @HiveField(9) @Default('ollama') String aiProviderPreset,

    /// OpenAI 兼容 API 地址（Ollama: http://localhost:11434/v1）
    @HiveField(10) @Default('http://localhost:11434/v1') String aiBaseUrl,

    /// 模型名（本地服务为手填，如 'qwen2.5:7b'）
    @HiveField(11) @Default('') String aiModel,

    /// API Key（本地服务留空；Tier 2 用，keychain 存储随 M8.7）
    @HiveField(12) @Default('') String aiApiKey,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  factory AppSettings.defaults() => const AppSettings();
}
