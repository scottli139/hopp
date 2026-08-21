import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../utils/constants.dart';
import 'environment_manager_dialog.dart';

/// 环境切换器
///
/// 显示当前激活的环境，支持下拉切换、打开环境管理对话框。
/// 当活动请求中存在未定义变量时，显示警告标记。
class EnvironmentSwitcher extends ConsumerWidget {
  const EnvironmentSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final environmentsAsync = ref.watch(environmentProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final unresolved = ref.watch(unresolvedVariablesProvider);

    final environments = environmentsAsync.valueOrNull ?? [];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceS),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.public,
            size: 14,
            color: activeEnv != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 6),
          // 环境下拉选择
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                key: const Key('environment_switcher_dropdown'),
                value: activeEnv?.id,
                isExpanded: true,
                isDense: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                hint: Text(
                  'No Environment',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'No Environment',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  ...environments.map(
                    (env) => DropdownMenuItem<String?>(
                      value: env.id,
                      child: Text(
                        env.name,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (id) {
                  ref.read(activeEnvironmentIdProvider.notifier).setActive(id);
                },
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
                color: theme.colorScheme.error,
              ),
            ),
          // 管理环境按钮
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              key: const Key('manage_environments_button'),
              icon: const Icon(Icons.tune, size: 16),
              padding: EdgeInsets.zero,
              tooltip: 'Manage Environments',
              color: theme.colorScheme.outline,
              onPressed: () => showEnvironmentManagerDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
