import '../../l10n/l10n.dart';

/// AI Provider 预设常量与云端判定（F9.5 本地组 + F9.9 云端组）
///
/// 单一 OpenAI 兼容客户端（F9.3）靠 `baseURL + model + key` 覆盖全部预设；
/// Anthropic 走其官方 OpenAI 兼容端点，不引第二套客户端。

/// 本地预设（Tier 1，数据不出机器）
const List<String> kAiLocalPresets = ['ollama', 'lmstudio'];

/// 云端预设（Tier 2 BYOK，数据将外发；custom 按 baseUrl 判定归属）
const List<String> kAiCloudPresets = [
  'openai',
  'deepseek',
  'anthropic',
  'custom',
];

/// Provider 预设 → 固定展示名（'custom' 的展示名走 l10n，见 [aiPresetLabel]）
const Map<String, String> kAiPresetLabels = {
  'ollama': 'Ollama',
  'lmstudio': 'LM Studio',
  'openai': 'OpenAI',
  'deepseek': 'DeepSeek',
  'anthropic': 'Anthropic',
  'custom': 'custom',
};

/// 预设 → 默认 Base URL（'custom' 无默认值，选中原样保留）
const Map<String, String> kAiPresetBaseUrls = {
  'ollama': 'http://localhost:11434/v1',
  'lmstudio': 'http://localhost:1234/v1',
  'openai': 'https://api.openai.com/v1',
  'deepseek': 'https://api.deepseek.com/v1',
  'anthropic': 'https://api.anthropic.com/v1',
};

String aiPresetLabel(String preset) => preset == 'custom'
    ? L10nBridge.t.ai_presetCustom
    : (kAiPresetLabels[preset] ?? preset);

/// 云端判定（F9.9 隐私门 / provider chip / Key 必填校验共用）
///
/// 云端三预设恒云端；'custom' 按 baseUrl 是否 loopback 判定（指向本机
/// 等价 Tier 1，无需隐私门与 Key）；本地预设恒本地。
bool isCloudPreset(String preset, String baseUrl) {
  if (kAiLocalPresets.contains(preset)) return false;
  if (preset == 'custom') return !_isLoopbackHost(baseUrl);
  return true;
}

bool _isLoopbackHost(String baseUrl) {
  final host =
      (Uri.tryParse(baseUrl.trim())?.host ?? '').toLowerCase().replaceAll(
            RegExp(r'[\[\]]'),
            '',
          );
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}
