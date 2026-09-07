import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/settings/settings_provider.dart';
import '../../services/ai/ai_presets.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';

/// 首次外发隐私门（F9.9）：云端 Provider 第一次实际调用前的一次性确认。
///
/// 按 Provider 记录（AppSettings.aiCloudConsents），同意过即直接放行；
/// 取消则中断本次调用并 toast 提示。挂载点：三个 AI 能力入口按钮 +
/// AI 设置对话框「检查连接」。
///
/// [capability] 本次外发内容的一句话说明（随入口不同而异）。
///
/// 预设 / Base URL 默认取已保存的设置；AI 设置对话框「检查连接」针对
/// 未保存的编辑态调用时经 [preset] / [baseUrl] 显式传入，确保门与
/// 实际外发的目标一致。
Future<bool> ensureAiCloudConsent(
  BuildContext context,
  WidgetRef ref, {
  String? preset,
  String? baseUrl,
  required String capability,
}) async {
  final settings = ref.read(settingsProvider).valueOrNull;
  if (settings == null) return false;

  final effectivePreset = preset ?? settings.aiProviderPreset;
  final effectiveBaseUrl = baseUrl ?? settings.aiBaseUrl;
  if (!isCloudPreset(effectivePreset, effectiveBaseUrl)) return true;
  if (settings.aiCloudConsents[effectivePreset] == true) return true;

  final agreed = await showAppDialog<bool>(
    context: context,
    title: context.l10n.ai_gateTitle,
    width: 480,
    child: _PrivacyGateContent(
      capability: capability,
      preset: effectivePreset,
      baseUrl: effectiveBaseUrl,
    ),
  );

  if (agreed == true) {
    await ref
        .read(settingsProvider.notifier)
        .grantAiCloudConsent(effectivePreset);
    return true;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.ai_gateDeclined)),
    );
  }
  return false;
}

/// 隐私门对话框内容（原型 `docs/design/tier2_byok_preview.html` 画板 B）：
/// 警示条 → 四行说明（本次外发 / 目标端点 / 不会外发 / 日志）→
/// 端点 mono 行 → 注记 → 「取消」「理解并同意外发」。
class _PrivacyGateContent extends StatelessWidget {
  const _PrivacyGateContent({
    required this.capability,
    required this.preset,
    required this.baseUrl,
  });

  final String capability;
  final String preset;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final l10n = context.l10n;

    // 内容整体可滚动：小窗口 / 界面缩放 150% 下不溢出
    return SingleChildScrollView(
      child: Column(
        key: const Key('ai_privacy_gate'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 警示条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppMetrics.space8 + 2),
            decoration: BoxDecoration(
              color: t.warningSoft,
              borderRadius: AppMetrics.br6,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: t.warning),
                const SizedBox(width: AppMetrics.space8),
                Expanded(
                  child: Text(
                    l10n.ai_gateBanner,
                    style: AppTextStyles.caption12.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppMetrics.space12),

          // 四行说明
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: AppMetrics.br8,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppMetrics.space12,
              vertical: AppMetrics.space4,
            ),
            child: Column(
              children: [
                _GateRow(label: l10n.ai_gateRowSend, value: capability),
                _GateRow(
                  label: l10n.ai_gateRowTarget,
                  value: l10n.ai_gateRowTargetValue(aiPresetLabel(preset)),
                ),
                _GateRow(
                  label: l10n.ai_gateRowNotSent,
                  value: l10n.ai_gateRowNotSentValue,
                ),
                _GateRow(
                  label: l10n.ai_gateRowLog,
                  value: l10n.ai_gateRowLogValue,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppMetrics.space12),

          // 端点 mono 行
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppMetrics.space8 + 2,
              vertical: AppMetrics.space8,
            ),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border.all(color: t.border),
              borderRadius: AppMetrics.br6,
            ),
            child: Text(
              'POST ${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions',
              style: AppTextStyles.code11.copyWith(color: t.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppMetrics.space8 + 2),

          Text(
            l10n.ai_gateNote,
            style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
          ),

          // 底部按钮
          const SizedBox(height: AppMetrics.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton.ghost(
                label: l10n.common_cancel,
                size: AppButtonSize.small,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: AppMetrics.space8),
              AppButton.primary(
                key: const Key('ai_gate_agree_button'),
                label: l10n.ai_gateAgree,
                size: AppButtonSize.small,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GateRow extends StatelessWidget {
  const _GateRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppMetrics.space8),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: AppTextStyles.caption12.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppMetrics.space8 + 2),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
