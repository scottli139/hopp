import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../providers/ai/ai_provider.dart';
import '../../providers/settings/settings_provider.dart';
import '../../services/ai/llm_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_controls.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';

/// Provider 预设 → 展示名
const Map<String, String> kAiPresetLabels = {
  'ollama': 'Ollama',
  'lmstudio': 'LM Studio',
  'custom': '自定义',
};

/// 预设 → 默认 Base URL（'custom' 无默认值，选中原样保留）
const Map<String, String> kAiPresetBaseUrls = {
  'ollama': 'http://localhost:11434/v1',
  'lmstudio': 'http://localhost:1234/v1',
};

String aiPresetLabel(String preset) => kAiPresetLabels[preset] ?? preset;

/// AI 可用门控：总开关开启且模型名已配置
bool isAiReady(AppSettings? settings) =>
    settings != null &&
    settings.aiEnabled &&
    settings.aiModel.trim().isNotEmpty;

/// 打开 AI 设置对话框
Future<T?> openAiSettingsDialog<T>(BuildContext context) {
  return showAppDialog<T>(
    context: context,
    title: 'AI 设置',
    width: 480,
    child: const AiSettingsDialog(),
  );
}

/// AI 未就绪时的统一提示（带「打开设置」入口）
void showAiNotReadySnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('未启用本地 AI 或未配置模型'),
      action: SnackBarAction(
        label: '打开设置',
        textColor: AppColors.onBrand,
        onPressed: () => openAiSettingsDialog(context),
      ),
    ),
  );
}

enum _ConnState { idle, checking, ok, fail }

/// AI 设置对话框（F9.5，Tier 1 本地模型配置）
///
/// 布局按原型 `docs/design/tier1_ai_preview.html` 画板 A：
/// 启用开关行 → Provider 预设分段 → Base URL / Model / API Key 三个输入
/// （Key 脱敏 + 可见性切换）→ 连接状态行（成功绿点 / 失败黄警示 +
/// 「检查连接」）→ 底部「取消」「保存」。
///
/// 保存走 [SettingsNotifier.updateAiSettings]；连接探测用
/// [llmClientProvider] 发一条最小 chat（user「ping」），任何成功响应
/// 即视为已连接，连接 / HTTP / 格式错误均按未连接展示并保留具体文案。
class AiSettingsDialog extends ConsumerStatefulWidget {
  const AiSettingsDialog({super.key});

