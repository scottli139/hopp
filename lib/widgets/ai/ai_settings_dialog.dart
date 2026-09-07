import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../providers/ai/ai_provider.dart';
import '../../providers/core/providers.dart';
import '../../providers/settings/settings_provider.dart';
import '../../services/ai/ai_presets.dart';
import '../../services/ai/llm_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_controls.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';
import 'ai_privacy_gate.dart';

/// AI 可用门控：总开关开启且模型名已配置；F9.9 起云端预设额外要求
/// 已保存 API Key（key 本体在 ai_keys 加密 box，这里只看非敏感标志位
/// 保持同步判定）
bool isAiReady(AppSettings? settings) {
  if (settings == null ||
      !settings.aiEnabled ||
      settings.aiModel.trim().isEmpty) {
    return false;
  }
  if (isCloudPreset(settings.aiProviderPreset, settings.aiBaseUrl)) {
    return settings.aiKeySavedPresets.contains(settings.aiProviderPreset);
  }
  return true;
}

/// 打开 AI 设置对话框
Future<T?> openAiSettingsDialog<T>(BuildContext context) {
  return showAppDialog<T>(
    context: context,
    title: context.l10n.ai_settingsTitle,
    width: 480,
    child: const AiSettingsDialog(),
  );
}

/// AI 未就绪时的统一提示（带「打开设置」入口）
void showAiNotReadySnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.ai_notReady),
      action: SnackBarAction(
        label: context.l10n.ai_openSettings,
        textColor: AppColors.onBrand,
        onPressed: () => openAiSettingsDialog(context),
      ),
    ),
  );
}

enum _ConnState { idle, checking, ok, fail }

/// AI 设置对话框（F9.5 Tier 1 + F9.9 Tier 2 BYOK）
///
/// 布局按原型 `docs/design/tier2_byok_preview.html` 画板 A：
/// 启用开关行 → Provider 预设两组分段（本地组 / 云端组，云端组带
/// 「数据将外发」警示标签）→ Base URL / Model / API Key 三个输入
/// （Key 只写不读：已存显示加密说明条 + 可清除，输入即覆盖；云端
/// 预设必填校验）→ 连接状态行（成功绿点 / 失败黄警示 +
/// 「检查连接」，云端预设先过隐私门）→ 底部「重置隐私确认」
/// 「取消」「保存」。
///
/// Key 本体存 ai_keys 加密 box（StorageService.writeAiKey），
/// AppSettings 只维护 aiKeySavedPresets 标志位。
class AiSettingsDialog extends ConsumerStatefulWidget {
  const AiSettingsDialog({super.key});

