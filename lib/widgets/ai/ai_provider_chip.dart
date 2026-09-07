import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/settings/settings_provider.dart';
import '../../services/ai/ai_presets.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// AI provider 状态 chip（F9.9）：常驻三个 AI 任务对话框标题区。
///
/// 云端 → warning 色「☁ {provider} · 数据外发」；本地 → neutral
/// 「⚲ {provider} · 本地处理」。设置未加载时不渲染。
class AiProviderChip extends ConsumerWidget {
  const AiProviderChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const SizedBox.shrink();

    final cloud = isCloudPreset(settings.aiProviderPreset, settings.aiBaseUrl);
    final t = context.appTheme;
    final label = aiPresetLabel(settings.aiProviderPreset);
    final text = cloud
        ? context.l10n.ai_chipCloud(label)
        : context.l10n.ai_chipLocal(label);

    return Container(
      key: Key(cloud ? 'ai_chip_cloud' : 'ai_chip_local'),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space8 + 1),
      decoration: BoxDecoration(
        color: cloud ? t.warningSoft : t.surfaceVariant,
        borderRadius: AppMetrics.br10,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTextStyles.tiny11.copyWith(
          color: cloud ? t.warning : t.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