  @override
  ConsumerState<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends ConsumerState<AiSettingsDialog> {
  late bool _enabled;
  late String _preset;
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _apiKeyCtrl;
  bool _showKey = false;
  _ConnState _conn = _ConnState.idle;
  String _connDetail = '';

  @override
  void initState() {
    super.initState();
    final settings =
        ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults();
    _enabled = settings.aiEnabled;
    _preset = settings.aiProviderPreset;
    _baseUrlCtrl = TextEditingController(text: settings.aiBaseUrl);
    _modelCtrl = TextEditingController(text: settings.aiModel);
    _apiKeyCtrl = TextEditingController(text: settings.aiApiKey);
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _conn = _ConnState.checking;
      _connDetail = '';
    });
    try {
      final client = ref.read(llmClientProvider);
      await client.chat(
        baseUrl: _baseUrlCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        apiKey: _apiKeyCtrl.text.trim(),
        messages: const [LlmMessage.user('ping')],
      );
      if (mounted) setState(() => _conn = _ConnState.ok);
    } catch (e) {
      if (mounted) {
        setState(() {
          _conn = _ConnState.fail;
          _connDetail = e.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    await ref.read(settingsProvider.notifier).updateAiSettings(
          aiEnabled: _enabled,
          aiProviderPreset: _preset,
          aiBaseUrl: _baseUrlCtrl.text.trim(),
          aiModel: _modelCtrl.text.trim(),
          aiApiKey: _apiKeyCtrl.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Column(
      key: const Key('ai_settings_dialog'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 启用开关行
        Row(
          children: [
            Expanded(
              child: Text(
                '启用本地 AI',
                style: AppTextStyles.body13.copyWith(color: t.textPrimary),
              ),
            ),
            AppSwitch(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ],
        ),
        const SizedBox(height: AppMetrics.space16),

        // Provider 预设
        _fieldLabel('Provider 预设'),
        const SizedBox(height: AppMetrics.space4 + 2),
        _buildPresetSegmented(context),
        const SizedBox(height: AppMetrics.space12),

        // Base URL
        _fieldLabel('Base URL'),
        const SizedBox(height: AppMetrics.space4 + 2),
        AppTextField(
          fieldKey: const Key('ai_base_url_field'),
          controller: _baseUrlCtrl,
          compact: true,
          hintText: 'http://localhost:11434/v1',
        ),
        const SizedBox(height: AppMetrics.space12),

        // Model
        _fieldLabel('Model'),
        const SizedBox(height: AppMetrics.space4 + 2),
        AppTextField(
          fieldKey: const Key('ai_model_field'),
          controller: _modelCtrl,
          compact: true,
          hintText: 'qwen2.5:7b',
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppMetrics.space4 + 1),
          child: Text(
            '手填，如 llama3.1:8b',
            style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
          ),
        ),
        const SizedBox(height: AppMetrics.space12),

        // API Key（脱敏 + 可见性切换）
        _fieldLabel('API Key'),
        const SizedBox(height: AppMetrics.space4 + 2),
        AppTextField(
          fieldKey: const Key('ai_api_key_field'),
          controller: _apiKeyCtrl,
          compact: true,
          obscureText: !_showKey,
          hintText: '留空即可',
          suffix: GestureDetector(
            onTap: () => setState(() => _showKey = !_showKey),
            child: Icon(
              _showKey
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 14,
              color: t.textTertiary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppMetrics.space4 + 1),
          child: Text(
            '本地模型通常无需 Key，留空即可；仅 Tier 2 云端使用',
            style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
          ),
        ),
        const SizedBox(height: AppMetrics.space12),

        // 连接状态行
        _buildConnRow(context),

        // 底部按钮
        const SizedBox(height: AppMetrics.space16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton.ghost(
              label: '取消',
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppMetrics.space8),
            AppButton.primary(
              key: const Key('ai_settings_save_button'),
              label: '保存',
              size: AppButtonSize.small,
              onPressed: _save,
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.caption12.copyWith(
        color: context.appTheme.textSecondary,
      ),
    );
  }

  Widget _buildPresetSegmented(BuildContext context) {
    final t = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: AppMetrics.br6,
      ),
      child: Row(
        children: [
          for (final entry in kAiPresetLabels.entries)
            Expanded(
              child: _PresetSegment(
                label: entry.value,
                selected: _preset == entry.key,
                onTap: () {
                  setState(() {
                    _preset = entry.key;
                    // 选预设自动填 Base URL；自定义保留当前值
                    final url = kAiPresetBaseUrls[entry.key];
                    if (url != null) _baseUrlCtrl.text = url;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnRow(BuildContext context) {
    final t = context.appTheme;

    final Color bg;
    final List<Widget> children;
    switch (_conn) {
      case _ConnState.idle:
        bg = t.surface;
        children = [
          Icon(Icons.info_outline, size: 14, color: t.textTertiary),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Text(
              '尚未检查连接',
              style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
            ),
          ),
          _checkButton(),
        ];
      case _ConnState.checking:
        bg = t.surface;
        children = [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: t.brand),
          ),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Text(
              '正在检查连接…',
              style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
            ),
          ),
        ];
      case _ConnState.ok:
        bg = t.successSoft;
        children = [
          Container(
            width: 8,
            height: 8,
            decoration:
                const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Text(
              '已连接 · ${aiPresetLabel(_preset)} · ${_modelCtrl.text.trim()}',
              style: AppTextStyles.caption12.copyWith(
                color: t.success,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ];
      case _ConnState.fail:
        bg = t.warningSoft;
        children = [
          Icon(Icons.warning_amber_rounded, size: 14, color: t.warning),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Text(
              _connDetail,
              style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _checkButton(),
        ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.space8 + 2,
        vertical: AppMetrics.space8 + 1,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppMetrics.br6),
      child: Row(children: children),
    );
  }

  Widget _checkButton() {
    return AppButton.ghost(
      key: const Key('ai_check_connection_button'),
      label: '检查连接',
      size: AppButtonSize.small,
      onPressed: _conn == _ConnState.checking ? null : _checkConnection,
    );
  }
}

class _PresetSegment extends StatefulWidget {
  const _PresetSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PresetSegment> createState() => _PresetSegmentState();
}

class _PresetSegmentState extends State<_PresetSegment> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMetrics.animFast,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? t.brandSoft : AppColors.transparent,
            borderRadius: AppMetrics.br4,
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.caption12.copyWith(
              color: selected
                  ? t.brand
                  : (_hovering ? t.textPrimary : t.textSecondary),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