  @override
  ConsumerState<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends ConsumerState<AiSettingsDialog> {
  late bool _enabled;
  late String _preset;
  late bool _keySaved;
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _apiKeyCtrl;

  /// 各预设 Base URL 记忆（会话内暂存 + 保存时持久化，F9.9 试用反馈：
  /// 自定义预设填的 URL 不能在切换预设后被冲掉）
  late Map<String, String> _presetUrls;
  bool _showKey = false;
  bool _keyError = false;
  _ConnState _conn = _ConnState.idle;
  String _connDetail = '';

  @override
  void initState() {
    super.initState();
    final settings =
        ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults();
    _enabled = settings.aiEnabled;
    _preset = settings.aiProviderPreset;
    _keySaved = settings.aiKeySavedPresets.contains(_preset);
    _presetUrls = {...settings.aiPresetBaseUrls};
    _baseUrlCtrl = TextEditingController(text: settings.aiBaseUrl);
    _modelCtrl = TextEditingController(text: settings.aiModel);
    // Key 只写不读：controller 恒空开场，不回显已存 key
    _apiKeyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  bool get _isCloud => isCloudPreset(_preset, _baseUrlCtrl.text.trim());

  void _selectPreset(String preset) {
    setState(() {
      // 离开前暂存当前预设的 URL（会话内记忆），切回时恢复
      _presetUrls[_preset] = _baseUrlCtrl.text.trim();
      _preset = preset;
      _keyError = false;
      final settings = ref.read(settingsProvider).valueOrNull;
      _keySaved = settings?.aiKeySavedPresets.contains(preset) ?? false;
      // 选中预设的 URL：优先按预设记忆，其次官方默认端点；
      // 都没有（自定义从未填过）保留输入框现状
      final url = _presetUrls[preset] ?? kAiPresetBaseUrls[preset];
      if (url != null && url.isNotEmpty) _baseUrlCtrl.text = url;
    });
  }

  Future<void> _checkConnection() async {
    final baseUrl = _baseUrlCtrl.text.trim();
    // F9.9：云端预设「检查连接」同样真实外发，先过隐私门
    if (isCloudPreset(_preset, baseUrl)) {
      final consented = await ensureAiCloudConsent(
        context,
        ref,
        preset: _preset,
        baseUrl: baseUrl,
        capability: context.l10n.ai_gateCapCheck,
      );
      if (!consented || !mounted) return;
    }
    setState(() {
      _conn = _ConnState.checking;
      _connDetail = '';
    });
    try {
      final keyInput = _apiKeyCtrl.text.trim();
      final apiKey = keyInput.isNotEmpty
          ? keyInput
          : await ref.read(storageServiceProvider).readAiKey(_preset);
      if (!mounted) return;
      final client = ref.read(llmClientProvider);
      await client.chat(
        baseUrl: baseUrl,
        model: _modelCtrl.text.trim(),
        apiKey: apiKey,
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
    final keyInput = _apiKeyCtrl.text.trim();
    // 云端预设必填校验：未存过且未输入 → 标红不落库
    if (_enabled && _isCloud && !_keySaved && keyInput.isEmpty) {
      setState(() => _keyError = true);
      return;
    }

    final settings = ref.read(settingsProvider).valueOrNull;
    final savedPresets = {...?settings?.aiKeySavedPresets};
    if (keyInput.isNotEmpty) {
      await ref.read(storageServiceProvider).writeAiKey(_preset, keyInput);
      savedPresets.add(_preset);
    }
    // 持久化各预设的 URL 记忆（含当前预设当前值）
    _presetUrls[_preset] = _baseUrlCtrl.text.trim();
    await ref.read(settingsProvider.notifier).updateAiSettings(
          aiEnabled: _enabled,
          aiProviderPreset: _preset,
          aiBaseUrl: _baseUrlCtrl.text.trim(),
          aiModel: _modelCtrl.text.trim(),
          aiKeySavedPresets: savedPresets.toList(),
          aiPresetBaseUrls: _presetUrls,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _clearKey() async {
    await ref.read(storageServiceProvider).deleteAiKey(_preset);
    final current = ref.read(settingsProvider).valueOrNull;
    if (current != null) {
      final savedPresets = {...current.aiKeySavedPresets}..remove(_preset);
      await ref
          .read(settingsProvider.notifier)
          .updateAiSettings(aiKeySavedPresets: savedPresets.toList());
    }
    if (mounted) setState(() => _keySaved = false);
  }

  Future<void> _resetConsents() async {
    await ref.read(settingsProvider.notifier).resetAiCloudConsents();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ai_consentResetDone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final l10n = context.l10n;

    // 内容整体可滚动：两组分段 + key 说明条使内容变高，
    // 界面缩放 125%/150% 或小窗口下不溢出
    return SingleChildScrollView(
      child: Column(
        key: const Key('ai_settings_dialog'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ai_settingsSubtitle,
            style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppMetrics.space12),

          // 启用开关行
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ai_enableAssistant,
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

          // Provider 预设（本地组 / 云端组）
          _fieldLabel(l10n.ai_providerPreset),
          const SizedBox(height: AppMetrics.space4 + 2),
          _PresetGroupLabel(
            label: l10n.ai_presetGroupLocal,
            tag: l10n.ai_presetTagLocal,
            tagColor: t.success,
            tagBg: t.successSoft,
          ),
          const SizedBox(height: AppMetrics.space4 + 1),
          _buildPresetSegmented(kAiLocalPresets),
          const SizedBox(height: AppMetrics.space8),
          _PresetGroupLabel(
            label: l10n.ai_presetGroupCloud,
            tag: l10n.ai_presetTagCloud,
            tagColor: t.warning,
            tagBg: t.warningSoft,
          ),
          const SizedBox(height: AppMetrics.space4 + 1),
          _buildPresetSegmented(kAiCloudPresets),
          const SizedBox(height: AppMetrics.space12),

          // Base URL
          _fieldLabel(l10n.ai_baseUrl),
          const SizedBox(height: AppMetrics.space4 + 2),
          AppTextField(
            fieldKey: const Key('ai_base_url_field'),
            controller: _baseUrlCtrl,
            compact: true,
            hintText: 'http://localhost:11434/v1',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppMetrics.space12),

          // Model
          _fieldLabel(l10n.ai_model),
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
              l10n.ai_modelHint,
              style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
            ),
          ),
          const SizedBox(height: AppMetrics.space12),

          // API Key（只写不读 + 已存说明条 + 云端必填校验）
          _fieldLabel(l10n.ai_apiKey),
          const SizedBox(height: AppMetrics.space4 + 2),
          AppTextField(
            fieldKey: const Key('ai_api_key_field'),
            controller: _apiKeyCtrl,
            compact: true,
            obscureText: !_showKey,
            hasError: _keyError,
            hintText: _keySaved
                ? l10n.ai_apiKeyHintSaved
                : (_isCloud ? l10n.ai_apiKeyHintCloud : l10n.ai_apiKeyHint),
            onChanged: (_) {
              if (_keyError) setState(() => _keyError = false);
            },
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
          if (_keyError)
            Padding(
              padding: const EdgeInsets.only(top: AppMetrics.space4 + 1),
              child: Text(
                l10n.ai_keyRequired,
                style: AppTextStyles.tiny11.copyWith(color: t.error),
              ),
            )
          else if (_keySaved)
            Container(
              margin: const EdgeInsets.only(top: AppMetrics.space4 + 2),
              padding: const EdgeInsets.symmetric(
                horizontal: AppMetrics.space8 + 2,
                vertical: AppMetrics.space8 - 2,
              ),
              decoration: BoxDecoration(
                color: t.surface,
                border: Border.all(color: t.border),
                borderRadius: AppMetrics.br6,
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 13, color: t.success),
                  const SizedBox(width: AppMetrics.space8 - 2),
                  Expanded(
                    child: Text(
                      l10n.ai_keySavedNote,
                      style:
                          AppTextStyles.tiny11.copyWith(color: t.textSecondary),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearKey,
                    child: Text(
                      l10n.ai_keyClear,
                      style: AppTextStyles.tiny11.copyWith(color: t.brand),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppMetrics.space4 + 1),
              child: Text(
                l10n.ai_apiKeyNote,
                style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
              ),
            ),
          const SizedBox(height: AppMetrics.space12),

          // 连接状态行
          _buildConnRow(context),

          // 底部按钮
          const SizedBox(height: AppMetrics.space16),
          Row(
            children: [
              AppButton.ghost(
                key: const Key('ai_reset_consent_button'),
                label: l10n.ai_resetConsent,
                size: AppButtonSize.small,
                onPressed: _resetConsents,
              ),
              const Spacer(),
              AppButton.ghost(
                label: l10n.common_cancel,
                size: AppButtonSize.small,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: AppMetrics.space8),
              AppButton.primary(
                key: const Key('ai_settings_save_button'),
                label: l10n.common_save,
                size: AppButtonSize.small,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildPresetSegmented(List<String> presets) {
    final t = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: AppMetrics.br6,
      ),
      child: Row(
        children: [
          for (final preset in presets)
            Expanded(
              child: _PresetSegment(
                label: aiPresetLabel(preset),
                selected: _preset == preset,
                onTap: () => _selectPreset(preset),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnRow(BuildContext context) {
    final t = context.appTheme;
    final l10n = context.l10n;

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
              l10n.ai_connIdle,
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
              l10n.ai_connChecking,
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
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Text(
              '${l10n.ai_connected} · ${aiPresetLabel(_preset)} · ${_modelCtrl.text.trim()}',
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
      label: context.l10n.ai_checkConnection,
      size: AppButtonSize.small,
      onPressed: _conn == _ConnState.checking ? null : _checkConnection,
    );
  }
}

/// 预设分组标签（组名 + 隐私归属 tag：本地 success / 云端 warning）
class _PresetGroupLabel extends StatelessWidget {
  const _PresetGroupLabel({
    required this.label,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
  });

  final String label;
  final String tag;
  final Color tagColor;
  final Color tagBg;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.tiny11.copyWith(
            color: t.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: AppMetrics.space8 - 2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.space4 + 2,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: AppMetrics.br4,
          ),
          child: Text(
            tag,
            style: AppTextStyles.tiny11.copyWith(
              color: tagColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
