import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../models/request_tab.dart';
import '../../providers/providers.dart';
import '../../utils/app_logger.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// 请求标签栏组件
///
/// 显示所有打开的请求标签，支持切换和关闭
class RequestTabs extends ConsumerWidget with LogMixin {
  const RequestTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(requestTabProvider);
    final activeTabId = ref.watch(activeTabIdProvider);

    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final appTheme = context.appTheme;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: appTheme.surface,
        border: Border(
          bottom: BorderSide(color: appTheme.border),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length + 1,
        itemBuilder: (context, index) {
          if (index == tabs.length) {
            return _buildNewTabButton(context, ref);
          }
          return _buildTab(context, ref, tabs[index], activeTabId);
        },
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    RequestTab tab,
    String? activeTabId,
  ) {
    final isActive = tab.id == activeTabId;
    final appTheme = context.appTheme;
    final methodColor = _getMethodColor(tab.request.method.value);

    return Material(
      color: isActive ? appTheme.background : appTheme.surface,
      child: InkWell(
        onTap: () {
          ref.read(activeTabIdProvider.notifier).state = tab.id;
        },
        hoverColor: appTheme.surfaceVariant,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.brand : AppColors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: appTheme.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 方法标识：品牌色加粗小字（设计原型规格，无底块）
              Text(
                tab.request.method.value,
                style: AppTextStyles.micro10.copyWith(color: methodColor),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tab.request.name,
                  style: AppTextStyles.tiny11.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? appTheme.textPrimary
                        : appTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tab.isDirty)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 4),
              // Close button（透明底，hover 显现）
              Material(
                color: AppColors.transparent,
                borderRadius: AppMetrics.br4,
                child: InkWell(
                  borderRadius: AppMetrics.br4,
                  hoverColor: appTheme.surfaceVariant,
                  onTap: () => _closeTab(ref, tab),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: appTheme.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewTabButton(BuildContext context, WidgetRef ref) {
    final appTheme = context.appTheme;

    return Material(
      color: appTheme.surface,
      child: InkWell(
        onTap: () => _createNewRequest(ref),
        hoverColor: appTheme.surfaceVariant,
        child: Container(
          width: 36,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: appTheme.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Icon(
            Icons.add,
            size: 16,
            color: appTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 创建新请求
  void _createNewRequest(WidgetRef ref) {
    logInfo('Creating new request from tab bar');
    final newRequest = HttpRequest.empty();
    ref.read(requestTabProvider.notifier).openTab(newRequest);
    ref.read(activeTabIdProvider.notifier).state = newRequest.id;
    logInfo('New request created: ${newRequest.id}');
  }

  void _closeTab(WidgetRef ref, RequestTab tab) {
    final tabs = ref.read(requestTabProvider);
    final activeId = ref.read(activeTabIdProvider);

    ref.read(requestTabProvider.notifier).closeTab(tab.id);

    // If we're closing the active tab, activate another one
    if (activeId == tab.id) {
      final remainingTabs = tabs.where((t) => t.id != tab.id).toList();
      if (remainingTabs.isNotEmpty) {
        ref.read(activeTabIdProvider.notifier).state = remainingTabs.last.id;
      } else {
        ref.read(activeTabIdProvider.notifier).state = null;
      }
    }
  }

  Color _getMethodColor(String method) {
    return AppColors.method(method);
  }
}
