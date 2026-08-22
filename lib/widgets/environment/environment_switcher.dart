import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_popup_menu.dart';
import 'environment_manager_dialog.dart';

/// 环境切换器
///
/// 显示当前激活的环境，支持弹出菜单切换、打开环境管理对话框。
/// 当活动请求中存在未定义变量时，显示警告标记。
class EnvironmentSwitcher extends ConsumerWidget {
  const EnvironmentSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final environmentsAsync = ref.watch(environmentProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final unresolved = ref.watch(unresolvedVariablesProvider);

    final appTheme = context.appTheme;
    final environments = environmentsAsync.valueOrNull ?? [];

    // 盒式选择器：30px 高、描边圆角（设计原型 .sb-env 规格）
    return Container(
      height: 30,
      margin: const EdgeInsets.only(
        left: AppMetrics.space8,
        right: AppMetrics.space8,
        bottom: AppMetrics.space8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space8),
      decoration: BoxDecoration(
        color: appTheme.background,
        border: Border.all(color: appTheme.border),
        borderRadius: AppMetrics.br6,
      ),
      child: Row(
        children: [
          Icon(
            Icons.public,
            size: 14,
            color: activeEnv != null ? appTheme.brand : appTheme.textTertiary,
          ),
          const SizedBox(width: 6),
          // 环境选择弹出菜单
          //
          // 菜单宽度自适应内容（min 160 / max 280），不随按钮宽度压缩，
          // 避免窄侧边栏中 "No Environment" 等文字折行。
          Expanded(
            child: PopupMenuButton<String?>(
              key: const Key('environment_switcher_dropdown'),
              tooltip: 'Select environment',
              offset: const Offset(0, 28),
              constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
              shape: AppPopupMenu.menuShape(theme),
              elevation: AppPopupMenu.menuElevation,
              color: AppPopupMenu.menuColor(theme),
              onSelected: (id) {
                ref.read(activeEnvironmentIdProvider.notifier).setActive(id);
              },
              itemBuilder: (context) => [
                AppPopupMenu.textItem(
                  theme: theme,
                  value: null,
                  label: 'No Environment',
                  selected: activeEnv == null,
                  color: appTheme.textTertiary,
                ),
                for (final env in environments)
                  AppPopupMenu.textItem(
                    theme: theme,
                    value: env.id,
                    label: env.name,
                    selected: activeEnv?.id == env.id,
                  ),
              ],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activeEnv?.name ?? 'No Environment',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption12.copyWith(
                        color: activeEnv != null
                            ? appTheme.textPrimary
                            : appTheme.textTertiary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: appTheme.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          // 未定义变量警告
          if (unresolved.isNotEmpty)
            Tooltip(
              message: 'Unresolved variables: ${unresolved.join(', ')}',
              child: Icon(
                key: const Key('unresolved_variables_warning'),
                Icons.warning_amber_rounded,
                size: 16,
                color: appTheme.error,
              ),
            ),
          // 管理环境按钮
          AppIconButton(
            key: const Key('manage_environments_button'),
            icon: Icons.tune,
            tooltip: 'Manage Environments',
            size: 24,
            iconSize: 14,
            onPressed: () => showEnvironmentManagerDialog(context),
          ),
        ],
      ),
    );
  }
}
