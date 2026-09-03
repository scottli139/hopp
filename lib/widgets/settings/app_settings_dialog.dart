import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/settings/settings_provider.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_dialog.dart';
import '../common/app_popup_menu.dart';
import '../common/app_segmented_control.dart';

/// 打开应用设置对话框（F5.9 / M8.8）
Future<T?> openAppSettingsDialog<T>(BuildContext context) {
  return showAppDialog<T>(
    context: context,
    title: context.l10n.settings_title,
    width: 480,
    child: const AppSettingsDialog(),
  );
}

/// 应用设置对话框：主题 / 语言（F5.9）/ 界面缩放（F5.7）
///
/// 侧栏底栏的主题、缩放快捷控件保留，本对话框为集中入口。
class AppSettingsDialog extends ConsumerWidget {
  const AppSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final themeMode = settings?.themeMode ?? 'system';
    final language = settings?.language ?? 'system';
    final uiScale = settings?.uiScale ?? 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SettingsRow(
          label: l10n.settings_theme,
          hint: l10n.settings_themeHint,
          control: AppSegmentedControl<String>(
            value: themeMode,
            items: [
              AppSegmentedItem(
                value: 'system',
                icon: Icons.brightness_auto_outlined,
                tooltip: l10n.settings_themeSystem,
              ),
              AppSegmentedItem(
                value: 'light',
                icon: Icons.light_mode_outlined,
                tooltip: l10n.settings_themeLight,
              ),
              AppSegmentedItem(
                value: 'dark',
                icon: Icons.dark_mode_outlined,
                tooltip: l10n.settings_themeDark,
              ),
            ],
            onChanged: (mode) =>
                ref.read(settingsProvider.notifier).updateThemeMode(mode),
          ),
        ),
        _SettingsRow(
          label: l10n.settings_language,
          hint: l10n.settings_languageHint,
          control: SizedBox(
            width: 160,
            child: AppPopupSelect<String>(
              value: language,
              boxed: true,
              compact: true,
              items: [
                AppPopupSelectEntry(
                  value: 'system',
                  label: l10n.settings_themeSystem,
                ),
                // 语言名固定用自身书写（endonym），不随界面语言翻译
                const AppPopupSelectEntry(value: 'en', label: 'English'),
                const AppPopupSelectEntry(value: 'zh', label: '中文'),
              ],
              onSelected: (lang) =>
                  ref.read(settingsProvider.notifier).updateLanguage(lang),
            ),
          ),
        ),
        _SettingsRow(
          label: l10n.settings_uiScale,
          hint: l10n.settings_uiScaleHint,
          control: SizedBox(
            width: 160,
            child: AppPopupSelect<double>(
              value: uiScale,
              boxed: true,
              compact: true,
              items: const [
                AppPopupSelectEntry(value: 1, label: '100%'),
                AppPopupSelectEntry(value: 1.25, label: '125%'),
                AppPopupSelectEntry(value: 1.5, label: '150%'),
              ],
              onSelected: (scale) =>
                  ref.read(settingsProvider.notifier).updateUiScale(scale),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.hint,
    required this.control,
  });

  final String label;
  final String hint;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppMetrics.space12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body13),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: AppTextStyles.caption12.copyWith(
                    color: t.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          control,
        ],
      ),
    );
  }
}
