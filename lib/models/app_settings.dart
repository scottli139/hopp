import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
@HiveType(typeId: 4)
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @HiveField(0) @Default('system') String themeMode,

    /// 界面语言（F5.9 / M8.8）：'system'（跟随系统）/ 'en' / 'zh'
    /// 注意：v0.16 前该字段为死默认值 'en'，由 storage getSettings 一次性迁移为 'system'
    @HiveField(1) @Default('system') String language,
    @HiveField(2) @Default(14) double editorFontSize,
    @HiveField(3) @Default('monospace') String editorFontFamily,
    @HiveField(4) @Default(true) bool validateCertificates,
    @HiveField(5) @Default(30000) int requestTimeoutMs,
    @HiveField(6) @Default(false) bool followRedirects,
    @HiveField(7) @Default(5) int maxRedirects,

    /// AI 助手总开关（F9.5，Tier 1 本地模型；默认关闭）
    @HiveField(8) @Default(false) bool aiEnabled,

    /// AI 服务预设标识（'ollama' / 'lmstudio' / 'openai' / 'deepseek' / 'anthropic' / 'custom'）
    @HiveField(9) @Default('ollama') String aiProviderPreset,

    /// OpenAI 兼容 API 地址（Ollama: http://localhost:11434/v1）
    @HiveField(10) @Default('http://localhost:11434/v1') String aiBaseUrl,

    /// 模型名（本地服务为手填，如 'qwen2.5:7b'）
    @HiveField(11) @Default('') String aiModel,

    /// 历史明文字段（F9.5 遗留）：M8.9 起 key 本体存 ai_keys 加密 box，
    /// 此处仅作一次性迁移来源，迁移后清空（见 storage getSettings）
    @HiveField(12) @Default('') String aiApiKey,

    /// 界面文字缩放（F5.7 / M8.7）：0.8 / 0.9 / 1.0 / 1.25 / 1.5，默认 1.0
    @HiveField(13) @Default(1.0) double uiScale,

    /// 云端隐私门确认记录（F9.9）：key = 云端预设标识，按 Provider 记一次
    @HiveField(14) @Default({}) Map<String, bool> aiCloudConsents,

    /// 已存 API Key 的预设清单（F9.9，非敏感标志位；key 本体在加密 box）
    @HiveField(15) @Default([]) List<String> aiKeySavedPresets,

    /// 各预设最近使用的 Base URL（F9.9 试用反馈）：预设共享单个 aiBaseUrl
    /// 时，自定义预设填的 URL 会在切换预设后被冲掉；按预设记忆，
    /// 选择预设时优先取此处，其次预设默认端点，最后保留输入框现状
    @HiveField(16) @Default({}) Map<String, String> aiPresetBaseUrls,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  factory AppSettings.defaults() => const AppSettings();
}
